---
title: "ROS 2 Docker 双宿主机通信指南：网络检查与 Topic 双向验证"
date: 2026-08-03T10:00:00+08:00
summary: "用三个步骤完成两台宿主机上的 ROS 2 Docker 容器通信：检查网络、启动容器，并验证 /cross_server_test 的双向收发。"
tags: [ros2, docker, dds, network, robot, embodied-ai]
categories: [embodied-ai]
draft: false
---

# ROS 2 Docker 双宿主机通信指南：网络检查与 Topic 双向验证

本文只做一次最小通信验证。请按顺序执行，不要跳过成功判断。

| 项目 | 宿主机 1 | 宿主机 2 |
| --- | --- | --- |
| IP 地址 | `10.1.252.118` | `10.1.252.121` |
| 容器名 | `ros2-host-1` | `ros2-host-2` |
| 镜像 | `phys-ros:ros-base` | `phys-ros:ros-base` |
| ROS 2 | Jazzy | Jazzy |
| ROS Domain | `0` | `0` |
| 验证 Topic | `/cross_server_test` | `/cross_server_test` |

文中的命令在对应宿主机终端执行；明确写出“容器内”时，才在容器中执行。

## 1. 检查两个宿主机网络

在宿主机 1（`10.1.252.118`）执行：

```bash
ip -4 -br addr
ping -c 4 10.1.252.121
```

成功条件：本机包含 `10.1.252.118`，并看到：

```text
4 packets transmitted, 4 received, 0% packet loss
```

在宿主机 2（`10.1.252.121`）执行：

```bash
ip -4 -br addr
ping -c 4 10.1.252.118
```

成功条件：本机包含 `10.1.252.121`，并看到：

```text
4 packets transmitted, 4 received, 0% packet loss
```

任一方向不是 `0% packet loss` 时，不要继续。分别执行下面的命令检查路由：

```bash
# 宿主机 1
ip route get 10.1.252.121

# 宿主机 2
ip route get 10.1.252.118
```

## 2. 在两个宿主机上启动 ROS 2 镜像

在宿主机 1 执行：

```bash
docker run -d \
  --name ros2-host-1 \
  --restart unless-stopped \
  --network host \
  -e ROS_DOMAIN_ID=0 \
  -e ROS_LOCALHOST_ONLY=0 \
  --entrypoint bash \
  phys-ros:ros-base \
  -lc 'source /opt/ros/jazzy/setup.bash; exec sleep infinity'
```

在宿主机 2 执行：

```bash
docker run -d \
  --name ros2-host-2 \
  --restart unless-stopped \
  --network host \
  -e ROS_DOMAIN_ID=0 \
  -e ROS_LOCALHOST_ONLY=0 \
  --entrypoint bash \
  phys-ros:ros-base \
  -lc 'source /opt/ros/jazzy/setup.bash; exec sleep infinity'
```

## 3. 分别进入两个镜像并验证 Topic 收发

打开两个终端。

终端 1 在宿主机 1 执行：

```bash
docker exec -it ros2-host-1 bash
source /opt/ros/jazzy/setup.bash
```

终端 2 在宿主机 2 执行：

```bash
docker exec -it ros2-host-2 bash
source /opt/ros/jazzy/setup.bash
```

先在终端 2 执行订阅：

```bash
timeout 15s ros2 topic echo \
  /cross_server_test \
  std_msgs/msg/String \
  --once
```

再在终端 1 执行发布：

```bash
timeout 10s ros2 topic pub \
  -r 2 \
  /cross_server_test \
  std_msgs/msg/String \
  "{data: hello-from-host-1}"
```

成功条件：终端 2 输出：

```text
data: hello-from-host-1
```

先在终端 1 执行订阅：

```bash
timeout 15s ros2 topic echo \
  /cross_server_test \
  std_msgs/msg/String \
  --once
```

再在终端 2 执行发布：

```bash
timeout 10s ros2 topic pub \
  -r 2 \
  /cross_server_test \
  std_msgs/msg/String \
  "{data: hello-from-host-2}"
```

成功条件：终端 1 输出：

```text
data: hello-from-host-2
```