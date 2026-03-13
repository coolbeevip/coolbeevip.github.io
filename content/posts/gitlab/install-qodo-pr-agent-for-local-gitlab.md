---
title: "在本地 GitLab 中通过 Docker 安装 Qodo PR-Agent 并集成代码 Review"
date: 2026-03-12T13:24:14+08:00
tags: [gitlab, docker, qodo, pr-agent, review]
categories: [gitlab]
draft: false
---

Qodo 的开源 `PR-Agent` 可以直接接入 GitLab Merge Request，在 MR 页面里生成描述、Review 结论和改进建议。对于内网自建 GitLab，最稳妥的方式是把 `PR-Agent` 作为一个本地 webhook 服务跑在 Docker 中，再通过 GitLab Webhook 把 MR 事件转给它。

本文记录一套在本地 GitLab 中落地的最小可用方案，目标是：

1. 使用 Docker 部署 `PR-Agent`
2. 接入本地 GitLab
3. 在 Merge Request 中通过评论触发 `/review`、`/describe`、`/improve`

> 说明：本文使用 webhook 模式，适合自建 GitLab 和内网环境。对应镜像标签可使用 `codiumai/pr-agent:0.32-gitlab_webhook`。

## 前置条件

部署前先准备好下面几项：

1. 一个可以访问 GitLab 的 Docker 主机
2. 一个本地 GitLab 实例，例如 `http://localhost:8080`
3. 一个 OpenAI 兼容模型
4. 一个专门给 `PR-Agent` 使用的 GitLab 机器人账号

建议不要直接使用管理员账号，而是新建一个 `pr-agent-bot` 用户。

## 第一步：在 GitLab 中准备机器人账号

先在 GitLab 中创建一个专用用户，例如 `pr-agent-bot`，然后把它加入需要接管 Review 的项目或组。

权限建议：

1. 项目级授予 `Developer` 权限，这样机器人至少能读取 MR、发表评论
2. 如果后续希望机器人创建更多评论或执行更深的写操作，再按需提升权限

接着为这个用户创建 Personal Access Token，至少勾选：

```text
api
```

记下这个 token，后面会配置为 `GITLAB__PERSONAL_ACCESS_TOKEN`。

**`pr-agent-bot` 用户创建完毕后，要先登录一次修改默认密码，否则 token 可能无法正常使用。**

## 第二步：生成 Webhook Secret

GitLab Webhook 和 `PR-Agent` 之间最好加一个共享密钥

```shell
openssl rand -hex 20
```

假设输出结果如下：

```text
5ac610e5e7cacf37a2167a96cb7f3bea3fe500d8
```

记下这个密钥，后面配置到 `GITLAB__SHARED_SECRET`，GitLab Webhook 配置里也要填这个值。

## 第三步：准备 PR-Agent 部署环境

在服务器上准备目录，例如：

```shell
mkdir -p /data02/gitlab_pr_agent
cd /data02/gitlab_pr_agent
```

## 第四步：准备 Embedding 模型

> 如果你的服务器无法联网，可手动准备模型文件

创建模型文件目录：

```shell
mkdir -p /data02/gitlab_pr_agent/tiktoken
```

下载 [o200k_base.tiktoken](https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken) 到 /data02/gitlab_pr_agent/tiktoken 目录下

生成模型文件的 CACHE KEY

```shell
echo -n "https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken" | sha1sum
fb374d419588a4632f3f557e76b4b70aebbca790
```

将下载后的模型文件重命名为 CACHE KEY：

```shell
mv /data02/gitlab_pr_agent/tiktoken/o200k_base.tiktoken /data02/gitlab_pr_agent/tiktoken/fb374d419588a4632f3f557e76b4b70aebbca790
```

## 第五步：编写 Docker Compose

新建 `pr-agent.yml`：

```yaml
version: '3'
services:
  pr-agent:
    image: codiumai/pr-agent:0.32-gitlab_webhook
    container_name: pr-agent
    restart: always
    ports:
      - "8082:3000"
    environment:
      TIKTOKEN_CACHE_DIR: /root/.cache/tiktoken
      CONFIG__GIT_PROVIDER: gitlab
      CONFIG__MODEL: hosted_vllm/qwen3.5-plus
      CONFIG__FALLBACK_MODELS: '["hosted_vllm/qwen3.5-plus"]'
      CONFIG__CUSTOM_MODEL_MAX_TOKENS: 128000
      HOSTED_VLLM_API_BASE: http://10.1.251.228:18080/v1
      HOSTED_VLLM_API_KEY: xxx
      GITLAB__URL: http://10.1.207.194:8081
      GITLAB__PERSONAL_ACCESS_TOKEN: glpat-xxxx
      GITLAB__SHARED_SECRET: 5ac610e5e7cacf37a2167a96cb7f3bea3fe500d8
      GITLAB__AUTH_TYPE: oauth_token
      GITLAB__PR_COMMANDS: '["/describe", "/review"]'
      GITLAB__HANDLE_PUSH_TRIGGER: 'true' 
      GITLAB__PUSH_COMMANDS: '["/review"]'      
      PORT: 3000
    volumes:
      - ./tiktoken:/root/.cache/tiktoken:ro
```

服务关键参数参数说明:

1. `PORT` 默认就是 `3000`，这里只是显式写出来方便排查(对外暴露的端口是 `8082`，内部容器还是 `3000`)
2. `CONFIG__GIT_PROVIDER=gitlab` 表示 Git Provider 使用 GitLab
3. `GITLAB__URL` 填你的 GitLab 地址，自建环境一般是内网地址
4. `GITLAB__AUTH_TYPE` 官方默认示例使用 `oauth_token`，如果你的 GitLab 版本较旧或兼容性有问题，再改成 `private_token`
5. `GITLAB__SHARED_SECRET` 就是前面生成的 Webhook Secret，确保和 GitLab Webhook 中一致
6. `GITLAB__PR_COMMANDS` 新建 MR 时自动执行 `/describe` 和 `/review`
7. `GITLAB__HANDLE_PUSH_TRIGGER` 和 `GITLAB__PUSH_COMMANDS` 配合使用，后续 MR 有新提交 push 进来时，再自动执行一次 `/review`，GitLab Webhook 必须开启 `Push events` 才能生效
8. `TIKTOKEN_CACHE_DIR` 指定 tiktoken 模型文件在容器内的路径，后面通过 `volumes` 把准备好的模型文件挂载进来

大模型模型关键参数说明:

1. 本地模型支持依赖 [LiteLLM](https://docs.litellm.ai/docs/providers/vllm) 支持，先确定推理服务名为 `hosted_vllm` (因为我的环境是使用 vLLM 作为本地推理服务)
2. 配置模型名称，`CONFIG__MODEL` 是主模型，`CONFIG__FALLBACK_MODELS` 是备用模型列表，格式为 `hosted_vllm/模型名称`
3. `CONFIG__CUSTOM_MODEL_MAX_TOKENS` 是自定义模型的最大上下文长度，单位是 token，根据你实际使用的模型调整
4. `HOSTED_VLLM_API_BASE` 和 `HOSTED_VLLM_API_KEY` 分别是本地 vLLM 推理服务的地址和访问密钥

如果你的 GitLab 使用自签名证书，可以额外增加：

```yaml
      GITLAB__SSL_VERIFY: "false"
```

更推荐的做法是把自定义 CA 证书挂进容器，而不是直接关闭 SSL 校验。

## 第六步：启动 PR-Agent

启动容器：

```shell
cd /data02/gitlab_pr_agent
docker-compose -f pr_agent.yml up -d
```

查看日志：

```shell
docker-compose logs -f pr-agent
```

可以先做一个本地连通性检查：

```shell
curl http://127.0.0.1:8082/
{"status":"ok"}
```

## 第七步：在 GitLab 中配置 Webhook

进入目标项目：

```text
Settings -> Webhooks
```

创建一个新的 Webhook：

1. URL 填 `http://<pr-agent-host>:8082/webhook`
2. Secret Token 填前面生成的 Webhook Secret，例如 `5ac610e5e7cacf37a2167a96cb7f3bea3fe500d8`
3. 勾选 `Merge request events`
4. 勾选评论事件，某些版本显示为 `Comments`，某些版本显示为 `Note events`
5. 如果你希望在新提交 push 后自动重新 review，再勾选 `Push events`

保存后先点一次 `Test`，确认 GitLab 能正常访问你的 `PR-Agent` 服务。

## 第八步：在 MR 中触发 Review

Webhook 接通以后，打开一个 Merge Request，在评论区输入下面这些命令即可：

```text
/describe
/review
/improve
```

常见用途：

1. `/describe` 自动总结本次 MR 做了什么
2. `/review` 输出整体 Review 结论、风险点和建议
3. `/improve` 给出更具体的代码修改建议

如果一切正常，机器人会直接在当前 Merge Request 中回评。

## 总结

对于本地 GitLab，`PR-Agent + Docker + Webhook` 是一套比较直接的集成方案：

1. GitLab 负责发送 MR / 评论 / Push 事件
2. `PR-Agent` 负责解析变更并调用大模型
3. Review 结果直接回写到 Merge Request