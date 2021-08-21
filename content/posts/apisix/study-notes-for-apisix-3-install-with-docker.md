---
title: "APISIX Study Notes (3) Install with Docker"
date: 2021-05-21T01:00:00+08:00
tags: [apisix]
categories: [gateway]
draft: false
---

使用 Docker 启动

## 定义卷目录

APISIX 目前好像还不支持通过环境变量配置参数，所以需要在宿主机上创建配置文件，并在启动 Docker 时通过 Volume 映射进容器

规划外部卷目录

```shell
mkdir apisix_home
mkdir -p apisix_home/apisix_volume/apisix/apisix_conf
mkdir -p apisix_home/apisix_volume/apisix/dashboard_conf
```

定义 APISIX Dashboard 配置文件 apisix_home/apisix_volume/apisix/dashboard_conf/conf.yaml

```yaml
conf:
  listen:
    # 绑定 IP 地址
    host: 0.0.0.0
    # 监听端口
    port: 9000
  etcd:
    # etcd 用户名
    # username: "root"
    # etcd 密码
    # password: "123456"    
    # etcd 地址，支持集群多节点定义
    endpoints:
      - apisix-etcd:2379
  log:
    error_log:
      # 日志级别 debug, info, warn, error, panic, fatal
      level: warn 
      # 日志输出路径
      file_path: logs/error.log
      
authentication:
  secret: secret
  # jwt token 过期时间（秒)
  expire_time: 3600     
  # 登录用户名密码
  users:
    - username: admin 
      password: admin
    - username: user
      password: user
```

定义 APISIX 配置文件 apisix_home/apisix_volume/apisix/apisix_conf/config.yaml

```yaml
apisix:
  node_listen: 9080
  enable_ipv6: false
  allow_admin:
    - 0.0.0.0/0
  admin_key:
    - name: "admin"
      key: edd1c9f034335f136f87ad84b625c8f1
      role: admin
etcd:
  host:
    - http://apisix-etcd:2379
```

## 定义 Docker Compose 文件

在这个文件里，将 APISIX，Dashboard，Etcd 都集成到一起，并且使用内部网络与 Etcd 通讯

创建 Docker Compose 文件 apisix_home/apisix-all-in-one.yml

```yaml
version: "3"
services:
  apisix:
    image: apache/apisix:2.5-alpine
    container_name: apisix-server
    restart: always
    volumes:
      - ./apisix_volume/apisix/apisix_log:/usr/local/apisix/logs
      - ./apisix_volume/apisix/apisix_conf/config.yaml:/usr/local/apisix/conf/config.yaml:ro
    depends_on:
      - apisix-etcd
    ports:
      - 9080:9080
      - 9443:9443
    networks:
      - apisix

  apisix-dashboard:
    image: apache/apisix-dashboard:2.6
    container_name: apisix-dashboard
    restart: always
    volumes:
      - ./apisix_volume/apisix/dashboard_conf/conf.yaml:/usr/local/apisix-dashboard/conf/conf.yaml:ro
    depends_on:
      - apisix-etcd
    ports:
      - 9000:9000
    networks:
      - apisix

  apisix-etcd:
    image: docker.io/bitnami/etcd:3.4.16
    container_name: apisix-etcd
    #ports:
    #  - 2380:2380
    #  - 2379:2379
    environment:
      - ALLOW_NONE_AUTHENTICATION=yes
      - ETCD_NAME=etcd-1
      - ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
      - ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
      - ETCD_ADVERTISE_CLIENT_URLS=http://0.0.0.0:2379
    volumes:
      - ./apisix_volume/apisix/etcd/data:/bitnami/etcd/data
      - ./apisix_volume/apisix/etcd/conf:/opt/bitnami/etcd/conf
    networks:
      - apisix

networks:
  apisix:
    driver: bridge
```

## 启动 & 停止

启动

```shell
$ cd apisix_home
$ docker-compose -f apisix-all-in-one.yml up -d
```

停止

```shell
$ cd apisix_home
$ docker-compose -f apisix-all-in-one.yml down
```

## 验证

* 在浏览器打开 APISIX Dashboard 页面 http://127.0.0.1:9000
  
* 验证 APISIX 服务

```shell
$ curl http://127.0.0.1:9080/apisix/admin/services/ -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1'

{
	"node": {
		"key": "\/apisix\/services",
		"dir": true,
		"nodes": {}
	},
	"action": "get",
	"count": "1"
}
```
