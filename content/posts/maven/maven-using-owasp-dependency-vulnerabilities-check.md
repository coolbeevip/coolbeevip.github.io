---
title: "Using OWASP Dependency Vulnerabilities Check with Maven"
date: 2022-02-24T13:24:14+08:00
tags: [maven,vulnerabilities,owasp]
categories: [java]
draft: false
---

使用 [OWASP](https://owasp.org/www-project-dependency-check/) 依赖检查 Maven 插件 [dependency-check-maven](https://jeremylong.github.io/DependencyCheck/dependency-check-maven/index.html) 发现依赖漏洞

## 增加编译插件

```xml
<properties>
  <dependency-check-maven.version>6.5.3</dependency-check-maven.version>
</properties>  

<plugins>
  <plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <version>${dependency-check-maven.version}</version>
    <configuration>
      <name>notifier-dependency-check</name>
      <format>HTML</format>
      <failBuildOnCVSS>8</failBuildOnCVSS>
      <failBuildOnAnyVulnerability>false</failBuildOnAnyVulnerability>
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

## 执行插件命令

```shell
./mvnw org.owasp:dependency-check-maven:aggregate -DskipTests
```

## 插件日志记录

```shell
[ERROR] Failed to execute goal org.owasp:dependency-check-maven:6.5.3:aggregate (default-cli) on project nc-notifier:
[ERROR]
[ERROR] One or more dependencies were identified with vulnerabilities that have a CVSS score greater than or equal to '8.0':
[ERROR]
[ERROR] apache-mime4j-core-0.7.2.jar: CVE-2021-40525
[ERROR] fastjson-1.2.58.jar: CWE-502: Deserialization of Untrusted Data
[ERROR] logback-core-1.2.3.jar: CVE-2021-42550
[ERROR] mybatis-plus-core-3.3.2.jar: CVE-2020-26945
[ERROR] nacos-api-1.2.1.jar: CVE-2021-29441
[ERROR] spring-cloud-netflix-ribbon-2.2.2.RELEASE.jar: CVE-2021-22053
[ERROR] spring-cloud-netflix-ribbon-2.2.9.RELEASE.jar: CVE-2021-22053
[ERROR] spring-cloud-starter-oauth2-2.2.5.RELEASE.jar: CVE-2018-1258, CVE-2021-22112
[ERROR] spring-cloud-starter-security-2.2.5.RELEASE.jar: CVE-2018-1258, CVE-2021-22112
[ERROR]
[ERROR] See the dependency-check report for more details.
```

## 查看漏洞 HTML 报告

你可以找到报告汇总文件 target/dependency-check-report.html
