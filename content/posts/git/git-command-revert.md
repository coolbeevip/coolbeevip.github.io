---
title: "Git Revert"
date: 2019-08-06T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

撤销上一次提交

```shell
$ git revert HEAD
```

撤销上两次提交
* [ISSUE-4](http://10.19.83.185:8081/ncdf/nc/nc-gateway-server/-/issues/4) 解决网关服务日志中无法正确显示经过代理访问的请求端 IP 问题
```shell
$ git revert [倒数第一个提交] [倒数第二个提交]
```