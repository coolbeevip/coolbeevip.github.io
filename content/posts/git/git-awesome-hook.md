---
title: "Awesome Git Hooks"
date: 2022-04-02T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

## commit-msg

```bash
#!/bin/sh

red='\033[0;31m'
green='\033[0;32m'
no_color='\033[0m'

commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")
max_length=50
if [ ${#commit_msg} -gt $max_length ]; then
    echo "${red}信息长度不能超过50！${no_color}"
    exit 1
fi

if [ "" = "$(grep -E '^(\[(fix|feat)\]:\[.*]\[.*\]|\[(docs|style|ref|test|chore|tag|revert|perf)\]:\[.*\])$' $1)" ]; then
	echo "${red}ERROR:${no_color} 你的提交描述格式错误, 请参考如下样例:"
	echo "${green}[feat]:[单号][新增XXXX]"
  echo "[feat]:[][新增XXXX]"
  echo "[fix]:[CRMAIF_ISSUE_XXX][修改/修复XXXX]"
  echo "[fix]:[][修改/修复XXXX]"
  echo "[docs]:[单号][新增/修订/删除XXXX]"
  echo "[docs]:[新增/修订/删除XXXX]"
  echo "[style]:[调整XX页XX格式]"
  echo "[ref]:[重构XXXX]"
  echo "[test]:[测试XXXX]"
  echo "[chore]:[构建/变动XXXX]"
  echo "[tag]:[版本XXXX]"
  echo "[revert]:[撤销/回退XXXX]"
  echo "[perf]:[性能优化XXXX]${no_color}"
	exit 1
fi
```

## pre-commit

```bash
#!/bin/sh

red='\033[0;31m'
green='\033[0;32m'
no_color='\033[0m'

USERNAME=$(git config user.name)
EMAIL=$(git config user.email)
EMAIL_USERNAME=$(echo "$EMAIL" | cut -d "@" -f 1)
EMAIL_DOMAIN=$(echo "$EMAIL" | cut -d "@" -f 2)

if [ "$EMAIL_DOMAIN" = "you email domain" ] && [ "$EMAIL_USERNAME" = "$USERNAME" ]; then
    echo "${green}检查 user.name=$USERNAME email=$EMAIL 成功!${no_color}"
    exit 0
else
    echo "${red} $EMAIL 不是合法的邮箱地址，或者邮箱名称前缀与用户名 $USERNAME 不匹配"
    echo "提交失败!${no_color}"
    exit 1
fi
```

## other

https://github.com/aitemr/awesome-git-hooks