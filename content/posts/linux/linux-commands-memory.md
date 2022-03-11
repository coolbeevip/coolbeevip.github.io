---
title: "Linux Command - Memory"
date: 2022-03-11T13:24:14+08:00
tags: [linux,memory]
categories: [linux]
draft: false
---

Linux 内存相关命令

## 查看系统内存

```shell
# free -h
              total        used        free      shared  buff/cache   available
Mem:           251G         40G        1.4G        4.0G        209G        206G
Swap:          4.0G        3.7G        312M
```

## 内存占用 TOP N

```shell
# ps aux | sort -k4,4nr | head -n 5
200      139348  227  6.9 38668500 18410776 ?   Ssl  3月10 1905:49 /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.282.b08-2.el8_3.x86_64/jre/bin/java...org.sonatype.nexus.karaf.NexusMain
mysql     33407  1.2  2.2 349722012 6012524 ?   Sl    2021 4596:18 /usr/local/mysql/bin/mysqld --basedir=/usr/local/mysql
mysql    118257  0.4  0.5 10170064 1536084 ?    Ssl  2月28  66:04 /usr/share/elasticsearch/jdk/bin/java -Xms1g -Xmx1g -XX:+UseConcMarkSweepGC
root      42564  9.6  0.5 38919648 1389108 ?    Sl   09:28   1:33 /usr/local/openjdk-8/bin/java -classpath /builds/rc/rm/rc-rm-hl/rm-hl-xz/.mvn/wrapper/maven-wrapper.jar
mysql    164658  0.2  0.3 19675724 792648 ?     Sl    2021 343:28 /opt/java/openjdk/bin/java -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75
```

## 查看某一进程内存信息

```shell
# top -p 139348
top - 09:40:19 up 263 days,  9:43,  2 users,  load average: 10.70, 12.23, 9.11
Tasks:   1 total,   0 running,   1 sleeping,   0 stopped,   0 zombie
%Cpu(s): 23.5 us,  2.3 sy,  0.0 ni, 74.2 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem : 26360806+total,  1585308 free, 41075156 used, 22094758+buff/cache
KiB Swap:  4194300 total,   330400 free,  3863900 used. 21742449+avail Mem

   PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
139348 200       20   0   36.4g  17.6g  31824 S  1653  7.0   1838:31 java
```

* 物理内存占用 17.6GB
* 虚拟内存占用 36.4GB
* 内存使用率为 7.0%

## 查看某一进程内存实际值

```shell
# pidstat -p 139348  -r
Linux 3.10.0-1160.31.1.el7.x86_64 (10-1-207-194) 	2022年03月11日 	_x86_64_	(64 CPU)

09时59分22秒   UID       PID  minflt/s  majflt/s     VSZ    RSS   %MEM  Command
09时59分22秒   200    139348     44.52      0.00 41064804 18410252   6.98  java
```

* minflt/s: 每秒次缺页错误次数 （minor page faults），虚拟内存地址映射成物理内存地址产生的 page fault 次数
* majflt/s: 每秒主缺页错误次数(major page faults)，当虚拟内存地址映射成物理内存地址时，相应的page在swap中，这样的page fault为major page fault，一般在内存使用紧张时产生。
* VSZ: 该进程使用的虚拟内存(以kB为单位)。
* RSS: 该进程使用的物理内存(以kB为单位)。
* %MEM: 该进程使用内存的百分比。
* Command: 拉起进程对应的命令
