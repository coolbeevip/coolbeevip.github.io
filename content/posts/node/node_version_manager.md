---
title: "Node 版本管理工具"
date: 2023-08-16T12:24:14+08:00
tags: [node]
categories: [node]
draft: false
---

官方网站 https://github.com/nvm-sh/nvm/

## 安装

```shell
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
```

## 使用

查看远程可用版本

```shell
nvm ls-remote
```

安装

```shell
nvm install 14.21.3
```

切换

```shell
nvm use 14.21.3
```