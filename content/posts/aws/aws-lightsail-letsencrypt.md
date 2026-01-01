---
title: "AWS Lightsail 证书安装与自动续期"
date: 2025-12-31T00:24:14+08:00
tags: [aws,let’s encrypt,dns-route53]
categories: [aws]
draft: false
---

## 适用场景

* 使用 **AWS Lightsail** 托管服务器
* 使用 **Lightsail / Route53** 管理 DNS
* 使用 **Nginx（宿主机或 Docker）**
* 需要 **通配符证书（`*.example.com`）**
* 希望 **证书自动续期、无人值守**

---

## 一、整体架构说明（非常重要）

```
Let’s Encrypt
   │
   │  DNS-01 验证
   ▼
Route53 / Lightsail DNS（权威）
   │
   │  TXT _acme-challenge
   ▼
Certbot（dns-route53 插件）
   │
   │  自动续期
   ▼
Nginx（reload 生效）
```

> ⚠️ **关键原则**
>
> * `_acme-challenge` TXT **只能由 certbot 自动管理**
> * **禁止手动添加或残留 TXT**
> * NS（Name Server）必须与 DNS Zone 完全一致

---

## 二、前置条件检查清单

### 1. 域名 DNS 已交由 Lightsail 管理

在 Lightsail 控制台应看到：

> ✅ *You are using Lightsail to manage the DNS records for your domain.*

并记录当前 **Name Servers**（示例）：

```
ns-xxxx.awsdns-xx.net
ns-xxxx.awsdns-xx.org
ns-xxxx.awsdns-xx.com
ns-xxxx.awsdns-xx.co.uk
```

### 2. 注册商 NS 必须与 Lightsail 显示一致

```bash
dig +short NS example.com
```

👉 输出必须 **完全一致**
否则 Let’s Encrypt 永远校验失败。

---

## 三、IAM：创建 certbot 专用 Access Key

### 1. 创建 IAM 用户

* 用户名：`certbot-route53`
* 访问方式：**Programmatic access**

### 2. 绑定最小权限策略（示例）

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. 保存 Access Key

你将得到：

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

---

## 四、在 Lightsail 实例上配置 AWS 凭证

### 1. 安装 AWS CLI（若未安装）

```bash
sudo apt update
sudo apt install -y awscli
```

### 2. 配置 certbot 专用凭证

```bash
sudo mkdir -p /root/.aws
sudo nano /root/.aws/credentials
```

```ini
[default]
aws_access_key_id = AKIAxxxxxxxx
aws_secret_access_key = xxxxxxxxxxxxxxxxx
```

```bash
sudo chmod 600 /root/.aws/credentials
```

### 3. 验证（必须成功）

```bash
sudo aws route53 list-hosted-zones
```

---

## 五、安装 Certbot 与 Route53 插件

```bash
sudo apt install -y certbot python3-certbot-dns-route53
```

验证插件存在：

```bash
certbot plugins | grep route53
```

---

## 六、签发 Wildcard 证书（只做一次）

```bash
sudo certbot certonly \
  --dns-route53 \
  --cert-name example-wildcard \
  -d example.com \
  -d '*.example.com'
```

成功标志：

* 无报错
* 输出证书路径

查看证书：

```bash
sudo certbot certificates
```

---

## 七、⚠️ 关键清理步骤（必做）

### ❌ 删除旧的 `_acme-challenge` TXT（如果存在）

在 Lightsail DNS 控制台：

```
TXT
_acme-challenge.example.com
"xxxx旧值xxxx"
```

👉 **必须手动删除**

验证：

```bash
dig TXT _acme-challenge.example.com +short
```

应为空。

---

## 八、Nginx 配置证书路径

### Nginx 示例：

```nginx
ssl_certificate     /etc/letsencrypt/live/example-wildcard/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example-wildcard/privkey.pem;
```

重载：

```bash
nginx -t && systemctl reload nginx
```

---

## 九、配置自动续期（核心）

### 1. systemd timer（Debian 默认已有）

```bash
systemctl list-timers | grep certbot
```

若没有：

```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

### 2. 配置 deploy-hook（证书更新后自动 reload Nginx）

#### Docker Nginx 示例（推荐）

```bash
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo nano /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

```bash
#!/bin/bash
set -e

LOG=/var/log/certbot-deploy.log

echo "[$(date)] certbot deploy-hook: reload nginx" >> $LOG
docker exec gateway-nginx nginx -t >> $LOG 2>&1
docker exec gateway-nginx nginx -s reload >> $LOG 2>&1
echo "[$(date)] nginx reload success" >> $LOG
```

```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

---

## 十、最终验证（必须）

### 1. 模拟续期

```bash
sudo certbot renew --dry-run
```

成功标志：

```
Congratulations, all simulated renewals succeeded
```

### 2. 验证 hook 是否执行

```bash
sudo tail /var/log/certbot-deploy.log
```

---

## 十一、日常运维规范（非常重要）

### ✅ 允许做的

* `certbot renew`
* 查看证书：

  ```bash
  certbot certificates
  ```

### ❌ 禁止做的

* ❌ 手动添加 `_acme-challenge` TXT
* ❌ 使用 `--manual`
* ❌ 重复 `certbot certonly`
* ❌ 删除 `/etc/letsencrypt/archive`

---

## 十二、半年一次健康检查（推荐）

```bash
sudo certbot certificates
dig +short NS example.com
```

---

## 十三、常见问题速查

### Q1：renew 失败，提示 TXT 不正确？

👉 99% 是：

* NS 未对齐
* `_acme-challenge` 有残留 TXT

### Q2：renew 成功但证书未生效？

👉 忘了 reload nginx
→ 检查 deploy-hook 日志
