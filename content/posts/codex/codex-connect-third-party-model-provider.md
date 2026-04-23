---
title: "如何让 Codex 连接第三方模型平台"
date: 2026-04-23T16:00:00+08:00
tags: [codex, llm, model-provider, config]
categories: [codex]
draft: false
---

Codex 接第三方平台，只改 `config.toml` 两段：

- `model_providers`：声明网关地址、协议和密钥变量
- `profiles`：绑定 provider 和具体模型参数

配置完成后，通过 profile 切换模型。

## 配置片段

```toml
# 模型平台
[model_providers.aliyuncs]
name = "dashscope aliyuncs"
base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1"
wire_api = "responses"
supports_websockets = false
env_key = "MY_API_KEY"

# 模型配方
[profiles.minimax]
model_provider = "aliyuncs"
model = "MiniMax-M2.5"
model_context_window = 131072
model_max_output_tokens = 8192
```

## 关键字段说明

1. `base_url`
   指向第三方网关根路径。这里是 `https://dashscope.aliyuncs.com/compatible-mode/v1`。
2. `wire_api = "responses"`
   告诉 Codex 按 responses 协议发请求，不走 chat completions 兼容层。
3. `env_key = "MY_API_KEY"`
   API Key 不写死在配置里，只从环境变量读取。
4. `profiles.minimax`
   把 provider + 模型 ID + context/output 上限打包成一个 profile。

## 环境变量

本地先注入密钥：

```bash
export MY_API_KEY="你的平台密钥"
```

`zsh` 用户直接写到 `~/.zshrc`，避免每次开新 shell 重新导出。

## 使用路径

启动 `codex -p minimax`，Codex 会自动加载 `minimax` profile。

## 我踩过的坑

1. `model_provider` 必须和 `[model_providers.xxx]` 的名字完全一致。  
   例如这里是 `asiainfo`，写成 `asiaInfo` 会直接失配。
2. `env_key` 写的是变量名，不是变量值。  
   把真实密钥写进 `config.toml` 会增加泄露风险。
3. `wire_api` 要和网关支持的协议一致。  
   不支持 responses 的网关需要改成对应协议，否则请求会失败。