---
title: "常用 Docker 命令"
date: 2021-04-06T13:24:14+08:00
draft: true
---

常用 Docker 命令记录

## 镜像

删除所有镜像

```shell
docker rmi -f $(docker images | awk '{print $3}')
```

删除所有 `<none>` 镜像

```shell
docker rmi -f $(docker images -a | grep "<none>" | awk '{print $3}') 
```

## 实例

删除所有 `Exited` 实例

```shell
docker rm $(docker ps -a | grep Exited | awk '{print $1}')
```

停止并删除所有实例

```shell
docker stop  $(docker ps | awk '{print $1}')
docker rm -f  $(docker ps -a | awk '{print $1}')
```

## 卷

删除所有卷 

```shell
docker volume rm $(docker volume ls | awk '{print $2}')
```

删除前 1000 个卷

```shell
docker volume rm $(docker volume ls | awk '{print $2}' | head -1000)
```

## 网络

删除所有网络

```shell
docker network rm $(docker network ls | awk '{print $1}')
```

创建容器网络

```shell
docker network create nc-network
```

显示所有容器 IP 地址

```shell
docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
```