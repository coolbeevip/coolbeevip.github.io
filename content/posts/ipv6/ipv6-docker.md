---
title: "Oracle Proxy Using HAProxy Docker"
date: 2020-09-01T13:24:14+08:00
tags: [ipv6,docker]
categories: [ipv6]
draft: true
---

docker engine 的版本大于等于20.10.2

1. 编辑 `/etc/docker/daemon.json`, 启用 IPv6 并设置 subnet. 例如这是子网为 to 2001:db8:1::/64.

```json
{
    "ipv6": true,
    "fixed-cidr-v6": "2001:db8:1::/64"
}
```

2. 重新加载配置文件

```shell
systemctl reload docker
```

3. 创建容器网络

192.168.65.0/24

```shell
docker network create -d bridge --ipv6 \
  --subnet "2001:db8:1:1::/64" --gateway="2001:db8:1::1" \
  --subnet=172.18.0.0/16 --gateway=172.18.0.1 \
  nc-network-ipv6
```
4. 创建容器实例

```shell
docker run -itd -P --ip=172.18.0.101 --ip6="2001:db8:1::101" --network=myNet --name=my101 centos:7
```
