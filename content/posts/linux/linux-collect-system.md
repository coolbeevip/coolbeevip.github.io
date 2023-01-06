---
title: "Linux Command - Supervisory"
date: 2022-11-07T13:24:14+08:00
tags: [linux,cpu,memory,collect]
categories: [linux]
draft: false
---

## 定时收集当前用户的CPU和内存利用率

创建如下 `user_usage.sh`

```shell
#!/usr/bin/bash

echo -e CPU%\\tMEM%
while true
  do    
    top -b -n 1 -u "$user" | awk -v user="$user" 'NR>7 { cpu_utilization_sum += $9;  mem_utilization_sum += $10;} END { printf "%.2f\t%.2f\n",cpu_utilization_sum,mem_utilization_sum; }'
  sleep $1
done
```

每 3 秒采集一次并保存到 user_usage.log 文件中

```shell
sh user_usage.sh 3 > user_usage.log &
```

## 定时收集某个进程的CPU和内存利用率

创建如下 `proc_usage.sh`

```shell
#!/usr/bin/bash

echo proc $2
echo -e CPU%\\tMEM%
while true
  do    
    top -b -n 1 -p `ps -ef | grep $2 | grep -v grep | awk '{ print $2 }' | paste -s -d ','` | awk -v user="$user" 'NR>7 { cpu_utilization_sum += $9;  mem_utilization_sum += $10;} END { printf "%.2f\t%.2f\n",cpu_utilization_sum,mem_utilization_sum; }'
  sleep $1
done
```

每 3 秒采集一次进程 myproc 的利用率并保存到 proc_usage.log 文件中

> 你可以使用 `ps -ef | grep myproc` 命令先检查一下 `myproc` 是否是你要监控的进程

```shell
sh proc_usage.sh 3 myproc > proc_usage.log &
```