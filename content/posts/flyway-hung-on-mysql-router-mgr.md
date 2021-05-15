---
title: "Flyway hung on the MySQL Router + MGR"
date: 2018-11-29T13:24:14+08:00
tags: [java, flyway, mysql]
categories: [java, flyway, mysql]
draft: false
---

Flyway 连接 MySQL Router 后启动卡在 GET_LOCK 语句

#### 现象

* MySQL MGR + Router 部署高可用集群
* Flyway 客户端使用 `jdbc:mysql:loadbalance` 连接
* 初始化 Schema History 表、或者执行多个 SQL 脚本时

当满足以上条件时，Flyway 会卡在初始化阶段，经过分析发现停顿在执行 GET_LOCK 语句时

#### 原因

Flyway 默认在执行 DDL 脚本时不启用事务，在初始化时 Flyway 会先执行 GET_LOCK 锁定数据库，然后再执行 DDL 脚本。当使用 `jdbc:mysql:loadbalance` 
连接时，会随机选择一个数据源，如果执行 GET_LOCK 和 执行 DDL 不是一个数据源，就会导致执行等待锁释放

#### 解决办法

在启动时设置 `group=true` 参数，这样 Flyway 在初始化时就会启用事务，确保一个事务内的 DDL 都在一个数据源执行

[ISSUE-3154](https://github.com/flyway/flyway/issues/3154)

```java
public class FlywayTestManual {

  String url="jdbc:mysql:loadbalance://192.168.51.206:3810,192.168.51.207:3810/nc_notifier?roundRobinLoadBalance=false&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=false&useJDBCCompliantTimezoneShift=true&useLegacyDatetimeCode=false&serverTimezone=GMT%2B8&allowMultiQueries=true&allowPublicKeyRetrieval=true";
  String user="user";
  String password="pass";

  @Test
  public void test(){
    Flyway flyway = Flyway.configure()
      .locations("classpath:/db/mysql")
      .baselineOnMigrate(true)
      .group(true)
      .dataSource(url, user, password).load();
    flyway.migrate();
  }
}
```