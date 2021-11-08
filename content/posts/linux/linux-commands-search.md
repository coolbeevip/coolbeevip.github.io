---
title: "Linux Command - Disk"
date: 2021-11-08T13:24:14+08:00
tags: [linux,grep]
categories: [linux]
draft: false
---

Linux 文件搜索相关命令

## Grep

使用正则表达式搜索文件内容

```shell
cat nc-auth_3000.log | grep -s 'timeCost":\d\d\d\d'
```

使用正则表达式搜索压缩文件内容

```shell
gzip -dc nc-auth_3000.20211106.38.log.gz | grep -s 'timeCost":\d\d\d\d'
```
