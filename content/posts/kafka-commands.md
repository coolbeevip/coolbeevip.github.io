---
title: "Kafka Commands"
date: 2020-07-28T13:24:14+08:00
tags: [kafka]
categories: [java]
draft: false
---

常用 Kafka 命令

## Topics

查询 topic 列表

```shell
./bin/kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --list
```

查看 topic 描述

```shell
./bin/kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --describe --topic my-topic
```

## Consumer Groups

查询消费组列表

```shell
./bin/kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --list
```

查询指定的组各 topic 消息消费情况

```shell
./bin/kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --describe --group my-group
```