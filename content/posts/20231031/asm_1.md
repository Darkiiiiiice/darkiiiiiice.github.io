---
title: "X86_64 Linux ASM 结构"
date: 2023-10-31T20:49:05+08:00
draft: false
description: "X86_64 Linux ASM 结构笔记"
keywords: "linux,asm"
lastmod: 2023-10-31T20:49:05+08:00

categories:
  - linux
  - asm
tags:
  - linux
  - asm

author: MarioMang
toc: true
---

## 汇编结构

### .data 段

在.data 段中使用以下格式声明和定义初始化数据
> <变量名称> <类型> <变量值>

数据类型

| 类型 | 长度 | 名称 |
| :-- | :-- | :-- |
| db | 8B | Byte |
| dw | 16B | Word |
| dd | 32B | Double World|
| dq | 64B | Quad Word | 


### .bss 段

bss 表示以符号开头的块 (Block Started by Symbol), 用来存放未初始化的变量
> <变量名称> <类型> <数字>

| 类型 | 长度 | 名称 |
| :-- | :-- | :-- |
| resb | 8B | Byte |
| resw | 16B | Word |
| resd | 32B | Double World|
| resq | 64B | Quad Word | 

> bss 段中的变量不包含任何值, 这些值将在程序运行时被分配, 内存位置不是在编译时保留的.

### .text 段

.text 段用于存放所有的操作, 并从以下代码开始执行

``` asm 
    global main
main: 
```



