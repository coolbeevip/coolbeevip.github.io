---
title: "用环境变量简化 Codex 本地模型切换"
date: 2026-09-20T16:00:00+08:00
tags: [codex, shell, powershell, windows, llm, model-provider]
categories: [codex]
draft: false
---

我平时会让 Codex 连接不同的本地模型或兼容网关。每次切换都修改 `~/.codex/config.toml` 很麻烦，也容易忘记改回来。

我的做法是用三个环境变量作为统一入口：

- `CODEX_MODEL`：模型名称
- `CODEX_BASE_URL`：模型服务地址
- `CODEX_API_KEY`：模型服务的 API Key

不设置时继续使用 Codex 默认配置；设置后只对当前终端生效，不会修改 `config.toml`。

## 配置 gateway provider

先在 `~/.codex/config.toml` 中定义名为 `gateway` 的 provider：

```toml
model_provider = "gateway"

[model_providers.gateway]
name = "Model Gateway"
base_url = "http://127.0.0.1:8000/v1"
env_key = "CODEX_API_KEY"
wire_api = "responses"
supports_websockets = false
```

这里的 `base_url` 是默认地址，后面可以用 `CODEX_BASE_URL` 临时覆盖。`env_key = "CODEX_API_KEY"` 表示从同名环境变量读取密钥。

## Bash 和 Zsh

根据使用的 shell 打开对应文件：

- Zsh：`~/.zshrc`
- Linux、WSL：`~/.bashrc`
- macOS Bash：`~/.bash_profile`

添加下面的函数：

```bash
# ============ Codex 统一环境变量接口 ============
codex() {
  local args=()
  [[ -n "${CODEX_MODEL:-}" ]] && args+=( -m "$CODEX_MODEL" )
  [[ -n "${CODEX_BASE_URL:-}" ]] && args+=( -c "model_providers.gateway.base_url=\"$CODEX_BASE_URL\"" )
  command codex "${args[@]}" "$@"
}
```

保存后重新打开终端，或者重新加载配置：

```shell
source ~/.zshrc
# 或
source ~/.bashrc
```

### 切换模型

在当前终端设置环境变量：

```shell
export CODEX_MODEL='zhipu/glm-5.3[1m]'
export CODEX_BASE_URL='https://tokenerpgw.asiainfo.com/erp/v1'
export CODEX_API_KEY='sk-xxx'

codex
```

也可以只让变量对一条命令生效：

```shell
CODEX_MODEL='zhipu/glm-5.3[1m]' \
CODEX_BASE_URL='https://tokenerpgw.asiainfo.com/erp/v1' \
CODEX_API_KEY='sk-xxx' \
codex
```