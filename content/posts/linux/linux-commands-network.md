---
title: "Linux Command - Network"
date: 2019-10-02T13:24:14+08:00
tags: [linux,network,iperf3]
categories: [linux]
draft: false
---

Linux 网络相关命令

可以使用 `yum install iperf3` 安装这个工具，或者从网站 https://iperf.fr/iperf-download.php 下载

## 测试 TCP 吞吐量

假设我们要测试 10.1.207.180 和 10.1.207.181 两个服务器之间的带宽

先在其中一台服务器 10.1.207.181 服上启动 iperf3 服务

```
[root@oss-irms-181 ~]# iperf3 -s -p 5001
-----------------------------------------------------------
Server listening on 5001
-----------------------------------------------------------
```

再在另一台机器 10.1.207.180 启动客户端连接服务端 10.1.207.181 测试

```shell
[root@oss-irms-180 ~]# iperf3 -c 10.1.207.181 -P 4 -t 30 -i 2 -p 5001
Connecting to host 10.1.207.181, port 5001
[  4] local 10.1.207.180 port 49244 connected to 10.1.207.181 port 5001
[  6] local 10.1.207.180 port 49246 connected to 10.1.207.181 port 5001
[  8] local 10.1.207.180 port 49248 connected to 10.1.207.181 port 5001
[ 10] local 10.1.207.180 port 49250 connected to 10.1.207.181 port 5001
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-2.00   sec   883 MBytes  3.70 Gbits/sec    0   3.01 MBytes
[  6]   0.00-2.00   sec   867 MBytes  3.63 Gbits/sec    0   3.04 MBytes
[  8]   0.00-2.00   sec   908 MBytes  3.80 Gbits/sec    0   3.03 MBytes
[ 10]   0.00-2.00   sec   878 MBytes  3.67 Gbits/sec    0   3.01 MBytes
[SUM]   0.00-2.00   sec  3.45 GBytes  14.8 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]   2.00-4.00   sec   952 MBytes  4.00 Gbits/sec    0   3.01 MBytes
[  6]   2.00-4.00   sec   950 MBytes  3.99 Gbits/sec    0   3.04 MBytes
[  8]   2.00-4.00   sec   949 MBytes  3.99 Gbits/sec    0   3.03 MBytes
[ 10]   2.00-4.00   sec   948 MBytes  3.98 Gbits/sec    0   3.01 MBytes
[SUM]   2.00-4.00   sec  3.71 GBytes  16.0 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]   4.00-6.00   sec  1.04 GBytes  4.45 Gbits/sec    0   3.01 MBytes
[  6]   4.00-6.00   sec  1.03 GBytes  4.44 Gbits/sec    0   3.04 MBytes
[  8]   4.00-6.00   sec  1.03 GBytes  4.44 Gbits/sec    0   3.03 MBytes
[ 10]   4.00-6.00   sec  1.03 GBytes  4.41 Gbits/sec    0   3.01 MBytes
[SUM]   4.00-6.00   sec  4.13 GBytes  17.7 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]   6.00-8.00   sec   998 MBytes  4.18 Gbits/sec    0   3.01 MBytes
[  6]   6.00-8.00   sec   992 MBytes  4.16 Gbits/sec    0   3.04 MBytes
[  8]   6.00-8.00   sec   989 MBytes  4.15 Gbits/sec    0   3.03 MBytes
[ 10]   6.00-8.00   sec   990 MBytes  4.15 Gbits/sec    0   3.01 MBytes
[SUM]   6.00-8.00   sec  3.88 GBytes  16.6 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]   8.00-10.00  sec  1002 MBytes  4.21 Gbits/sec    0   3.01 MBytes
[  6]   8.00-10.00  sec  1001 MBytes  4.20 Gbits/sec    0   3.04 MBytes
[  8]   8.00-10.00  sec  1001 MBytes  4.20 Gbits/sec    0   3.03 MBytes
[ 10]   8.00-10.00  sec   996 MBytes  4.18 Gbits/sec    0   3.01 MBytes
[SUM]   8.00-10.00  sec  3.91 GBytes  16.8 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  10.00-12.00  sec   979 MBytes  4.10 Gbits/sec    0   3.01 MBytes
[  6]  10.00-12.00  sec   979 MBytes  4.10 Gbits/sec    0   3.04 MBytes
[  8]  10.00-12.00  sec   974 MBytes  4.08 Gbits/sec    0   3.03 MBytes
[ 10]  10.00-12.00  sec   971 MBytes  4.07 Gbits/sec    0   3.01 MBytes
[SUM]  10.00-12.00  sec  3.81 GBytes  16.4 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  12.00-14.00  sec  1008 MBytes  4.22 Gbits/sec    0   3.01 MBytes
[  6]  12.00-14.00  sec  1006 MBytes  4.22 Gbits/sec    0   3.04 MBytes
[  8]  12.00-14.00  sec  1002 MBytes  4.20 Gbits/sec    0   3.03 MBytes
[ 10]  12.00-14.00  sec  1004 MBytes  4.21 Gbits/sec    0   3.01 MBytes
[SUM]  12.00-14.00  sec  3.93 GBytes  16.9 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  14.00-16.00  sec  1.09 GBytes  4.70 Gbits/sec    0   3.01 MBytes
[  6]  14.00-16.00  sec  1.09 GBytes  4.69 Gbits/sec    0   3.04 MBytes
[  8]  14.00-16.00  sec  1.09 GBytes  4.70 Gbits/sec    0   3.03 MBytes
[ 10]  14.00-16.00  sec  1.09 GBytes  4.69 Gbits/sec    0   3.01 MBytes
[SUM]  14.00-16.00  sec  4.37 GBytes  18.8 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  16.00-18.00  sec   979 MBytes  4.11 Gbits/sec    0   3.01 MBytes
[  6]  16.00-18.00  sec   976 MBytes  4.09 Gbits/sec    0   3.04 MBytes
[  8]  16.00-18.00  sec   972 MBytes  4.08 Gbits/sec    0   3.03 MBytes
[ 10]  16.00-18.00  sec   970 MBytes  4.07 Gbits/sec    0   3.01 MBytes
[SUM]  16.00-18.00  sec  3.81 GBytes  16.3 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  18.00-20.00  sec  1.08 GBytes  4.64 Gbits/sec    0   3.01 MBytes
[  6]  18.00-20.00  sec  1.08 GBytes  4.63 Gbits/sec    0   3.04 MBytes
[  8]  18.00-20.00  sec  1.07 GBytes  4.61 Gbits/sec    0   3.03 MBytes
[ 10]  18.00-20.00  sec  1.08 GBytes  4.62 Gbits/sec    0   3.01 MBytes
[SUM]  18.00-20.00  sec  4.31 GBytes  18.5 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  20.00-22.00  sec   989 MBytes  4.15 Gbits/sec    0   3.01 MBytes
[  6]  20.00-22.00  sec   986 MBytes  4.13 Gbits/sec    0   3.04 MBytes
[  8]  20.00-22.00  sec   986 MBytes  4.13 Gbits/sec    0   3.03 MBytes
[ 10]  20.00-22.00  sec   982 MBytes  4.12 Gbits/sec    0   3.01 MBytes
[SUM]  20.00-22.00  sec  3.85 GBytes  16.5 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  22.00-24.00  sec   984 MBytes  4.13 Gbits/sec    0   3.01 MBytes
[  6]  22.00-24.00  sec   982 MBytes  4.12 Gbits/sec    0   3.04 MBytes
[  8]  22.00-24.00  sec   979 MBytes  4.11 Gbits/sec    0   3.03 MBytes
[ 10]  22.00-24.00  sec   978 MBytes  4.10 Gbits/sec    0   3.01 MBytes
[SUM]  22.00-24.00  sec  3.83 GBytes  16.5 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  24.00-26.00  sec  1.09 GBytes  4.66 Gbits/sec    0   3.01 MBytes
[  6]  24.00-26.00  sec  1.08 GBytes  4.65 Gbits/sec    0   3.04 MBytes
[  8]  24.00-26.00  sec  1.08 GBytes  4.64 Gbits/sec    0   3.03 MBytes
[ 10]  24.00-26.00  sec  1.08 GBytes  4.64 Gbits/sec    0   3.01 MBytes
[SUM]  24.00-26.00  sec  4.33 GBytes  18.6 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  26.00-28.00  sec  1.12 GBytes  4.80 Gbits/sec    0   3.01 MBytes
[  6]  26.00-28.00  sec  1.12 GBytes  4.80 Gbits/sec    0   3.04 MBytes
[  8]  26.00-28.00  sec  1.12 GBytes  4.79 Gbits/sec    0   3.03 MBytes
[ 10]  26.00-28.00  sec  1.11 GBytes  4.79 Gbits/sec    0   3.01 MBytes
[SUM]  26.00-28.00  sec  4.47 GBytes  19.2 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  28.00-30.00  sec  1.07 GBytes  4.60 Gbits/sec    0   3.01 MBytes
[  6]  28.00-30.00  sec  1.07 GBytes  4.59 Gbits/sec    0   3.04 MBytes
[  8]  28.00-30.00  sec  1.07 GBytes  4.58 Gbits/sec    0   3.03 MBytes
[ 10]  28.00-30.00  sec  1.07 GBytes  4.58 Gbits/sec    0   3.01 MBytes
[SUM]  28.00-30.00  sec  4.27 GBytes  18.4 Gbits/sec    0
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-30.00  sec  15.1 GBytes  4.31 Gbits/sec    0             sender
[  4]   0.00-30.00  sec  15.1 GBytes  4.31 Gbits/sec                  receiver
[  6]   0.00-30.00  sec  15.0 GBytes  4.30 Gbits/sec    0             sender
[  6]   0.00-30.00  sec  15.0 GBytes  4.30 Gbits/sec                  receiver
[  8]   0.00-30.00  sec  15.0 GBytes  4.30 Gbits/sec    0             sender
[  8]   0.00-30.00  sec  15.0 GBytes  4.30 Gbits/sec                  receiver
[ 10]   0.00-30.00  sec  15.0 GBytes  4.29 Gbits/sec    0             sender
[ 10]   0.00-30.00  sec  15.0 GBytes  4.29 Gbits/sec                  receiver
[SUM]   0.00-30.00  sec  60.1 GBytes  17.2 Gbits/sec    0             sender
[SUM]   0.00-30.00  sec  60.1 GBytes  17.2 Gbits/sec                  receiver

iperf Done.
```

从以上结果可以看出 4 个数据流接收到的数据大小和平均带宽 4.XX Gbits/sec

```shell
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-30.00  sec  15.1 GBytes  4.31 Gbits/sec    0             sender
[  4]   0.00-30.00  sec  15.1 GBytes  4.31 Gbits/sec                  receiver
[  6]   0.00-30.00  sec  15.0 GBytes  4.30 Gbits/sec    0             sender
[  6]   0.00-30.00  sec  15.0 GBytes  4.30 Gbits/sec                  receiver
[  8]   0.00-30.00  sec  15.0 GBytes  4.30 Gbits/sec    0             sender
[  8]   0.00-30.00  sec  15.0 GBytes  4.30 Gbits/sec                  receiver
[ 10]   0.00-30.00  sec  15.0 GBytes  4.29 Gbits/sec    0             sender
[ 10]   0.00-30.00  sec  15.0 GBytes  4.29 Gbits/sec                  receiver
```

还有接收到的总数据和总带宽 17.2 Gbits/sec

```shell
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[SUM]   0.00-30.00  sec  60.1 GBytes  17.2 Gbits/sec    0             sender
[SUM]   0.00-30.00  sec  60.1 GBytes  17.2 Gbits/sec                  receiver
```

## 测试 UDP 丢包率

```shell
[root@oss-irms-180 ~]# iperf3 -c 10.1.207.181 -u -P 4 -t 30 -i 2 -p 5001
Connecting to host 10.1.207.181, port 5001
[  4] local 10.1.207.180 port 52917 connected to 10.1.207.181 port 5001
[  6] local 10.1.207.180 port 54137 connected to 10.1.207.181 port 5001
[  8] local 10.1.207.180 port 36687 connected to 10.1.207.181 port 5001
[ 10] local 10.1.207.180 port 47721 connected to 10.1.207.181 port 5001
[ ID] Interval           Transfer     Bandwidth       Total Datagrams
[  4]   0.00-2.00   sec   245 KBytes  1.00 Mbits/sec  173
[  6]   0.00-2.00   sec   245 KBytes  1.00 Mbits/sec  173
[  8]   0.00-2.00   sec   245 KBytes  1.00 Mbits/sec  173
[ 10]   0.00-2.00   sec   245 KBytes  1.00 Mbits/sec  173
[SUM]   0.00-2.00   sec   979 KBytes  4.01 Mbits/sec  692
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]   2.00-4.00   sec   256 KBytes  1.05 Mbits/sec  181
[  6]   2.00-4.00   sec   256 KBytes  1.05 Mbits/sec  181
[  8]   2.00-4.00   sec   256 KBytes  1.05 Mbits/sec  181
[ 10]   2.00-4.00   sec   256 KBytes  1.05 Mbits/sec  181
[SUM]   2.00-4.00   sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]   4.00-6.00   sec   256 KBytes  1.05 Mbits/sec  181
[  6]   4.00-6.00   sec   256 KBytes  1.05 Mbits/sec  181
[  8]   4.00-6.00   sec   256 KBytes  1.05 Mbits/sec  181
[ 10]   4.00-6.00   sec   256 KBytes  1.05 Mbits/sec  181
[SUM]   4.00-6.00   sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]   6.00-8.00   sec   256 KBytes  1.05 Mbits/sec  181
[  6]   6.00-8.00   sec   256 KBytes  1.05 Mbits/sec  181
[  8]   6.00-8.00   sec   256 KBytes  1.05 Mbits/sec  181
[ 10]   6.00-8.00   sec   256 KBytes  1.05 Mbits/sec  181
[SUM]   6.00-8.00   sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]   8.00-10.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]   8.00-10.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]   8.00-10.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]   8.00-10.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]   8.00-10.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  10.00-12.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  10.00-12.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  10.00-12.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  10.00-12.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  10.00-12.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  12.00-14.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  12.00-14.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  12.00-14.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  12.00-14.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  12.00-14.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  14.00-16.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  14.00-16.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  14.00-16.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  14.00-16.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  14.00-16.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  16.00-18.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  16.00-18.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  16.00-18.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  16.00-18.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  16.00-18.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  18.00-20.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  18.00-20.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  18.00-20.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  18.00-20.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  18.00-20.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  20.00-22.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  20.00-22.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  20.00-22.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  20.00-22.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  20.00-22.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  22.00-24.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  22.00-24.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  22.00-24.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  22.00-24.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  22.00-24.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  24.00-26.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  24.00-26.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  24.00-26.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  24.00-26.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  24.00-26.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  26.00-28.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  26.00-28.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  26.00-28.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  26.00-28.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  26.00-28.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[  4]  28.00-30.00  sec   256 KBytes  1.05 Mbits/sec  181
[  6]  28.00-30.00  sec   256 KBytes  1.05 Mbits/sec  181
[  8]  28.00-30.00  sec   256 KBytes  1.05 Mbits/sec  181
[ 10]  28.00-30.00  sec   256 KBytes  1.05 Mbits/sec  181
[SUM]  28.00-30.00  sec  1024 KBytes  4.19 Mbits/sec  724
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams
[  4]   0.00-30.00  sec  3.74 MBytes  1.05 Mbits/sec  0.040 ms  0/2707 (0%)
[  4] Sent 2707 datagrams
[  6]   0.00-30.00  sec  3.74 MBytes  1.05 Mbits/sec  0.036 ms  0/2707 (0%)
[  6] Sent 2707 datagrams
[  8]   0.00-30.00  sec  3.74 MBytes  1.05 Mbits/sec  0.036 ms  0/2707 (0%)
[  8] Sent 2707 datagrams
[ 10]   0.00-30.00  sec  3.74 MBytes  1.05 Mbits/sec  0.039 ms  0/2707 (0%)
[ 10] Sent 2707 datagrams
[SUM]   0.00-30.00  sec  15.0 MBytes  4.18 Mbits/sec  0.038 ms  0/10828 (0%)

iperf Done.
```

`Jitter` 列表示抖动时间，或者称为传输延迟，`Lost/Total` 列表示丢失的数据报和总的数据报数量，后面的0%是平均丢包的比率，`Datagrams` 列显示的是总共传输数据报的数量。这个输出结果过于简单，要了解更详细的UDP丢包和延时信息，可以在iperf服务端查看，因为在客户端执行传输测试的同时，服务端也会同时显示传输状态.
