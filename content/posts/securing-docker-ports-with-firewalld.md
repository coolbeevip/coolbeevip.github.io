---
title: "Securing Docker ports with firewalld"
date: 2021-05-11T13:24:14+08:00
categories: [docker,firewalld,centos]
draft: false
---

## 概述

为了保护 Docker 暴露的端口不受外部访问的影响，可以使用 firewalld 配置防火墙规则，只允许特定的 IP 访问。 
通过让 firewalld 创建 DOCKER-USER 链，我们可以实现由 firewalld 维护的安全 Docker 端口, Docker 处理 iptables 规则以提供网络隔离，[更多详细](https://docs.docker.com/network/iptables/)

本文基于环境

* Docker-CE 19.03.12 
* CentOS Linux release 7.8.2003
* Firewall 0.6.3

本文例子:

我们使用 Docker 安装一个 Nginx，并将 80(HTTP) 端口对外映射为 8080，443(HTTPS) 端口对外映射为 8443，并通过 Firewalld 仅允许特定的 IP 访问；**提示：后续的防火墙规则中配置的端口是容器内部端口，例如 80，443**

* 192.168.51.246 安装 Nginx Docker

* 配置 192.168.51.245 可以访问 Nginx Docker

* 其他机器无法访问 Nginx Docker

**重要的事情说三遍**

如果你在 Docker 运行时重启 firewalld，那么 firewalld 将删除 DOCKER-USER

**不要在 Docker 运行时重启 firewalld**

**不要在 Docker 运行时重启 firewalld**

**<font color="red">不要在 Docker 运行时重启 firewalld</font>**

## 准备

清除所有 iptables 配置并重启 Docker。否则在启动 Nginx Docker 时可能会看到 `failed: iptables: No chain/target/match by that name` 错误

```text
iptables -t filter -F
iptables -t filter -X
iptables -t nat -F
iptables -t nat -X
systemctl restart docker
```

设置 SELINUX 权限

```shell
setenforce Permissive
```

永久设置 SELINUX 权限

修改 `/etc/selinux/config` 文件，设置 `SELINUX=permissive`，使其永久生效（需要重启）

## 安装 Nginx

```shell
docker run --name test-nginx --rm -d -p 8080:80 -p 8443:443 nginx:1.20.0-alpine
```
在任意其他机器上测试 `http://192.168.51.246:8080/` 可以正常访问

```shell
curl http://192.168.51.246:8080/

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## 配置 Firewalld

1. 停止 Docker

```shell
systemctl stop docker
```

2. 在 firewalld 中重建 DOCKER-USER iptables chain（请忽略任何警告）

```shell
firewall-cmd --permanent --direct --remove-chain ipv4 filter DOCKER-USER
firewall-cmd --permanent --direct --remove-rules ipv4 filter DOCKER-USER
firewall-cmd --permanent --direct --add-chain ipv4 filter DOCKER-USER
```

3. 添加 iptables 规则到 DOCKER-USER chain

```shell
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 \
  -m conntrack \
  --ctstate RELATED,ESTABLISHED -j ACCEPT \
  -m comment --comment 'Allow containers to connect to the outside world'

firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 \
  -j RETURN \
  -s 172.17.0.0/16 \
  -m comment --comment 'allow internal docker communication'
```

**提示: 172.17.0.0/16  是 Docker 的默认子网地址, 也可以改为你实际的 Docker 子网地址**

4. 为 机器 192.168.51.245 配置允许访问 Nginx Docker 80，443 端口，优先级为1（您可以在以后添加更多优先级为 0 的规则。请参见下文）

```shell
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 1 \
  -o docker0 \
  -p tcp -m multiport \
  --dports 80,443 -s 192.168.51.245/32 -j ACCEPT \
  -m comment \
  --comment 'Allow IP 192.168.51.245 to access http and https docker ports'
```

**提示：这里的端口是指的 Docker 的内部端口 80，443，而不是映射的外部端口 8080，8443**

5. 阻止所有其他IP。 此规则的优先级最低，您可以稍后在此规则之前添加规则

```shell
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 10 \
  -j REJECT -m comment --comment 'reject all other traffic to DOCKER-USER'
```

6. 激活规则

```shell
firewall-cmd --reload
```

7. 启动 Docker

```shell
systemctl start docker
```

8. 配置完毕

你能在文件 `/etc/firewalld/direct.xml` 中看到规则配置

```xml
<?xml version="1.0" encoding="utf-8"?>
<direct>
  <chain table="filter" ipv="ipv4" chain="DOCKER-USER"/>
  <rule priority="1" table="filter" ipv="ipv4" chain="DOCKER-USER">-m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT -m comment --comment 'Allow containers to connect to the outside world'</rule>
  <rule priority="1" table="filter" ipv="ipv4" chain="DOCKER-USER">-j RETURN -s 172.17.0.0/16 -m comment --comment 'allow internal docker communication'</rule>
  <rule priority="1" table="filter" ipv="ipv4" chain="DOCKER-USER">-o docker0 -p tcp -m multiport --dports 80,443 -s 192.168.51.245/32 -j ACCEPT -m comment --comment 'Allow IP 192.168.51.245 to access htt
    p and https docker ports'</rule>
  <rule priority="10" table="filter" ipv="ipv4" chain="DOCKER-USER">-j REJECT -m comment --comment 'reject all other traffic to DOCKER-USER'</rule>
</direct>
```

使用 iptables -L 命令查看 

```text
Chain DOCKER-USER (1 references)
target     prot opt source               destination
LOG        all  --  anywhere             anywhere             LOG level warning prefix " DOCKER TCP: "
ACCEPT     all  --  anywhere             anywhere             ctstate RELATED,ESTABLISHED /* Allow containers to connect to the outside world */
RETURN     all  --  172.17.0.0/16        anywhere             /* allow internal docker communication */
ACCEPT     tcp  --  192.168.51.245       anywhere             multiport dports http,https /* Allow IP 192.168.51.245 to access http and https docker ports */
REJECT     all  --  anywhere             anywhere             /* reject all other traffic to DOCKER-USER */ reject-with icmp-port-unreachable
RETURN     all  --  anywhere             anywhere
```

## 调试日志

为了进行调试，您可以将日志记录添加到具有最高优先级的DOCKER-USER链中
  
```shell
firewall-cmd --direct --add-rule ipv4 filter DOCKER-USER 0 \
  -j LOG --log-prefix ' DOCKER TCP: '
```

执行 `tail -f /var/log/messages | grep "DOCKER TCP"` 命令可以查看日志

来自 192.168.51.245 的访问被允许

```text
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=ens33 OUT=docker0 MAC=00:0c:29:a5:9d:2d:00:0c:29:4f:d7:c9:08:00 SRC=192.168.51.245 DST=172.17.0.2 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=52186 DF PROTO=TCP SPT=38880 DPT=80 WINDOW=29200 RES=0x00 SYN URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=docker0 OUT=ens33 PHYSIN=veth621dcb8 MAC=02:42:c9:d9:ec:7f:02:42:ac:11:00:02:08:00 SRC=172.17.0.2 DST=192.168.51.245 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=0 DF PROTO=TCP SPT=80 DPT=38880 WINDOW=28960 RES=0x00 ACK SYN URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=ens33 OUT=docker0 MAC=00:0c:29:a5:9d:2d:00:0c:29:4f:d7:c9:08:00 SRC=192.168.51.245 DST=172.17.0.2 LEN=52 TOS=0x00 PREC=0x00 TTL=63 ID=52187 DF PROTO=TCP SPT=38880 DPT=80 WINDOW=229 RES=0x00 ACK URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=ens33 OUT=docker0 MAC=00:0c:29:a5:9d:2d:00:0c:29:4f:d7:c9:08:00 SRC=192.168.51.245 DST=172.17.0.2 LEN=135 TOS=0x00 PREC=0x00 TTL=63 ID=52188 DF PROTO=TCP SPT=38880 DPT=80 WINDOW=229 RES=0x00 ACK PSH URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=docker0 OUT=ens33 PHYSIN=veth621dcb8 MAC=02:42:c9:d9:ec:7f:02:42:ac:11:00:02:08:00 SRC=172.17.0.2 DST=192.168.51.245 LEN=52 TOS=0x00 PREC=0x00 TTL=63 ID=24181 DF PROTO=TCP SPT=80 DPT=38880 WINDOW=227 RES=0x00 ACK URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=docker0 OUT=ens33 PHYSIN=veth621dcb8 MAC=02:42:c9:d9:ec:7f:02:42:ac:11:00:02:08:00 SRC=172.17.0.2 DST=192.168.51.245 LEN=290 TOS=0x00 PREC=0x00 TTL=63 ID=24182 DF PROTO=TCP SPT=80 DPT=38880 WINDOW=227 RES=0x00 ACK PSH URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=docker0 OUT=ens33 PHYSIN=veth621dcb8 MAC=02:42:c9:d9:ec:7f:02:42:ac:11:00:02:08:00 SRC=172.17.0.2 DST=192.168.51.245 LEN=664 TOS=0x00 PREC=0x00 TTL=63 ID=24183 DF PROTO=TCP SPT=80 DPT=38880 WINDOW=227 RES=0x00 ACK PSH URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=ens33 OUT=docker0 MAC=00:0c:29:a5:9d:2d:00:0c:29:4f:d7:c9:08:00 SRC=192.168.51.245 DST=172.17.0.2 LEN=52 TOS=0x00 PREC=0x00 TTL=63 ID=52189 DF PROTO=TCP SPT=38880 DPT=80 WINDOW=237 RES=0x00 ACK URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=ens33 OUT=docker0 MAC=00:0c:29:a5:9d:2d:00:0c:29:4f:d7:c9:08:00 SRC=192.168.51.245 DST=172.17.0.2 LEN=52 TOS=0x00 PREC=0x00 TTL=63 ID=52190 DF PROTO=TCP SPT=38880 DPT=80 WINDOW=247 RES=0x00 ACK URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=ens33 OUT=docker0 MAC=00:0c:29:a5:9d:2d:00:0c:29:4f:d7:c9:08:00 SRC=192.168.51.245 DST=172.17.0.2 LEN=52 TOS=0x00 PREC=0x00 TTL=63 ID=52191 DF PROTO=TCP SPT=38880 DPT=80 WINDOW=247 RES=0x00 ACK FIN URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=docker0 OUT=ens33 PHYSIN=veth621dcb8 MAC=02:42:c9:d9:ec:7f:02:42:ac:11:00:02:08:00 SRC=172.17.0.2 DST=192.168.51.245 LEN=52 TOS=0x00 PREC=0x00 TTL=63 ID=24184 DF PROTO=TCP SPT=80 DPT=38880 WINDOW=227 RES=0x00 ACK FIN URGP=0
May 12 11:45:48 localhost kernel: DOCKER TCP: IN=ens33 OUT=docker0 MAC=00:0c:29:a5:9d:2d:00:0c:29:4f:d7:c9:08:00 SRC=192.168.51.245 DST=172.17.0.2 LEN=52 TOS=0x00 PREC=0x00 TTL=63 ID=52192 DF PROTO=TCP SPT=38880 DPT=80 WINDOW=247 RES=0x00 ACK URGP=0
```

来自 192.168.51.236 的访问被拒绝

```text
May 12 11:45:55 localhost kernel: DOCKER TCP: IN=ens33 OUT=docker0 MAC=00:0c:29:a5:9d:2d:00:0c:29:26:fd:35:08:00 SRC=192.168.51.236 DST=172.17.0.2 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=49189 DF PROTO=TCP SPT=56194 DPT=80 WINDOW=29200 RES=0x00 SYN URGP=0
```

## 提示

如果你想重置 firewalld，那么请按如下步骤操作，**！！！必须先停止 Docker！！！**

```shell
systemctl stop docker
systemctl stop firewalld
rm -rf /etc/firewalld/direct.xml
systemctl start firewalld
systemctl start docker
```