---
title: "在 AWS 搭建 VPN"
date: 2023-05-30T00:24:14+08:00
tags: [openvpn,aws]
categories: [vpn]
draft: false
---

## 下载安装程序脚本

```shell
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh
```

## 执行安装

执行安装脚本，端口建议改为 443（你所在的局域网客户端通常不会阻止 443 出口）

```shell
$ ./openvpn-install.sh
Welcome to the OpenVPN installer!
The git repository is available at: https://github.com/angristan/openvpn-install

I need to ask you a few questions before starting the setup.
You can leave the default options and just press enter if you are ok with them.

I need to know the IPv4 address of the network interface you want OpenVPN listening to.
Unless your server is behind NAT, it should be your public IPv4 address.
IP address: x.x.x.x <-- 此处输入公网 IP 地址

Checking for IPv6 connectivity...

Your host appears to have IPv6 connectivity.

Do you want to enable IPv6 support (NAT)? [y/n]: y <-- 此处支持 IPv6

What port do you want OpenVPN to listen to?
   1) Default: 1194
   2) Custom
   3) Random [49152-65535]
Port choice [1-3]: 2
Custom port [1-65535]: 443 
```

协议选择 TCP（UDP 443 有可能在限制比较多的局域网中被阻止）

```shell
What protocol do you want OpenVPN to use?
UDP is faster. Unless it is not available, you shouldn't use TCP.
   1) UDP
   2) TCP
Protocol [1-2]: 2
```

选择一个 DNS

```shell
What DNS resolvers do you want to use with the VPN?
   1) Current system resolvers (from /etc/resolv.conf)
   2) Self-hosted DNS Resolver (Unbound)
   3) Cloudflare (Anycast: worldwide)
   4) Quad9 (Anycast: worldwide)
   5) Quad9 uncensored (Anycast: worldwide)
   6) FDN (France)
   7) DNS.WATCH (Germany)
   8) OpenDNS (Anycast: worldwide)
   9) Google (Anycast: worldwide)
   10) Yandex Basic (Russia)
   11) AdGuard DNS (Anycast: worldwide)
   12) NextDNS (Anycast: worldwide)
   13) Custom
DNS [1-12]: 11
```

选择不压缩

```shell
Do you want to use compression? It is not recommended since the VORACLE attack makes use of it.
Enable compression? [y/n]: n
```

选择不设置加密策略

```shell
Do you want to customize encryption settings?
Unless you know what you're doing, you should stick with the default parameters provided by the script.
Note that whatever you choose, all the choices presented in the script are safe. (Unlike OpenVPN's defaults)
See https://github.com/angristan/openvpn-install#security-and-encryption to learn more.

Customize encryption settings? [y/n]: n 
```

看到如下提示后，按任意键后继续安装

```shell
Okay, that was all I needed. We are ready to setup your OpenVPN server now.
You will be able to generate a client at the end of the installation.
Press any key to continue...
```


添加一个新客户端

```shell
Tell me a name for the client.
The name must consist of alphanumeric character. It may also include an underscore or a dash.
Client name: coolbeevip

Do you want to protect the configuration file with a password?
(e.g. encrypt the private key with a password)
   1) Add a passwordless client
   2) Use a password for the client
Select an option [1-2]: 1
```

安装完成后，你将看到如下提示。下载 /home/admin/coolbeevip.ovpn 文件到你的客户端，倒入 OpenVPN Client 后就可以使用了。

```shell
* Using SSL: openssl OpenSSL 1.1.1n  15 Mar 2022

* Using Easy-RSA configuration: /etc/openvpn/easy-rsa/vars

* The preferred location for 'vars' is within the PKI folder.
  To silence this message move your 'vars' file to your PKI
  or declare your 'vars' file with option: --vars=<FILE>
Generating an EC private key
writing new private key to '/etc/openvpn/easy-rsa/pki/806f7e5f/temp.cab3ff4c'
-----

Notice
------
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/easy-rsa/pki/reqs/coolbeevip.req
key: /etc/openvpn/easy-rsa/pki/private/coolbeevip.key
Using configuration from /etc/openvpn/easy-rsa/pki/806f7e5f/temp.6d51dbc3
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'coolbeevip'
Certificate is to be certified until Sep  7 10:13:42 2025 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Notice
------
Certificate created at:
* /etc/openvpn/easy-rsa/pki/issued/coolbeevip.crt

Notice
------
Inline file created:
* /etc/openvpn/easy-rsa/pki/inline/coolbeevip.inline
Client coolbeevip added.

The configuration file has been written to /home/admin/coolbeevip.ovpn.
Download the .ovpn file and import it in your OpenVPN client.
```


