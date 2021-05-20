---
title: "APISIX Study Notes (1) QuickStart"
date: 2021-05-21T01:00:00+08:00
tags: [apisix,gateway]
categories: [gateway]
draft: true
---

## 编译环境准备

* Node.js 10.23.0+
* Yarn
* openresty
* luarocks
* lua@5.1
* curl
* wget

```shell
npm install -g yarn
brew install openresty/brew/openresty luarocks lua@5.1 etcd curl git
```

## 编译 APISIX 服务

```shell
git clone git@github.com:apache/apisix.git
cd apisix
make deps
```

版本查看

```shell
./bin/apisix version
```

## 编译 APISIX 控制台

```shell
git clone https://github.com/apache/apisix-dashboard.git
cd apisix-dashboard
make build
```

如果出现错误提示：
**错误: 无法验证 github.com 的由 “CN=DigiCert High Assurance TLS Hybrid ECC SHA256 2020 CA1,O=DigiCert\\, Inc.,C=US” 颁发的证书:
无法本地校验颁发者的权限。
要以不安全的方式连接至 github.com，使用“--no-check-certificate”。**

打开 `api/build.sh`

找到 `wget https://github.com/api7/dag-to-lua/archive/v1.1.tar.gz -P /tmp`

替换为 `wget --no-check-certificate https://github.com/api7/dag-to-lua/archive/v1.1.tar.gz -P /tmp`

## 启动 

* 启动 Etcd

```shell
brew services start etcd
```

etcd server 启用 TLS

```shell
etcd --cert-file=/path/to/cert --key-file=/path/to/pkey --advertise-client-urls https://127.0.0.1:2379
```

* 启动 APISIX 服务

```shell
./bin/apisix start
```

* 启动 APISIX 控制台

```shell
cd ./output
#./manager-api 或者 nohup ./manager-api &
```

## 访问

在浏览器打开 http://127.0.0.1:9000/

![image-notice-csv](/images/posts/study-notes-for-apisix/apisix-dashboard.png)

## 停止

* 停止 APISIX 服务

```shell

```

* 停止 APISIX 控制台

```shell
./manager-api stop
```

* 停止 Etcd