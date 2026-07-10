---
title: "在 Isaac ROS 容器环境中安装 Orbbec DaBai 摄像头驱动"
date: 2026-07-08T10:00:00+08:00
summary: "在已有 Isaac ROS 环境中接入 Orbbec DaBai：先在 Ubuntu 主机确认设备，再到容器内安装 Orbbec ROS 2 驱动、启动节点并检查图像 topic。"
tags: [isaac-ros, ros2, ubuntu, camera, embodied-ai, nvidia]
categories: [embodied-ai]
draft: false
---

# 在 Isaac ROS 容器环境中安装 Orbbec DaBai 摄像头驱动

本文记录在 Isaac ROS 容器里接入 Orbbec DaBai 的过程。前半部分确认主机能识别摄像头，后半部分在容器里安装 Orbbec ROS 2 驱动、启动节点，并用 RViz2 看图像。

## 1. 环境准备

在 Ubuntu 主机和 Isaac ROS 容器中安装以下工具：

```bash
sudo apt update
sudo apt install -y usbutils v4l-utils ffmpeg
```

这些包对应的常用命令：

| 包           | 命令         | 用途                                        |
|-------------|------------|-------------------------------------------|
| `usbutils`  | `lsusb`    | 查看 USB 摄像头、Orbbec DaBai 是否被 USB 总线识别 |
| `v4l-utils` | `v4l2-ctl` | 查看 `/dev/video*`、摄像头格式、分辨率、帧率             |
| `ffmpeg`    | `ffmpeg` / `ffplay` | 抓取或预览 `/dev/video*` 图像，确认摄像头是否能出画面 |

## 2. 在 Ubuntu 主机上检测摄像头

这一部分在主机终端执行。

### 2.1 检查 USB 设备是否枚举

普通 USB 摄像头和 Orbbec DaBai 都应该先能在 USB 层看到。

```bash
lsusb
```

### 2.2 检查是否生成 `/dev/video*`

UVC 摄像头和很多 RGB-D 摄像头会暴露 V4L2 视频节点：

```bash
ls -l /dev/video*
```

更清楚的方式是按设备列出：

```bash
v4l2-ctl --list-devices
```

查看某个设备支持的分辨率、像素格式和帧率：

```bash
v4l2-ctl -d /dev/video0 --list-formats-ext
```

- 有 `/dev/video*`：说明内核已经暴露视频设备。
- 没有 `/dev/video*`，但 `lsusb` 能看到：可能是权限问题、驱动未绑定，或该相机本来不走 V4L2。
- 有多个 `/dev/video*`：不要默认 `/dev/video0` 就是目标相机，要用 `v4l2-ctl --list-devices` 对应设备名。

### 2.3 检查设备权限

查看当前用户是否能访问视频设备：

```bash
ls -l /dev/video0
groups
```

典型视频设备权限类似：

```text
crw-rw----+ 1 root video ... /dev/video0
```

- 当前用户在 `video` 组里：通常可以访问。
- 不在 `video` 组里：主机上直接运行 ROS 2 driver 可能会权限失败。

### 2.4 对普通 USB/UVC 摄像头做最小图像验证

可以用 `ffplay` 直接打开 `/dev/video0`。这一步只验证主机摄像头是否能出图。

```bash
ffplay /dev/video0
```

或者指定参数，例如 MJPEG：

```bash
ffplay -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 30 /dev/video0
```

`input_format`、`video_size` 和 `framerate` 必须来自 `v4l2-ctl --list-formats-ext` 的实际输出。

## 3. 在 Isaac ROS 容器环境中安装摄像头驱动

在 Ubuntu 主机上执行以下命令，进入 Isaac ROS 容器：

```bash
cd ${ISAAC_ROS_WS}
isaac-ros activate
```

以下步骤都在 Isaac ROS 容器内执行。

### 3.1 检测容器内能否看到摄像头设备

```bash
lsusb
lsusb | grep -Ei 'orbbec'
```

再检查 USB bus 是否被透传进容器：

```bash
ls -l /dev/bus/usb
```

如果容器里 `lsusb` 看不到 Orbbec 设备，但主机能看到，问题在容器设备透传。此时优先检查 Isaac ROS CLI / Docker 启动配置是否把 USB 设备传入容器。

### 3.2 检测容器内摄像头是否可读

先看容器里是否有 V4L2 视频节点：

```bash
ls -l /dev/video*
v4l2-ctl --list-devices
```

如果 DaBai 暴露了 RGB 视频节点，可以继续查看格式：

```bash
v4l2-ctl -d /dev/video0 --list-formats-ext
```

在容器里，优先用“抓一帧”的方式检测摄像头是否可读。这样不依赖 GUI，也不会长时间占用摄像头。

如果摄像头支持 MJPEG，抓一帧保存成 JPEG：

```bash
ffmpeg -i /dev/video0 -frames:v 1 /tmp/orbbec-dabai-frame.jpg
```

如果成功生成图片，说明摄像头在容器里可读。

### 3.3 安装 Orbbec DaBai ROS 2 驱动

> 项目里最好把 Orbbec ROS 2 wrapper 预装到镜像里，避免每次启动容器后手动安装。

先确认容器里的 ROS 2 发行版：

```bash
echo ${ROS_DISTRO}
```

本文实测环境是 ROS 2 Jazzy。2026-07-09 在 Ubuntu 24.04 Noble / ROS 2 Jazzy 环境中，ROS 官方 apt 仓库已经提供 Orbbec 二进制包：

```bash
apt-cache policy ros-${ROS_DISTRO}-orbbec-camera ros-${ROS_DISTRO}-orbbec-description
```

实测输出里可以看到：

```text
ros-jazzy-orbbec-camera:
  Candidate: 2.7.6-1noble.20260615.151450
ros-jazzy-orbbec-description:
  Candidate: 2.7.6-1noble.20260303.233722
```

如果你的环境也能查到候选版本，优先用 apt 安装：

```bash
sudo apt update
sudo apt install -y \
  ros-${ROS_DISTRO}-orbbec-camera \
  ros-${ROS_DISTRO}-orbbec-description
```

先使用以下命令检测是否已经安装过 `orbbec_camera` 包：

```bash
ros2 pkg list | grep -E '^orbbec_camera$'
```

正常情况下会看到 `orbbec_camera` 和 `orbbec_camera_msgs`。再确认 launch 文件存在：

```bash
ls $(ros2 pkg prefix orbbec_camera)/share/orbbec_camera/launch
```

如果 apt 仓库里没有对应包，或者你需要修改驱动源码，再从源码编译安装。

- 驱动源码不要直接放在 `${ISAAC_ROS_WS}` 根目录。
- 如果 `${ISAAC_ROS_WS}` 里已经有项目，把第三方驱动放到 `src/third_party/`。`git clone` 只会新增 `OrbbecSDK_ROS2` 目录；除非已有同名目录，否则不会覆盖项目包。

推荐目录结构：

```text
${ISAAC_ROS_WS}/
├── src/
│   ├── your_robot_project/
│   └── third_party/
│       └── OrbbecSDK_ROS2/
└── install/
```

进入 workspace：

```bash
cd ${ISAAC_ROS_WS}
mkdir -p src/third_party
```

拉取 Orbbec ROS 2 wrapper。官方仓库的 `main` 分支是 SDK V1 版本，`v2-main` 分支是 SDK V2 版本。DaBai 属于 legacy OpenNI 协议设备，应使用 V1 版本。

```bash
cd ${ISAAC_ROS_WS}/src/third_party
git clone -b main https://github.com/orbbec/OrbbecSDK_ROS2.git
```

安装依赖并构建：

```bash
cd ${ISAAC_ROS_WS}
rosdep update
rosdep install --from-paths src/third_party/OrbbecSDK_ROS2 --ignore-src -r -y
colcon build \
  --symlink-install \
  --packages-up-to orbbec_camera \
  --event-handlers console_direct+
```

重新加载 workspace：

```bash
source install/setup.bash
```

如果不想每次进入容器后都手动执行这句，可以把它写入容器用户的 `~/.bashrc`。先确认 `${ISAAC_ROS_WS}/install/setup.bash` 已经存在，再执行：

```bash
grep -qxF "source ${ISAAC_ROS_WS}/install/setup.bash" ~/.bashrc || \
  echo "source ${ISAAC_ROS_WS}/install/setup.bash" >> ~/.bashrc
```

重新打开一个容器终端，或手动加载一次：

```bash
source ~/.bashrc
```

之后再进入容器时，`orbbec_camera` 会自动出现在 ROS 2 环境里，不需要每次手动 `source install/setup.bash`。

再次确认驱动存在：

```bash
ros2 pkg list | grep -E '^orbbec_camera$'
```

执行以下命令列出 Orbbec 相机设备：

```bash
ros2 run orbbec_camera list_devices_node
```

实测双 DaBai DC1 会返回两个序列号：

```text
[list_device_node]: serial: CC1N16200F0
[list_device_node]: usb port: 3-3.4
[list_device_node]: serial: CC1WC5201FV
[list_device_node]: usb port: 3-1.2.4
```

如果命令没有返回设备，打开 debug 日志再执行一次：

```bash
ros2 run orbbec_camera list_devices_node -- --enabled_sdk_log --sdk_log_level debug
```

如果提示 `usbEnumerator createUsbDevice failed`，可以临时执行：

```bash
sudo chmod -R a+rw /dev/bus/usb
```

这是临时办法，容器重启或重新插拔摄像头后都会失效。

更稳妥的做法是配置 udev 规则：

1. 查找规则文件。
2. 找到类似 `99-sensor-libusb.rules` 或 `99-obsensor-libusb.rules` 的文件。
3. 在宿主机上复制到 `/etc/udev/rules.d/` 目录。

apt 安装时可以这样找：

```bash
find /opt/ros/${ROS_DISTRO}/share -path "*orbbec*" -name "*.rules" -print
```

源码安装时可以这样找：

```bash
find ${ISAAC_ROS_WS}/src/third_party/OrbbecSDK_ROS2 -name "*.rules" -print
```

找到实际规则文件后复制，例如：

```bash
sudo cp /path/to/99-obsensor-libusb.rules /etc/udev/rules.d/
```

4. 重新加载并应用 udev 规则：

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

然后重新插拔摄像头。配置生效后，就不会再因为 USB 权限问题触发 `usbEnumerator createUsbDevice failed`。

### 3.4 启动 Orbbec DaBai ROS 2 节点

先查看当前 `orbbec_camera` 包实际提供了哪些 launch 文件：

```bash
ls $(ros2 pkg prefix orbbec_camera)/share/orbbec_camera/launch
```

如果提供 `dabai.launch.py`，优先使用：

```bash
ros2 launch orbbec_camera dabai.launch.py
```

连接两个 Orbbec DaBai 时，不要依赖 `/dev/video0`、`/dev/video1` 的顺序。建议这样做：

1. 先查两个相机的序列号。
2. 每个相机指定不同的 `camera_name`。
3. 调试时可以用两个终端分别启动；工程化时再写一个总 launch 文件。

先列出设备，记录两个相机的 serial number：

```bash
ros2 run orbbec_camera list_devices_node
```

实测输出中，两个 DaBai DC1 的序列号如下：

```text
[list_device_node]: serial: CC1N16200F0
[list_device_node]: usb port: 3-3.4
[list_device_node]: serial: CC1WC5201FV
[list_device_node]: usb port: 3-1.2.4
```

再查看你当前版本的 `dabai.launch.py` 支持哪些参数：

```bash
ros2 launch orbbec_camera dabai.launch.py --show-args
```

如果输出中包含 `camera_name` 和 `serial_number`，可以先用命令行方式调试。

方式 A：两个终端分别启动。

终端 1 启动顶部相机：

```bash
ros2 launch orbbec_camera dabai.launch.py \
  camera_name:=camera_top \
  serial_number:=CC1WC5201FV
```

终端 2 启动腕部相机：

```bash
ros2 launch orbbec_camera dabai.launch.py \
  camera_name:=camera_wrist \
  serial_number:=CC1N16200F0
```

这种方式适合调试：每个终端只看一个相机的日志，出错时更容易定位。两个相机都稳定后，再改成一个总 launch 文件。

方式 B：写一个项目 launch 文件统一启动。

可以新建一个项目 launch 文件，例如：

```text
${ISAAC_ROS_WS}/src/your_robot_bringup/launch/two_dabai.launch.py
```

内容如下，把 `SERIAL_TOP` 和 `SERIAL_WRIST` 换成实际序列号：

```python
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare


def dabai_launch(camera_name, serial_number):
    return IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            PathJoinSubstitution([
                FindPackageShare("orbbec_camera"),
                "launch",
                "dabai.launch.py",
            ])
        ),
        launch_arguments={
            "camera_name": camera_name,
            "serial_number": serial_number,
        }.items(),
    )


def generate_launch_description():
    return LaunchDescription([
        dabai_launch("camera_top", "CC1WC5201FV"),
        dabai_launch("camera_wrist", "CC1N16200F0"),
    ])
```

启动两个相机：

```bash
ros2 launch your_robot_bringup two_dabai.launch.py
```

两个相机会发布到不同 topic 前缀下：

```text
/camera_top/color/image_raw
/camera_top/color/camera_info
/camera_top/depth/image_raw
/camera_top/depth/camera_info
/camera_top/depth/points

/camera_wrist/color/image_raw
/camera_wrist/color/camera_info
/camera_wrist/depth/image_raw
/camera_wrist/depth/camera_info
/camera_wrist/depth/points
```

验证两个相机的 topic：

```bash
ros2 topic list | grep -E 'camera_top|camera_wrist'
ros2 topic hz /camera_top/color/image_raw
ros2 topic hz /camera_wrist/color/image_raw
```

如果 `dabai.launch.py --show-args` 里的序列号参数不叫 `serial_number`，以实际输出为准。物理相机用序列号绑定，ROS topic 用 `camera_name` 区分。

启动摄像头 driver 的终端需要保持运行。同一个摄像头不要重复启动多个 driver，否则可能出现 `device busy` 或 topic 间歇掉帧。

### 3.5 检测图像是否写入 ROS 2 topic

另开一个 Isaac ROS 容器终端，进入同一个环境：

```bash
isaac-ros activate
cd ${ISAAC_ROS_WS}
source install/setup.bash
```

先看节点是否存在：

```bash
ros2 node list
```

再列出摄像头相关 topic：

```bash
ros2 topic list | grep -Ei 'camera|color|depth|image|points|info'
```

Orbbec driver 的 topic 名称会随 launch 文件和参数变化，常见形式如下：

```text
/camera_top/color/image_raw
/camera_top/color/camera_info
/camera_top/depth/image_raw
/camera_top/depth/camera_info
/camera_top/depth/points

/camera_wrist/color/image_raw
/camera_wrist/color/camera_info
/camera_wrist/depth/image_raw
/camera_wrist/depth/camera_info
/camera_wrist/depth/points
```

确认图像 topic 的消息类型：

```bash
ros2 topic info /camera_top/color/image_raw
ros2 topic info /camera_top/depth/image_raw
ros2 topic info /camera_wrist/color/image_raw
ros2 topic info /camera_wrist/depth/image_raw
```

图像 topic 类型应为：

```text
sensor_msgs/msg/Image
```

确认相机内参 topic：

```bash
ros2 topic info /camera_top/color/camera_info
ros2 topic info /camera_top/depth/camera_info
ros2 topic info /camera_wrist/color/camera_info
ros2 topic info /camera_wrist/depth/camera_info
ros2 topic echo /camera_top/color/camera_info --once
```

内参 topic 类型应为：

```text
sensor_msgs/msg/CameraInfo
```

检查图像是否持续写入 topic：

```bash
ros2 topic hz /camera_top/color/image_raw
ros2 topic hz /camera_top/depth/image_raw
ros2 topic hz /camera_wrist/color/image_raw
ros2 topic hz /camera_wrist/depth/image_raw
```

如果实际 topic 名称不同，以 `ros2 topic list` 输出为准替换上面的路径。

这次实测的最低结果可以作为验收参考：

| Topic | Type | 实测图像格式 | 实测频率 |
|---|---|---|---|
| `/camera_top/color/image_raw` | `sensor_msgs/msg/Image` | `640x480`, `rgb8` | 约 3.7-6.7 Hz |
| `/camera_top/depth/image_raw` | `sensor_msgs/msg/Image` | `640x400`, `16UC1` | 约 30 Hz |
| `/camera_wrist/color/image_raw` | `sensor_msgs/msg/Image` | `640x480`, `rgb8` | 约 2-3 Hz |
| `/camera_wrist/depth/image_raw` | `sensor_msgs/msg/Image` | `640x400`, `16UC1` | 约 30 Hz |
| `/camera_top/color/camera_info` | `sensor_msgs/msg/CameraInfo` | `640x480` | 有 publisher |
| `/camera_top/depth/camera_info` | `sensor_msgs/msg/CameraInfo` | `640x400` | 有 publisher |
| `/camera_wrist/color/camera_info` | `sensor_msgs/msg/CameraInfo` | `640x480` | 有 publisher |
| `/camera_wrist/depth/camera_info` | `sensor_msgs/msg/CameraInfo` | `640x400` | 有 publisher |

实测 frame id 分别是：

```text
camera_top_color_optical_frame
camera_top_depth_optical_frame
camera_wrist_color_optical_frame
camera_wrist_depth_optical_frame
```

注意这次 `list_devices_node` 日志里两个设备都显示 `Connection: USB2.0`，`lsusb` 也能看到每个 DaBai 同时枚举出 `2bc5:0557 Dabai DC1` 和 `2bc5:0657 ORBBEC Depth Sensor`。在这个连接状态下，深度图稳定在约 30 Hz，但 RGB topic 明显低于 30 Hz。后续如果算法依赖高帧率 RGB，应先检查 USB 拓扑、Hub、线材、相机输出配置和是否被其他节点占用。

### 3.6 可视化确认图像

ROS 2 常用的可视化工具是 RViz2，命令是 `rviz2`。它可以查看图像、点云、TF、机器人模型和 Marker。

这里直接在 Isaac ROS 容器内运行 RViz2。

进入容器前，先在 Ubuntu 主机允许本地容器访问 X11 显示：

```bash
echo $DISPLAY
xhost +local:root
```

然后进入 Isaac ROS 容器：

```bash
isaac-ros activate
```

进入容器后，确认显示环境已传入：

```bash
echo $DISPLAY
ls -l /tmp/.X11-unix
```

如果 `DISPLAY` 为空，或 `/tmp/.X11-unix` 不存在，容器通常打不开 RViz2。这是 GUI 透传问题，不是摄像头 topic 问题。

设置 `XDG_RUNTIME_DIR`，避免 Qt/SDL 报 runtime dir 错误：

```bash
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p ${XDG_RUNTIME_DIR}
chmod 700 ${XDG_RUNTIME_DIR}
```

确认容器里已经能看到图像 topic：

```bash
ros2 topic list | grep -Ei 'camera|color|depth|image|points|info'
ros2 topic hz /camera_top/color/image_raw
```

检查容器里是否有 RViz2：

```bash
which rviz2
ros2 pkg list | grep -E '^rviz2$'
```

如果没有，安装：

```bash
sudo apt update
sudo apt install -y ros-${ROS_DISTRO}-rviz2
```

启动 RViz2：

```bash
QT_X11_NO_MITSHM=1 rviz2
```

如果 RViz2 打不开窗口，检查：

```bash
echo $DISPLAY
ls -l /tmp/.X11-unix
echo $XDG_RUNTIME_DIR
```

在 RViz2 里查看 DaBai 图像：

1. 点击左下角 `Add`。
2. 选择 `By topic`。
3. 选择 `/camera_top/color/image_raw` 或 `/camera_wrist/color/image_raw` 对应的 `Image`。
4. 如果要看深度图，选择 `/camera_top/depth/image_raw` 或 `/camera_wrist/depth/image_raw` 对应的 `Image`。
5. 如果驱动发布了点云，选择 `/camera_top/depth/points` 或 `/camera_wrist/depth/points` 对应的 `PointCloud2`。

如果 `PointCloud2` 显示报 TF 或 Fixed Frame 错误，先查点云 topic 的 `frame_id`：

```bash
ros2 topic echo /camera_top/depth/points --once --field header.frame_id
```

然后在 RViz2 左侧 `Global Options` 里把 `Fixed Frame` 设置成这个 frame id。常见值可能类似：

```text
camera_top_depth_optical_frame
camera_top_color_optical_frame
camera_wrist_depth_optical_frame
camera_wrist_color_optical_frame
```

只看 2D 图像时，RViz2 的 `Image` display 通常不依赖完整 TF tree；看点云、机器人模型或多传感器融合结果时，需要正确的 TF。

判断：

- 容器里 `ros2 topic hz` 正常：摄像头 driver 正在发布图像。
- `rviz2` 打不开窗口：优先判断为容器 GUI 透传问题。
- `$ROS_DOMAIN_ID` 为空是正常情况，表示使用 ROS 2 默认 domain，不需要额外设置。

可视化只用来确认画面。稳定性看 `ros2 topic hz`：

```bash
ros2 topic hz /camera_top/color/image_raw
ros2 topic hz /camera_top/depth/image_raw
ros2 topic hz /camera_wrist/color/image_raw
ros2 topic hz /camera_wrist/depth/image_raw
```

确认 `Image`、`CameraInfo`、帧率和时间戳都正常后，再把 DaBai 接入 AprilTag、深度融合、nvblox、DNN 推理或机械臂感知链路。

## 4. Isaac ROS 算法节点前的最低验收标准

把摄像头接入 AprilTag、Visual SLAM、nvblox、DNN 推理或机械臂感知前，先检查这些项：

| 检查项 | 合格标准 |
|---|---|
| 主机识别 | `lsusb`、`/dev/video*` 或厂商 SDK 能看到设备 |
| Isaac ROS 环境识别 | 进入 Isaac ROS 后仍能看到同一个设备 |
| ROS driver | 对应 ROS 2 driver package 可见，节点能启动 |
| 图像 topic | `sensor_msgs/msg/Image` 稳定发布 |
| 内参 topic | `sensor_msgs/msg/CameraInfo` 稳定发布 |
| 帧率 | `ros2 topic hz` 接近预期 |
| 时间戳 | image 和 camera_info 的 header 时间正常 |
| frame id | frame id 非空且与 TF 设计一致 |
| 分辨率 | image 和 camera_info 的 width/height 一致 |

如果这张表没有通过，不要先调 Isaac ROS 算法参数。先把摄像头输入链路修到稳定。

## 5. 实际项目里的最佳实践

如果 apt 仓库已经提供 `ros-${ROS_DISTRO}-orbbec-camera`，正式项目优先把二进制包预装进基础镜像或硬件适配镜像。这样镜像构建更快，也避免把第三方驱动源码混进业务 workspace。

调试驱动源码、修 bug 或 apt 仓库缺包时，再把 `OrbbecSDK_ROS2` 放到 `${ISAAC_ROS_WS}/src/third_party/` 编译。

如果你的项目当前使用的 Isaac ROS 基础镜像是：

```text
nvcr.io/nvidia/isaac/ros:isaac_ros_28556f8bc78a98822bd08b2d7c6fcf9b-amd64
```

最小 Dockerfile 可以这样写：

```dockerfile
FROM nvcr.io/nvidia/isaac/ros:isaac_ros_28556f8bc78a98822bd08b2d7c6fcf9b-amd64

ARG ROS_DISTRO=jazzy

RUN apt-get update && apt-get install -y --no-install-recommends \
    usbutils \
    v4l-utils \
    ffmpeg \
    ros-${ROS_DISTRO}-orbbec-camera \
    ros-${ROS_DISTRO}-orbbec-description \
    && rm -rf /var/lib/apt/lists/*
```

构建镜像：

```bash
docker build -t isaac-ros-orbbec-dabai:latest .
```

构建结果不是一个 workspace 目录，而是 Docker 本地镜像。可以这样确认：

```bash
docker images | grep isaac-ros-orbbec-dabai
```

进入容器后检查驱动是否已经在环境里：

```bash
ros2 pkg list | grep -E '^orbbec_camera$'
ros2 pkg prefix orbbec_camera
```

apt 安装时，`ros2 pkg prefix orbbec_camera` 通常会指向：

```text
/opt/ros/jazzy
```

如果必须从源码编译驱动，不要把预装驱动放在 `${ISAAC_ROS_WS}`。Isaac ROS 运行时常把 `${ISAAC_ROS_WS}` 映射成宿主机工程目录，放在那里容易和项目代码混在一起，甚至被挂载覆盖。源码编译的硬件驱动可以放到独立 workspace：

```text
/opt/orbbec_ws/install/setup.bash
/opt/lidar_ws/install/setup.bash
/opt/gripper_ws/install/setup.bash
```

然后统一写入 `/etc/bash.bashrc`：

```bash
source /opt/orbbec_ws/install/setup.bash
source /opt/lidar_ws/install/setup.bash
source /opt/gripper_ws/install/setup.bash
```

项目自己的 workspace 仍然放在 `${ISAAC_ROS_WS}`。这样驱动层和业务项目分开：镜像负责提供硬件驱动，项目仓库负责 launch、config 和感知逻辑。
