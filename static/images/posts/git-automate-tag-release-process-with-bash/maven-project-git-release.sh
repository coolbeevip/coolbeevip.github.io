#!/bin/bash -e
## ---------------------------------------------------------------------------
## Licensed to the Apache Software Foundation (ASF) under one or more
## contributor license agreements.  See the NOTICE file distributed with
## this work for additional information regarding copyright ownership.
## The ASF licenses this file to You under the Apache License, Version 2.0
## (the "License"); you may not use this file except in compliance with
## the License.  You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
## Maven Project Release & Git
## author：zhang lei
## ---------------------------------------------------------------------------

COLOR_RED='\033[1;31m'
COLOR_GREEN='\033[1;32m'
COLOR_CLEAN='\033[0m'

# git repository url
GIT_REPO_URL=$1

# repository name
GIT_REPO_URL_SUFFIX=$(basename $GIT_REPO_URL)
GIT_REPO_NAME=${GIT_REPO_URL_SUFFIX%.*}

# release work directory
RELEASE_WORK_DIR=$(mktemp -d -t release-$GIT_REPO_NAME)

# modify maven pom version
modify_maven_project_version(){
  mvn versions:set -DnewVersion=$1
  mvn versions:commit
}

# build & test maven project
check_source_before_release(){
  mvn clean package
}

# Generate the next version number
# $1: current version
# $2: increase position 0 – major, 1 – minor, 2 – patch
next_version() {
  local delimiter=.
  local array=($(echo "$1" | tr $delimiter '\n'))
  array[$2]=$((array[$2]+1))
  echo $(local IFS=$delimiter ; echo "${array[*]}")
}

# Check if the branch and tag already exist
check_git_repo_before_release(){

  if git branch -a | grep remotes/origin/$RELEASE_BRANCH_NAME ; then
    echo "${COLOR_RED}Pre-release branch and TAG check fails, The branch $RELEASE_BRANCH_NAME already exists, you can use the following command to delete the existing branch:${COLOR_CLEAN}"
    echo "git branch -D $RELEASE_BRANCH_NAME"
    echo "git push origin --delete $RELEASE_BRANCH_NAME"
    exit 1
  fi

  if git tag | grep $RELEASE_VERSION ; then
    echo "${COLOR_RED}Pre-release branch and TAG check fails, The tag $RELEASE_VERSION already exists, you can use the following command to delete the existing tag:${COLOR_CLEAN}"
    echo "git tag -d $RELEASE_VERSION"
    echo "git push origin :refs/tags/$RELEASE_VERSION"
    exit 1
  fi

  echo "Pre-release branch and TAG check...${COLOR_GREEN}OK${COLOR_CLEAN}"
}

release_now(){
  echo "${COLOR_GREEN}Create branch $RELEASE_BRANCH_NAME${COLOR_CLEAN}"
  git checkout -b $RELEASE_BRANCH_NAME
  git push origin $RELEASE_BRANCH_NAME

  echo "${COLOR_GREEN}Create tag $RELEASE_VERSION${COLOR_CLEAN}"
  git checkout master
  modify_maven_project_version $RELEASE_VERSION
  git commit -a -m "Upgrade Version to v$RELEASE_VERSION"
  git tag -a v$RELEASE_VERSION -m "Release v$RELEASE_VERSION"
  git push origin v$RELEASE_VERSION

  echo "${COLOR_GREEN}Update branch master version to $NEXT_VERSION${COLOR_CLEAN}"
  modify_maven_project_version $NEXT_VERSION
  git commit -a -m "Upgrade Release Version $NEXT_VERSION"
  git push origin master

  echo "${COLOR_GREEN}The release is successful, Please check branch & tag & master in the git repository${COLOR_CLEAN}"
}

main(){
  # =========================
  echo "${COLOR_GREEN}Initialize work directory${COLOR_CLEAN}"
  if [ ! -d $RELEASE_WORK_DIR ]; then
    mkdir -p $RELEASE_WORK_DIR
  fi
  cd $RELEASE_WORK_DIR
  echo "release home: "$RELEASE_WORK_DIR
  echo

  # =========================
  echo "${COLOR_GREEN}Download Repository${COLOR_CLEAN}"
  git clone $GIT_REPO_URL
  echo

  # =========================
  echo "${COLOR_GREEN}Build & Test${COLOR_CLEAN}"
  cd $GIT_REPO_NAME
  check_source_before_release
  echo

  # =========================
  echo "${COLOR_GREEN}Release Plan${COLOR_CLEAN}:"

  # current version
  CURRENT_VERSION=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.version}' --non-recursive exec:exec)

  # maintenance branch name
  RELEASE_BRANCH_NAME=${CURRENT_VERSION//0-SNAPSHOT/X}

  # release tag name
  RELEASE_VERSION=${CURRENT_VERSION//-SNAPSHOT/}

  # next snapshot version
  NEXT_VERSION=$(next_version $RELEASE_VERSION 1)-SNAPSHOT

  echo "${COLOR_GREEN}===================================================================="
  echo "GIT_REPO_URL: $GIT_REPO_URL"
  echo "RELEASE WORK DIR: $RELEASE_WORK_DIR"
  echo "CURRENT VERSION: $CURRENT_VERSION"
  echo "MAINTENANCE BRANCH NAME: $RELEASE_BRANCH_NAME"
  echo "TAG NAME: v$RELEASE_VERSION"
  echo "RELEASE VERSION: $RELEASE_VERSION"
  echo "NEXT VERSION: $NEXT_VERSION"
  echo "====================================================================${COLOR_CLEAN}\n"
  check_git_repo_before_release
  while true
  do
    read -p "Are you release？(Y/N): " input

    case $input in
        [yY])
        check_git_repo_before_release
        release_now
        exit 0
        ;;

        [nN])
        exit 1
        ;;

        *)
        echo "Invalid input"
        ;;
    esac
  done
}

main "$@"
