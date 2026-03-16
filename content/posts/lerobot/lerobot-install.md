---
title: "LeRobot 驱动安装和遥空操作"
date: 2026-03-04T00:24:14+08:00
tags: [robot]
categories: [lerobot]
draft: false
---

## 安装 Miniconda

```shell
mkdir -p ~/miniconda3
curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -o ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh
```

接受 Anaconda 默认 channel 的服务条款

```shell
source ~/miniconda3/bin/activate
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
```

其他操作系统安装，参考 https://www.anaconda.com/docs/getting-started/miniconda/install 文档

## 环境设置

初始化 LeRobot 虚拟环境

```shell
source ~/miniconda3/bin/activate
conda create -y -n lerobot python=3.12
conda activate lerobot
```

**注意后续工作都需要在 LeRobot 虚拟环境中进行**，如果关闭了终端或者新开了一个终端，需要重新执行上面的 `source ~/miniconda3/bin/activate` 和 `conda activate lerobot` 命令进入 LeRobot 虚拟环境。

安装 ffmpeg 7.x(ffmpeg 8.X is not yet supported)

```shell
conda install ffmpeg=7.1.1 -c conda-forge
ffmpeg -version
```

## 安装 LeRobot

下载仓库代码

```shell
git clone https://github.com/huggingface/lerobot.git
cd lerobot
```

以源代码模式安装该库

```shell
pip install -e .
```

安装附加功能

```shell
pip install 'lerobot[all]'          # 安装全部功能
pip install 'lerobot[aloha,pusht]'  # 或单独安装模拟器 (Aloha & Pusht)
pip install 'lerobot[feetech]'      # 或单独安装电机控制
```

验证安装（如果安装成功，下面的命令会输出版本信息和环境信息）

```shell
lerobot-info

- lerobot version: 0.4.4
- Platform: macOS-15.7.3-arm64-arm-64bit
- Python version: 3.11.14
- Huggingface Hub version: 0.35.3
- Datasets version: 4.7.0
- Numpy version: 2.2.6
- FFmpeg version: 8.0
- PyTorch version: 2.10.0
- Is PyTorch built with CUDA support?: False
- Cuda version: N/A
- GPU model: N/A
- Using GPU in script?: <fill in>
- lerobot scripts: ['lerobot-calibrate', 'lerobot-dataset-viz', 'lerobot-edit-dataset', 'lerobot-eval', 'lerobot-find-cameras', 'lerobot-find-joint-limits', 'lerobot-find-port', 'lerobot-imgtransform-viz', 'lerobot-info', 'lerobot-record', 'lerobot-replay', 'lerobot-setup-can', 'lerobot-setup-motors', 'lerobot-teleoperate', 'lerobot-train', 'lerobot-train-tokenizer']
```

## 遥控操作

> 人类控制 Leader 机械臂，Follower 机械臂模仿 Leader 机械臂的动作

### 找到与每个机械臂关联的 USB 端口

> 你也可以使用 lerobot-find-port 命令按照照提示找到每个机械臂的端口

将设备连接到电脑上，并查看连接设备的端口，so101_follower 的端口是 `/dev/tty.usbmodem5B415369931`，so101_leader 的端口是 `/dev/tty.usbmodem5B420772871`。

> 如果不确定可以单独连接一个设备尝试

```shell
ls /dev/tty.usb*
/dev/tty.usbmodem5B415369931	/dev/tty.usbmodem5B420772871
```

### 设置与校准

> 首次安装需要进行机械臂校准，之后的使用会自动加载之前的校准结果

执行以下命令后根据提示回车进入校准模式，然后根据提示操作机械臂并手动将机械臂各个关节造作到极限角度，完成校准后会自动保存校准结果到本地缓存目录，之后的使用会自动加载之前的校准结果。

校准机器人 Leader 机械臂

> 校准后可以看到校准数据存储在 `~/.cache/huggingface/lerobot/calibration/teleoperators/so_leader/zihao_leader_arm.json`

```shell
lerobot-calibrate \
    --teleop.type=so101_leader \
    --teleop.port=/dev/tty.usbmodem5B420772871 \
    --teleop.id=zihao_leader_arm
```

校准 机器人 Follower 机械臂

> 校准后可以看到校准数据存储在 `~/.cache/huggingface/lerobot/calibration/robots/so_follower/zihao_follower_arm.json`

```shell
lerobot-calibrate \
    --robot.type=so101_follower \
    --robot.port=/dev/tty.usbmodem5B415369931 \
    --robot.id=zihao_follower_arm
```

校准完毕后执行如下摇操作命令，按照提示回车进入摇操作模式，之后就可以通过 Leader 机械臂控制 Follower 机械臂的动作了。

```shell
lerobot-teleoperate \
    --robot.type=so101_follower \
    --robot.port=/dev/tty.usbmodem5B415369931 \
    --robot.id=zihao_follower_arm \
    --teleop.type=so101_leader \
    --teleop.port=/dev/tty.usbmodem5B420772871 \
    --teleop.id=zihao_leader_arm
```

## 相机

接入相机后可以在遥操命令中添加摄像头配置参数，指定使用哪个摄像头进行图像采集，并设置相应的分辨率、帧率和编码格式等参数。 这样在遥操过程中就可以同时采集机械臂动作数据和摄像头的图像数据了。

### 查找摄像头

执行 `lerobot-find-cameras opencv` 命令可以看到系统中所有可用的摄像头设备，以及它们的默认流配置（分辨率、帧率等）。 你可以根据输出的信息选择合适的摄像头进行后续的图像采集和处理任务。

> 因为我笔记本有一个摄像头，又连接了两个 USB 摄像头，所以输出结果里显示了三个摄像头设备，分别是设备索引为 0、1、2 的三个摄像头。 你可以根据输出的信息选择合适的摄像头进行后续的图像采集和处理任务。

```shell
lerobot-find-cameras opencv

--- Detected Cameras ---
Camera #0:
  Name: OpenCV Camera @ 0
  Type: OpenCV
  Id: 0
  Backend api: AVFOUNDATION
  Default stream profile:
    Format: 16.0
    Fourcc:
    Width: 1920
    Height: 1080
    Fps: 5.0
--------------------
Camera #1:
  Name: OpenCV Camera @ 1
  Type: OpenCV
  Id: 1
  Backend api: AVFOUNDATION
  Default stream profile:
    Format: 16.0
    Fourcc:
    Width: 1920
    Height: 1080
    Fps: 5.0
--------------------
Camera #2:
  Name: OpenCV Camera @ 2
  Type: OpenCV
  Id: 2
  Backend api: AVFOUNDATION
  Default stream profile:
    Format: 16.0
    Fourcc:
    Width: 1920
    Height: 1080
    Fps: 24.0
--------------------
```

### 在遥操中增加摄像头显示

在摇操作命令中添加摄像头配置参数，指定使用哪个摄像头进行图像采集，并设置相应的分辨率、帧率和编码格式等参数。 例如，下面的命令配置了一个名为 `front` 的摄像头，使用 OpenCV 后端，**设备索引为 index_or_path: 0**，分辨率为 640x480，帧率为 30 FPS，视频编码格式为 MJPG。

> 以下我添加了两个摄像头，一个摄像头对着 Follower 机械臂，另一个摄像头对着 Leader 机械臂，两个摄像头的设备索引分别是 0 和 1。Leader 机械臂不要入境

注意 `index_or_path` `width` `height` `fps` 这些参数需要根据实际的摄像头设备和需求进行调整，确保摄像头能够正常工作并满足你的图像采集要求(但如果特别卡，可以降低 width 和 height)。

```shell
lerobot-teleoperate \
    --robot.type=so101_follower \
    --robot.port=/dev/tty.usbmodem5B415369931 \
    --robot.id=zihao_follower_arm \
    --teleop.type=so101_leader \
    --teleop.port=/dev/tty.usbmodem5B420772871 \
    --teleop.id=zihao_leader_arm \
    --robot.cameras='{ front: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 5}, side: {type: opencv, index_or_path: 1, width: 640, height: 480, fps: 5} }' \
    --display_data=true
```

![image](/images/posts/lerobot/camera.png)