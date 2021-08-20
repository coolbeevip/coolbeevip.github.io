---
title: "Using Redis as a Cache"
date: 2020-08-19T13:24:14+08:00
tags: [redis]
categories: [redis]
draft: false
type: "post"
---

当 Redis 用作缓存时，通常可以方便地让它在您添加新数据时自动驱逐旧数据。Redis 支持 6 种驱逐策略，你可以使用 `maxmemory-policy` 修改驱逐策略。默认是不驱逐，也就是说如果使用的内存超过了 `maxmemory` 限制，将提示 OOM。

你可以在 redis.conf 通过 `maxmemory 2gb` 设置，也可以通过 `config set maxmemory 2gb` 方式动态设置，**注意：** 在64bit系统下，maxmemory设置为0表示不限制内存使用，在32bit系统下，maxmemory不能超过3GB

## 驱逐策略

* **noenviction:** 禁止驱逐数据(默认淘汰策略) 当 redis 内存数据达到 maxmemory，在该策略下，直接返回OOM错误；
* **volatile-lru:** 驱逐已设置过期时间的内存数据集中最近最少使用的数据；
* **volatile-ttl:** 驱逐已设置过期时间的内存数据集中即将过期的数据；
* **volatile-random:** 驱逐已设置过期时间的内存数据集中任意挑选数据；
* **allkeys-lru:** 驱逐内存数据集中最近最少使用的数据；
* **allkeys-random:** 驱逐数据集中任意挑选数据；
* **volatile-lfu** 驱逐已设置过期时间的内存数据集中使用频率最少的数据；（since 4.0）
* **allkeys-lfu** 驱逐内存数据集中使用频率最少的数据；（since 4.0）

如果 KEY 未设置过期时间，那么 volatile-random、volatile-ttl 和 volatile-lru 等同于 noenviction。

## 驱逐程序如何运作

重要的是要了解驱逐过程的工作方式如下：

1. 客户端运行新命令，导致添加更多数据。
2. Redis 检查内存使用情况，如果大于 maxmemory limit ，则根据策略驱逐键。
3. 执行新命令，等等。

所以我们不断地越过内存限制的边界，越过它，然后通过驱逐键返回到限制之下。 如果某个命令导致使用大量内存一段时间，则内存限制可能会明显超出。
