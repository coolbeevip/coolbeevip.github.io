---
title: "Important JVM Options"
date: 2019-08-06T13:24:14+08:00
tags: [jvm]
categories: [java]
draft: false
---

## Heap Memory

#### -XX:MetaspaceSize

Metaspace 空间初始大小，如果不设置的话，默认是20.79M。这个初始大小是触发首次 Metaspace Full GC 的阈值，例如 `-XX:MetaspaceSize=128M`  

#### -XX:MaxMetaspaceSize

Metaspace 最大值，默认不限制大小，但是线上环境建议设置，例如 `-XX:MaxMetaspaceSize=512M`

## GC

#### -Xnoclassgc

表示关闭JVM对类的垃圾回收，缺省情况下，当一个类没有任何活动实例时，JVM 就会从内存中卸装该类，但是这样会使性能下降。如果关闭类垃圾回收，就可以消除由于多次装入和卸装同一个类而造成的开销

#### -XX:+UseParNewGC

设置年轻代为并行收集

#### -XX:MaxTenuringThreshold

控制新生代需要经历多少次GC​晋升到老年代中的最大阈值，默认值 15

#### -XX:+CMSParallelRemarkEnabled

CMS收集算法步骤如下：初始标记 -> 并发标记 -> 重新标记 -> 标记清除。
其中 初始标记和重新标记都需要STW，即暂停用户线程。
CMSParallelRemarkEnabled参数可以让重新标记阶段进行并行重新标记，减少暂停时间

#### -XX:SurvivorRatio

设置 Eden、S0、S1 分配比例，默认值是 8

-XX:SurvivorRatio=5 表示 Eden 占 50%，S0、S1 平分剩余空间

#### -XX:+UseCompressedOops

In short, don't turn it on, use a version which has it on by default.

https://stackoverflow.com/questions/11054548/what-does-the-usecompressedoops-jvm-flag-do-and-when-should-i-use-it

#### -XX:+DisableExplicitGC

禁止 `System.gc()` 触发 GC 操作，当没有开启 DisableExplicitGC 这个参数时,你会发现JVM每个小时会执行一次Full GC,这是因为JVM在做分布式GC,为RMI服务的,
可以通过 sun.rmi.dgc.server.gcInterval 这个参数来修改 GC 间隔,默认是一个小时

```shell
-Dsun.rmi.dgc.server.gcInterval=7200000
-Dsun.rmi.dgc.client.gcInterval=7200000
```

**使用了 DirectByteBuffer 的不要使用此参数**

#### -XX:ParallelGCThreads

并行 GC 线程的数量，建议和 CPU 数量相当

#### -XX:+PrintGCDetails

开启 GC 日志

## CMS

#### -XX:+UseConcMarkSweepGC

使用CMS垃圾回收器

#### -XX:CMSInitiatingOccupancyFraction

CMS垃圾收集器，当老年代达到 N% 时，触发CMS垃圾回收

#### -XX:+UseCMSInitiatingOccupancyOnly 

用设定 CMSInitiatingOccupancyFraction 参数永久有效，否则只在第一次生效

#### -XX:+UseCMSCompactAtFullCollection

是否在 Full GC 时压缩

#### -XX:+CMSFullGCsBeforeCompaction

在上一次CMS并发GC执行过后，到底还要再执行多少次 Full GC才会做压缩。默认是0

#### -XX:+CMSClassUnloadingEnabled

GC也会扫描PermGen，并删除不再使用的类

#### -XX:+ExplicitGCInvokesConcurrent

使用 CMS 收集器来触发 Full GC

## GC LOG

#### -XX:+UseGCLogFileRotation

开启GC日志滚动记录功能，要求必须设置 -Xloggc参数

#### -XX:NumberOfGCLogFiles

设置滚动日志文件的个数，必须大于等于1

#### -XX:GCLogFileSize

设置滚动日志文件的大小，必须大于8k

#### -XX:+PrintGCDetails

输出详细日志

#### -XX:+PrintGCTimeStamps

JVM启动的时候的相对时间

#### -XX:+PrintGCDateStamps

打印具体的时间