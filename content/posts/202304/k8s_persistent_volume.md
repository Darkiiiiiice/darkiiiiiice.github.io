---
title: "K8S Persistent Volume"
date: 2023-04-04T10:07:22+08:00
lastmod: 2023-04-04T10:07:22+08:00
author: "MarioMang"
keywords: "linux,k8s,pv,persistent,persistent volume,volume"
categories:
    - linux
    - k8s
tags:
  - linux
  - k8s

toc: true
---

# Persistent Volume

``` yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: <name>
  annotations:
    <key>: <value>        # 可选。键值对形式的注释。
spec:
  capacity:
    storage: <size>       # 必需。存储的大小，例如 "500Gi"。
  accessModes:
    - <mode>              # 必需。存储的访问模式，例如 "ReadWriteOnce" 或 "ReadOnlyMany"。可以指定多个模式。
  persistentVolumeReclaimPolicy: <policy>  # 必需。当 PersistentVolume 没有与任何 PersistentVolumeClaim 关联时的回收策略。"Retain" 保留 PV，"Delete" 删除 PV，"Recycle" 回收 PV。
  storageClassName: <class-name>           # 可选。如果您的集群支持动态卷提供程序则可以指定存储类。否则请使用 "null"。
  mountOptions:
    - <option>            # 可选。挂载到 Pod 时需要使用的参数，例如 "hard"、"vers=3" 等。
  volumeMode: <mode>      # 可选。指定 PV 的访问模式是文件系统还是块，文件系统是默认值。
  nodeAffinity:
    <affinity>            # 可选。节点亲和性规则，确定如何将 PV 绑定到集群上的节点。
  persistentVolumeSource:
    <source>              # 必需。定义持久卷后端的类型和配置，如 GCEPersistentDisk、AWSElasticBlockStore、NFS 等。
```

说明：

* metadata：元数据字段，定义 PV 的名称和注释等信息。
* spec.capacity.storage：PV 的容量大小。
* spec.accessModes：指定访问模式。必须至少指定一个访问模式，可以指定多个访问模式。
* spec.persistentVolumeReclaimPolicy：定义 PV 回收策略，当 PV 所有关联的 PVC 都被删除后，应该怎样处理 PV。默认策略是 "Delete"。
* spec.storageClassName：如果您在集群中启用了动态卷提供程序，则可以指定 PV 所属的存储类。否则，可将其设置为 "null"。
* spec.mountOptions：当将 PV 挂载到 Pod 时使用的选项，例如 "hard"、"vers=3" 等。
* spec.volumeMode：PV 的访问模式，支持文件系统和块两种模式，文件系统是默认值。
* spec.nodeAffinity：节点亲和性规则，确定 PV 如何绑定到集群上的节点。
* spec.persistentVolumeSource：定义 PV 的后端类型和配置。包括：AWS EBS、GCE PD、RBD、iSCSI、NFS、GlusterFS、CephFS、Cinder、FC 等。
