---
title: "Slow LOG In Redis"
date: 2021-12-05T13:24:14+08:00
tags: [redis]
categories: [redis]
draft: false
---

SLOWLOG 记录了 Redis 运行时间超时特定阀值的命令。这类慢查询命令被保存在 Redis 服务器的一个定长队列中，最多保存 slowlog-max-len(默认128）个慢查询命令。当慢查询命令达到128个时，新产生的慢查询被加入前，会从队列中删除最旧的慢查询命令。

## 配置

redis slowlog通过2个参数配置管理，默认命令耗时超过10毫秒，就会被记录到慢查询日志队列中；队列默认保存最近产生的128个慢查询命令。

* **slowlog-log-slower-than:** 慢查询阀值，单位微秒，默认100000 (10毫秒)； 执行耗时超过这个值的查询会被记录；建议你生产环境设置为 10000（1毫秒），因为如果命令都是 1 毫秒以上，那么 Redis 吞吐率只有 1000 QPS；

* **slowlog-max-len:** 慢查询存储的最大个数，默认128；生产设置设置大于1024，因为 slowlog 会省略过多的参数，慢查询不会占用过多的内存；

## 读取

返回最新的 2 条慢查询

```shell
SLOWLOG GET 2

1) 1) (integer) 9495
   2) (integer) 1638760173
   3) (integer) 13923
   4) 1) "COMMAND"
   5) "10.30.107.152:41830"
   6) ""
2) 1) (integer) 9494
   2) (integer) 1638759729
   3) (integer) 17170
   4) 1) "SADD"
      2) "nc_oauth:uname_to_access:nc:vpengcheng"
      3) "\xac\xed\x00\x05sr\x00Corg.springframework.security.oauth2.common.DefaultOAuth2AccessToken\x0c\xb2\x9e6\x1b$\xfa\xce\x02\x00\x06L\x00\x15additionalInformationt\x00\x0fLjava/util/Map;... (9974 more bytes)"
   5) "10.30.107.149:42132"
   6) ""
```

返回数据关键字段含义如下：

```shell
1) 1) (integer) 9495          
   2) (integer) 1638760173 # 表示查询执行时的 Unix 时间戳
   3) (integer) 13923      # 表示查询执行微秒数
   4) 1) "COMMAND"         # 表示查询的命令和参数
   5) "10.30.107.152:41830"
   6) ""
```
