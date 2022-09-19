---
title: "在 Maven 多模块项目中使用 JaCoCo"
date: 2022-07-03T13:24:14+08:00
tags: [java, jacoco]
categories: [maven]
draft: false
---

本文记录了如何在 Maven 多模块项目中使用 JaCoCo 生成覆盖率报告并推送到 Sonar 中

## 一个多模块项目

假设我有一个多模块项目，这个项目包含若干子模块，并且有若干测试用例。根目录的 pom.xml 看起来如下：

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

关于 `module-dependencies` 模块的作用，可以查看我之前写的[MAVEN PROJECTS BEST PRACTICES](https://coolbeevip.github.io/posts/maven/maven-best-practices-for-structuring-projects-and-modules/)


## 在根项目 pom.xml 中增加 `jacoco-maven-plugin` 插件，并增加 `module-coverage` 模块

增加 jacoco-maven-plugin 插件

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
    <jacoco-maven-plugin.version>0.8.6</jacoco-maven-plugin.version>
  </properties>

  <modules>
    <module>module-dependencies</module>
    <module>module-bar</module>
    <module>module-foo</module>   
    <module>module-coverage</module>
  </modules>

  <build>
    <pluginManagement>
      <plugins>    
        <plugin>
          <groupId>org.jacoco</groupId>
          <artifactId>jacoco-maven-plugin</artifactId>
          <version>${jacoco-maven-plugin.version}</version>
        </plugin>
      </plugins>
    </pluginManagement>

    <plugins>
      <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <executions>
          <execution>
            <id>prepare-agent</id>
            <goals>
              <goal>prepare-agent</goal>
            </goals>
          </execution>
          <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
              <goal>report</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

增加 `module-coverage` 模块，此模块的作用就是搜集所有子模块的覆盖率报告并汇聚到本模块的 `target/site/jacoco-aggregate/jacoco.xml` 文件中，注意需要将要统计的模块增加到这个模块中


```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>my</groupId>
    <artifactId>my-project</artifactId>
    <version>${revision}</version>
  </parent>  
  <artifactId>module-coverage</artifactId>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>my</groupId>
        <artifactId>module-dependencies</artifactId>
        <version>${project.version}</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <dependencies>
    <dependency>
      <groupId>my</groupId>
      <artifactId>module-bar</artifactId>
    </dependency>
    <dependency>
      <groupId>my</groupId>
      <artifactId>module-foo</artifactId>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <executions>
          <execution>
            <phase>initialize</phase>
            <goals>
              <goal>prepare-agent</goal>
            </goals>
          </execution>
          <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
              <goal>report-aggregate</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```


在两个子模块 `module-bar` 和 `module-foo` 中定义 `sonar.coverage.jacoco.xmlReportPaths` 参数，将本模块的覆盖率报告输出到 `module-coverage` 模块的 target 下

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <parent>
    <groupId>my</groupId>
    <artifactId>module-dependencies</artifactId>
    <version>${revision}</version>
    <relativePath>../module-dependencies</relativePath>
  </parent>
  <modelVersion>4.0.0</modelVersion>

  <artifactId>module-bar</artifactId>

  <properties>
    <sonar.coverage.jacoco.xmlReportPaths>../module-coverage/target/site/jacoco-aggregate/jacoco.xml</sonar.coverage.jacoco.xmlReportPaths>
  </properties>
</project>
```


## 生成覆盖率测试报告

执行如下命令，你将在 `module-coverage` 模块下找到  `target/site/jacoco-aggregate/index.html` 覆盖率报告，以及覆盖率数据 `target/site/jacoco-aggregate/jacoco.xml`

```shell
./mvnw clean package
```

## 推送覆盖率报告到 Sonar


你需要在 Sonar 上创建你的项目 `sonar.projectKey=my-projec` 和 key `-Dsonar.login=83cf76c9cc3d580d001e35d709636eaab64c4ed7` ，在这个项目的 `Project Settings -> JaCoCo -> sonar.coverage.jacoco.xmlReportPaths` 属性中填写 `target/site/jacoco-aggregate/jacoco.xml`


然后使用如下命令将覆盖率报告 `target/site/jacoco-aggregate/jacoco.xml` 推送到 Sonar 中。


```shell
./mvnw clean package sonar:sonar -Dsonar.host.url=http://sonar.my.com:59000 -Dsonar.projectKey=my-projec -Dsonar.login=83cf76c9cc3d580d001e35d709636eaab64c4ed8
```

![image-apisix-dashboard](/images/posts/jacoco-in-maven-multi-module/sonar-overall-code.png)

## 排除

如果你想避免一些模块或者类参与到覆盖率统计中，你可以在根 pom.xml 使用 `<sonar.coverage.exclusions>` 要排除一些模块，例如


```xml
<properties>
  <sonar.coverage.exclusions>
    **/module-foo/**
  </sonar.coverage.exclusions>
</properties>
```	

