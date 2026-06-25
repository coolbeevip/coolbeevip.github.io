---
title: "ALFWorld 长程任务评测：从“说出计划”到“执行家庭任务”"
date: 2026-06-17T10:00:00+08:00
summary: "介绍 ALFWorld 长程任务评测机制，并用 clean apple 这类家庭任务说明 agent 如何从说出计划转向执行任务。"
tags: [ai, agent, embodied-ai, planning, alfworld]
categories: [embodied-ai]
draft: true
---

# ALFWorld 长程任务评测：从“说出计划”到“执行家庭任务”

这篇文章讨论的问题：ALFWorld 这类基准测试到底在评估什么，以及它为什么比普通文本游戏更接近具身智能里的长程任务规划。

## ALFWorld 是什么

ALFWorld 是 ICLR 2021 的一个 embodied agent 基准测试。它的核心想法很直接：把 ALFRED 里的家庭任务，映射成 TextWorld 里的文本交互环境，让 agent 先在抽象文本世界里学习高层策略，再把这些策略迁移到更具体的视觉具身环境里。

这句话听起来像论文摘要，换成工程语言就是：同一个任务有两个版本。

一个版本是文本版。环境告诉你现在在哪、附近有什么、可以做哪些动作，agent 输出类似 `go to fridge 1`、`open fridge 1`、`take apple 1 from countertop 1` 的文本命令。

另一个版本是具身版。任务仍然来自 ALFRED，但 agent 面对的是 AI2-THOR 里的家庭场景，需要处理视觉、导航、物体检测和低层动作。

ALFWorld 的价值就在这条对齐线上。它不是只做文本游戏，也不是直接把所有问题扔给视觉机器人。它把任务拆成两个抽象层：高层规划在 TextWorld 里可以看清楚，低层执行在 THOR 里能接上真实约束。

普通 LLM 可以说出"把洗干净的苹果放进冰箱"的计划，但在 ALFWorld 里，这句话没有直接得分。agent 要找到苹果，找到能清洗的地方，确认冰箱在哪，打开容器，移动物体，执行清洗，再把目标物体放到目标容器里。每一步都要被环境接受。

## ALFWorld 的一次评估由什么组成

从工程角度看，一次 ALFWorld 测试可以拆成七个要素：任务描述、房间和物体观察、可执行动作、环境反馈、隐含世界状态、任务类型、完成条件。

任务描述通常是自然语言目标，比如把一个洗干净的 apple 放进 fridge。观察给出当前位置附近的物体和容器，比如 countertop、sinkbasin、fridge、cabinet。动作空间是文本命令，比如 `open fridge 1`、`put apple 1 in sinkbasin 1`、`clean apple 1 with sinkbasin 1`。环境反馈会告诉 agent 动作是否成功，以及观察是否变化。

这里最容易被低估的是隐含世界状态。agent 看到的是文本，但环境内部维护的是结构化状态：apple 在哪里，fridge 是否打开，sinkbasin 是否可用，apple 是否已经 clean，agent 是否正拿着目标物体，目标容器是否能放入该物体。

ALFWorld 还把任务分成几类典型家庭目标：简单拿放、拿两个同类物体并放置、在灯光下查看物体、清洗后放置、加热后放置、冷却后放置、借助可移动容器完成放置。

这几类任务覆盖了一个很关键的变化：从"把 A 放到 B"到"先让 A 发生状态变化，再放到 B"。后者才是长程规划真正变难的地方。

## ALFWorld 的成功机制是什么

ALFWorld 的文本环境不是让 agent 最后输出一段答案，再由评测器读这段答案打分。它更像一个交互式游戏循环。

每一步，agent 输入一条文本动作：

```text
open fridge 1
take apple 1 from diningtable 1
clean apple 1 with sinkbasin 1
put apple 1 in fridge 1
```

环境执行动作，更新内部世界状态，然后返回新的观察、分数、是否结束，以及一组 info 字段。ALFWorld 的 TextWorld 环境在初始化时会请求 `won=True` 和 `admissible_commands=True` 这类信息，所以程序里可以直接拿到当前游戏是否已经赢，而不是只能从自然语言反馈里猜。

简化成伪代码大概是：

```python
obs, info = env.reset()

while True:
    action = agent.act(obs, info)
    obs, scores, dones, infos = env.step([action])

    if infos["won"][0]:
        success = True
        break

    if dones[0]:
        success = False
        break
```

实际代码里字段形状会受 batch size 影响，但核心机制就是这样：agent 连续输入 action，环境每步检查目标条件。如果内部状态已经满足任务目标，比如 `clean apple in fridge`，TextWorld 的游戏状态会把 `won` 置为 true，episode 也会结束。

所以成功不是靠 agent 自己说"done"。如果 agent 输出 `done`、`finish` 或一段解释，但环境状态没有达成目标，通常不会算成功。反过来，如果最后一步 `put apple 1 in fridge 1` 让目标状态成立，环境会通过 `won` 给出程序化成功信号。

观察文本里有时也会出现类似成功提示，但评测时不应该把字符串匹配当成主判断。更可靠的判断是：`infos["won"] == True`，或者在非 batch 封装里检查 state 里的 `won` 字段。`done` 只能说明 episode 结束，可能是成功，也可能是步数耗尽或失败终止；`won` 才是成功条件。

## 为什么用 ALFWorld 讨论具身智能

先说边界。ALFWorld 不是工业机器人测试场。它没有真实机械臂动力学，没有抓取姿态规划，没有力控，没有产线安全互锁，也不处理复杂工装和 PLC 节拍。不能从 ALFWorld 分数直接推出一个系统能在工厂里干活。

但它比纯问答和纯文本游戏更接近具身智能的一层问题：任务不再是回答，而是改变环境状态。

家庭任务看起来简单，实际上很像一个小型操作系统调度问题。目标是用户进程，物体是资源，容器是文件系统目录，动作是系统调用。你不能只在脑子里声明"苹果已经洗干净并放进冰箱"。你必须先拿到 apple 的句柄，确认 sinkbasin 可用，调用 clean，再把对象移动到 fridge。调用顺序错了，系统就返回错误。

这也是 ALFWorld 适合讨论 long-horizon planning 的原因。它省掉了一部分真实世界的连续控制问题，但保留了高层任务最难的结构：对象搜索、前置条件、容器状态、物体状态变化、阶段推进、反馈校验和失败恢复。

## 测试场景：put a clean apple in fridge

下面用一个典型的 clean-and-place 任务来说明。

任务可以写成：

```text
Your task is to put a clean apple in fridge.
```

![ALFWorld clean apple 任务执行流程](/images/posts/embodied-ai/alfworld-long-horizon-planning/clean_apple.png)

这个任务最容易被误解成一个三步计划：

```text
find apple
clean apple
put apple in fridge
```

自然语言计划这么写没有问题，但它还不是可执行计划。ALFWorld 里的 agent 必须回答更细的问题：apple 当前在哪？它能不能被拿起？sinkbasin 在哪？是否需要先移动到 sinkbasin 才能 clean？fridge 是否关闭？apple 是否还在 inventory 里？如果 clean 后 apple 留在 sinkbasin，下一步要不要重新拿起？

这就是文本计划和具身计划的差别。文本计划描述目标，具身计划维护状态。

## 房间和对象

一个典型厨房场景里，agent 可能会看到这些对象：

```text
kitchen
  - countertop
  - diningtable
  - cabinet
  - drawer
  - fridge
  - sinkbasin
  - microwave
  - garbagecan
  - apple
  - mug
  - knife
  - plate
```

其中真正关键的对象只有几个。

apple 是目标物体。sinkbasin 是状态转换工具，用来把 apple 变成 clean apple。fridge 是目标容器。countertop、diningtable、cabinet、drawer 可能是搜索路径上的中间位置。microwave、knife、plate 也许完全无关，但它们会占据观察窗口，干扰 agent。

这和 ScienceWorld 里的 melt water 很像。任务看起来是一个概念问题，实际跑起来变成一个状态机问题：目标物体在哪里，哪个工具能改变它的状态，哪个容器是最终目标，每个动作之后世界状态是否真的变了。

## 一个可执行动作链

在文本环境里，一个 clean apple 任务可以压缩成六个阶段。具体对象编号和位置会随场景变化，下面只保留动作结构。

### 1. 搜索目标物体

```text
look
go to countertop 1
examine countertop 1
go to diningtable 1
examine diningtable 1
take apple 1 from diningtable 1
```

这一步不是"知道苹果在哪里"，而是把 apple 从环境里的某个 receptacle 绑定到 agent 的当前状态里。

如果 apple 不在当前观察里，agent 需要继续搜索。常见失败是过早执行 `take apple 1`，环境返回目标不可见或不可达。更稳的做法是把搜索也当成阶段：当前房间有哪些 receptacle，哪些已经查过，哪些还没查。

### 2. 找到清洗位置

```text
go to sinkbasin 1
examine sinkbasin 1
```

clean 不是一个凭空发生的动作。它需要工具或地点。对 apple 来说，sinkbasin 是让对象状态发生变化的设备。

这里的关键不是 sinkbasin 这个词，而是动作模型：哪些对象能被 clean，哪些 receptacle 能支持 clean，clean 后目标物体会停在哪里。

### 3. 清洗 apple

```text
put apple 1 in sinkbasin 1
clean apple 1 with sinkbasin 1
take apple 1 from sinkbasin 1
```

这一阶段有两个容易出错的点。

第一，agent 可能以为 `clean apple 1` 就够了，但环境命令需要带上工具或地点。第二，clean 后 apple 未必自动回到 inventory。agent 如果忘记重新拿起 apple，下一步去 fridge 时就会发现自己没有目标物体。

所以状态更新不应该只写：

```text
apple is clean
```

还要写：

```text
apple:
  state: clean
  location: sinkbasin 1 / inventory
```

状态变化和位置变化必须分开记。

### 4. 找到并打开 fridge

```text
go to fridge 1
open fridge 1
```

容器状态在 ALFWorld 里非常关键。fridge 是目标 receptacle，但关闭的 fridge 不能直接放入物体。agent 必须显式打开它。

这类前置条件很容易被 LLM 忽略。因为在自然语言里，"放进冰箱"默认包含"打开冰箱门"。但环境不会替你补这个动作。动作模型不自动脑补。

### 5. 放置目标物体

```text
put apple 1 in fridge 1
```

这一步的前置条件至少包括三件事：apple 在 inventory，apple 已经 clean，fridge 可访问且打开。

少一件都可能失败，或者放进去也不触发完成。比如 apple 没洗干净，动作本身可能成功，但目标状态不成立。这个区别很重要：动作成功不等于任务成功。

### 6. 观察完成条件

```text
inventory
look
```

真正可靠的 agent 不应该只在执行 `put apple 1 in fridge 1` 后立刻假设任务完成。它应该确认环境反馈是否出现任务完成，或者至少确认 apple 的位置和状态满足目标。

整个状态链可以简化成：

```text
apple on diningtable
  -> apple in inventory
  -> apple in sinkbasin
  -> apple becomes clean
  -> apple back in inventory
  -> fridge opens
  -> clean apple in fridge
  -> task completed
```

## 这个场景在测试什么

clean apple 的难点不在常识。普通模型当然知道苹果可以洗，冰箱可以放东西。难点在把这个常识编译成环境接受的动作。

对象搜索方面，agent 要在多个 receptacle 之间查找 apple。可见性方面，物体可能藏在 cabinet、drawer、fridge 这类需要打开的容器里。工具绑定方面，clean 必须绑定到 sinkbasin。状态转换方面，apple 要从普通状态变成 clean。位置跟踪方面，apple 在清洗前后可能不在同一个地方。容器前置条件方面，fridge 需要打开。完成校验方面，放置动作成功之后，还要确认目标状态成立。

这里面任何一个环节断掉，都会产生一种看起来很"笨"的错误：空手去冰箱，反复打开已经打开的容器，把没洗的 apple 放进去，洗完后忘记拿走 apple，或者在找不到 apple 时原地重复 `look`。

这些错误不是知识缺失。它们更像运行时状态错了。

## 普通 LLM 智能和具身智能的区别

通过 clean apple 可以更具体地看出差异。

普通 LLM 的目标是生成合理计划，输入是任务描述和上下文，输出是解释、步骤或工具调用。ALFWorld / 具身智能的目标是改变世界状态，输入是局部观察和动作反馈，输出是环境可执行的动作序列。

普通 LLM 可以写：

```text
1. 找到苹果
2. 清洗苹果
3. 打开冰箱
4. 把苹果放进冰箱
```

ALFWorld 需要的是：

```text
go to diningtable 1
take apple 1 from diningtable 1
go to sinkbasin 1
put apple 1 in sinkbasin 1
clean apple 1 with sinkbasin 1
take apple 1 from sinkbasin 1
go to fridge 1
open fridge 1
put apple 1 in fridge 1
```

前者是计划文本，后者是状态转换日志。

这就是区别。LLM 在语言空间里看目标是否合理，具身 agent 在环境空间里看状态是否达成。语言计划里被省略的东西，到了环境里都会变成错误码。

## 如何设计这类 agent

围绕 clean apple，一个可用的 ALFWorld agent 至少要处理六个设计问题。

### 1. 世界状态

世界状态不应该只存在于对话历史里。它要是一个可查询、可更新的结构。

在 clean apple 中，至少要记录：

```text
location: kitchen
inventory:
  - apple 1 / empty
objects:
  apple 1:
    location: diningtable 1 / sinkbasin 1 / inventory / fridge 1
    state: unknown / clean
  sinkbasin 1:
    supports: clean
  fridge 1:
    door: open / closed
searched_receptacles:
  - countertop 1
  - diningtable 1
task:
  object: apple 1
  required_state: clean
  target_receptacle: fridge 1
```

没有这层状态，agent 很容易忘记 apple 当前在哪里，也不知道自己是否已经满足 clean 这个中间目标。

世界状态层要回答几个问题：我现在在哪？目标物体在哪？它是否在手里？它的状态变了吗？目标容器是否打开？哪些地方已经搜索过？

### 2. 动作模型

动作模型描述每个动作的前置条件、效果和失败模式。

`take apple 1 from diningtable 1` 需要 apple 可见且可拿，效果是 apple 进入 inventory。`put apple 1 in sinkbasin 1` 需要 apple 在 inventory，效果是 apple 位置变成 sinkbasin。`clean apple 1 with sinkbasin 1` 需要 apple 和 sinkbasin 建立可操作关系，效果是 apple 状态变成 clean。`open fridge 1` 需要 fridge 可见，效果是 fridge door 变 open。`put apple 1 in fridge 1` 需要 apple 在 inventory 且 fridge 可放入，效果是 clean apple 进入 fridge。

普通 LLM 习惯跳过前置条件。动作模型的作用就是把"常识上应该这样"约束成"环境里允许这样"。

### 3. 记忆结构

长程任务里的记忆不能只保存完整历史。完整历史会越来越长，而且很多信息没有用。

更稳的是分层记忆：最近观察保存环境刚返回的文本，工作记忆保存当前阶段目标，状态记忆保存对象位置和属性，搜索记忆保存查过的 receptacle，失败记忆保存刚刚无效的动作。

比如 agent 在找 apple 时，不应该只记得一串 `go` 和 `look`。它应该能更新：

```text
searched:
  countertop 1: no apple
  diningtable 1: apple found
```

清洗之后，它应该更新：

```text
apple 1:
  state: clean
  location: sinkbasin 1
next_action: take apple 1 from sinkbasin 1
```

这样 planner 才不会直接空手去 fridge。

### 4. 阶段控制

clean apple 不适合只靠一次性计划。更稳的是阶段控制。

搜索目标物体：退出条件是 apple 已找到并进入 inventory。准备清洗：退出条件是 sinkbasin 可访问。清洗目标：退出条件是 apple 状态变成 clean。回收目标物体：退出条件是 clean apple 回到 inventory。准备目标容器：退出条件是 fridge 可访问且打开。最终放置：退出条件是 clean apple in fridge。完成校验：退出条件是环境返回成功或状态检查满足目标。

阶段控制的价值在于防止错时机动作。还没拿到 apple 时不应该去 clean，clean 后 apple 还在 sinkbasin 时不应该去 fridge，fridge 没打开时不应该 put。

这比简单的 Step 1 -> Step 2 -> Step 3 更强，因为每个阶段都有进入条件和退出条件。

### 5. 观察和校验

具身任务不能只记录"动作发出去了"，必须确认动作后果是否发生。

关键校验点包括：apple 是否拿到，sinkbasin 是否可用，clean 动作是否成功，apple 清洗后在哪里，fridge 是否打开，目标物体是否进入 fridge，环境是否返回完成。

这里要区分两个概念：动作被接受，目标状态达成。`put apple 1 in fridge 1` 被接受，只能说明 apple 进了 fridge。它不能自动说明 apple 是 clean。状态条件必须提前满足，或者在放置前后校验。

### 6. 恢复和降级

ALFWorld 里的恢复能力很关键。

如果 apple 不可见，就继续搜索未检查的 receptacle，而不是重复拿一个不可见对象。如果 fridge 已经打开，就不要反复打开，直接进入放置阶段。如果 clean 动作失败，就检查 apple 是否在 sinkbasin，或者命令是否绑定了正确工具。如果 put 失败，就检查 apple 是否在 inventory、fridge 是否打开、目标容器是否可达。如果任务没有完成，就回查目标状态：apple 是否 clean，apple 是否在 fridge。

恢复层要避免两个极端：一出错就重启整个任务，或者无限重复刚才失败的动作。

更实际的做法是回到最近的稳定状态。比如稳定状态是 apple clean 且 apple in sinkbasin，当前失败是 `put apple 1 in fridge 1`，下一步不是重新找 apple，而是先 `take apple 1 from sinkbasin 1`。

## 是否只靠 agent + 大模型就够

clean apple 这类任务说明，单靠通用大模型加提示词可以跑出部分结果，但要稳定完成大量变体并不容易。

原因不是大模型不知道家庭常识。它当然知道苹果要先洗再放进冰箱。问题在于它不一定稳定维护当前世界状态、动作前置条件、动作后果、阶段退出条件和失败恢复路径。

比较实际的系统分工是：LLM 负责理解目标、解释异常、生成候选计划；agent runtime 负责状态管理、动作约束、阶段控制、观察校验和恢复策略；策略训练或轨迹学习负责让模型在 ALFWorld 的动作空间里更稳定地选择下一步。

如果只是 demo，LLM + prompt + few-shot trajectory 可能够用。如果要稳定跑完整测试集，通常要把 admissible commands、对象状态表、阶段控制器、失败记忆和轨迹学习都接进去。

ALFWorld 最有价值的地方，不是证明某个模型会不会做家务，而是把"会说计划"和"能执行计划"之间那层运行时暴露出来。

## 本地测试报告

## 参考资料

* ALFWorld GitHub 仓库：https://github.com/alfworld/alfworld
* ALFWorld: Aligning Text and Embodied Environments for Interactive Learning，ICLR 2021：https://openreview.net/forum?id=0IOX0YcCdTn
* ALFWorld 论文 arXiv：https://arxiv.org/abs/2010.03768
* ALFWorld 官方项目页：https://alfworld.github.io/
* ALFRED: A Benchmark for Interpreting Grounded Instructions for Everyday Tasks：https://arxiv.org/abs/1912.01734
