---
title: "Run Docker without Docker Desktop on macOS"
date: 2022-02-14T13:24:14+08:00
tags: [minikube, macOS]
categories: [kubernetes]
draft: false
---

由于 Docker Desktop 修改了授权条款，不再对企业用户免费，所以我们需要啊寻求一种替代品。到目前为止 Minikube 已经成为 Docker Desktop 最简单的替代品。 Minikube 用于在本地环境中运行 Kubernetes 集群，但它也运行了一个可用于运行容器的 Docker 守护进程。如果你不需要使用 Kubernetes ，那么你可以通过 `minikube pause` 暂停 Kubernetes 相关镜像，从而解决系统资源。

在 macOS 上，Minikube 运行在很多虚拟化技术上，由于[ISSUE-6296](https://github.com/kubernetes/minikube/issues/6296)原因，本例使用 Virtualbox 方式（你需要先安装 Virtualbox）。

## 卸载 Docker Desktop for macOS

如果你之前安装过 Docker Desktop，那么你需要先卸载它

1. 在 Docker Desktop 菜单中选择 Troubleshoot 并且选择 Uninstall.
2. 删除 /Applications/Docker.app

## 安装 Docker CLI

因为卸载 Docker Desktop 后将自动卸载 Docker CLI，所以你需要单独安装

```shell
$ brew install docker
$ brew install docker-compose
```

**提示：** 在执行 `brew install docker-compose` 命令的时候可能得到如下的失败信息，这是因为依赖包下载失败。你可以使用 `brew install gdbm` 单独下载依赖包，就避免了找不到依赖版本的错误。

```shell
==> Installing dependencies for docker-compose: gdbm, mpdecimal, sqlite, xz and python@3.9
==> Installing docker-compose dependency: gdbm
==> Pouring gdbm-1.20.catalina.bottle.tar.gz
Error: No such file or directory @ rb_sysopen - /Users/zhanglei/Library/Caches/Homebrew/downloads/3a7181542ed14a53077d6b4cd5685859711691e0cb8029f0b49b159a47a7b999--gdbm-1.20.catalina.bottle.tar.gz
```

安装完毕后你可以看到 CLI 版本

```shell
$ docker -v
Docker version 20.10.8, build 3967b7d28e
$ docker-compose -v
docker-compose version 1.29.2, build unknown
```

## 安装 Minikube

你需要下载对应版本的安装介质，详细安装细节可以参考[官方文档](https://minikube.sigs.k8s.io/docs/start/)

安装

```shell
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
```

启动

```shell
$ minikube start \
--memory='4gb' \
--cpus='2' \
--disk-size='30gb' \
--driver=virtualbox \
--image-mirror-country='cn' \
--registry-mirror='https://registry.cn-hangzhou.aliyuncs.com,http://registry-private.com:8888' \
--insecure-registry='registry-private.com:8888'
```

**提示：** 使用  `minikube start help` 可以看到参数的详细说明

**提示：** 如果你不涉及使用VPN连接到工作网络，那么推荐使用 hyperkit 驱动，你需要使用 `brew install hyperkit` 命令先安装 Hyperkit 并且在启动命令中通过参数 `--driver=hyperkit` 启用 Hyperkit

**提示：** 你使用 Hyperkit 驱动启动时如果提示如下错误，那么可以手动下载 `https://github.com/kubernetes/minikube/releases/download/v1.24.0/docker-machine-driver-hyperkit` 文件到 `~/.minikube/bin` 目录下后再启动 Minikube

> 💾  正在下载驱动 docker-machine-driver-hyperkit:
❗  Unable to update hyperkit driver: download: getter: &{Ctx:context.Background Src:https://github.com/kubernetes/minikube/releases/download/v1.24.0/docker-machine-driver-hyperkit?checksum=file:https://github.com/kubernetes/minikube/releases/download/v1.24.0/docker-machine-driver-hyperkit.sha256 Dst:/Users/zhanglei/.minikube/bin/docker-machine-driver-hyperkit.download Pwd: Mode:2 Umask:---------- Detectors:[0x40ae630 0x40ae630 0x40ae630 0x40ae630 0x40ae630 0x40ae630 0x40ae630] Decompressors:map[bz2:0x40ae630 gz:0x40ae630 tar:0x40ae630 tar.bz2:0x40ae630 tar.gz:0x40ae630 tar.xz:0x40ae630 tar.zst:0x40ae630 tbz2:0x40ae630 tgz:0x40ae630 txz:0x40ae630 tzst:0x40ae630 xz:0x40ae630 zip:0x40ae630 zst:0x40ae630] Getters:map[file:0xc000f1aa70 http:0xc0006d4860 https:0xc0006d4880] Dir:false ProgressListener:0x406ffd0 Insecure:false Options:[0x2448e00]}: invalid checksum: Error downloading checksum file: Get "https://github.com/kubernetes/minikube/releases/download/v1.24.0/docker-machine-driver-hyperkit.sha256": dial tcp 20.205.243.166:443: connect: connection refused

设置 Docker CLI 使用 Minikube 的 VM

```shell
$ eval $(minikube docker-env)
```

查看默认启动的容器

```shell
$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS     NAMES
a4e2ae0ed30f   6e38f40d628d           "/storage-provisioner"   2 minutes ago   Up 2 minutes             k8s_storage-provisioner_storage-provisioner_kube-system_1ee87471-9ac7-4dd0-90bb-3e6bd95af01a_2
b8b86bda2d56   8d147537fb7d           "/coredns -conf /etc…"   2 minutes ago   Up 2 minutes             k8s_coredns_coredns-78fcd69978-sfd6c_kube-system_1ca00abe-d487-4b3b-aca3-871a47e94724_1
a448c38496c4   6120bd723dce           "/usr/local/bin/kube…"   2 minutes ago   Up 2 minutes             k8s_kube-proxy_kube-proxy-5l45m_kube-system_a36c7041-31ed-4f76-b66f-8eaf6bd9a002_1
8878e549c80e   k8s.gcr.io/pause:3.5   "/pause"                 2 minutes ago   Up 2 minutes             k8s_POD_kube-proxy-5l45m_kube-system_a36c7041-31ed-4f76-b66f-8eaf6bd9a002_1
d5cd9d87efaa   k8s.gcr.io/pause:3.5   "/pause"                 2 minutes ago   Up 2 minutes             k8s_POD_storage-provisioner_kube-system_1ee87471-9ac7-4dd0-90bb-3e6bd95af01a_1
c8e099276f14   k8s.gcr.io/pause:3.5   "/pause"                 2 minutes ago   Up 2 minutes             k8s_POD_coredns-78fcd69978-sfd6c_kube-system_1ca00abe-d487-4b3b-aca3-871a47e94724_1
8bea4867b31e   004811815584           "etcd --advertise-cl…"   2 minutes ago   Up 2 minutes             k8s_etcd_etcd-minikube_kube-system_d3e8bd529aa2c19bd371c917d710530a_1
63b85c36bfad   53224b502ea4           "kube-apiserver --ad…"   2 minutes ago   Up 2 minutes             k8s_kube-apiserver_kube-apiserver-minikube_kube-system_c470a327a906a1c8b254f97177783990_1
4f31a201c1c8   05c905cef780           "kube-controller-man…"   2 minutes ago   Up 2 minutes             k8s_kube-controller-manager_kube-controller-manager-minikube_kube-system_cf61f8185359bbfecb994d4d92683b56_1
8b868aef92e4   0aa9c7e31d30           "kube-scheduler --au…"   2 minutes ago   Up 2 minutes             k8s_kube-scheduler_kube-scheduler-minikube_kube-system_eee9e2da42102bf0a05e1e7b00e318bf_1
f293391e8cc6   k8s.gcr.io/pause:3.5   "/pause"                 2 minutes ago   Up 2 minutes             k8s_POD_kube-apiserver-minikube_kube-system_c470a327a906a1c8b254f97177783990_1
1ffe327189ca   k8s.gcr.io/pause:3.5   "/pause"                 2 minutes ago   Up 2 minutes             k8s_POD_etcd-minikube_kube-system_d3e8bd529aa2c19bd371c917d710530a_1
1eb097cba9d0   k8s.gcr.io/pause:3.5   "/pause"                 2 minutes ago   Up 2 minutes             k8s_POD_kube-scheduler-minikube_kube-system_eee9e2da42102bf0a05e1e7b00e318bf_1
2f3b5bf3ae2b   k8s.gcr.io/pause:3.5   "/pause"                 2 minutes ago   Up 2 minutes             k8s_POD_kube-controller-manager-minikube_kube-system_cf61f8185359bbfecb994d4d92683b56_1
```

**提示：** minikube 启动时会默认启动 k8s 的容器，如果你不使用 k8s，你可以使用 `minikube pause` 命令暂停 k8s 相关的容器，这样可以节省一些系统资源。

## 验证环境

我们可以启动一个 Nginx 容器验证 Docker 环境

```shell
docker run --rm --name some-nginx -p 8080:80 nginx
```

区别于 Docker Desktop 的方式，Docker 环境是被安装在 VM 上的，所以你不能在使用宿主机的IP访问容器，你可以使用 `minikube ip` 命令获取 VM 地址，并使用此地址访问 Nginx。或者也可以直接使用下边的写法

```shell
$ curl http://`minikube ip`:8080/
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## Minikube 备忘录

* minikube stop - 停止 VM 和 k8s 集群

* minikube delete --all --purge - 删除 VM 和 k8s 集群

* minikube ip - 查看 VM 的 IP 地址

* minikube pause - 暂停 k8s 相关的容器

* minikube unpause - 取消暂停 k8s 相关的容器

* minikube ssh - 登入 VM
