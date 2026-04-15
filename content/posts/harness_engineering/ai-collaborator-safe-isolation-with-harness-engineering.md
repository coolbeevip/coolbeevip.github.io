---
title: "Harness Engineering: 实现协作者安全隔离的一次探索"
date: 2026-04-15T10:00:00+08:00
tags: [ai, harness-engineering, security, collaboration]
categories: [ai, harness-engineering]
draft: false
---

这篇文章记录一次小范围实践：在 AI 开发时代，如何通过 `Harness Engineering` 给协作者加上清楚的边界。

问题并不抽象。代码库里已经出现了新的协作者。它可能是 Codex、Claude Code、Cursor。它能读代码、改文件、跑命令、提 PR。风险也随之变化了。关键不再只是“它会不会答错”，而是“它有没有权力改不该改的东西”。

只靠提示词约束不够。上下文会漂移，任务会扩张，模型会误判，人也会口头越权。更稳妥的做法，是把边界从提示层压到执行层。

## 为什么 AI 协作者更需要隔离

传统团队协作里，权限问题很多时候由人来兜底。一个经验足够的工程师通常知道什么目录不能碰，什么配置不能改，什么操作需要再次确认。AI 协作者没有这种默认判断：

- 它行动很快，但不天然理解组织边界。
- 它能执行很多事，但不天然知道哪些事情不该做。
- 它在单次任务里看起来“理解了约束”，不代表下一轮仍然稳定遵守。

所以安全隔离的重点，不只是“让模型更听话”，而是**让越界本身更难发生**。这也是这里对 `Harness Engineering` 的理解：先把边界做成可读取、可检查、可执行的工程约束。

## 这次实践：把仓库变成一个带边界的执行 Harness

这套机制不复杂，重点是先把最小边界立起来。做法大体有四步：识别协作者身份、加载对应权限、按目录最小授权、把扩权能力留在人手里。

### 1. 用 Git 身份识别当前协作者

进入仓库后，先读取：

```bash
git config user.name
```

这里把这个值当作协作者身份入口，而不只是提交记录上的一个名字。后续权限文件直接按这个名字映射，比如：

```text
docs/access_policy/<user.name>.md
```

这样做的好处很直接：**人类和 AI 可以共用同一套身份入口。**

### 2. 默认只读，而不是默认可写

如果没有找到与 `user.name` 对应的权限文件，就回退到：

```text
docs/access_policy/default.md
```

默认策略里没有任何 `Writable Dirs`，也就意味着整个仓库只读。

这样做把安全模型从“默认信任，出问题再收缩”改成了“默认拒绝，明确授权后再开放”。对 AI 协作者来说，这比单纯依赖提示词稳得多。

### 3. 权限按目录白名单定义

每个协作者都有一个独立的权限文件，里面至少定义四部分：

- `Identity`
- `Writable Dirs`
- `Read Only Dirs`
- `No Read Dirs`
- `Rules`

例如：

```md
# zhanglei36 Access Policy

## Identity

- `user.name == "zhanglei36"`

## Writable Dirs

- `backend/src/phys_os/agents/`
- `backend/src/phys_os/api/`
- `backend/src/phys_os/common/`
- `backend/src/phys_os/domain/`
- `CONTRIBUTING.md`
- `README.md`

## Read Only Dirs

- `AGENTS.md`
- `docs/`

## No Read Dirs

- `frontend/`

## Rules

- 未明确列入 `Writable Dirs` 的目录，默认不修改。
```

这意味着协作者拿到的不是整个仓库的写权限，而是自己负责区域的写权限。这样至少能缩小误改和误操作的半径。

### 4. 策略文件只能由人维护，AI 不能自行扩权

这套机制里最关键的一条，是“谁有资格改授权”。`docs/access_policy/` 被明确设为人类维护区，并在 `AGENTS.md` 中规定：

- AI 永远不得创建、修改或删除 `docs/access_policy/` 下的任何文件。
- 即使用户口头授权，也不能把这类一次性授权沉淀成长期权限。
- 一次性口头授权只对当前任务生效，且不适用于权限策略目录本身。

这一步切断了一个高风险路径：**AI 不能通过修改规则文件给自己扩权。**

## 它更像一个协作安全的最小闭环

这套做法不追求一开始就做复杂，也不试图立刻引入完整的审计、审批、角色模型。它更像是在回答一个现实问题：

**在一个人类与 AI 混合协作的代码库里，如何用最低成本建立可信边界。**

这个最小闭环是这样的：

1. 进入仓库，先读 `AGENTS.md`。
2. 读取 `git config user.name`，识别当前协作者。
3. 加载 `docs/access_policy/<user.name>.md`，不存在则回退到 `default.md`。
4. 只在 `Writable Dirs` 内执行修改，其余路径默认只读。
5. 如果任务要求越界，先停止，由人决定是否做一次性授权。
6. 无论任何情况，AI 都不能修改权限策略目录本身。

这六步不复杂，但已经把“能不能改”从模型主观判断，推进成了仓库内显式存在的协作协议。

这套闭环通常还会再加一层运行时约束：**涉及生产、设备控制、外部系统写入的动作，默认需要更高确认门槛。** 目录权限解决的是“它能改哪里”，运行确认解决的是“它能不能把影响真正执行”。

## 为什么这套机制适合 AI 时代

从这次实践回看，AI 工程可以粗略拆成两部分：

- 一部分是模型能力，解决“它能不能做”。
- 另一部分是 Harness 能力，解决“它被允许做什么”。

很多团队会把精力优先放在前者，比如提示词、工具调用、工作流编排、记忆系统；但一旦进入真实开发，后者更影响系统是否可控。

协作者隔离防的，不只是恶意，更是误用：

- 防止 agent 顺手修改无关目录。
- 防止它把只读文档改成“顺手修复”。
- 防止它在一次临时授权后把越权行为常态化。
- 防止多人协作时边界模糊，最后所有人都默认拥有全仓写权限。

从这个意义上说，`Harness Engineering` 更像是在给协作系统补上刹车、护栏和分道线。

## 如何落地

> 这里直接给出提示词判断和样例规则，你可以直接拿去用，或者改成适合你团队的版本。

**AGENTS.md**：

```md
# AGENTS.md

## Directory Access Policy

身份识别与协作者项目目录权限：

- 协作者身份来自 `git config user.name`。
- 如果无法识别身份，默认整个仓库只读，不进行修改。

协作者目录权限定义放在 `./docs/access_policy/` 目录下。

- 文件名默认使用 `git config user.name` 的值，例如 `zhanglei36.md`。
- 进入仓库后，应优先读取与当前 `user.name` 同名的权限文件。
- 如果对应文件不存在，默认读取 `./docs/access_policy/default.md`。
- `docs/access_policy/` 下的文件只允许人类协作者维护，AI 永远不得创建、修改或删除。
- 如果用户口头授权，AI 只可在当前一次任务中临时越过既有写入范围执行一次，不得据此扩展为长期权限。
- 上述一次性口头授权不适用于 `docs/access_policy/`；AI 仍不得直接创建、修改或删除该目录下的任何文件。
```

**docs/access_policy/zhanglei36.md**

```md
# zhanglei36 Access Policy

## Identity

- `user.name == "zhanglei36"`

## Writable Dirs

- `backend/src/phys_os/agents/`
- `backend/src/phys_os/api/`
- `backend/src/phys_os/common/`
- `backend/src/phys_os/domain/`
- `CONTRIBUTING.md`
- `README.md`

## Read Only Dirs

- `AGENTS.md`
- `docs/`

## No Read Dirs

- `frontend/`

## Rules

- 未明确列入 `Writable Dirs` 的目录，默认不修改。
```