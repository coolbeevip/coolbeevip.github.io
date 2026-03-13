---
title: "使用 mitmprox 抓取 codex 数据包"
date: 2026-03-09T22:10:00+08:00
tags: [codex,mitmproxy,proxy,debug]
categories: [ai]
draft: false
---

> 标题里写的是 `mitmprox`，实际使用的工具名是 `mitmproxy`。

这篇文章只做一件事：**在 macOS 上用 `mitmproxy` 抓一次 Codex 发送 `hello` 的请求，并把请求体导出成文本文件。**

## Step 1. 安装 mitmproxy

```bash
brew install mitmproxy
```

确认安装成功：

```bash
mitmdump --version
```

## Step 2. 启动抓包代理

打开第一个终端，执行：

```bash
mitmdump --listen-host 127.0.0.1 --listen-port 8080 -w codex-hello.mitm
```

这一步会：

- 在本机启动代理 `127.0.0.1:8080`
- 把抓到的流量保存到 `codex-hello.mitm`

这个终端先不要关。

## Step 3. 安装 mitmproxy 根证书

第一次启动 `mitmproxy` 后，会在本机生成证书：

```bash
open ~/.mitmproxy
```

在 macOS 中操作：

1. 双击 `mitmproxy-ca-cert.pem`
2. 导入到“登录”钥匙串
3. 打开“钥匙串访问”
4. 找到 `mitmproxy` 证书
5. 双击证书，展开“信任”
6. 把“使用此证书时”改成“始终信任”
7. 关闭窗口并输入密码保存

## Step 4. 让 Codex 走本地代理

打开第二个终端，执行：

```bash
export HTTP_PROXY="http://127.0.0.1:8080"
export HTTPS_PROXY="http://127.0.0.1:8080"
export ALL_PROXY="http://127.0.0.1:8080"
export SSL_CERT_FILE="$HOME/.mitmproxy/mitmproxy-ca-cert.pem"
export NODE_EXTRA_CA_CERTS="$HOME/.mitmproxy/mitmproxy-ca-cert.pem"
```

## Step 5. 启动 Codex 并发送 `hello`

还是在第二个终端里执行：

```bash
codex
```

进入交互界面后，输入：

```text
hello
```

发送后，回到第一个终端，你应该能看到 `mitmdump` 打印出新的请求记录。

## Step 6. 停止抓包并确认文件

在第一个终端按 `Ctrl+C` 停止抓包。

然后检查文件是否存在：

```bash
ls -lh codex-hello.mitm
```

如果文件存在，说明抓包成功。

## Step 7. 回放抓包文件

```bash
mitmproxy -nr codex-hello.mitm
```

你可以在这里看到请求和响应。

## Step 8. 把请求体导出成文本文件

新建一个脚本 `save_request_body.py`：

```python
from pathlib import Path
from mitmproxy import http

saved = False

def request(flow: http.HTTPFlow) -> None:
    global saved
    if saved:
        return
    body = flow.request.get_text(strict=False)
    Path("codex-hello-request.json").write_text(body, encoding="utf-8")
    saved = True
```

然后执行：

```bash
mitmdump -nr codex-hello.mitm -s save_request_body.py
```

执行完成后，当前目录会多出一个文件：

```text
codex-hello-request.json
```

这个文件就是抓到的请求体文本。

## Step 9. 请求体完整长什么样

Codex 发送的请求体通常不是单独一个 `hello`，而是一整个 JSON 包，里面会带上模型、系统提示词、工具定义、推理配置和当前输入。

下面这个例子保留了**完整请求体结构**，但把长文本、路径、缓存键和其他敏感值做了脱敏。这样既能看清楚请求体完整长什么样，也适合公开展示。

```json
{
  "type": "response.create",
  "model": "gpt-5.4",
  "instructions": "<full system instructions redacted>",
  "previous_response_id": null,
  "input": [
    {
      "type": "message",
      "role": "developer",
      "content": [
        {
          "type": "input_text",
          "text": "<permissions instructions redacted>"
        }
      ]
    },
    {
      "type": "message",
      "role": "user",
      "content": [
        {
          "type": "input_text",
          "text": "# AGENTS.md instructions for <workspace path redacted>\n\n<INSTRUCTIONS>...redacted...</INSTRUCTIONS>"
        },
        {
          "type": "input_text",
          "text": "<environment_context>\n  <cwd><workspace path redacted></cwd>\n  <shell>zsh</shell>\n  <current_date>2026-03-09</current_date>\n  <timezone>Asia/Shanghai</timezone>\n</environment_context>"
        }
      ]
    },
    {
      "type": "message",
      "role": "developer",
      "content": [
        {
          "type": "input_text",
          "text": "<collaboration_mode># Collaboration Mode: Default ... redacted ...</collaboration_mode>"
        }
      ]
    },
    {
      "type": "message",
      "role": "user",
      "content": [
        {
          "type": "input_text",
          "text": "hello"
        }
      ]
    }
  ],
  "tools": [
    {
      "type": "function",
      "name": "exec_command",
      "description": "Runs a command in a PTY, returning output or a session ID for ongoing interaction.",
      "strict": false,
      "parameters": {
        "type": "object",
        "properties": {
          "cmd": {
            "type": "string",
            "description": "Shell command to execute."
          },
          "justification": {
            "type": "string",
            "description": "<redacted>"
          },
          "login": {
            "type": "boolean",
            "description": "Whether to run the shell with -l/-i semantics. Defaults to true."
          },
          "max_output_tokens": {
            "type": "number",
            "description": "Maximum number of tokens to return. Excess output will be truncated."
          },
          "prefix_rule": {
            "type": "array",
            "items": {
              "type": "string"
            },
            "description": "<redacted>"
          },
          "sandbox_permissions": {
            "type": "string",
            "description": "Sandbox permissions for the command. Set to \"require_escalated\" to request running without sandbox restrictions; defaults to \"use_default\"."
          },
          "shell": {
            "type": "string",
            "description": "Shell binary to launch. Defaults to the user's default shell."
          },
          "tty": {
            "type": "boolean",
            "description": "Whether to allocate a TTY for the command."
          },
          "workdir": {
            "type": "string",
            "description": "Optional working directory to run the command in."
          },
          "yield_time_ms": {
            "type": "number",
            "description": "How long to wait (in milliseconds) for output before yielding."
          }
        },
        "required": ["cmd"],
        "additionalProperties": false
      }
    },
    {
      "type": "function",
      "name": "write_stdin",
      "description": "Writes characters to an existing unified exec session and returns recent output.",
      "strict": false,
      "parameters": {
        "type": "object",
        "properties": {
          "chars": {
            "type": "string",
            "description": "Bytes to write to stdin (may be empty to poll)."
          },
          "max_output_tokens": {
            "type": "number",
            "description": "Maximum number of tokens to return. Excess output will be truncated."
          },
          "session_id": {
            "type": "number",
            "description": "Identifier of the running unified exec session."
          },
          "yield_time_ms": {
            "type": "number",
            "description": "How long to wait (in milliseconds) for output before yielding."
          }
        },
        "required": ["session_id"],
        "additionalProperties": false
      }
    },
    {
      "type": "function",
      "name": "update_plan",
      "description": "Updates the task plan.",
      "strict": false,
      "parameters": {
        "type": "object",
        "properties": {
          "explanation": {
            "type": "string"
          },
          "plan": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "status": {
                  "type": "string",
                  "description": "One of: pending, in_progress, completed"
                },
                "step": {
                  "type": "string"
                }
              },
              "required": ["step", "status"],
              "additionalProperties": false
            }
          }
        },
        "required": ["plan"],
        "additionalProperties": false
      }
    },
    {
      "type": "function",
      "name": "request_user_input",
      "description": "Request user input for one to three short questions and wait for the response.",
      "strict": false,
      "parameters": {
        "type": "object",
        "properties": {
          "questions": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "header": {
                  "type": "string"
                },
                "id": {
                  "type": "string"
                },
                "options": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "description": {
                        "type": "string"
                      },
                      "label": {
                        "type": "string"
                      }
                    },
                    "required": ["label", "description"],
                    "additionalProperties": false
                  }
                },
                "question": {
                  "type": "string"
                }
              },
              "required": ["id", "header", "question", "options"],
              "additionalProperties": false
            }
          }
        },
        "required": ["questions"],
        "additionalProperties": false
      }
    },
    {
      "type": "custom",
      "name": "apply_patch",
      "description": "Use the `apply_patch` tool to edit files.",
      "format": {
        "type": "grammar",
        "syntax": "lark",
        "definition": "<lark grammar redacted>"
      }
    },
    {
      "type": "web_search",
      "external_web_access": true,
      "search_content_types": ["text", "image"]
    },
    {
      "type": "function",
      "name": "view_image",
      "description": "View a local image from the filesystem.",
      "strict": false,
      "parameters": {
        "type": "object",
        "properties": {
          "path": {
            "type": "string",
            "description": "Local filesystem path to an image file"
          }
        },
        "required": ["path"],
        "additionalProperties": false
      }
    }
  ],
  "tool_choice": "auto",
  "parallel_tool_calls": true,
  "reasoning": {
    "effort": "high"
  },
  "store": false,
  "stream": true,
  "include": ["reasoning.encrypted_content"],
  "prompt_cache_key": "<redacted>",
  "text": {
    "verbosity": "low"
  },
  "generate": false,
  "client_metadata": {
    "x-codex-turn-metadata": "{\"turn_id\":\"<redacted>\",\"sandbox\":\"seatbelt\"}"
  }
}
```

从这个例子可以看出来，`hello` 只是 `input` 里的最后一条用户消息，而不是整个请求体本身。真正发出去的是一个完整的代理请求包。

## 注意

不要把真实抓包里的 token、缓存键、本地路径、完整系统提示词或者完整会话内容直接发到博客、工单或公开仓库。要展示完整结构时，建议像上面这样保留字段、脱敏字段值。
