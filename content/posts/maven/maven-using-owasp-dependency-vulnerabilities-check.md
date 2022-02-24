---
title: "Using OWASP Dependency Vulnerabilities Check with Maven"
date: 2022-02-24T13:24:14+08:00
tags: [maven,vulnerabilities,owasp]
categories: [java]
draft: false
---

使用 [OWASP](https://owasp.org/www-project-dependency-check/) 依赖检查 Maven 插件 [dependency-check-maven](https://jeremylong.github.io/DependencyCheck/dependency-check-maven/index.html) 发现依赖漏洞

## 增加编译插件

在 pom.xml 中增加如下配置，如果是多模块项目请增加在最外层 pom.xml 中，并且配置 `<goal>` 为 `aggregate`

```xml
<properties>
  <dependency-check-maven.version>6.5.3</dependency-check-maven.version>
</properties>  

<build>
  <plugins>
    <plugin>
      <groupId>org.owasp</groupId>
      <artifactId>dependency-check-maven</artifactId>
      <version>${dependency-check-maven.version}</version>
      <configuration>
        <name>notifier-dependency-check</name>
        <format>HTML</format>
        <failBuildOnCVSS>9</failBuildOnCVSS>
        <failOnError>false</failOnError>
        <skipProvidedScope>true</skipProvidedScope>
        <skipRuntimeScope>true</skipRuntimeScope>
        <skipTestScope>true</skipTestScope>
        <skipArtifactType>pom</skipArtifactType>
      </configuration>
      <executions>
        <execution>
          <goals>
            <goal>aggregate</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

* failBuildOnCVSS 当发现此级别的漏洞后编译失败，评分和严重等级如下
  * 0.0	None
  * 0.1 – 3.9	Low
  * 4.0 – 6.9	Medium
  * 7.0 – 8.9	High
  * 9.0 – 10.0	Critical

## 执行插件命令

```shell
./mvnw org.owasp:dependency-check-maven:aggregate
```

## 插件日志记录

执行完毕后，如果还有漏洞评分大于 `9` 的依赖，则会看到如下信息

```shell
[ERROR] Failed to execute goal org.owasp:dependency-check-maven:6.5.3:aggregate (default-cli) on project nc-notifier:
[ERROR]
[ERROR] One or more dependencies were identified with vulnerabilities that have a CVSS score greater than or equal to '9.0':
[ERROR]
[ERROR] apache-mime4j-core-0.7.2.jar: CVE-2021-40525
[ERROR] fastjson-1.2.58.jar: CWE-502: Deserialization of Untrusted Data
[ERROR] nacos-api-1.2.1.jar: CVE-2021-29441
[ERROR] spring-cloud-starter-oauth2-2.2.5.RELEASE.jar: CVE-2021-22112
[ERROR] spring-cloud-starter-security-2.2.5.RELEASE.jar: CVE-2021-22112
[ERROR]
[ERROR] See the dependency-check report for more details.
```

## 查看漏洞 HTML 报告

你可以找到漏洞报告 target/dependency-check-report.html，用浏览器打开这个报告可以看到汇总信息以及每个依赖的详细信息