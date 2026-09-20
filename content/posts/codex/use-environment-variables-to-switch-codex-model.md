---
title: "用环境变量简化 Codex 本地模型切换"
date: 2026-09-20T16:00:00+08:00
tags: [codex, shell, powershell, windows, llm, model-provider]
categories: [codex]
draft: false
---

我平时会让 Codex 连接不同的本地模型或兼容网关。每次修改 `~/.codex/config.toml` 很麻烦，也容易忘记改回来。

现在可以用三个环境变量临时切换：

- `CODEX_MODEL`：模型名称
- `CODEX_BASE_URL`：模型服务地址
- `CODEX_API_KEY`：模型服务的 API Key

不设置时继续使用 Codex 默认配置；设置后只对当前终端生效，不会修改 `config.toml`。

## 前置条件

Codex 配置中需要有一个名为 `gateway` 的 provider，并通过 `CODEX_API_KEY` 读取密钥：

```toml
model_provider = "gateway"

[model_providers.gateway]
name = "Model Gateway"
base_url = "http://127.0.0.1:8000/v1"
env_key = "CODEX_API_KEY"
wire_api = "responses"
supports_websockets = false
```

默认配置文件通常位于 `~/.codex/config.toml`。如果还没有配置 provider，可以先参考 [《如何让 Codex 连接第三方模型平台》](/posts/codex/codex-connect-third-party-model-provider/)。

## macOS、Linux、WSL 和 Git Bash

运行安装命令：

```shell
curl -fsSL https://raw.githubusercontent.com/coolbeevip/coolbeevip.github.io/master/static/scripts/install-codex-gateway.sh | bash
```

脚本会自动识别 Bash 或 Zsh，并在修改 shell 配置前生成备份。安装完成后，关闭并重新打开终端。

设置模型、服务地址和密钥：

```shell
export CODEX_MODEL='zhipu/glm-5.3[1m]'
export CODEX_BASE_URL='https://tokenerpgw.asiainfo.com/erp/v1'
export CODEX_API_KEY='uk-xxx'

codex
```

想恢复 `config.toml` 中的默认配置，清除变量即可：

```shell
unset CODEX_MODEL CODEX_BASE_URL CODEX_API_KEY
```

## Windows PowerShell

运行安装命令：

```powershell
irm https://raw.githubusercontent.com/coolbeevip/coolbeevip.github.io/master/static/scripts/install-codex-gateway.ps1 | iex
```

安装完成后，关闭并重新打开 PowerShell，然后设置变量：

```powershell
$env:CODEX_MODEL = 'zhipu/glm-5.3[1m]'
$env:CODEX_BASE_URL = 'https://tokenerpgw.asiainfo.com/erp/v1'
$env:CODEX_API_KEY = 'uk-xxx'

codex
```

恢复默认配置：

```powershell
Remove-Item -Path Env:CODEX_MODEL, Env:CODEX_BASE_URL, Env:CODEX_API_KEY -ErrorAction SilentlyContinue
```

## 更新和卸载

重新运行安装命令即可更新。脚本只维护带有下面标记的配置片段，不会反复追加：

```text
# >>> codex gateway wrapper >>>
# <<< codex gateway wrapper <<<
```

macOS、Linux、WSL 和 Git Bash 的卸载命令：

```shell
curl -fsSL https://raw.githubusercontent.com/coolbeevip/coolbeevip.github.io/master/static/scripts/install-codex-gateway.sh \
  | bash -s -- --uninstall
```

Windows PowerShell 的卸载命令：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/coolbeevip/coolbeevip.github.io/master/static/scripts/install-codex-gateway.ps1))) -Uninstall
```

卸载只会删除脚本管理的包装函数，不会修改 Codex 配置和环境变量。

## 注意 API Key

示例中的 `uk-xxx` 只是占位符。不要把真实 API Key 提交到 Git，也不要直接写入公开的 shell 配置文件。更稳妥的做法是通过密码管理工具或私密配置注入密钥。

安装脚本本身不会保存模型、服务地址和 API Key。它只负责在启动 `codex` 时，把当前终端中的环境变量转换成临时启动参数。

Codex 官方文档可以参考 [配置优先级](https://developers.openai.com/zh-Hans/docs/config-file/config-basic/)、[provider 配置字段](https://developers.openai.com/zh-Hans/docs/config-file/config-reference/)和[环境变量说明](https://developers.openai.com/zh-Hans/docs/config-file/environment-variables/)。
