---
title: "Awesome Git Aliases"
date: 2022-04-02T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

我们可以通过别名定义简化命令输出，创造自己的命令

打开 `~/.gitconfig` 文件您可以看到如下片段，在这个片段中我们可以为已有命令定义别名

```toml
[alias]
```

例如我们创建分支是需要使用 `git branch -b xxx` 命令，那么我们可以将 `branch` 简化为 `br`。我们只需要增加如下配置

```toml
[alias]
  br = branch
```

这是我自己常用的配置

```toml
[alias]
  ci = commit -a
  co = checkout
  cl = clone
  st = status
  br = branch
  mr = merge
  cp = cherry-pick
  hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
  type = cat-file -t
  dump = cat-file -p
```