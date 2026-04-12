---
title: "如何使用 rtk 让 Codex 节省 Token"
date: 2026-04-12T10:00:00+08:00
tags: [codex, rtk, token, llm]
categories: [codex]
draft: false
---

`rtk` 的定位很直接：**它不是替代命令行，而是把命令行输出先做一层压缩、过滤和摘要，再交给 LLM。**

对 Codex 这类 agent 来说，真正烧 token 的往往不是一句指令，而是后面那一大段命令输出：

* `ls -la` 把一整个目录细节全喷出来
* `git diff` 带出大量上下文
* `pytest`、`pnpm test`、`cargo test` 输出几百上千行日志
* `cat` 一个大文件，直接把无关内容塞进上下文

所以想让 Codex 省 token，最有效的方法之一不是“少问一句”，而是**减少无效输出进入上下文窗口**。`rtk` 干的就是这个事情。

## macOS 安装

如果你在 macOS 上，只想先快速用起来，最简单的是直接用 Homebrew：

```bash
brew install rtk
rtk --version
```

截至 2026-04-12，官方仓库还提供了安装脚本、`cargo install --git` 和预编译二进制等方式。  
如果你不是 macOS，或者想看最新安装说明、初始化 hook 的方法，直接看官方仓库：

<https://github.com/rtk-ai/rtk>

## rtk 是怎么帮 Codex 省 token 的

从 `rtk --help` 可以看到，它的描述是：

> A high-performance CLI proxy designed to filter and summarize system outputs before they reach your LLM context.

这句话基本已经把原理说完了。

也就是说，原来是：

```bash
git diff
```

现在变成：

```bash
rtk git diff
```

区别不是命令执行结果变了，而是**输出给 Codex 的内容被压缩过了**。  
对 agent 来说，输入 token 就是成本，输出越短、越聚焦，后续每一轮对话的上下文压力就越小。

如果你想先看一个最直观的结果，可以直接执行：

```bash
rtk gain
```

我在 2026-04-12 这次会话里看到的是：

```text
RTK Token Savings (Global Scope)

Total commands:    50
Input tokens:      18.4K
Output tokens:     14.2K
Tokens saved:      4.2K (22.7%)
```

这组数字的意义很直接：  
`rtk` 不只是“看起来输出更短”，而是**可以把节省下来的 token 直接统计出来**。

你可以把它理解为两件事：

1. 过滤噪音：去掉进度条、重复日志、边框、无关字段、超长上下文
2. 保留重点：只保留错误、变化、摘要、结构信息

## 最值得替换的几类命令

这一节只列最常用的高收益命令，更多命令直接参考官方文档：

<https://github.com/rtk-ai/rtk>

```bash
rtk ls -la content/posts
rtk tree content/posts/codex
rtk read -n -m 200 content/posts/gpt/prompt-engineering.md
rtk git status
rtk git diff
rtk diff
rtk test npm test
rtk pytest tests/unit
rtk vitest run
rtk json response.json
rtk log app.log
rtk grep -n "TODO|FIXME" content/posts/codex
rtk err npm run build
```

## 如何与 Codex 集成

如果你不想每次都手动提醒 Codex 使用 `rtk`，最直接的做法是把这件事写进 Codex 的工作约束里。

### 第一步：修改 `$CODEX_HOME/AGENTS.md`

在 `$CODEX_HOME/AGENTS.md` 中增加下面这条说明：

```text
ALWAYS execute shell commands through `rtk` by prefixing the original command with `rtk` (for example, run `rtk git status` instead of `git status`).
```

这样 Codex 在执行 shell 命令时，会优先走 `rtk` 包装后的命令，而不是直接调用原生命令。

### 第二步：修改 `$CODEX_HOME/config.toml`

```toml
[shell_environment_policy]
inherit = "all"
set = { RTK_DB_PATH = "/Users/zhanglei/rtk/history.db" }
ignore_default_excludes = false

[sandbox_workspace_write]
writable_roots = ["/Users/zhanglei/rtk"]
```

这里有两个目的：

* 通过 `RTK_DB_PATH` 把 `rtk` 的数据存储路径传入 Codex 沙箱
* 通过 `writable_roots` 给沙箱内的 `rtk` 写入 `/Users/zhanglei/.chi/rtk` 的权限

这样配完以后，Codex 不只是“会调用 `rtk`”，而且 `rtk` 的统计和历史数据也能正常落盘。

## 试一试

`rtk` 自带了一个很实用的命令：

```bash
rtk gain
```

我在 2026-04-12 这次会话里看到的统计是：

* Total commands: `50`
* Input tokens: `18.4K`
* Output tokens: `14.2K`
* Tokens saved: `4.2K (22.7%)`

这组数字不代表所有场景都一定是 22.7%，但它说明了一件事：  
**只要你的工作流里有大量目录浏览、diff、测试、日志和文件读取，`rtk` 的节流效果是可以被量化出来的。**

如果你想持续优化自己的习惯，`rtk gain` 应该经常看。

## 如何把“偶尔用 rtk”变成“默认用 rtk”

真正的节省不来自某一条命令，而来自默认习惯。

一个简单原则就够了：

* 原本会产生很多输出的命令，优先写成 `rtk xxx`
* 原本可能把整份内容灌进上下文的命令，优先找 `rtk` 对应子命令
* 不确定有没有等价命令时，先试 `rtk rewrite`

例如：

```bash
rtk rewrite git status
```

`rtk rewrite --help` 里说明得很清楚，它就是把原始命令改写成对应的 `rtk` 形式，适合做 hook 或养成习惯时使用。

## 一个很重要的判断标准

不是“这个命令能不能跑”，而是：

**这个命令的原始输出，有多少内容其实不需要让 Codex 看见。**

只要答案是“很多”，那它就值得先过一层 `rtk`。

所以，`rtk` 节省 token 的本质不是魔法，而是一个很朴素的原则：

> 不把无效上下文喂给 LLM。

对 Codex 来说，这通常意味着：

* 更少的上下文污染
* 更低的 token 消耗
* 更快定位重点
* 更稳定的多轮迭代

如果你平时已经习惯让 Codex 直接跑命令，那最小改动只有一个：

```bash
把原来的命令前面，加一个 rtk
```

很多时候，这就是最便宜、也最有效的 token 优化。
