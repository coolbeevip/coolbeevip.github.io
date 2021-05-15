---
title: "MacOS Switch JDK"
date: 2021-03-25T13:24:14+08:00
categories: [macos,jdk,java]
draft: false
---

#### 查看本机 JDK 版本

命令行输入 `/usr/libexec/java_home -V` 可以看到多个 JDK 版本

```shell
$ /usr/libexec/java_home -V
Matching Java Virtual Machines (2):
    11.0.10, x86_64:	"OpenJDK 11.0.10"	/Users/zhanglei/Library/Java/JavaVirtualMachines/adopt-openj9-11.0.10/Contents/Home
    1.8.0_201, x86_64:	"Java SE 8"	/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home

/Users/zhanglei/Library/Java/JavaVirtualMachines/adopt-openj9-11.0.10/Contents/Home
```

#### 查看当前使用的 JDK 版本

```shell
$ java -version
java version "1.8.0_201"
Java(TM) SE Runtime Environment (build 1.8.0_201-b09)
Java HotSpot(TM) 64-Bit Server VM (build 25.201-b09, mixed mode)
```

#### 切换 JDK

切换到 JDK `11.0.10` 版本，并查看切换后的 JDK 版本

```shell
$ export JAVA_HOME=`/usr/libexec/java_home -v 11.0.10`
$ java -version

openjdk version "11.0.10" 2021-01-19
OpenJDK Runtime Environment AdoptOpenJDK (build 11.0.10+9)
Eclipse OpenJ9 VM AdoptOpenJDK (build openj9-0.24.0, JRE 11 Mac OS X amd64-64-Bit Compressed References 20210120_897 (JIT enabled, AOT enabled)
OpenJ9   - 345e1b09e
OMR      - 741e94ea8
JCL      - 0a86953833 based on jdk-11.0.10+9)
```

#### 设置默认的 JDK 版本(可选)

在 `~/.bash_profile` 文件中增加默认切换命令

```shell
export JAVA_HOME=`/usr/libexec/java_home -v 1.8.0_201`
```