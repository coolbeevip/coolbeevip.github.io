---
title: "在 Maven 项目中使用 PMD Plugin 检查 Java 代码（Java源代码）质量"
date: 2022-09-18T13:24:14+08:00
tags: [java, pmd]
categories: [maven]
draft: false
---

本文记录了如何在 Maven 项目中使用 [Apache Maven PMD Plugin](https://maven.apache.org/plugins/maven-pmd-plugin/) 检查代码（Java 代码）质量

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

## 在根项目 pom.xml 中增加 `maven-pmd-plugin` 插件

增加 maven-pmd-plugin 插件

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
    <maven-pmd-plugin.version>3.19.0</maven-pmd-plugin.version>
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
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-pmd-plugin</artifactId>
          <version>${maven-pmd-plugin.version}</version>
          <configuration>
            <language>java</language>
            <rulesets>src/pmd/ruleset.xml</rulesets>
            <printFailingErrors>true</printFailingErrors>
            <linkXRef>false</linkXRef>
            <includeTests>true</includeTests>
          </configuration>
        </plugin>
      </plugins>
    </pluginManagement>

    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-pmd-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

增加 `src/pmd/ruleset.xml` 规则文件，这个文件中你可以指定[检查规则](https://github.com/pmd/pmd/tree/master/pmd-java/src/main/resources/category/java)，排除不需要检查的包。


```xml
<?xml version="1.0"?>
<ruleset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         name="ndcp-collector"
         xmlns="http://pmd.sourceforge.net/ruleset/2.0.0"
         xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 http://pmd.sourceforge.net/ruleset_2_0_0.xsd">

  <exclude-pattern>.*/jmh_generated/.*</exclude-pattern>

  <!-- security -->
  <rule ref="category/java/security.xml"/>

  <!-- best practices -->
  <rule ref="category/java/bestpractices.xml/AvoidPrintStackTrace"/>
  <rule ref="category/java/bestpractices.xml/MissingOverride"/>
  <rule ref="category/java/bestpractices.xml/UnusedFormalParameter"/>
  <rule ref="category/java/bestpractices.xml/UnusedLocalVariable"/>
  <rule ref="category/java/bestpractices.xml/UnusedPrivateField"/>
  <rule ref="category/java/bestpractices.xml/UseCollectionIsEmpty"/>
  <rule ref="category/java/bestpractices.xml/UseTryWithResources"/>

  <!-- codestyle -->
  <rule ref="category/java/codestyle.xml/AvoidProtectedMethodInFinalClassNotExtending"/>
  <rule ref="category/java/codestyle.xml/AvoidProtectedFieldInFinalClass"/>
  <rule ref="category/java/codestyle.xml/IdenticalCatchBranches"/>
  <rule ref="category/java/codestyle.xml/UnnecessaryConstructor"/>
  <rule ref="category/java/codestyle.xml/UnnecessaryCast"/>
  <rule ref="category/java/codestyle.xml/UnnecessaryLocalBeforeReturn"/>
  <rule ref="category/java/codestyle.xml/UnnecessaryModifier"/>
  <rule ref="category/java/codestyle.xml/UseDiamondOperator"/>

  <!-- design -->
  <rule ref="category/java/design.xml/SimplifyBooleanReturns"/>

  <!-- error prone -->
  <rule ref="category/java/errorprone.xml/ReturnEmptyArrayRatherThanNull"/>
  <rule ref="category/java/errorprone.xml/ReturnEmptyCollectionRatherThanNull"/>
  <rule ref="category/java/errorprone.xml/AvoidFieldNameMatchingTypeName"/>
  <rule ref="category/java/errorprone.xml/CloseResource"/>
  <rule ref="category/java/errorprone.xml/DoNotTerminateVM"/>

  <!-- multi threading -->
  <rule ref="category/java/multithreading.xml/NonThreadSafeSingleton"/>

  <!-- performance -->
  <rule ref="category/java/performance.xml/AppendCharacterWithChar"/>
  <rule ref="category/java/performance.xml/ConsecutiveAppendsShouldReuse"/>
  <rule ref="category/java/performance.xml/StringToString"/>
  <rule ref="category/java/performance.xml/UseIndexOfChar"/>
  <rule ref="category/java/performance.xml/UseStringBufferForStringAppends"/>
</ruleset>
```


## 命令行检查

你可以在 PR 的合并请求时使用以下命令，已确保代码合并前符合规则

```shell
mvn clean validate -DskipTests pmd:check
```

## IDE 工具

[Jetbrains IDEA PMD](https://plugins.jetbrains.com/plugin/1137-pmdplugin)