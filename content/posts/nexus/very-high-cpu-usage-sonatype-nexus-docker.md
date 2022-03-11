---
title: "Very High CPU usage Sonatype Nexus Docker"
date: 2022-03-11T13:24:14+08:00
tags: [nexus]
categories: [nexus]
draft: false
---

本文记录 Sonatype Nexus 私服遇到性能劣化问题的分析过程（未解决）

## 环境说明

使用 `sonatype/nexus3` 镜像启动，通过挂载卷存储数据

Nexus 配置，可以看到关键配置 `-Xms8g -Xmx8g -XX:MaxDirectMemorySize=35158M -XX:+UseConcMarkSweepGC`

```shell
200      105083 105062 99 11:01 ?        2-00:51:44 /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.282.b08-2.el8_3.x86_64/jre/bin/java -server -Dinstall4j.jvmDir=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.282.b08-2.el8_3.x86_64/jre -Dexe4j.moduleName=/opt/sonatype/nexus/bin/nexus -XX:+UnlockDiagnosticVMOptions -Dinstall4j.launcherId=245 -Dinstall4j.swt=false -Di4jv=0 -Di4jv=0 -Di4jv=0 -Di4jv=0 -Di4jv=0 -Xms8g -Xmx8g -XX:MaxDirectMemorySize=35158M -XX:ActiveProcessorCount=16 -XX:+UseParNewGC -XX:ParallelGCThreads=12 -XX:MaxTenuringThreshold=6 -XX:SurvivorRatio=5 -XX:+UseConcMarkSweepGC -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=65 -XX:+UseCMSInitiatingOccupancyOnly -XX:+UseCMSCompactAtFullCollection -XX:+CMSClassUnloadingEnabled -XX:+DisableExplicitGC -XX:+PrintGCDetails -Xloggc:/nexus-data/vgc/nexus-1646967690.vgc -XX:+UnlockDiagnosticVMOptions -XX:+LogVMOutput -XX:LogFile=../sonatype-work/nexus3/log/jvm.log -XX:-OmitStackTraceInFastThrow -Djava.net.preferIPv4Stack=true -Dkaraf.home=. -Dkaraf.base=. -Dkaraf.etc=etc/karaf -Djava.util.logging.config.file=etc/karaf/java.util.logging.properties -Dkaraf.data=../sonatype-work/nexus3 -Dkaraf.log=../sonatype-work/nexus3/log -Djava.io.tmpdir=../sonatype-work/nexus3/tmp -Dkaraf.startLocalConsole=false -Djdk.tls.ephemeralDHKeySize=2048 -Djava.endorsed.dirs=lib/endorsed -Di4j.vpt=true -classpath /opt/sonatype/nexus/.install4j/i4jruntime.jar:/opt/sonatype/nexus/lib/boot/nexus-main.jar:/opt/sonatype/nexus/lib/boot/activation-1.1.1.jar:/opt/sonatype/nexus/lib/boot/jakarta.xml.bind-api-2.3.3.jar:/opt/sonatype/nexus/lib/boot/jaxb-runtime-2.3.3.jar:/opt/sonatype/nexus/lib/boot/txw2-2.3.3.jar:/opt/sonatype/nexus/lib/boot/istack-commons-runtime-3.0.10.jar:/opt/sonatype/nexus/lib/boot/org.apache.karaf.main-4.3.6.jar:/opt/sonatype/nexus/lib/boot/osgi.core-7.0.0.jar:/opt/sonatype/nexus/lib/boot/org.apache.karaf.specs.activator-4.3.6.jar:/opt/sonatype/nexus/lib/boot/org.apache.karaf.diagnostic.boot-4.3.6.jar:/opt/sonatype/nexus/lib/boot/org.apache.karaf.jaas.boot-4.3.6.jar com.install4j.runtime.launcher.UnixLauncher run 9d17dc87 0 0 org.sonatype.nexus.karaf.NexusMain
```

系统内核

```shell
# uname -a
Linux 10-1-207-194 3.10.0-1160.31.1.el7.x86_64 #1 SMP Thu Jun 10 13:32:12 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
```

内存信息

```shell
# free -h
              total        used        free      shared  buff/cache   available
Mem:           251G         38G        6.2G        4.0G        206G        208G
Swap:          4.0G        3.8G        209M
```

## 故障现象

读取 pom 耗时 16 秒

```shell
[root@10-1-207-194 ~]# time curl http://127.0.0.1:8088/nexus/repository/releases/com/ai/nc-common-um/4.1.0/nc-common-um-4.1.0.pom
<?xml version="1.0" encoding="UTF-8"?>
<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd" xmlns="http://maven.apache.org/POM/4.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    ...
  </parent>
  ...
  <dependencies>
   ...
  </dependencies>
  <repositories>
    ...
  </repositories>
</project>

real	0m16.433s
user	0m0.005s
sys	0m0.004s
```

## 在 Nexus 容器内安装 jstack 工具

因为 nexus3 官方镜像中只有 JRE，所以我们需要在容器内安装 JDK

以 root 权限登录容器内部

```shell
docker exec -u 0 -it nexus3.9.x bash
```

安装 JDK

```shell
yum install java-1.8.0-openjdk-devel.x86_64
```

## 劣化分析

以普通用户登录容器内部

```shell
docker exec -it nexus3.9.x bash
```

使用 `top` 命令查看 CPU 利用率为 1666%

```shell
bash-4.4$ top
top - 07:22:50 up 263 days, 15:25,  0 users,  load average: 13.83, 12.73, 12.55
Tasks:   4 total,   1 running,   3 sleeping,   0 stopped,   0 zombie
%Cpu(s): 23.5 us,  2.5 sy,  0.0 ni, 74.1 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem : 257429.8 total,   6311.8 free,  39158.4 used, 211959.5 buff/cache
MiB Swap:   4096.0 total,    209.1 free,   3886.9 used. 213295.4 avail Mem

   PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
     1 nexus     20   0   43.8g  10.4g  32524 S  1666   4.1   2984:04 java
   878 root      20   0   19336   2384   1832 S   0.0   0.0   0:00.13 bash
  2379 nexus     20   0   12036   1952   1464 S   0.0   0.0   0:00.01 bash
  2386 nexus     20   0   49120   2164   1504 R   0.0   0.0   0:00.00 top
```

使用 `top -n 1 -b -H -p 1 | head -n 30 && jstack 1 > /nexus-data/nexus_thread.info` 命令查看 CPU 利用率高的线程并保存线程信息到 /nexus-data/nexus_thread.info

```shell
bash-4.4$ top -n 1 -b -H -p 1 | head -n 30 && jstack 1 > /nexus-data/nexus_thread.info
top - 07:39:25 up 263 days, 15:42,  0 users,  load average: 17.86, 17.93, 15.91
Threads: 527 total,  17 running, 510 sleeping,   0 stopped,   0 zombie
%Cpu(s): 35.1 us,  4.1 sy,  0.0 ni, 60.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem : 257429.8 total,   4224.3 free,  35897.7 used, 217307.8 buff/cache
MiB Swap:   4096.0 total,    211.9 free,   3884.1 used. 216556.0 avail Mem

   PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   265 nexus     20   0   43.8g  10.4g  32548 R  94.1   4.1  69:01.28 java
  1416 nexus     20   0   43.8g  10.4g  32548 S  64.7   4.1  16:43.97 qtp1892721215-6
  1653 nexus     20   0   43.8g  10.4g  32548 S  58.8   4.1   4:32.59 qtp1892721215-8
  1951 nexus     20   0   43.8g  10.4g  32548 R  58.8   4.1   2:08.03 qtp1892721215-1
  2285 nexus     20   0   43.8g  10.4g  32548 S  58.8   4.1  11:54.16 qtp1892721215-1
   793 nexus     20   0   43.8g  10.4g  32548 S  52.9   4.1  21:48.02 qtp1892721215-5
  1432 nexus     20   0   43.8g  10.4g  32548 S  52.9   4.1   6:49.96 qtp1892721215-6
  1685 nexus     20   0   43.8g  10.4g  32548 S  52.9   4.1   3:34.37 qtp1892721215-8
  1747 nexus     20   0   43.8g  10.4g  32548 R  52.9   4.1  11:23.02 qtp1892721215-9
  1803 nexus     20   0   43.8g  10.4g  32548 R  52.9   4.1  11:59.63 qtp1892721215-1
  2254 nexus     20   0   43.8g  10.4g  32548 S  52.9   4.1   0:27.77 qtp1892721215-1
  2293 nexus     20   0   43.8g  10.4g  32548 S  52.9   4.1   3:47.03 qtp1892721215-1
  2295 nexus     20   0   43.8g  10.4g  32548 R  52.9   4.1   0:25.11 qtp1892721215-1
  2306 nexus     20   0   43.8g  10.4g  32548 S  52.9   4.1   2:12.40 qtp1892721215-1
  2330 nexus     20   0   43.8g  10.4g  32548 R  52.9   4.1   8:36.55 qtp1892721215-1
  1721 nexus     20   0   43.8g  10.4g  32548 R  47.1   4.1  15:02.04 qtp1892721215-9
  1772 nexus     20   0   43.8g  10.4g  32548 S  47.1   4.1   4:22.38 qtp1892721215-9
  1781 nexus     20   0   43.8g  10.4g  32548 S  47.1   4.1  16:55.50 qtp1892721215-9
  1784 nexus     20   0   43.8g  10.4g  32548 R  47.1   4.1  13:05.06 qtp1892721215-9
  1807 nexus     20   0   43.8g  10.4g  32548 S  47.1   4.1   8:50.17 qtp1892721215-1
  1838 nexus     20   0   43.8g  10.4g  32548 R  47.1   4.1   1:15.92 qtp1892721215-1
  1901 nexus     20   0   43.8g  10.4g  32548 R  47.1   4.1   2:42.83 qtp1892721215-1
  1933 nexus     20   0   43.8g  10.4g  32548 S  47.1   4.1   2:39.22 qtp1892721215-1
```

分别查看高 CPU 的线程堆栈

PID=265(0x109)

```shell
"Concurrent Mark-Sweep GC Thread" os_prio=0 tid=0x00007f4e0c112000 nid=0x109 runnable
```

PID=1416(0x588)

```shell
"qtp1892721215-631 <command>sql.select from asset where bucket = :bucket and name = :propValue</command>" #631 prio=5 os_prio=0 tid=0x00007f4cfc004000 nid=0x588 runnable [0x00007f4a9afec000]
   java.lang.Thread.State: RUNNABLE
        at com.orientechnologies.common.concur.lock.ODistributedCounter.decrement(ODistributedCounter.java:50)
        at com.orientechnologies.common.concur.lock.OReadersWriterSpinLock.releaseReadLock(OReadersWriterSpinLock.java:113)
        at com.orientechnologies.common.concur.lock.OPartitionedLockManager$SpinLockWrapper.unlock(OPartitionedLockManager.java:107)
        at com.orientechnologies.orient.core.storage.cache.local.twoq.O2QCache.doLoad(O2QCache.java:379)
        at com.orientechnologies.orient.core.storage.cache.local.twoq.O2QCache.load(O2QCache.java:294)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.base.ODurableComponent.loadPage(ODurableComponent.java:145)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readFullEntry(OPaginatedCluster.java:1898)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecordBuffer(OPaginatedCluster.java:779)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecord(OPaginatedCluster.java:742)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecord(OPaginatedCluster.java:721)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.doReadRecord(OAbstractPaginatedStorage.java:4220)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.readRecord(OAbstractPaginatedStorage.java:3807)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.readRecord(OAbstractPaginatedStorage.java:1410)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx$SimpleRecordReader.readRecord(ODatabaseDocumentTx.java:3395)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.executeReadRecord(ODatabaseDocumentTx.java:2008)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.load(ODatabaseDocumentTx.java:656)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.load(ODatabaseDocumentTx.java:103)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.executeSearchRecord(OCommandExecutorSQLSelect.java:585)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.serialIterator(OCommandExecutorSQLSelect.java:1638)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.fetchFromTarget(OCommandExecutorSQLSelect.java:1585)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.fetchValuesFromIndexCursor(OCommandExecutorSQLSelect.java:2466)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.searchForIndexes(OCommandExecutorSQLSelect.java:2280)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.searchInClasses(OCommandExecutorSQLSelect.java:1017)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLResultsetAbstract.assignTarget(OCommandExecutorSQLResultsetAbstract.java:203)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.assignTarget(OCommandExecutorSQLSelect.java:527)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.executeSearch(OCommandExecutorSQLSelect.java:509)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.execute(OCommandExecutorSQLSelect.java:485)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLDelegate.execute(OCommandExecutorSQLDelegate.java:70)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.executeCommand(OAbstractPaginatedStorage.java:3400)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.command(OAbstractPaginatedStorage.java:3318)
        at com.orientechnologies.orient.core.command.OCommandRequestTextAbstract.execute(OCommandRequestTextAbstract.java:69)
        at org.sonatype.nexus.repository.storage.MetadataNodeEntityAdapter.findByProperty(MetadataNodeEntityAdapter.java:165)
```  

PID=1653(0x675)   

```shell
"qtp1892721215-859 <command>sql.select from asset where bucket = :bucket and name = :propValue</command>" #859 prio=5 os_prio=0 tid=0x00007f496400d800 nid=0x675 runnable [0x00007f4be2de8000]
   java.lang.Thread.State: WAITING (parking)
        at sun.misc.Unsafe.park(Native Method)
        - parking to wait for  <0x00000006005092a8> (a java.util.concurrent.locks.ReentrantLock$NonfairSync)
        at java.util.concurrent.locks.LockSupport.park(LockSupport.java:175)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.parkAndCheckInterrupt(AbstractQueuedSynchronizer.java:836)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireQueued(AbstractQueuedSynchronizer.java:870)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquire(AbstractQueuedSynchronizer.java:1199)
        at java.util.concurrent.locks.ReentrantLock$NonfairSync.lock(ReentrantLock.java:209)
        at java.util.concurrent.locks.ReentrantLock.lock(ReentrantLock.java:285)
        at com.orientechnologies.common.collection.closabledictionary.OClosableEntry.acquireStateLock(OClosableEntry.java:84)
        at com.orientechnologies.common.collection.closabledictionary.OClosableLinkedContainer.acquire(OClosableLinkedContainer.java:292)
        at com.orientechnologies.orient.core.storage.cache.local.OWOWCache.getFilledUpTo(OWOWCache.java:959)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.base.ODurableComponent.getFilledUpTo(ODurableComponent.java:132)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readFullEntry(OPaginatedCluster.java:1889)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecordBuffer(OPaginatedCluster.java:779)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecord(OPaginatedCluster.java:742)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecord(OPaginatedCluster.java:721)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.doReadRecord(OAbstractPaginatedStorage.java:4220)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.readRecord(OAbstractPaginatedStorage.java:3807)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.readRecord(OAbstractPaginatedStorage.java:1410)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx$SimpleRecordReader.readRecord(ODatabaseDocumentTx.java:3395)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.executeReadRecord(ODatabaseDocumentTx.java:2008)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.load(ODatabaseDocumentTx.java:656)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.load(ODatabaseDocumentTx.java:103)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.executeSearchRecord(OCommandExecutorSQLSelect.java:585)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.serialIterator(OCommandExecutorSQLSelect.java:1638)
```   

PID=1951(0x79f)

```shell
"qtp1892721215-1159 <command>sql.select from asset where bucket = :bucket and name = :propValue</command>" #1159 prio=5 os_prio=0 tid=0x00007f48d800f000 nid=0x79f waiting on condition [0x00007f45c51cd000]
   java.lang.Thread.State: WAITING (parking)
        at sun.misc.Unsafe.park(Native Method)
        - parking to wait for  <0x00000006005092a8> (a java.util.concurrent.locks.ReentrantLock$NonfairSync)
        at java.util.concurrent.locks.LockSupport.park(LockSupport.java:175)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.parkAndCheckInterrupt(AbstractQueuedSynchronizer.java:836)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireQueued(AbstractQueuedSynchronizer.java:870)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquire(AbstractQueuedSynchronizer.java:1199)
        at java.util.concurrent.locks.ReentrantLock$NonfairSync.lock(ReentrantLock.java:209)
        at java.util.concurrent.locks.ReentrantLock.lock(ReentrantLock.java:285)
        at com.orientechnologies.common.collection.closabledictionary.OClosableEntry.acquireStateLock(OClosableEntry.java:84)
        at com.orientechnologies.common.collection.closabledictionary.OClosableLinkedContainer.acquire(OClosableLinkedContainer.java:292)
        at com.orientechnologies.orient.core.storage.cache.local.OWOWCache.getFilledUpTo(OWOWCache.java:959)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.base.ODurableComponent.getFilledUpTo(ODurableComponent.java:132)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecordBuffer(OPaginatedCluster.java:762)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecord(OPaginatedCluster.java:742)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecord(OPaginatedCluster.java:721)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.doReadRecord(OAbstractPaginatedStorage.java:4220)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.readRecord(OAbstractPaginatedStorage.java:3807)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.readRecord(OAbstractPaginatedStorage.java:1410)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx$SimpleRecordReader.readRecord(ODatabaseDocumentTx.java:3395)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.executeReadRecord(ODatabaseDocumentTx.java:2008)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.load(ODatabaseDocumentTx.java:656)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.load(ODatabaseDocumentTx.java:103)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.executeSearchRecord(OCommandExecutorSQLSelect.java:585)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.serialIterator(OCommandExecutorSQLSelect.java:1638)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.fetchFromTarget(OCommandExecutorSQLSelect.java:1585)
```

PID=2285(0x8ed)

```shell
"qtp1892721215-1491 <command>sql.select from asset where bucket = :bucket and name = :propValue</command>" #1491 prio=5 os_prio=0 tid=0x00007f4a30006000 nid=0x8ed waiting on condition [0x00007f47c6de8000]
   java.lang.Thread.State: WAITING (parking)
        at sun.misc.Unsafe.park(Native Method)
        - parking to wait for  <0x0000000600508ef0> (a java.util.concurrent.locks.ReentrantLock$NonfairSync)
        at java.util.concurrent.locks.LockSupport.park(LockSupport.java:175)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.parkAndCheckInterrupt(AbstractQueuedSynchronizer.java:836)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireQueued(AbstractQueuedSynchronizer.java:870)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquire(AbstractQueuedSynchronizer.java:1199)
        at java.util.concurrent.locks.ReentrantLock$NonfairSync.lock(ReentrantLock.java:209)
        at java.util.concurrent.locks.ReentrantLock.lock(ReentrantLock.java:285)
        at com.orientechnologies.common.collection.closabledictionary.OClosableEntry.acquireStateLock(OClosableEntry.java:84)
        at com.orientechnologies.common.collection.closabledictionary.OClosableLinkedContainer.acquire(OClosableLinkedContainer.java:292)
        at com.orientechnologies.orient.core.storage.cache.local.OWOWCache.getFilledUpTo(OWOWCache.java:959)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.base.ODurableComponent.getFilledUpTo(ODurableComponent.java:132)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readFullEntry(OPaginatedCluster.java:1889)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecordBuffer(OPaginatedCluster.java:779)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecord(OPaginatedCluster.java:742)
        at com.orientechnologies.orient.core.storage.impl.local.paginated.OPaginatedCluster.readRecord(OPaginatedCluster.java:721)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.doReadRecord(OAbstractPaginatedStorage.java:4220)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.readRecord(OAbstractPaginatedStorage.java:3807)
        at com.orientechnologies.orient.core.storage.impl.local.OAbstractPaginatedStorage.readRecord(OAbstractPaginatedStorage.java:1410)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx$SimpleRecordReader.readRecord(ODatabaseDocumentTx.java:3395)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.executeReadRecord(ODatabaseDocumentTx.java:2008)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.load(ODatabaseDocumentTx.java:656)
        at com.orientechnologies.orient.core.db.document.ODatabaseDocumentTx.load(ODatabaseDocumentTx.java:103)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.executeSearchRecord(OCommandExecutorSQLSelect.java:585)
        at com.orientechnologies.orient.core.sql.OCommandExecutorSQLSelect.serialIterator(OCommandExecutorSQLSelect.java:1638)
```

有的时候还发现大量 CPU 利用率在 50% 左右的线程，这些线程执行垃圾收集，但无法回收导致 CPU 利用率高的堆内存

```shell
bash-4.4$ top -n 1 -b -H -p 1 | head -n 30 && jstack 1 > /nexus-data/nexus_thread.info
top - 08:04:55 up 263 days, 16:07,  0 users,  load average: 22.25, 16.58, 15.25
Threads: 503 total,  12 running, 491 sleeping,   0 stopped,   0 zombie
%Cpu(s): 25.1 us,  3.0 sy,  0.0 ni, 71.9 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem : 257429.8 total,   2308.7 free,  36091.9 used, 219029.1 buff/cache
MiB Swap:   4096.0 total,    212.6 free,   3883.4 used. 216354.0 avail Mem

   PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   265 nexus     20   0   43.8g  10.4g  32660 S  52.9   4.1  78:42.98 java
   257 nexus     20   0   43.8g  10.4g  32660 R  47.1   4.1  55:13.06 java
   259 nexus     20   0   43.8g  10.4g  32660 R  47.1   4.1  55:13.65 java
   250 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:12.86 java
   251 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:12.68 java
   252 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:13.58 java
   253 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:13.15 java
   254 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:13.40 java
   255 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:13.25 java
   256 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:13.24 java
   258 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:13.19 java
   260 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:12.91 java
   261 nexus     20   0   43.8g  10.4g  32660 R  41.2   4.1  55:13.13 java
```   

```
"Gang worker#0 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c05d800 nid=0xfa runnable

"Gang worker#1 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c05f000 nid=0xfb runnable

"Gang worker#2 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c060800 nid=0xfc runnable

"Gang worker#3 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c065000 nid=0xfd runnable

"Gang worker#4 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c067000 nid=0xfe runnable

"Gang worker#5 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c068800 nid=0xff runnable

"Gang worker#6 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c06a800 nid=0x100 runnable

"Gang worker#7 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c06c800 nid=0x101 runnable

"Gang worker#8 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c06e000 nid=0x102 runnable

"Gang worker#9 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c070000 nid=0x103 runnable

"Gang worker#10 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c071800 nid=0x104 runnable

"Gang worker#11 (Parallel GC Threads)" os_prio=0 tid=0x00007f4e0c073800 nid=0x105 runnable
```

## GC 日志分析

查看 GC 文件发现频繁

```shell
22045.210: [GC (Allocation Failure) 22045.210: [ParNew: 876288K->146048K(876288K), 0.1231922 secs] 4367587K->3685888K(8242560K), 0.1234838 secs] [Times: user=1.08 sys=0.01, real=0.12 secs]
22045.545: [GC (Allocation Failure) 22045.545: [ParNew: 876288K->118569K(876288K), 0.1480261 secs] 4300040K->3649444K(8242560K), 0.1483200 secs] [Times: user=1.19 sys=0.04, real=0.15 secs]
22045.901: [GC (Allocation Failure) 22045.901: [ParNew: 848809K->136830K(876288K), 0.1007517 secs] 4269203K->3557224K(8242560K), 0.1010417 secs] [Times: user=0.92 sys=0.02, real=0.10 secs]
22046.199: [GC (Allocation Failure) 22046.199: [ParNew: 867070K->146048K(876288K), 0.1262746 secs] 4186874K->3508758K(8242560K), 0.1265621 secs] [Times: user=1.15 sys=0.02, real=0.12 secs]
22046.528: [GC (Allocation Failure) 22046.528: [ParNew: 876288K->146048K(876288K), 0.1154658 secs] 4135340K->3445385K(8242560K), 0.1157458 secs] [Times: user=1.03 sys=0.01, real=0.12 secs]
22046.863: [GC (Allocation Failure) 22046.864: [ParNew: 876288K->146048K(876288K), 0.1380234 secs] 4056185K->3381568K(8242560K), 0.1383243 secs] [Times: user=1.20 sys=0.02, real=0.14 secs]
22047.238: [GC (Allocation Failure) 22047.239: [ParNew: 876288K->146048K(876288K), 0.1175596 secs] 4007589K->3321101K(8242560K), 0.1178741 secs] [Times: user=0.91 sys=0.01, real=0.11 secs]
22047.577: [GC (Allocation Failure) 22047.577: [ParNew: 876288K->146048K(876288K), 0.1095810 secs] 3979304K->3283188K(8242560K), 0.1098780 secs] [Times: user=0.98 sys=0.01, real=0.11 secs]
22047.906: [GC (Allocation Failure) 22047.906: [ParNew: 876288K->146048K(876288K), 0.1460188 secs] 3936187K->3253343K(8242560K), 0.1464933 secs] [Times: user=1.33 sys=0.02, real=0.15 secs]
22048.254: [GC (Allocation Failure) 22048.254: [ParNew: 876288K->146048K(876288K), 0.1357416 secs] 3906382K->3219026K(8242560K), 0.1360523 secs] [Times: user=1.24 sys=0.01, real=0.14 secs]
22048.604: [GC (Allocation Failure) 22048.605: [ParNew: 876288K->146048K(876288K), 0.1257560 secs] 3860409K->3178499K(8242560K), 0.1260555 secs] [Times: user=1.11 sys=0.01, real=0.13 secs]
22048.944: [GC (Allocation Failure) 22048.944: [ParNew: 876288K->146048K(876288K), 0.1227148 secs] 3848451K->3162435K(8242560K), 0.1230789 secs] [Times: user=0.93 sys=0.01, real=0.12 secs]
22049.275: [GC (Allocation Failure) 22049.275: [ParNew: 876288K->146048K(876288K), 0.1300142 secs] 3837726K->3164053K(8242560K), 0.1303308 secs] [Times: user=1.12 sys=0.02, real=0.13 secs]
22049.617: [GC (Allocation Failure) 22049.617: [ParNew: 876288K->146048K(876288K), 0.1560830 secs] 3785033K->3102054K(8242560K), 0.1564236 secs] [Times: user=1.30 sys=0.04, real=0.16 secs]
22049.829: [CMS-concurrent-sweep: 7.565/12.417 secs] [Times: user=185.39 sys=17.96, real=12.42 secs]
22049.830: [CMS-concurrent-reset-start]
22049.892: [CMS-concurrent-reset: 0.063/0.063 secs] [Times: user=1.14 sys=0.16, real=0.06 secs]
22049.984: [GC (Allocation Failure) 22049.984: [ParNew: 876288K->146048K(876288K), 0.1332560 secs] 3749726K->3073390K(8242560K), 0.1335766 secs] [Times: user=1.14 sys=0.04, real=0.13 secs]
22050.326: [GC (Allocation Failure) 22050.326: [ParNew: 876288K->146048K(876288K), 0.1500684 secs] 3803630K->3113169K(8242560K), 0.1504454 secs] [Times: user=1.24 sys=0.02, real=0.15 secs]
22050.701: [GC (Allocation Failure) 22050.701: [ParNew: 876288K->146048K(876288K), 0.1538092 secs] 3843409K->3161059K(8242560K), 0.1541364 secs] [Times: user=1.23 sys=0.03, real=0.15 secs]
22051.055: [GC (Allocation Failure) 22051.055: [ParNew: 876288K->146048K(876288K), 0.1283893 secs] 3891299K->3198929K(8242560K), 0.1287281 secs] [Times: user=1.08 sys=0.00, real=0.13 secs]
22051.401: [GC (Allocation Failure) 22051.401: [ParNew: 876288K->146048K(876288K), 0.1382001 secs] 3929169K->3244359K(8242560K), 0.1385485 secs] [Times: user=1.07 sys=0.02, real=0.14 secs]
22051.753: [GC (Allocation Failure) 22051.754: [ParNew: 876288K->146048K(876288K), 0.1212361 secs] 3974599K->3291855K(8242560K), 0.1217161 secs] [Times: user=1.01 sys=0.03, real=0.12 secs]
22052.076: [GC (Allocation Failure) 22052.077: [ParNew: 876288K->146048K(876288K), 0.1348037 secs] 4022095K->3334990K(8242560K), 0.1351310 secs] [Times: user=1.12 sys=0.01, real=0.14 secs]
22052.432: [GC (Allocation Failure) 22052.432: [ParNew: 876288K->146048K(876288K), 0.1207005 secs] 4065230K->3377339K(8242560K), 0.1210904 secs] [Times: user=1.01 sys=0.02, real=0.12 secs]
22052.757: [GC (Allocation Failure) 22052.757: [ParNew: 876288K->146048K(876288K), 0.1216388 secs] 4107579K->3427506K(8242560K), 0.1219509 secs] [Times: user=0.96 sys=0.02, real=0.13 secs]
22053.102: [GC (Allocation Failure) 22053.102: [ParNew: 876288K->146048K(876288K), 0.1176569 secs] 4157746K->3474495K(8242560K), 0.1179791 secs] [Times: user=0.94 sys=0.03, real=0.12 secs]
22053.444: [GC (Allocation Failure) 22053.444: [ParNew: 876288K->146048K(876288K), 0.1153058 secs] 4204735K->3524874K(8242560K), 0.1156208 secs] [Times: user=0.93 sys=0.02, real=0.12 secs]
22053.825: [GC (Allocation Failure) 22053.825: [ParNew: 876288K->146048K(876288K), 0.1370090 secs] 4255114K->3574406K(8242560K), 0.1376114 secs] [Times: user=1.16 sys=0.04, real=0.14 secs]
22054.226: [GC (Allocation Failure) 22054.226: [ParNew: 876288K->146048K(876288K), 0.1293793 secs] 4304646K->3603376K(8242560K), 0.1297292 secs] [Times: user=1.06 sys=0.02, real=0.13 secs]
22054.580: [GC (Allocation Failure) 22054.580: [ParNew: 876288K->146048K(876288K), 0.1383698 secs] 4333616K->3655122K(8242560K), 0.1387208 secs] [Times: user=1.10 sys=0.01, real=0.14 secs]
22054.928: [GC (Allocation Failure) 22054.928: [ParNew: 876288K->146048K(876288K), 0.1168988 secs] 4385362K->3691694K(8242560K), 0.1172026 secs] [Times: user=1.04 sys=0.01, real=0.12 secs]
22055.269: [GC (Allocation Failure) 22055.269: [ParNew: 876288K->146048K(876288K), 0.1274913 secs] 4421934K->3724706K(8242560K), 0.1278116 secs] [Times: user=1.02 sys=0.02, real=0.12 secs]
22055.626: [GC (Allocation Failure) 22055.626: [ParNew: 876288K->146048K(876288K), 0.1319667 secs] 4454946K->3769275K(8242560K), 0.1323446 secs] [Times: user=1.03 sys=0.03, real=0.14 secs]
22055.964: [GC (Allocation Failure) 22055.964: [ParNew: 876288K->146048K(876288K), 0.1282238 secs] 4499515K->3814194K(8242560K), 0.1285613 secs] [Times: user=1.02 sys=0.02, real=0.13 secs]
22056.286: [GC (Allocation Failure) 22056.286: [ParNew: 876288K->146048K(876288K), 0.1295692 secs] 4544434K->3854773K(8242560K), 0.1299219 secs] [Times: user=1.01 sys=0.02, real=0.13 secs]
22056.627: [GC (Allocation Failure) 22056.627: [ParNew: 876288K->146048K(876288K), 0.1299080 secs] 4585013K->3904723K(8242560K), 0.1302944 secs] [Times: user=1.06 sys=0.02, real=0.13 secs]
22056.962: [GC (Allocation Failure) 22056.962: [ParNew: 876288K->146048K(876288K), 0.1490967 secs] 4634963K->3964984K(8242560K), 0.1494244 secs] [Times: user=1.15 sys=0.02, real=0.15 secs]
22057.318: [GC (Allocation Failure) 22057.318: [ParNew: 876288K->146048K(876288K), 0.1499307 secs] 4695224K->4010986K(8242560K), 0.1503423 secs] [Times: user=1.23 sys=0.03, real=0.16 secs]
22057.680: [GC (Allocation Failure) 22057.680: [ParNew: 876288K->146048K(876288K), 0.1232765 secs] 4741226K->4057267K(8242560K), 0.1235796 secs] [Times: user=0.99 sys=0.04, real=0.12 secs]
22058.018: [GC (Allocation Failure) 22058.018: [ParNew: 876288K->146048K(876288K), 0.1574910 secs] 4787507K->4107281K(8242560K), 0.1577976 secs] [Times: user=1.32 sys=0.03, real=0.16 secs]
```

> 22045.210: [GC (Allocation Failure) 22045.210: [ParNew: 876288K->146048K(876288K), 0.1231922 secs] 4367587K->3685888K(8242560K), 0.1234838 secs] [Times: user=1.08 sys=0.01, real=0.12 secs]

* ParNew: 876288K->146048K(876288K), 0.1231922 secs

> GC 前年轻代 876288KB(876MB), GC后该内存区域使用容量 146048KB; GC 耗时 0.1231922 秒

* 4367587K->3685888K(8242560K), 0.1234838 secs

> 堆区垃圾回收前的大小 4367587K(4GB)，堆区垃圾回收后的大小 3685888K(3.6GB)，堆区总大小 8242560K(8GB); GC 耗时 0.1234838 秒

* [Times: user=1.08 sys=0.01, real=0.12 secs]

> 分别表示用户态耗时 1.08 秒，内核态耗时 0.01 秒，总耗时 0.12 秒

分析下可以得出结论：

* 该次 GC 新生代减少了 876288K - 146048K = 730240K (730MB)
* Heap 区总共减少了 4367587K - 3685888K = 681699K (681MB)

730240K – 681699K = 48541K (48MB)，说明该次共有 48MB 内存从年轻代移到了老年代，可以看出年轻代频繁达到最大（876MB）并触法 ParNew, 该收集器采用复制算法回收内存，期间会停止其他工作线程，即 **Stop The World**
