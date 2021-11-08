---
title: "The Impact of Undertow Thread Options & Database Connection Pool on Performance"
date: 2021-09-23T13:24:14+08:00
tags: [undertow,hikari]
categories: [java]
draft: false
---

Hikari 线程参数和数据库连接池参数对业务吞吐率的影响分析

#### 场景

本例中我们使用 Undertow 作为 Web 容器，使用 Hikari 作为数据库连接池，
并通过 `spring.datasource.hikari.maximum-pool-size` 和 `server.undertow.threads.worker` 两个参数的调整，看看对于业务的性能影响有多大

为此我准备了一个简单的 DEMO，并且执行 1000 次请求，并发 100，每次请求执行一个 SLEEP(5) 的 SQL模拟单笔耗时。并在一个 2C 的服务器上测试。应用默认参数如下

```properties
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.minimum-idle=10
spring.datasource.hikari.maximum-pool-size=10
server.undertow.threads.worker(默认是 2C*8)
```

#### 默认参数

```shell
$ ab -c 100 -n 1000 http://localhost:6060/test
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking localhost (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Completed 400 requests
Completed 500 requests
Completed 600 requests
Completed 700 requests
Completed 800 requests
Completed 900 requests
Completed 1000 requests
Finished 1000 requests


Server Software:
Server Hostname:        localhost
Server Port:            6060

Document Path:          /test
Document Length:        14 bytes

Concurrency Level:      100
Time taken for tests:   510.675 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      121000 bytes
HTML transferred:       14000 bytes
Requests per second:    1.96 [#/sec] (mean)
Time per request:       51067.452 [ms] (mean)
Time per request:       510.675 [ms] (mean, across all concurrent requests)
Transfer rate:          0.23 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   0.9      0       6
Processing:  5035 48195 8437.9  50501   55617
Waiting:     5034 48193 8438.6  50499   55612
Total:       5039 48196 8437.3  50502   55618
WARNING: The median and mean for the initial connection time are not within a normal deviation
        These results are probably not that reliable.

Percentage of the requests served within a certain time (ms)
  50%  50502
  66%  50505
  75%  50507
  80%  50509
  90%  50575
  95%  50627
  98%  55482
  99%  55547
 100%  55618 (longest request)
```

直接上结论，如果并发 100 是产品经理提出的要求，那么**这个系统生产不可用**

* 50% 的请求返回需要 50 秒
* 1000 请求完成需要 8 分钟
* 处理平均耗时 50秒
* 请求平均等待 50秒

#### 优化参数

实际上服务的请求处理耗时理论上应该是 SELECT SLEEP(5) FROM DUAL (模拟执行5秒)，但是从基准测试上看耗时远大于这个数。并且你可以通过日志查看到大部分 SQL 执行耗时确实是 5 秒。那么基本就可以确认性能瓶颈出现在吞吐上。

好吧，如果你的产品经理给你提出过性能指标，那么产品交付文档中应该指导交付团队配置合理参数

```properties
spring.datasource.hikari.minimum-idle=100 
spring.datasource.hikari.maximum-pool-size=100
server.undertow.threads.worker=200
```

再次测试

```shell
$ ab -c 100 -n 1000 http://localhost:6060/test
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking localhost (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Completed 400 requests
Completed 500 requests
Completed 600 requests
Completed 700 requests
Completed 800 requests
Completed 900 requests
Completed 1000 requests
Finished 1000 requests


Server Software:
Server Hostname:        localhost
Server Port:            6060

Document Path:          /test
Document Length:        14 bytes

Concurrency Level:      100
Time taken for tests:   81.252 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      121000 bytes
HTML transferred:       14000 bytes
Requests per second:    12.31 [#/sec] (mean)
Time per request:       8125.207 [ms] (mean)
Time per request:       81.252 [ms] (mean, across all concurrent requests)
Transfer rate:          1.45 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   1.1      0       8
Processing:  5023 7010 2292.8   5279   14751
Waiting:     5023 7007 2293.2   5276   14750
Total:       5023 7011 2292.7   5280   14751

Percentage of the requests served within a certain time (ms)
  50%   5280
  66%   9786
  75%   9844
  80%   9874
  90%   9939
  95%  10006
  98%  10221
  99%  10285
 100%  14751 (longest request)
```

调整参数后，可以看到这比较符合预期（因为单笔耗时是5秒）。

* 50% 的请求返回需要 5 秒
* 1000 请求完成需要 81 秒
* 处理平均耗时 5秒
* 请求平均等待 5秒

#### 真正的瓶颈

系统真正的瓶颈还是单比业务耗时，假设我们可以优化到单笔业务耗时 1 秒，那么可以得到如下基准报告

* 每秒能处理 58 笔请求
* 1000 笔请求可以在 16 秒处理完毕
* 90% 的请求都可以在 2 秒内处理完毕

```shell
$ ab -c 100 -n 1000 http://localhost:6060/test
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking localhost (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Completed 400 requests
Completed 500 requests
Completed 600 requests
Completed 700 requests
Completed 800 requests
Completed 900 requests
Completed 1000 requests
Finished 1000 requests


Server Software:
Server Hostname:        localhost
Server Port:            6060

Document Path:          /test
Document Length:        14 bytes

Concurrency Level:      100
Time taken for tests:   16.967 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      121000 bytes
HTML transferred:       14000 bytes
Requests per second:    58.94 [#/sec] (mean)
Time per request:       1696.661 [ms] (mean)
Time per request:       16.967 [ms] (mean, across all concurrent requests)
Transfer rate:          6.96 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   2.5      0      24
Processing:  1010 1469 324.6   1366    2469
Waiting:     1010 1466 324.9   1363    2469
Total:       1010 1470 324.4   1369    2472

Percentage of the requests served within a certain time (ms)
  50%   1369
  66%   1582
  75%   1721
  80%   1737
  90%   1952
  95%   2070
  98%   2316
  99%   2337
 100%   2472 (longest request)
```