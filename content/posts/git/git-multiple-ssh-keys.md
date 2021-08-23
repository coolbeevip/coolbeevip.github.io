---
title: "Multiple SSH Keys Settings For Different Git Platform[Github、Gitlab]"
date: 2021-08-22T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

我们在使用 Github、Gitlab 或者 JetBrains Space 时通常使用 SSH 密钥可以连接 Git 服务，而无需在每次访问时都提供用户名和个人访问令牌。
另外现在大量平台启用账户登录多次验证，也促进我们避免使用账号密码登录。

为了便于管理我们通常会为每个 Git 平台配置不同的 SSH KEY，然后通过 `~/.ssh/config` 配置每个平台对应的 SSH KEY。

## 创建多个 SSH KEY

使用如下命令创建 `id_github`，注意提示输入文件名时请修改成 id_github 

```shell
ssh-keygen -t ed25519 -C "coolbeevip@github.com"
```

使用同样的方法我们分别创建 `id_gitlab` 和 `id_github`，这时在的本地的 `~/.ssh` 目录下会得到如下文件

* id_github、id_github.pub
* id_gitlab、id_gitlab.pub

将 *.pub 文件内容分别导入到 Git 服务中，详细方式请参考 [Github and SSH keys](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh) 、
[GitLab and SSH keys](https://docs.gitlab.com/ee/ssh/) 或 [JetBrains Space and SSH keys](https://www.jetbrains.com/help/space/git-keys-and-passwords.html)

## 配置 SSH

编辑 `~/.ssh/config` 文件为每个 Git 地址配置不同的 KEY

```shell
Host github.com
    ServerAliveInterval 60
    UseKeychain yes
    IdentityFile ~/.ssh/id_github

Host gitlab.com
    ServerAliveInterval 60
    UseKeychain yes
    IdentityFile ~/.ssh/id_gitlab
```

验证 Github 平台

```shell
ssh -T git@github.com
Hi coolbeevip! You've successfully authenticated, but GitHub does not provide shell access.
```

验证公司 Gitlab，因为公司服务的端口不是默认端口，所以需要使用 `p` 参数指定

```shell
ssh -T git@mycompany.com -p 20022
Welcome to GitLab, @zhanglei!
```