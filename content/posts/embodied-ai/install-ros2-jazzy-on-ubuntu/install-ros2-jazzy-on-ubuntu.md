---
title: "在 Ubuntu 24.04 中安装 ROS 2 Jazzy"
date: 2026-07-20T10:00:00+08:00
summary: "从系统版本检查、软件源配置到 Desktop/Base 安装和 Talker/Listener 验证，完整介绍如何在 Ubuntu 24.04 中安装 ROS 2 Jazzy。"
tags: [ros2, jazzy, ubuntu, robot, embodied-ai]
categories: [embodied-ai]
draft: false
---

# 在 Ubuntu 24.04 中安装 ROS 2 Jazzy

ROS 2 Jazzy Jalisco 是一个长期支持版本，官方为 Ubuntu 24.04（Noble Numbat）的 `amd64` 和 `arm64` 架构提供二进制软件包。对于机器人、具身智能和 Isaac ROS 开发环境，直接通过 Ubuntu 的 APT 包管理器安装，通常是最简单、也最容易维护的方式。

本文从一台新安装的 Ubuntu 系统出发，完成 ROS 2 Jazzy 的安装、环境配置和基本通信测试。

> 本文只适用于 Ubuntu 24.04。Ubuntu 22.04 对应的官方 ROS 2 长期支持版本是 Humble，不要在 22.04 中直接套用本文的软件源和安装命令。

## 1. 检查系统版本和架构

先确认当前系统版本：

```bash
lsb_release -a
```

输出中应包含：

```text
Description: Ubuntu 24.04 LTS
Codename:    noble
```

再检查 CPU 架构：

```bash
dpkg --print-architecture
```

ROS 2 Jazzy 在 Ubuntu 24.04 上正式支持：

- `amd64`：常见的 Intel、AMD 台式机和服务器；
- `arm64`：常见的 ARM 开发板和嵌入式设备。

如果系统不是 Ubuntu 24.04，建议先选择与当前 Ubuntu 版本匹配的 ROS 2 发行版，而不是强行混用软件源。

## 2. 配置 UTF-8 Locale

ROS 2 要求系统使用支持 UTF-8 的 Locale。Ubuntu Desktop 通常已经配置好，但精简系统、服务器和容器环境可能仍然使用 `POSIX` 或 `C`。

先检查当前配置：

```bash
locale
```

如果输出中没有 UTF-8，可以执行：

```bash
sudo apt update
sudo apt install locales -y
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```

再次运行 `locale`，确认 `LANG` 和 `LC_ALL` 已经使用 `en_US.UTF-8`。

这里选择英文 Locale 只是为了和 ROS 2 官方测试环境保持一致，不会影响 Ubuntu 桌面的中文输入和显示。

## 3. 启用 Ubuntu Universe 软件源

ROS 2 的部分依赖来自 Ubuntu Universe 软件源。安装相关工具并启用该软件源：

```bash
sudo apt install software-properties-common -y
sudo add-apt-repository universe
```

如果提示确认，按 Enter 继续。

## 4. 添加 ROS 2 官方 APT 软件源

ROS 2 官方现在推荐安装 `ros2-apt-source` 软件包。它会为系统配置 ROS 2 软件源和签名密钥；以后软件源配置发生变化时，也可以通过软件包升级自动更新。相比手动下载 GPG Key 并创建 `.list` 文件，这种方式更不容易留下过期配置。

先安装 `curl`：

```bash
sudo apt update
sudo apt install curl -y
```

获取 `ros-apt-source` 的最新版本号：

```bash
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}')
```

下载与当前 Ubuntu 版本匹配的软件包：

```bash
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
```

安装软件源配置：

```bash
sudo dpkg -i /tmp/ros2-apt-source.deb
```

完成后更新软件包索引：

```bash
sudo apt update
```

## 5. 更新 Ubuntu 系统

ROS 2 二进制包基于持续更新的 Ubuntu 软件包构建。为了避免系统中的旧依赖与 ROS 2 软件包冲突，安装前建议先升级系统：

```bash
sudo apt upgrade -y
```

如果升级了内核、显卡驱动或其他底层组件，最好先重启系统，再继续安装 ROS 2。

## 6. 选择 Desktop 或 ROS-Base

ROS 2 Jazzy 提供两种常用的安装组合。

### Desktop：适合开发电脑

Desktop 版本包含 ROS 2 核心组件、RViz、示例和教程。第一次学习 ROS 2，或者需要图形化调试机器人时，推荐安装它：

```bash
sudo apt install ros-jazzy-desktop -y
```

### ROS-Base：适合服务器和机器人本体

ROS-Base 只包含通信库、消息包和命令行工具，不包含 RViz 等 GUI 工具，更适合无桌面的服务器、容器和机器人控制器：

```bash
sudo apt install ros-jazzy-ros-base -y
```

二者选择一个即可。已经安装 ROS-Base 的系统，以后仍然可以安装 `ros-jazzy-desktop` 补齐桌面工具。

如果需要创建和编译自己的 ROS 2 工作空间，还建议安装开发工具：

```bash
sudo apt install ros-dev-tools -y
```

## 7. 加载 ROS 2 环境

安装完成后，当前终端还不知道 ROS 2 命令和软件包的位置，需要先加载环境脚本：

```bash
source /opt/ros/jazzy/setup.bash
```

检查是否安装成功：

```bash
ros2 --help
printenv ROS_DISTRO
```

第二条命令应该输出：

```text
jazzy
```

为了避免每次打开 Bash 都手动执行 `source`，可以把它加入 `~/.bashrc`：

```bash
echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

如果使用 Zsh，则改为：

```zsh
echo "source /opt/ros/jazzy/setup.zsh" >> ~/.zshrc
source ~/.zshrc
```

不要同时在多个 Shell 配置文件中重复加载不同 ROS 2 发行版，否则容易出现环境变量相互覆盖的问题。

## 8. 用 Talker 和 Listener 验证安装

只看到 `ros2 --help` 还不够。下面通过两个示例节点验证 C++、Python 和 DDS 通信是否都能正常工作。

打开第一个终端，运行 C++ Talker：

```bash
source /opt/ros/jazzy/setup.bash
ros2 run demo_nodes_cpp talker
```

正常情况下，它会持续输出：

```text
Publishing: 'Hello World: 1'
Publishing: 'Hello World: 2'
```

再打开第二个终端，运行 Python Listener：

```bash
source /opt/ros/jazzy/setup.bash
ros2 run demo_nodes_py listener
```

Listener 应该可以收到 Talker 发布的消息：

```text
I heard: [Hello World: 1]
I heard: [Hello World: 2]
```

这说明以下组件已经正常工作：

- ROS 2 命令行工具；
- C++ 客户端库 `rclcpp`；
- Python 客户端库 `rclpy`；
- 默认的 Fast DDS 中间件；
- ROS 2 节点发现、Topic 发布和订阅。

使用 `Ctrl+C` 可以停止两个示例节点。

## 9. 常见问题

### `ros2: command not found`

通常是当前终端没有加载 ROS 2 环境。执行：

```bash
source /opt/ros/jazzy/setup.bash
```

如果 `/opt/ros/jazzy` 不存在，说明 ROS 2 软件包没有安装成功，需要回到安装步骤检查 APT 的错误信息。

### 找不到 `ros-jazzy-desktop`

先确认 Ubuntu 代号是 `noble`：

```bash
. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}}
```

然后重新安装 `ros2-apt-source` 并执行：

```bash
sudo apt update
apt-cache policy ros-jazzy-desktop
```

如果仍然没有候选版本，重点检查网络、系统时间以及 `/etc/apt/sources.list.d/` 下是否残留了旧的 ROS 软件源配置。

### 安装 `ros-dev-tools` 时依赖冲突

部分 Ubuntu 24.04 系统只启用了基础 `noble` 仓库。检查：

```bash
grep Suites /etc/apt/sources.list.d/ubuntu.sources
```

正常情况下，`Suites` 应至少包含：

```text
Suites: noble noble-updates noble-backports
```

如果缺少 `noble-updates` 或 `noble-backports`，先备份并修正 `ubuntu.sources`，再执行：

```bash
sudo apt clean
sudo apt update
sudo apt full-upgrade -y
sudo apt install ros-dev-tools -y
```

### 两个终端中的节点互相发现不了

先确认两个终端都加载了 Jazzy，并且使用相同的 Domain ID：

```bash
printenv ROS_DISTRO
printenv ROS_DOMAIN_ID
```

如果设置过 `ROS_LOCALHOST_ONLY`，也要确认两个终端的值一致。在容器、虚拟机或多机通信场景中，还需要检查主机网络、防火墙、组播支持和 DDS 配置。

## 10. 安装后的下一步

如果准备开始开发自己的 ROS 2 包，可以初始化 `rosdep`：

```bash
sudo rosdep init
rosdep update
```

然后创建一个工作空间：

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
colcon build
source install/setup.bash
```

此后每个工作空间通常会有两层环境：先加载 `/opt/ros/jazzy/setup.bash` 提供的 ROS 2 基础环境，再加载工作空间自己的 `install/setup.bash`，让本地开发的软件包覆盖或扩展基础安装。

## 参考资料

- [ROS 2 Jazzy：Ubuntu deb packages](https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html)
- [ROS 2 Jazzy Jalisco 发布说明与支持平台](https://docs.ros.org/en/jazzy/Releases/Release-Jazzy-Jalisco.html)
- [ROS 2 Jazzy Tutorials](https://docs.ros.org/en/jazzy/Tutorials.html)
