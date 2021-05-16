---
title: "To roll up Flyway incremental changes into 1 file"
date: 2018-11-29T13:24:14+08:00
tags: [java, flyway]
categories: [java]
draft: false
---

Flyway 通过 SQL Patch 脚本的方式管理数据库脚本版本，开发一段时间后会积攒大量脚本。当一个版本稳定后我们希望合并成一个全量脚本

## 1.首先对齐程序与数据库中的脚本版本号

查看程序中脚本版本清单，例如：程序中有三个版本的脚本

```
V1.0.0.0__init.sql
V1.0.0.1__add_user_table.sql
V1.0.0.2__modify_user_table.sql
```

查看数据库中历史版本记录表 (默认是 `flyway_schema_history`) 中执行过的脚本版本，例如：

| versions | description | script  | success                |
| -------- | ----------- | --------| ---------------------- |
| 1.0.0.0  | init.sql    | V1.0.0.0__init.sql | 1 |
| 1.0.0.1  | add_user_table.sql  | V1.0.0.1__add_user_table.sql   | 1 |
| 1.0.0.2  | modify_user_table | V1.0.0.2__modify_user_table.sql | 1 |

这里只摘取了关键字段，你可以看到每个版本都已经执行，并且执行都是成功的 `success=1`

**至此：你已经对齐了程序和数据库中脚本版本号，可以开始准备合并了**

## 2.合并程序中的SQL脚本

合并多个脚本的内容到最大版本号的文件中，例如：将 `V1.0.0.0__init.sql`, `V1.0.0.1__add_user_table.sql`, `V1.0.0.2__modify_user_table.sql` 合并为 `V1.0.0.2__init.sql`

**注意：** 不是简单的文件合并，而是最终执行结果的合并

## 3.重新打包程序

只包含合 `V1.0.0.2__init.sql` 脚本的程序

## 4.停止所有老版本的程序

包含 `V1.0.0.0__init.sql`,`V1.0.0.1__add_user_table.sql`,`V1.0.0.2__modify_user_table.sql` 老脚本的程序

## 5.删除数据库中的版本历史表

默认是 `flyway_schema_history`

## 6.重启应用程序

在程序启动时设置基线版本参数为当前版本，设置这个参数的目的是告诉 Flyway 当前已经执行过 1.0.0.2 脚本了。这之前的脚本不要再执行了。

```properties
flyway.baseline-version=1.0.0.2
```

**注意：** 如果是空库，全新安装程序，那么则不需要设置 `flyway.baseline-version` 参数 

## 7.结束

查看数据库中历史版本记录表 (默认是 `flyway_schema_history`) 中执行过的脚本版本，例如：

| versions | description | script  | success                |
| -------- | ----------- | --------| ---------------------- |
| 1.0.0.2  | << Flyway Baseline >> | << Flyway Baseline >> | 1 |

至此：版本合并已经结束，后续再开发是数据库脚本的版本号从 `V1.0.0.3__xxx` 开始