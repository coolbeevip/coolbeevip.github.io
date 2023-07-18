---
title: "Using gitlab-ci to cache python"
date: 2023-07-018T13:24:14+08:00
tags: [cache, python]
categories: [gitlab]
draft: false
---

```yaml
# 缓存位置环境变量
variables:  
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

# virtualenv 和 pip 缓存目录
cache:
  paths:
    - .cache/pip
    - venv/

# 预运行脚本
before_script:
  - python -V
  - pip install virtualenv
  - virtualenv venv
  - source venv/bin/activate

stages:
  - build

merge_job:
  image: python:3.9-buster
  stage: build
  only:
    refs:
      - merge_requests
  script:
    - pip install .
```