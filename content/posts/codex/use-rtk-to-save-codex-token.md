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

官方仓库还提供了安装脚本、`cargo install --git` 和预编译二进制等方式。  
如果你不是 macOS，或者想看最新安装说明、初始化 hook 的方法，直接看官方仓库：

<https://github.com/rtk-ai/rtk>

## rtk 是怎么帮 Codex 省 token 的

从 `rtk --help` 可以看到，它的描述是：

> A high-performance CLI proxy designed to filter and summarize system outputs before they reach your LLM context.

这句话基本已经把原理说完了。 也就是说，原来是：

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

你会看到类似如下信息：

```text
RTK Token Savings (Global Scope)
════════════════════════════════════════════════════════════

Total commands:    76
Input tokens:      26.9K
Output tokens:     17.5K
Tokens saved:      9.4K (35.0%)
Total exec time:   1m53s (avg 1.5s)
Efficiency meter: ████████░░░░░░░░░░░░░░░░ 35.0%

By Command
───────────────────────────────────────────────────────────────────────
  #  Command                   Count  Saved    Avg%    Time  Impact
───────────────────────────────────────────────────────────────────────
 1.  rtk read                      1   2.5K   54.4%   151ms  ██████████
 2.  rtk cargo test -p chi...      1   2.4K   94.7%    1.7s  ██████████
 3.  rtk git diff                  1    873   18.7%    67ms  ███░░░░░░░
 4.  rtk ls -la content/posts      1    588   83.6%    1.2s  ██░░░░░░░░
 5.  rtk ls -la .                  2    566   77.9%    17ms  ██░░░░░░░░
 6.  rtk git diff src-taur...      2    446   12.9%    22ms  ██░░░░░░░░
 7.  rtk cargo test -p chi...      1    446   97.0%   18.0s  ██░░░░░░░░
 8.  rtk cargo test -p chi...      1    265   95.0%   18.6s  █░░░░░░░░░
 9.  rtk git diff src-taur...      3    185   15.0%    22ms  █░░░░░░░░░
10.  rtk cargo test -p chi...      1    168   92.3%   17.5s  █░░░░░░░░░
───────────────────────────────────────────────────────────────────────
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

这样配完以后，Codex 不只是“会调用 `rtk`，而且 `rtk` 的统计和历史数据也能正常落盘。

## 试一试

最简单的方式，就是让 Codex 帮你列出当前目录下的文件。

```bash
codex
╭──────────────────────────────────────────────╮
│ >_ OpenAI Codex (v0.120.0)                   │
│                                              │
│ model:     gpt-5.4 medium   /model to change │
│ directory: ~/Work/xxx                        │
╰──────────────────────────────────────────────╯
› 列出当前目录下文件
```

你可以看到 Codex 输出的命令是 `rtk ls -la`：

```bash
• 我会直接查看当前工作目录的文件列表，并把结果整理给你。

• Ran rtk ls -la
  └ .codex/
    .git/
    … +32 lines (ctrl + t to view transcript)
    vitest.config.ts  378B
    vitest.setup.ts  36B
```

最后你可以通过 `rtk gain` 来查看节省的 token