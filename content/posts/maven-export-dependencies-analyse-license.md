---
title: "导出 Maven 项目的依赖报告并分析 LICENSE 信息"
date: 2021-05-09T13:24:14+08:00
categories: [maven,license,opensource]
draft: false
---

有的时候我们那需要分析多模块 Maven 项目的依赖使用情况，并希望能够分析出这些依赖的 LICENSE 信息。使用 [io.github.coolbeevip:license-maven-plugin](https://github.com/coolbeevip/license-maven-plugin) 插件
可以生成 TXT 或者 CSV 格式的分析报告

## CSV 格式的报告

![image-notice-csv](/images/posts/maven-export-dependencies-analyse-license/notice-csv.png)

## TXT 格式的报告

![image-notice-txt](/images/posts/maven-export-dependencies-analyse-license/notice-txt.png)

## 插件 LICENSE-MAVEN-PLUGIN

* -Dformat 导出格式，例如 `-Dformat=csv` (默认)；或者 `-Dformat=txt`；
* -Dlicense 是否分析 LICENSE 信息，例如 `-Dlicense=false`（默认）;  `-Dlicense=true`；

## 导出报告

在 Maven 项目的根目录执行如下命令

导出 CSV

```shell
mvn io.github.coolbeevip:license-maven-plugin:1.4.0:dependency-license-export -Dformat=csv
```

导出 TXT

```shell
mvn io.github.coolbeevip:license-maven-plugin:1.4.0:dependency-license-export -Dformat=txt
````

## 分析 LICENSE

此功能使用 [selenium](https://github.com/SeleniumHQ/selenium) 从 [Maven Central Repository](https://search.maven.org/) 分析依赖的 License 信息

在 MacOS 下安装 selenium 支持，更对支持参见[ChromeDriver](https://github.com/SeleniumHQ/selenium/wiki/ChromeDriver)

```
brew install --cask chromedriver
```

导出时增加参数 `-Dlicense=true` 即可

```shell
mvn io.github.coolbeevip:license-maven-plugin:1.4.0:dependency-license-export -Dformat=csv -Dlicense=true
```