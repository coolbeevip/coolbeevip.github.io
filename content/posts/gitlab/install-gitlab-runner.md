---
title: "Install Gitlab Runner"
date: 2023-07-018T13:24:14+08:00
tags: [runner]
categories: [gitlab]
draft: false
---

启动 Gitlab Runner

```shell
docker run -d --name gitlab-runner-01 --restart always \
  -v /data01/runner/git-runner-01/volumns/runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /bin/docker:/bin/docker \
  -v /data01/runner/git-runner-01/volumns/runner/apache-maven-3.6.3:/root/.m2 \
  -v /data01/runner/git-runner-01/volumns/runner/apache-maven-3.6.3/bin/mvn:/bin/mvn \
  gitlab/gitlab-runner:latest
```

注册 Gitlab Runner 到 Gitlab

```shell
docker exec -it gitlab-runner-01 gitlab-ci-multi-runner register \
  --non-interactive \
  --url "http://mygitlab:8081/" \
  --registration-token "K6PPp2LWzdHpks5RKJWy" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "runner-01" \
  --tag-list "runner-01" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
  --docker-volumes /data01/runner/git-runner-01/volumns/runner/apache-maven-3.6.3:/root/.m2 \
  --docker-volumes /data01/runner/git-runner-01/volumns/runner/apache-maven-3.6.3/bin/mvn:/bin/mvn
```


注销 Gitlab Runner 到 Gitlab

```shell
docker exec -it gitlab-runner-01 gitlab-ci-multi-runner unregister \
  --non-interactive \
  --url "http://mygitlab:8081/" \
  --token "K6PPp2LWzdHpks5RKJWy"
```

启动后自动生成的 config.toml

```toml
concurrent = 1
check_interval = 0
log_level = "debug"

[session_server]
  session_timeout = 1800

[[runners]]
  name = "10.19.32.51-runner-01"
  url = "http://git.oss.asiainfo.com:8081/"
  token = "LrVrtzxwNamXUCyHE2Nx"
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
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/data01/runner/git-runner-01/volumns/runner/apache-maven-3.6.3:/root/.m2", "/data01/runner/git-runner-01/volumns/runner/apache-maven-3.6.3/bin/mvn:/bin/mvn", "/cache"]
    shm_size = 0
```

## Q & A

1. Initial heap size set to a larger value than the maximum heap size



