---
title: "Git Reset HEAD"
date: 2019-08-06T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

Git 分支非常有用，您可以根据需要创建一个新分支，合并一个分支或删除一个分支。 您可以使用许多 git 命令来管理 git 中的分支。

当您使用 git checkout 分支时，HEAD会指出最后的提交。 简单来说，您可以说 Git HEAD 是当前分支。 每当您签出一个分支或创建一个新分支时，Git HEAD 都会转移它。

HEAD 是对当前检出分支中最后一次提交的引用。

在存储库中，HEAD 始终指向当前分支的起点。 换句话说，HEAD 是指向下一个提交的父对象或下一个提交将发生的地方的指针。

更具体地说，HEAD 是一个移动指针，它可以引用或可以不引用当前分支，但是它始终引用当前提交。

### 什么是 HEAD^

插入符（^）是 Commit 的父级。

### 什么是 HEAD~

代字号（〜）是一行几个字符（^）的简写字符。

HEAD〜2 与 HEAD ^^ 的作用相同。

如果写数字，则使用的默认值为1，因此 HEAD〜 等价于 HEAD ^。

### 如何检查HEAD的状态

您可以使用以下命令查看当前 Git HEAD 指向的位置：

```shell
$ cat .git/HEAD
ref: refs/heads/master
```

并且，你可以使用以下命令查看指向 HEAD 的 commit 的 Hash ID：

```shell
$ git rev-parse --short HEAD
6f975a5
```

### Detached HEAD

HEAD 是您目前的工作分支。 当您尝试 git checkout 分支时，HEAD 指向该分支的顶部，这样您就可以继续工作而没有任何困难。

如果您使用 git checkout <commit sha1> 签出特定的提交，则您已经处于 **Detached HEAD**。 这意味着之后的所有提交都不属于任何 Git 分支，您无法将代码合并到 main 分支或任何其他分支中。

**如果此时使用 git checkout 命令切换分支，您的修改将丢失**。

### Detached HEAD 解决方案

当你看到 **You're in the 'detached HEAD' state** 提示时，不是一种错误，此状态只是意味着你没有处于任何分支中

您可以随时使用 `git  checkout` 命令从 **detached HEAD** 返回到分支中

```shell
$ git checkout <your-branch>
```

如果您已经对 **detached HEAD** 进行了一些更改并且不想丢失它们，则应将这些更改保存到一个临时分支中：

```shell
$ git checkout -b <temporary-branch-name>
```

之后，可以将临时分支合并到另一个分支中，例如到主分支：

```shell
$ git checkout main
$ git merge <temporary-branch-name>
```

### Git Head Reset

首先，**git reset-hard 是一个危险的命令**。它可以销毁所有未提交的修改。在开始使用之前，请确保仔细检查 git status 是否还有未提交的修改。将更改提交到存储库后，您的更改将是安全的。

git reset 命令以特定顺序覆盖（HEAD /索引 /工作目录），并有有三种不同的模式

**Soft:**

这种模式只会移动 HEAD。并且，您的索引（暂存区）和工作目录将不受影响。

```shell
$ git reset --soft
```

**Mixed:**

这是默认模式。因此，如果您编写 git reset，该命令将在混合模型中运行。

此模式将移动 HEAD 并更新临时区域。因此，此命令将撤消由 git add 和 git commit 添加的内容。

```shell
$ git reset --mixed or $ git reset
```

**Hard:**

**使用此命令可能很危险。仅当您确切知道自己在做什么时才使用。**

此命令将移动 HEAD 和暂存区域。同样，它将撤消您的最后一次提交。

如果您想在 HEAD 之前重置提交（您需要撤消上一次提交），可以将 git reset 命令与 hard 选项一起使用：

```shell
$ git reset --hard HEAD^
```

### 总结

git reset 的目的是将当前 HEAD 转移到指定的提交（在HEAD本身上，在HEAD之前的一个提交，依此类推）。

本文内容来自于[Git HEAD: The Definitive Guide](https://acompiler.com/git-head/)
