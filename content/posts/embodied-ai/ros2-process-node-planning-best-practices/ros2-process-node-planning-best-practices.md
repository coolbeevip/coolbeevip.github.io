---
title: "具身智能系统中基于 ROS 2 的进程与节点规划最佳实践"
date: 2026-07-03T10:00:00+08:00
summary: "结合 ROS 2、Agent、仿真平台和机器人系统工程实践，说明具身智能系统中 Node 与 Process 的区别，以及如何按业务域、故障域、数据流和实时性规划进程与节点。"
tags: [ai, robot, embodied-ai, ros2, agent]
categories: [embodied-ai]
draft: true
---

# 具身智能系统中基于 ROS 2 的进程与节点规划最佳实践

随着大语言模型（LLM）、机器人和仿真平台的发展，越来越多的具身智能系统开始采用 **ROS 2 + Agent** 的整体架构。

然而，很多开发者第一次接触 ROS 2 时，都会产生一个误区：

> **一个 ROS Node 就是一个操作系统进程。**

实际上，这只是 ROS 2 官方教程为了便于学习而采用的一种简单组织方式，并不是大型机器人系统的工程实践。

本文将结合当前主流机器人系统的设计经验，介绍一种适用于具身智能平台的 **ROS 2 进程与节点规划最佳实践**。

## 一、首先区分 Node 和 Process

很多人容易混淆这两个概念。

### Process（进程）

进程是操作系统调度的基本单位。

例如：

```text
camera_process
perception_process
motion_process
agent_process
```

Linux 中可以通过：

```bash
ps -ef
```

看到它们。

### Node（节点）

Node 是 ROS 2 中的逻辑功能模块。

例如：

```text
CameraNode
PlannerNode
MoveItNode
DetectionNode
```

一个 Node 可以拥有：

* Publisher
* Subscriber
* Service
* Action
* Parameter
* Timer

Node 是 ROS 2 的通信单元，而不是操作系统进程。

### 两者关系

ROS 2 支持：

```text
一个 Process
    └── 一个 Node
```

也支持：

```text
一个 Process
    ├── CameraNode
    ├── DetectionNode
    └── TrackingNode
```

因此：

> **Node ≠ Process。**

大型机器人系统通常都会在一个进程中运行多个 Node。

## 二、为什么教程喜欢一个 Node 一个进程？

官方教程大多数都是：

```text
camera_process
    CameraNode

planner_process
    PlannerNode
```

原因非常简单：

* 容易理解
* 容易调试
* 容易学习
* 崩溃互不影响

这种方式非常适合 Demo。

但是：

对于真正的机器人而言，

```text
Camera
↓
YOLO
↓
Tracking
↓
Scene Graph
```

如果每一步都是一个进程，那么每一张图像都会经过：

```text
DDS
↓
序列化
↓
网络传输
↓
反序列化
↓
内存复制
```

对于几十 MB 的图像和点云而言，开销非常明显。

## 三、现代 ROS 2 的最佳实践

目前行业已经逐渐形成一种共识：

> **先划分进程，再划分节点。**

也就是说：

### 第一层：按业务域划分 Process

例如：

```text
感知
运动规划
控制
Agent
UI
```

每个业务域对应一个独立进程。

而不是：

```text
一个功能
↓
一个进程
```

### 第二层：进程内部拆分 Node

例如感知进程：

```text
perception_process
├── CameraNode
├── RectifyNode
├── DetectionNode
├── TrackingNode
└── SceneGraphNode
```

其中 `RectifyNode` 指图像矫正节点，通常负责对相机图像做畸变校正、视角校正或双目图像对齐。它不负责识别物体，而是在检测、跟踪之前把原始图像整理成更适合后续算法处理的输入。

这些模块：

* 数据交换频繁
* 生命周期一致
* 故障影响一致

因此放在同一个进程更加合理。

## 四、规划进程时应该遵循哪些原则？

通常建议综合考虑三个维度。

### 1）故障域（Failure Domain）

首先思考：

> 哪些模块应该一起崩？

例如：

```text
Camera
YOLO
Tracking
```

如果 Camera 崩了：

YOLO 自然也无法继续工作。

因此：

```text
Perception Process
CameraNode
DetectionNode
TrackingNode
```

属于同一个故障域。

而：

```text
RViz
WebUI
```

即使崩了，

机器人仍然可以继续工作。

因此：

应该放到独立进程。

### 2）数据流（Data Flow）

数据交换越频繁，

越应该放在同一个进程。

例如：

```text
Camera
↓
Detection
↓
Segmentation
↓
Tracking
```

图像数据非常大。

因此：

更适合：

```text
一个 Process
多个 Node
```

利用 ROS 2 的进程内通信（Intra-process Communication）减少数据复制。

### 3）实时性（Real-time）

例如：

```text
LLM 推理
```

耗时：

```text
500ms~5s
```

而：

```text
机械臂控制
Servo
Joint Controller
```

可能要求：

```text
1ms~10ms
```

因此：

绝不能放在同一个实时执行链路。

Agent 层应该与控制层彻底隔离。

## 五、哪些模块建议独立进程？

通常包括：

### 驱动

例如：

```text
Camera Driver
LiDAR Driver
Robot Driver
```

驱动最容易因为硬件异常退出。

建议独立。

### 仿真平台

例如：

* MuJoCo
* Isaac Sim
* Gazebo

这些都是完整的软件系统。

建议作为独立进程运行。

### UI

例如：

```text
RViz
Web UI
Qt GUI
```

GUI 崩溃不能影响机器人。

### 生命周期管理

例如：

```text
Health Monitor
Lifecycle Manager
Diagnostics
```

通常独立部署。

## 六、哪些模块适合组合到一个进程？

典型包括：

### 感知流水线

```text
Camera
↓
Detection
↓
Tracking
↓
Scene Graph
```

### Agent

```text
Planner
↓
Memory
↓
Tool
↓
Reasoning
```

这些模块：

生命周期一致，

数据交换频繁。

适合：

```text
agent_process
```

### Motion

```text
MoveIt
↓
IK
↓
Trajectory
↓
Planning Scene
```

也是一个典型业务域。

## 七、仿真应该如何设计？

很多团队会把：

```text
MuJoCo
Isaac Sim
```

直接集成到 Agent 中。

这并不是一种推荐方式。

更合理的是：

```text
Agent
↓
ROS 2
↓
Simulation Adapter
↓
Simulation Backend
```

例如：

```text
simulation_process
├── SimBackendNode
├── SimSensorBridgeNode
├── SimControlBridgeNode
└── SimClockNode
```

底层可以自由切换：

```text
MuJoCo
Isaac Sim
Gazebo
```

而 Agent 完全无需修改。

这样：

仿真与真机可以共享统一接口。

## 八、推荐的具身智能整体进程规划

下面是一种比较均衡、适合中大型具身智能平台的划分方式。

```text
physos-agent-process
├── LLMNode
├── PlannerNode
├── MemoryNode
└── SkillSchedulerNode

physos-runtime-process
├── TaskRuntimeNode
├── DeviceManagerNode
├── SkillAdapterNode
└── DiagnosticsNode

simulation-process
├── SimBackendNode
├── SimSensorBridgeNode
├── SimControlBridgeNode
└── SimClockNode

perception-process
├── CameraNode
├── DetectionNode
├── TrackingNode
└── WorldModelNode

motion-process
├── MoveItNode
├── PlanningSceneNode
└── TrajectoryNode

control-process
├── ros2_control
├── JointController
└── GripperController

ui-process
└── WebUINode
```

其中：

* **Agent**：负责长程规划、推理、记忆和技能编排。
* **Runtime**：负责技能执行、任务调度和设备管理。
* **Simulation**：负责仿真后端适配，可切换 MuJoCo、Isaac Sim 等平台。
* **Perception**：负责视觉、场景理解和世界模型更新。
* **Motion**：负责运动规划、轨迹生成和碰撞检测。
* **Control**：负责实时控制和硬件驱动。
* **UI**：负责监控、调试和人机交互。

这种划分具有较好的可扩展性，可以在不影响上层 Agent 的情况下自由替换仿真平台或真实机器人。

## 九、节点之间应该如何通信？

进程和节点划分完成之后，还需要继续规划节点之间的通信方式。

这里也有一个常见误区：

> **ROS 2 节点之间的通信不等于全部使用 Topic。**

Topic 很重要，但它只适合一类通信场景。一个完整的具身智能系统通常会同时使用 Topic、Service、Action、Parameter、TF、Lifecycle 等机制。

### 1）Topic：持续流动的数据

Topic 适合持续发布、持续订阅的数据流。

例如：

```text
CameraNode
  └── /camera/color/image_raw
      ↓
DetectionNode

DetectionNode
  └── /perception/detections
      ↓
TrackingNode

TrackingNode
  └── /perception/tracks
      ↓
WorldModelNode
```

典型 Topic 包括：

* 图像
* 点云
* 检测框
* 跟踪结果
* 关节状态
* 传感器状态
* 世界模型增量更新

这类数据的特点是：

* 高频产生
* 最新值通常比历史值更重要
* 发布者不关心有多少订阅者
* 接收方不需要逐条确认

因此：

> **感知流、状态流、传感器流通常使用 Topic。**

### 2）Service：短事务请求

Service 适合一次请求、一次响应的短事务。

例如：

```text
DeviceManagerNode
  └── /device/get_status
      ↓
RobotDriverNode

SkillAdapterNode
  └── /gripper/open
      ↓
GripperControllerNode
```

典型 Service 包括：

* 查询设备状态
* 切换模式
* 打开或关闭夹爪
* 触发一次标定
* 读取或写入配置

这类交互的特点是：

* 请求很明确
* 响应很快返回
* 不需要持续反馈
* 不适合长时间阻塞

因此：

> **短命令、短查询、短配置操作通常使用 Service。**

### 3）Action：长时间任务

Action 适合需要持续执行、可反馈进度、可取消的任务。

例如：

```text
PlannerNode
  └── /motion/plan_and_execute
      ↓
MotionProcess

SkillSchedulerNode
  └── /skill/pick_object
      ↓
TaskRuntimeNode
```

典型 Action 包括：

* 移动到某个位置
* 执行一条轨迹
* 抓取一个物体
* 完成一个技能
* 执行一个长程任务步骤

这类交互的特点是：

* 执行时间较长
* 需要中间反馈
* 可能成功、失败或被取消
* 调用方需要知道最终结果

因此：

> **运动执行、技能执行、任务执行通常使用 Action。**

对于 Agent 系统尤其重要的一点是：

Agent 不应该通过一个阻塞 Service 去等待机械臂完成长时间动作，而应该通过 Action 获取反馈、结果和取消能力。

### 4）Parameter：配置，而不是业务数据流

Parameter 适合表达节点运行参数。

例如：

```text
DetectionNode
  ├── confidence_threshold
  ├── model_path
  └── max_detection_count

TrackingNode
  ├── max_lost_frames
  └── association_threshold
```

Parameter 适合：

* 阈值
* 模型路径
* 控制参数
* 开关配置
* 调试参数

不适合：

* 图像
* 点云
* 检测结果
* 任务状态
* 高频控制数据

因此：

> **Parameter 用来配置节点，不应该被当成业务通信通道。**

### 5）TF：坐标系关系

机器人系统里还有一类特殊通信：坐标变换。

例如：

```text
world
└── base_link
    └── camera_link
        └── camera_optical_frame
```

感知、规划和控制都会依赖这些坐标关系。

例如：

* 相机看到的物体在 `camera_frame`
* 机械臂规划需要目标在 `base_link`
* 导航系统需要机器人在 `map`
* 仿真系统需要发布统一时钟和坐标树

这类数据不应该用普通 Topic 随便传结构体，而应该使用 ROS 2 的 TF 体系。

因此：

> **空间坐标关系使用 TF，而不是每个节点自己约定坐标转换。**

### 6）Lifecycle：节点状态管理

对于中大型系统，还应该规划节点生命周期。

例如：

```text
unconfigured
↓
inactive
↓
active
↓
finalized
```

Lifecycle 适合管理：

* 驱动启动顺序
* 感知模块激活顺序
* 模型加载
* 故障恢复
* 仿真和真机切换
* 系统健康检查

例如：

```text
LifecycleManager
  ├── configure CameraNode
  ├── activate DetectionNode
  ├── activate TrackingNode
  └── deactivate PerceptionProcess
```

因此：

> **系统级启停、恢复和状态迁移应该通过 Lifecycle 管理。**

### 7）同一进程内是否还需要 Topic？

如果多个 Node 放在同一个进程里，它们仍然可以使用 ROS 2 的 Topic、Service 和 Action API 通信。

区别在于：

如果启用了 ROS 2 的进程内通信（Intra-process Communication），同一进程内的 Topic 通信可以减少序列化和内存复制。

例如：

```text
perception_process
├── CameraNode
│   └── image topic
│       ↓
├── DetectionNode
│   └── detections topic
│       ↓
└── TrackingNode
```

从代码结构上看，它们仍然是 Node 和 Topic。

从运行效率上看，它们不一定需要走完整 DDS 网络通信路径。

因此：

> **同一进程内可以继续使用 Topic 建模数据流，同时利用进程内通信降低开销。**

不过也不要把所有内部函数都包装成 Node。

如果某些逻辑只是一个算法内部步骤，例如图像归一化、后处理、规则过滤，它们可以只是普通函数或类，不必强行变成 ROS Node。

### 8）一种推荐通信规划

结合前面的进程划分，可以得到一种更完整的通信关系。

```text
perception-process
├── CameraNode
│   └── Topic: /camera/image_raw
├── DetectionNode
│   └── Topic: /perception/detections
├── TrackingNode
│   └── Topic: /perception/tracks
└── WorldModelNode
    └── Topic: /world_model/updates

motion-process
├── MoveItNode
│   └── Action: /motion/plan_and_execute
├── PlanningSceneNode
│   └── Topic: /planning_scene
└── TrajectoryNode
    └── Action: /trajectory/execute

control-process
├── JointController
│   └── Topic: /joint_states
├── GripperController
│   └── Action: /gripper/grasp
└── RobotDriver
    └── Service: /robot_driver/set_mode

physos-runtime-process
├── TaskRuntimeNode
│   └── Action: /task/execute
├── DeviceManagerNode
│   └── Service: /device/get_status
└── DiagnosticsNode
    └── Topic: /diagnostics

physos-agent-process
├── PlannerNode
│   └── Action Client: /task/execute
├── MemoryNode
└── SkillSchedulerNode
    └── Action Client: /skill/execute
```

简单来说：

* **Topic**：用于持续数据流。
* **Service**：用于短请求和短响应。
* **Action**：用于长时间、可反馈、可取消的任务。
* **Parameter**：用于配置节点。
* **TF**：用于坐标系关系。
* **Lifecycle**：用于节点状态管理。

所以，节点之间不是全都通过 Topic。

更合理的做法是：

> **先判断通信语义，再选择 ROS 2 通信机制。**

## 十、总结

对于现代具身智能系统而言，ROS 2 不应仅仅被视为一个消息通信框架，而应作为连接 Agent、感知、规划、控制和仿真等多个业务域的统一运行时。

在工程实践中，有几条原则值得长期遵循：

* **Node 是逻辑模块，Process 是部署单元，不应将两者等同。**
* **优先按业务域和故障域划分进程，再在进程内部拆分多个 Node。**
* **高频、大数据通信的节点应尽量放在同一进程，利用进程内通信降低开销。**
* **Agent 与实时控制链路保持解耦，避免推理延迟影响机器人控制。**
* **仿真平台通过统一的适配层接入，使 MuJoCo、Isaac Sim、Gazebo 与真实机器人能够共享同一套上层接口。**

这种架构既符合当前 ROS 2 的工程实践，也为未来在不同机器人、不同仿真平台之间复用具身智能能力提供了良好的基础。
