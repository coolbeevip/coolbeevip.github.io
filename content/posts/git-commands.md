---
title: "Git Commands"
date: 2019-04-06T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

常用 Git 命令

## Init

在已有目录中初始化 GIT 仓库

```
$ git init
$ git remote add origin <仓库地址>
$ git add .
$ git commit -m "Initial commit"
$ git push -u origin master
```

## Branch

创建分支

```shell
git checkout -b <分支名>
```

推送分支

```shell
git push origin <分支名> 
```

修改分支名

```shell
git branch -m <旧分支名> <新分支名>
```

删除本地分支

```shell
git branch -D <分支名>
```

删除远程分支

```shell
git push origin --delete <分支名>
```

拉取远程分支

```shell
git fetch origin <分支名>
```

拉取远程分支并切换

```shell
git checkout -b <分支名> origin/<分支名>
```

当前分支会退到指定版本

```shell
git reset --hard <版本号的sha1>
```

## Tag

创建本地 Tag

```shell
git tag -a <标签名> -m "my tag"
```

删除本地 Tag

```shell
git tag -d <标签名>
```

删除远程 Tag

```shell
git push origin :refs/tags/<标签名>
```

推送本地所有 Tag 到远程

```shell
git push origin --tags
```

重命名 Tag

```shell
git tag <新标签名> <老标签名>
git tag -d <老标签名>
git push origin <新标签名> :<老标签名>
```

## Commit

修改最后一次 commit

```shell
git commit --amend
```

合并 commit

```shell
git rebase -i <commit id>
```