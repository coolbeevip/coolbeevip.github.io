---
title: "macOS 远程连接 Ubuntu 桌面：NoMachine 安装指南"
date: 2026-07-25T13:24:14+08:00
tags: [linux,ubuntu,macos,nomachine,remote-desktop]
categories: [linux]
draft: false
---

这篇文章介绍如何从 macOS 连接 Ubuntu 远程桌面，尤其适合没有物理显示器、默认只有命令行环境的 Ubuntu 服务器。

本文使用的方案是：

- 客户端：macOS
- 服务端：Ubuntu 24.04
- 桌面环境：XFCE
- 远程桌面：NoMachine

SSH 用来完成服务端安装和故障排查，真正承载远程桌面会话的是 NoMachine 的 NX 协议。

## 准备 Ubuntu 账号

先通过 SSH 登录 Ubuntu，并确认系统版本、处理器架构和当前用户：

```shell
lsb_release -a
dpkg --print-architecture
whoami
```

常见的 x86 服务器架构为：

```text
amd64
```

下载 NoMachine 时，需要选择与服务器架构匹配的 DEB 安装包。

后文用 `ubuntu-user` 表示登录 Ubuntu 桌面的用户。执行命令时，将它替换成真实用户名。

## 安装 XFCE 桌面

如果 Ubuntu 只有命令行环境，先安装相对轻量的 XFCE：

```shell
sudo apt update
sudo apt install -y xfce4 xfce4-goodies dbus-x11
```

安装过程中如果出现显示管理器选择界面，保持默认选项即可。NoMachine 创建虚拟桌面不依赖物理显示器。

确认 XFCE 已经安装：

```shell
command -v startxfce4
ls /usr/share/xsessions/
```

正常情况下，可以看到类似结果：

```text
/usr/bin/startxfce4
xfce.desktop
```

## 在 Ubuntu 安装 NoMachine

打开 NoMachine 下载页面：

<https://download.nomachine.com/download>

选择 Linux、服务器对应的处理器架构和 DEB 格式，复制安装包下载地址。然后回到 Ubuntu，通过 SSH 下载并安装：

```shell
cd /tmp
wget '复制的 DEB 下载地址' -O nomachine.deb
sudo apt install ./nomachine.deb
```

安装完成后检查服务状态和监听端口：

```shell
sudo /etc/NX/nxserver --status
sudo ss -lntp | grep 4000
```

NoMachine 默认使用 TCP 4000 端口。如果 Ubuntu 启用了 UFW，需要放行这个端口：

```shell
sudo ufw allow 4000/tcp
```

如果 Ubuntu 运行在云服务器上，还要在云平台安全组中放行 TCP 4000。建议只允许自己的固定公网 IP 或可信网络访问，不要直接向整个互联网开放。

## 配置无显示器服务器

没有物理显示器时，需要让 NoMachine 按需创建虚拟显示。编辑服务端配置：

```shell
sudo vi /usr/NX/etc/server.cfg
```

在 `vi` 中输入 `/CreateDisplay` 并按回车，可以定位相关配置；按 `n` 查找下一个匹配项。将对应配置调整为：

```text
CreateDisplay 1
DisplayOwner "ubuntu-user"
DisplayGeometry 2560x1600
```

其中：

- `DisplayOwner` 必须替换为真实的 Ubuntu 用户名。
- `2560x1600` 适合高分辨率 MacBook。
- 如果带宽有限或操作延迟明显，可以改成 `1920x1200`。

保存并退出 `vi`：

```text
:wq
```

检查最终生效的配置，避免同一个配置项出现多份有效值：

```shell
grep -nE '^[[:space:]]*(CreateDisplay|DisplayOwner|DisplayGeometry)' \
  /usr/NX/etc/server.cfg
```

重启 NoMachine：

```shell
sudo /etc/NX/nxserver --restart
```

无物理显示器时，重启过程中出现下面的提示属于正常现象：

```text
Cannot find X servers running on this machine.
A new virtual display will be created on demand.
```

它表示当前没有可用的物理 X Server，NoMachine 会在用户连接时创建虚拟显示。

## 检查 `.Xauthority`

NoMachine 需要在用户主目录中写入 `.Xauthority` 文件。如果这个路径被错误创建成目录，虚拟显示会启动失败。

先用准备登录桌面的 Ubuntu 用户执行：

```shell
ls -ld "$HOME/.Xauthority"
```

如果文件尚不存在，`ls` 会提示找不到文件，这通常不需要处理，NoMachine 可以在建立会话时创建它。

如果它已经存在，正常结果应该以 `-` 开头，表示这是普通文件：

```text
-rw------- ... .Xauthority
```

如果结果以 `d` 开头：

```text
drwxr-xr-x ... .Xauthority
```

说明 `.Xauthority` 是目录，需要先将错误目录移走，再创建同名普通文件。下面的命令会自动查询账号的主目录和主用户组：

```shell
UBUNTU_USER=ubuntu-user
USER_HOME=$(getent passwd "$UBUNTU_USER" | cut -d: -f6)
USER_GROUP=$(id -gn "$UBUNTU_USER")

sudo mv \
  "$USER_HOME/.Xauthority" \
  "$USER_HOME/.Xauthority.invalid-directory"

sudo install \
  -o "$UBUNTU_USER" \
  -g "$USER_GROUP" \
  -m 600 \
  /dev/null \
  "$USER_HOME/.Xauthority"
```

记得先把 `ubuntu-user` 改成真实用户名。确认修复结果：

```shell
ls -l "$USER_HOME/.Xauthority"
file "$USER_HOME/.Xauthority"
```

预期看到一个权限为 `600`、归属正确的普通文件。然后重启 NoMachine：

```shell
sudo /etc/NX/nxserver --restart
```

## 从 macOS 建立连接

在 Mac 上打开同一个下载页面：

<https://download.nomachine.com/download>

选择 macOS 版本，安装并启动 NoMachine 客户端。新建连接时填写：

```text
协议：NX
主机：Ubuntu 服务器 IP 或域名
端口：4000
```

连接后，使用 Ubuntu 的系统用户名和密码登录。这里使用的是 Ubuntu 本机账号，不是 NoMachine 单独创建的账号。

如果该用户平时只通过 SSH 密钥登录、还没有系统密码，可以先在服务器设置：

```shell
sudo passwd ubuntu-user
```

密码设置完成后，再回到 NoMachine 客户端登录。

## 调整分辨率和清晰度

对于内置屏幕分辨率为 3024×1964 的 14 英寸 MacBook，可以先把远程桌面设置为：

```text
2560×1600
```

如果操作延迟明显，或者远程界面元素太小，可以改为：

```text
1920×1200
```

在 Ubuntu 的显示设置中建议使用：

```text
Scale：100%
Fractional Scaling：关闭
```

如果字体模糊，通常是远程画面被非整数比例缩放。连接远程桌面后，按下面的快捷键打开 NoMachine 会话菜单：

```text
Control + Option + 0
```

进入 `Display`，建议：

- 启用 `Resize remote screen`
- 关闭 `Scale to window`
- 尽量使用全屏模式
- 根据网络状况适当提高图像质量

不要为了改善清晰度直接启用 Ubuntu 的 Fractional Scaling。它可能和 NoMachine 的画面缩放叠加，反而让字体更模糊。

## 验证虚拟显示

首次从 Mac 发起连接后，可以在 Ubuntu 上检查 X11 套接字和相关进程：

```shell
ls -la /tmp/.X11-unix/
ps aux | grep -E 'nxserver|nxnode|Xorg' | grep -v grep
```

虚拟显示创建成功后，可以看到类似内容：

```text
/tmp/.X11-unix/X1001
nxserver.bin --virtualsession
nxnode.bin
```

`X1001` 的编号并不固定，只要存在 NoMachine 创建的 X11 显示和虚拟会话进程即可。

## 常见故障排查

### 客户端提示无法创建新显示

如果客户端提示：

```text
Cannot create a new display, please contact your system administrator.
```

先检查服务端日志：

```shell
sudo grep -RniE \
  'error|failed|fatal|display|xorg|permission|denied' \
  /usr/NX/var/log 2>/dev/null | tail -n 200
```

常用日志文件包括：

```text
/usr/NX/var/log/server.log
/usr/NX/var/log/daemon.log
/usr/NX/var/log/history
```

如果日志中出现：

```text
Cannot write to .Xauthority file
Is a directory
```

说明 `.Xauthority` 被创建成了目录，按照前文的方法将它修复为普通文件。

### `/tmp/.X11-unix` 为空

执行下面的命令：

```shell
ls -la /tmp/.X11-unix/
```

如果目录为空，说明 X11 虚拟显示没有创建成功。重点检查：

- `CreateDisplay 1` 是否生效。
- `DisplayOwner` 是否为真实用户名。
- 用户主目录是否存在并且可写。
- `.Xauthority` 是否为归属正确的普通文件。
- `/usr/NX/var/log/server.log` 中是否有权限或 Xorg 错误。

### 只有 NoMachine 守护进程

如果进程列表中只有：

```text
nxserver.bin --daemon
```

却没有：

```text
nxserver.bin --virtualsession
nxnode.bin
```

说明 NoMachine 服务已经启动，但虚拟桌面会话启动后退出了。此时应优先查看 Ubuntu 上的服务端日志；Mac 客户端日志通常只能看到通用的连接错误。

### 无法连接 TCP 4000

在 Mac 的终端中检查服务器端口：

```shell
nc -vz Ubuntu服务器IP 4000
```

如果连接失败，依次检查：

- NoMachine 服务是否正在运行。
- Ubuntu 是否监听 TCP 4000。
- UFW 是否允许 TCP 4000。
- 云服务器安全组是否放行 TCP 4000。
- 客户端当前公网 IP 是否在安全组允许范围内。