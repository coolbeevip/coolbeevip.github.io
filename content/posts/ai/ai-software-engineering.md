---
title: "智能体软件工程：AI在软件开发中的应用与挑战"
date: 2026-03-08T00:24:14+08:00
tags: [engineering,ai]
categories: [ai]
draft: false
---

## 导读

> 本信息搜集整理自网络，内容仅供参考。

## 智能体软件工程 #1｜智能体原生工作估算

> _**《智能体软件工程》可能是一系列文章，记录我从传统软件工程向智能体软件工程的迁移过程。**_

#### 一个老程序员的顿悟

我写了近二十年代码了。估算工期这件事，早已刻进肌肉记忆——拆任务、排优先级、乘以经验系数、加上联调和 buffer（冗余量），最后给出一个"两到三周"。这套方法论伴随我度过了瀑布、敏捷、DevOps 的每一次范式迁移，从未失灵。

直到 AI 编程到来。

我最近用 AI Agent 做一个 CLI 工具。脑子里的第一反应是这个工具的实现过程：解析参数、核心转换、校验逻辑、错误处理、测试，一整套下来，按古法编程怎么也得两三天。结果 Agent 从动手到交付，连半小时都没用完。

效率提升了吗？表面上看，当然。

但更深层的问题随之浮现：**我甚至无法正确预判 AI 需要多久。**

我的整个估算框架是锚定在"人类开发者"这个基座上的。多少行代码、多少次 debug、多少轮 code review。当执行者从人变成智能体，这套尺子就彻底失灵了。

更讽刺的是，AI Agent 自己也犯同样的错。你问 Claude 或 GPT："做这个功能要多久？"它会一本正经地告诉你"大约 2-3 天"。因为它的训练数据里，Stack Overflow 和技术博客就是这么写的。Agent 在用人类的经验估人类的时间，然后自己十分钟干完。

我开始意识到，当软件工程迈向智能体软件工程（Agentic Software Engineering）的过程中，**第一个需要变化的，就是这种"拿人的尺子量 AI 的活"的心态。**

所以我写了一个 Skill，[agent-estimation](https://github.com/ZhangHanDong/agent-estimation)，专门解决这个问题。

#### 问题的根源：人类时间锚定

我把这个现象叫做 **Human-Time Anchoring**（人类时间锚定）。

它的运作机制是这样的：

AI Agent 在生成估算时，会不自觉地调用训练数据中的"集体经验"。一个 REST API 项目？论坛上说要一周。一个带实时图表的全栈 Dashboard？技术负责人在 Sprint Planning 里估了三个迭代。这些数字是人类开发者在人类的认知带宽、上下文切换成本、沟通损耗下产出的经验值。它们对人类成立，但对一个可以每 3 分钟完成一轮"思考→写码→执行→验证→修复"循环的 Agent 来说，完全不适用。

这导致了一个系统性偏差：**AI 几乎总是高估自己的工期。**

而我们这些老程序员，反过来也在犯同样的错：我们拿自己过去的经验去预期 AI 的产出速度，然后在"哇，这么快？"和"等等，它真能做到吗？"之间反复横跳。

问题不在于 AI 编码快不快。问题在于：我们还没有一套 **AI 原生的度量体系** 来衡量它到底有多快，以及哪些地方其实没那么快。

#### 一种解法：让 Agent 用自己的单位思考

我设计的这个 Skill（Agent Work Estimation Skill），核心思路只有一句话：

> **先用轮次（Round）估算，最后才转换成人类时间。**

这里的"轮次"是 Agent 的原子操作单位——一个完整的工具调用循环：

思考 → 编写代码 → 执行 → 查看输出 → 决定是否修复

一轮大约 2-4 分钟。这不是拍脑袋的数字，而是实际观察 AI Coding Agent 在真实项目中的运行节奏得出的经验值。

在这个基础上，我定义了四层估算单位：

- **轮次（Round）**：一次工具调用循环约 2-4 分钟
- **模块（Module）**：由多轮构成的功能单元，约 2-15 轮
- **波次（Wave）**：无相互依赖的模块批次，可并行 1-N 个模块
- **项目（Project）**：所有波次顺序执行 + 集成 + 调试波次之和

单 Agent 顺序编码用"轮次"，多 Agent 并发编码用"波次"。这就是 **AI Native 的估算方式**。

#### 五步估算法

**第一步：拆解模块**

把任务分成可以独立构建和测试的功能模块。核心问题是："如果我一次只做一件事，我会按什么顺序做？"

**第二步：估算每个模块的轮次**

这里有一组校准锚点：

| 模式               | 典型轮次 | 示例                 |
| :----------------- | :------- | :------------------- |
| 模板化 / 已知模式  | 1-2      | CRUD 端点、配置文件    |
| 中等复杂度         | 3-5      | 自定义 UI、状态管理    |
| 探索性 / 文档不足  | 5-10     | 陌生框架、平台特定 API |
| 高不确定性         | 8-15     | 未文档化行为、新算法   |

关键的校准规则很直觉：如果 Agent 一次生成就能跑通，那就是 1 轮；如果要生成、报错、修复，那就是 2-3 轮；如果库的文档稀烂需要靠猜，那就是 5 轮起步。

**第三步：加风险系数**

| 风险等级 | 系数 | 何时使用                         |
| :------- | :--- | :------------------------------- |
| 低       | 1.0  | 成熟生态、清晰文档               |
| 中       | 1.3  | 小幅未知，可能多 1-2 轮调试      |
| 高       | 1.5  | 文档稀缺、平台怪癖               |
| 极高     | 2.0  | 可能撞墙、需要换方案             |

**第四步：计算总量**

**顺序模式** ：

模块有效轮次 = 基础轮次 × 风险系数
项目轮次 = Σ(模块有效轮次) + 集成轮次（基础总量的 10-20%）

**波次模式（多 Agent 并发）** ：

波次耗时 = 波内模块的最大有效轮次
项目轮次 = Σ(波次耗时) + 协调轮次 + 集成轮次

**第五步：最后才转换为人类时间**

人类时间 = 项目轮次 × 每轮分钟数

默认每轮 3 分钟。但这个参数可调——快速迭代可以用 2 分钟，需要用户手动测试的场景可以用 5 分钟。

重点是：**人类时间是输出，不是输入。** 整个推理链条里没有"一个开发者大概需要……"这种话。

#### 实战校准：三个尺度的对照

小项目示例：CLI JSON-to-YAML 转换器（约 8 轮）

| 模块             | 基础轮次 | 风险 | 有效轮次 |
| :--------------- | :------- | :--- | :------- |
| 参数解析 + I/O   | 1        | 1.0  | 1        |
| JSON→YAML 核心   | 1        | 1.0  | 1        |
| Schema 校验      | 3        | 1.3  | 4        |
| 错误处理 + UX    | 2        | 1.0  | 2        |

总计 8 轮，约 24 分钟。如果按人类经验估，你会说"一天"，甚至"两天"。

中型项目示例：桌面键盘广播器（约 36 轮）

一台 Mac 键盘控制 27 台设备，涉及 HTTP/WebSocket 服务、Makepad UI、macOS CGEvent 键盘捕获、二维码生成等模块。

顺序执行：约 108 分钟（1.5-2 小时）。

如果用 3 个 Agent 并行的波次模式：

- Wave 1：HTTP 服务、二维码、手机端（无依赖，并行）→ 3 轮
- Wave 2：主 UI、客户端管理、分类过滤 → 10 轮
- Wave 3：键盘捕获 → 8 轮
- 集成 → 5 轮
- 协调开销 → 3 轮

并行时间约 57 分钟，比顺序快 47%。按人类经验？你大概率会估"两到三周"。

大型项目示例：全栈实时 Dashboard（约 63 轮）

React 前端 + Rust 后端 + WebSocket 流式推送 + 图表组件 + 认证。

顺序执行约 189 分钟（3-3.5 小时）。三 Agent 并行约 108 分钟。

人类估时？"三个月"不算夸张。

#### 六个必须避免的反模式

这些是这个 Skill 存在的根本原因。每一条都是我在实践中踩过的坑：

1.  **人类时间锚定。** "一个开发者大概需要两周"。不。从轮次开始推。
2.  **凭感觉加 buffer。** "以防万一加点余量"。不。用风险系数，每一分钟的膨胀都要有理由。
3.  **混淆复杂度和代码量。** 500 行模板代码不等于难。一行 macOS CGEvent API 也不等于简单。按不确定性估算，不按行数。
4.  **忘记集成成本。** 模块各自跑通，合在一起就炸。永远加集成轮次。
5.  **忽略用户侧瓶颈。** 如果用户需要手动授权、重启应用、在真机上测试——调整每轮分钟数，别凭空加轮次。
6.  **假设并行是免费的。** 多 Agent 协作有协调成本，合约定义、冲突解决都需要额外轮次。

#### 不止是估算方法，更是思维范式的迁移

写这个 Skill 的过程中，我越来越觉得，这不仅仅是一个技术问题。

我们正处在一个过渡期。软件工程的基本假设，"人写代码、人 debug、人沟通、人做决策"，正在被 Agent 重新定义。但我们的思维惯性还停留在旧范式里。我们用 Story Point 估算 Agent 的工作量，用 Sprint 规划 Agent 的迭代周期，用"人天"衡量 Agent 的产出——这就像用马车的速度去规划火车的时刻表。

AI Coding 的效率提升并不是简单的"同样的事做得更快"。它改变了工作的粒度。人类开发者的原子操作是"一天的编码"，Agent 的原子操作是"一轮工具调用"。当原子尺度变了，所有建立在旧原子之上的度量体系都需要重建。

同时我们也不能走向另一个极端，盲目乐观地认为 AI 什么都能秒杀。macOS 权限 API 的诡异行为、未文档化的框架边界、跨系统集成的隐式依赖——这些不确定性不会因为执行者是 AI 就消失。风险系数的存在就是为了尊重这个现实。

#### 写在最后

这个 Skill 是开源的，遵循 Agent Skills 开放标准，支持 Claude Code、Cursor、Codex CLI 等主流 Agent。你可以直接安装：

`npx skills add ZhangHanDong/agent-estimation`

但比安装一个 Skill 更重要的是：**开始练习用 Agent 的视角看问题。**

下次你想说"这个功能大概要三天"的时候，停一下。问自己：Agent 做这件事需要几轮？每轮的不确定性有多高？有哪些模块可以并行？

当你开始这样思考，你就已经踏入了智能体软件工程的大门。

这不是 AI 替代人的故事。这是人学会用新的尺子丈量新世界的故事。

---

## 智能体软件工程 #2｜重新思考 Code Review

*本文是"智能体软件工程"系列的一部分。上一篇：《AI Native 任务估算：轮次、波次与人工时间锚定偏差》。*

> 人工古法编程死于2025年。人工肉眼代码审查将死于2026年。 — Ankit Jain, Latent Space, 2026.03.02

#### 一场注定失败的战争

2026 年 3 月，Latent Space 发表了一篇标题极其激进的文章：[《How to Kill the Code Review》](https://www.latent.space/p/reviews-dead)。文章援引 Faros AI 对超过 10,000 名开发者、1,255 个团队的数据分析，画出了一张令人不安的图表：

- 高 AI 采纳率团队的**任务吞吐量**提升 21%
- **PR 合并率**暴涨 97.8%
- 但 **Review 中位时间**也暴涨 91.1%

这组数据描述的是一个经典的**生产-消费失衡**：AI 把代码生产速度拉到了指数曲线上，而人类 Review 能力仍然趴在线性甚至固定的水平线上。两条曲线必然交叉，而交叉点就是系统崩溃点。

GitHub 的 [Octoverse 报告](https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/)进一步证实了这个趋势：到 2025 年底，月度代码推送突破 8200 万次，合并 PR 达 4300 万，约 41% 的新代码由 AI 辅助生成。与此同时，Addy Osmani 的研究显示，AI 生成的 PR 体积增长约 18%，每个 PR 的事故率上升约 24%，变更失败率上升约 30%。

问题的严重性不仅在于**量**的失衡，更在于**质**的恶化。[CodeRabbit](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) 对 470 个 PR 的分析发现，AI 编写的代码平均每个 PR 产生 10.83 个问题，而人工编写的只有 6.45 个。AI 生成的代码在逻辑错误上的发生率是人类的 1.4-1.7 倍，在可读性问题上的差距更大。AI 代码看起来整洁一致，但经常违反本地代码库的命名约定、架构模式和惯例。

换句话说：**AI 生成了更多、更大、更难审查的代码变更，而人类 Review 的能力并没有相应增长。** 这是一场注定失败的战争。

但大多数人对此的反应是错误的。他们要么试图"用 AI 辅助人做 Review"（本质上还是人在读代码），要么试图"用 AI 做第一轮筛选，人做最终审批"（瓶颈只是略微后移）。这些方案都没有触及问题的根本。

要真正解决这个问题，我们需要回到第一性原理。

#### 第一性原理拆解：Code Review 到底在解决什么问题？

##### Code Review 不是目的，是手段

Code Review 从来不是一个"目的"，而是一个实现手段。它真正要解决的问题只有一个：

**"怎么确保进入生产环境的变更不会搞砸系统？"**

但在几十年的实践中，这个简单的目的被附加了越来越多的功能。今天的 Code Review 实际上同时承载着五个完全不同的职能：

**第一性原理的核心洞察**是：

**这五个功能并不需要绑定在同一个流程里，更不需要绑定在"人眼逐行读 diff"这个特定动作上**。

这就像早期的手机把电话、相机、音乐播放器、导航仪捆绑在一起是因为便利，但每个功能的最优解是独立演进的。**Code Review 把五个功能捆绑在一起，只是因为在人工编码时代，这是成本最低的妥协方案**。

##### 三个隐含假设的瓦解

传统 Code Review 建立在三个隐含假设之上，而这三个假设在 AI Coding 时代正在同时瓦解：

**假设一："读代码是验证正确性的最佳方式"**

这个假设从来就不太站得住脚。人眼 Review 发现缺陷的能力大约在 60-70%，而且 Review 质量随 diff 大小急剧衰减。**当 diff 超过 400 行时，Review 效果趋近于零**。我们只是因为没有更好的替代方案而接受了这个现实。

但现在我们有了更好的替代方案：形式化验证、属性测试、模糊测试、合约检查。这些确定性手段的验证能力远超人眼扫描。

**假设二："代码是需要长期维护的核心资产"**

当一个模块需要三个月编写、半年维护时，每一行代码都是投资，当然需要仔细审查。但当 AI 能在 30 分钟重写整个模块时，代码的性质发生了根本变化。它从"需要精心维护的长期资产"变成了"可随时重新生成的一次性制品"。

真正的长期资产不再是代码本身，而是**规格说明（Spec）**。这正是 [StrongDM Attractor](https://github.com/strongdm/attractor) 框架的核心哲学：

> Code must not be written by humans. Code must not be reviewed by humans.

代码变成了 Spec 的编译产物。你不会去逐行审查编译器输出的汇编代码，同样的道理。

正如 Obsidian 团队在 2023 年的承诺一样：**软件易逝，文件比应用程序更重要的理念进行开发**。

> Obsidian 对外承诺永远不发展到超过 12 个人，永不接受风险投资，永不收集个人数据和分析数据。持续秉持软件易逝，文件比应用程序更重要的理念进行开发，使用开放且持久的格式。

这套 File over App 的哲学，在 AI 时代正好和我们的理念不谋而合。这套承诺本身很加分，但它最厉害的地方不在“他们保证永远怎样”，而在于“就算他们将来不怎样了，你（用户）也能体面撤退”。

这才是“文件优先/ Spec 规格”真正的优势。

**假设三："质量检查必须发生在代码完成之后"**

这是传统"事后检验"思维的典型表现。第一性原理告诉我们一个制造业早已证明的真理：**质量应该内建（built-in）而不是检测出来（inspected-in）**。

W. Edwards Deming （现代质量管理之父） 在半个世纪前就说过："Cease dependence on inspection to achieve quality" 。软件行业在 CI/CD 上已经接受了这个思想，但在 Code Review 上却还停留在"事后审批"模式。

##### 验证不对称性：被忽视的根本性质

在我上一篇关于 AI Native 任务估算的文章中，我提出了一个核心概念：**人工时间锚定偏差**。经验丰富的开发者（和在人类内容上训练的 LLM）会不自觉地用人类时间线来锚定 AI 任务估算。

在 Code Review 领域，存在一个完全类似的偏差，我称之为 **"审查时间锚定"**：

> 我们假设审查一段代码所需的时间应该与编写它所需的时间成正比。当人类花一天写的代码，人类花两小时审查，比例大约 1:4 到 1:8。但当 AI 花 5 分钟生成同等量级的代码时，我们的直觉仍然告诉我们应该花两小时审查。这不是效率问题，这是度量框架错误。

但更深层的洞察是**验证不对称性**（Verification Asymmetry）：

**验证一个结果是否正确的成本，在本质上远低于生成该结果的成本。**

这个性质在数学中表现为 P ≠ NP 猜想，在密码学中表现为哈希验证 vs 碰撞攻击，在软件工程中表现为：运行一组测试（毫秒级）远比编写被测代码（小时级）快。

理解了这个不对称性，Code Review 的未来方向就清晰了：**我们不应该让人（或 AI）去"理解"代码然后判断它是否正确，而应该构建确定性的验证系统，让正确性成为一个可以被机器快速检验的属性。**

#### 从 Review Code 到 Review Intent：范式迁移

##### 审查点上移：从代码层到意图层

传统 Code Review 的审查点在代码层：

人写代码 → 人 Review 代码 → 合并 → 部署

在 AI Coding 时代，正确的审查点应该**上移到意图层**：

人写 Spec → AI 生成代码 → 机器验证代码满足 Spec → 人验收最终结果

这个迁移不是"让 AI 帮人做 Review"，而是**根本性地改变了人类在流程中的角色**：

- **旧角色**：代码的审查者（Did you write this correctly?）
- **新角色**：意图的定义者（Are we solving the right problem with the right constraints?）

人类的判断力不应该浪费在"这个 for 循环的边界条件对不对"这种机器可以完美验证的问题上，而应该聚焦在"我们是否在解决正确的问题"、"约束条件是否完备"、"验收标准是否覆盖了关键场景"这些只有人类才能判断的高阶问题上。

Latent Space 文章中的核心观点与此完全一致：

> Human-in-the-loop approval moves from "Did you write this correctly?" to "Are we solving the right problem with the right constraints?" The most valuable human judgment is exercised before the first line of code is generated, not after.

##### Spec 成为控制面

在智能体软件工程的框架中，我们需要重新定义三个平面的角色：

- **控制面（Control Plane）**：Spec，定义"做什么"和"怎样算对"
- **数据面（Data Plane）**：Code，Spec 的编译产物
- **执行面（Execution Plane）**：Agent，将 Spec 转化为 Code 的执行者

在这个架构下，Review 的对象从代码变成了 Spec。为什么这是合理的？因为 Spec 具有代码不具备的几个关键特性：

**Spec 的信息密度远高于代码。** 一条 "所有金额必须使用 Money 类型，精度为小数点后两位" 的 Spec 规则，对应的代码实现可能分散在几十个文件、几百行代码中。Review 一条 Spec 规则比 Review 它对应的所有代码实现高效得多。

**Spec 的验证可以自动化。** 一旦 Spec 被形式化（哪怕只是半形式化），它就可以变成自动化验证规则。代码是否满足 Spec，可以通过测试、静态分析、合约检查等确定性手段来验证，不需要人类的主观判断。

**Spec 的变更频率远低于代码。** 业务规则和架构约束的变化频率远低于实现代码。这意味着人类 Review 的工作量与系统复杂度之间保持了可管理的比例关系。

##### BDD 的第二春

这里有一个有趣的历史回环。行为驱动开发（BDD）在 2003 年被 Dan North 提出时，理念非常超前：用自然语言描述预期行为，然后自动化为测试。但 BDD 从未真正普及，核心原因是**在人工编码时代，写 Spec 被视为"额外工作"**。你已经要写代码了，还要先写一遍 Spec？

这其实也是我之前不看好 Spec 驱动 AI 编程的原因之一。但当我意识到这是我用之前的经验来评判新的变化产生的误解。

但在 Agent 时代，等式彻底翻转：

- **旧等式**：写 Spec（额外成本）+ 写代码（主要工作）= 总成本上升
- **新等式**：写 Spec（唯一人工工作）+ AI 生成代码（近零边际成本）= 总成本大幅下降

Spec 不再是"额外工作"，而是**唯一的人工工作**。BDD 曾经解决不了的问题，"谁来写那些 Spec？" 现在有了明确答案：**人类工程师的核心职能就是写 Spec**。

而且，用自然语言写 Spec 这件事，恰好是 LLM 最擅长理解和执行的。这创造了一个完美的分工：

```gherkin
Given 用户登录时输入了错误密码超过 5 次
When 用户再次尝试登录
Then 账户应被锁定 30 分钟
And 系统应发送安全通知邮件
```

人写 Spec。Agent 实现。BDD 框架验证。你不需要读实现代码，除非验证失败。

##### AI Native Code Review：五层信任模型

理解了范式迁移的方向后，**具体的替代方案是什么**？

答案不是找到"一个"替代 Code Review 的银弹，而是构建**多层确定性验证体系**：瑞士奶酪模型（Swiss Cheese Model）。每一层都不完美，但当你把足够多的不完美层堆叠起来时，漏洞就不会对齐。

(此图来自于 [latent.space](//latent.space) 博客文章，但我这里的五层模型跟它的有所区别)

##### Layer 0：编译时护栏（类型系统与静态分析）

这是最便宜、最快、最可靠的一层。类型系统不会疲劳，不会遗漏，不会被 diff 大小吓到。

在 AI Coding 时代，类型系统的价值不是降低了，而是极大地提升了。因为 AI 生成的代码最常见的问题恰好是类型系统擅长捕获的：接口不匹配、类型转换错误、空值处理遗漏。

有的人说，AI 都会写代码了，编程语言不重要了。但我认为，编程语言恰恰更加重要了，原因就是因为，有些语言天生就自带编译时护栏。这也是我选择 Rust 语言的原因之一

**实践建议**：如果你的项目还在用动态类型语言且没有类型标注，现在是迁移的最佳时机。除了 Rust，TypeScript 之于 JavaScript，mypy 之于 Python，都是在为 AI 生成的代码提供第一道确定性防线。

##### Layer 1：合约验证（前置条件、后置条件、不变量）

```python
// 合约定义（人类编写） 示例
@contract
def transfer_money(from_account, to_account, amount):
    # 前置条件
    require(amount > 0, "Amount must be positive")
    require(from_account.balance >= amount, "Insufficient funds")
    
    # 不变量
    total_before = from_account.balance + to_account.balance
    
    # ... AI 生成的实现代码 ...
    
    # 后置条件
    ensure(from_account.balance == old.from_account.balance - amount)
    ensure(to_account.balance == old.to_account.balance + amount)
    ensure(from_account.balance + to_account.balance == total_before)
```

合约验证的核心价值在于：**它把"正确性"从一个需要人类主观判断的模糊概念，转化为可以被机器精确检验的形式化属性。** AI 可以生成任何实现方式，只要它满足合约，我们就不关心具体实现细节。

##### Layer 2：BDD 验收测试（人类定义“什么是正确”）

这一层是人类审查点的核心锚定位置。人类不再审查代码，而是审查和编写验收标准：

```
Feature: 支付风控
  Scenario: 异常大额交易触发风控
    Given 用户历史月均消费为 5000 元
    When 用户发起单笔 50000 元的交易
    Then 交易应被暂时冻结
    And 系统应发送短信验证
    And 交易应在人工审批队列中出现

  Scenario: 正常消费不触发风控
    Given 用户历史月均消费为 5000 元
    When 用户发起单笔 3000 元的交易
    Then 交易应立即完成
```

这些验收标准由人类编写，它们本身就是需要"Review"的核心制品。但 Review Spec 比 Review Code 高效一个数量级。因为 Spec 是人类可理解的业务语言，而不是实现细节。

##### Layer 3：对抗性多 Agent 验证

这一层引入了智能体软件工程的独特优势。传统 Code Review 的一个核心问题是：写代码的人和审查代码的人共享相同的认知偏差。当 Review 者知道实现意图时，往往会不自觉地"脑补"代码的正确性。

多 Agent 对抗性验证通过架构设计消除了这个问题：

- **Blue Agent**：实现功能代码
- **Red Agent**：尝试破坏代码，生成攻击性测试用例和边界条件
- **Audit Agent**：独立检查安全、性能、合规性，不了解实现过程
- **Arbiter Agent**：综合所有信号做出最终判断

关键设计原则是**关注点分离 + 互不信任**。这和传统财务审计的逻辑一样，做账的和审计的必须是不同的主体。放到 Agent 世界里，使用不同的模型实例、不同的 system prompt、不同的上下文窗口，来保证审查的独立性。

这里有一个 Latent Space Engineering 博客中提到的有趣技巧：给 Review Agent 设定竞争框架，告诉每个子 Agent，发现最多合法问题的那个可以"获得奖励"。这个技巧利用了 LLM 在竞争性 prompt 下更加仔细的特性。

##### Layer 4：权限沙箱（最小权限原则的架构化）

大多数 Agent 框架对权限的处理是全有或全无。Agent 要么有 shell 访问权限，要么没有。但粒度至关重要。

```yaml
# 任务级权限定义
task: fix-date-parsing-bug
permissions:
  files:
    read: ["src/utils/dates.py", "tests/test_dates.py"]
    write: ["src/utils/dates.py", "tests/test_dates.py"]
  network: deny
  env_vars: deny
  
escalation_triggers:
  - pattern: "auth|authentication|authorization"
    action: require_human_review
  - pattern: "schema.*migration|ALTER TABLE"
    action: require_human_review
  - pattern: "dependency.*add|requirements.*txt"
    action: require_human_review
```

权限沙箱的价值在于：**即使前面所有层都失败了，Agent 也无法触碰它不应该触碰的东西。** 这是纵深防御的最后一道实质性屏障。

##### Layer 5：生产环境的最终防线（可观测性 + 快速回滚）

即使前面五层全部失效，系统仍然需要能够在生产环境中快速发现和修复问题：

- **金丝雀发布**：新变更先在 1% 的流量上验证
- **实时可观测性**：错误率、延迟、资源消耗的实时监控
- **自动回滚**：异常指标触发秒级自动回滚
- **特性开关**：任何新功能都可以在不部署新代码的情况下关闭

这一层的哲学是承认一个现实：**无论你的验证体系多么完善，bug 都会进入生产环境。** **传统 Code Review 试图在部署前消灭所有 bug，这在 AI 时代是不现实的**。

正确的策略是：**让 bug 的影响范围最小化，让修复速度最大化。**

#### AI Native Review 的估算范式

在之前的 AI Native 任务估算文章中，我们提出了两个核心度量单位：

- **轮次（Rounds）**：单 Agent 顺序执行的迭代次数
- **波次（Waves）**：多 Agent 并发执行的批次数

对于 Code Review，我们可以**用同样的框架来重新定义 Review 的成本度量**：

##### 传统度量（已过时）

Review 成本 = 人数 × 每人 Review 时间
≈ 2 人 × 1.5 小时 = 3 人时 / PR

这个度量方式假设 Review 是人力密集型活动，其成本与代码量成正比。在 AI 时代这个假设彻底失效。

##### AI Native 度量

验证成本 = Σ(各层验证波次 × 每波次计算成本)

Wave 0: 静态分析 + 类型检查 → ~10秒，零人工
Wave 1: 合约验证 + 单元测试 → ~30秒，零人工
Wave 2: BDD 验收测试 → ~2分钟，零人工
Wave 3: 多Agent对抗性审查 → ~5分钟，低 Token 成本
Wave 4: 人工 Spec/结果验收 → 仅在必要时，~15分钟

注意这个结构的关键特征：

1.  **成本递增**：越往后的层成本越高，但触发频率越低
2.  **确定性优先**：前三层完全确定性，不涉及人工判断
3.  **人工兜底**：人工只在最后一层、且仅在前面的层无法确认时介入
4.  **总成本与代码量解耦**：AI 生成 100 行还是 10000 行代码，Wave 0-3 的成本几乎不变

这就解决了 Latent Space 文章中描述的根本矛盾 "if the code review takes longer than the AI took to write the feature, the math doesn't make sense to higher ups"。在新范式下，验证成本与生成成本保持了合理的比例关系。

#### 迁移路径：从传统到 AI Native

范式迁移不会一夜之间发生。以下是一个渐进式的迁移路径：

##### 阶段一：增强（Augment）

在现有 Code Review 流程中引入自动化层：

- 部署 AI Code Review 工具（CodeRabbit、Graphite Diamond 等）作为第一轮筛选
- 在 CI 中增加静态分析和合约检查
- Review 者只关注 AI 工具未覆盖的高层问题

**人的角色**：仍然是代码的最终审批者，但工作量减少 30-50%。

##### 阶段二：分离（Separate）

将 Review 的五个职能显式分离，各用最优手段处理：

- 规范合规 → 自动化 linter（零人工）
- 正确性验证 → 合约检查 + BDD 测试（零人工）
- 安全性检查 → 专用安全扫描 + 对抗性测试（零人工）
- 架构一致性 → AI Agent 审查 + 架构约束配置（低人工）
- 知识传递 → 代码库文档自动生成 + 变更摘要（低人工）

**人的角色**：从"审查所有代码"转变为"审查架构决策和异常情况"。

##### 阶段三：上移（Elevate）

彻底将人的审查点从代码层上移到 Spec 层：

- 建立 Spec 驱动的开发流程
- 所有新功能从 BDD Spec 开始，而非从代码开始
- AI Agent 在 Spec 约束下生成代码，多层自动验证
- 人只 Review Spec 和最终验收结果

**人的角色**：意图的定义者和最终结果的验收者，不再接触代码 diff。

##### 阶段四：自治（Autonomize）

构建完全自治的验证流水线：

- 多 Agent 对抗性验证替代所有人工审查
- 人只在特定触发条件（安全敏感、架构变更、异常指标）下介入
- 系统具备自愈能力——发现问题后自动生成修复、验证、部署

**人的角色**：系统的架构师和异常的处理者，日常流程中不出现。

#### 尚未解决的问题

坦白来说，这个范式迁移还有几个关键问题还没有很好的答案：

**问题一：谁来 Review Spec？**

我们把审查点从代码上移到了 Spec，但 Spec 本身也会有错误。写一个完备的 Spec，其实并不比写代码简单。正如 Latent Space 评论区中一位读者指出的，"spec driven development 的倡导者对写出完整 Spec 的难度过于天真"。这是真实的挑战。

不过，Spec 错误和代码错误有一个关键区别：Spec 错误通常在验收测试阶段就能暴露（因为系统行为不符合预期），而代码级别的 bug 可能在 Spec 维度上看起来完全正确但在实现中引入了微妙的问题。**Spec 错误的反馈循环更短**，这部分缓解了这个问题。

**问题二：Agent 的知识边界**

当前的 AI Agent 缺乏对业务上下文的深度理解。它不知道你上周和客户开会做了什么决定，不知道你的产品路线图刚刚发生了转向。正如 Graphite 的 Greg Foster 所说，"Real code review demands domain expertise"。

这个问题的解决方向可能是更好的上下文注入机制，将业务决策、架构决定记录（ADR）、产品路线图等结构化为 Agent 可消费的上下文。但目前的上下文窗口和检索增强技术还不足以完全解决这个问题。随着记忆系统的逐渐成熟，我觉得这很快将不会是一个问题。

**问题三：责任归属，谁来背锅？**

如果 AI 生成的代码导致了安全事故，谁负责？传统 Code Review 有一个朴素但有效的机制，Approve 按钮背后是一个真实的工程师，他/她为这个决定承担责任。

在全自动化验证流水线中，责任归属变得模糊。这不仅是技术问题，更是组织和法律问题。在这个问题得到解决之前，完全消除人工审批在很多组织中是不可能的。特别是在金融、医疗、航空等受监管行业。

但，**如果问题一的答案是人类开发者负责 Review Spec 的话，那第三个问题就自然迎刃而解**。而第二个问题也会随着 AI 生态发展而很快被解决。

#### 结语：不是读得更快，而是不再需要读

让我们回到开篇的那组数据：PR 合并率暴涨 97.8%，Review 时间暴涨 91.1%。

面对这个数据，错误的反应是"我们需要更快的 Review 工具"。正确的反应是"我们需要重新思考 Review 本身的存在形式"。

Code Review 不是二十年前就有的传统。Latent Space 的文章提醒我们，代码审查直到 2012-2014 年才真正普及。在此之前，大量软件团队不做逐行代码审查，但也在成功交付软件。他们依赖的是什么？测试、渐进式发布、快速回滚，这些至今仍然有效的机制。

Code Review 的检查点之前也发生过迁移。我们从瀑布式签审迁移到了持续集成。我们可以再次迁移，从审查代码迁移到审查意图，从事后检验迁移到内建质量，从人眼扫描迁移到确定性验证。

智能体软件工程的核心公式在这里再次得到验证：

> **Spec 是控制面，Code 是数据面，Agent 是执行面。**

Review 的未来不是 "AI 帮人读代码"，而是 **"人根本不需要读代码"**。

人类最宝贵的认知资源：判断力、创造力、对业务的深度理解，应该用在定义"什么是正确的"（Spec），而不是检查"这段代码写得对不对"（Review）。

未来是：**快速发布，全面观测，极速回滚。**

而不是：**缓慢审查，遗漏 bug，在生产环境调试。**

我们不可能在阅读速度上超过机器。我们需要在思考质量上超越它们，在上游，在决策真正重要的地方。

---

## 智能体软件工程 #3｜重新思考版本控制

#### 引言：版本控制的隐含假设正在瓦解

2019 年底，Google 工程师 **Martin von Zweigbergk** 以个人项目的名义启动了一个版本控制系统。他把命令行工具取名为 **`jj`**（因为好打字）。

项目叫 **Jujutsu**，因为和 `jj` 匹配，好像没啥实际含义。

六年后，这个项目已经：

- 获得 **25k+ GitHub stars**
- 成为 **Google 内部版本控制演进的重要方向**
- 其设计理念开始被一个当初没有预料到的群体重新发现

> **AI Coding Agent**

时间来到 **2026 年 3 月**，几件事几乎同时发生：

- **OpenAI** 被报道正在构建 **GitHub 竞品**
  - 原因：GitHub 频繁服务降级
  - 对依赖 **AI Agent 持续集成** 的团队影响严重
- OpenAI 开源 **Symphony**
  - 一个 **Elixir 实现的 Agent 编排系统**
  - 核心理念：

  > 让工程师管理工作，而不是监督 Agent

  功能包括：

  - 为每个 Linear Issue 创建隔离 workspace
  - 启动 Codex 自动执行
  - 收集工作证明

- 一家创业公司 **JJHub**
  - 基于 **Jujutsu**
  - 构建 **Agent-Native 开发平台**

  其核心观点：

  > AI Agent 让一个小创业公司在 commit 量上看起来像 Google

- Rust 核心维护者 **Steve（Rust Book 作者）**
  - 在 2025 年基于 **JJ 创业**
  - 公司 **ersc**
  - 同时写了一篇 **JJ 教程**
- **GitHub**
  - 2026 年 1 月推出 **Agentic Workflows 技术预览**
  - 试图把 Agent 嵌入 CI/CD

所有这些动作指向一个事实：

> **Git 统治了 20 年的软件工程版本控制系统，其核心设计假设正在被 AI Coding Agent 系统性挑战。**

但挑战 Git **不是目的**。

版本控制的根本目标一直是：

> **安全地管理代码变更的历史与并发**

在 **智能体软件工程（Agentic Software Engineering）** 框架下：

- 目标没有变
- **实现方式必须彻底重构**

#### 第一部分：Git 的五个隐含假设

Git 的设计建立在 **人类开发者** 的行为模式上。

在 **Agent 时代**，这些假设正在逐一瓦解。

#### 假设一：操作者理解上下文

Git 的所有交互设计都假设：

> 操作者理解自己在做什么

例如：

```bash
git add -p
git rebase -i
git merge
```

这些操作都要求：

- 理解代码语义
- 理解 commit 依赖关系
- 做正确决策

而 **Agent 不理解上下文**。

Agent：

- 基于 **统计推理**
- 适合执行 **确定性命令序列**

例如：

```bash
git add -A
git commit -m "..."
```

但当遇到：

```bash
git rebase -i
```

需要：

- 打开文本编辑器
- 修改 `pick / squash / edit`

这对 Agent 是 **脆弱操作**。

#### 假设二：操作是顺序的

Git 的并发模型假设：

> 一个 working directory 只有一个操作者

证据：

- `git stash`
- `git rebase in progress`

例如：

```text
.git/index.lock
```

在 Agent 时代：

- 并发是常态
- 一个 orchestrator 可能管理 **10 个 Agent**

Git 的锁机制变成 **瓶颈**。

#### 假设三：变更需要显式暂存

Git 的 **staging area** 是为人类设计的。

目的：

> 精选 commit 内容

流程：

```text
working dir
↓
staging
↓
commit
```

但 Agent：

- 不需要精选
- 任务 workspace 是隔离的

结果：

```bash
git add -A
```

成了 **100% 仪式操作**

问题：

- 消耗 token
- 增加工具调用
- 没有决策价值

#### 假设四：分支需要命名

Git 分支必须有名字：

```text
feature/login
bugfix/auth
```

人类需要沟通：

> 我在 feature/login 分支

但 Agent：

- 分支是临时的
- 会话级
- 一次性

分支命名成为 **无意义开销**

更深层问题：

Git 将：

```text
branch pointer
commit hash
```

绑定。

当 commit amend 时：

```text
hash 改变
```

引用全部失效。

这对 **自动化系统** 是巨大协调成本。

#### 假设五：冲突必须立即解决

Git：

- merge 冲突
- rebase 冲突

会 **阻塞流程**。

例如：

```text
<<<<<<<
=======
>>>>>>>
```

Git 进入：

```text
rebase in progress
```

等待人类。

对于 Agent 编排系统：

这是 **灾难性设计**。

因为：

- 一个 Agent 阻塞
- 整个 orchestrator 卡住

#### 第二部分：Jujutsu 如何解决这些问题

Jujutsu（jj）不是：

> 更好的 Git CLI

而是：

> **新的版本控制数据模型**

特点：

- Git backend
- Rust 实现
- gitoxide

#### 解决方案一：一切皆 Commit

Git 有四种状态：

- working dir
- staging
- stash
- commit

jj：

> 统一为 **commit**

你的工作副本：

```text
@
```

就是一个 commit。

##### Git

```bash
git add -A
git commit
```

##### jj

只需要：

```text
编辑文件
```

系统自动 snapshot。

示例：

```bash
vim src/auth.rs
```

完成。

然后：

```bash
jj describe -m "实现登录"
```

核心机制：

任何 jj 命令：

```bash
jj status
jj log
jj new
```

都会：

> 自动 snapshot working copy

Git 心智模型：

```text
文件修改
↓
未提交脏状态
```

jj 心智模型：

```text
文件修改
↓
@ commit 最新内容
```

#### split：替代 staging

```bash
jj split
```

交互式拆分 commit。

Git 思路：

```text
先选
再存
```

jj 思路：

```text
先存
再拆
```

优势：

> 永远不会丢数据

#### 解决方案二：Change ID

jj 引入两层标识：

##### Revision

不可变，类似 commit hash。

##### Change ID

稳定标识。

无论 amend：

```text
Change ID 不变
```

这对 Agent 编排非常关键。

#### 解决方案三：冲突是一等对象

Git：

```text
冲突 = 状态
```

jj：

```text
冲突 = 数据
```

commit 可以：

```text
包含冲突
```

但仍然是合法 commit。

内部结构：

```text
conflict tree
```

示例：

```text
base
side_1
side_2
```

而不是文本标记。

优势：

- rebase 永远成功
- 不阻塞 pipeline
- 冲突可延迟处理

#### 冲突解决传播

如果：

```text
A ← B' ← C'(冲突) ← D'(冲突)
```

解决 C：

```text
C''
```

jj 自动：

```text
rebase D
```

可能自动解决。

Git 需要：

```text
逐个解决
```

#### 解决方案四：Operation Log

Git：

```text
reflog
```

用途有限。

jj：

```text
operation log
```

示例：

```bash
jj op log
```

撤销：

```bash
jj undo
```

回到任意操作：

```bash
jj op restore <id>
```

对于 Agent：

这是 **时间机器**。

#### 解决方案五：自动 Rebase

当 commit 修改：

```text
B → B'
```

所有子 commit 自动 rebase。

即使冲突，也不会阻塞。

#### 解决方案六：workspace

Git：

```text
worktree
```

复杂状态包括：

- HEAD
- index
- working dir
- rebase state

jj workspace：

```text
@
```

只有一个状态。

示例：

```bash
jj workspace add ../feature-login
jj workspace add ../bugfix-auth
```

每个 workspace：

```text
@ → change ID
```

编排系统只需要追踪：

```text
change ID
```

复杂度：

```text
多维 → 一维
```

#### 第三部分：Spec-Change 绑定

智能体软件工程模型：

```text
Spec = 控制面
Code = 数据面
Agent = 执行面
```

任务规格：

```text
Task Contract
```

包含：

- Intent
- Decisions
- Boundaries
- Completion Criteria

当前问题：

Spec 与代码：

```text
弱关联
```

例如：

```text
Issue #42
```

只是 commit message。

jj 提供解决方案：

##### Change ID

稳定追踪。

##### 元数据

Spec 可绑定 Change。

形成：

```text
Spec
↓
Change
↓
Verification
↓
Acceptance
```

#### 第四部分：Agent-Native VCS 还缺什么

jj 解决了 **80% 问题**。

剩下需要：

#### 原语一：验证状态

Change 内置：

```text
verification
```

例如：

```text
type check PASS
BDD PASS
adversarial PENDING
```

#### 原语二：Agent 身份

需要记录：

```text
agent id
role
permissions
orchestrator
```

#### 原语三：时间线视图

Git DAG：

```text
不可读
```

Agent 系统需要：

```text
timeline
```

按以下维度过滤：

- Agent
- Contract
- module

#### 第五部分：从 Code Review 到 Contract Acceptance

传统流程：

```text
branch
↓
PR
↓
review
↓
merge
```

问题：

1. review 对象错了
2. branch 粒度错了
3. merge 门控错了

Agent-Native 模型：

```text
Contract
↓
Changes
↓
Verification
↓
Acceptance
```

人类审查：

```text
Contract
```

机器验证：

```text
Code
```

#### 第六部分：渐进采用路径

##### Level 0

Git 仓库 colocate jj：

```bash
jj git init --colocate
```

##### Level 1

Agent workspace 使用 jj。

##### Level 2

编排系统使用：

```text
change ID
```

追踪任务。

##### Level 3

冲突即数据。

冲突：

```text
不是错误
```

而是：

```text
待处理状态
```

#### 第七部分：总结

Git → jj → Agent-Native VCS

jj 已经解决：

```text
80% Agent 摩擦
```

核心设计：

- 一切皆 commit
- change ID
- 冲突即数据
- 自动 rebase
- operation log

#### 结语

版本控制系统反映了时代的软件工程模式。

##### CVS / SVN

中央服务器，顺序提交。

##### Git

分布式，分支协作。

##### Agent 时代

需要：

- 自动快照
- 稳定标识
- 冲突即数据
- 原子操作
- 完整审计

Git 没有错。

它为人类开发者服务了 **20 年**。

但它的核心假设：

- 操作者理解上下文
- 操作是顺序的
- 必须显式暂存
- 冲突必须立即解决

在 Agent 时代变成了 **摩擦力**。

**Jujutsu 提供了一条现实路径：**

- 兼容 Git
- 不破坏生态
- 引入 Agent-Native 模型

当：

```text
Spec = 控制面
Code = 数据面
Agent = 执行面
```

而：

```text
Version Control = 数据面的物理层
```

当这个物理层从：

```text
为人类设计的锋利刀具
```

变成：

```text
为 Agent 设计的安全电动工具
```

整个 **智能体软件工程体系的设计空间将被重新打开**。

---

## 智能体软件工程 #4｜当 Agent 写完代码，谁来说「可以合并」？

在这个系列的前两篇中，我们分别拆解了两个问题：

- 当 Agent 每天可以产出几十个 PR 时，传统的 Code Review 流程会崩溃（#2）
- 当多个 Agent 并发工作时，Git 的心智模型会成为瓶颈（#3）

这两个问题指向同一个更根本的空白：

**在 Agent 完成编码之后、代码合并到主分支之前，缺少一个确定性的、机器可执行的质量门禁。**

传统流程中，这个门禁是 **人类 reviewer**。

流程通常是：

1. 打开 PR
2. 阅读几百行 diff
3. 在脑子里模拟代码行为
4. 判断“代码是否正确”
5. 点击 Approve

这个过程依赖三种资源：

- 经验
- 注意力
- 时间

而在 Agent 时代，这三者 **都是不可扩展资源**。

CI 只是机器门禁，但它只检查：

> “已有测试是否通过”

而不是：

> “这次 Agent 的实现是否符合任务意图”

Agent 可以让所有测试通过，但实现完全错误的功能。

因为 CI 并不知道：

**这次任务的意图是什么。**

这就是 **agent-spec** 要解决的问题。

agent-spec 不是一个“更好的 Code Review 工具”，而是一个**不同的范式**：

- 审查对象：**代码 → 合约**
- 审查时间：**编码之后 → 编码之前**
- 审查执行者：**人 → 机器**

---

### 一、审查点的位移

agent-spec 的核心理念：

> 把人类的审查点从「代码写完之后」移动到「代码写之前」。

传统流程的人类时间分配：

_（未完待续）_
