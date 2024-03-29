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

排序查看子目录下每个文件夹占用空间

```shell
$ du -h --max-depth=1 | sort -h
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

## 挂载裸盘

查看并找到裸盘 /dev/vdb

```shell
# fdisk -l

Disk /dev/vda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x00034bb9

   Device Boot      Start         End      Blocks   Id  System
/dev/vda1   *        2048     2099199     1048576   83  Linux
/dev/vda2         2099200    83886079    40893440   8e  Linux LVM

Disk /dev/mapper/centos-root: 37.7 GB, 37706792960 bytes, 73646080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/centos-swap: 4160 MB, 4160749568 bytes, 8126464 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/vdb: 1073.7 GB, 1073741824000 bytes, 2097152000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

对裸盘分区

```shell
# fdisk /dev/vdb
Welcome to fdisk (util-linux 2.23.2).

Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table
Building a new DOS disklabel with disk identifier 0x2cdae9cc.

Command (m for help): n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p):
Using default response p
Partition number (1-4, default 1):
First sector (2048-2097151999, default 2048):
Using default value 2048
Last sector, +sectors or +size{K,M,G} (2048-2097151999, default 2097151999):
Using default value 2097151999
Partition 1 of type Linux and of size 1000 GiB is set

Command (m for help): p

Disk /dev/vdb: 1073.7 GB, 1073741824000 bytes, 2097152000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0xf0d27047

   Device Boot      Start         End      Blocks   Id  System
/dev/vdb1            2048  2097151999  1048574976   83  Linux

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```

格式化分区

```shell
# mkfs.ext4 /dev/vdb1
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
65536000 inodes, 262143744 blocks
13107187 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2409627648
8000 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
	4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
	102400000, 214990848

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done
```

创建目录并挂载分区

```shell
# mkdir /data01
# mount /dev/vdb1 /data01/
```

查看结果

```shell
# df -h
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/centos-root   36G  1.4G   34G   4% /
devtmpfs                  16G     0   16G   0% /dev
tmpfs                     16G     0   16G   0% /dev/shm
tmpfs                     16G  8.5M   16G   1% /run
tmpfs                     16G     0   16G   0% /sys/fs/cgroup
/dev/vda1               1014M  133M  882M  14% /boot
tmpfs                    3.2G     0  3.2G   0% /run/user/0
/dev/vdb1                985G   77M  935G   1% /data01
```

## 进程磁盘使用情况

```shell
# pidstat -p 139348 -d
Linux 3.10.0-1160.31.1.el7.x86_64 (10-1-207-194) 	2022年03月11日 	_x86_64_	(64 CPU)

10时01分57秒   UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s  Command
10时01分57秒   200    139348      0.01      0.13      0.01  java
```

* kB_rd/s: 每秒进程从磁盘读取的数据量(以kB为单位)。
* kB_wr/s: 每秒进程向磁盘写的数据量(以kB为单位)。
* kB_ccwr/s：每秒进程被取消向磁盘写的数据量(以kB为单位)。
* Command:：拉起进程对应的命令

## 磁盘 I/O 性能指标

```shell
$ iostat -d -x 1
Linux 3.10.0-957.el7.x86_64 (bjrdc5-cmc-nmdep-app-2.novalocal) 	11/08/2022 	_x86_64_	(4 CPU)

Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
vda               0.07     0.08    0.07    0.46     4.31    12.77    64.19     0.05  171.54  170.33  171.72  21.76   1.16
vdb               0.00     0.00    0.00    0.00     0.00     0.00    41.99     0.00   26.37   26.55    2.00  17.41   0.00
vdc               0.01     0.06    0.72    0.60   168.66    44.33   323.68     0.24   30.60  235.82  206.46  27.21   3.58
dm-0              0.00     0.00    0.78    0.90   172.60    56.84   272.87     0.15   87.37  234.71  239.95  31.71   5.33
dm-1              0.00     0.00    0.09    0.07     0.36     0.26     8.00     0.02  125.60   40.33  243.05   5.45   0.09
```

| 性能指标     | 含义                       | 提示                                    |
|----------|--------------------------|---------------------------------------|
| r/s      | 	每秒发送给磁盘的读请求数            | 	合并后的请求数                              |
| w/s      | 	每秒发送给磁盘的写请求数            | 	合并后的请求数                              |
| rkB/s    | 	每秒从磁盘读取的数据量	            | 单位为kB                                 |
| wkB/s    | 每秒向磁盘写入的数据量              | 	单位为kB                                |
| rrqm/s   | 	每秒合并的读请求数               | 	%rrqm表示合并读请求的百分比                     |
| wrqm/s   | 	每秒合并的写请求数	              | %wrqm表示合并写请求的百分比                      |
| r_await  | 	读请求处理完成等待时间	            | 包括队列中的等待时间和设备实际处理的时间，单位为毫秒            |
| w_await  | 	写请求处理完成等待时间	            | 包括队列中的等待时间和设备实际处理的时间，单位为毫秒            |
| aqu-sz   | 	平均请求队列长度	               | 旧版中为avgqu-sz                          |
| rareq-sz | 	平均读请求大小                 | 	单位为kB                                |
| wareq-sz | 	平均写请求大小	                | 单位为kB                                 |
| svctm    | 处理I/O请求所需的平均时间(不包括等待时间)	 | 单位为毫秒。注意这是推断的数据，并不保证完全准确              |
| %util    | 磁盘处理I/O的时间百分比	           | 即使用率，由于可能存在并行 I/O，100%并不一定表明磁盘 I/O 饱和 | 