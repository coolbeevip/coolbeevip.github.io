---
title: "Git Pick Commits to Another Reps"
date: 2023-02-18T09:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

从上游仓库中选取 commits 提交到另一个仓库

> 附加修改作者，消息，时间

## 前期准备

你要准备一个要同步的库

```shell
# 下载这个库
git clone git@github.com:coolbeevip/git-commits-replay.git

# 查看这个库的所有 commits
git --git-dir=./git-commits-replay/.git log --pretty=format:"%H,%an,%ae,%ad,%s" --date=format:'%Y-%m-%d %H:%M:%S' --reverse

52d099240f6da63193ba309106dad77d060836a7,Lei Zhang,zhanglei@apache.org,2023-02-18 10:49:43,Create A.md
516e406615c0020919939bafe59b35359a03c33b,Lei Zhang,zhanglei@apache.org,2023-02-18 10:50:09,Create B.md
551e5c88440396b73f3b1642bf765dcb9136fd1f,Lei Zhang,zhanglei@apache.org,2023-02-18 10:50:30,Create C.md
5dacf876b6f0b4a0d3ead7ec3daaac924b1b37f4,Lei Zhang,zhanglei@apache.org,2023-02-18 10:51:02,Create ALL.md
72a7a54c48286e9a7c92d1201108baa61cbd7db4,Lei Zhang,zhanglei@apache.org,2023-02-18 10:52:13,删除 A B C
```

新建一个仓库并关联要同步的库

```shell
# 新建一个本地仓库
mkdir git-commits-replay-local
cd git-commits-replay-local
git init
git config --global init.defaultBranch master
git branch -m master

# 关联上游仓库
git remote add upstream git@github.com:coolbeevip/git-commits-replay.git
```

## 重放 commit 并修改提交信息

> 例如要将 52d099240f6da63193ba309106dad77d060836a7,Lei Zhang,zhanglei@apache.org,2023-02-18 10:49:43,Create A.md 同步并修改

```shell
# 拉取上游
git fetch upstream

# 摘取 commit-id 到本地仓库
git cherry-pick 52d099240f6da63193ba309106dad77d060836a7
git commit --author='Lei Zhang <coolbeevip@gmail.com>' --amend -m '增加 A.md 文件' --date "Mon 20 Aug 2018 20:19:19 BST" --no-edit
```

查看同步后的内容

```shell
git log
commit 12edb6e32da6d4550bad395d692b346dd9dbc5e2 (HEAD -> master)
Author: Lei Zhang <coolbeevip@gmail.com>
Date:   Mon Aug 20 20:19:19 2018 +0100

    增加 A.md 文件
```

## 相关命令

1. 获取 commit 清单

```shell
git --git-dir=/work/git-commits-replay/.git log --pretty=format:"%H,%an,%ae,%ad,%s" --date=format:'%Y-%m-%d %H:%M:%S' --reverse

52d099240f6da63193ba309106dad77d060836a7,Lei Zhang,zhanglei@apache.org,2023-02-18 10:49:43,Create A.md
516e406615c0020919939bafe59b35359a03c33b,Lei Zhang,zhanglei@apache.org,2023-02-18 10:50:09,Create B.md
551e5c88440396b73f3b1642bf765dcb9136fd1f,Lei Zhang,zhanglei@apache.org,2023-02-18 10:50:30,Create C.md
5dacf876b6f0b4a0d3ead7ec3daaac924b1b37f4,Lei Zhang,zhanglei@apache.org,2023-02-18 10:51:02,Create ALL.md
72a7a54c48286e9a7c92d1201108baa61cbd7db4,Lei Zhang,zhanglei@apache.org,2023-02-18 10:52:13,删除 A B C
```

2. 获取 commit-id 的文件清单

```shell
git --git-dir=/work/git-commits-replay/.git show --pretty=format:"%H,%an,%ae,%ad,%s" --no-commit-id --name-status 52d099240f6da63193ba309106dad77d060836a7

A       A.md
52d099240f6da63193ba309106dad77d060836a7,Lei Zhang,zhanglei@apache.org,Sat Feb 18 10:49:43 2023 +0800,Create A.md
```
