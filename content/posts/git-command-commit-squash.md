---
title: "Git Squash Commits"
date: 2020-04-06T13:24:14+08:00
categories: [git]
draft: false
---

压缩合并 Commits，将多个 commit 整理合并的方法，这样可以使提交记录更加清晰

1. 查看提交记录，选择你要合并的范围

```shell
git log

commit 6d757f70af289b5a90d00bd5e4b93d892d64a258 (HEAD -> SCB-1669)
Author: Lei Zhang <zhanglei@apache.org>
Date:   Thu Dec 19 13:53:26 2019 +0800

    SCB-1669 Fixed reverse compensation sort bug in FSM

commit 37e0c5d99d0e6dae188cbd78f543ba69433b928f (origin/SCB-1669)
Author: Lei Zhang <zhanglei@apache.org>
Date:   Thu Dec 19 02:00:20 2019 +0800

    SCB-1669 Fixed Reverse compensation sort bug in FSM

commit b4ea8717a86d1eba1956d21727d05c466ff6d8a2 (upstream/master, origin/master, origin/HEAD, master)
Author: Lei Zhang <zhanglei@apache.org>
Date:   Tue Dec 10 16:25:48 2019 +0800

    SCB-1658 Improve encapsulation on txEntityMap of SagaData
```

可以看到最后两次提交，都是为了修复 SCB-1669 这个问题，此时我想合并最后两次提交 `6d757f70af289b5a90d00bd5e4b93d892d64a258` 和 `37e0c5d99d0e6dae188cbd78f543ba69433b928f`

2. 开始合并，使用rebase命令调出要合并的log（注意：以下命令中最后的提交序号是要合并的提交的前一次提交）

```shell
$ git rebase -i b4ea8717a86d1eba1956d21727d05c466ff6d8a2

pick 37e0c5d9 SCB-1669 Fixed Reverse compensation sort bug in FSM
pick 6d757f70 SCB-1669 Fixed reverse compensation sort bug in FSM

# Rebase b4ea8717..6d757f70 onto b4ea8717 (2 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup <commit> = like "squash", but discard this commit's log message
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
# .       create a merge commit using the original merge commit's
# .       message (or the oneline, if no original merge commit was
# .       specified). Use -c <commit> to reword the commit message.
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
```

3. 将最后一次提交的 pick 改为 squash

```shell
pick 37e0c5d9 SCB-1669 Fixed Reverse compensation sort bug in FSM
squash 6d757f70 SCB-1669 Fixed reverse compensation sort bug in FSM
```

4. wq保存退出，会提示输入新的提交说明，再次wq保存退出

```shell
(base) bogon:servicecomb-pack zhanglei$ git rebase -i b4ea8717a86d1eba1956d21727d05c466ff6d8a2
[detached HEAD b7f9da4f] SCB-1669 Fixed reverse compensation sort bug in FSM
 Date: Thu Dec 19 02:00:20 2019 +0800
 3 files changed, 64 insertions(+), 4 deletions(-)
 create mode 100644 alpha/alpha-fsm/src/test/java/org/apache/servicecomb/pack/alpha/fsm/model/TxEntitiesTest.java
Successfully rebased and updated refs/heads/SCB-1669.
```

5. 再次执行 git log 可以看到最后两次提交已经合并

```shell
commit b7f9da4f386d47220768c6329e5c95777f83bce9 (HEAD -> SCB-1669)
Author: Lei Zhang <zhanglei@apache.org>
Date:   Thu Dec 19 02:00:20 2019 +0800

    SCB-1669 Fixed reverse compensation sort bug in FSM

commit b4ea8717a86d1eba1956d21727d05c466ff6d8a2 (upstream/master, origin/master, origin/HEAD, master)
Author: Lei Zhang <zhanglei@apache.org>
Date:   Tue Dec 10 16:25:48 2019 +0800

    SCB-1658 Improve encapsulation on txEntityMap of SagaData
```

**后悔药:** 如果想放弃此次合并可以执行 `git rebase --abort`