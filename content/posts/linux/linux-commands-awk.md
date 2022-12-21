---
title: "常用日志统计脚本"
date: 2022-10-23T13:24:14+08:00
tags: [linux,awk]
categories: [linux]
draft: false
---

常用日志分析脚本，日志样例如下

> 2022-12-02 17:00:02,580 [reactor-http-epoll-7] O [com.my.gateway.filter.RequestGlobalFilter] RequestGlobalFilter.java:46 - request http://gateway/myapp/graphql remote address 110.242.12.19

## 统计文件中匹配规则的行数

统计 2022-12-02 日 17 点至 18 点包含 `RequestGlobalFilter` 关键字的行数

```shell
$ cat my-gateway_9999.log | grep '2022-12-02 17.*RequestGlobalFilter' | wc -l
24003
```

统计 2022-12-02 日 17 点至 18 点包含 `RequestGlobalFilter` 并且请求路径包含 `myapp` 关键字的行数

```shell
$ cat my-gateway_9999.log | grep '2022-12-02 17.*RequestGlobalFilter.*myapp.*' | wc -l
6369
```

## 分组统计

统计 2022-12-02 日 17 点至 18 点包含 `RequestGlobalFilter` 按照客户端 IP 地址统计每个客户端的请求行数

```shell
$ cat my-gateway_9999.log | grep '2022-12-02 17.*RequestGlobalFilter.*' | awk -F ' ' '{count[$14]++;} END {for(i in count) {print i "\t" count[i]}}'
110.242.12.19	6919
110.221.173.234	7003
110.221.172.110	1
110.242.15.91	2
110.219.216.34	1
110.219.216.35	5
110.242.12.20	9113
110.234.255.139	294
110.221.171.81	6
110.221.173.212	241
110.234.255.141	418
```

统计 2022-12-02 日 17 点至 18 点包含 `RequestGlobalFilter` 按照请求路径统计每个客户端的请求行数

```shell
$ cat my-gateway_9999.log | grep '2022-12-02 17.*RequestGlobalFilter.*' | awk -F ' ' '{count[$11]++;} END {for(i in count) {print i "\t" count[i]}}'
```

统计 2022-12-02 日 17 点至 18 点包含 `RequestGlobalFilter` 按照请求路径统计每个客户端的请求行数（并过滤出行数统计大于 500 的）

```shell
$ cat my-gateway_9999.log | grep '2022-12-02 17.*RequestGlobalFilter.*' | awk -F ' ' '{count[$11]++;} END {for(i in count) {print i "\t" count[i]}}' | awk -F '\t' '{if($2>500){print $0}}'
http://gateway/app1/graphql	5785
http://110.221.173.236:18005/app2/graphql	845
http://gateway/app3/graphql	875
http://gateway/app4/graphql	943
http://110.221.173.236:18005/myapp/graphql	5758
http://110.221.173.198:8005/myapp/graphql	518
http://gateway/app5/graphql	3274
http://gateway/app6/graphql	1015
http://gateway/app7/graphql	1690
```