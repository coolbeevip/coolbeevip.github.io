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

echo -e TIME\\tCPU%\\tMEM%
while true
  do    
    top -b -n 1 -u "$user" | awk -v user="$user" -v date="$(date '+%Y/%m/%d %H:%M:%S')" 'NR>7 { cpu_utilization_sum += $9;  mem_utilization_sum += $10;} END { printf "%s\t%.2f\t%.2f\n",date,cpu_utilization_sum,mem_utilization_sum; }'
  sleep $1
done
```

每 3 秒采集一次

```shell
sh user_usage.sh 3
TIME	CPU%	MEM%
2023/01/06 17:26:56	64.80	82.10
2023/01/06 17:26:57	70.60	82.10
2023/01/06 17:26:58	393.60	82.10
2023/01/06 17:26:59	137.50	82.20
```

## 定时收集某个进程的CPU和内存利用率

创建如下 `proc_usage.sh`

```shell
#!/usr/bin/bash

echo proc $2
echo -e TIME\\tCPU%\\tMEM%
while true
  do    
    top -b -n 1 -p `ps -ef | grep $2 | grep -v grep | awk '{ print $2 }' | paste -s -d ','` | awk -v user="$user" -v date="$(date '+%Y/%m/%d %H:%M:%S')" 'NR>7 { cpu_utilization_sum += $9;  mem_utilization_sum += $10;} END { printf "%s\t%.2f\t%.2f\n",date,cpu_utilization_sum,mem_utilization_sum; }'
  sleep $1
done
```

每 3 秒采集一次进程 myproc

> 你可以使用 `ps -ef | grep myproc` 命令先检查一下 `myproc` 是否是你要监控的进程

```shell
sh proc_usage.sh 3 myproc
TIME	CPU%	MEM%
2023/01/06 17:29:27	26.70	23.70
2023/01/06 17:29:30	0.00	23.70
2023/01/06 17:29:33	13.40	23.70
```

## 定时收集常用系统指标

创建如下 `system_usage.sh`

```shell
#!/usr/bin/bash

echo -e TIME\\tCPU\\tMEM\\tDISK
while true
  do
    MEMORY=$(free -m | awk 'NR==2{printf "%.2f%%\t\t", $3*100/$2 }')
    DISK=$(df -h | awk '$NF=="/"{printf "%s\t\t", $5}')
    CPU=$(top -bn1 | grep load | awk '{printf "%.2f%%\t\t\n", $(NF-2)}')
    echo -e $(date '+%Y/%m/%d %H:%M:%S')\\t$CPU\\t$MEMORY\\t$DISK    
  sleep $1
done
```

每 5 秒采集一次

```shell
$ sh system_usage.sh 5
TIME	CPU	MEM	DISK
2023/01/06 17:20:53	4.34% 	83.59% 	76%
2023/01/06 17:20:54	4.16% 	83.58% 	76%
2023/01/06 17:20:55	4.16% 	83.57% 	76%
2023/01/06 17:20:57	4.16% 	83.57% 	76%
2023/01/06 17:20:58	4.16% 	83.56% 	76%
2023/01/06 17:20:59	4.06% 	83.57% 	76%
2023/01/06 17:21:00	4.06% 	83.58% 	76%
2023/01/06 17:21:02	4.06% 	83.59% 	76%
```