---
title: "Synchronize between image repositories with Bash"
date: 2021-04-19T13:24:14+08:00
tags: [docker,shell]
categories: [docker,shell]
draft: false
---

从源镜像仓库批量拉取镜像，并将这些镜像推送到目标镜像仓库的批量脚本

```shell
#!/bin/bash

#################################################
# 使用方式
#  从源仓库拉取镜像到本机
#  sh docker-images-pulling-pushing.sh pull
#
#  将本机镜像推送到目的仓库
#  sh docker-images-pulling-pushing.sh push
#
#  清理本机的镜像
#  sh docker-images-pulling-pushing.sh clean
#################################################

# 源仓库地址
DOCKER_REPO_FROM=
# 目标仓库地址
DOCKER_REPO_TO=192.168.2.2:8888/
DOCKER_REPO_TO_USER=test
DOCKER_REPO_TO_PASS=Test123456

# 镜像定义
DOCKER_IMAGES=()
DOCKER_IMAGES+=(postgres:9.6)
DOCKER_IMAGES+=(elasticsearch:6.6.2)
DOCKER_IMAGES+=(coolbeevip/servicecomb-pack)

# 从源仓库地址拉取镜像到本机仓库
function pull(){
  echo "Pull images from $DOCKER_REPO_FROM"
  for image in ${DOCKER_IMAGES[@]};
  do
    docker pull $DOCKER_REPO_FROM$image
  done
}

# 本机镜像推送到目的仓库
function push(){
  docker login http://$DOCKER_REPO_TO -u $DOCKER_REPO_TO_USER -p $DOCKER_REPO_TO_PASS
  echo "Push $DOCKER_REPO_FROM to $DOCKER_REPO_TO"
  for image in ${DOCKER_IMAGES[@]};
  do
    docker image tag $DOCKER_REPO_FROM$image $DOCKER_REPO_TO$image
    docker push $DOCKER_REPO_TO$image
  done
}

# 清理本机拉取后的镜像
function clean(){
  echo "Remove images"
  docker rmi -f $(docker images | grep $DOCKER_REPO_FROM | awk '{print $3}')
  docker rmi -f $(docker images | grep $DOCKER_REPO_TO | awk '{print $3}')
}

case "${@: -1}" in
	pull )
		pull
		;;
  clean )
		clean
		;;
	push )
		push
		;;
esac
```