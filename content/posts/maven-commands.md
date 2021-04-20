---
title: "常用 Maven 命令"
date: 2018-11-23T13:24:14+08:00
categories: [maven]
draft: false
---

常用 Maven 命令

## Parameters

* -D 指定参数，如 -Dmaven.test.skip=true 跳过单元测试；
* -P 指定 Profile 配置，可以用于区分环境；
* -e 显示maven运行出错的信息；
* -o 离线执行命令,即不去远程仓库更新包；
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