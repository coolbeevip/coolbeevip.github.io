---
title: "Setting up Redis for Production"
date: 2020-08-19T13:24:14+08:00
tags: [redis]
categories: [redis]
draft: false
---

## 安装

官方建议的安装方法是从源代码编译安装，您可以从 [redis.io](https://redis.io/) 下载最新稳定版的 TAR 包

```shell
wget https://download.redis.io/releases/redis-6.2.5.tar.gz
tar xvzf redis-6.2.5.tar.gz
cd redis-6.2.5
make
```

此时，您可以通过键入 `make test` 来测试您的构建是否正常工作。编译后 `redis-6.2.5/src` 目录填充了一部分可执行文件。
最好将编译后的 Redis 执行文件都复制到适当的位置，或者使用以下命令手动复制（假设我们的安装路径是 /usr/local/redis）：

```shell
# 可执行文件
sudo mkdir -p /usr/local/redis/bin
sudo cp src/redis-server /usr/local/redis/bin
sudo cp src/redis-cli /usr/local/redis/bin
sudo cp src/redis-sentinel /usr/local/redis/bin
sudo cp src/redis-benchmark /usr/local/redis/bin
sudo cp src/redis-check-aof /usr/local/redis/bin
sudo cp src/redis-check-rdb /usr/local/redis/bin
# 配置文件
sudo mkdir -p /usr/local/redis/conf
sudo cp redis.conf /usr/local/redis/conf
sudo cp sentinel.conf /usr/local/redis/conf
# 数据目录
sudo mkdir -p /usr/local/redis/data
sudo mkdir -p /usr/local/redis/log
# 创建链接
sudo ln -s /usr/local/redis/bin/redis-server /usr/bin/redis-server
sudo ln -s /usr/local/redis/bin/redis-cli /usr/bin/redis-cli
```

**提示：** 复制完毕后，您可以删除 redis-6.2.5.tar.gz 和 解压后的 redis-6.2.5 目录

## 启动

执行 redis-server 文件并指定 redis.conf 参数

```shell
$ redis-server /usr/local/redis/conf/redis.conf
29212:C 19 Aug 2021 15:01:44.882 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
29212:C 19 Aug 2021 15:01:44.882 # Redis version=6.2.5, bits=64, commit=00000000, modified=0, pid=29212, just started
29212:C 19 Aug 2021 15:01:44.882 # Configuration loaded
29212:M 19 Aug 2021 15:01:44.883 * monotonic clock: POSIX clock_gettime
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 6.2.5 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 29212
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           https://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

29212:M 19 Aug 2021 15:01:44.885 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
29212:M 19 Aug 2021 15:01:44.885 # Server initialized
29212:M 19 Aug 2021 15:01:44.885 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
29212:M 19 Aug 2021 15:01:44.886 * Ready to accept connections
```

## 检查 Redis 是否工作正常

使用 `ping` 命令检查服务是否正常返回 'PONG'

```shell
$ redis-cli -h 127.0.0.1 -p 6379 ping
PONG
```

我们还可以通过运行 Redis Benchmark 进行快速检查。它不仅会对 Redis 本身进行压力测试，还会验证我们的安装是否有任何问题。下面将发出来自 50 个客户端的 100000 个请求，同时发送 12 个命令

```shell
$ /usr/local/redis/bin/redis-benchmark -h 127.0.0.1 -p 16379 -q -n 100000 -c 50 -P 12
PING_INLINE: 347250.00 requests per second, p50=0.743 msec
PING_MBULK: 463000.00 requests per second, p50=0.591 msec
SET: 510244.91 requests per second, p50=0.639 msec
GET: 492650.25 requests per second, p50=0.583 msec
INCR: 526357.88 requests per second, p50=0.575 msec
LPUSH: 495089.09 requests per second, p50=0.935 msec
RPUSH: 456657.53 requests per second, p50=0.735 msec
LPOP: 350905.28 requests per second, p50=0.991 msec
RPOP: 502552.75 requests per second, p50=0.711 msec
SADD: 534802.12 requests per second, p50=0.591 msec
HSET: 531957.44 requests per second, p50=0.759 msec
SPOP: 529142.88 requests per second, p50=0.575 msec
ZADD: 321569.16 requests per second, p50=1.359 msec
ZPOPMIN: 404890.69 requests per second, p50=0.639 msec
LPUSH (needed to benchmark LRANGE): 303054.53 requests per second, p50=1.375 msec
LRANGE_100 (first 100 elements): 66761.02 requests per second, p50=4.303 msec
LRANGE_300 (first 300 elements): 19651.80 requests per second, p50=15.047 msec
LRANGE_500 (first 500 elements): 10563.85 requests per second, p50=28.623 msec
LRANGE_600 (first 600 elements): 9882.21 requests per second, p50=24.927 msec
MSET (10 keys): 194947.36 requests per second, p50=2.775 msec
```

## 操作系统配置

在刚才的启动中你可以看到两个警告

* WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.

编辑 `/etc/sysctl.conf` 添加 `net.core.somaxconn=2048`，然后在终端执行 `sysctl -p`

* WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.

编辑 `/etc/sysctl.conf` 添加 `vm.overcommit_memory=1`，然后在终端执行 `sysctl -p`

## Redis 配置

Redis 附带了一个非常合理且包含大量注释的配置文件。查看 /usr/local/redis/conf/redis.conf 文件并逐步完成一下配置。

#### 绑定地址

您需要配置绑定地址，否则这个 Redis 无法在外部访问，如果服务器有多个网卡地址，都需要支持外部访问，那么可配置成 `0.0.0.0`。**Redis通常作为内部服务使用，建议通过防火墙控制访问策略**

```shell
bind 0.0.0.0 -::/0
```

**提示：** `::/0` 是 IPv6 的写法

#### 端口

我建议你修改默认端口 `6379`，这可以避免基于默认端口的漏洞扫描

```shell
port 65379
```

#### 工作目录

RDB 和 AOF 的数据文件都会存储到这个目录

```shell
dir /usr/local/redis/data
```

#### 日志

配置日志存储位置

```shell
logfile "/usr/local/redis/log/redis-server.log"
```

#### PID 位置

定义 PID 文件存储位置

```shell
pidfile /usr/local/redis/redis.pid
```

#### 开启守护进程模式

Redis 会在后台运行，并将进程 PID 号写入至 redis.conf 选项 pidfile 设置的文件中，此时 redis 将一直运行，除非手动kill该进程

```shell
daemonize yes
```

#### 内存

请根据业务实际需要配置合理的内存，以下配置的是 2GB

```shell
maxmemory 2gb
```

**提示：** 当超过 maxmemory 内存时，Redis 有多种处理策略，默认策略是不驱逐(maxmemory-policy noeviction)，这时会提示 OOM。如果你将 Redis 当作缓存来使用，并且丢失一个部分数据也不会影响你的业务，那么建议使用其他策略。   

#### 危险指令

重命名一些危险指令，重命名这些命令前请和业务侧确认

```shell
rename-command config "config_do"
rename-command flushall "flushall_do"
rename-command flushdb "flushdb_do"
rename-command shutdown "shutdown_do"
```

#### 持久化 

> 如果你的 Redis 用作缓存存储，并且您根本不介意丢失其数据，那么请忽略此章节。

配置 RDB 模式的快照数据存储位置，Redis 会定期将其数据集转储到文件中，使其成为备份的理想选择。

```shell
dbfilename dump.rdb
```

配置 RDB 快照频率，您可以使用多个这些语句来使您的快照更加精细。请注意，配置文件中已经有一些这样的语句。

```shell
# 每 900 秒（15分钟）至少 1 个 KEY 变化，写入 RDB
save 900 1
# 每 300 秒（5分钟）至少 10 个 KEY 变化，写入 RDB
save 300 10
# 每 60 秒（1分钟）至少 10000 个 KEY 变化，写入 RDB
save 60 10000
```

开启 AOF 并配置文件存储位置，用于记录写入操作日志，及时你的机器崩溃，您仍然可以恢复并拥有最新数据

```shell
appendonly yes
appendfilename "appendonly.aof"
```

因为操作系统维护一个输出缓冲区，成功写入并不一定意味着数据会立即写入（刷新）到磁盘。为了告诉操作系统真正将数据写入磁盘，Redis 需要在写入调用后立即调用 fsync() 函数，这可能会很慢。所以 Redis 提供了 3 个选项：

* **no:** 不调用 `fsync()`，依靠操作系统在需要的时候刷新，写入速度快
* **always:** 每次写 AOF 后都调用 `fsync()`，慢但是安全
* **everysec:** 美妙调用 `fsync()`，这是默认选型

请根据您的业务情况自行评估使用哪种方式，如果你要严格的数据可靠性，则可以设置 `appendfsync always`

```shell
appendfsync everysec
```

## 安全

## 可靠停止服务

您可以在持久化章节了解 Redis 持久化的工作原理，如果您使用默认配置启动 Redis，Redis 只会不时自发地保存数据集（例如如果您的数据至少有 100 次更改，则至少需要五分钟），因此如果您希望数据库在重启后持久保存并重新加载，请确保每次要强制执行数据集快照时手动调用 SAVE 命令。否则请确保使用 SHUTDOWN 命令关闭数据库

```shell
$ redis-cli -h 127.0.0.1 -p 65379 shutdown
```

## 增加到系统服务

将 Redis 发行版中 utils 目录下的找到的 redis_init_script 脚本复制到 /etc/init.d 中。我们建议使用 `redis_端口号` 重命名这个文件

```shell
sudo cp utils/redis_init_script /etc/init.d/redis_65379
```

编辑 `/etc/init.d/redis_65379` 文件

```shell
# 配置端口号
REDISPORT=65379
# 定义执行文件路径
EXEC=/usr/local/redis/bin/redis-server
CLIEXEC=/usr/local/redis/bin/redis-cli
# PID 存储路径
PIDFILE=/usr/local/redis/redis.pid
# 配置文件路径
CONF="/usr/local/redis/conf/redis.conf"
```

最后使用以下命令将新的 Redis init 脚本添加到所有默认运行级别

```shell
sudo update-rc.d redis_6379 defaults
```

你完成了！现在您可以尝试使用以下命令运行您的实例

```shell
sudo /etc/init.d/redis_65379 start
```

## 监控

除了传统的磁盘空间监控和、CPU 监控外，我们更加需要关注内存的使用，你可以使用 `redis-cli -h 127.0.0.1 -p 65379 info memory` 命令查看内存使用情况

```shell
used_memory:872024
maxmemory:2147483648
```

通常你需要关注已用内存的占比，当达到一定阀值时就表示可能内存不够用了

```
内存使用率(%) = used_memory / maxmemory * 100
```

## 备份

如配置部分所述，Redis 提供了非常适合进行备份的 RDB 快照。 
RDB 文件包含您存储的每一条数据，因此您可以安全地只备份 RDB 文件，并在发生事故时能够恢复。

```shell
cp /usr/local/redis/data/dump.rdb /somewhere/backup/dump.$(date +%Y%m%d%H%M).rdb
```

这很简单。您可以在服务器仍在运行时执行此操作。作为安全预防措施，您应该考虑在将文件上传到外部存储之前对其进行加密。自动化该过程的合理方法是通过 cron 任务

## 恢复

现在让我们假设发生了意外（例如有人删除了一些数据），我们想从这些 RDB 快照备份中恢复数据集的先前版本。是否启用 AOF 会导致恢复的步骤稍有不同

#### 只开启了 RDB

这种方式恢复非常简单

1. 停止 Redis 服务
2. 删除 /usr/local/redis/data/dump.rdb 文件
3. 使用备份的 dump.rdb 文件覆盖到 /usr/local/redis/data 目录下
4. 启动 Redis 服务

#### RDB + AOF

使用 AOF，这个过程会更复杂一些。当 Redis 启动时，它会将 AOF 日志视为主要信息来源，因为它始终具有可用的最新数据。
问题是，如果我们只有 RDB 快照而没有 AOF 日志（或者我们有日志但被事故影响无法使用），Redis仍然会使用AOF日志作为唯一的数据源。并且由于日志丢失，它根本不会加载任何数据并创建一个新的空快照文件。

1. 停止 Redis 服务
2. 删除 /usr/local/redis/data/dump.rdb 、/usr/local/redis/aof/appendonly.aof 文件
3. 使用备份的 dump.rdb 文件覆盖到 /usr/local/redis/data 目录下
4. 修改 /usr/local/redis/conf/redis.conf 配置文件，禁用 AOF `appendonly no`
5. 启动 Redis 服务
6. 执行 `redis-cli BGREWRITEAOF`，这可能需要一些时间，您可以通过 `redis-cli info | grep aof_rewrite_in_progress` 值来检查进度（0 - 完成，1 - 尚未）
7. `BGREWRITEAOF` 命令执行完毕后你可以看到一个全新的 `/usr/local/redis/aof/appendonly.aof` 文件
8. 停止 Redis 服务
9. 修改 /usr/local/redis/conf/redis.conf 配置文件，启用 AOF `appendonly yes`
10. 启动 Redis 服务

**在 RDB + AOF 情况下，我们也可以直接备份 AOF 文件，不过这个文件通常很大，除非你不需要为磁盘空间担心**
