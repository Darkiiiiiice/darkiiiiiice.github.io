---
title: "Install ansible debian"
date: 2023-08-05T19:10:27+08:00
description: "在debian上安装ansible的bash脚本"
keywords: "debian,linux,ansible,bash"
lastmod: 2023-08-05T19:10:27+08:00

categories:
  - linux
  - ansible
tags:
  - linux
  - ansible

author: MarioMang
toc: true
---

# Install ansible debain

## Install

``` bash
#! /bin/bash
#

sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible
``
