---
title: "在 AWS 搭建 ChatGPT 使用环境"
date: 2023-05-30T00:24:14+08:00
tags: [chatgpt,ai,aws]
categories: [chatgpt]
draft: false
---

AWS Lightsail 配合 Cloudflare WARP，使 [Griseo](https://github.com/korandoru/griseo) 在远程主机通过命令行使用 ChatGPT

## 背景

你可以使用 `curl ipinfo.io` 命令查看你的 IP 地址，通常 AWS 服务器的 org 会显示 Amazon.com, 此时你是无法访问 chat.openai.com 的。我们需要使用 Cloudflare 让被访问网站认为访问来自于“原生IP”

```shell
curl ipinfo.io
{
  "ip": "xxxx",
  "hostname": "xxxx",
  "city": "Tokyo",
  "region": "Tokyo",
  "country": "JP",
  "loc": "xxx",
  "org": "XXXX Amazon.com, Inc.",
  "postal": "xxx-xxxx",
  "timezone": "Asia/Tokyo",
  "readme": "https://ipinfo.io/missingauth"
}
```

## Cloudflare Warp 代理模式

> 通过在服务器本机启动一个 SOCKS5 代理，然后把需要的流量转发到这个代理上

#### 安装软件包

以 Debian 举例，添加安装源

```
sudo apt install curl
curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
```

添加完源后，安装 Cloudflare WARP 客户端：

```shell
sudo apt update
sudo apt install cloudflare-warp
```

#### 配置 Cloudflare WARP

如果是第一次安装，你需要先注册一个帐号。其注册信息会在这里/var/lib/cloudflare-warp/reg.json

```shell
warp-cli register
```

然后设置代理模式，这点非常重要，因为默认是 WARP 模式，这个会把你的整个 VPS 带到 Cloudflare 的 VPN 网络中，那么就会出现无法连接的情况

```shell
warp-cli set-mode proxy
```

然后，设置永久连接模式。

```shell
warp-cli enable-always-on
```

配置完后，你可以使用 warp-cli settings 来查看配置。你也可以通过查看配置文件来看是否配置成功，配置文件在 /var/lib/cloudflare-warp/settings.json

#### 连接 Cloudflare WARP

使用如下命令来连接 Cloudflare WARP：

```shell
warp-cli connect
```

你可以使用 warp-cli status 来查看连接状态。如：

```shell
$ warp-cli status
Status update: Connected
Success
```

连接成功后，你可以会在本地有一个 Socks5 代理， 127.0.0.1:40000，你可以使用如下命令来查看：

```shell
curl -x "socks5://127.0.0.1:40000" ipinfo.ioo
{
  "ip": "xxx",
  "city": "Tokyo",
  "region": "Tokyo",
  "country": "JP",
  "loc": "xxx",
  "org": "XXXX Cloudflare, Inc.",
  "postal": "xxx-xxxx",
  "timezone": "Asia/Tokyo",
  "readme": "https://ipinfo.io/missingauth"
}
```

你可以看到 org 已经变成了 Cloudflare, Inc.

## 安装 Griseo

参考官方网站即可 https://github.com/korandoru/griseo

![griseo](/images/posts/ai/griseo.png)

