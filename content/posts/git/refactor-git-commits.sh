#!/bin/bash
set +e
CURRENT_DIR=$(pwd)

#========================================
# 工作目录
ROOT_DIR=/Users/zhanglei/Work/git-to-git
# 上游仓库
UPSTREAM_REPO_URL=ssh://git@git.oss.xxxx.com:10022/ndcp/ndcp-collector.git
# 目标仓库
TARGET_REPO_URL=ssh://git@git.oss.xxxx.com:10022/zhanglei36/ndcp-collector-gitai.git
# 从此日期之后的 commit
AFTER_DATE="1977-01-01 00:00:00"
#========================================

TEMP_DIR=$ROOT_DIR/TMP
TARGET_DIR=$ROOT_DIR/TARGET

UPSTREAM_REPO_URL_SUFFIX=$(basename $UPSTREAM_REPO_URL)
UPSTREAM_REPO_NAME=${UPSTREAM_REPO_URL_SUFFIX%.*}
UPSTREAM_REPO_DIR=$ROOT_DIR/$UPSTREAM_REPO_NAME
UPSTREAM_COMMITS_CSV=commits.csv

TEMP_REPO_DIR=$TEMP_DIR/$UPSTREAM_REPO_NAME

TARGET_REPO_URL_SUFFIX=$(basename $TARGET_REPO_URL)
TARGET_REPO_NAME=${TARGET_REPO_URL_SUFFIX%.*}
TARGET_REPO_DIR=$TARGET_DIR/$TARGET_REPO_NAME

function clone_repo() {
  mkdir -p $ROOT_DIR
  mkdir -p $TEMP_DIR
  mkdir -p $TARGET_DIR

  if [ ! -d $UPSTREAM_REPO_DIR ]; then
    echo "init $UPSTREAM_REPO_DIR"
    cd $ROOT_DIR
    git clone $UPSTREAM_REPO_URL
  fi

  if [ ! -d $TEMP_REPO_DIR ]; then
    echo "init $TEMP_REPO_DIR"
    cd $TEMP_DIR
    git clone $UPSTREAM_REPO_URL
  fi

  if [ ! -d $TARGET_REPO_DIR ]; then
    echo "init $TARGET_REPO_DIR"
    cd $TARGET_DIR
    git clone $TARGET_REPO_URL
  fi
}

function export_commits() {
  echo "export commits to $UPSTREAM_REPO_DIR/$UPSTREAM_COMMITS_CSV"
  cd $UPSTREAM_REPO_DIR
  git pull
  git log --date=format:'%Y-%m-%d,%H:%M:%S' --pretty=format:"%H,%an,%ae,%ad,%s" --after="$AFTER_DATE" --reverse >$UPSTREAM_REPO_DIR/$UPSTREAM_COMMITS_CSV
  echo "已经导出 $UPSTREAM_REPO_DIR/$UPSTREAM_COMMITS_CSV"
}

function import_commits() {
  cd $TARGET_REPO_DIR
  git pull
  while IFS="," read -r COMMIT_ID USERNAME EMAIL DATE TIME MESSAGE; do
    echo "$COMMIT_ID"

    cd $TEMP_REPO_DIR
    git reset --hard $COMMIT_ID
    rm -rf $TARGET_REPO_DIR/*
    cp -r * $TARGET_REPO_DIR

    cd $TARGET_REPO_DIR
    git add .
    git commit --author="$USERNAME <$EMAIL>" -m "$MESSAGE" --date "$DATE $TIME"

  done <$UPSTREAM_REPO_DIR/$UPSTREAM_COMMITS_CSV
}

case "$1" in
init)
  clone_repo
  ;;

export)
  clone_repo
  export_commits
  ;;

import)
  import_commits
  ;;

*)
  echo "Usage: $0 {init|export|import}"
  exit 1
  ;;
esac
cd $CURRENT_DIR
exit 0
