---
title: "Bash script automates the Maven project Git release process"
date: 2021-05-16T13:24:14+08:00
tags: [git,maven,java,release]
categories: [git]
draft: false
---

开源项目中我们大多采用主干开发模式管理我们的项目，他基本遵循以下规则

* 所有的 PR 都默认向主干合并
* 主干上项目的版本号是 -SNAPSHOT
* 当主干要发布时，我们会建立与之对应的 X 分支（此分支的目的是为了基于此分支发布补丁版本）
* 基于当前主干去除版本号中的 -SNAPSHOT 后建立与版本对应的 TAG
* 将主干上的版本号中的 minor 累加一，并在后边增加 -SNAPSHOT 后缀  

此过程繁琐，切容易出错。我制作了一个脚本 [maven-project-git-release.sh](https://gist.github.com/coolbeevip/e2021c07c44566653d6601f68cccc8a1) 用来实现这个过程的规范化和自动化

当然，这并不意味着你不需要掌握正手动发布的过程。

由于某种原因导致自动过程中断后，你依然需要手动去处理，**所以在使用这个脚本前，请确保你了解这个脚本帮你做了什么工作，以及如何做的**。

## 如何使用

maven-project-git-release.sh 脚本会帮你自动化以下工作

* 创建一个编译用的目录
  
    目录会创建在你系统的临时目录下，在我的 Mac 系统系统中看起来像 /var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T
  
* 在编译用的目录中 git clone 你的仓库代码
  
    你的仓库地址在使用脚本时通过参数指定，像这样 `sh maven-project-git-release.sh git@github.com:coolbeevip/license-maven-plugin.git`  

* 编译你的代码确保正确
  
  默认在当前仓库根目录下执行 `mvn clean package`，如果你需要特殊的方式，可以修改脚本中的 check_source_before_release 函数
  
* 计算版本号分支名
  
  根据 pom 中的版本定义，自动计算下一版本号，默认采 maven 的3段式版号方式 `major.minor.patch`，并以此为基准滚动 minor 版本号，如果你需要特殊的方式，可以修改脚本中的 next_version 函数
  
* 输出发布计划
  
  发布计划中会显示你要发布的仓库地址，当前版本号、维护用 X 分支、TAG 名称、下一个版本号等信息
  
  ```text
  Release Plan:
  ====================================================================
  GIT_REPO_URL: git@github.com:coolbeevip/license-maven-plugin.git
  RELEASE WORK DIR: /var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.IC6Y8ZhQ
  CURRENT VERSION: 1.6.0-SNAPSHOT
  MAINTENANCE BRANCH NAME: 1.6.X
  TAG NAME: v1.6.0
  RELEASE VERSION: 1.6.0
  NEXT VERSION: 1.6.1-SNAPSHOT
  ====================================================================
  Pre-release branch and TAG check...OK
  Are you release？(Y/N)
  ```
  
* 开始发布
  
  当你确认后，将自动创建分支、TAG 并修改主干的版本号。在发布过程中涉及到修改 pom 文件中的版本号，默认采用 versions:set 的方式，你可以通过修改脚本中的 modify_maven_project_version 函数修改这个默认行为

## 执行样例

我自己写的 Maven 项目依赖 Licnese 分析插件 [license-maven-plugin](https://coolbeevip.github.io/posts/maven-export-dependencies-analyse-license/) 仓库也是使用这种方式发布，执行过程如下：

```shell
$ sh maven-project-git-release.sh git@github.com:coolbeevip/license-maven-plugin.git
Initialize work directory
release home: /var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot

Download Repository
Cloning into 'license-maven-plugin'...
remote: Enumerating objects: 493, done.
remote: Counting objects: 100% (493/493), done.
remote: Compressing objects: 100% (234/234), done.
remote: Total 493 (delta 191), reused 418 (delta 119), pack-reused 0
Receiving objects: 100% (493/493), 138.38 KiB | 268.00 KiB/s, done.
Resolving deltas: 100% (191/191), done.

Build & Test
[INFO] Scanning for projects...
[WARNING]
[WARNING] Some problems were encountered while building the effective model for io.github.coolbeevip:license-maven-plugin:maven-plugin:1.6.0-SNAPSHOT
[WARNING] 'build.plugins.plugin.version' for org.apache.maven.plugins:maven-surefire-plugin is missing. @ line 141, column 15
[WARNING]
[WARNING] It is highly recommended to fix these problems because they threaten the stability of your build.
[WARNING]
[WARNING] For this reason, future Maven versions might no longer support building such malformed projects.
[WARNING]
[INFO]
[INFO] -------------< io.github.coolbeevip:license-maven-plugin >--------------
[INFO] Building license-maven-plugin 1.6.0-SNAPSHOT
[INFO] ----------------------------[ maven-plugin ]----------------------------
[INFO]
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ license-maven-plugin ---
[INFO]
[INFO] --- maven-enforcer-plugin:1.2:enforce (enforce-maven) @ license-maven-plugin ---
[INFO]
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ license-maven-plugin ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/src/main/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.1:compile (default-compile) @ license-maven-plugin ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 9 source files to /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/target/classes
[WARNING] /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/src/main/java/io/github/coolbeevip/AggregateLicenseExportMojo.java: /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/src/main/java/io/github/coolbeevip/AggregateLicenseExportMojo.java使用了未经检查或不安全的操作。
[WARNING] /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/src/main/java/io/github/coolbeevip/AggregateLicenseExportMojo.java: 有关详细信息, 请使用 -Xlint:unchecked 重新编译。
[INFO]
[INFO] --- maven-plugin-plugin:3.6.0:descriptor (default-descriptor) @ license-maven-plugin ---
[INFO] Using 'UTF-8' encoding to read mojo source files.
[INFO] java-javadoc mojo extractor found 0 mojo descriptor.
[INFO] java-annotations mojo extractor found 1 mojo descriptor.
[INFO]
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ license-maven-plugin ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.1:testCompile (default-testCompile) @ license-maven-plugin ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/target/test-classes
[INFO]
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ license-maven-plugin ---
[INFO] Tests are skipped.
[INFO]
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ license-maven-plugin ---
[INFO] Building jar: /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/target/license-maven-plugin-1.6.0-SNAPSHOT.jar
[INFO]
[INFO] --- maven-plugin-plugin:3.6.0:addPluginArtifactMetadata (default-addPluginArtifactMetadata) @ license-maven-plugin ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.837 s
[INFO] Finished at: 2021-05-17T01:17:56+08:00
[INFO] ------------------------------------------------------------------------

Release Plan:
====================================================================
GIT_REPO_URL: git@github.com:coolbeevip/license-maven-plugin.git
RELEASE WORK DIR: /var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot
CURRENT VERSION: 1.6.0-SNAPSHOT
MAINTENANCE BRANCH NAME: 1.6.X
TAG NAME: v1.6.0
RELEASE VERSION: 1.6.0
NEXT VERSION: 1.7.0-SNAPSHOT
====================================================================

Pre-release branch and TAG check...OK
Are you release？(Y/N): y
Pre-release branch and TAG check...OK
Create branch 1.6.X
Switched to a new branch '1.6.X'
Total 0 (delta 0), reused 0 (delta 0)
remote:
remote: Create a pull request for '1.6.X' on GitHub by visiting:
remote:      https://github.com/coolbeevip/license-maven-plugin/pull/new/1.6.X
remote:
To github.com:coolbeevip/license-maven-plugin.git
 * [new branch]      1.6.X -> 1.6.X
Create tag 1.6.0
Switched to branch 'master'
Your branch is up to date with 'origin/master'.
[INFO] Scanning for projects...
[WARNING]
[WARNING] Some problems were encountered while building the effective model for io.github.coolbeevip:license-maven-plugin:maven-plugin:1.6.0-SNAPSHOT
[WARNING] 'build.plugins.plugin.version' for org.apache.maven.plugins:maven-surefire-plugin is missing. @ line 141, column 15
[WARNING]
[WARNING] It is highly recommended to fix these problems because they threaten the stability of your build.
[WARNING]
[WARNING] For this reason, future Maven versions might no longer support building such malformed projects.
[WARNING]
[INFO]
[INFO] -------------< io.github.coolbeevip:license-maven-plugin >--------------
[INFO] Building license-maven-plugin 1.6.0-SNAPSHOT
[INFO] ----------------------------[ maven-plugin ]----------------------------
[INFO]
[INFO] --- versions-maven-plugin:2.8.1:set (default-cli) @ license-maven-plugin ---
[INFO] Local aggregation root: /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin
[INFO] Processing change of io.github.coolbeevip:license-maven-plugin:1.6.0-SNAPSHOT -> 1.6.0
[INFO] Processing io.github.coolbeevip:license-maven-plugin
[INFO]     Updating project io.github.coolbeevip:license-maven-plugin
[INFO]         from version 1.6.0-SNAPSHOT to 1.6.0
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.204 s
[INFO] Finished at: 2021-05-17T01:18:12+08:00
[INFO] ------------------------------------------------------------------------
[INFO] Scanning for projects...
[WARNING]
[WARNING] Some problems were encountered while building the effective model for io.github.coolbeevip:license-maven-plugin:maven-plugin:1.6.0
[WARNING] 'build.plugins.plugin.version' for org.apache.maven.plugins:maven-surefire-plugin is missing. @ line 141, column 15
[WARNING]
[WARNING] It is highly recommended to fix these problems because they threaten the stability of your build.
[WARNING]
[WARNING] For this reason, future Maven versions might no longer support building such malformed projects.
[WARNING]
[INFO]
[INFO] -------------< io.github.coolbeevip:license-maven-plugin >--------------
[INFO] Building license-maven-plugin 1.6.0
[INFO] ----------------------------[ maven-plugin ]----------------------------
[INFO]
[INFO] --- versions-maven-plugin:2.8.1:commit (default-cli) @ license-maven-plugin ---
[INFO] Accepting all changes to /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/pom.xml
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.891 s
[INFO] Finished at: 2021-05-17T01:18:13+08:00
[INFO] ------------------------------------------------------------------------
[master 2806e60] Upgrade Version to v1.6.0
 1 file changed, 1 insertion(+), 1 deletion(-)
Enumerating objects: 6, done.
Counting objects: 100% (6/6), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 435 bytes | 435.00 KiB/s, done.
Total 4 (delta 2), reused 0 (delta 0)
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To github.com:coolbeevip/license-maven-plugin.git
 * [new tag]         v1.6.0 -> v1.6.0
Update branch master version to 1.7.0-SNAPSHOT
[INFO] Scanning for projects...
[WARNING]
[WARNING] Some problems were encountered while building the effective model for io.github.coolbeevip:license-maven-plugin:maven-plugin:1.6.0
[WARNING] 'build.plugins.plugin.version' for org.apache.maven.plugins:maven-surefire-plugin is missing. @ line 141, column 15
[WARNING]
[WARNING] It is highly recommended to fix these problems because they threaten the stability of your build.
[WARNING]
[WARNING] For this reason, future Maven versions might no longer support building such malformed projects.
[WARNING]
[INFO]
[INFO] -------------< io.github.coolbeevip:license-maven-plugin >--------------
[INFO] Building license-maven-plugin 1.6.0
[INFO] ----------------------------[ maven-plugin ]----------------------------
[INFO]
[INFO] --- versions-maven-plugin:2.8.1:set (default-cli) @ license-maven-plugin ---
[INFO] Local aggregation root: /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin
[INFO] Processing change of io.github.coolbeevip:license-maven-plugin:1.6.0 -> 1.7.0-SNAPSHOT
[INFO] Processing io.github.coolbeevip:license-maven-plugin
[INFO]     Updating project io.github.coolbeevip:license-maven-plugin
[INFO]         from version 1.6.0 to 1.7.0-SNAPSHOT
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.023 s
[INFO] Finished at: 2021-05-17T01:18:22+08:00
[INFO] ------------------------------------------------------------------------
[INFO] Scanning for projects...
[WARNING]
[WARNING] Some problems were encountered while building the effective model for io.github.coolbeevip:license-maven-plugin:maven-plugin:1.7.0-SNAPSHOT
[WARNING] 'build.plugins.plugin.version' for org.apache.maven.plugins:maven-surefire-plugin is missing. @ line 141, column 15
[WARNING]
[WARNING] It is highly recommended to fix these problems because they threaten the stability of your build.
[WARNING]
[WARNING] For this reason, future Maven versions might no longer support building such malformed projects.
[WARNING]
[INFO]
[INFO] -------------< io.github.coolbeevip:license-maven-plugin >--------------
[INFO] Building license-maven-plugin 1.7.0-SNAPSHOT
[INFO] ----------------------------[ maven-plugin ]----------------------------
[INFO]
[INFO] --- versions-maven-plugin:2.8.1:commit (default-cli) @ license-maven-plugin ---
[INFO] Accepting all changes to /private/var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.0tv43eot/license-maven-plugin/pom.xml
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.928 s
[INFO] Finished at: 2021-05-17T01:18:24+08:00
[INFO] ------------------------------------------------------------------------
[master 2c2af24] Upgrade Release Version 1.7.0-SNAPSHOT
 1 file changed, 1 insertion(+), 1 deletion(-)
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 331 bytes | 331.00 KiB/s, done.
Total 3 (delta 2), reused 0 (delta 0)
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To github.com:coolbeevip/license-maven-plugin.git
   5a31260..2c2af24  master -> master
The release is successful, Please check branch & tag & master in the git repository
(base) bogon:git-automate-tag-release-process-with-bash zhanglei$
```