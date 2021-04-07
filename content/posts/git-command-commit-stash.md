---
title: "Git Stash"
date: 2021-04-06T13:24:14+08:00
categories: [git]
draft: true
---

你在当前分支上开发代码，此时不想 commit，但是又想切换到其他分支完成其他的工作，此时可以用 stash

1. 在当前分支执行 stash 将当前分支未提交的代码隐藏起来

```shell
$ git stash
Saved working directory and index state WIP on SCB-1577: 2554be3d SCB-1593 Add notice for Boringssl support ciphers
(base) bogon:servicecomb-pack zhanglei$ 
```

此时你可以看到已经存储到一个id为 2554be3d 里了，这时你可以用 git status 查看已经没有要提交的内容了

```shell
git status
On branch SCB-1577
nothing to commit, working tree clean
(base) bogon:servicecomb-pack zhanglei$ 
```

2. 这时你就可以切换到其他分支开始新的工作

```shell
(base) bogon:servicecomb-pack zhanglei$ git checkout master
Switched to branch 'master'
Your branch is up to date with 'origin/master'.
```

3. 返回原来的分支继续工作

```shell
git checkout SCB-1577
Switched to branch 'SCB-1577'
```

4. 查看以前隐藏的修改内容

```shell
git stash list
stash@{0}: WIP on SCB-1577: 2554be3d SCB-1593 Add notice for Boringssl support ciphers
(base) bogon:servicecomb-pack zhanglei$ 
```

5. 恢复隐藏内容继续工作，使用 `git stash apply {id}`

```shell
(base) bogon:servicecomb-pack zhanglei$ git stash apply stash@{0}
On branch SCB-1577
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        modified:   alpha/alpha-server/src/main/java/org/apache/servicecomb/pack/alpha/server/GrpcTxEventEndpointImpl.java
        modified:   alpha/alpha-server/src/main/java/org/apache/servicecomb/pack/alpha/server/fsm/GrpcSagaEventService.java
        modified:   alpha/alpha-server/src/test/java/org/apache/servicecomb/pack/alpha/server/AlphaIntegrationTest.java
        modified:   alpha/alpha-server/src/test/java/org/apache/servicecomb/pack/alpha/server/AlphaIntegrationWithRandomPortTest.java
        modified:   alpha/alpha-server/src/test/java/org/apache/servicecomb/pack/alpha/server/fsm/OmegaEventSender.java
        modified:   omega/omega-connector/omega-connector-grpc/src/main/java/org/apache/servicecomb/pack/omega/connector/grpc/core/PushBackReconnectRunnable.java
        modified:   omega/omega-connector/omega-connector-grpc/src/main/java/org/apache/servicecomb/pack/omega/connector/grpc/core/ReconnectStreamObserver.java
        modified:   omega/omega-connector/omega-connector-grpc/src/main/java/org/apache/servicecomb/pack/omega/connector/grpc/saga/GrpcCompensateStreamObserver.java
        modified:   omega/omega-connector/omega-connector-grpc/src/main/java/org/apache/servicecomb/pack/omega/connector/grpc/saga/GrpcSagaClientMessageSender.java
        modified:   omega/omega-connector/omega-connector-grpc/src/test/java/org/apache/servicecomb/pack/omega/connector/grpc/saga/SagaLoadBalancedSenderTest.java
        modified:   omega/omega-connector/omega-connector-grpc/src/test/java/org/apache/servicecomb/pack/omega/connector/grpc/saga/SagaLoadBalancedSenderTestBase.java
        modified:   pack-contracts/pack-contract-grpc/src/main/proto/GrpcTxEvent.proto

no changes added to commit (use "git add" and/or "git commit -a")
(base) bogon:servicecomb-pack zhanglei$ 
```

至此，你已经完成了整个过程可以原来分支的工作了。

**注意:**
* 在一个分支下多次执行 git stash 会产生多份隐藏数据，你在使用 git stash list 命令的时候可以查看到，恢复的时候注意在 git stash apply 命令后写上隐藏数据的id，这个id类似“stash@{x}” 这样的描述
* 隐藏数据可以使用 git stash drop stash@{x} 命令删除