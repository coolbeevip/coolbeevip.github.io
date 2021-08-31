---
title: "Use Maven plugin to export license info in source files and its optional dependencies"
date: 2021-05-09T13:24:14+08:00
tags: [maven,license]
categories: [java]
draft: false
---

有的时候我们那需要分析多模块 Maven 项目的依赖使用情况，并希望能够分析出这些依赖的 LICENSE 信息。使用 [io.github.coolbeevip:license-maven-plugin](https://github.com/coolbeevip/license-maven-plugin) 插件
可以生成 TXT 或者 CSV 格式的分析报告

[youtube](https://www.youtube.com/watch?v=hhC0m-OZgfM)

[bilibili](https://www.bilibili.com/video/BV1qU4y1t7M4/)

## CSV 格式的报告

![image-notice-csv](/images/posts/maven-export-dependencies-analyse-license/notice-csv.png)

* [NOTICE.CSV](https://github.com/coolbeevip/license-maven-plugin/blob/master/samples/NOTICE.CSV)
* [NOTICE-LICENSE.CSV](https://github.com/coolbeevip/license-maven-plugin/blob/master/samples/NOTICE-LICENSE.CSV)

## TXT 格式的报告

![image-notice-txt](/images/posts/maven-export-dependencies-analyse-license/notice-txt.png)

* [NOTICE.TXT](https://github.com/coolbeevip/license-maven-plugin/blob/master/samples/NOTICE.TXT)
* [NOTICE-LICENSE.TXT](https://github.com/coolbeevip/license-maven-plugin/blob/master/samples/NOTICE-LICENSE.TXT)

## 插件 LICENSE-MAVEN-PLUGIN

* format 导出格式，支持 csv、txt；
* license 是否分析 LICENSE 信息，默认 false；
* ignoreGroupIds 忽略 groupId 列表, 多个用逗号分割;
* timeout 分析 LICENSE 的超时时间，默认 5 秒;

## 导出报告

在 Maven 项目的根目录执行如下命令

导出 CSV

```shell
mvn io.github.coolbeevip:license-maven-plugin:1.5.0:dependency-license-export -Dformat=csv
```

导出 TXT

```shell
mvn io.github.coolbeevip:license-maven-plugin:1.5.0:dependency-license-export -Dformat=txt
````

**提示：** 导出的报告位置在 `./target/distribute` 目录下

## 导出报告(忽略部分依赖)

```shell
mvn io.github.coolbeevip:license-maven-plugin:1.5.0:dependency-license-export -Dformat=csv -DignoreGroupIds=org.apache.servicecomb,com.github.seanyinx
```

## 导出报告(分析LICENSE)

此功能使用 [selenium](https://github.com/SeleniumHQ/selenium) 从 [Maven Central Repository](https://search.maven.org/) 分析依赖的 License 信息

在 MacOS 下安装 selenium 支持，更对支持参见[ChromeDriver](https://github.com/SeleniumHQ/selenium/wiki/ChromeDriver)

```
brew install --cask chromedriver
```

我个人建议手动安装 `ChromeDriver` ，因为 `ChromeDriver` 版本要与你本地安装的 Chrome 浏览器版本保持大版本一致。你可以先查看你浏览器的版本，例如是 `版本 92.0.4515.159（正式版本） (x86_64)`
，您可以在 [ChromeDriver](http://chromedriver.storage.googleapis.com/index.html) 下载版本号最接近的驱动文件。下载解压后将可执行文件 `chromedriver` 放到你本地的目录，并增加到 path 中。
执行一下命令可以看到安装成功

```shell
$ chromedriver --version
ChromeDriver 92.0.4515.107 (87a818b10553a07434ea9e2b6dccf3cbe7895134-refs/branch-heads/4515@{#1634})
```

导出时增加参数 `-Dlicense=true` 即可

```shell
mvn io.github.coolbeevip:license-maven-plugin:1.5.0:dependency-license-export -Dformat=csv -Dlicense=true
```

分析过的 LICENSE 信息会存储在数据文件 `~/.m2/mvnrepository.mapdb` 中，再次分析时会优先从数据文件中提取 LICENSE 信息。
你也可以下载作者的 [mvnrepository.mapdb](https://github.com/coolbeevip/license-maven-plugin/blob/master/db/mvnrepository.mapdb) 文件放到本机 `~/.m2/` 目录下
这个数据文件中包含了作者常用的一些依赖信息