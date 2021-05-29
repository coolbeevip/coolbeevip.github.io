---
title: "GraphQL Tools Schema Parser"
date: 2021-05-29T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---
SYSTEM

MacBook Pro 16G

JVM

```properties
-Xmx4g
-Xms4g
-Xss256k
-XX:MetaspaceSize=128m
-XX:MaxMetaspaceSize=512m
-Xnoclassgc
-XX:+UseConcMarkSweepGC
-XX:+UseParNewGC
-XX:ParallelGCThreads=12
-XX:MaxTenuringThreshold=15
-XX:+ExplicitGCInvokesConcurrent
-XX:+CMSParallelRemarkEnabled
-XX:SurvivorRatio=8
-XX:CMSInitiatingOccupancyFraction=65
-XX:+UseCMSInitiatingOccupancyOnly
-XX:+UseCMSCompactAtFullCollection
-XX:+CMSClassUnloadingEnabled
-XX:+UseGCLogFileRotation
-XX:NumberOfGCLogFiles=10
```

CPU Flame Graph

![](/images/posts/misc/graphql-tools-cpu-flame-graph-0.png)

GrpaphQL Schema Parser

![](/images/posts/misc/graphql-tools-cpu-flame-graph-2.png)

Slow Method

![](/images/posts/misc/graphql-tools-call-slow.png)
