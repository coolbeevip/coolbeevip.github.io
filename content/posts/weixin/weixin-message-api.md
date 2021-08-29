---
title: "Setting up Redis for Production"
date: 2020-08-19T13:24:14+08:00
tags: [weixin]
categories: [weixin]
draft: true
---

获取 ACCESS_TOKEN

```
curl "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=<ID>&corpsecret=<secret>"

{"errcode":0,"errmsg":"ok","access_token":"<your token>","expires_in":7200}
```

发送应用消息

```
curl -X POST \
-H "Content-Type: application/json" \
-d '{"touser":"@all","toparty":"@all","totag":"@all","msgtype":"text","agentid":1000002,"text":{"content":"你的快递已到，请携带工卡前往邮件中心领取。\n出发前可查看<a href=\"http://work.weixin.qq.com\">邮件中心视频实况</a>，聪明避开排队。"},"safe":0,"enable_id_trans":0,"enable_duplicate_check":0,"duplicate_check_interval":1800}' \
https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=<your token>

{"errcode":0,"errmsg":"ok","invaliduser":"","msgid":"Dv0oBVNA9p2BIWPODPqgkhw26-_zTx0hw9gS0AkLk8xpEqvcVwAPN1tsF8pYu2CUBZRLyrY3wvULvVWYsMGzaw"}
```

撤回消息

```
curl -X POST \
-H "Content-Type: application/json" \
-d '{"msgid":"<msgid>"}' \
https://qyapi.weixin.qq.com/cgi-bin/message/recall?access_token=<your token>

{"errcode":0,"errmsg":"ok"}
```

