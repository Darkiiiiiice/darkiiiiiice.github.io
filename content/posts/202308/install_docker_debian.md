---
title: "Debian安装 Docker Engine 脚本"
description: "在debian上安装docker engine的bash脚本"
keywords: "debian,linux,docker,bash"

date: 2023-08-05T18:19:36+08:00
lastmod: 2023-08-05T18:19:36+08:00

categories:
  - linux
  - docker
tags:
  - linux
  - docker

author: MarioMang
toc: true
---

# Debian 12 中安装 Docker Engine 脚本

## Install

``` bash
#! /bin/bash
#
#
#

DOCKER_REGISTRY="https://giliog9w.mirror.aliyuncs.com"

# remove package
function remove_docker() {
 echo  '==================== Remove docker package ===================='
 for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
}

# update apt package
function update_apt() {
 echo  '==================== Update apt package ===================='
 sudo apt-get update -y
}

# install tools
function install_tools() {
 echo  '==================== Install tools ===================='
 sudo apt-get install -y ca-certificates curl gnupg
}

# add docker's gpg key
function add_gpg() {
 echo  '==================== Add docker gpg key ===================='
 sudo install -m 0755 -d /etc/apt/keyrings
 sudo rm /etc/apt/keyrings/docker.gpg
 curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
 sudo chmod a+r /etc/apt/keyrings/docker.gpg
}

# use the following command to set up the repository
function set_up_repository() {
 echo  '==================== Set up the repository ===================='
 echo \
   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
   "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}


# install docker engine, containerd, docker compose
function install() {
 echo  '==================== Install docker engine ===================='
 update_apt
 sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
 set_registry
}

# run test
function check() {
 echo  '==================== Run test container ===================='
 if [ $(sudo docker ps -a | awk '{print $1}' | grep -c "") -le 1 ];
 then
  sudo docker run -d --name hello-world hello-world;
  if [ $(sudo docker ps -a | grep -c "hello-world")  -ge 1 ];
  then echo "+++++++++++++++ Install docker success!!!" && sudo docker rm hello-world;
  else echo "--------------- Install docker failed" && ./uninstall_docker.sh;
  fi
 fi
}

# set registry
function set_registry() {
 sudo mkdir /etc/docker
 sudo tee /etc/docker/daemon.json <<-'EOF'
 {
   "registry-mirrors": ["DOCKER_REGISTRY"]
 }
 EOF
 sudo sed -i -e 's!DOCKER_REGISTRY!'$DOCKER_REGISTRY'!g' /etc/docker/daemon.json
 sudo systemctl daemon-reload
 sudo systemctl restart docker
}


echo "Install docker engine for $(. /etc/os-release && echo $NAME $VERSION_ID $VERSION_CODENAME)"
remove_docker && update_apt && install_tools && add_gpg && set_up_repository && install && check
```

## Uninstall

``` bash
#! /bin/bash
#
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
```
