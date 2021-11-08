---
title: "Linux Command - Grep"
date: 2021-11-07T13:24:14+08:00
tags: [linux,grep]
categories: [linux]
draft: false
---

## 使用正则表达式搜索文件内容

macOS

```shell
cat nc-auth_3000.log | grep -s 'timeCost":\d\d\d\d'
```

centOS

```shell
cat nc-auth_3000.log | grep -P 'timeCost":\d\d\d\d'
```

## 使用正则表达式搜索压缩文件内容

macOS

```shell
gzip -dc nc-auth_3000.20211106.38.log.gz | grep -s 'timeCost":\d\d\d\d'
```

centOS

```shell
gzip -dc nc-auth_3000.20211106.38.log.gz | grep -P 'timeCost":\d\d\d\d'
```
