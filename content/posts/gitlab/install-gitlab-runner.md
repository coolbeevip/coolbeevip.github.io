---
title: "Install Gitlab Runner"
date: 2023-07-18T13:24:14+08:00
tags: [runner]
categories: [gitlab]
draft: false
---

本文记录使用 Docker 安装 `GitLab Runner` 并注册到 GitLab 的最小步骤，适用于 `docker executor` 场景。

前置条件：

- 宿主机已安装 Docker，且能正常执行 `docker` 命令
- GitLab 服务地址可从 Runner 宿主机访问
- 预先准备 Runner 配置目录与 Maven 缓存目录
- 文中的 URL、Token、路径均为示例，请替换为自己的值

启动 Gitlab Runner

```shell
docker run -d --name gitlab-runner-01 --restart always \
  -v /data01/runner/git-runner-01/volumes/runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /bin/docker:/bin/docker \
  -v /data01/runner/git-runner-01/volumes/runner/apache-maven-3.6.3:/root/.m2 \
  -v /data01/runner/git-runner-01/volumes/runner/apache-maven-3.6.3/bin/mvn:/bin/mvn \
  gitlab/gitlab-runner:v13.6.0
```

如果宿主机无法解析内网域名，可按需追加 `--add-host=gitlab.example.com:10.0.0.10` 这类参数。

注册 Gitlab Runner 到 Gitlab

`RUNNER_REGISTRATION_TOKEN` 可在 GitLab 的 Runner 管理页面获取：

- 实例级 Runner：`Admin > CI/CD > Runners`
- 组级或项目级 Runner：进入对应 Group / Project 的 `Settings > CI/CD > Runners`

```shell
docker exec -it gitlab-runner-01 gitlab-runner register \
  --non-interactive \
  --url "http://gitlab.example.com:8081/" \
  --registration-token "<RUNNER_REGISTRATION_TOKEN>" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "runner-01" \
  --tag-list "runner-01" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
  --docker-volumes /data01/runner/git-runner-01/volumes/runner/apache-maven-3.6.3:/root/.m2 \
  --docker-volumes /data01/runner/git-runner-01/volumes/runner/apache-maven-3.6.3/bin/mvn:/bin/mvn
```

如果使用旧版 Runner 镜像，也可以使用 `gitlab-ci-multi-runner register`。

注销 Gitlab Runner 到 Gitlab

```shell
docker exec -it gitlab-runner-01 gitlab-runner unregister \
  --non-interactive \
  --url "http://gitlab.example.com:8081/" \
  --token "<RUNNER_TOKEN>"
```

验证：

```shell
docker ps | grep gitlab-runner-01
docker exec -it gitlab-runner-01 gitlab-runner verify
docker exec -it gitlab-runner-01 gitlab-runner list
```

如果 Runner 已在 GitLab 页面显示为在线，并且能成功执行一个最小 CI Job，则说明安装完成。

注意：

- 挂载 `/var/run/docker.sock` 后，CI Job 可直接控制宿主机 Docker，请仅在可信环境中使用
- 不要在文档、仓库或截图中保存真实的 registration token 和 runner token

启动后自动生成的 config.toml

```toml
concurrent = 1
check_interval = 0
log_level = "debug"

[session_server]
  session_timeout = 1800

[[runners]]
  name = "10.19.32.51-runner-01"
  url = "http://gitlab.example.com:8081/"
  token = "<RUNNER_TOKEN>"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    cpus = "2"
    memory = "2g"
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/data01/runner/git-runner-01/volumes/runner/apache-maven-3.6.3:/root/.m2", "/data01/runner/git-runner-01/volumes/runner/apache-maven-3.6.3/bin/mvn:/bin/mvn", "/cache"]
    shm_size = 0
```
