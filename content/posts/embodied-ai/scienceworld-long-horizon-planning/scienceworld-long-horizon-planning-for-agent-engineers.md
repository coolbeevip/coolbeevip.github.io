---
title: "从 ScienceWorld 看具身智能长程规划"
date: 2026-06-12T10:00:00+08:00
summary: "介绍 ScienceWorld 基准测试框架，并用 melt water 任务说明具身智能评估如何围绕世界状态、动作模型、记忆、阶段控制、观察校验和恢复降级展开。"
tags: [ai, agent, embodied-ai, planning, scienceworld]
categories: [embodied-ai]
draft: true
---

# 从 ScienceWorld 看具身智能长程规划

![scienceworld-long-horizon-planning](/images/posts/embodied-ai/scienceworld-long-horizon-planning/melt.png)

这篇文章讨论的问题：ScienceWorld 这类基准测试到底在评估什么，以及它为什么能暴露普通 LLM agent 和具身智能 agent 之间的差异。

## ScienceWorld 是什么

ScienceWorld 是 Allen Institute for AI 发布的交互式科学任务基准测试，论文发表于 EMNLP 2022。它面向的是文本环境里的 embodied agent，而不是普通问答模型。

交互流程很直接：环境给出任务目标和当前房间观察，agent 输出一个文本动作，环境执行并返回新的观察，agent 继续决策，直到任务完成、失败或超过步数限制。

官方仓库和论文中，ScienceWorld 包含 30 个任务，覆盖 10 类小学科学主题——物体属性、热学、电学、化学变化、生物生命周期、植物生长、遗传等。每个任务还有多个参数化变体，用来减少"背答案"的可能。

它和传统科学问答的差别在哪？传统科学问答的输入是一道题，输出是答案或解释，知识正确通常就够了。ScienceWorld 的输入是一个可交互环境，输出是一串动作，必须让环境状态达到目标才算完成。错误来源也不同——传统问答的错误主要是推理错，ScienceWorld 的错误可能来自找错物体、漏前置条件、等待不足、过早提交。每一步动作都会改变后续状态。

所以 ScienceWorld 虽然是文本环境，但它评估的不是纯文本能力。它把物体、房间、容器、设备、温度、时间、状态变化都做成环境状态，agent 必须通过动作去改变这些状态。

一个普通 LLM 可以回答"冰在温度升高到 0 摄氏度以上时会融化成水"，但在 ScienceWorld 中这个回答没有直接得分。agent 要找到冰，或者先制造出冰，再把它放到热源上，等待状态变化，最后通过观察确认任务完成。

## ScienceWorld 的一次评估由什么组成

从工程角度看，一次测试可以拆成六个要素：任务描述（自然语言目标，比如 melt water）、初始环境（agent 所在房间、可见物体、门和容器状态）、动作空间（文本动作，比如 go to kitchen、open freezer、move metal pot to stove）、环境反馈（每个动作后的文本观察，包括成功、失败、状态变化）、隐含状态（物体位置、容器关系、设备开关、温度、物态等）、完成条件（环境判断目标状态是否达成，返回 Task Completed）。

这里最关键的是隐含状态。agent 看到的是文本，但环境内部维护的是可执行世界状态。比如 metal pot 在哪里、metal pot 里装了什么、freezer 是否打开、stove 是否启动、substance 当前是 water 还是 ice、当前温度是多少——这些都不是自然语言能直接回答的，必须通过动作和观察来获取。

这也是它适合用来分析具身智能长程规划的原因。它省掉了真实机器人的视觉识别和连续控制问题，但保留了长程任务最关键的结构：状态、动作、时间、反馈和完成条件。

## 为什么用 ScienceWorld 讨论具身智能

先把边界说清楚：ScienceWorld 不是工业机器人基准测试，也不是人形机器人测试场。它没有真实视觉、机械臂控制、抓取姿态、碰撞检测、力控、PLC、安全互锁、产线节拍和工艺参数。不能从 ScienceWorld 分数直接推出一个系统能做好工业机器人。

它的价值在另一个层面。它把具身智能的高层任务问题抽象出来，让我们能单独观察 agent 是否会管理世界状态、动作后果、阶段推进、观察校验和失败恢复。

制造业流水线机械臂和开放场所人形机器人都属于具身智能，但它们不是同一个问题。制造业更像是在强约束下可靠完成任务，开放场所机器人更像是在开放世界里理解和行动。ScienceWorld 处在更高抽象的一层。它不验证机器人本体能力，但可以帮助我们理解：一旦智能体从"回答问题"进入"改变世界"，系统就必须处理状态、动作、时间和反馈。后面用 melt water 讲的正是这部分能力。

## 测试场景：melt water

下面用官方标准答案里的 melt water 任务来说明。

任务描述是：

```text
Your task is to melt water.
First, focus on the substance.
Then, take actions that will cause it to change its state of matter.
```

这个任务容易误解。它不是让 agent 解释"冰怎么融化"，也不是让 agent 直接加热一杯水。任务叫 melt water，但液态水本身不能被 melt。一个可行策略是先找到 water，再把 water 冷冻成 ice，再加热 ice，让 ice 融化。也就是说，agent 要自己构造出一个可融化对象。

## 房间和对象

标准答案从 hallway 开始。初始观察里，hallway 有多扇门，其中包括通往 kitchen 的门。

```text
hallway
  - agent
  - picture
  - air
  - door to green house
  - door to living room
  - door to art studio
  - door to kitchen
  - door to bedroom
  - door to workshop
```

关键资源集中在 kitchen：

```text
kitchen
  - thermometer，当前 10 摄氏度
  - freezer，门关闭
  - stove，关闭，炉子上没有东西
  - sink，关闭，水槽里没有东西
  - cupboard，门关闭
  - table
    - glass cup，空
  - counter
    - drawer
    - bowl，里面有 potato、red apple、orange、banana
  - fridge、oven、lighter、soap、air、stopwatch、painting 等
```

从这个场景能看出两点。

环境里有大量无关物体。potato、apple、soap、painting 都会出现在观察里，但和任务无关。agent 不能只做关键词匹配。

有用对象分散在多个功能点上：thermometer 用来检查温度变化，metal pot 装水并承载目标 substance，sink 产生 water，freezer 降温把 water 变成 ice，stove 加热把 ice 融化。其中 metal pot 一开始不在可见列表里，需要打开 cupboard 才能拿到。这就是前置条件。

## 标准答案的动作链

官方标准答案可以压缩成七个阶段。

### 1. 进入 kitchen

```text
look around
open door to kitchen
go to kitchen
look around
```

其中 open door to kitchen 返回"门已经打开"。这不是任务失败，而是一次状态确认。agent 需要根据反馈继续执行 go to kitchen。

### 2. 拿 thermometer 和 metal pot

```text
pick up thermometer
open cupboard
pick up metal pot
```

这一步对应两个目标：thermometer 用于后续状态验证，metal pot 用于承载 water / ice。

如果没有打开 cupboard，metal pot 不可见。这里已经出现了典型的具身前置条件：不是知道"需要锅"就够了，还要通过动作让锅进入可操作状态。

### 3. 用 sink 生成 water

标准答案把锅放进 sink，打开再关闭 sink：

```text
move metal pot to sink
activate sink
deactivate sink
pick up metal pot
```

执行后，metal pot 里出现 substance in metal pot，也就是 water。水不是一开始就作为独立物体放在桌上，而是由环境动作生成。

这一阶段的状态变化是：

```text
before:
  metal pot contains nothing
  sink is off

after:
  metal pot contains water
  sink is off
```

### 4. focus on substance

任务要求先 focus on the substance，所以标准答案执行：

```text
focus on substance in metal pot
```

环境返回 agent 聚焦到 water。

这个动作很重要。它不是科学常识动作，而是测试协议动作。agent 如果只知道"要加热或冷冻"，但漏掉 focus，就可能无法触发任务完成条件。

### 5. 把 water 冷冻成 ice

任务目标是 melt，但当前对象是 liquid water。agent 需要先把它变成 ice：

```text
open freezer
move metal pot to freezer
examine substance in metal pot
use thermometer in inventory on substance in metal pot
wait
use thermometer in inventory on substance in metal pot
wait
examine ice
use thermometer in inventory on ice
```

官方轨迹中的温度和物态变化大致是：

```text
water at 10°C
  -> wait
water at 3°C
  -> wait
ice at -4°C
```

这里体现的是过程控制。agent 不能只执行一次 move metal pot to freezer 就宣布成功，它需要等待，并通过观察确认 water 已经变成 ice。

### 6. 把 ice 转移到 stove

ice 形成后，标准答案把锅从 freezer 转移到 stove，并启动 stove：

```text
pick up metal pot
move metal pot to stove
activate stove
```

这一阶段需要同时满足三件事：目标物质在 metal pot 里，metal pot 在 stove 上，stove 已启动。少一个条件，物态变化都不一定发生。

### 7. 观察融化并完成

标准答案继续观察 ice 和温度：

```text
examine ice
use thermometer in inventory on substance in metal pot
wait1
```

后续环境返回 Task Completed。其中一个关键反馈是温度回到 2°C，说明 ice 已经跨过融化状态，重新接近液态 water。

整个状态链可以简化成：

```text
empty metal pot
  -> sink fills pot with water
  -> focus on water
  -> freezer cools water
  -> water becomes ice
  -> stove heats ice
  -> ice melts
  -> Task Completed
```

## 这个场景在测试什么

melt water 的难点不在物理知识本身，而在把知识接到动作和状态上。

目标解释方面，melt water 实际要求先制造可融化对象。房间搜索方面，agent 要从 hallway 找到 kitchen。对象发现方面，打开 cupboard 才能拿到 metal pot。工具选择方面，thermometer 用于确认温度，pot 用于承载 substance。状态生成方面，sink 动作生成 water。任务绑定方面，需要 focus on substance in metal pot。过程控制方面，freezer + wait 让 water 变 ice。动作后果方面，stove + wait 让 ice 融化。校验方面，examine 和 thermometer 确认状态变化。恢复方面，对无效动作和冗余动作要能继续推进。

官方标准答案里还有一些不完美动作，比如把 metal pot 倒进自己，或者重复 pick up metal pot。这类动作会得到错误或无变化反馈。它们反而说明一个现实问题：长程任务里的 agent 不一定每一步都完美，但必须能根据环境反馈继续回到有效路径。

## 普通 LLM 智能和具身智能的区别

通过 melt water 可以更具体地看出差异。

普通 LLM 的目标是生成正确解释，输入是文本问题和上下文，输出是答案、计划、工具参数，成功标准是回答是否合理。ScienceWorld / 具身智能的目标是改变环境状态，输入是房间观察、物体状态、动作反馈，输出是可执行动作，成功标准是世界状态是否达成目标。记忆方面，普通 LLM 用对话历史，具身智能需要记住对象位置、容器关系、设备状态、阶段进度。错误处理方面，普通 LLM 重新回答或修改计划，具身智能要根据环境反馈恢复路径。

普通 LLM 可以解释"冰受热会融化成水"，但 ScienceWorld 需要的是：找到锅 -> 接水 -> 聚焦 water -> 放进 freezer -> 等到变 ice -> 放到 stove -> 加热 -> 观察 Task Completed。

具身智能的关键不是"懂不懂概念"，而是能不能把概念变成一串可执行、可验证、可恢复的状态转换。

## 如何设计这类 agent

围绕 melt water，一个可用的具身 agent 至少要处理六个设计问题。

### 1. 世界状态

世界状态不是聊天记录。它应该显式记录环境当前是什么样。

在 melt water 中，至少要记录：

```text
location: kitchen
inventory:
  - thermometer
  - metal pot
objects:
  metal pot:
    location: inventory / sink / freezer / stove
    contains: nothing / water / ice
  freezer:
    door: open / closed
  stove:
    status: on / off
focused_object:
  substance in metal pot
substance:
  state_of_matter: water / ice
  temperature_celsius: 10 / 3 / -4 / 2
```

没有这层状态，agent 只能依赖上下文猜测，很容易重复拿物体、忘记锅在哪里，或者在 water 还没变成 ice 时就去加热。

世界状态层要回答几个问题：我现在在哪里？关键对象在哪里？容器里装了什么？设备是否可用？当前目标物质是什么状态？哪些前置条件已经满足？

### 2. 动作模型

动作模型描述每个动作的前置条件、效果和风险。

以几个动作为例：open cupboard 需要 agent 在 kitchen 且 cupboard 可见，效果是 cupboard 变 open 且内部物体可见，如果已经打开则无状态变化。pick up metal pot 需要 metal pot 可见且可拿，效果是进入 inventory，如果不可见或在封闭容器里则失败。activate sink 需要 metal pot 在 sink 中，效果是生成 water，没有容器时可能无效。move metal pot to freezer 需要 freezer 可访问且 pot 可移动，如果 freezer 未打开或 pot 不在手里则失败。activate stove 需要 pot 在 stove 上，效果是开始加热 pot 中 substance，stove 上没有目标容器则无效。

普通 LLM 很容易生成"把水冷冻，然后加热"的自然语言计划。动作模型要做的是把计划约束到环境允许的命令和状态变化上。

### 3. 记忆结构

长程任务里的记忆不应该只存完整对话。完整历史太长，而且很多信息会过期。

更合理的是分层记忆：短期观察（最近一次环境反馈，比如 freezer open、pot in freezer）、工作记忆（当前阶段需要的信息，比如正在等待 water 变 ice）、状态记忆（稳定世界状态，比如 pot contains water、focused on substance）、失败记忆（刚发生的无效动作，比如不能把 metal pot 倒进 metal pot）、任务记忆（目标和完成条件，比如 melt focused substance）。

这样设计的目的不是保存更多文本，而是让 planner 查询更可靠的信息。

例如，agent 在 wait 之后不应该只记得"我等过了"，而应该更新：

```text
temperature changed from 10°C to 3°C
state_of_matter is still water
next action: wait or inspect again
```

再一次等待后，观察到 ice，状态记忆才应变成：

```text
state_of_matter: ice
next stage: move to heat source
```

### 4. 阶段控制

melt water 不能只靠一次性计划，更适合做成阶段控制。

找到厨房（进入条件：agent 在 hallway；退出条件：agent 到达 kitchen）、准备工具（进入条件：kitchen 可观察；退出条件：thermometer 和 metal pot 可用）、生成 water（进入条件：metal pot 可用且 sink 可用；退出条件：pot contains water）、聚焦目标（进入条件：pot contains water；退出条件：focused_object 是 substance in metal pot）、冷冻（进入条件：pot contains water 且 freezer 可用；退出条件：substance 变成 ice）、加热（进入条件：substance 是 ice 且 stove 可用；退出条件：substance 融化）、完成校验（进入条件：观察到目标状态；退出条件：环境返回 Task Completed）。

阶段控制的价值在于防止 agent 做错时机的动作。还没有 water 时不应该去 freezer 等待，water 还没有变 ice 时不应该启动 stove，ice 已经形成后不应该继续无限冷冻，stove 未启动时不应该期待融化。

这比简单的 Step 1 -> Step 2 -> Step 3 更强，因为每个阶段都有进入和退出条件。

### 5. 观察和校验

具身任务不能只记录"动作已经执行"，必须确认动作后果是否发生。

在 melt water 中，关键校验点包括：metal pot 是否拿到（通过 inventory 或 look around 确认容器可用）、pot 是否有 water（通过 examine substance in metal pot 确认 sink 动作有效）、温度是否下降（通过 thermometer 判断 freezer 是否生效）、water 是否变 ice（通过 examine ice 判断是否可以进入加热阶段）、stove 是否开始加热（通过 stove 状态或后续温度判断 heat source 是否生效）、任务是否完成（通过环境返回 Task Completed 最终验收）。

这里要区分两个概念：动作被环境接受，和目标状态已经发生。move metal pot to freezer 被接受，只能说明锅进了 freezer，不能说明 water 已经变成 ice。必须 wait，再观察。

### 6. 恢复和降级

官方标准答案中出现的无效动作说明，恢复能力不是可选项。

常见恢复策略：门已经打开（door already open）时，不重复开门，直接 go。物体不可见时，look around，打开容器，换房间搜索。动作无效（比如不能把物体放进自己）时，放弃该动作，回到状态目标。等待后状态未达成（water 仍未变 ice）时，继续等待或确认 freezer 条件。设备未生效（温度不变）时，检查容器位置、设备开关。最终未完成（没有 Task Completed）时，重新校验 focused object 和目标状态。

恢复层要避免两种极端：一出错就重置整个任务，或者无限制重复同一个无效动作。更好的做法是回到最近的稳定状态。比如：稳定状态是 pot contains water、pot in freezer、focused on substance，当前问题是 wait 后仍是 water，下一步是继续 wait 或检查 thermometer 确认 freezer 是否仍有效。

恢复和降级最终要服务于一个目标：让 agent 即使在局部动作不完美时，也能沿着状态目标继续推进。

## 是否只靠 agent + 大模型就够

melt water 这样的任务说明，单靠通用大模型加提示词可以跑出部分结果，但很难稳定。

原因不是大模型不知道物理常识，而是它不一定稳定掌握当前世界状态、动作前置条件、动作后果、阶段切换、延迟反馈、失败恢复这些要素。

比较实际的系统分工是：LLM 负责语言理解、目标解释、候选计划、异常解释；Agent runtime 负责状态管理、动作约束、阶段控制、观察校验、恢复策略；后训练 / 策略训练让模型从轨迹中学会在特定环境里稳定选择动作。

如果只是 demo，LLM + prompt + few-shot trajectory 可能够用。如果要稳定完成大量 ScienceWorld 变体，通常需要加入轨迹学习、行为克隆、强化学习、过程监督或反思数据微调。后训练的目标不是补科学知识，而是让模型学会在环境反馈中行动。

## 公开做过 ScienceWorld 基准测试的系统

截至 2026-06-12，我没有找到主流商业智能体产品在官网上正式发布 ScienceWorld 排行榜分数。公开宣称做过 ScienceWorld 基准测试的，主要是论文里的 agent 框架、模型系统和研究型方法。

不同论文的评测集、平均方式、失败计分、动作步数限制和是否允许反思可能不同，下面的结果不能直接当统一排行榜。

| 系统 / 方法 | 测试设置 | 报告结果 | 说明 | 引用 |
| --- | --- | --- | --- | --- |
| `DRRN`、`KG-A2C`、`CALM-GPT2` | `ScienceWorld` 原始论文中的强化学习 / 文本游戏 agent 基线 | 平均表现约 `0.17`、`0.11`、`0.05`，分数按 `0-1` 计 | 早期基线，整体表现较低 | [`ScienceWorld` EMNLP 2022](https://aclanthology.org/2022.emnlp-main.775.pdf) |
| `BC-T5`、`TDT-T5` / `Macaw` 变体 | 原始论文中的离线 Transformer agent | `T5-Large` 约 `0.15` / `0.13`，`Macaw-Large` 约 `0.17` / `0.15`，`Macaw-11B` 约 `0.08` | 测试行为克隆和 Decision Transformer 路线 | [`ScienceWorld` EMNLP 2022](https://aclanthology.org/2022.emnlp-main.775.pdf) |
| `SayCan`、`ReAct`、`Reflexion` 的 `ScienceWorld` 适配版本 | `SwiftSage` 论文中基于 `GPT-4` 改造的提示式基线 | Overall `33.82`、`36.43`、`45.34`，分数按 `0-100` 计 | 不是原始机器人 `SayCan` 产品直接跑，而是论文适配版本 | [`SwiftSage` NeurIPS 2023](https://arxiv.org/abs/2305.17390) |
| `SwiftSage` | 在 `ScienceWorld` `30` 类任务上评测，使用快慢双系统 | Overall `84.68`，分数按 `0-100` 计 | 用小模型做快速动作，`GPT-4` 做慢思考和子目标规划 | [`SwiftSage` NeurIPS 2023](https://arxiv.org/abs/2305.17390) |
| `GPT-J 6B` 单阶段 agent | 在完整 `1,819` 个 `ScienceWorld` test games 上评测 | `All train` 为 `62.57`，`No variations` 为 `63.35`，`Up to 18 games` 为 `39.78` | 重点是利用更长历史上下文提升单阶段 agent | [`Remember what you did...` EMNLP Findings 2023](https://arxiv.org/abs/2311.01468) |
| `EMPO^2` | 在 `ScienceWorld` 和 `WebShop` 上测试强化学习式 agent 优化 | 摘要报告在 `ScienceWorld` 上相对 `GRPO` 提升 `128.6%` | 摘要未给出统一绝对分数 | [`EMPO^2` arXiv 2026](https://arxiv.org/abs/2602.23008) |
| `Q-Evolve` | 在 `AlfWorld`、`WebShop`、`ScienceWorld` 上测试 | 摘要声明超过强基线 | 摘要未给出本文可直接摘录的绝对分数 | [`Q-Evolve` arXiv 2026](https://arxiv.org/abs/2606.07367) |

## 参考资料

* ScienceWorld GitHub 仓库：https://github.com/allenai/ScienceWorld
* ScienceWorld: Is your Agent Smarter than a 5th Grader?，EMNLP 2022：https://aclanthology.org/2022.emnlp-main.775/
* ScienceWorld 官方项目页：https://sciworld.apps.allenai.org/
* SwiftSage: A Generative Agent with Fast and Slow Thinking for Complex Interactive Tasks，NeurIPS 2023：https://arxiv.org/abs/2305.17390
* Remember what you did so you know what to do next，EMNLP Findings 2023：https://arxiv.org/abs/2311.01468
* Exploratory Memory-Augmented LLM Agent via Hybrid On- and Off-Policy Optimization，arXiv 2026：https://arxiv.org/abs/2602.23008
* Self-evolving LLM agents with in-distribution Optimization，arXiv 2026：https://arxiv.org/abs/2606.07367
* Evaluating agents for scientific discovery,2026: https://allenai.org/blog/evaluating-scientific-discovery-agents
