---
title: "在 AWS 上搭建 WireGuard 并在 macOS 上连接"
date: 2026-06-26T00:24:14+08:00
tags: [wireguard,aws,macos,vpn]
categories: [vpn]
draft: false
---

本文记录如何在 Amazon Lightsail 上搭建 WireGuard VPN，并使用 macOS 客户端连接。示例使用 **Debian 13 (Trixie)**，VPN 网段使用 `10.66.66.0/24`，WireGuard 监听 UDP `58222`。

## 适用场景

* 需要一个轻量、配置简单的个人 VPN
* 使用 Amazon Lightsail VPS 作为公网入口
* macOS 通过 WireGuard 官方客户端连接
* 希望所有流量都走 VPN，或者只让指定网段走 VPN

## 一、Lightsail 准备

### 1. 创建 Lightsail 实例

建议配置：

| 项目 | 建议值 |
| --- | --- |
| Platform | Linux/Unix |
| Blueprint | Debian 13 (Trixie) |
| Plan | 1 GB 内存以上 |
| Storage | 8 GB 以上 |
| Public IP | 建议绑定 Lightsail Static IP |

如果只是个人使用，最低配通常已经足够。建议创建后立即绑定 Static IP，避免实例 stop/start 后公网 IP 变化。

### 2. 配置 Lightsail 防火墙

在 Lightsail 实例页面进入：

```
Networking
  -> IPv4 Firewall
  -> Add rule
```

入站规则至少需要：

| Type | Protocol | Port | Source | 说明 |
| --- | --- | --- | --- | --- |
| SSH | TCP | 22 | 你的公网 IP/32 | 管理服务器 |
| Custom UDP | UDP | 58222 | 你的公网 IP/32 或 `0.0.0.0/0` | WireGuard |

如果你的客户端网络经常变化，WireGuard 端口可以临时放开到 `0.0.0.0/0`。SSH 不建议对全网开放。这里的 `58222` 是示例端口，需要和安装脚本中选择的 WireGuard 端口保持一致。

Lightsail 防火墙只控制进入实例公网 IP 的流量，出站流量默认允许。本文只配置 IPv4，如果你给实例开启了 IPv6，并希望客户端也走 IPv6，需要在 IPv6 Firewall 中单独添加规则。

### 3. 绑定 Static IP

在 Lightsail 控制台进入：

```
Networking
  -> Create static IP
  -> 选择和实例相同的 Region
  -> Attach to an instance
```

后续 macOS 客户端配置中的 `<LIGHTSAIL_STATIC_IP>` 就使用这个静态公网 IP。

## 二、安装 WireGuard 和执行安装脚本

SSH 登录 Lightsail Debian 实例：

```shell
ssh admin@<LIGHTSAIL_STATIC_IP>
```

Lightsail 的 Debian 系统默认用户通常是 `admin`。如果你的实例镜像显示了不同的默认用户，以 Lightsail 控制台的 SSH 连接信息为准。

Debian 13 默认没有预装 WireGuard，先安装 WireGuard 内核模块相关包和命令行工具：

```shell
sudo apt update
sudo apt install -y curl wireguard wireguard-tools
wg --version
```

如果 `wg --version` 能正常输出版本号，说明 `wg` 命令已经可用。

下载 angristan 的 WireGuard 一键安装脚本：

```shell
curl -O https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
chmod +x wireguard-install.sh
sudo ./wireguard-install.sh
```

脚本会交互式询问服务端和客户端配置。个人使用可以按下面的思路填写：

| 配置项 | 建议 |
| --- | --- |
| IPv4 or IPv6 public address | 使用 Lightsail Static IP |
| Public interface | 使用默认检测结果，通常是 `ens5` 或 `eth0` |
| WireGuard port | `58222` |
| Client name | 例如 `macos` |
| Client WireGuard IPv4 | 使用脚本默认值 |
| DNS server | 可选 Cloudflare、Google、AdGuard 或系统默认 DNS |

安装完成后，脚本会生成客户端配置文件，通常位于当前用户目录下，例如：

```text
/home/admin/wg0-client-macos.conf
```

后续在 macOS 上导入这个 `.conf` 文件即可连接，不需要手动生成客户端密钥，也不需要手写客户端配置。

## 三、查看服务端配置

脚本会自动完成以下工作：

* 生成服务端私钥和公钥
* 生成客户端私钥和公钥
* 创建 `/etc/wireguard/wg0.conf`
* 为客户端生成可直接导入的 `.conf` 文件
* 配置 NAT 转发规则
* 创建并启动 `wg-quick@wg0` systemd 服务

一般不需要手动编辑 `/etc/wireguard/wg0.conf`。如果需要确认脚本生成了什么，可以用下面的命令查看：

```shell
sudo cat /etc/wireguard/wg0.conf
sudo systemctl status wg-quick@wg0
sudo wg show
```

确认系统外网网卡名称：

```shell
ip route | grep default
```

Lightsail Debian 常见输出：

```text
default via 172.31.0.1 dev ens5 proto dhcp src 172.31.1.10 metric 100
```

这里的外网网卡就是 `ens5`。也有系统可能显示为 `eth0`，如果后续排查 NAT 规则，需要以这条命令显示的网卡名称为准。

> 私钥不要提交到 Git，也不要发送给不可信的人。使用脚本时，服务端和客户端私钥都会自动写入对应配置文件，正常情况下不需要手动复制私钥。

## 四、IP 转发

一键脚本通常会自动开启 IP 转发。可以用下面的命令确认：

```shell
sudo sysctl net.ipv4.ip_forward
```

如果输出不是 `net.ipv4.ip_forward = 1`，手动开启：

```shell
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl --system
```

如果你只使用 IPv4，可以不配置 IPv6。若需要 IPv6 转发，还要额外配置 `net.ipv6.conf.all.forwarding=1`，并在 Lightsail、WireGuard 和系统防火墙中同时处理 IPv6。

## 五、启动和检查服务端

脚本安装完成后通常已经启动 WireGuard。确认服务状态：

```shell
sudo systemctl enable --now wg-quick@wg0
sudo systemctl status wg-quick@wg0
sudo wg show
```

如果启动失败，优先检查：

* 如果手动改过 `/etc/wireguard/wg0.conf`，私钥、公钥是否填反
* `PostUp` / `PostDown` 中的网卡名称是否正确
* Lightsail IPv4 Firewall 是否放行脚本中选择的 UDP 端口，例如 `58222`

## 六、配置 macOS 客户端

### 1. 安装 WireGuard

在 macOS App Store 安装 WireGuard 官方客户端：

```
https://apps.apple.com/us/app/wireguard/id1451685025
```

### 2. 导入脚本生成的配置

安装脚本结束时会生成客户端配置文件，例如：

```text
/home/admin/wg0-client-macos.conf
```

把它下载到 macOS：

```shell
scp admin@<LIGHTSAIL_STATIC_IP>:/home/admin/wg0-client-macos.conf .
```

然后在 WireGuard 客户端中选择：

```
Import tunnel(s) from file...
```

导入 `wg0-client-macos.conf` 后点击 `Activate`。

### 3. Full tunnel 与 Split tunnel

脚本生成的客户端配置中，关键是 `[Peer]` 里的 `AllowedIPs`。

如果配置是 full tunnel：

```ini
AllowedIPs = 0.0.0.0/0
```

这表示 macOS 的 IPv4 流量都会走 WireGuard。

如果只希望访问 VPN 网段走 WireGuard，例如只访问 WireGuard 服务器或 VPN 内部资源，可以把客户端配置改成：

```ini
AllowedIPs = 10.66.66.0/24
```

如果还要访问 Lightsail 私有网络网段，例如私有网段是 `172.26.0.0/16`，可以写成：

```ini
AllowedIPs = 10.66.66.0/24, 172.26.0.0/16
```

## 七、验证连接

在 macOS 连接 VPN 后，先测试 WireGuard 内网地址：

```shell
ping 10.66.66.1
```

测试公网出口 IP：

```shell
curl https://ifconfig.me
```

如果使用 full tunnel，返回结果应该是 Lightsail 的公网 IP。

在服务器上查看握手状态：

```shell
sudo wg show
```

正常情况下可以看到类似：

```text
peer: <MACOS_PUBLIC_KEY>
  endpoint: <CLIENT_PUBLIC_IP>:<PORT>
  allowed ips: 10.66.66.2/32
  latest handshake: 20 seconds ago
  transfer: 10.2 KiB received, 4.3 KiB sent
```

## 八、增加更多客户端

脚本会为每个客户端生成独立密钥和独立 VPN IP。不要在多台设备之间复用同一个 `.conf` 文件。

再次执行安装脚本：

```shell
sudo ./wireguard-install.sh
```

如果服务器已经安装过 WireGuard，脚本会进入管理菜单。选择添加新客户端，然后输入新的客户端名称，例如：

```text
iphone
```

脚本会生成新的客户端配置文件，例如：

```text
/home/admin/iphone.conf
```

下载到 macOS 后导入 WireGuard：

```shell
scp admin@<LIGHTSAIL_STATIC_IP>:/home/admin/iphone.conf .
```

服务端配置会自动追加新的 `[Peer]`，可以用下面的命令确认：

```shell
sudo wg show
```

## 九、常见问题

### 1. macOS 显示已连接，但无法访问互联网

检查以下项目：

* `sudo sysctl net.ipv4.ip_forward` 是否输出 `net.ipv4.ip_forward = 1`
* `PostUp` 中 `-o ens5` 的网卡名称是否正确
* Lightsail IPv4 Firewall 是否放行脚本中选择的 UDP 端口，例如 `58222`
* 服务器上执行 `sudo wg show` 是否能看到 `latest handshake`

### 2. 没有 latest handshake

通常是网络或密钥问题：

* macOS `Endpoint` 的 IP 和端口是否正确
* Lightsail IPv4 Firewall 是否放行脚本中选择的 UDP 端口，例如 `58222`
* 客户端配置中的 `Endpoint` 端口是否和服务端 `/etc/wireguard/wg0.conf` 中的 `ListenPort` 一致
* 如果手动改过配置，服务端 `[Peer] PublicKey` 是否填的是客户端公钥
* 如果手动改过配置，客户端 `[Peer] PublicKey` 是否填的是服务端公钥

### 3. 只能 ping 通 10.66.66.1，不能访问公网

说明 WireGuard 隧道本身正常，问题在转发或 NAT：

```shell
sudo sysctl net.ipv4.ip_forward
sudo iptables -t nat -S
sudo iptables -S FORWARD
```

确认存在类似规则：

```text
-A POSTROUTING -o ens5 -j MASQUERADE
-A FORWARD -i wg0 -j ACCEPT
-A FORWARD -o wg0 -j ACCEPT
```

### 4. 重启后无法连接

确认服务已经开机启动：

```shell
sudo systemctl is-enabled wg-quick@wg0
sudo systemctl status wg-quick@wg0
```

如果没有启用：

```shell
sudo systemctl enable --now wg-quick@wg0
```

## 十、安全建议

* SSH 只允许自己的固定公网 IP 访问
* WireGuard 端口可以改成非默认端口，例如 `443/udp`、`8443/udp`
* 不要复用客户端配置文件，每台设备都通过脚本单独生成一个客户端
* 丢失设备后，删除服务端对应 `[Peer]` 并重启 WireGuard
* 定期升级系统：

```shell
sudo apt update
sudo apt upgrade -y
```

删除某个客户端时，再次执行脚本并选择删除客户端：

```shell
sudo ./wireguard-install.sh
```

## 参考资料

* WireGuard Quick Start: https://www.wireguard.com/quickstart/
* angristan/wireguard-install: https://github.com/angristan/wireguard-install
* WireGuard macOS App: https://apps.apple.com/us/app/wireguard/id1451685025
* Amazon Lightsail Firewall: https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-firewall-and-port-mappings-in-amazon-lightsail.html
* Amazon Lightsail Static IP: https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-static-ip-addresses-in-amazon-lightsail.html
