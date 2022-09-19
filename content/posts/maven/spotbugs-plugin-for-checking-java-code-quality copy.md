---
title: "在 Maven 项目中使用 Spotbugs Plugin 检查 Java 代码（字节码）质量"
date: 2022-09-18T13:24:14+08:00
tags: [java, spotbugs]
categories: [maven]
draft: false
---

本文记录了如何在 Maven 项目中使用 [SpotBugs Maven Plugin](https://spotbugs.github.io/spotbugs-maven-plugin/) 检查代码（字节码）质量

## 一个 Maven 项目

假设我有一个 Maven 项目，这个项目包含若干子模块。根目录的 pom.xml 看起来如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>
  <groupId>my</groupId>
  <artifactId>my-project</artifactId>
  <version>${revision}</version>
  <packaging>pom</packaging>

  <properties>
  	<revision>0.1.0-SNAPSHOT</revision>
  </properties>

  <modules>
    <module>module-dependencies</module>
    <module>module-bar</module>
    <module>module-foo</module>   
  </modules>
</project>
```

## 在根项目 pom.xml 中增加 `spotbugs-maven-plugin` 插件

增加 spotbugs-maven-plugin 插件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>
  <groupId>my</groupId>
  <artifactId>my-project</artifactId>
  <version>${revision}</version>
  <packaging>pom</packaging>

  <properties>
    <spotbugs-maven-plugin.version>4.7.1.1</spotbugs-maven-plugin.version>
  </properties>

  <modules>
    <module>module-dependencies</module>
    <module>module-bar</module>
    <module>module-foo</module>   
  </modules>

  <build>
    <pluginManagement>
      <plugins>    
        <plugin>
          <groupId>com.github.spotbugs</groupId>
          <artifactId>spotbugs-maven-plugin</artifactId>
          <version>${spotbugs-maven-plugin.version}</version>
          <configuration>
            <includeFilterFile>src/spotbugs/spotbugs-include.xml</includeFilterFile>
            <excludeFilterFile>src/spotbugs/spotbugs-exclude.xml</excludeFilterFile>
            <includeTests>false</includeTests>
          </configuration>
        </plugin>
      </plugins>
    </pluginManagement>

    <plugins>
      <plugin>
        <groupId>com.github.spotbugs</groupId>
        <artifactId>spotbugs-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

增加 `src/spotbugs/spotbugs-include.xml` 包含规则文件，这个文件中你可以指定检查哪些包，以及使用哪些 [BUG规则](https://spotbugs.readthedocs.io/en/latest/bugDescriptions.html)


```xml
<FindBugsFilter>
  <Match>
    <Package name="~com\.my\.project.*" />
    <Bug category="SECURITY,BAD_PRACTICE"/>
  </Match>
</FindBugsFilter>
```

增加 `src/spotbugs/spotbugs-exclude.xml` 排除规则文件，这个文件中你指定排除哪些规则


```xml
<FindBugsFilter>
  <Match>
    <Bug pattern="EQ_COMPARETO_USE_OBJECT_EQUALS"></Bug>
  </Match>
</FindBugsFilter>
```

## 命令行检查

你可以在 PR 的合并请求时使用以下命令，已确保代码合并前符合规则

```shell
mvn clean validate -DskipTests spotbugs:check
```

## IDE 工具

[Jetbrains IDEA SpotBugs](https://plugins.jetbrains.com/plugin/14014-spotbugs)