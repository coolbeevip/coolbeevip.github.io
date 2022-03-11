---
title: "Docker IPv6 Support"
date: 2022-03-11T13:24:14+08:00
tags: [ipv6,docker]
categories: [ipv6]
draft: false
---

本文介绍在 IPv6 网络主机上部署 Docker

## 主机 IPv6 网络检查

使用 `ifconfig` 命令查看是否已经配置了 IPv6 网络

```shell
$ ifconfig eth1
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.252.248.152  netmask 255.255.255.128  broadcast 10.252.248.255
        inet6 2409:8010:5ac0:400:200::2d  prefixlen 128  scopeid 0x0<global>
        inet6 fe80::f816:3eff:fe84:bc36  prefixlen 64  scopeid 0x20<link>
        ether fa:16:3e:84:bc:36  txqueuelen 1000  (Ethernet)
        RX packets 7150695  bytes 4751783652 (4.4 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 5018420  bytes 4436770306 (4.1 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```        

* 你可以看到主机已经获取到了 IPv6 地址 **inet6 2409:8010:5ac0:400:200::2d**
* **注意：** fe80:: 开头的地址只是链接本地地址


分别在主机和其他主机使用 `ping6` 命令验证网络是否可达

```shell
$ ping6 2409:8010:5ac0:400:200::2d
PING 2409:8010:5ac0:400:200::2d(2409:8010:5ac0:400:200::2d) 56 data bytes
64 bytes from 2409:8010:5ac0:400:200::2d: icmp_seq=1 ttl=64 time=43.5 ms
64 bytes from 2409:8010:5ac0:400:200::2d: icmp_seq=2 ttl=64 time=0.211 ms
64 bytes from 2409:8010:5ac0:400:200::2d: icmp_seq=3 ttl=64 time=0.222 ms
```

至此，你的主机已经正确分配了 IPv6 地址，并且网络可达。

## Docker 配置 IPv6

Docker 版本至少要 19.03 以上

```shell
$ docker -v
Docker version 19.03.12, build 48a66213fe
```

编辑 /etc/docker/daemon.json 文件，加上如下的内容

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64"
}
```

重新加载 Docker 配置

```shell
sudo systemctl reload docker
```

手动配置 IPv6 路由网络（否则容器内无法连接到外部 IPv6 网络）

```shell
sudo ip6tables -t nat -I POSTROUTING -j MASQUERADE
```

## 检查 Docker IPv6 配置

使用 `ip aaddr show` 命令查看 docker0 网络是否有 IPv6 地址 **inet6 2001:db8:1::1/64**

```shell
6033: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:0c:c3:c3:42 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 2001:db8:1::1/64 scope global tentative
       valid_lft forever preferred_lft forever
    inet6 fe80::1/64 scope link tentative
       valid_lft forever preferred_lft forever
```

**注意：** 如果 docker0 网络没有 IPv6 地址，则需要使用如下命令重建 docker0 网络

```shell
pkill docker
iptables -t filter -F
iptables -t filter -X
iptables -t nat -F
iptables -t nat -X
ifconfig docker0 down
ip link del docker0
systemctl restart docker
```

执行 docker network inspect bridge 命令查看容器默认网络是否已经 **EnableIPv6=true**

```shell
$ docker network inspect bridge
[
    {
        "Name": "bridge",
        "Id": "9ca5a393724ae742f29537572920dd69187465be04bcb660f1d146fa0f7836da",
        "Created": "2021-12-16T14:38:41.371029327+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": true,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                },
                {
                    "Subnet": "2001:db8:1::/64"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]
```

启动一个容器，验证容器内是否正确获取了 IPv6 地址

```shell
$ docker run --rm -it alpine:3.14 ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02  
          inet addr:172.17.0.2  Bcast:172.17.255.255  Mask:255.255.0.0
          inet6 addr: 2001:db8:1::242:ac11:2/64 Scope:Global
          inet6 addr: fe80::42:acff:fe11:2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:1 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:110 (110.0 B)  TX bytes:90 (90.0 B)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```          

进入容器内部尝试 ping6 外部主机

```shell
$ docker run --rm -it alpine:3.14 ping6 2409:8010:5ac0:400:200::2d
PING 2409:8010:5ac0:400:200::2d (2409:8010:5ac0:400:200::2d): 56 data bytes
64 bytes from 2409:8010:5ac0:400:200::2d: seq=0 ttl=63 time=45.846 ms
64 bytes from 2409:8010:5ac0:400:200::2d: seq=1 ttl=63 time=0.444 ms
64 bytes from 2409:8010:5ac0:400:200::2d: seq=2 ttl=63 time=0.406 ms
64 bytes from 2409:8010:5ac0:400:200::2d: seq=3 ttl=63 time=0.334 ms
```

## 启动 Nginx Docker 验证 IPv6 地址访问

启动一个镜像

```shell
$ docker run --rm --name my-nginx -d -p 8080:80 my-nginx
```

使用 IPv6 地址访问

```shell
$ curl -g http://[2409:8010:5ac0:400:200::2d]:8080
*   Trying 127.0.0.1:8080...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET / HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.65.2
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Server: nginx/1.20.1
< Date: Fri, 09 Jul 2021 08:49:02 GMT
< Content-Type: text/html
< Content-Length: 612
< Last-Modified: Tue, 25 May 2021 13:41:16 GMT
< Connection: keep-alive
< ETag: "60acfe7c-264"
< Accept-Ranges: bytes
<
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
* Connection #0 to host localhost left intact

```
