---
title: "Install Gitlab Runner"
date: 2023-07-18T13:24:14+08:00
tags: [runner]
categories: [gitlab]
draft: false
---

本文记录 `GitLab Runner` 常见的三种执行模式对比，以及使用 Docker 安装并注册到 GitLab 的最小步骤。

## GitLab Runner 的三种执行模式

在开始安装前，先明确 CI Job 实际运行时采用哪种模式。常见有三种：

| 模式 | 核心做法 | 适用场景 | 优点 | 缺点 |
| --- | --- | --- | --- | --- |
| `docker executor + host docker (via docker.sock)` | Runner 使用 `docker` executor，Job 通过挂载 `/var/run/docker.sock` 调用宿主机 Docker | 单机部署、需要复用宿主机镜像缓存和网络环境 | 配置简单，构建速度快，缓存复用好 | Job 实际可控制宿主机 Docker，隔离性最弱 |
| `docker executor + docker-in-docker (dind)` | Runner 使用 `docker` executor，Job 连接独立的 `docker:dind` 服务 | 需要 Docker 能力，但希望与宿主机 Docker 隔离 | 与宿主机隔离更好，环境更独立 | 配置更复杂，缓存和网络调优成本更高 |
| `shell executor` | Runner 使用 `shell` executor，直接在宿主机 Shell 中执行脚本 | 自建机、物理机、需要直接操作宿主机工具链 | 性能直接，环境最少一层封装 | 环境污染风险高，依赖宿主机一致性和清理机制 |

## 前置条件

开始前请确认以下公共条件已经满足：

- GitLab 服务地址可从 Runner 所在机器访问
- 已提前获取 `RUNNER_REGISTRATION_TOKEN`
- 已根据目标模式确认使用 `docker` executor 还是 `shell` executor
- 文中的 URL、Token、路径均为示例，请替换为自己的值

`RUNNER_REGISTRATION_TOKEN` 可在 GitLab 的 Runner 管理页面获取：

- 实例级 Runner：`Admin > CI/CD > Runners`
- 组级或项目级 Runner：进入对应 Group / Project 的 `Settings > CI/CD > Runners`

## docker executor + host docker (via docker.sock)

启动 GitLab Runner

```shell
docker run -d --name gitlab-runner-01 --restart always \
  -v /data01/runner/git-runner-01/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /bin/docker:/bin/docker \
  -v /data01/runner/git-runner-01/m2:/root/.m2 \
  -v /data01/runner/git-runner-01/m2/bin/mvn:/bin/mvn \
  gitlab/gitlab-runner:v13.6.0
```

* `/data01/runner/git-runner-01/config` ：GitLab Runner 配置目录，必须挂载到容器的 `/etc/gitlab-runner`，否则注册后 Runner 无法保存配置，重启后会丢失注册状态。
* `/var/run/docker.sock` 和 `/bin/docker`：让 Runner 容器内的 Job 能直接调用宿主机 Docker，执行构建、推送等操作。
* `/data01/runner/git-runner-01/m2`：Maven 本地缓存目录，挂载到容器内的 `/root/.m2`，让 Job 内部执行 Maven 构建时能复用缓存，加速构建过程。
* `/data01/runner/git-runner-01/m2/bin/mvn`：如果宿主机上的 Maven 可执行文件不在 PATH 中，或者需要特定版本，也可以直接挂载到容器内的 `/bin/mvn`，让 Job 内部直接调用。

注册 GitLab Runner 到 GitLab 实例

```shell
docker exec -it gitlab-runner-01 gitlab-runner register \
  --non-interactive \
  --url "http://gitlab.example.com:8081/" \
  --registration-token "<RUNNER_REGISTRATION_TOKEN>" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "group-prod-runner-01" \
  --tag-list "group,prod,runner-01,docker,maven" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
  --docker-volumes /data01/runner/git-runner-01/m2:/root/.m2 \
  --docker-volumes /data01/runner/git-runner-01/m2/bin/mvn:/bin/mvn
```

* `url` 参数指定 GitLab 实例地址，确保 Runner 所在机器能访问该地址。
* `registration-token` 参数使用之前获取的注册 token。
* `executor` 参数指定使用 `docker` executor。
* `docker-image` 参数指定 Job 内部默认使用的基础镜像，这里以 `alpine:latest` 为例，实际可根据需要选择。
* `description` 和 `tag-list` 参数用于标识 Runner，建议包含组织、环境和节点信息，便于在 GitLab 页面识别和调度。
* `docker-volumes` 参数重复挂载了之前启动 Runner 时指定的卷，确保 Job 内部能访问 Docker 和 Maven 缓存。

## docker executor + docker-in-docker (dind)

### 1. 启动 GitLab Runner

这种模式通常需要同时启动一个 `docker:dind` 服务容器，供 Job 内部执行 Docker 命令。

```shell
docker run -d --name gitlab-dind-01 --restart always \
  --privileged \
  -e DOCKER_TLS_CERTDIR="" \
  docker:20.10-dind
```

```shell
docker run -d --name gitlab-runner-01 --restart always \
  --link gitlab-dind-01:docker \
  -v /data01/runner/git-runner-01/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:v13.6.0
```

如果不希望使用 `--link`，也可以改为自定义 Docker Network，让 Runner 容器通过服务名访问 DinD 容器。

### 2. 注册 GitLab Runner

```shell
docker exec -it gitlab-runner-01 gitlab-runner register \
  --non-interactive \
  --url "http://gitlab.example.com:8081/" \
  --registration-token "<RUNNER_REGISTRATION_TOKEN>" \
  --executor "docker" \
  --docker-image docker:20.10 \
  --description "group-prod-runner-01-dind" \
  --tag-list "group,prod,runner-01,docker,dind" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected" \
  --docker-privileged="true" \
  --docker-volumes /cache
```

对应的 CI Job 通常还需要声明 `services: ["docker:dind"]`，并设置 `DOCKER_HOST=tcp://docker:2375` 等变量。

## shell executor

### 1. 启动 GitLab Runner

这种模式通常直接在宿主机安装 `gitlab-runner`，并以系统服务方式启动。安装方式可按宿主机发行版选择。

```shell
gitlab-runner start
```

如果宿主机使用 `systemd` 管理服务，也可以使用 `systemctl start gitlab-runner`。

### 2. 注册 GitLab Runner

```shell
gitlab-runner register \
  --non-interactive \
  --url "http://gitlab.example.com:8081/" \
  --registration-token "<RUNNER_REGISTRATION_TOKEN>" \
  --executor "shell" \
  --description "group-prod-runner-01-shell" \
  --tag-list "group,prod,runner-01,shell" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"
```

这种模式下，CI Job 会直接使用宿主机上的 Shell、Docker、Maven、Node.js 等工具链，因此需要自行保证宿主机环境一致性。

## 注销 GitLab Runner

```shell
docker exec -it gitlab-runner-01 gitlab-runner unregister \
  --non-interactive \
  --url "http://gitlab.example.com:8081/" \
  --token "<RUNNER_TOKEN>"
```

如果使用的是 `shell executor`，则直接在宿主机执行：

```shell
gitlab-runner unregister \
  --non-interactive \
  --url "http://gitlab.example.com:8081/" \
  --token "<RUNNER_TOKEN>"
```

## 验证

```shell
docker ps | grep gitlab-runner-01
docker exec -it gitlab-runner-01 gitlab-runner verify
docker exec -it gitlab-runner-01 gitlab-runner list
```

如果使用的是 `shell executor`，则改为在宿主机执行 `gitlab-runner verify` 和 `gitlab-runner list`。

如果 Runner 已在 GitLab 页面显示为在线，并且能成功执行一个最小 CI Job，则说明安装完成。

## 注意事项

- 挂载 `/var/run/docker.sock` 后，CI Job 可直接控制宿主机 Docker，请仅在可信环境中使用
- 不要在文档、仓库或截图中保存真实的 registration token 和 runner token

## 维护

- Runner 配置文件位于 `/data01/runner/git-runner-01/config/config.toml`
- 修改配置后，可执行 `docker restart gitlab-runner-01` 使配置生效
- 可通过 `docker exec -it gitlab-runner-01 gitlab-runner verify` 检查 Runner 状态
- 如需删除 Runner，可先执行 `unregister`，再停止并删除容器
