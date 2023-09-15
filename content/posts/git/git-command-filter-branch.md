---
title: "Git filter-branch"
date: 2023-09-15T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

使用git filter-branch --commit-filter重新历史记录可能会导致数据丢失。这个命令允许你在Git存储库的历史记录中进行修改，应用一个自定义的commit过滤器。当你使用这个命令时，请务必小心操作，因为它会改变存储库的历史记录。

在执行git filter-branch之前，建议先进行备份，以确保你有一个完好的历史记录备份。另外，这个命令可能会导致一些副作用，如更改提交哈希值、移除或合并提交、删除部分文件等。

因此，在执行git filter-branch之前，请确保你已经理解了它的工作原理，并且在执行前考虑了潜在的风险。如果你不确定自己在做什么，建议先创建一个分支进行实验，以避免意外破坏存储库的历史记录。

## 删除 README.md 和 docs/docker_build.md 两个文件，并清理所有产生的提交

```shell
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch README.md docs/docker_build.md' --prune-empty --tag-name-filter cat -- --all
```

## 删除指定编号的提交信息

使用 `git log --oneline` 命令查询到要删除提交

```shell
git log --oneline | grep Update
ed2e2a7 [feat]:[][Update docs/场景梳理.xlsx]
2a919eb [feat]:[][Update docs/场景梳理.xlsx]
```

记录要删除的提交短 ID 到以下脚本的 `DEL_COMMIT_IDS=['ed2e2a7','a919eb']` 位置

```shell
git filter-branch --force --commit-filter 'DEL_COMMIT_IDS=['ed2e2a7','a919eb']; if [[ $DEL_COMMIT_IDS =~ ${GIT_COMMIT:0:7} ]]; then skip_commit "$@"; else git commit-tree "$@"; fi' HEAD
```

执行后可以看到 `Ref 'refs/heads/master' was rewritten` 表示已经重写了历史记录，然后再用 `git log --oneline` 查看可以看到已经删除
