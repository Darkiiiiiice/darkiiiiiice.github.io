---
title: "X86_64 Linux ASM"
date: 2023-10-31T20:49:05+08:00
draft: false
description: "X86_64 Linux ASM 笔记"
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
| db | 8bit | Byte |
| dw | 16bit | Word |
| dd | 32bit | Double World|
| dq | 64bit | Quad Word | 


### .bss 段

bss 表示以符号开头的块 (Block Started by Symbol), 用来存放未初始化的变量
> <变量名称> <类型> <数字>

| 类型 | 长度 | 名称 |
| :-- | :-- | :-- |
| resb | 8bit | Byte |
| resw | 16bit | Word |
| resd | 32bit | Double World|
| resq | 64bit | Quad Word | 

> bss 段中的变量不包含任何值, 这些值将在程序运行时被分配, 内存位置不是在编译时保留的.

### .text 段

.text 段用于存放所有的操作, 并从以下代码开始执行

``` asm 
    global main
main: 
```

## 寄存器

### 通用寄存器

| 64位 | 32位 | 16位 | 低8位 | 高8位 | 备注 |
| :-- | :-- | :-- | :-- | :-- | :-- |
| rax | eax | ax | al | ah | |
| rbx | ebx | bx | bl | bh | |
| rcx | ecx | cx | cl | ch | |
| rdx | edx | dx | dl | dh | |
| rsi | esi | si | sil |-| |
| rdi | edi | di | dil |-| |
| rsp | esp | sp | spl |-| 基指针 |
| rbp | ebp | bp | bpl |-| 栈指针 |
| r8  | r8d | r8w | r8b |-| |
| r9  | r9d | r9w | r9b |-| |
| r10 | r10d | r10w | r10b |-| |
| r11 | r11d | r11w | r11b |-| |
| r12 | r12d | r12w | r12b |-| |
| r13 | r13d | r13w | r13b |-| |
| r14 | r14d | r14w | r14b |-| |
| r15 | r15d | r15w | r15b |-| |

> 低始终是最右边的位

### 指令指针寄存器 (rip)

处理器通过将下一条指令的地址存储在rip中来跟踪要执行的下一条指令
> 不应该直接修改rip的值, 而是使用跳转指令

### 标志寄存器 (Flag Register)

执行指令后, 程序可以检查是否设置了某个标志, 然后采取相应的动作

| 名称 | 标记 | 位 | 内容 |
|:--|:--|:--|:--|
| Carry | CF | 0 | 先前的指令有一个进位 |
| Parity | PF | 2 | 最后一个字节有偶数个 1 |
| Adjust | AF | 4 | BCD 操作 |
| Zero | ZF | 6 | 上一条指令的结果为 0 |
| Sign | SF | 8 | 上一条指令的最高有效位等于 1 |
| Direction | DF | 10 | 字符串操作的方向(递增或递减) |
| Overflow | OF | 11 | 上一条指令导致溢出 |
| MXCSR | | | |

### xmm 和 ymm 寄存器

这些寄存器用于浮点计算和SIMD

