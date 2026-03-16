---
title: "LeRobot 数据采集"
date: 2026-03-04T00:24:14+08:00
tags: [robot]
categories: [LeRobot]
draft: false
---

通过操作 LeRobot 机械臂执行指定任务来采集数据，数据会被保存到本地并可以选择上传到 Hugging Face Hub 进行管理和分享。

切换到 LeRobot 虚拟环境

```shell
source ~/miniconda3/bin/activate
conda activate lerobot
```

执行以下命令跟随语音提示完成 3 轮摇操作数据采集，每轮采集在 60 秒内完成抓取香蕉放到苹果旁，然后再在。30 秒内将香蕉摆放回原来的位置后再等待下一轮的语音指令，直到完成 3轮数据采集后命令会自动结束。

> `dataset.repo_id` 配置数据集的存储目录名，最终数据会存储到 `~/.cache/huggingface/lerobot/{repo-id}` 目录下，注意 repo-id 的格式必须为 `{xxx}/{xxx}`。

```shell
lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/tty.usbmodem5B415369931 \
    --robot.id=zihao_follower_arm \
    --teleop.type=so101_leader \
    --teleop.port=/dev/tty.usbmodem5B420772871 \
    --teleop.id=zihao_leader_arm \
    --robot.cameras='{ front: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 5}, side: {type: opencv, index_or_path: 1, width: 640, height: 480, fps: 5} }' \
    --display_data=true \
    --dataset.repo_id=zhanglei/lerobot-test \
    --dataset.num_episodes=3 \
    --dataset.single_task="Grab the banana and place it next to the apple." \
    --dataset.push_to_hub=false \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=30 
```

## 录制参数

通过命令行参数设置数据录制流程：

- `--dataset.episode_time_s=60` 每个数据录制 **Episode（回合）** 的持续时间（默认：60 秒）。
- `--dataset.reset_time_s=60` 每个 Episode 结束后，用于 **重置环境** 的时间（默认：60 秒）。
- `--dataset.num_episodes=50` 需要录制的 **Episode 总数量**（默认：50）。

## 录制过程中的键盘控制

在数据录制过程中，可以通过键盘快捷键控制录制流程：

- **右箭头（→）** : 提前结束当前 Episode 或 Reset 阶段，并进入 **下一轮 Episode**。
- **左箭头（←）** : **取消当前 Episode**，并重新录制该 Episode。
- **ESC（Escape）** : **立即结束整个录制会话**。

## 重放

> 使用以下命令允许回放任何已采集的片段，或来自任何外部数据集的片段。此功能有助于您测试机器人动作的可重复性，并评估同型号机器人之间的可迁移性。

执行以下命令可让 Follower 机械臂回放之前录制的 Episode 1 的数据，回放过程中会自动加载之前保存的校准结果，并根据录制的数据自动控制 Follower 机械臂的动作。

```shell
lerobot-replay \
    --robot.type=so101_follower \
    --robot.port=/dev/tty.usbmodem5B415369931 \
    --robot.id=zihao_follower_arm \
    --dataset.repo_id=zhanglei/lerobot-test \
    --dataset.episode=1
```

## 数据集可视化

> 录制完成后，上传数据到 hub 然后通过 [visualize your dataset online](https://huggingface.co/spaces/lerobot/visualize_dataset) 可视化数据

上传数据到 Hugging Face Hub，`HF_USER` 是你的 Hugging Face 用户名，`repo-id` 是你之前在录制命令中设置的数据集存储目录名（格式必须为 `{xxx}/{xxx}`）。

```shell
hf upload ${HF_USER}/lerobot-test ~/.cache/huggingface/lerobot/zhanglei/lerobot-test --repo-type dataset
```

这是我上传的测试用训练数据，点开后可以看到如下界面 https://huggingface.co/spaces/lerobot/visualize_dataset?path=%2Fcoolbeevip%2Flerobot-test%2Fepisode_0%3Ft%3D15

![image](/images/posts/lerobot/visualize.png)

## 参考资料

- https://huggingface.co/docs/lerobot
- https://wiki.seeedstudio.com/cn/lerobot_so100m/