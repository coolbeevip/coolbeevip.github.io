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

### 1.1 验证两台宿主机的 ROS 2 组播

ROS 2 使用的 DDS 发现机制主要依赖 UDP 组播。`ping` 成功只能说明单播网络可达，不能证明 DDS 组播能够正常通过。使用 ROS 2 自带的组播工具做一次端到端验证，这是继续后续步骤前的必要检查。

在宿主机 1（`10.1.252.118`）执行接收：

```bash
ros2 multicast receive
```

保持该终端等待，然后在宿主机 2（`10.1.252.121`）执行发送：

```bash
ros2 multicast send
```

成功条件：宿主机 1 立即输出类似下面的信息：

```text
Received from 10.1.252.121:43751: 'Hello World!'
```

然后交换两台宿主机的角色，再执行一次，确认两个方向都能收到组播消息。

如果 ROS 2 只安装在 `phys-ros:ros-base` 镜像中，请先按第 2 节启动容器，再分别进入两个容器执行上述命令；容器必须使用本指南中的 `--network host` 配置。

任一方向未收到消息时，不要继续。此时再检查路由、宿主机防火墙，以及交换机或云网络安全策略是否阻隔了 UDP 组播流量。

### 1.2 组播不可用时使用 Fast DDS Discovery Server

如果网络设备或防火墙不支持 UDP 组播，可以使用 Fast DDS Discovery Server 提供单播发现。下面以宿主机 2（`10.1.252.121`）作为 Discovery Server，端口使用 `11811`。

先按第 2 节启动两个容器，并分别进入容器。然后在宿主机 2 的容器内启动 Discovery Server：

```bash
source /opt/ros/jazzy/setup.bash
nohup fastdds discovery -i 0 -l 0.0.0.0 -p 11811 \
  > /tmp/fastdds-discovery.log 2>&1 &
echo $! > /tmp/fastdds-discovery.pid
```

检查服务是否仍在运行：

```bash
cat /tmp/fastdds-discovery.pid
ps -p "$(cat /tmp/fastdds-discovery.pid)"
tail -f /tmp/fastdds-discovery.log
```

保持 Discovery Server 运行，在宿主机 1 和宿主机 2 的容器内分别检查到发现服务 UDP 端口的连通性：

```bash
nc -uvz -w 3 10.1.252.121 11811
```

如果环境中没有安装 `nc`，可以使用 Python 3 检查：

```bash
python3 -c "import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(2); s.sendto(b'', ('10.1.252.121', 11811)); exec('try:\n s.recvfrom(1024); print(\"open (received response)\")\nexcept socket.timeout:\n print(\"open (no response, but no ICMP error)\")\nexcept:\n print(\"closed/filtered\")')"
```

输出 `open (received response)` 或 `open (no response, but no ICMP error)` 表示没有检测到端口不可达；输出 `closed/filtered` 时，应先排查网络和防火墙配置。

使用 `nc` 检查成功时，通常会输出类似信息：

```text
Connection to 10.1.252.121 11811 port [udp/*] succeeded!
```

如果任一容器报告 `timed out`、`No route to host` 或 `Connection refused`，先检查容器是否使用 `--network host`、到 `10.1.252.121` 的路由，以及宿主机 2 是否已放行 `11811/UDP`，不要继续 Topic 验证。

注意：UDP 没有连接握手，不同版本的 `nc` 和不同操作系统的 Python Socket 对 UDP 探测结果的判断也可能不同。上述检查成功表示没有检测到不可达错误，不能单独证明 Discovery Server 已正确处理请求；还需要结合 Discovery Server 进程和日志，以及后续的 Topic 双向验证确认。

在两个容器中分别打开新的终端，并设置相同的 Discovery Server 地址：

```bash
source /opt/ros/jazzy/setup.bash
export ROS_DOMAIN_ID=0
export ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET
export ROS_DISCOVERY_SERVER=10.1.252.121:11811
```

如果环境没有明确使用 Fast DDS，再额外设置：

```bash
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
```

之后继续执行第 3 节的 Topic 双向验证。此时两个 ROS 2 节点通过宿主机 2 的 `11811` 端口完成发现，不再依赖两台宿主机之间的 DDS 组播发现。

成功条件：在设置上述环境变量后，宿主机 1 和宿主机 2 仍能分别收到对方发布的 `/cross_server_test` 消息。

注意：`ROS_DISCOVERY_SERVER` 只对 Fast DDS 生效，因此必须确认当前 RMW 实现是 `rmw_fastrtps_cpp`；如果已经通过环境或系统默认配置使用 Fast DDS，就不需要重复设置 `RMW_IMPLEMENTATION`。Discovery Server 所在宿主机的 `11811/UDP` 端口必须允许宿主机 1 访问；该单个 Server 发生故障时，客户端之间将无法继续完成新的发现。

完成所有验证后，关闭 Discovery Server：

```bash
kill "$(cat /tmp/fastdds-discovery.pid)"
```

## 2. 在两个宿主机上启动 ROS 2 镜像

在宿主机 1 执行：

```bash
docker run -d \
  --name ros2-host-1 \
  --restart unless-stopped \
  --network host \
  -e ROS_DOMAIN_ID=0 \
  -e ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET \
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
  -e ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET \
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
