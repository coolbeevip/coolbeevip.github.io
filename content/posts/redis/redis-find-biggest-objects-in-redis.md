---
title: "Find The Biggest Objects In Redis"
date: 2021-08-25T13:24:14+08:00
tags: [redis]
categories: [redis]
draft: false
---

在 REDIS 中一个字符串最大512MB，一个二级数据结构（例如hash、list、set、zset）可以存储大约40亿个(2^32-1)个元素，但实际上中如果下面两种情况，我就会认为它是 bigkeys。

* 字符串类型：单个 value 超过5MB
* 哈希、列表、集合、有序集合元素可数超过 10000

因为 REDIS 是单进程处理，所以对 BIGKEY 的访问会产生阻塞，如果你获取 100 次单体大小为 5MB 的 KEY，那么这些数据（500MB）传输到客户端就需要一定的时间，这期间其他命令都要排队等待。

## 查找 BIGKEY

使用 `bigkeys` 命令可以统计大对象（**建议在从结点执行**），为了方式阻塞，我们设置一个休眠参数 `-i 0.1`

```shell
redis-cli -h <ip> -p <port> -a <password> --bigkeys -i 0.1
```

结果如下：

```shell
$ redis-cli -h 192.168.51.207 -p 9015 --bigkeys

Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.

# Scanning the entire keyspace to find biggest keys as well as
# average sizes per key type.  You can use -i 0.1 to sleep 0.1 sec
# per 100 SCAN commands (not usually needed).

[00.00%] Biggest string found so far 'nc_oauth:access_to_refresh:82aa3bd2-ca90-4280-ba77-ff8285ad1b79' with 36 bytes
[00.00%] Biggest string found so far 'nc_oauth:refresh_auth:394cadfb-0658-4cdf-9945-2f3ed2943005' with 15521 bytes
[00.00%] Biggest string found so far '1:user_details::chengnan' with 159063 bytes
[00.10%] Biggest string found so far 'nc_oauth:refresh_auth:98401f58-6fa3-4140-876c-eb0203fe4a2f' with 173315 bytes
[00.33%] Biggest string found so far 'nc_oauth:auth:46199e17-2074-4bb1-8f02-72b866e9c91e' with 224152 bytes
[00.33%] Biggest set    found so far 'nc_oauth:uname_to_access:nc:vchenyuwei' with 4 members
[00.46%] Biggest string found so far '1:nc-um:function_node_details::SYS_USER-8a9e2d0d5d4fef7d015ec69a0eb0005a' with 403948 bytes
[01.23%] Biggest string found so far '1:nc-um:function_node_details::SYS_USER-8a9e2d0d5104019c01518fc4af27004f' with 655570 bytes
[01.41%] Biggest string found so far '1:nc-um:function_node_details::SYS_USER-8a9e2d0d61fb015c0163f705ca8400e2' with 1028627 bytes
[01.76%] Biggest set    found so far 'nc_oauth:uname_to_access:nc:vwulei6' with 11 members
[01.83%] Biggest set    found so far 'nc_oauth:uname_to_access:nc:vchengfanjiang' with 25 members
[04.20%] Biggest string found so far '1:nc-um:function_node_details::SYS_USER-8a993e736fac50a501720d688a252473' with 1344875 bytes
[04.34%] Biggest string found so far '1:nc-um:function_node_details::SYS_USER-8a993e736915883301695494cbe30a0e' with 1904333 bytes
[06.54%] Biggest set    found so far 'nc_oauth:uname_to_access:nc:lvyong' with 77 members
[12.05%] Biggest set    found so far 'nc_oauth:uname_to_access:nc:wangzhe4' with 93 members
[21.82%] Biggest set    found so far 'nc_oauth:uname_to_access:nc:robot' with 1824 members
[35.93%] Biggest string found so far '1:nc-um:function_node_details::c3ca9bc7122a4a16ab07f6626f320d86' with 1909348 bytes
[44.14%] Biggest set    found so far 'nc_oauth:client_id_to_access:nc' with 3178 members
[55.79%] Biggest string found so far '1:nc-um:function_node_details::4ae76cbc0a134470b0dd27120b576ac0' with 1909943 bytes

-------- summary -------

Sampled 30865 keys in the keyspace!
Total key length in bytes is 1797722 (avg len 58.24)

Biggest string found '1:nc-um:function_node_details::4ae76cbc0a134470b0dd27120b576ac0' has 1909943 bytes
Biggest    set found 'nc_oauth:client_id_to_access:nc' has 3178 members

0 lists with 0 items (00.00% of keys, avg size 0.00)
0 hashs with 0 fields (00.00% of keys, avg size 0.00)
30400 strings with 843125909 bytes (98.49% of keys, avg size 27734.40)
0 streams with 0 entries (00.00% of keys, avg size 0.00)
465 sets with 8157 members (01.51% of keys, avg size 17.54)
0 zsets with 0 members (00.00% of keys, avg size 0.00)
```

摘要中可以看到字符串类型和集合类型中两个最大的 KEY

```shell
Biggest string found '1:nc-um:function_node_details::4ae76cbc0a134470b0dd27120b576ac0' has 1909943 bytes
Biggest    set found 'nc_oauth:client_id_to_access:nc' has 3178 members
```
字符串类型大小 1909943 bytes (1.9MB)
集合类型包含 3178 个成员，使用 `MEMORY USAGE nc_oauth:client_id_to_access:nc` 命令可以看到大小为 25404114 bytes（24MB）

## 统计多个 KEY 大小

可以通过 Lua 脚本使用 `SCAN` 统计出名称匹配的 KEY，然后使用 `MEMORY USAGE` 获取每个 KEY 的大小

创建 memory-usage-pattern.lua 文件，并在脚本中定义了要统计的 KEY `1:nc-um:function_node_details:*`

```lua
-- 定义 KEY 模糊匹配
local pattern="1:nc-um:function_node_details:*"

local resp=redis.call('SCAN',0,'MATCH',pattern,'COUNT',999999)
local nextCursor=tonumber(resp[1])
local dataList=resp[2]
local totalsize=0
local counter=0;
for i=1,#dataList do
 local k = dataList[i]
 local keysize = redis.call('MEMORY','USAGE',k)
 counter=counter+1
 totalsize=totalsize+keysize
end
return {nextCursor, counter, totalsize}
```

使用以下命令可以查看符合条件的 KEY 共使用了多少内存，这个命令返回三个结果，

1) 游标位置，如果游标位置为 0 表示已经遍历完毕，否则请调整脚本中 `999999` 为更大的数
2) 符合条件 KEY 的数量
3) 服务条件 KEY 的内存占用

```shell
$ redis-cli -h 192.168.51.207 -p 9015 --eval memory-usage-pattern.lua
1) (integer) 0
2) (integer) 3403
3) (integer) 264671287
```

可以看到占用内存 264671287 byte(252MB)