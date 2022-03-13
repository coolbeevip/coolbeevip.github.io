---
title: "Kafka 3.X"
date: 2022-03-09T13:24:14+08:00
tags: [kafka]
categories: [java]
draft: false
---

由于 ksqlDB 在 Kafka 之上运行，我们将使用 Docker Compose 来运行 Kafka 组件、ksqlDB 服务器和 ksqlDB CLI 客户端：

## Docker

创建文件 ksqldb.yml

```yaml
---
version: '2'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.0.1
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  broker:
    image: confluentinc/cp-kafka:7.0.1
    hostname: broker
    container_name: broker
    depends_on:
      - zookeeper
    ports:
      - "29092:29092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:9092,PLAINTEXT_HOST://localhost:29092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1

  ksqldb-server:
    image: confluentinc/ksqldb-server:0.24.0
    hostname: ksqldb-server
    container_name: ksqldb-server
    depends_on:
      - broker
    ports:
      - "8088:8088"
    environment:
      KSQL_LISTENERS: http://0.0.0.0:8088
      KSQL_BOOTSTRAP_SERVERS: broker:9092
      KSQL_KSQL_LOGGING_PROCESSING_STREAM_AUTO_CREATE: "true"
      KSQL_KSQL_LOGGING_PROCESSING_TOPIC_AUTO_CREATE: "true"

  ksqldb-cli:
    image: confluentinc/ksqldb-cli:0.24.0
    container_name: ksqldb-cli
    depends_on:
      - broker
      - ksqldb-server
    entrypoint: /bin/sh
    tty: true
```

首先，让我们启动 ksqlDB

```shell
$ docker-compose -f ksqldb.yml up
```

接下来，在所有服务启动后，让我们连接到交互式 CLI

```shell
$ docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

我们还将告诉 ksqlDB 从每个主题的最早点开始所有查询

```shell
ksql> SET 'auto.offset.reset' = 'earliest';
```

## 参考

* https://ksqldb.io/quickstart.html
* https://www.baeldung.com/ksqldb
* https://daniel.arneam.com/blog/distributedarchitecture/2020-11-09-Kafka-ksqlDB-Concepts/
