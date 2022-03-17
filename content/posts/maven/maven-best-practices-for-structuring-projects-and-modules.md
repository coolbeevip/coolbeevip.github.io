---
title: "Maven Projects Best Practices"
date: 2020-05-02T13:24:14+08:00
tags: [maven,java,project]
categories: [java]
draft: false
---

本文整理构建Maven项目和模块的最佳实践的关键事项，其中包含依赖、版本、属性、模块划分等关键因素，推荐使用 Maven 3.6.3 及以上版本。 为了便于理解，我们假设有一个 API
网关项目，这个网关项目包含服务端、客户端、通知服务端支持插件。

## 目标

* 通过多模块方式组织项目
* 管理项目版本、依赖，属性
* 规划模块依赖关系

### 主项目 POM

每个项目都应该在项目根目录下有一个主 POM 文件，并通过主 POM 文件管理下级子模块。在主 POM 中至少会使用一下标签

* properties: 定义字符集编码、JDK 版本、插件版本;
* modules: 下级子模块;
* pluginRepositories: 插件仓库地址（非必须，主要解决国内访问慢的问题）;
* repositories: 定义 Maven 私服地址;
* distributionManagement: 定义发布用 Maven 私服地址
* pluginManagement: 定义管理类插件版本

例如：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<build xmlns="http://maven.apache.org/POM/4.0.0"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>

  <groupId>com.coolbeevip.apigateway</groupId>
  <artifactId>apigateway-parent</artifactId>
  <version>${revision}</version>
  <packaging>pom</packaging>

  <properties>
    <!-- 使用 revision 管理项目版本 -->
    <revision>1.0.0-SNAPSHOT</revision>

    <!-- project -->
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    <maven.compiler.encoding>UTF-8</maven.compiler.encoding>
    <maven.compiler.source>8</maven.compiler.source>
    <maven.compiler.target>8</maven.compiler.target>

    <!-- plugins version -->
    <maven-compiler-plugin.version>3.1</maven-compiler-plugin.version>
    <jacoco-maven-plugin.version>0.8.6</jacoco-maven-plugin.version>
    <docker-maven-plugin.version>0.34.1</docker-maven-plugin.version>
    <maven-deploy-plugin.version>2.7</maven-deploy-plugin.version>
    <maven-surefire-plugin.version>3.0.0-M5</maven-surefire-plugin.version>
    <sonar-maven-plugin.version>3.8.0.2131</sonar-maven-plugin.version>
    <dependency-check-maven.version>6.5.3</dependency-check-maven.version>

    <!-- sonar plugin -->
    <sonar.host.url>http://private.sonar:59000</sonar.host.url>

    <!-- maven deploy -->
    <distribution.url>private.nexus:8099</distribution.url>
    <distribution.username/>
    <distribution.password/>
  </properties>

  <!-- 下级子模块（后续会将到子模块的划分原则）-->
  <modules>
    <module>apigateway-dependencies</module>
    <module>apigateway-common</module>
    <module>apigateway-server-common</module>
    <module>apigateway-server</module>
    <module>apigateway-server-plugins</module>
    <module>apigateway-client</module>
  </modules>

  <!-- 插件下载仓库 -->
  <pluginRepositories>
    <!-- 国内使用阿里云可能快点 -->
    <pluginRepository>
      <id>aliyun</id>
      <url>https://maven.aliyun.com/repository/public</url>
      <releases>
        <enabled>true</enabled>
      </releases>
      <snapshots>
        <enabled>false</enabled>
      </snapshots>
    </pluginRepository>
  </pluginRepositories>

  <!-- 下载依赖的私有仓库 -->
  <repositories>
    <!-- 国内使用阿里云可能快点 -->
    <repository>
      <id>aliyun</id>
      <name>aliyun</name>
      <url>http://maven.aliyun.com/nexus/content/groups/public</url>
    </repository>
    <repository>
      <id>releases</id>
      <name>releases</name>
      <url>http://${distribution.url}/nexus/repository/releases/</url>
      <releases>
        <enabled>true</enabled>
      </releases>
      <snapshots>
        <enabled>false</enabled>
      </snapshots>
    </repository>
    <repository>
      <id>snapshots</id>
      <name>Snapshots</name>
      <url>http://${distribution.url}/nexus/repository/snapshots/</url>
      <releases>
        <enabled>true</enabled>
      </releases>
      <snapshots>
        <enabled>true</enabled>
        <updatePolicy>always</updatePolicy>
      </snapshots>
    </repository>
  </repositories>

  <!-- 发布用私有仓库地址 -->
  <distributionManagement>
    <repository>
      <id>releases</id>
      <name>Release Repository</name>
      <url>
        http://${distribution.username}:${distribution.password}@${distribution.url}/nexus/repository/releases/
      </url>
    </repository>
    <snapshotRepository>
      <id>snapshots</id>
      <name>Snapshot Repository</name>
      <url>
        http://${distribution.username}:${distribution.password}@${distribution.url}/nexus/repository/snapshots/
      </url>
    </snapshotRepository>
  </distributionManagement>

  <!-- 项目管理类插件版本管理（根据自身情况自选） -->
  <build>
    <pluginManagement>
      <plugins>
        <!-- Java 编译插件 -->
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-compiler-plugin</artifactId>
          <version>${maven-compiler-plugin.version}</version>
          <configuration>
            <compilerArgument>-Xlint:unchecked</compilerArgument>
          </configuration>
        </plugin>
        <!-- Docker 发布插件 -->
        <plugin>
          <groupId>io.fabric8</groupId>
          <artifactId>docker-maven-plugin</artifactId>
          <version>${docker-maven-plugin.version}</version>
        </plugin>
        <!-- Maven 发布插件 -->
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-deploy-plugin</artifactId>
          <version>${maven-deploy-plugin.version}</version>
        </plugin>
        <!-- 执行测试用例插件 -->
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-surefire-plugin</artifactId>
          <version>${maven-surefire-plugin.version}</version>
        </plugin>
        <!-- 代码覆盖率插件 -->
        <plugin>
          <groupId>org.jacoco</groupId>
          <artifactId>jacoco-maven-plugin</artifactId>
          <version>${jacoco-maven-plugin.version}</version>
        </plugin>
        <!-- 代码质量管理插件 -->
        <plugin>
          <groupId>org.sonarsource.scanner.maven</groupId>
          <artifactId>sonar-maven-plugin</artifactId>
          <version>${sonar-maven-plugin.version}</version>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>

  <profiles>
    <profile>
      <!-- 缺陷检查插件 ./mvnw org.owasp:dependency-check-maven:aggregate -->
      <id>owasp</id>
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
              <failBuildOnAnyVulnerability>false</failBuildOnAnyVulnerability>
              <failOnError>false</failOnError>
              <skipProvidedScope>true</skipProvidedScope>
              <skipRuntimeScope>true</skipRuntimeScope>
              <skipTestScope>true</skipTestScope>
              <skipDependencyManagement>true</skipDependencyManagement>
              <retireJsAnalyzerEnabled>false</retireJsAnalyzerEnabled>              
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
    </profile>
  </profiles>  
</project>
```

### 使用 Maven Wrapper 安装和管理 Maven 版本

为了降低参与难度，建议在项目中使用 [Maven Wrapper](https://github.com/takari/takari-maven-plugin) 方式管理 Maven，这样参与者使用 `mvnw` 命令代替 `mvn`
命令执行时，会自动下载安装 Maven. 同样，您也可以看到我将镜像仓库地址也写到了主 pom 文件中，这也是为了避免参与者去手动修改本地 Maven 的 `settings.xml` 文件，从而降低参与的难度。

### 子模块 POM

通常我们为了解耦一个项目，通常会采用多模块的方式按照子系统垂直拆分模块，或则按照基础设施水平拆分模块，总之拆分模块是必须的，拆分的合理性和粒度也决定了开发者的参与门槛。

根据我们这个想象的项目，我们可以按如下方式拆子模块.

```xml

<modules>
  <!-- 依赖版本管理、公共参数管理 -->
  <module>apigateway-dependencies</module>
  <!-- 网关的公共代码 -->
  <module>apigateway-common</module>
  <!-- 网关服务的公共代码 -->
  <module>apigateway-server-common</module>
  <!-- 网关服务本身 -->
  <module>apigateway-server</module>
  <!-- 网关服务插件 -->
  <module>apigateway-server-plugins</module>
  <!-- 网关客户端服 -->
  <module>apigateway-client</module>
</modules>
```

* 服务端模块 `pigateway-server`，包含 `apigateway-dependencies`，`apigateway-server-common`，`apigateway-server-plugins` 模块;
* 客户端模块 `apigateway-client` 包含 `apigateway-dependencies`，`apigateway-common` 模块;
* 插件模块 `apigateway-server-plugins` 包含 `apigateway-dependencies`，`apigateway-server-common` 模块;

子模块的 POM 要继承上级 POM

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>com.coolbeevip.apigateway</groupId>
    <artifactId>apigateway-parent</artifactId>
    <version>${revision}</version>
  </parent>
  <artifactId>apigateway-server</artifactId>

</project>
```

* 子模块只能继承本系统的模块（只有这样参数才能继承，避免重复定义）
* 子模块中不要单独定义版本号

### 依赖定义子模块

通常在项目中必须有一个地方几种定义依赖的版本，承担这个功能的模块一般是主 pom 或者一个单独的子模块，例如 `apigateway-dependencies`. 在这个模块里通常会用到以下定义

* properties
* dependencyManagement
* pluginManagement

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>com.coolbeevip.apigateway</groupId>
    <artifactId>apigateway-parent</artifactId>
    <version>${revision}</version>
  </parent>
  <artifactId>apigateway-dependencies</artifactId>

  <properties>
    <!-- 定义版本号 -->
    <h2.version>1.4.200</h2.version>
    <dom4j.version>2.1.3</dom4j.version>
    <commons-httpclient.version>3.0</commons-httpclient.version>
  </properties>

  <dependencyManagement>
    <dependencies>
      <!-- 管理依赖版本 -->
      <dependency>
        <groupId>com.h2database</groupId>
        <artifactId>h2</artifactId>
        <version>${h2.version}</version>
      </dependency>
      <dependency>
        <groupId>org.dom4j</groupId>
        <artifactId>dom4j</artifactId>
        <version>${dom4j.version}</version>
      </dependency>
      <dependency>
        <groupId>commons-httpclient</groupId>
        <artifactId>commons-httpclient</artifactId>
        <version>${commons-httpclient.version}</version>
      </dependency>      
    </dependencies>
  </dependencyManagement>

  <build>
    <pluginManagement>
      <plugins>
        <!-- Docker 发布的插件配置 -->
        <plugin>
          <groupId>io.fabric8</groupId>
          <artifactId>docker-maven-plugin</artifactId>
          <configuration>
            <skip>true</skip>
            <dockerHost>${docker.host}</dockerHost>
            <registry>${docker.registry}</registry>
            <authConfig>
              <push>
                <username>${docker.username}</username>
                <password>${docker.password}</password>
              </push>
            </authConfig>
            <images>
              <image>
                <name>${docker.registry}/${docker.namespace}/${project.name}:%v</name>
                <build>
                  <dockerFile>${project.basedir}/Dockerfile</dockerFile>
                </build>
              </image>
              <image>
                <name>${docker.registry}/${docker.namespace}/${project.name}:latest</name>
                <build>
                  <dockerFile>${project.basedir}/Dockerfile</dockerFile>
                </build>
              </image>
            </images>
          </configuration>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
</project>
```
