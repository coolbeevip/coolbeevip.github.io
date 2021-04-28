---
title: "Flyway 补丁脚本合并成全量脚本的步骤"
date: 2018-11-29T13:24:14+08:00
categories: [java, flyway]
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

## 3.重启应用程序，设置基线版本

在程序启动时设置基线版本参数为当前版本，设置这个参数的目的是告诉 Flyway 当前已经执行过 1.0.0.2 脚本了。这之前的脚本不要再执行了。

```properties
flyway.baseline-version=1.0.0.2
```