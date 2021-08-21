---
title: "Maven Commands"
date: 2018-11-23T13:24:14+08:00
tags: [maven]
categories: [java]
draft: false
---

常用 Maven 命令

## Parameters

* -D 指定参数，如 -Dmaven.test.skip=true 跳过单元测试；
* -P 指定 Profile 配置，可以用于区分环境；
* -e 显示maven运行出错的信息；
* -o 离线执行命令,即不去远程仓库更新包；
* -f 强制指定使用 POM 文件，或者包含 POM 文件的目录
* -pl 选项后可跟随{groupId}:{artifactId}或者所选模块的相对路径(多个模块以逗号分隔)
* -am 表示同时处理选定模块所依赖的模块
* -amd 表示同时处理依赖选定模块的模块
* -rf 表示从指定模块开始继续处理  
* -N 表示不递归子模块  
* -X 显示maven允许的debug信息；
* -U 强制去远程更新 snapshot的插件或依赖，默认每天只更新一次。
* --no-snapshot-updates 禁止更新 snapshot 

## Dependency

显示maven依赖数

```shell
mvn dependency:tree
```

显示maven依赖列表

```shell
mvn dependency:list
````

下载依赖包的源码

```shell
mvn dependency:sources
```

## Maven Wrapper

自动安装 maven 的包装器（适合不想手动安装Maven的用户），使用插件[Maven Wrapper plugin](https://github.com/takari/takari-maven-plugin)将其自动化安装指定版本的 Maven

```shell
mvn -N io.takari:maven:wrapper -Dmaven=3.6.3
```

这个命令会在你的项目中生成如下文件，请将这些文件与源代码一起管理

* mvnw: 这是 Linux Script 可执行文件，用来代替 `mvn`
* mvnw.cmd: 这是 Windows Script 可执行文件，用来代替 `mvn`
* mvn: 隐藏的文件夹，其中包含Maven Wrapper Java库及其属性文件

首次执行 `mvnw` 或者 `mvnw.cmd` 时会自动下载对应版本的 Maven 到本地，支持 Linux、OSX 、Windows 、Solaris。

在 Linux 下执行编译

```shell
./mvnw clean install
```
在 Windows 下执行编译

```shell
./mvnw.cmd clean install
```

### 批量修改 POM 版本号

```shell
mvn versions:set -DnewVersion=4.1.9
```

确认修改

```shell
mvn versions:commit
```

取消修改

```shell
mvn versions:revert
```