---
title: "Install kafka cluster with docker"
date: 2023-08-07T23:01:44+08:00
description: "使用docker搭建kafak集群"
keywords: "linux,kafka,docker,zookeeper"
lastmod: 2023-08-07T23:01:44+08:00

categories:
  - linux
  - kafka
tags:
  - linux
  - kafka
  - docker
  - zookeeper

author: MarioMang
toc: true
---

为了方便搭建 kafka集群进行学习和开发，在此记录一下搭建的过程
使用docker来实现单节点zookeeper和三个节点的kafka集群的创建

### 创建docker网络

``` bash
docker network create kafka-cluster
```

### 创建卷

``` bash
docker volume create zk-data
docker volume create zk-datalog
docker volume create zk-logs
```

### 拉取镜像

``` bash
docker pull bitnami/zookeeper:3.8.2
docker pull bitnami/kafka:2.3.1
```

### 启动单节点 zookeeper

``` bash
docker run -d \
    --network kafka-cluster \
    --name zookeeper \
    -p 9000:2181 \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    -v zk-data:/data \
    -v zk-datalog:/datalog \
    -v zk-logs:/logs \
    -v /etc/localtime:/etc/localtime \
    bitnami/zookeeper:3.8.2
```

### 启动三个节点的kafak

#### kafka00 节点

``` bash
 docker run -d \
    --restart=always \
    --name kafka00 \
    --network kafka-cluster \
    -p 9100:9092 \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_BROKER_ID=0 \
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka00:9092 \
    -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 \
    -v /etc/localtime:/etc/localtime \
    bitnami/kafka:2.3.1
```

#### kafka01 节点

``` bash
 docker run -d \
    --restart=always \
    --name kafka01 \
    --network kafka-cluster \
    -p 9101:9092 \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_BROKER_ID=1 \
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka01:9092 \
    -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 \
    -v /etc/localtime:/etc/localtime \
    bitnami/kafka:2.3.1
```

#### kafka02 节点

``` bash
 docker run -d \
    --restart=always \
    --name kafka02 \
    --network kafka-cluster \
    -p 9102:9092 \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_BROKER_ID=2 \
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka02:9092 \
    -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 \
    -v /etc/localtime:/etc/localtime \
    bitnami/kafka:2.3.1
```

### 验证是否启动成功

进入 kafka00 节点，发送消息

``` bash
docker exec -it kafka00 bash
cd /opt/bitnami/kafka/bin/
./kafka-console-producer.sh --broker-list localhost:9092 --topic test_topic
```

进入 kafka02 节点，接收消息

``` bash
docker exec -it kafka02 bash
cd /opt/bitnami/kafka/bin/
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test_topic --from-beginning
```
