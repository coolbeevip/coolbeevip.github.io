---
title: "Linux Command - CRON"
date: 2023-05-16T13:24:14+08:00
tags: [linux,cron]
categories: [linux]
draft: false
---

Linux CRON 命令

## CREATE A CRON SCRIPT TO CLEAN

Edit the /opt/daily-clean.sh file 

```shell
#!/bin/bash

# docker
docker system prune -f
docker builder prune -f
docker volume prune -f

# /home/puaiuc/
find /home/puaiuc/ -maxdepth 1 -type f \( -iname "*" ! -iname ".*" \) -delete
```

Now give the file executable permission

```shell
chmod a+x /opt/daily-clean.sh
```

Edit the crontab file to schedule it

```shell
crontab -e
```

In our case, we have scheduled it to every day at the start of the day

```shell
0 1 * * * sh /opt/daily-clean.sh
```


