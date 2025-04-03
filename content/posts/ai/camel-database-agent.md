---
title: "CAMEL DatabaseAgent: 使数据查询变得像日常对话一样自然"
date: 2025-04-03T20:24:14+08:00
tags: [text2sql,ai]
categories: [ai]
draft: false
---

作为一名数据工程师，经常面临这样的挑战：业务分析师需要从数据库中提取信息，但他们并不具备编写SQL的技能。每次他们需要一个新报表或数据视图时，都要依赖技术团队的支持，这种情况既降低了效率，也增加了沟通成本。

今天，我很高兴向大家介绍一个开源工具 CAMEL DatabaseAgent，它能够彻底改变这种工作模式。

## 什么是CAMEL DatabaseAgent？

CAMEL DatabaseAgent是一个基于[CAMEL-AI框架](https://github.com/camel-ai/camel)的开源智能体，它能够帮助开发者构建自然语言数据库查询解决方案。简单来说，它允许用户使用自然语言提问，并自动将这些问题转换为准确的SQL查询，然后执行并返回结果。

想象一下，当你的同事问"哪些客户在2009年的消费超过了100美元？"时，不需要编写一行代码，系统就能直接给出答案。这正是CAMEL DatabaseAgent所实现的功能。

## 核心组件

CAMEL DatabaseAgent由三个核心组件组成：

1. **DataQueryInferencePipeline**：将数据库模式和样本数据转换为查询的少样本示例（包括问题和对应的SQL）的管道。
2. **DatabaseKnowledge**：一个向量数据库，用于存储数据库模式、样本数据和查询的少样本示例。
3. **DatabaseAgent**：基于CAMEL框架的智能代理，利用DatabaseKnowledge来回答用户问题。

## 支持的数据库系统

目前，CAMEL DatabaseAgent支持以下数据库系统：

- SQLite
- MySQL
- PostgreSQL

并且所有操作都可以在只读模式下进行，确保数据安全。

## 实际使用体验

我最近在一个音乐分发平台的数据库上测试了这个工具，体验非常棒。它不仅能够准确理解各种复杂的业务问题，还能生成优化的SQL查询并以清晰的表格形式展示结果。

例如，当我问"查找包含超过10首曲目的播放列表名称"时，它立即生成了正确的SQL查询：

![image](/images/posts/ai/camel-database-agent/screenshot-question-1.png)

更令人印象深刻的是，CAMEL DatabaseAgent还能自动分析你的数据库结构，生成数据库概览和推荐问题，帮助用户更好地了解和利用数据库。

场景一: 统计2009年售出的曲目总数和相应的总销售金额，涉及多表连接和时间范围过滤。
![image](/images/posts/ai/camel-database-agent/screenshot-question-2.png)
场景二: 按音乐类型分组统计2009年的总收入，需要四个表连接和时间过滤条件。
![image](/images/posts/ai/camel-database-agent/screenshot-question-3.png)
场景三: 查找销售额最高的艺术家，需要多表连接、分组、排序和结果限制。
![image](/images/posts/ai/camel-database-agent/screenshot-question-4.png)
场景四: 计算购买过雷鬼音乐的不同客户数量，使用子查询和多表连接来筛选特定音乐类型。
![image](/images/posts/ai/camel-database-agent/screenshot-question-5.png)
场景五: 计算美国客户占总客户的百分比，使用条件计数和百分比计算。
![image](/images/posts/ai/camel-database-agent/screenshot-question-6.png)
场景六: 找出支持客户数量最多的员工，通过左连接处理可能没有客户的员工情况。
![image](/images/posts/ai/camel-database-agent/screenshot-question-7.png)

## 多语言支持

作为一个国际化的工具，CAMEL DatabaseAgent支持基于多种语言进行训练和交互。你可以用中文、英文、韩文其他语言提问，系统都能理解并给出相应的回答。这对于多语言环境的团队协作非常有价值。

![image](/images/posts/ai/camel-database-agent/screenshot-question-chinese.png)
![image](/images/posts/ai/camel-database-agent/screenshot-question-korean.png)

## 快速上手

想要尝试CAMEL DatabaseAgent非常简单，下载项目并使用内置的 CLI 命令行工具就可以轻松连接到本地的数据库：

```shell
git clone git@github.com:coolbeevip/camel-database-agent.git
cd camel-database-agent
pip install uv ruff mypy
uv venv .venv --python=3.10
source .venv/bin/activate
uv sync --all-extras

# 设置环境变量
export OPENAI_API_KEY=sk-xxx
export OPENAI_API_BASE_URL=https://api.openai.com/v1/
export MODEL_NAME=gpt-4o-mini

# 连接到示例数据库
python camel_database_agent/cli.py \
--database-url sqlite:///database/sqlite/music.sqlite
```

第一次连接时会花几分钟生成知识数据，之后使用就会非常流畅。

## 开发者集成

对于想要在自己的应用中集成CAMEL DatabaseAgent的开发者，我们提供了简洁的API：

```python
# 安装依赖库
pip install camel-database-agent

# 初始化数据库代理
database_agent = DatabaseAgent(
    interactive_mode=True,
    database_manager=DatabaseManager(db_url=database_url),
    model=ModelFactory.create(...),
    embedding_model=OpenAIEmbedding(...)
)

# 训练代理对数据库模式的知识
database_agent.train_knowledge(level=TrainLevel.MEDIUM)

# 使用自然语言执行查询
response = database_agent.ask(
    session_id=str(uuid.uuid4()),
    question="列出所有包含超过5首曲目的播放列表"
)
```

## 结语

CAMEL DatabaseAgent代表了我对数据库交互未来的愿景，使数据查询变得像日常对话一样自然。无论你是数据库管理员、业务分析师还是开发人员，这个工具都能显著提高你的工作效率。

我欢迎大家试用CAMEL DatabaseAgent，并通过GitHub提交反馈和建议。让我们一起打造更智能、更直观的数据库查询体验！

[GitHub链接](https://github.com/coolbeevip/camel-database-agent)

如果你觉得这个项目有价值，别忘了给它点个星⭐！