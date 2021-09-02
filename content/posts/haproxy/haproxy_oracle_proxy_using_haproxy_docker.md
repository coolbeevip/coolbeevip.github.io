---
title: "Oracle Proxy Using HAProxy Docker"
date: 2020-09-01T13:24:14+08:00
tags: [haproxy,oracle]
categories: [haproxy]
draft: false
---

下载 HAProxy Docker

```shell
docker pull haproxy:2.3
```

创建工作目录

```shell
mkdir -p /opt/haproxy-oracle/docker_volume
```

在 `/opt/haproxy-oracle/docker_volume` 目录下创建如下 haproxy.cfg 文件，请将文件尾部的 oracle 地址和端口改为你的地址和端口

```shell
global
  daemon
  log 127.0.0.1 local0
  log 127.0.0.1 local1 notice
  maxconn 4096
  tune.ssl.default-dh-param 2048

defaults
  log               global
  retries           3
  maxconn           2000
  timeout connect   5s
  timeout client    50s
  timeout server    50s

listen stats
  bind *:9090
  balance
  mode http
  stats enable
  stats auth admin:admin
  stats uri /stats

listen oracle-proxy
  log global
  bind :1521
  mode tcp
  balance roundrobin
  server oracle-1 10.221.172.58:1521
  #server oracle-2 10.221.172.120:1521
```

在 `/opt/haproxy-oracle` 目录，创建 haproxy-oracle.yml 文件

```yaml
version: '3.2'
services:
  haproxy:
    image: haproxy:2.3
    container_name: haproxy
    restart: always
    ports:
      - 1521:1521
      - 9090:9090
    volumes:
      - ./docker_volume:/usr/local/etc/haproxy:ro
```

进入到 `/opt/haproxy-oracle` 目录，执行一下命令启动 HAProxy

```shell
docker-compose -f haproxy-oracle.yml up -d
```

在浏览器输入 `http://localhost:9090/stats` 可以打开 HAProxy 的监控页面，用户名 admin 密码 admin。此时就完成的代理服务的启动。

此时你访问 HAProxy 这台机器的 IP:1521 ，将被代理到 10.221.172.58:1521


