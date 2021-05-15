---
title: "Docker Commands"
date: 2019-02-06T13:24:14+08:00
tags: [docker,commands]
categories: [docker,commands]
draft: false
type: "post"
---

常用 Docker 命令记录

## 镜像

#### 删除所有镜像

```shell
docker rmi -f $(docker images | awk '{print $3}')
```

#### 删除所有 dangling 镜像

```shell
docker rmi -f $(docker images -a | grep "<none>" | awk '{print $3}') 
```

#### 导出镜像

```shell
docker save -o postgres_9.6.tar postgres:9.6
```

#### 导入镜像

```shell
docker load -i postgres_9.6.tar
```

## 容器

#### 删除所有 `Exited` 容器

```shell
docker rm $(docker ps -a | grep Exited | awk '{print $1}')
```

#### 停止并删除所有容器

```shell
docker stop  $(docker ps | awk '{print $1}')
docker rm -f  $(docker ps -a | awk '{print $1}')
```

#### 停止 dead 容器

删除实例时提示 device or resource busy

```shell
[root@jenkins233 ~]# docker rm 0d5871af9e3b
Error response from daemon: driver "overlay" failed to remove root filesystem for 0d5871af9e3be63589da2b6fbdd0cc112ac88bbc2b9a65372137e72acb06420d: remove /var/lib/docker/overlay/9fb10812222a3ba935dbedd2c9d83ad02d2bbb34cae10665d1b6b7bd52a9409b/merged: device or resource busy
```

查看那个进程占用设备

```shell
grep docker /proc/*/mountinfo | grep overlay
```

然后杀死进程

## 数据卷

#### 删除所有 dangling 数据卷

```shell
docker volume rm $(docker volume ls -qf dangling=true)
```

#### 删除所有数据卷

```shell
docker volume rm $(docker volume ls | awk '{print $2}')
```

#### 删除前 1000 个数据卷

```shell
docker volume rm $(docker volume ls | awk '{print $2}' | head -1000)
```

## 网络

#### 删除所有网络

```shell
docker network rm $(docker network ls | awk '{print $1}')
```

#### 创建容器网络

```shell
docker network create nc-network
```

#### 显示所有容器 IP 地址

```shell
docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
```

## 系统

#### 资源占用查看

```shell
docker system df
TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              29                  0                   9.786GB             9.786GB (100%)
Containers          0                   0                   0B                  0B
Local Volumes       83                  0                   11.99GB             11.99GB (100%)
Build Cache         0                   0                   0B                  0B
```

镜像占用了 9.786GB，容器占用 0，数据卷占用 11.99GB