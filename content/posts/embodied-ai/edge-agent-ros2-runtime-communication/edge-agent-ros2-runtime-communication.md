---
title: "端侧 Agent Runtime 与 ROS Runtime 通信方案市场调研"
date: 2026-07-24T10:00:00+08:00
summary: "针对端侧 Agent Runtime 与一个或多个 ROS Runtime 分离部署的场景，比较 HTTP + WebSocket、gRPC over UDS 和全 WebSocket，并基于机器人厂商、具身智能平台与开源项目的公开资料分析市场采用情况。"
tags: [ai, robot, embodied-ai, ros2, agent, grpc, websocket, architecture]
categories: [embodied-ai]
draft: true
---

# 端侧 Agent Runtime 与 ROS Runtime 通信方案市场调研

## 调研摘要

本次调研针对一个已经确定的系统边界：

- Agent Runtime 与 ROS Runtime 必须分离部署。
- Agent Runtime 负责任务理解、长程规划和跨机器人编排。
- ROS Runtime 负责连接机器人、传感器、VLA、运动规划与安全执行。
- 一台端侧设备上可能运行一个 Agent Runtime 和多个 ROS Runtime。

本文只比较三种候选方案：

1. HTTP 下发命令，WebSocket 推送事件。
2. gRPC over Unix Domain Socket。
3. 命令、响应和事件全部使用 WebSocket。

本次公开样本按接口边界呈现为：

| 公开接口边界 | 本次样本中观察到的方案 | 代表性公开案例 |
|---|---|---|
| 机器人对外任务与状态 API | HTTP/REST + WebSocket | ABB、KABAM、Misty |
| 强类型机器人 SDK、平台服务接口 | gRPC/Protobuf | Spot、ANYmal |
| 同机模块化 Runtime | gRPC over UDS | Viam |
| VLA 远程推理、ROS 通用桥接和可视化 | 全 WebSocket | OpenPI、rosbridge、Foxglove |
| 机器人内部感知、控制和高频状态 | ROS 2/DDS、UDP、RTDE 等 | Unitree、DEEP Robotics、UBTECH、Universal Robots |

在可核验的公开资料中：

- HTTP + WebSocket 找得到 ABB、KABAM、Misty 等直接产品 API 案例。
- Boston Dynamics Spot、ANYbotics ANYmal 公开使用 gRPC 强类型接口；Viam 明确公开了同机 gRPC over UDS 模块通信。
- 全 WebSocket 的公开案例主要集中在 OpenPI 策略推理、rosbridge 和 Foxglove 这类连续数据或通用桥接边界。
- Figure、1X、Agility、Apptronik、Tesla、Sanctuary AI、智元等主流具身智能厂商没有公开足以判断内部 Agent—Runtime IPC 的资料，不能根据产品演示反推协议。

本次公开样本没有显示 Agent—ROS Runtime 通信已经形成统一标准。

## 调研范围与证据标准

调研时间截止到 `2026-07-24`。

检索范围包括机器人厂商官方开发文档、官方 SDK、官方 GitHub 仓库、产品技术资料和具身智能项目文档。博客转载、论坛猜测和无法追溯到厂商的架构图不作为结论依据。

样本覆盖工业机器人、移动机器人、四足机器人、人形机器人、机器人软件平台和 VLA 推理项目。它不是一份穷尽全球所有厂商的名录，而是一份“公开资料能够支撑到什么程度”的可核验样本。

厂商公开的通常是 SDK 或对外 API，而不是机器人内部进程拓扑。为了避免把不同边界混为一谈，本文使用四级证据：

| 等级 | 定义 |
|---|---|
| A | 与目标场景高度一致：独立 Runtime 或模块之间的通信方式、传输和进程关系均公开 |
| B | 使用相同协议组合，但位于机器人对外 API、SDK 或平台集成边界 |
| C | 位于 VLA 推理、调试桥接或底层控制等相邻边界，只能证明技术可用 |
| U | 厂商公开了产品或 SDK，但没有公开足以判断通信协议的资料 |

这里不能计算严格的“市场占有率”。公开资料存在明显偏差：开放 SDK 的厂商更容易进入样本，封闭产品即使部署量很大，也可能完全不披露内部实现。

## 系统模型：一个 Agent Runtime 对多个 ROS Runtime

目标部署不是固定的一对一，而是一对多：

```text
human
  |
  v
+------------------------------+
| Agent Runtime                |
| task planning and routing    |
+-----+---------------+--------+
      |               |
      |               |
      v               v
+-------------+  +-------------+
| ROS Runtime |  | ROS Runtime |
| arm-a       |  | mobile-a    |
+------+------+  +------+------+
       |                |
       v                v
    robot A          robot B
```

Agent Runtime 不加入 ROS graph，也不直接依赖 ROS 2 发行版和接口包。每个 ROS Runtime 在内部使用 ROS 2 Action、Service 和 Topic，对外只暴露经过约束的任务接口。

多个 Runtime 带来四个通信要求：

1. 每个 Runtime 必须有稳定的 `runtime_id`。
2. Agent 必须知道每个 Runtime 管理哪些 `robot_id`、资源和技能。
3. 某个 Runtime 或事件连接断开时，其他 Runtime 不能受影响。
4. 执行记录必须同时包含 `runtime_id` 和 `execution_id`。

Agent 侧需要一个很薄的 Runtime Registry：

```text
RuntimeRegistry
  |
  +-- arm-a
  |     endpoint: 127.0.0.1:8101
  |     robots: robot-arm-a
  |     skills: pick, place, inspect
  |
  +-- mobile-a
        endpoint: 127.0.0.1:8102
        robots: robot-mobile-a
        skills: navigate, dock
```

Runtime 数量少且实例固定时，可以使用静态配置加健康检查；实例动态创建或数量较多时，则需要服务发现或统一注册机制。

## 三种方案核心对比

| 对比项 | HTTP + WebSocket | gRPC over UDS | 全 WebSocket |
|---|---|---|---|
| 命令下发 | HTTP POST | Unary RPC | 自定义 command 消息 |
| 状态查询 | HTTP GET | Unary RPC | 自定义 query/response |
| 进度反馈 | WebSocket event | Server stream | 自定义 event |
| 取消执行 | HTTP command | Unary RPC | 自定义 command |
| 接口定义 | OpenAPI + JSON Schema | `.proto` | AsyncAPI 或自定义 Schema |
| 默认数据格式 | JSON | Protobuf | 通常 JSON，也可二进制 |
| 类型约束 | 中 | 强 | 默认较弱 |
| 请求响应关联 | HTTP 天然提供 | 框架提供 | 自己维护 correlation ID |
| 标准错误与超时 | HTTP 状态码和客户端库 | gRPC status/deadline | 自己定义 |
| 流量控制 | 命令与事件分离，WS 队列需治理 | gRPC stream 提供流量控制能力 | 应用层处理队列和背压 |
| 单连接故障影响 | WS 断开不影响 HTTP 命令 | channel 中断影响该 Runtime RPC/stream | 命令、响应和事件一起中断 |
| 多 Runtime 地址 | 每实例一个端口 | 每实例一个 Socket 文件 | 每实例一个 WS endpoint |
| Agent 连接数 | 每实例一个 HTTP pool + 一条 WS | 每实例一个 channel | 每实例一条或多条 WS |
| 同机访问控制 | loopback、网络命名空间、鉴权 | Socket 文件权限 | loopback、网络命名空间、鉴权 |
| 调试工具 | curl、浏览器、Postman | grpcurl、生成客户端 | WS 客户端和日志 |
| 初期工作内容 | HTTP API、事件连接和两套错误处理 | `.proto`、代码生成、server/channel | 消息信封、关联、错误、超时和心跳 |
| 后续治理内容 | OpenAPI、Schema 与事件兼容 | Protobuf 字段和服务兼容 | 自定义 RPC、重连、背压和版本兼容 |

三种方案都能承载低频任务通信。性能差异需要在目标硬件、语言实现、消息大小和并发模型下测量。Agent 与 ROS Runtime 交换的是技能目标、状态和结果，不是关节控制周期里的高频数据，仅凭协议名称无法判断性能是否会成为主要差异。

还有一个常被混在一起的维度：gRPC、HTTP 和 WebSocket 是接口与交互方式，TCP 与 UDS 是连接落在哪里。HTTP 也可以运行在 UDS 上，gRPC 也可以监听 loopback TCP。选协议解决契约问题，选 UDS 还是本机端口解决部署和访问边界。

## 方案一：HTTP Command API + WebSocket Event Stream

### 结构

```text
                         ROS 2 Action, Service, Topic
Agent <---- HTTP/WS ----> Runtime API Adapter <--------> ROS nodes
                               |
                               +---- execution store
                               +---- VLA adapter
                               +---- safety guard
```

HTTP 只负责有明确请求结果的操作：

```http
POST /v1/executions
GET  /v1/executions/{execution_id}
POST /v1/executions/{execution_id}:cancel
GET  /v1/runtime
GET  /v1/runtime/snapshot
```

WebSocket 只负责异步事件：

```text
execution.accepted
execution.started
execution.progress
execution.succeeded
execution.failed
execution.canceled
runtime.state_changed
```

### 优势

- 命令与事件职责清楚。HTTP 请求失败和 WS 事件流中断是两种不同故障。
- WS 断开后，Agent 仍能通过 HTTP 查询状态或取消任务。
- 不要求生成客户端代码；接口变化需要同步维护 OpenAPI、Schema、客户端和服务端校验。
- curl、浏览器和 Postman 就能复现大部分问题。
- 多 Runtime 模型直观：每个 Runtime 一个端口，Agent 为每个实例维护独立连接。
- Web、云端服务、测试工具和非 ROS 客户端都容易接入。

### 劣势

- 同时维护 HTTP 和 WS 两套连接、鉴权与可观测性。
- JSON Schema、OpenAPI 和实际代码可能逐渐漂移，需要契约测试。
- WebSocket 事件需要自己定义顺序、重复、丢失和重连恢复规则。
- 每个 Runtime 占用一个端口，实例动态变化时需要额外发现机制。
- JSON 对大消息的编码效率不如 Protobuf，但对高层任务通常不是关键问题。

### 多 Runtime 落地方式

每个 ROS Runtime 暴露同一套 API：

```text
http://127.0.0.1:8101
ws://127.0.0.1:8101/v1/events

http://127.0.0.1:8102
ws://127.0.0.1:8102/v1/events
```

Agent 不把它们聚合成一条没有来源信息的事件流。每条事件都携带 `runtime_id`、`robot_id` 和 `execution_id`：

```json
{
  "schema_version": "1",
  "event_id": "evt-0192",
  "event_type": "execution.progress",
  "runtime_id": "arm-a",
  "robot_id": "robot-arm-a",
  "execution_id": "exec-8f4c",
  "state_version": 7,
  "occurred_at": "2026-07-24T10:15:02.381+08:00",
  "payload": {
    "phase": "grasping",
    "progress": 0.6
  }
}
```

### 市场证据

本次样本包含三个 HTTP + WebSocket 机器人产品 API 案例：

- ABB Robot Web Services 使用 HTTP 操作控制器资源，通过 WebSocket 发送资源变化和订阅事件。[ABB Robot Web Services](https://developercenter.robotstudio.com/api/rwsApi/)
- KABAM Smart+ Link 使用 REST 下发导航命令、读取配置，使用 WebSocket 推送机器人和任务状态。[KABAM Smart+ Link](https://github.com/KABAM-Robotics/smart-link-docs)
- Misty 的远程机器人应用使用 HTTP API 发送动作请求，通过 WebSocket 接收传感器与事件数据。[Misty Web API](https://docs.mistyrobotics.com/misty-ii/web-api/overview/)

这些属于对外产品接口，不是厂商内部 IPC。它们证明“命令走 HTTP、事件走 WS”已经用于机器人产品，不能证明 ABB、KABAM 或 Misty 的内部进程也采用同样方案。

## 方案二：gRPC over Unix Domain Socket

### 结构

```protobuf
service RobotRuntime {
  rpc GetRuntimeInfo(GetRuntimeInfoRequest)
      returns (RuntimeInfo);
  rpc StartExecution(StartExecutionRequest)
      returns (StartExecutionResponse);
  rpc GetExecution(GetExecutionRequest)
      returns (Execution);
  rpc CancelExecution(CancelExecutionRequest)
      returns (CancelExecutionResponse);
  rpc WatchEvents(WatchEventsRequest)
      returns (stream ExecutionEvent);
}
```

多个 Runtime 使用不同 Socket：

```text
unix:///run/robot/arm-a.sock
unix:///run/robot/mobile-a.sock
```

### 优势

- `.proto` 同时定义服务和消息，跨语言类型约束强。
- Unary RPC、server stream 和 bidirectional stream 都有标准模型。
- deadline、status、metadata 和代码生成减少自定义协议工作。
- Protobuf 编码紧凑；接口数量和消息量上升后的实际收益需要测量。
- UDS 不需要监听 TCP 端口，可以使用 Socket 文件权限控制本机访问。
- 多 Runtime 可以自然映射为多个 channel 和 Socket 文件。

gRPC 原生支持 unary、server streaming、client streaming 和 bidirectional streaming，并从 `.proto` 生成客户端与服务端代码。[gRPC 核心概念](https://grpc.io/docs/what-is-grpc/core-concepts/)

### 劣势

- 团队需要掌握 `.proto`、生成代码、兼容规则和 gRPC 调试工具。
- 接口仍在频繁推倒重来时，强类型契约会增加修改摩擦。
- UDS 路径长度、残留 Socket、权限和 Runtime 重启需要生命周期管理。
- 浏览器和普通运维工具的直接支持不如 HTTP。
- gRPC 解决不了业务幂等、执行恢复和物理动作回滚。

gRPC 取消只会终止 RPC，不会撤销已经发生的机器人动作。机械臂抓到一半时连接断开，最终状态仍然要由 ROS Runtime 的执行状态机判断。

### 市场证据

gRPC 在机器人 SDK 和平台服务接口中有以下公开案例：

- Viam 的模块作为 `viam-server` 的独立子进程运行，默认通过随机命名的 Unix Domain Socket 做 gRPC 通信。这是公开资料里与本文场景最接近的案例。[Viam 模块生命周期](https://docs.viam.com/operate/modules/lifecycle-of-a-module/)
- Boston Dynamics Spot 的服务接口使用 gRPC 与 Protobuf，第三方服务还会注册到 Robot Directory，但公开场景主要是网络服务，不是同机 UDS。[Spot API Service](https://dev.bostondynamics.com/docs/concepts/developing_api_services.html)
- ANYbotics 的公开产品资料说明 ANYmal API 基于 gRPC，用于任务控制、数据同步和第三方系统集成，但没有公开为 Agent—ROS 同机 UDS。[ANYmal 产品技术资料](https://www.anybotics.com/wp-content/uploads/2022/07/ANYmal-Specifications-Sheet-22062022.pdf)

这些资料能够证明 gRPC 已用于机器人服务接口。对于 gRPC over UDS，能直接对应本文同机独立 Runtime 边界的样本目前是 Viam。

## 方案三：全 WebSocket

### 结构

命令、响应和事件全部进入一条连接：

```json
{
  "type": "command",
  "name": "execution.start",
  "message_id": "cmd-001",
  "runtime_id": "arm-a",
  "payload": {}
}
```

```json
{
  "type": "response",
  "name": "execution.accepted",
  "correlation_id": "cmd-001",
  "execution_id": "exec-001"
}
```

### 优势

- 一条长连接天然支持双向消息。
- 长连接全双工语义可以承载观测和动作持续往返的会话。
- 快速原型不必同时建设 HTTP API 和事件通道。
- 浏览器、可视化工具和非 ROS 客户端容易接入。

### 劣势

- 请求响应关联、超时、错误码和幂等都要自行定义。
- 命令、响应和事件共享连接，断线影响面最大。
- 需要自己处理心跳、重连、状态恢复、队列上限和慢消费者。
- 协议复杂后，实际上是在 WebSocket 上重写一个 RPC 框架。
- 多 Runtime 意味着多条长期连接，连接状态与业务状态容易缠在一起。

浏览器标准 `WebSocket` API 本身不提供背压，消费者跟不上时，应用层需要限制队列、合并进度事件或断开慢客户端。[MDN WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)

### 市场证据

全 WebSocket 更多出现在相邻边界：

- Physical Intelligence 的 OpenPI 使用 WebSocket policy client，机器人运行时发送观测与 prompt，策略服务返回 action chunk。[OpenPI 远程推理](https://github.com/Physical-Intelligence/openpi/blob/main/docs/remote_inference.md)
- rosbridge 在 WebSocket 等传输上提供结构化协议，让非 ROS 客户端发布、订阅和调用 ROS 能力。[rosbridge 协议](https://github.com/RobotWebTools/rosbridge_suite/blob/ros2/ROSBRIDGE_PROTOCOL.md)
- Foxglove Bridge 使用 WebSocket 把 ROS 1/ROS 2 数据连接到可视化与调试工具。[Foxglove Bridge](https://docs.foxglove.dev/docs/fleet/bridge)

这些案例都位于连续策略推理、浏览器工具或通用 ROS 桥接边界，不能直接作为 Agent 任务事务边界的采用证据。

如果将通用 rosbridge 直接暴露给 Agent，Agent 会获得发现 Topic、发布消息和调用 Service 的广泛能力。通用桥追求 ROS 能力覆盖面，受限任务 API 追求最小授权范围，二者的权限模型不同。

## 厂商与代表性项目调研

下表记录本次检索中能够找到一手资料的厂商、平台和代表性项目。这里的“采用方案”只描述公开接口，不代表厂商全部内部系统。

| 厂商或项目 | 公开边界 | 公开采用方案 | 证据 | 与目标场景的关系 |
|---|---|---|---|---|
| Viam | `viam-server` 与本机独立模块 | gRPC over UDS | A | 与独立 Runtime 同机 IPC 高度接近 |
| ABB Robot Web Services | 应用与机器人控制器 | HTTP + WebSocket | B | 命令与事件拆分方式直接可借鉴 |
| KABAM Smart+ Link | AI/业务应用与机器人网关 | REST + WebSocket | B | 任务命令和机器人状态边界接近 |
| Misty Robotics | 远程应用与机器人 | HTTP + WebSocket | B | 动作命令与传感器事件分流 |
| Boston Dynamics Spot | SDK、第三方服务与机器人 | gRPC/Protobuf | B | 证明强类型机器人服务接口成熟，不是 UDS |
| ANYbotics ANYmal | 集成系统与 ANYmal 平台 | gRPC API | B | 面向任务、数据和平台集成，不是同机 IPC |
| Physical Intelligence OpenPI | 机器人 Runtime 与 VLA 策略服务 | WebSocket | C | 属于观测—动作推理边界 |
| RobotWebTools rosbridge | 非 ROS 客户端与 ROS | WebSocket 协议 | C | 属于通用桥接，不是受限任务 API |
| Foxglove Bridge | ROS 与可视化、调试平台 | WebSocket | C | 属于数据与运维边界 |
| Unitree SDK2 / ROS 2 | 应用与 Go2、B2、H1、G1 等机器人 | CycloneDDS / ROS 2 | C | 说明机器人控制面仍大量采用 DDS，不属于三种候选 |
| DEEP Robotics | 感知主机、运动主机和机器人 SDK | ROS 2 或 UDP | C | 说明底层部署会采用 ROS/UDP，不应拿来决定高层任务 API |
| UBTECH Walker TienKung | 开发应用与人形机器人 SDK | ROS 2 / DDS | C | 公开 SDK 以 ROS 2 为基础，属于机器人控制边界 |
| Fetch Robotics | 用户应用与 Fetch/Freight | ROS Action、Topic、Service | C | 历史研究平台案例，现已停止销售支持 |
| Universal Robots | ROS Driver 与机器人控制器 | ROS 2 + RTDE | C | 工业机器人底层接口，不属于 Agent—Runtime API |
| Fourier Intelligence | GRx/Aurora 客户端与 SDK | 公开 SDK，本文边界协议不明确 | U | 不能从 SDK 存在推断内部 IPC |
| AgiBot | 数据、模型与仿真平台 | 未公开目标边界协议 | U | 公开资料集中在数据、模型和仿真 |
| Agility Robotics Digit/Arc | Arc、Digit 与企业系统 | 宣布云平台和加密通信，未公开协议 | U | 无法判断内部 Agent—Runtime IPC |
| Figure | 自研 Fleet Management System 与机器人 | 未公开协议 | U | 公开了舰队管理能力，没有公开 IPC |
| 1X | 数据 API 与 5 Hz inference SDK | 未公开传输协议 | U | 证明存在推理边界，不能判断协议 |
| Apptronik | Draco/Apollo 与开发环境 | Draco 曾公开 ROS 集成，Apollo 边界未公开 | U | 不能据此判断当前产品内部架构 |
| Tesla Optimus | Optimus 软件栈 | 未公开目标边界协议 | U | 公开了视觉、规划、控制和软件栈方向，没有开发接口资料 |
| Sanctuary AI | Physical AI 与多种机器人形态 | 未公开目标边界协议 | U | 公开了全栈产品方向，没有 Runtime IPC 资料 |

按公开证据归类，这个样本呈现为：

- HTTP + WebSocket：3 个 B 级机器人产品 API 案例。
- gRPC：1 个 A 级 gRPC over UDS 案例，2 个 B 级 gRPC 机器人接口案例。
- 全 WebSocket：3 个 C 级推理或通用桥接案例。
- 其他技术路线：5 个 C 级 ROS 2、DDS、UDP 或 RTDE 案例。
- 协议未充分公开：8 个 U 级厂商样本。

这些数字用于展示证据结构，不是市场份额。尤其不能把“未公开”并入任何一种方案，也不能把 rosbridge 和 Foxglove 的项目采用量算成机器人厂家采用量。

对应的一手资料：

- Unitree 官方说明 SDK2 基于 CycloneDDS，并可直接使用 ROS 2 消息通信。[Unitree ROS 2](https://github.com/unitreerobotics/unitree_ros2)
- DEEP Robotics 官方仓库公开了 ROS 2 版本、UDP 版本以及 ROS/UDP 转换组件。[DEEP Robotics GitHub](https://github.com/DeepRoboticsLab)
- UBTECH Walker TienKung SDK 以 ROS 2 为基础，并公开 DDS 相关配置。[Walker TienKung SDK](https://docs.ubtrobot.com/walker-tienkung/en/docs/V2.0.4.x/sdk/7/)
- Fetch Research Edition 公开采用标准 ROS 接口，但产品已停止销售支持。[Fetch API Overview](https://fetchrobotics.github.io/docs/api_overview.html)
- Universal Robots 的 ROS 2 Driver 建立在机器人 Client Library 与 RTDE 等接口之上。[Universal Robots ROS 2 Driver](https://github.com/UniversalRobots/Universal_Robots_ROS2_Driver)
- Fourier 公开了 GRx Client 与 Aurora SDK，但公开页面不足以判断本文所关心的 Runtime IPC。[Fourier GitHub](https://github.com/FFTAI)
- AgiBot 的公开资料以机器人数据、模型和仿真平台为主。[AgiBot World](https://github.com/OpenDriveLab/Agibot-World)
- Agility 公开说明 Arc 是连接 Digit 与仓库系统的云端平台，但未披露底层协议。[Agility Digit and Arc](https://www.agilityrobotics.com/solutions)
- Figure 公开说明其自研 Fleet Management System 管理机器人健康、位置和任务，但未披露通信协议。[Figure Fleet Management](https://www.figure.ai/news/ramping-figure-03-production)
- 1X 公开提到数据 API 和以 5 Hz 运行的 inference SDK，但没有说明传输协议。[1X and NVIDIA](https://www.1x.tech/discover/1X-NVIDIA-Research-Collaboration)
- Apptronik 公开说明 Draco 支持实时 Linux 与 ROS 集成，没有公开 Apollo 当前的 Agent—Runtime IPC。[Apptronik Draco](https://apptronik.com/our-work/draco-ii-iii)
- Tesla 公开了 Optimus 所需的视觉、规划、控制和软件栈方向，没有公开 Agent—Runtime 开发接口。[Tesla AI and Robotics](https://www.tesla.com/AI)
- Sanctuary AI 公开了 Physical AI 面向多种机器人形态的全栈产品方向，没有公开本文目标边界的通信协议。[Sanctuary AI](https://www.sanctuary.ai/technology)

## 公开证据分布

### 1. HTTP + WebSocket 集中在产品任务与状态 API

ABB、KABAM、Misty 都把有明确结果的操作放在 HTTP，把持续状态和事件放在 WebSocket。这些接口虽然不是内部 IPC，但和 Agent 下发任务、Runtime 反馈状态的交互形状最接近。

这些案例能够证明这种职责拆分已经用于机器人产品，不能证明内部 Agent—Runtime 边界也采用同一方案。

### 2. gRPC 的厂商质量很高，但 UDS 证据不能扩大解释

Spot、ANYmal 和 Viam 都公开采用了 gRPC。可其中只有 Viam 与“同机独立模块 + UDS”高度一致。Spot 和 ANYmal 只能计入 gRPC 协议家族，不能计入 gRPC over UDS 样本。

公开样本没有提供“同机进程应当采用 gRPC over UDS”的普遍性证据。

### 3. 全 WebSocket 集中在连续数据边界

OpenPI、rosbridge 和 Foxglove 的共同点不是“机器人”，而是数据连续流动：观测与动作往返、ROS 数据桥接、实时可视化。这与任务启动、取消和查询不是同一种交互。

本次样本没有找到 A 级或 B 级的全 WebSocket 机器人任务控制 API 案例。

### 4. 大量厂商根本不在这三种方案里

Unitree 的 CycloneDDS、DEEP Robotics 的 ROS 2/UDP、Universal Robots 的 RTDE 和 Fetch 的 ROS 接口说明，机器人底层通信仍然高度多样。

这些案例说明三种候选只覆盖 Agent—ROS Runtime 的高层任务边界。ROS Runtime 往下仍可能连接 DDS、ROS、UDP、共享内存或厂商 SDK。

## 多 Runtime 的共同结构

三种方案都可以放进同一个一对多结构，区别只在 Runtime Client 与 API Adapter 之间的通信实现：

```text
+-----------------------------------+
| Agent Runtime                     |
|                                   |
|  RuntimeRegistry                  |
|  RuntimeClientManager             |
|  Plan and execution mapping       |
+----------+----------------+-------+
           |                |
           | runtime API    | runtime API
           v                v
+----------------+  +----------------+
| ROS Runtime A  |  | ROS Runtime B  |
| API Adapter    |  | API Adapter    |
| ExecutionStore |  | ExecutionStore |
| ROS, VLA       |  | ROS, VLA       |
+-------+--------+  +-------+--------+
        |                   |
        v                   v
     robot A             robot B
```

| 方案 | Agent 侧连接对象 | ROS Runtime 侧监听对象 |
|---|---|---|
| HTTP + WebSocket | 每个 Runtime 一个 HTTP pool 和一条事件连接 | 每实例一个 loopback HTTP/WS 端口 |
| gRPC over UDS | 每个 Runtime 一个 gRPC channel | 每实例一个 Unix Socket 文件 |
| 全 WebSocket | 每个 Runtime 一条或多条 WS session | 每实例一个 WS endpoint |

每个 Runtime 的身份接口至少返回：

| 字段 | 用途 |
|---|---|
| `runtime_id` | Runtime 稳定标识，重启后不变 |
| `robot_ids` | 当前负责的机器人和执行资源 |
| `capabilities` | 可执行技能及版本 |
| `api_version` | Agent 判断接口兼容性 |
| `runtime_state` | `starting/ready/degraded/offline` |
| `last_seen_at` | 健康检查和失联判断 |

每次执行至少保存：

| 字段 | 用途 |
|---|---|
| `runtime_id` | 找到执行状态的权威 Runtime |
| `execution_id` | Runtime 内的执行主键 |
| `robot_id` | 真正占用的机器人资源 |
| `plan_id`、`step_id` | 映射回 Agent 长程计划 |
| `idempotency_key` | 防止超时重试造成重复启动 |
| `state`、`state_version` | 权威状态和乱序保护 |
| `result` 或 `error` | 结构化结果与失败原因 |

稳定引用使用：

```text
(runtime_id, execution_id)
```

不要假设 `execution_id` 在多个 Runtime 之间天然全局唯一。

## 执行状态与故障恢复

协议不会替系统定义任务状态。三种方案都需要相同的执行状态机：

```text
submitted ------> rejected
    |
    v
accepted
    |
    v
running --------> canceling ------> canceled
    |  \
    |   \-------> failed
    |
    +-----------> succeeded
```

HTTP 返回 `202 Accepted`、gRPC 返回 `execution_id` 或 WS 返回 `accepted`，都只说明 Runtime 接管了请求，不代表机器人已经完成动作。

断线语义需要在接口契约中明确：

| 故障 | 处理 |
|---|---|
| 命令响应丢失 | Agent 使用同一个 `idempotency_key` 向原 Runtime 查询或重试 |
| 某个事件流断开 | 只影响对应 Runtime；重连后先查询该实例快照 |
| Agent 退出 | Runtime 按既定任务策略继续或取消，不把断连直接等同急停 |
| 某个 Runtime 重启 | 该实例恢复执行记录，并与控制器和机器人现场对账 |
| 事件消费过慢 | 终态和状态迁移不能丢，普通进度可以合并或降频 |
| 机器人或 VLA 断开 | Runtime 进入底层定义的安全状态，再报告结构化失败 |

三种传输方案都不能单独提供物理动作的“恰好执行一次”。网络超时发生时，Agent 可能不知道请求有没有到；Runtime 重启时，也可能不知道某个物理动作进行到了哪一步。幂等键、持久化记录和现场对账可以约束不确定性，不能回滚物理世界。

跨 Runtime 任务也不能依赖传统分布式事务完成物理回滚。例如移动机器人先送料，再由机械臂抓取，需要逐步确认和失败补偿，每个 ROS Runtime 只保存自己执行部分的权威状态。

## 选型验证维度

市场案例只能说明某种方案被使用过，最终比较还需要代入项目数据：

| 验证维度 | HTTP + WebSocket | gRPC over UDS | 全 WebSocket |
|---|---|---|---|
| 接口变更频率 | 检查 OpenAPI/Schema 同步成本 | 检查 `.proto` 与生成代码变更成本 | 检查自定义消息兼容成本 |
| 语言与客户端数量 | 检查各语言 HTTP/WS 客户端的一致性 | 检查生成客户端覆盖范围 | 检查各语言自定义协议实现差异 |
| 多 Runtime 规模 | 测量端口、连接池和 WS 数量 | 测量 channel、Socket 文件和进程生命周期 | 测量长连接数量和重连风暴 |
| 消息与事件吞吐 | 测量 JSON 编解码和 WS 队列 | 测量 Protobuf、stream 与 flow control | 测量序列化、队列和应用层背压 |
| 故障隔离 | 验证 HTTP 与 WS 分离后的恢复路径 | 验证 channel 和 stream 中断后的恢复路径 | 验证单连接中命令与事件同时中断的影响 |
| 调试与可观测性 | 验证 curl、日志和 tracing 链路 | 验证 grpcurl、reflection 和 tracing | 验证 correlation ID、日志和抓包能力 |
| 本机访问控制 | 验证端口、网络命名空间和鉴权 | 验证 Socket 文件权限与清理 | 验证端口、网络命名空间和鉴权 |
| 现有工程能力 | 统计 HTTP、WS、OpenAPI 的维护成本 | 统计 Protobuf、代码生成和 gRPC 的维护成本 | 统计自定义 RPC 机制的维护成本 |

三种方案可以映射到同一组业务操作：

```text
POST /executions       -> StartExecution()
GET  /executions/{id}  -> GetExecution()
POST /{id}:cancel      -> CancelExecution()
WS events              -> WatchEvents()
```

这组映射只说明业务模型可以保持一致，不表示三种传输实现的工程成本相同。

## VLA 通信与 Agent 通信不能混为一谈

Agent 与 ROS Runtime 交换任务语义：技能、目标对象、约束、进度和结果。VLA 与执行循环交换观测和动作：图像、本体状态、prompt 和 action chunk。

```text
low frequency
Agent <---- task and event ----> ROS Runtime
                                  |
                                  | observation and action
                                  v
                                VLA
high frequency
```

OpenPI 使用 WebSocket 做策略推理，只能作为 VLA 推理边界的证据，不能直接作为 Agent 任务 API 的证据。它们处在不同时间尺度和数据边界。

如果相机图像、点云和高频关节状态跨越 Agent—ROS Runtime 边界，三种方案需要重新按大消息吞吐进行测试；如果边界只包含场景摘要、目标位姿、技能阶段和结果证据，则属于本文比较的低频任务通信范围。

## 安全边界

三种通信方案都不能承担安全闭环。

急停、碰撞保护、关节限位、速度限制、控制器 watchdog 和断连安全动作必须留在 ROS Runtime、机器人控制器或更低层。Agent 连接断开，安全策略不能一起消失。

存在多个 ROS Runtime 时，同一机器人或执行资源只能有一个写入所有者。Agent Registry 应报告重复的 `robot_id` 和资源声明，硬件控制器与安全层则必须阻止两个 Runtime 同时取得控制权。

这些安全责任与选择 HTTP + WebSocket、gRPC over UDS 或全 WebSocket 无关。
