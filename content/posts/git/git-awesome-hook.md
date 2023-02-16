---
title: "Awesome Git Hooks"
date: 2022-04-02T13:24:14+08:00
tags: [git]
categories: [git]
draft: false
---

## commit-msg 

检查提交描述

```bash
#!/bin/sh

# [feat]:[123]:[增加A功能]
# [fix]:[123]:[修复A错误]
# [fix]:[]:[修复A错误]
# [tag]:[增加 1.0.0 标签]
# [revert]:[撤销某修改]
# [perf]:[提升某性能]
# [test]:[增加某测试]
# [refactor]:[重构某模块]
# [style]:[格式化某代码]
# [docs]:[增加某文档]

red='\033[0;31m'
no_color='\033[0m'

if [ "" = "$(grep '^\[feat\|fix]:\[.*\]:\[.*\]\|\[tag\|revert\|perf\|chore\|test\|refactor\|style\|docs]:\[.*\]$' $1)" ]; then
	echo "${red}ERROR:${no_color} Your commit message must match the regex '^\[feat\|fix]:\[.*\]:\[.*\]\|\[tag\|revert\|perf\|chore\|test\|refactor\|style\|docs]:\[.*\]$'"
	exit 1
fi
```

## other

https://github.com/aitemr/awesome-git-hooks