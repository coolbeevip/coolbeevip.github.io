---
title: "APISIX Study Notes (1) QuickStart"
date: 2021-05-21T01:00:00+08:00
tags: [apisix,gateway]
categories: [gateway]
draft: false
---

## 安装

以下操作在 macOS 系统

#### 安装 Etcd

* 启动

apisix-etcd.yml

```yaml
version: '3.2'
services:
  etcd-1:
    image: docker.io/bitnami/etcd:3.4.16
    hostname: etcd
    container_name: apisix-etcd
    ports:
      - '2380:2380'
      - '2379:2379'
    environment:
      - ALLOW_NONE_AUTHENTICATION=yes
      - ETCD_NAME=etcd-1
      - ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
      - ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
      - ETCD_ADVERTISE_CLIENT_URLS=http://0.0.0.0:2379
    volumes:
      - ./volume/apisix/etcd/data:/bitnami/etcd/data
      - ./volume/apisix/etcd/conf:/opt/bitnami/etcd/conf
```

```shell
docker-compose -f docker-compose-apisix-etcd.yml up -d
```

* 验证

```shell
$ curl -L http://127.0.0.1:2379//health
{"health":"true"}
```
#### 安装编译环境

* 安装 Node 10.23.0+
  
```shell
$ node -v
v12.18.3
```

* 安装 Yarn
  
```shell
$ npm install -g yarn
$ yarn -v
1.22.10
```

* 安装 openresty 、luarocks、lua、curl、 git

```shell
brew install openresty/brew/openresty luarocks lua@5.1 curl git
```

查看 openresty 版本
  
```shell
$ openresty -v
nginx version: openresty/1.19.3.1
```
查看 luarocks 版本
  
```shell
$ luarocks --version
/usr/local/bin/luarocks 3.6.0
LuaRocks main command-line interface
```

查看 lua@5.1 版本
  
```shell
$ lua -v
Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
```

查看 curl 版本
  
```shell
$ curl --version
curl 7.65.2 (x86_64-apple-darwin13.4.0) libcurl/7.65.2 OpenSSL/1.1.1c zlib/1.2.11 libssh2/1.8.2
```

查看 wget 版本

```shell
$ wget --version
GNU Wget 1.21.1 在 darwin19.6.0
```

#### 安装 APISIX 服务

* 下载和编译

```shell
git clone git@github.com:apache/apisix.git
cd apisix
make deps
```

* 查看版本

```shell
$ ./bin/apisix version
/usr/local/Cellar/openresty/1.19.3.1_1/luajit/bin/luajit ./apisix/cli/apisix.lua version
2.5
```

* 启动 APISIX 服务

```shell
$ ./bin/apisix start
/usr/local/Cellar/openresty/1.19.3.1_1/luajit/bin/luajit ./apisix/cli/apisix.lua start
APISIX is running...
```

* 验证服务

```shell
$ curl http://127.0.0.1:9080/apisix/admin/services/ -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1'
{"node":{"key":"\/apisix\/services","dir":true,"nodes":{}},"action":"get","count":"1"}
```

* 停止 APISIX 服务

```shell
$ ./bin/apisix stop
/usr/local/Cellar/openresty/1.19.3.1_1/luajit/bin/luajit ./apisix/cli/apisix.lua stop
```

#### 安装 APISIX 控制台

* 下载和编译

```shell
git clone https://github.com/apache/apisix-dashboard.git
cd apisix-dashboard
make build
```

**提示：** 如果出现以下提示，需要修改 `api/build.sh` 文件中 `wget https://github.com/api7/dag-to-lua/archive/v1.1.tar.gz -P /tmp` 部分，修改为 `wget --no-check-certificate https://github.com/api7/dag-to-lua/archive/v1.1.tar.gz -P /tmp`

```shell
无法验证 github.com 的由 “CN=DigiCert High Assurance TLS Hybrid ECC SHA256 2020 CA1,O=DigiCert\\, Inc.,C=US” 颁发的证书:
无法本地校验颁发者的权限。
要以不安全的方式连接至 github.com，使用“--no-check-certificate”。
```

* 启动

```shell
$ ./manager-api
The manager-api is running successfully!

Version : 2.6
GitHash : 9728a43
Listen  : 0.0.0.0:9000
Loglevel: warn
Logfile : /Users/zhanglei/github/apisix-dashboard/output/logs/error.log
```

* 在浏览器打开 http://127.0.0.1:9000/，默认用户名密码为 admin/admin

![image-apisix-dashboard](/images/posts/study-notes-for-apisix/apisix-dashboard.png)

* 停止

```shell
./manager-api stop
```

## 使用

* 配置一个 UPSTREAM (http://192.168.51.234:5005)

![image-apisix-dashboard-upstream](/images/posts/study-notes-for-apisix/apisix-dashboard-upstream.png)

确定这个 upstream  可以正常工作

```shell
$ curl -i -X GET http://192.168.51.234:5005/nc-tools/actuator/health
HTTP/1.1 200 OK
Connection: keep-alive
Transfer-Encoding: chunked
Content-Type: application/vnd.spring-boot.actuator.v3+json
Date: Fri, 21 May 2021 12:20:00 GMT

{"status":"UP","components":{...}}
```

配置后的数据开起来如下

```shell
curl http://127.0.0.1:9080/apisix/admin/upstreams/355873825117701764 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1'

{
	"action": "get",
	"node": {
		"key": "\/apisix\/upstreams\/355873825117701764",
		"value": {
			"scheme": "http",
			"timeout": {
				"read": 6,
				"connect": 6,
				"send": 6
			},
			"pass_host": "pass",
			"create_time": 1621646929,
			"nodes": [{
				"port": 5005,
				"weight": 100,
				"host": "192.168.51.234"
			}],
			"id": "355873825117701764",
			"type": "roundrobin",
			"name": "my-upstream",
			"update_time": 1621648975,
			"retries": 3
		}
	},
	"count": "1"
}
```

* 配置一个 ROUTE(355873926217205380)

![image-apisix-dashboard-route](/images/posts/study-notes-for-apisix/apisix-dashboard-route.png)

* 关联 UPSTREAM(355873825117701764)

![image-apisix-dashboard-backend-server](/images/posts/study-notes-for-apisix/apisix-dashboard-backend-server.png)

配置后的数据看起来如下

```shell
$ curl http://127.0.0.1:9080/apisix/admin/routes/355873926217205380 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1'

{
	"action": "get",
	"node": {
		"key": "\/apisix\/routes\/355873926217205380",
		"value": {
			"uris": ["\/nc-tools\/actuator\/health"],
			"name": "my-upstream",
			"labels": {
				"API_VERSION": "1.0"
			},
			"create_time": 1621646989,
			"status": 1,
			"id": "355873926217205380",
			"upstream_id": "355873825117701764",
			"update_time": 1621648989,
			"methods": ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS", "CONNECT", "TRACE"]
		}
	},
	"count": "1"
}
```

* 通过 APISIX 调用我的 UPSTREAM 服务

```shell
$ curl -i -X GET http://127.0.0.1:9080/nc-tools/actuator/health
HTTP/1.1 200 OK
Content-Type: application/vnd.spring-boot.actuator.v3+json
Transfer-Encoding: chunked
Connection: keep-alive
Date: Sat, 22 May 2021 02:00:27 GMT
Server: APISIX/2.5

{"status":"UP","components":{...}}
```