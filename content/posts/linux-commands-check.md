---
title: "常用 Linux 检测命令"
date: 2019-05-06T13:24:14+08:00
categories: [linux]
draft: false
---

## IO

磁盘IO测试

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