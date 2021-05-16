---
title: "MySQL Commands"
date: 2020-05-11T13:24:14+08:00
tags: [mysql]
categories: [database]
draft: false
---

常用 MySQL 命令

## 连接数配置

### 查看允许的最大连接数

```sql
show variables like '%max_connection%';
```
### 如果过去曾达到此限制，则可以使用以下方法检查

```sql
SHOW GLOBAL STATUS LIKE 'max_use%';
```

### 配置用户的最大并发连接数

```sql
GRANT USAGE ON *.* TO 'repl'@'%'
WITH MAX_CONNECTIONS_PER_HOUR 100 MAX_USER_CONNECTIONS 10;
```

### 查看用户的最大并发连接数

```sql
SELECT User, Host, max_connections, max_user_connections FROM mysql.user;
```

### 设置最大连接数

```sql
set global max_connections=1000;
```

### 查看当前连接数

```sql
show status like  'Threads%';
```

* Threads_cached 当前线程池中缓存有多少空闲线程
* Threads_connected 当前的连接数 ( 也就是线程数 )
* Threads_running 已经创建的线程总数
* Threads_created 当前激活的线程数 ( Threads_connected 中的线程有些可能处于休眠状态 )

thread_cache_size 值过小会导致频繁创建线程，直接反映就是 show status 查看 `Threads_created` 值过大。
当 Threads_cached 越来越少 但 Threads_connected 始终不降 且 Threads_created 持续升高
这时可适当增加 thread_cache_size 的大小

```sql
show variables like 'thread_cache_size';
```

查看所有用户的当前连接（root 用户才能看所有）

```sql
select * from INFORMATION_SCHEMA.PROCESSLIST
```

## 状态查看

```sql
show status;
```

| 属性 | 描述 |
| ---- | ---- |
|Aborted_clients |由于客户没有正确关闭连接已经死掉，已经放弃的连接数量|
|Aborted_connects |尝试已经失败的MySQL服务器的连接的次数。|
|Connections |试图连接MySQL服务器的次数。|
|Created_tmp_tables |当执行语句时，已经被创造了的隐含临时表的数量。|
|Delayed_insert_threads |正在使用的延迟插入处理器线程的数量。|
|Delayed_writes |用INSERT DELAYED写入的行数。|
|Delayed_errors |用INSERT DELAYED写入的发生某些错误(可能重复键值)的行数。|
|Flush_commands |执行FLUSH命令的次数。|
|Handler_delete |请求从一张表中删除行的次数。|
|Handler_read_first |请求读入表中第一行的次数。|
|Handler_read_key |请求数字基于键读行。|
|Handler_read_next |请求读入基于一个键的一行的次数。|
|Handler_read_rnd |请求读入基于一个固定位置的一行的次数。|
|Handler_update |请求更新表中一行的次数。|
|Handler_write |请求向表中插入一行的次数。|
|Key_blocks_used |用于关键字缓存的块的数量。|
|Key_read_requests |请求从缓存读入一个键值的次数。|
|Key_reads |从磁盘物理读入一个键值的次数。|
|Key_write_requests |请求将一个关键字块写入缓存次数。|
|Key_writes |将一个键值块物理写入磁盘的次数。|
|Max_used_connections |同时使用的连接的最大数目。|
|Not_flushed_key_blocks |在键缓存中已经改变但是还没被清空到磁盘上的键块。|
|Not_flushed_delayed_rows |在INSERT DELAY队列中等待写入的行的数量。|
|Open_tables |打开表的数量。|
|Open_files |打开文件的数量。|
|Open_streams |打开流的数量(主要用于日志记载）|
|Opened_tables |已经打开的表的数量。|
|Questions |发往服务器的查询的数量。|
|Slow_queries |要花超过long_query_time时间的查询数量。|
|Threads_connected |当前打开的连接的数量。|
|Threads_running |不在睡眠的线程数量。|
|Uptime |服务器工作了多长时间，单位秒。|


## 内存配置公式

以下公式计算出最大内存单位为 GB

```sql
select (@@innodb_buffer_pool_size
            + @@key_buffer_size
            + @@max_connections * (@@sort_buffer_size + @@read_buffer_size + @@binlog_cache_size)
            + @@max_connections * 2 * 1024 * 1024) / 1024 / 1024 /1024
```