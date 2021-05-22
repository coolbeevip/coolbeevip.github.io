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

set -e
OS=`uname -s`

if [ $OS == "Darwin" ];then
  COLOR_RED="\033[1;31m"
  COLOR_GREEN="\033[1;32m"
  COLOR_CLEAN="\033[0m"
else
  COLOR_RED="\e[31m"
  COLOR_GREEN="\e[32m"
  COLOR_CLEAN="\e[0m"
fi

# git repository url
GIT_REPO_URL=$1

# repository name
GIT_REPO_URL_SUFFIX=$(basename $GIT_REPO_URL)
GIT_REPO_NAME=${GIT_REPO_URL_SUFFIX%.*}

# release work directory
if [ $OS == "Darwin" ];then
	RELEASE_WORK_DIR=$(mktemp -d -t release-$GIT_REPO_NAME)
else
	RELEASE_WORK_DIR=$(mktemp -d -t release-$GIT_REPO_NAME-XXX)
fi

# pre release script steps
RELEASE_STEP_SCRIPTS=()

# take current project version
current_maven_project_version(){
  CURRENT_VERSION=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.version}' --non-recursive exec:exec)
}

# modify maven pom version
modify_maven_project_version(){
  RELEASE_STEP_SCRIPTS+=("mvn versions:set -DnewVersion=$1")
  RELEASE_STEP_SCRIPTS+=("mvn versions:commit")
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
    echo_e "${COLOR_RED}Pre-release branch and TAG check fails, The branch $RELEASE_BRANCH_NAME already exists, you can use the following command to delete the existing branch:${COLOR_CLEAN}"
    echo_e "git branch -D $RELEASE_BRANCH_NAME"
    echo_e "git push origin --delete $RELEASE_BRANCH_NAME"
    exit 1
  fi

  if git tag | grep $RELEASE_VERSION ; then
    echo_e "${COLOR_RED}Pre-release branch and TAG check fails, The tag $RELEASE_VERSION already exists, you can use the following command to delete the existing tag:${COLOR_CLEAN}"
    echo_e "git tag -d $RELEASE_VERSION"
    echo_e "git push origin :refs/tags/$RELEASE_VERSION"
    exit 1
  fi

  echo_e "Pre-release branch and TAG check...${COLOR_GREEN}OK${COLOR_CLEAN}"
}

release_now(){
  for i in "${RELEASE_STEP_SCRIPTS[@]}"
  do
    if  [[ $i == STEP* ]] || [[ $i == ----* ]]; then
      echo_e "${COLOR_GREEN}$i${COLOR_CLEAN}"
    else
      eval $i
    fi
  done
}

pre_release_steps(){
  RELEASE_STEP_SCRIPTS+=("STEP1: Create maintenance branch $RELEASE_BRANCH_NAME")
  RELEASE_STEP_SCRIPTS+=("git checkout -b $RELEASE_BRANCH_NAME")
  RELEASE_STEP_SCRIPTS+=("git push origin $RELEASE_BRANCH_NAME")

  RELEASE_STEP_SCRIPTS+=("--------------------------------------------------------------------")
  RELEASE_STEP_SCRIPTS+=("STEP2: Create release Tag $RELEASE_VERSION")
  RELEASE_STEP_SCRIPTS+=("git checkout master")
  modify_maven_project_version $RELEASE_VERSION
  RELEASE_STEP_SCRIPTS+=("git commit -a -m 'Upgrade Version to v$RELEASE_VERSION'")
  RELEASE_STEP_SCRIPTS+=("git tag -a v$RELEASE_VERSION -m 'Release v$RELEASE_VERSION'")
  RELEASE_STEP_SCRIPTS+=("git push origin v$RELEASE_VERSION")

  RELEASE_STEP_SCRIPTS+=("--------------------------------------------------------------------")
  RELEASE_STEP_SCRIPTS+=("STEP3: Update branch master version to $NEXT_VERSION")
  modify_maven_project_version $NEXT_VERSION
  RELEASE_STEP_SCRIPTS+=("git commit -a -m 'Upgrade Release Version $NEXT_VERSION'")
  RELEASE_STEP_SCRIPTS+=("git push origin master")
  RELEASE_STEP_SCRIPTS+=("--------------------------------------------------------------------")
  RELEASE_STEP_SCRIPTS+=("STEP4: The $RELEASE_VERSION release is successful")
  RELEASE_STEP_SCRIPTS+=("STEP5: Please check branch $RELEASE_BRANCH_NAME exist in the git repository")
  RELEASE_STEP_SCRIPTS+=("STEP6: Please check release tag v$RELEASE_VERSION exist in the git repository")
  RELEASE_STEP_SCRIPTS+=("STEP7: Please check master version changed to $NEXT_VERSION in the git repository")
}

main(){
  # =========================
  echo_e "${COLOR_GREEN}Initialize work directory${COLOR_CLEAN}"
  if [ ! -d $RELEASE_WORK_DIR ]; then
    mkdir -p $RELEASE_WORK_DIR
  fi
  cd $RELEASE_WORK_DIR
  echo_e "release home: "$RELEASE_WORK_DIR
  echo

  # =========================
  echo_e "${COLOR_GREEN}Download Repository${COLOR_CLEAN}"
  git clone $GIT_REPO_URL
  echo

  # =========================
  echo_e "${COLOR_GREEN}Build & Test${COLOR_CLEAN}"
  cd $GIT_REPO_NAME
  check_source_before_release
  echo

  # =========================
  echo_e "${COLOR_GREEN}Release Plan${COLOR_CLEAN}:"

  # current version
  current_maven_project_version

  # maintenance branch name
  RELEASE_BRANCH_NAME=${CURRENT_VERSION//0-SNAPSHOT/X}

  # release tag name
  RELEASE_VERSION=${CURRENT_VERSION//-SNAPSHOT/}

  # next minor version
  NEXT_VERSION=$(next_version $RELEASE_VERSION 1)-SNAPSHOT

  pre_release_steps

  echo_e "${COLOR_GREEN}===================================================================="
  echo_e "OS: $OS"
  echo_e "GIT_REPO_URL: $GIT_REPO_URL"
  echo_e "RELEASE WORK DIR: $RELEASE_WORK_DIR"
  echo_e "CURRENT VERSION: $CURRENT_VERSION"
  echo_e "MAINTENANCE BRANCH NAME: $RELEASE_BRANCH_NAME"
  echo_e "TAG NAME: v$RELEASE_VERSION"
  echo_e "RELEASE VERSION: $RELEASE_VERSION"
  echo_e "NEXT VERSION: $NEXT_VERSION"
  echo_e "====================================================================${COLOR_CLEAN}"

  for i in "${RELEASE_STEP_SCRIPTS[@]}"
  do
    echo_e "$i"
  done

  echo_e "${COLOR_GREEN}====================================================================${COLOR_CLEAN}\n"
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
        echo_e "${COLOR_RED}Invalid input${COLOR_CLEAN}"
        ;;
    esac
  done
}

# echo support color
echo_e(){
  if [ $OS == "Darwin" ];then
    echo $1
  else
    echo -e $1
  fi
}

main "$@"
