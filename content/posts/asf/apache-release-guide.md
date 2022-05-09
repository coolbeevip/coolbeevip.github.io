---
title: "Apache Servicecomb Pack Release Guide"
date: 2022-05-08T01:00:00+08:00
tags: [release]
categories: [ASF]
draft: false
---

**注意:** 本文档基于 `0.7.0` 正式版发布过程编写，实际操作时请替换文档中的版本号 `0.7.0-SNAPSHOT` 和 `0.7.0` 为实际的版本号。

**注意：** 开始发布前，请提前一周通过 `dev@servicecomb.apache.org` 预告即将开始发布，确认代码是否已经准备就绪。

```shell
Hello All,

Since from last ServiceComb pack 0.6.0 release we have done significant changes so now is the time to release the new version 0.7.0.

I will be cutting a new release tomorrow morning from the branch https://github.com/apache/servicecomb-pack/tree/0.7.x .

@PMC/@Committers please let me know if there is any important patch we need to merge before this release.

Regards
```

**注意:** 发布流程中的 **PMC投票** 环节通常需要 3 天，并且在没有任何 PMC 投反对票后才能正式发布，因此请提前计划发布活动。

## 发布环境准备

#### 生成签名密钥

1. 安装 GPG

在[GnuPG官网](https://www.gnupg.org/download/index.html)下载 2.X 安装包. 安装完毕后可以使用如下命令查看版本

```shell
$ gpg --version
gpg (GnuPG/MacGPG2) 2.2.20
libgcrypt 1.8.5
Copyright (C) 2020 Free Software Foundation, Inc.
```

2. 配置 GPG

安装完毕后你可以找到 `$HOME/.gnupg/gpg.conf` 文件，并增加如下[推荐配置](https://infra.apache.org/openpgp.html#sha-defaults)

```properties
personal-digest-preferences SHA512
cert-digest-algo SHA512
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
```

3. 用 GPG 生成密钥

根据提示使用 Apache 邮箱生成 GPG 的密钥，更多详细说明请参考[Generaate Key with OPENGPG](https://infra.apache.org/openpgp.html#generate-key)

```shell
$ gpg --full-gen-key
gpg (GnuPG/MacGPG2) 2.2.20; Copyright (C) 2020 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

请选择您要使用的密钥类型：
   (1) RSA 和 RSA （默认）
   (2) DSA 和 Elgamal
   (3) DSA（仅用于签名）
   (4) RSA（仅用于签名）
  (14) Existing key from card
您的选择是？ 1
RSA 密钥的长度应在 1024 位与 4096 位之间。
您想要使用的密钥长度？(2048) 4096
请求的密钥长度是 4096 位
请设定这个密钥的有效期限。
         0 = 密钥永不过期
      <n>  = 密钥在 n 天后过期
      <n>w = 密钥在 n 周后过期
      <n>m = 密钥在 n 月后过期
      <n>y = 密钥在 n 年后过期
密钥的有效期限是？(0)
密钥永远不会过期
这些内容正确吗？ (y/N) y

GnuPG 需要构建用户标识以辨认您的密钥。

真实姓名： Lei Zhang
电子邮件地址： zhanglei@apache.org
注释： CODE SIGNING KEY
您选定了此用户标识：
    “Lei Zhang (CODE SIGNING KEY) zhanglei@apache.org”

更改姓名（N）、注释（C）、电子邮件地址（E）或确定（O）/退出（Q）？ O
```

输入确定 `O` 会车后根据提示输入 **【密钥密码】** 后完成操作。请保存这个密钥密码，以后会经常使用。

4. 查看密钥ID

你可以使用如下命令查看生成的密钥，请保存 **【密钥ID】**。

```shell
$ gpg --list-keys
pub   rsa4096 2022-05-05 [SC]
      <密钥ID>
uid           [ 绝对 ] Lei Zhang (CODE SIGNING KEY) zhanglei@apache.org
sub   rsa4096 2022-05-05 [E]
```

5. 发布公钥到 keyserver

使用 **【密钥ID】** 将公钥发布到 `pgpkeys.mit.edu`，发布后稍等一会就会自动同步到其他 keyserver

```shell
gpg --keyserver pgpkeys.mit.edu --send-key <密钥ID>
```

使用如下命令验证公钥是否发布成功（因为发布后后台需要同步，所以可能需要多试几次）

```shell
gpg --keyserver hkp://pgpkeys.mit.edu --recv-keys <密钥ID>
```

如果你看到如下信息，说明已经发布成功

```shell
gpg: <密钥ID>：“Lei Zhang (CODE SIGNING KEY) <zhanglei@apache.org>” 未改变
gpg: 处理的总数：1
gpg:              未改变：1
```

6. 发布公钥指纹到 Apache 用户信息中（不是发布流程的必须环节）

使用以下命令生成公钥匙指纹，登录 https://id.apache.org, 将下面指纹(CA24 2F7D E725 DFB5 A8E4  4649 2B33 8CEB 8A38 1CFF) 粘贴到自己的用户信息中 OpenPGP Public Key Primary Fingerprint 中。

```shell
$ gpg --fingerprint Lei Zhang
pub   rsa4096 2022-05-05 [SC]
      CA24 2F7D E725 DFB5 A8E4  4649 2B33 8CEB 8A38 1CFF
uid           [ 绝对 ] Lei Zhang (CODE SIGNING KEY) <zhanglei@apache.org>
sub   rsa4096 2022-05-05 [E]
```

7. 备份公钥和私钥（不是发布流程的必须环节）

你可以使用以下方式备份密钥，以便在其他机器上恢复

导出公钥

```shell
gpg -a -o public-file.key --export <密钥ID>
```

导出私钥(需要生成密钥时的密码)

```shell
gpg -a -o private-file.key --export-secret-keys <密钥ID>
```

#### Apache Maven 认证配置

在发布前我们需要配置 Apache Maven 仓库的服务器地址、账号和密码。为了安全我们使用 [Password Encryption](https://maven.apache.org/guides/mini/guide-encryption.html) 对 Apache LDAP 密码加密

1. 创建一个主密码

使用如下命令创建一个 **【主密码】**

```shell
$ mvn --encrypt-master-password <主密码>
```

在 ~/.m2/settings-security.xml 文件中存储主密码

```xml
<settingsSecurity>
  <master><!-- 主密码 --></master>
</settingsSecurity>
```

2. 加密你的 Apache LDAP 密码

```shell
$ mvn --encrypt-password <Apache LDAP 密码>
```

3. 加密你的密钥密码

```shell
$ mvn --encrypt-password <密钥密码>
```

4. 在 `~/.m2/settings.xml` 文件中配置发布服务器地址和配置加密后的密码

```xml
<settings>
  <servers>
    <server>
      <id>apache.snapshots.https</id>
      <username>zhanglei</username>
      <password><!-- 加密后的 Apache LDAP 密码 --></password>
    </server>
    <server>
      <id>apache.releases.https</id>
      <username>zhanglei</username>
      <password><!-- 加密后的 Apache LDAP 密码 --></password>
    </server>
     <server>
      <id>gpg.passphrase</id>
      <passphrase><!-- 加密后的密钥密码 --></passphrase>
    </server>
  </servers>
</settings>
```

## Servicecomb Pack 发布

#### 发布到临时筹备库

1. 使用 Apache LDAP 账号登录 `https://repository.apache.org/` 清除的临时筹备仓库(Staging Repositories)中多余的版本

2. 下载代码

```shell
mkdir ~/github-apache
git clone https://github.com/apache/servicecomb-pack.git
```

3. 执行 Maven 部署命令

```shell
mvn deploy -DskipTests -Prelease -Drevision=0.7.0
```

4. 使用 Apache LDAP 账号登录 `https://repository.apache.org/`，在 Staging Repositories 中选择刚刚发布的 repository，点击 Close

#### 测试临时筹备库

在发起投票前，我们需要使用临时存储库中的组件执行验收测试，我们需要一些配置步骤让验收测试从临时存储库中拉取依赖包，更多详细说明可以参考 [Guide to Testing Staged Releases](https://maven.apache.org/guides/development/guide-testing-releases.html)


1. 删除本地仓库中组件

```shell
mvn dependency:purge-local-repository -Drevision=0.7.0 -DreResolve=false
```

2. 增加临时存储库配置

在 `~/.m2/settings.xml` 中增加如下配置

```xml
<profiles>
  <profile>
    <id>staged-releases</id>
    <repositories>
      <repository>
        <id>staged-releases</id>
        <url>https://repository.apache.org/content/groups/staging/</url>
      </repository>
    </repositories>
    <pluginRepositories>
      <pluginRepository>
        <id>staged-releases</id>
        <url>https://repository.apache.org/content/groups/staging/</url>
      </pluginRepository>
    </pluginRepositories>
  </profile>
</profiles>
```

3. 执行验收测试

```shell
mvn clean verify -B -f demo -Pdemo -Pdocker -Drevision=0.7.0 -Pstaged-releases
mvn clean verify -B -f acceptance-tests -Pdemo -Pdocker -Drevision=0.7.0 -Pstaged-releases
```

4. 执行验收测试成功后删除本地仓库中的组件

```shell
mvn dependency:purge-local-repository -Drevision=0.7.0 -DreResolve=false
```

5. Share the staging repo with peers to verify on different OS and machines using the demo.

6. If everything is fine then push the tag to master.（在这之前好像遗漏了 TAG 推送和 X 分支推送）


#### 签署版本 & 上传到 Apache SVN

1. 拉取 SVN 仓库到本地

```shell
mkdir ~/apache-dist
cd ~/apache-dist
svn co https://dist.apache.org/repos/dist/dev/servicecomb/servicecomb-pack --username=<Apache LDAP 用户名> --password=<Apache LDAP 密码>
```

2. 创建发布包目录

如果你是第 1 次发布 0.7.0 版本，那么创建 `0.7.0/rc01` 目录，例如：

```shell
mkdir -p ~/apache-dist/servicecomb-pack/0.7.0/rc01
```

3. 复制发布包到发布目录

```shell
cd ~/apache-dist/servicecomb-pack/0.7.0/rc01
cp ~/github-apache/servicecomb-pack/distribution/target/apache-servicecomb-pack-distribution-0.7.0-bin.zip .
cp ~/github-apache/servicecomb-pack/distribution/target/apache-servicecomb-pack-distribution-0.7.0-bin.zip.asc .
cp ~/github-apache/servicecomb-pack/distribution/target/apache-servicecomb-pack-distribution-0.7.0-src.zip .
cp ~/github-apache/servicecomb-pack/distribution/target/apache-servicecomb-pack-distribution-0.7.0-src.zip.asc .
```

6. 生成 SHA512 签名

```shell
cd ~/apache-dist/servicecomb-pack/0.7.0/rc01
shasum -a 512 apache-servicecomb-pack-distribution-0.7.0-bin.zip >> apache-servicecomb-pack-distribution-0.7.0-bin.zip.sha512
shasum -a 512 apache-servicecomb-pack-distribution-0.7.0-src.zip >> apache-servicecomb-pack-distribution-0.7.0-src.zip.sha512
```

7. 提交 Aapache SVN

```shell
cd ~/apache-dist/servicecomb-pack
svn add 0.7.0
svn commit -m 'prepare for 0.7.0 RC1'  --username=<Apache LDAP 用户名> --password=<Apache LDAP 密码>
```

8. 验证发布候选版本

从 Apache SVN https://dist.apache.org/repos/dist/dev/servicecomb/servicecomb-pack/0.7.0/rc01/ 下载发布包检查 GPG 签名和 SHA512 哈希

检查 SHA512 哈希

```shell
$ shasum -c apache-servicecomb-pack-distribution-0.7.0-bin.zip.sha512
$ shasum -c apache-servicecomb-pack-distribution-0.7.0-src.zip.sha512
```

导入公钥

```shell
curl https://dist.apache.org/repos/dist/dev/servicecomb/KEYS >> KEYS
$ gpg --import KEYS
```  

检查 GPG 签名，如果是第一次检查，需要首先导入公钥。

```shell
gpg --verify apache-servicecomb-pack-distribution-0.7.0-bin.zip.asc apache-servicecomb-pack-distribution-0.7.0-bin.zip
gpg --verify apache-servicecomb-pack-distribution-0.7.0-src.zip.asc apache-servicecomb-pack-distribution-0.7.0-src.zip

```

#### PMC 投票

发送投票邮件到 dev@servicecomb.apache.org，投票持续 3 天

```html
Hi All,

This is a call for Vote to release Apache ServiceComb Pack version 0.7.0

Release Candidate :
https://dist.apache.org/repos/dist/dev/servicecomb/servicecomb-pack/0.7.0/rc-01/


Staging Repository :
https://repository.apache.org/content/repositories/orgapacheservicecomb-xxx


Release Tag : https://github.com/apache/servicecomb-pack/releases/tag/0.7.0


Release CommitID : d315a88027e278c473b7c257c45dead970b02694

Release Notes :
https://issues.apache.org/jira/secure/ReleaseNote.jspa?projectId=xxx&version=xxx


Keys to verify the Release Candidate :
https://dist.apache.org/repos/dist/dev/servicecomb/KEYS

Voting will start now ( Thursday, 21st May, 2020) and will remain open for
at-least 72 hours, Request all PMC members to give their vote.

[ ] +1 Release this package as 0.7.0
[ ] +0 No Opinion
[ ] -1 Do not release this package because....

On the behalf of ServiceComb Team

Lei Zhang
```

Wait for 72 hours or unless you get 3 +1 binding vote with no -1 vote. If you get even one -1 binding vote then fix the issue and start again from Step 1.

```html
Hi All,

Thanks everyone for voting on this release, the vote has been closed now and we will announce the results shortly.

Regards
```

Publish the result of the vote in dev@servicecomb.apache.org.

```html
Hello All,

We are glad to announce that ServiceComb community has approved the Apache ServiceComb Pack 0.7.0 release with the following results:

+1 binding: X (xxx, xxx, xxx)

We will be publishing the release binaries soon.

Thanks All for your participation in this vote.
```

#### 公告

Upload the releases to Apache release repository.

Wait for 24 hours to replicate the release in all the mirrors.

Delete old releases from dev and [release] (https://dist.apache.org/repos/dist/release) and check for the old release in archive, update the same links in the website for old releases.

Upload the release page of ServiceComb Website.

Send the announcement mails to dev@servicecomb.apache.org, announce@apache.org
