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

如果你是第一次找这个文件，默认位置通常是 `$CODEX_HOME/config.toml`，很多机器上会落在 `~/.codex/config.toml`。

本文配置在 `OpenAI Codex v0.123.0` 下验证，验证日期为 `2026-04-23`。版本变化快，后续行为以官方文档和 release notes 为准。

配置完成后，通过 profile 切换模型。

## 配置片段

```toml
# 模型平台
[model_providers.aliyuncs]
name = "dashscope aliyuncs"
base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1"
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

- **base_url**: 第三方网关根路径，示例为 `https://dashscope.aliyuncs.com/compatible-mode/v1`。  
- **supports_websockets**: 是否启用 WebSocket 通道。这个配置走 HTTP，请设为 `false`。  
- **env_key**: 读取 API Key 的环境变量名，示例为 `MY_API_KEY`。  
- **model_provider**: profile 绑定的 provider 名，必须与 `[model_providers.aliyuncs]` 保持一致。  
- **model**: 实际调用的模型 ID，示例为 `MiniMax-M2.5`。  
- **model_context_window**: 上下文窗口上限（输入 + 输出 token 总预算），示例为 `131072`。  
- **model_max_output_tokens**: 单次响应最大输出 token，示例为 `8192`。

## 环境变量

本地先注入密钥：

```bash
export MY_API_KEY="你的平台密钥"
```

`zsh` 用户直接写到 `~/.zshrc`，避免每次开新 shell 重新导出。

## 使用路径

启动 `codex -p minimax`，Codex 会自动加载 `minimax` profile。

![](/images/posts/codex/codex-connect-third-party-model-provider/codex-minimax.png)

## 我踩过的坑

### Q1: litellm.BadRequestError

```text
litellm.BadRequestError: DashscopeException - 'function' is a required property, expected an object -
'tools.15' Received Model Group=MiniMax-M2.5 AvaiLable Model Group
Fallbacks=None
```

### A1

原因是 Codex 请求体里的 `tools` 里混进了非标准的 `function` 格式。典型例子就是 `web_search` 这类工具。这个问题我在另一篇文章里做过抓包分析，可以参考我写的另一个文章 [《抓包逆向分析智能体运行时-Codex》](https://coolbeevip.github.io/posts/ai/mitmproxy-codex-packets/)

解决办法是把不需要的工具关掉。我的配置是：

```toml
[profiles.minimax]
model_provider = "aliyuncs"
model = "MiniMax-M2.5"
model_context_window = 131072
model_max_output_tokens = 8192
web_search = "disabled"
apply_patch_freeform = false
tools = { view_image = false }

[profiles.minimax.features]
tool_search = false
image_generation = false
apps = false
plugins = false
multi_agent = false
js_repl = false
code_mode = false
```

### Q2: Unexpected message role

```text
{"error":{"message":"Unexpected message role.","type":"BadRequestError","param":null,"code":400}}
```

### A2

因为 Codex 内置发送系统消息角色不是 `system` 而是 `developer` ，有的第三方推理平台会对消息角色进行检查，目前没有太好的办法，一定要用可以修改 Codex 源代码。