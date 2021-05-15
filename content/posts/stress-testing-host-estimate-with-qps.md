---
title: "Estimate host capacity based on QPS"
date: 2018-03-07T13:24:14+08:00
categories: [stress,test,host,qps]
draft: false
katex: true
markup: "mmark"
type: "post"
---

通过单个服务器压测的 QPS 估算需要的服务器数量 

#### 已知 QPS 和期望每笔耗时，估算服务器数量

服务器数量 $$ = QPS \div (1000 \div 每笔毫秒) \div 每服务器CPU个数 $$

例如：

* QPS：每秒处理3200笔
* 每笔毫秒：50ms
* 每个服务器CPU个数：16

服务器数量 $$ 3200_{qps} \div (1000_{ms} \div 50_{ms}) \div 16_{cpu} = 10_{台} $$

#### 已知 QPS 以及服务器数量，估算每笔耗时

每笔耗时毫秒 $$ = 1000 \div ( QPS \div ( 服务器数量 \times 每服务器CPU个数 ) ) $$

例如：

* QPS：每秒处理3200笔
* 服务器数量：10
* 每服务器CPU个数：16

每笔耗时毫秒 $$ 1000 \div ( 3200 \div ( 10 \times 16 ) ) = 50_{ms}$$

