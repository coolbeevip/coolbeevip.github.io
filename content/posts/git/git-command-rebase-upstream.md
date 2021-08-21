---
title: "Synchronizing Your Forked Git Project"
date: 2020-04-06T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

当你 fork 一个仓库后，可以时用此方法使你 fork 后的仓库 master 分支保持和上游 master 分支的同步

使用 `rebase` 命令同步上游 master 分支到你本地的 master 分支，并推送到你 fork 后的仓库

```shell
git fetch upstream
git checkout master
git rebase upstream/master
git push -f origin master
```

或者你确定放弃你本地所有的修改，则可以简单的重置为上游版本

```shell
git fetch upstream
git checkout master
git reset --hard upstream/master
git push -f origin master
```

如果你也想同步 master 分支的修改到你的功能分支

```shell
git checkout <分支名>
git rebase master
git push -f origin <分支名>
```
