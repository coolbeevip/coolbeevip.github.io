---
title: "macOS 上使用 PyCharm 远程开发 Isaac ROS"
date: 2026-07-06T00:00:00+08:00
summary: "记录在 macOS 上通过 PyCharm 连接远程 Ubuntu GPU 主机开发 Isaac ROS 的推荐环境结构、配置步骤、调试方式与常见坑。"
tags: [nvidia, isaac-ros, pycharm, macos, ros2, ubuntu]
categories: [embodied-ai]
draft: false
---

# macOS 上使用 PyCharm 远程开发 Isaac ROS

目标：在 macOS 上使用 PyCharm 编写和调试代码，在远程 Ubuntu GPU 主机上运行 Isaac ROS、Docker、ROS 2、CUDA 和传感器驱动。

工作边界：

- macOS：PyCharm UI、SSH、Git、调试入口。
- 远程主机：Isaac ROS workspace、Docker、ROS 2、CUDA、TensorRT、传感器和机器人硬件接口。
- Isaac ROS 容器：`ros2`、`colcon`、Python 节点、launch 文件的实际运行环境。

本文不复制 Isaac ROS 官方安装细节。Isaac ROS 本体安装以官方 Getting Started 文档为准；本文补齐 macOS + PyCharm 远程开发链路。

环境隔离使用 Docker。除非需要调试驱动、设备权限或系统依赖，否则不要把 Isaac ROS 的 Python、TensorRT、OpenCV 等依赖铺到远程宿主机系统环境里。

参考：[Isaac ROS Development Environment](https://nvidia-isaac-ros.github.io/concepts/dev_env/index.html) 说明官方 Docker 开发环境、workspace 挂载和 `isaac-ros activate` 工作流。

## 1. 推荐架构

开发结构：

| 层级           | 位置              | 职责                                            |
|--------------|-----------------|-----------------------------------------------|
| PyCharm UI   | macOS           | 编辑代码、查看索引、提交 Git、发起运行或调试                      |
| 远程主机         | Ubuntu GPU 主机 | 保存 Isaac ROS workspace，运行 Docker、ROS 2、colcon |
| Isaac ROS 容器 | 远程主机            | 执行 `isaac-ros activate` 后进入的真实开发环境            |
| GPU / 传感器    | 远程主机            | CUDA、TensorRT、相机、雷达、机器人硬件接口                   |

操作规则：PyCharm 连接远程主机；运行 Isaac ROS 节点前，在 PyCharm Terminal 中执行 `isaac-ros activate` 进入容器。

## 2. 在远程主机安装 Isaac ROS

执行顺序：先让 Isaac ROS 在远程 Ubuntu GPU 主机上独立跑通，再配置 macOS 和 PyCharm。

### 2.1 确认远程主机可用

远程主机使用 x86_64 Ubuntu + NVIDIA GPU。先从 macOS 登录远程主机：

```bash
ssh user@remote-host
```

验证 SSH 成功后，再确认 NVIDIA GPU 驱动可见：

```bash
nvidia-smi
```

确认结果：macOS 能稳定 SSH 登录远程主机，`nvidia-smi` 能看到 NVIDIA GPU 和驱动信息。

### 2.2 按官方文档安装 Isaac ROS

安装入口使用官方 Getting Started 文档：

- [NVIDIA Isaac ROS Getting Started](https://nvidia-isaac-ros.github.io/getting_started/index.html)

在远程主机上按官方文档完成：

1. 安装或确认 NVIDIA 驱动。
2. 安装 Docker 和 NVIDIA Container Toolkit。
3. 配置 Isaac ROS APT 仓库。
4. 安装 `isaac-ros-cli`。
5. 创建 Isaac ROS workspace，例如 `~/workspaces/isaac_ros-dev`。
6. 执行 `isaac-ros init docker` 初始化 Docker 开发环境。

安装完成后，在远程主机上验证 CLI 和 workspace：

```bash
echo $ISAAC_ROS_WS
isaac-ros --help
test -d "${ISAAC_ROS_WS}/src" && echo "workspace ok"
```

看到 workspace 路径、`isaac-ros` 帮助信息和 `workspace ok` 后，再进入下一步。

### 2.3 进入 Docker 开发环境并验证 ROS 2

进入 Isaac ROS Docker 开发环境：

```bash
cd $ISAAC_ROS_WS
isaac-ros activate
```

进入容器后验证 ROS 2 基础命令：

```bash
ros2 --help
ros2 pkg list
```

`ros2 --help` 能输出帮助信息，说明 ROS 2 命令可用；`ros2 pkg list` 能列出当前环境可发现的 package，说明当前 shell 已经具备 ROS 2 package 发现能力。

如果这一步失败，不要继续。先回到 Getting Started 文档修远程主机环境。

### 2.4 创建最小 Python 节点验证开发链路

远程主机、Docker 容器和 ROS 2 都验证通过后，再创建一个最小 Python ROS 2 package，确认 workspace、`colcon` 构建、Python 节点注册和 `ros2 run` 都能正常工作。

如果还不在 Isaac ROS 容器中，先执行：

```bash
cd $ISAAC_ROS_WS
isaac-ros activate
```

在容器中创建最小 package：

```bash
cd ${ISAAC_ROS_WS}/src
ros2 pkg create py_hello --build-type ament_python --dependencies rclpy
```

这条命令会在 `src` 目录下创建一个名为 `py_hello` 的 ROS 2 package：

- `py_hello`：package 名称，后续运行时会用到，例如 `ros2 run py_hello hello_node`。
- `--build-type ament_python`：说明这是一个 Python package，使用 ROS 2 的 `ament_python` 构建方式。
- `--dependencies rclpy`：声明这个 package 依赖 ROS 2 Python 客户端库，后面的节点会通过它创建 node、timer、logger 等对象。

编辑 `${ISAAC_ROS_WS}/src/py_hello/py_hello/hello_node.py`：

```python
import rclpy
from rclpy.node import Node


class HelloNode(Node):
    def __init__(self):
        super().__init__("hello_node")
        self.timer = self.create_timer(1.0, self.say_hello)

    def say_hello(self):
        self.get_logger().info("Hello from Isaac ROS remote dev")


def main():
    rclpy.init()
    node = HelloNode()
    try:
        rclpy.spin(node)
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
```

再编辑 `${ISAAC_ROS_WS}/src/py_hello/setup.py`，在 `entry_points` 的 `console_scripts` 下加入节点入口：

```python
entry_points={
    "console_scripts": [
        "hello_node = py_hello.hello_node:main",
    ],
},
```

构建并运行：

```bash
cd ${ISAAC_ROS_WS}
colcon build --symlink-install --packages-select py_hello
source install/setup.bash
ros2 run py_hello hello_node
```

看到下面的日志就说明最小开发链路跑通：

```text
[INFO] [hello_node]: Hello from Isaac ROS remote dev
```

这一步用到的三个命令分别负责：

- `colcon build --symlink-install --packages-select py_hello`：只构建 `py_hello`。`--symlink-install` 让 Python 脚本和 launch 文件以符号链接进入 `install/`，便于开发时改完直接跑。
- `source install/setup.bash`：把当前 workspace 加载到这个 shell，让 ROS 2 找到刚构建出来的 package 和节点。
- `ros2 run py_hello hello_node`：运行 `py_hello` 包里注册的 `hello_node` 节点。

launch 文件用于一次性启动多个 ROS 2 节点、设置参数、配置 topic remap 和组织启动流程。本文的最小 hello 示例只启动一个节点，所以使用 `ros2 run`；真实 Isaac ROS demo 或机器人应用通常使用 `ros2 launch your_package your_launch.py` 启动整组节点。

## 3. 准备 macOS 端开发环境

PyCharm 远程开发相关能力以 JetBrains 官方文档为准：

- [Connect to a remote server from PyCharm](https://www.jetbrains.com/help/pycharm/remote-development-starting-page.html)
- [Configure an interpreter using SSH](https://www.jetbrains.com/help/pycharm/configuring-remote-interpreters-via-ssh.html)
- [Configure an interpreter using Docker](https://www.jetbrains.com/help/pycharm/using-docker-as-a-remote-interpreter.html)
- [Remote Debugging with PyCharm](https://www.jetbrains.com/help/pycharm/remote-debugging-with-product.html)

### 3.1 安装本地工具并配置 SSH

macOS 端安装这些工具即可：

- PyCharm Professional
- Git
- SSH key

验证本地工具：

```bash
git --version
ssh -V
```

如果使用 JetBrains Gateway，也可以安装；如果直接用 PyCharm 内置 Remote Development，则不需要单独安装 Gateway。

确认结果：`git --version` 和 `ssh -V` 都能正常输出版本信息。

### 3.2 验证 SSH 免密登录

把 macOS 的 SSH key 加到远程主机：

```bash
ssh-copy-id user@remote-host
```

验证免密登录：

```bash
ssh user@remote-host
```

如果没有 `ssh-copy-id`，也可以手动把 `~/.ssh/id_ed25519.pub` 追加到远程主机的 `~/.ssh/authorized_keys`。

确认结果：执行 `ssh user@remote-host` 后无需输入密码，能直接进入远程主机 shell。

### 3.3 使用 Remote Development 打开 Isaac ROS workspace

推荐使用 PyCharm Remote Development。PyCharm 后端运行在远程主机，macOS 只显示 UI，对大型 ROS 2 workspace 更稳定。

基本步骤：

1. 打开 PyCharm。
2. 选择 `Remote Development`。
3. 选择 `SSH`。
4. 填写远程主机地址、用户名、SSH key。
5. 选择远程目录：`${ISAAC_ROS_WS}`，例如 `/home/user/workspaces/isaac_ros-dev`。
6. 等待 PyCharm 在远程主机安装 IDE backend。

打开后，在 PyCharm Terminal 中验证当前目录和环境：

```bash
pwd
cd $ISAAC_ROS_WS
isaac-ros activate
```

确认结果：PyCharm Terminal 位于远程主机，`isaac-ros activate` 能进入 Isaac ROS Docker 开发环境。

可选方式：`SSH Interpreter + Deployment`，适合小型 Python 脚本。本文主线不采用该方式；SSH Interpreter 选择的是远程宿主机 Python，而 Isaac ROS 节点运行在容器内，两者环境可能不一致。

### 3.4 确认运行方式和解释器策略

Isaac ROS 相关命令统一从 PyCharm Terminal 进入 Docker 开发环境后执行：

```bash
cd $ISAAC_ROS_WS
isaac-ros activate
```

进入容器后验证：

```bash
echo $ROS_DISTRO
ros2 --help
```

构建过当前 workspace 后，再加载 workspace 环境：

```bash
source ${ISAAC_ROS_WS}/install/setup.bash
```

`echo $ROS_DISTRO` 能输出 ROS 发行版，`ros2 --help` 能输出帮助信息，构建后的 package 可以在 source workspace 后被 `ros2 run` 或 `ros2 launch` 找到。

PyCharm 的 Python Interpreter 可以先选择远程宿主机 Python，用于索引和基础补全；真正运行 Isaac ROS 节点、`colcon build`、`ros2 run`、`ros2 launch` 时，以 PyCharm Terminal 中的 `isaac-ros activate` 环境为准。

### 3.5 配置索引和排除目录

在 Project 视图中，把这些目录标记为 Sources Root：

- `${ISAAC_ROS_WS}/src`
- 自己维护的 ROS 2 package 目录
- 生成的 Python package 源码目录

同时排除这些目录：

- `build/`
- `install/`
- `log/`
- `.cache/`
- rosbag 数据目录
- 模型权重目录

Project 视图中源码目录能正常索引，`build/`、`install/`、`log/` 和大数据目录不会参与索引。Isaac ROS workspace 经常包含 rosbag、模型、TensorRT engine 和构建缓存，不排除会明显拖慢 PyCharm。

## 4. Python 节点远程调试

调试原则：节点仍在 Isaac ROS 容器中用 `ros2 run` 或 `ros2 launch` 启动，PyCharm 只接收 debug 连接。

### 4.1 配置 PyCharm Debug Server

在 PyCharm 中创建 `Python Debug Server` 配置：

1. 打开 `Run | Edit Configurations`。
2. 新建 `Python Debug Server`。
3. 端口填写 `5678`。
4. 配置 path mappings：容器内代码路径映射到 PyCharm 打开的 workspace 路径。
5. 启动这个 debug server。

确认结果：PyCharm 进入等待连接状态，端口为 `5678`。

### 4.2 确认容器能访问 Debug Server

使用 Remote Development 时，PyCharm 后端在远程主机上，Debug Server 也在远程主机侧。Isaac ROS 容器通常使用 host 网络，节点可以直接连接：

```text
127.0.0.1:5678
```

如果你使用的是 macOS 本地 PyCharm，而不是 Remote Development，需要从 macOS 另开一个终端建立反向隧道：

```bash
ssh -N -R 5678:127.0.0.1:5678 user@remote-host
```

保持这个 SSH 进程不退出。远程侧访问 `127.0.0.1:5678` 时，会转发到 macOS 上的 PyCharm Debug Server。

### 4.3 在 Isaac ROS 容器内安装调试包

在 PyCharm Terminal 中进入容器：

```bash
cd $ISAAC_ROS_WS
isaac-ros activate
```

安装调试包：

```bash
python3 -m pip install pydevd-pycharm
```

如果容器重建或清理过，需要重新安装。

### 4.4 在节点中接入调试器

在需要调试的 Python 节点入口附近临时加入：

```python
import pydevd_pycharm

pydevd_pycharm.settrace(
    "127.0.0.1",
    port=5678,
    stdoutToServer=True,
    stderrToServer=True,
    suspend=False,
)
```

如果容器不是 host 网络，把 `127.0.0.1` 替换成容器能访问到的远程主机地址。

启动节点：

```bash
source ${ISAAC_ROS_WS}/install/setup.bash
ros2 run py_hello hello_node
```

确认结果：节点启动后连接到 PyCharm，断点可命中，stdout/stderr 能在 Debug 窗口看到。

调试完成后，删除 `settrace` 代码，或用环境变量保护，避免提交到生产代码。

## 5. ROS 图形工具怎么处理

macOS 上直接运行远程 RViz 稳定性和交互体验都较差。建议按优先级选择：

1. 在远程 Linux 桌面上运行 RViz。
2. 使用 Foxglove 通过网络查看 ROS 2 topic。
3. 使用 XQuartz / X11 forwarding，只作为临时方案。

如果只是看 topic、service、node 和日志，优先用命令行：

```bash
ros2 node list
ros2 topic list
ros2 topic echo /topic_name
ros2 service list
ros2 bag record /topic_name
```

## 6. 常见问题

### 6.1 PyCharm 能连远程主机，但运行节点失败

先确认你是在 Isaac ROS 容器里运行：

```bash
isaac-ros activate
```

再确认 workspace 环境已经 source：

```bash
source ${ISAAC_ROS_WS}/install/setup.bash
```

### 6.2 `add-apt-repository universe` 触发 Docker 源握手失败

安装 Isaac ROS 时，官方步骤里会执行：

```bash
sudo add-apt-repository universe
```

这个命令本身只是启用 Ubuntu 的 `universe` 仓库，但它通常会顺带触发一次 `apt update`。如果远程服务器在国内网络环境下访问 Docker 官方源受限，可能出现类似错误：

```text
Err:2 https://download.docker.com/linux/ubuntu noble InRelease
  Could not handshake: Error in the pull function.
W: Failed to fetch https://download.docker.com/linux/ubuntu/dists/noble/InRelease
```

这不是 Isaac ROS 或 Ubuntu `universe` 仓库本身的问题，而是远程服务器访问 `download.docker.com` 失败。可选处理方式有两种：

1. 在远程服务器上直接使用可访问外网的 VPN 或代理。
2. 通过 SSH 反向隧道，让远程服务器临时使用 macOS 客户端上的 VPN 代理。

如果 macOS 本地有 HTTP 代理，例如 `127.0.0.1:7890`，可以从 macOS 发起反向隧道：

```bash
ssh -N -R 7890:127.0.0.1:7890 user@remote-host
```

然后在远程服务器上临时给 APT 配置代理：

```bash
sudo tee /etc/apt/apt.conf.d/99proxy >/dev/null <<'EOF'
Acquire::http::Proxy "http://127.0.0.1:7890";
Acquire::https::Proxy "http://127.0.0.1:7890";
EOF

sudo apt update
```

安装完成后可以删除临时代理配置：

```bash
sudo rm /etc/apt/apt.conf.d/99proxy
```

APT 需要 HTTP 代理地址。如果 macOS 客户端只有 SOCKS5 代理，先转换成 HTTP 代理，或直接使用服务器端 VPN。

### 6.3 PyCharm 可以索引，但提示 import 不存在

这通常是解释器与实际运行环境不一致。PyCharm 可能使用远程主机 Python，但节点实际运行在 Isaac ROS 容器内。先确认缺失依赖是否只存在于容器里，再决定是否需要调整解释器或运行方式。

### 6.4 文件同步后容器里看不到

Isaac ROS Docker 模式会把 `${ISAAC_ROS_WS}` 挂载到容器中的 `/workspaces/isaac_ros-dev`。PyCharm 打开的远程目录必须是宿主机上的 `${ISAAC_ROS_WS}`。

### 6.5 `colcon build` 很慢

优先排除 PyCharm 索引目录，并使用：

```bash
colcon build --symlink-install --packages-select your_package
```

大型 Isaac ROS 包不建议每次全量构建。

### 6.6 ROS 2 多机通信不通

先检查三件事：

```bash
echo $ROS_DOMAIN_ID
hostname -I
ros2 topic list
```

多机通信时，macOS、远程主机、机器人控制器和容器网络可能不在同一个广播域。调试阶段先让 ROS 2 节点都在远程主机或同一个容器网络内运行，减少变量。

## 7. 最小可用清单

搭建完成后，至少应满足：

- macOS 可以 SSH 免密登录远程主机。
- PyCharm Remote Development 能打开 `${ISAAC_ROS_WS}`。
- PyCharm Terminal 中可以执行 `isaac-ros activate`。
- 容器中可以执行 `colcon build --symlink-install`。
- 容器中可以执行 `ros2 run` 或 `ros2 launch`。
- PyCharm 排除了 `build/`、`install/`、`log/` 和大数据目录。
- Python 节点需要断点时，可以通过 Debug Server 或 SSH 端口转发接回 PyCharm。
