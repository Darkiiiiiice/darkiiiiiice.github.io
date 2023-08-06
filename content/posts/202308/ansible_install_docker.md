---
title: "安装docker的ansible playbook模版"
date: 2023-08-06T16:54:12+08:00
description: "使用ansible批量安装docker的playbook模版"
keywords: "linux,ansible,docker,ansible-playbook,playbook"
lastmod: 2023-08-06T16:54:12+08:00

categories:
  - linux
  - ansible
tags:
  - linux
  - ansible
  - docker

author: MarioMang
toc: true
---

为了方便在集群中批量安装docker，写了一份ansible playbook的模版

### daemon.json

``` json
{
  "registry-mirrors": ["https://giliog9w.mirror.aliyuncs.com"]
}
```

### playbook.yaml

安装模版

``` yaml
---
- hosts: all
  remote_user: user
  tasks:
    - name:  remove docker package
      become: yes
      shell: apt-get remove {{ item }}
      with_items:
        - docker.io
        - docker-doc
        - docker-compose
        - podman-docker
        - containerd
        - runc
    - name: clean resources
      become: yes
      shell: rm -r {{ item }}
      with_items:
        - /etc/apt/keyrings/docker.gpg
        - /etc/apt/sources.list.d/docker.list
        - /etc/docker
      ignore_errors: True
    - name:  update apt package
      shell: apt-get update -y
      become: yes
    - name:  install apt package
      shell: apt-get install -y {{ item }}
      become: yes
      with_items:
        - ca-certificates
        - curl
        - gnupg
        - firewalld
    - name: install keyrings
      become: yes
      shell: install -m 0755 -d /etc/apt/keyrings
    - name: curl docker gpg
      shell: curl -fsSL https://download.docker.com/linux/debian/gpg -o /tmp/a.out
    - name: dearmor docker gpg
      become: yes
      shell: sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg  /tmp/a.out
    - name: chomod docker gpg
      become: yes
      shell: sudo chmod a+r /etc/apt/keyrings/docker.gpg
    - name: clean temp
      become: yes
      shell: sudo rm /tmp/a.out
      ignore_errors: True
    - name: mkdir docker config
      shell: mkdir /etc/docker
      become: yes
    - name: set up the repository
      become: yes
      shell: echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" >> /etc/apt/sources.list.d/docker.list
    - name: set docker repository
      copy: src=./daemon.json dest=/etc/docker/daemon.json
      become: yes
    - name:  update apt package
      shell: apt-get update -y
      become: yes
    - name:  install docker
      shell: apt-get install -y {{ item }}
      become: yes
      with_items:
        - docker-ce
        - docker-ce-cli
        - containerd.io
        - docker-buildx-plugin
        - docker-compose-plugin
    - name: daemon-reload
      shell: systemctl daemon-reload
      become: yes
    - name: restart docker
      shell: systemctl restart docker
      become: yes
```

卸载模版

``` yaml
---
- hosts: all
  remote_user: mariomang
  tasks:
    - name:  remove docker package
      become: yes
      shell: apt-get purge -y {{ item }}
      with_items:
        - docker-ce
        - docker-ce-cli
        - containerd.io
        - docker-buildx-plugin
        - docker-compose-plugin
        - docker-ce-rootless-extras
    - name: clean resources
      become: yes
      shell: rm -r {{ item }}
      with_items:
        - /etc/apt/keyrings/docker.gpg
        - /etc/apt/sources.list.d/docker.list
        - /etc/docker
        - /var/lib/docker
        - /var/lib/containerd
        - /etc/docker
      ignore_errors: True
```
