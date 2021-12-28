---
title: "Linux Command - Disk"
date: 2019-05-06T13:24:14+08:00
tags: [linux,disk]
categories: [linux]
draft: false
---

Linux 磁盘相关命令

## 磁盘IO dd

```shell
[root@localhost ~]# dd if=/dev/zero of=./a.dat bs=8K count=1M conv=fdatasync
记录了8192+0 的读入
记录了8192+0 的写出
8589934592字节(8.6 GB)已复制，14.8606 秒，578 MB/秒
[root@localhost ~]# dd if=./a.dat of=/dev/null bs=1M count=8k iflag=direct
记录了8192+0 的读入
记录了8192+0 的写出
8589934592字节(8.6 GB)已复制，14.2462 秒，603 MB/秒
```

## 磁盘空间 df

查看磁盘各个分区的空间大小、占用、可用等信息

```shell
$ df -h
Filesystem      Size   Used  Avail Capacity iused      ifree %iused  Mounted on
/dev/disk1s5   466Gi   10Gi  128Gi     8%  488463 4881964417    0%   /
devfs          192Ki  192Ki    0Bi   100%     663          0  100%   /dev
/dev/disk1s1   466Gi  318Gi  128Gi    72% 4557528 4877895352    0%   /System/Volumes/Data
/dev/disk1s4   466Gi  8.0Gi  128Gi     6%       8 4882452872    0%   /private/var/vm
map auto_home    0Bi    0Bi    0Bi   100%       0          0  100%   /System/Volumes/Data/home
```

查看指定目录

```shell
$ df -h /opt/
Filesystem     Size   Used  Avail Capacity iused      ifree %iused  Mounted on
/dev/disk1s1  466Gi  318Gi  128Gi    72% 4557536 4877895344    0%   /System/Volumes/Data
```

## 查看文件夹空间 du

查看子目录下每个文件夹占用空间

```shell
$ du -h --max-depth=1
8.0G	./root-sh
4.0K	./.ssh
130M	./redis-6.2.5
612M	./.m2
0	./.ansible
9.0G
```

查看当前文件夹占用空间

```shell
$ du -sh
1.8G
```

查看指定文件夹占用空间

```shell
$ du -sh ~/mydocker/
2.3G	/Users/zhanglei/mydocker/
```
