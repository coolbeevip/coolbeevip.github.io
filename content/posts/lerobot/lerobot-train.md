---
title: "LeRobot 训练"
date: 2026-03-04T00:24:14+08:00
tags: [robot]
categories: [LeRobot]
draft: true
---

切换到 LeRobot 虚拟环境

```shell
source ~/miniconda3/bin/activate
conda activate lerobot
pip install "lerobot[smolvla]"
```

## 下载基础模型

```shell
git clone https://huggingface.co/HuggingFaceTB/SmolVLM2-500M-Video-Instruct
git clone https://huggingface.co/lerobot/smolvla_base
```

## ACT

> Action Chunking Transformer

训练

```shell
lerobot-train \
  --policy.type=act \  
  --policy.push_to_hub=false \
  --policy.device=mps \
  --policy.repo_id=zhanglei/lerobot_policy \
  --dataset.repo_id=zhanglei/lerobot-test \  
  --output_dir=lerobot_train/lerobot_act_so101_test \
  --job_name=lerobot_act_so101_test \
  --steps=200 \
  --batch_size=4
```

评估

- dataset.repo_id 是评估后要写入的数据集，名称必须以 `eval_` 开头
- 

```shell
lerobot-record  \
    --robot.type=so101_follower \
    --robot.port=/dev/tty.usbmodem5B415369931 \
    --robot.id=zihao_follower_arm \
    --robot.cameras='{ front: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 5}, side: {type: opencv, index_or_path: 1, width: 640, height: 480, fps: 5} }' \
    --display_data=false \
    --dataset.repo_id=zhanglei/eval_lerobot-test \
    --dataset.single_task="Grab the banana and place it next to the apple." \
    --dataset.streaming_encoding=true \
    --dataset.encoder_threads=2 \
    --dataset.push_to_hub=false \
    --policy.path=lerobot_train/lerobot_act_so101_test/checkpoints/000200/pretrained_model
```

- dataset.repo_id 的数据集必须以 `eval_` 开头

### SmolVLA

> Small Vision-Language-Action model

训练

```shell
lerobot-train \
  --policy.push_to_hub=false \  
  --policy.device=mps \
  --policy.type=smolvla \  
  --policy.path=lerobot/smolvla_base \
  --dataset.repo_id=zhanglei/lerobot-test \
  --output_dir=lerobot_train/lerobot_smolvla_so101_test \
  --job_name=lerobot_smolvla_so101_test \
  --steps=200 \    
  --batch_size=4  
```

评估 



## 参考资料

- https://huggingface.co/docs/lerobot
- https://wiki.seeedstudio.com/cn/lerobot_so100m/