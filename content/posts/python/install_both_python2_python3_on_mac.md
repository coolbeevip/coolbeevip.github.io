---
title: "Use brew install python2 and python3 on macOS"
date: 2023-03-04T10:24:14+08:00
tags: [python]
categories: [macOS]
draft: false
---

使用 pyenv 可以很灵活的配置版本环境

## 环境说明

我的 macbook 上默认已经安装了 python3，但是我还需要一个 python2 环境编译一些老的项目

```shell
python3 --version
Python 3.11.2
```

## 安装

安装 pyenv

```shell
$ brew install pyenv
```

允许在 bash 中启用 pyenv

```shell
$ eval "$(pyenv init -)"
```

## 使用

一旦你安装了pyenv并激活了它，你可以安装不同版本的python并选择你可以使用的版本。

```shell
$ pyenv install 2.7.18
```

你可以用以下命令检查安装的版本

```shell
$ pyenv versions
```

你可以使用如下命令切换全局版本

```shell
$ pyenv global 3.3.1
```

你可以使用如下命令在当前目录设置版本

```shell
$ pyenv local 3.5.2
```

你能够运行以下命令检查版本

```shell
$ python --version
Python 2.7.18
```