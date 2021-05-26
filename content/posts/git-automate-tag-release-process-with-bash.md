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
  OS: Darwin
  GIT_REPO_URL: git@github.com:coolbeevip/license-maven-plugin.git
  RELEASE WORK DIR: /var/folders/fd/gqdh88px2fj66tmtcy6ffr580000gn/T/release-license-maven-plugin.EkWqLOOW
  CURRENT VERSION: 1.11.0-SNAPSHOT
  MAINTENANCE BRANCH NAME: 1.11.X
  TAG NAME: v1.11.0
  RELEASE VERSION: 1.11.0
  NEXT VERSION: 1.12.0-SNAPSHOT
  ====================================================================
  STEP1: Create maintenance branch 1.11.X
  git checkout -b 1.11.X
  git push origin 1.11.X
  --------------------------------------------------------------------
  STEP2: Create release Tag 1.11.0
  git checkout master
  mvn versions:set -DnewVersion=1.11.0
  mvn versions:commit
  git commit -a -m 'Upgrade Version to v1.11.0'
  git tag -a v1.11.0 -m 'Release v1.11.0'
  git push origin v1.11.0
  --------------------------------------------------------------------
  STEP3: Update branch master version to 1.12.0-SNAPSHOT
  mvn versions:set -DnewVersion=1.12.0-SNAPSHOT
  mvn versions:commit
  git commit -a -m 'Upgrade Release Version 1.12.0-SNAPSHOT'
  git push origin master
  --------------------------------------------------------------------
  STEP4: The 1.11.0 release is successful
  STEP5: Please check branch 1.11.X exist in the git repository
  STEP6: Please check release tag v1.11.0 exist in the git repository
  STEP7: Please check master version changed to 1.12.0-SNAPSHOT in the git repository
  ====================================================================

  Pre-release branch and TAG check...OK
  Are you release？(Y/N):  
  ```
  
* 开始发布
  
  当你确认后，将自动创建分支、TAG 并修改主干的版本号。在发布过程中涉及到修改 pom 文件中的版本号，默认采用 versions:set 的方式，你可以通过修改脚本中的 modify_maven_project_version 函数修改这个默认行为