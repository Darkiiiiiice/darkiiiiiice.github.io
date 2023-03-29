+++
title = "ARP 地址解析协议"
date = "2023-03-19T00:24:36+08:00"
author = "MarioMang"
authorTwitter = "" #do not include @
cover = "images/default_cover.gif"
tags = ["internet", "protocol"]
keywords = ["internet", "protocol", "arp"]
description = ""
showFullContent = false
readingTime = true
hideComments = false
color = "red" #color from the theme settings
+++


# ARP(Address Resolution Protocol)
>
> 地址解析协议

## 引言

传统IPv4网络需要使用32位的IPv4地址和48位的硬件地址, 才可以将一个帧发送至另外一台主机
*地址解析协议*[ARP](RFC0826) 提供了在IPv4地址和硬件地址之间的映射, ARP 仅用于IPv4, IPv6使用邻居发现协议, 它被合并入ICMPv6

## ARP缓存

ARP高效运行的关键是维护在每个主机和路由器上的ARP缓存, 该缓存使用地址解析为每个接口维护从网络层地址到硬件地址的最新映射

Linux下使用arp命令查看ARP缓存

``` shell {linenos=false}
$ arp
Address     HWtype HWaddress         FlagsMask  Iface
192.168.1.1 ether  f4:0f:3b:2a:4b:ec C          eno1
```

arp -a 用于显示缓存中的所有条目

``` shell {linenos=false}
$ arp -a
domain (192.168.199.121) at f4:0f:24:2a:4b:ec [ether] on eno1
```

## ARP帧格式

|字段|DST|SRC|TYPE|HardwareType|ProtocolType|HardwareLength|ProtoclLength|Op|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|字节|6|6|2|2|2|1|1|2|

|字段|SRC MAC|SRC IP|DST MAC|DST IP|Padding|FCS|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|字节|6|6|6|6|18|4

字段解释

|字段| 名称 | 字节 | 值 |
|:-:|:-:|:-:|:-:|
|DST| 目的地址 | 6 | [ff:ff:ff:ff:ff:ff] |
|SRC| 来源地址 | 6 | [12:34:56:78:9a:bc] |
|TYPE| 长度或类型 | 2| ARP 该字段必须为 0x0806 |
|Hardware Type| 硬件类型 | 2 | 0x01 |
|Protocol Type| 协议类型 | 2 | 0x0800|
|Hardware Len | 硬件大小 | 1 | 0x06 |
|Protocol Len | 协议大小 | 1 | 0x04 |
| Op          | 操作    | 2 | ARP请求=0x01 ARP应答=0x02 RARP请求=0x03 RARP应答=0x04|
| SRC MAC | 源硬件地址 | 6 | [12:34:56:78:9a:bc] |
| SRC IP  | 源IPv4地址| 4 | [123.123.123.123] |
| DST MAC | 目标硬件地址|6 | [12:34:56:78:9a:bc] |
| DST IP  | 目标IPv4地址|4| [123.123.123.123] |
| Padding | 填充字段 | 18 | 0x00 |
| FCS |             | 4  |      |

## ARP 缓存超时

在大多数实现中, 完成条目的超时为20分钟, 不完整条目的超时时间为3分钟

## ARP数据包发送与接收

### 发送ARP数据包

1. Linux:
    * 首先实现一个 htons, 因为 Socket() 中 protocol 参数占用两个字节，所以实现一个 int16 的 htons 就可以了

    ``` go
        func Htons16(n int) int {
            return (n & 0xFF) << 8 + (n >> 8) & 0xFF
        }
    ```

    * 定义 Arp Packet 结构

    ``` go
        // ArpPacket  ARP数据包
        type ArpPacket struct {
            DstMac [6]byte // 目的地址
            SrcMac [6]byte // 来源地址
            Frame  uint16  // 长度或类型

            HwType     uint16   // 硬件类型
            ProtoType  uint16   // 协议类型
            HwLen      byte     // 硬件大小
            ProtoLen   byte     // 协议大小
            Op         uint16   // 操作
            ArpSrcMac  [6]byte  // 源硬件地址
            ArpSrcIp   [4]byte  // 源IPv4地址
            ArpDstMac  [6]byte  // 目标硬件地址
            ArpDstIp   [4]byte  // 目标IPv4地址
            ArpPadding [18]byte // 填充字段
            //ArpFCS     [4]byte
        }
    ```

    * 构造 Arp 数据包

    ``` go
        // 构造arp数据包
        packet := new(arp.ArpPacket)
        // 构造头部信息
        copy(packet.DstMac[:], dstMac)
        copy(packet.SrcMac[:], eno1.HardwareAddr)
        packet.Frame = syscall.ETH_P_ARP

        // 构造ARP类型
        packet.HwType = 0x01
        packet.ProtoType = 0x0800
        packet.HwLen = 0x06
        packet.ProtoLen = 0x04
        packet.Op = ArpRequest

        // 构造来源ARP地址信息
        srcIp := net.ParseIP("192.168.199.153")
        copy(packet.ArpSrcMac[:], eno1.HardwareAddr)
        copy(packet.ArpSrcIp[:], srcIp.To4())

        // 构造目的ARP地址信息
        dstIp := net.ParseIP("192.168.199.101")
        //copy(packet.ArpDstMac[:], dstMac)
        copy(packet.ArpDstIp[:], dstIp.To4())
    ```

    * 建立原始套接字

    ``` go
        sockfd, err := syscall.Socket(
            syscall.AF_PACKET,
            syscall.SOCK_RAW,
            arp.Htons16(syscall.ETH_P_ARP))
        if err != nil {
            log.Fatalln(err)
        }
    ```

    * 发送数据包并关闭 Socket

    ``` go {linenos=inline,hl_lines=[3,"6-9"]}
        // 将Packet结构转为bytes
        buffer := bytes.NewBuffer(make([]byte, 0))
        if err := binary.Write(buffer, binary.BigEndian, packet); err != nil {
            log.Fatalln(err)
        }

        // 发送数据
        if err = syscall.Sendto(sockfd, buffer.Bytes(), 0, linklayer); err != nil {
            log.Fatalln(err)
        }

        // 关闭套接字

  if err := syscall.Close(sockfd); err != nil {
   log.Fatalln(err)
  }

    ```

2. Mac OS X
    > 需要使用BPF实现, 等有空的时候再实现

### 接收ARP数据包

1. Linux
    * 建立原始套接字

    ``` go
        // 通过 Linux 原始套接字完成数据包的接收
        recvFd, err := syscall.Socket(
            syscall.AF_PACKET,
            syscall.SOCK_RAW,
            arp.Htons16(syscall.ETH_P_ARP))
        if err != nil {
            log.Fatalln(err)
        }
    ```

    * 接受 Arp 数据包

    ``` go
        // 数据会读取进buf切片中
        buf := make([]byte, 60)

  n, fromAddr, err := syscall.Recvfrom(recvFd, buf, 0)
  if err != nil {
   log.Fatalln(err)
        }
    ```

    * 解析数据包

    ``` go
        packet := new(arp.ArpPacket)
  buffer := bytes.NewBuffer(buf)
  if err := binary.Read(buffer, binary.BigEndian, packet); err != nil {
   log.Fatalln(err)
  }
    ```

    * 关闭套接字

    ``` go
        // 关闭套接字
        if err := syscall.Close(recvFd); err != nil {
            log.Fatalln(err)
        }
    ```

2. Mac OS X
    > 需要使用BPF实现, 等有空的时候再实现
