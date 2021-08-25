---
title: "Domain-Driven Artifacts Introduces"
date: 2021-08-22T00:24:14+08:00
tags: [domain-driven]
categories: [ddd]
draft: true
---

本文将通过一个简单的例子练习 DDD 的设计过程 

## 需求

一个IT外包公司，他们有一些员工和 IT 自由职业者，他们希望搭建一个平台管理他们的客户、项目、自由职业者以及时间表

* 必须提供自由职业之的搜索目录
* 每个自由职业者允许设置多个联系方式
* 必须提供可搜索的项目目录
* 必须提供可搜索的客户目录
* 必须维护合同下的自由职业者的时间表

## 传统方式

#### 软件建模

通常设计人员会根据需求进行软件建模

![mvc-class-diagram](/images/posts/ddd/example/mvc-class-diagram.png)

这是以数据为中心采用面向对象软件模型，他包含了客户、项目、自由职业者、时间表等对象，甚至还包含用于维护这些对象的用户设计。你甚至可以直接将它转换为一个实体关系模型(Entity Relationship Diagram)。
在通过传统软件分层设计 SO、DAO、DTO、DO 你基本可以动手开始开发这个项目，我相信很快就可以开发完成。

当然本文是为了介绍 DDD。所以请我们来看看这个软件建模有什么缺陷

* 首先这个对象图很大，在重负载时（内存中加载了大量 Freelancer)，如果不使用延迟加载，会占用大量内存。
* Freelancer 类包含一个项目列表。这也意味着在不修改 Freelancer 对象的情况下无法添加项目。这可能会导致重负载下的事务失败，因为可能有多个用户为同一客户添加项目。
* ContactInformation 中使用 int 表示联系方式，这看起来有点像实体模型(Entity)
* 没有业务逻辑，无法根据这个模型创建出业务服务来存储和检索服务

#### 行为建模

让我们设计一个行为，即 **自由职业者更新地址**，下图描述了 Freelancer 地址变更行为，如果你了解 PO, BO, VO, DTO, POJO, DAO 那么你可以很容易的看懂下图

![mvc-behavior](/images/posts/ddd/example/mvc-behavior.png)

* 在这个图中我们很难直观的看到业务行为，这些行为都隐藏在方法名中，貌似每个业务行为都一样，都是从上到下的不同方法调用。用例隐含在方法名中。
* 我们通过 Freelancer 的 setter 方法修改属性，没有调用上下文。我们如何判断此修改的行为
* 我们通过 DTO 中的 getAddress() 方法隐式的体现出地址的概念（初期需求可能就是返回 name、zipCode、city 的字符串组合）。就像联系方式类型一样通过一个简单的属性体现一种概念。

## DDD 方法

DDD 不是银弹，如果你的业务简单，使用类似以上的方式也未尝不可。那么如果我们用 DDD 的方式如何建模，以及有哪些好处呢。

#### 域划分

我们可以将一个大域划分成多个子域，这可以帮助我们设计更好的解决方案。分离的域可以很容易地可视化。在 DDD 术语中，这称为上下文映射，它是任何进一步建模的起点

![ddd-domain](/images/posts/ddd/example/ddd-domain.png)

现在我们需要将子域(Subdomain)与我们的解决方案设计对齐，我们需要形成一个界限上下文(Bounded Context)。最好将一个子域与一个限界上下文对应

在开始前你可以先了解一下[核心构造块(Building Blocks)]()的一些概念和模式，這些核心构造块面向对象领域建模的一些核心最佳实践的浓缩。这些核心构造块可以使得我们的设计更加标准有序。
根据 DDD 方法重新设计后有哪些改进

![ddd-class-diagram](/images/posts/ddd/example/ddd-class-diagram.png)

* 根据划分的子域使用有界上下文(Bounded Contexts)隔离，每个子域之间没有直接关系。
* 多个子域的相交部分，通过一组通用类型(Common Type) 关联，这组通用类型在 DDD 中成为共享核心(Shared Kernel)
* "自由职业者管理子域"，"客户管理子域"，"项目管理子域" 不可替代，所以这三个域是核心域(Core Domain)
* "身份和访问管理子域" 可以被现有 IAM 方案代替，所以是通用子域(Generic Subdomain)
* 每个有界上下文中都有聚合根(Aggregation Root)和值对象(Value Object)，通过聚合根确保了封装性。
* 聚合(Aggregation)和实体(Entity)是唯一具有ID的东西
* 值对象(Value Object)看成一个不可变的整体，不需要唯一ID，只描述是什么，不描述是哪一个。每个值对象的修改方法都会返回一个新实例，例如：`Address` 的 `Address changeCity(String city)` 方法

### 行为设计

我们同样对 **自由职业者更新地址** 行为进行建模，通常每种类型的聚合（Freelancer Aggregate）都应该有一个存储库，所以下图中我们定义了 FreelancerRepository，使用 FreelancerRepository 可以对自由职业者实现增加、修改、删除、查询等一系列操作。**请注意，存储库是用业务术语描述的接口。我们将在下一章讨论实现**

下图中你会看到一个新的组件 **Client** 客户端接口，客户端可以是一个 SOAP 或者 REST API。
客户端向 **FreelancerApplicationService** 发送 **FreelancerMovedCommand** 命令。 
**FreelancerApplicationService** 将命令 **FreelancerMovedCommand** 通过 **FreelancerRepository** 加载域模型 **Freelancer** 并调用 Freelancer 聚合上的 movedTo() 完成操作。 
**FreelancerApplicationService** 形成事务边界，每次调用都会产生一个新事务，将事务控制置于域模型之外总是一个不错的选择。事务控制更多是技术问题而不是业务问题，因此不应在域模型中实现

![ddd-behavior](/images/posts/ddd/example/ddd-behavior.png)

#### 应用架构

![ddd-application](/images/posts/ddd/example/ddd-application.png)

## 战略模式

Domain, and Subdomains:As mentioned above, a Domain is a sphere of knowledge. A Domain can be split into Subdomains if it is too large. The Domain is usually known as the problem space.

Bounded Context:A Bounded context should be aligned with a Domain or a Subdomain. There is one Ubiquitous Language applied within a Bounded Context. A Bounded Context is usually the solution space, where we design our software or business solution.

Context Map:A Context Map displays the alignment of Domains, Subdomains and their Bounded Contexts. A Context Map also shows dependencies between Bounded Contexts. Such dependencies can be upstream or downstream. Dependencies show where integration patterns should or must be applied.

## 战术模式

**实体(Entity)**: An object that is not defined by its attributes, but rather by a thread of continuity and its identity.

Example: Most airlines distinguish each seat uniquely on every flight. Each seat is an entity in this context. However, Southwest Airlines (or EasyJet/RyanAir for Europeans) does not distinguish between every seat; all seats are the same. In this context, a seat is actually a value object

**值对象(Value Object)**: An object that contains attributes but has no conceptual identity. They should be treated as immutable.

Example: When people exchange dollar bills, they generally do not distinguish between each unique bill; they only are concerned about the face value of the dollar bill. In this context, dollar bills are value objects. However, the Federal Reserve may be concerned about each unique bill; in this context each bill would be an entity.

**聚合根(Aggregate)**: A collection of objects that are bound together by a root entity, otherwise known as an aggregate root. The aggregate root guarantees the consistency of changes being made within the aggregate by forbidding external objects from holding references to its members. Aggregates can also be seen as a kind of bounded context, giving the root entity and the whole object graph a context in which they are used.

Example: When you drive a car, you do not have to worry about moving the wheels forward, making the engine combust with spark and fuel, etc.; you are simply driving the car. In this context, the car is an aggregate of several other objects and serves as the aggregate root to all of the other systems. A steering wheel can be rotated, this is it’s context within the car aggregate. It can also be produced or recycled. This usually happens not within the driving car context, so this would be another aggregate, probably referencing the car as well.

**(领域事件)Domain Events**:Domain events can be used to model distributed systems. The model will become more complex, but it can be more scalable. Domain Events are often used in an Event Driven Architecture Service: When an operation does not conceptually belong to any object. Following the natural contours of the problem, you can implement these operations in services.

**存储库(Repository)**: Repositories save and retrieve Entities or Aggregates to or from the underlying storage mechanism. Repositories are part of the domain model, so they should be database vendor independent. Repositories can use DAOs(Data Access Objects) for retrieving data and to encapsulate database specific logic from the domain. Note: Hibernate is also a Data Access Object! Wrapping Hibernate inside a DAO can be an overkill. Repositories can use an Aggregate Oriented Database.

**模块(Packages)**:Components with high cohesion should be packaged together. Modules are defined by business dependencies, not by the technical architecture.

Example: The Bill Aggregate and the Bill Repository should be put into the same module, as they are very tightly coupled.

**工厂(Factory)**: methods for creating domain objects should delegate to a specialized Factory object such that alternative implementations may be easily interchanged.

## 参考

https://www.mirkosertic.de/blog/2013/04/domain-driven-design-example/
https://www.mirkosertic.de/blog/2012/07/domain-driven-design-overview-and-building-blocks/
https://www.jianshu.com/p/570d29bdda48
https://www.itread01.com/content/1589857384.html
https://yasinshaw.com/articles/78