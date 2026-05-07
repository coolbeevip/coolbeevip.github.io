---
title: "Git 仓库主分支镜像同步（保留 Commit 历史）"
date: 2026-05-04T10:00:00+08:00
tags: [git, gitlab, mirror, sync]
categories: [gitlab]
draft: false
---

# Git 仓库主分支镜像同步（保留 Commit 历史）

最近需要将一个 Git 仓库 A 的 `master` 分支定期同步到另一个 GitLab 仓库 B，并且要求：

- 保留 A 的所有 commit 历史
- B 最终以 A 为准
- 后续支持定期同步

最终整理了一套稳定可复用的方案。

---

# 场景

源仓库 A：

```text
ssh://git@example.com:10022/group/source-repo.git
```

目标仓库 B：

```text
http://gitlab.example.com/group/target-repo.git
```

目标：

```text
A/master  ->  B/master
```

并且：

- 保留所有 commit
- 后续支持自动同步

---

# 为什么不使用 git push --mirror

一开始尝试：

```bash
git push --mirror target
```

会遇到：

```text
deny updating a hidden ref
```

因为 GitLab 内部存在：

```text
refs/merge-requests/*
```

这些隐藏 refs 不允许推送。

另外：

```text
master -> master (forced update)
```

说明：

```text
A/master 与 B/master 历史不一致
```

因此：

- 普通 push 会失败
- 需要 force push
- 但只应该同步 master
- 不应该 mirror 全部 refs

---

# 推荐方案

核心思路：

```text
使用 mirror clone 保存 A
仅 force push master 到 B
```

---

# 第一次初始化

## 1. 创建同步目录

```bash
mkdir -p ~/git-sync-test
cd ~/git-sync-test
```

---

## 2. mirror clone 源仓库

```bash
git clone --mirror \
  ssh://git@example.com:10022/group/source-repo.git
```

进入目录：

```bash
cd source-repo.git
```

---

## 3. 添加目标仓库

```bash
git remote add target \
  http://gitlab.example.com/group/target-repo.git
```

---

## 4. 获取远端信息

```bash
git fetch origin
git fetch target master
```

---

## 5. Dry Run 验证

```bash
git push \
  --force-with-lease \
  --dry-run \
  target \
  refs/heads/master:refs/heads/master
```

如果看到：

```text
master -> master (forced update)
```

说明：

```text
B/master 将被 A/master 覆盖
```

---

## 6. 正式同步

```bash
git push \
  --force-with-lease \
  target \
  refs/heads/master:refs/heads/master
```

---

# 注意事项

## 1. B 的 master 可能需要允许 force push

如果出现：

```text
You are not allowed to force push code to a protected branch
```

需要在 GitLab：

```text
Settings
  -> Repository
    -> Protected branches
```

临时：

- Unprotect master
- 或允许 force push

---

## 2. B 最好不要再直接开发

因为：

```text
B 会被 A 周期性覆盖
```

如果 B 上继续开发：

- 会再次产生历史分叉
- 后续同步还会需要 force push

因此：

```text
B 更适合作为镜像仓库
```

---

# 后续定期同步

后续只需要：

```bash
cd ~/git-sync-test/source-repo.git

git fetch origin
git fetch target master

git push \
  --force-with-lease \
  target \
  refs/heads/master:refs/heads/master
```

---

# 自动同步脚本

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/path/to/git-mirror"
REPO_DIR="${BASE_DIR}/source-repo.git"

SOURCE_REMOTE="origin"
TARGET_REMOTE="target"
BRANCH="master"

cd "$REPO_DIR"

echo "[INFO] Fetch latest from ${SOURCE_REMOTE}..."
git fetch "$SOURCE_REMOTE"

echo "[INFO] Fetch latest from ${TARGET_REMOTE}/${BRANCH}..."
git fetch "$TARGET_REMOTE" "$BRANCH"

echo "[INFO] Push ${SOURCE_REMOTE}/${BRANCH} to ${TARGET_REMOTE}/${BRANCH}..."
git push --force-with-lease \
  "$TARGET_REMOTE" \
  "refs/heads/${BRANCH}:refs/heads/${BRANCH}"

echo "[INFO] Verifying synchronization..."

LOCAL_HASH=$(git rev-parse "refs/heads/${BRANCH}")
REMOTE_HASH=$(git ls-remote "$TARGET_REMOTE" "refs/heads/${BRANCH}" | awk '{print $1}')

echo "[INFO] Local  ${BRANCH}: ${LOCAL_HASH}"
echo "[INFO] Remote ${BRANCH}: ${REMOTE_HASH}"

if [[ "$LOCAL_HASH" == "$REMOTE_HASH" ]]; then
  echo "[INFO] Sync verification succeeded."
else
  echo "[ERROR] Sync verification failed!"
  exit 1
fi

cd "$BASE_DIR"

echo "[INFO] Done."
```

---

# 验证同步是否成功

本地：

```bash
git rev-parse refs/heads/master
```

远端：

```bash
git ls-remote target refs/heads/master
```

两个 commit hash 一致即可。

---

# 总结

最终方案：

```text
mirror clone A
↓
fetch A
↓
fetch B/master
↓
force-with-lease push A/master -> B/master
↓
compare commit hash
```

这个方案适合：

- GitLab 仓库镜像
- 内网代码同步
- 多环境仓库同步
- 主仓库 -> 只读仓库

同时：

- 保留完整 commit 历史
- 避免 merge request refs 问题
- 支持自动化定期同步