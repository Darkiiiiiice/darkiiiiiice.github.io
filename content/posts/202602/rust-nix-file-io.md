---
title: "Rust nix 库：文件 I/O 系统调用"
date: 2026-02-25T11:00:00+08:00
draft: false
---

本文介绍如何使用 Rust 的 `nix` 库进行文件 I/O 操作。`nix` 提供了对 Unix 系统调用的类型安全封装，是 Rust 系统编程的常用库。

## 添加依赖

```toml
# Cargo.toml
[dependencies]
nix = { version = "0.29", features = ["fs"] }
```

## 文件描述符

在 `nix` 中，文件描述符使用 `RawFd`（原始文件描述符）或 `OwnedFd`（拥有所有权的文件描述符）表示。

```rust
use nix::unistd::{self, RawFd};

// 标准文件描述符常量
use nix::libc::{
    STDIN_FILENO,   // 0
    STDOUT_FILENO,  // 1
    STDERR_FILENO,  // 2
};
```

## open - 打开/创建文件

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::unistd::close;
use std::path::Path;
```

### OFlag 标志

`OFlag` 是位标志的集合，常用的有：

| 标志 | 说明 |
|------|------|
| O_RDONLY | 只读 |
| O_WRONLY | 只写 |
| O_RDWR | 读写 |
| O_CREAT | 不存在则创建 |
| O_EXCL | 与 O_CREAT 一起使用，存在则报错 |
| O_TRUNC | 截断为 0 长度 |
| O_APPEND | 追加模式 |
| O_NONBLOCK | 非阻塞 |
| O_SYNC | 同步写入 |
| O_CLOEXEC | close-on-exec 标志 |

### Mode 权限

```rust
use nix::sys::stat::Mode;
```

| 常量 | 值 | 说明 |
|------|-----|------|
| S_IRUSR | 0o400 | 用户读 |
| S_IWUSR | 0o200 | 用户写 |
| S_IXUSR | 0o100 | 用户执行 |
| S_IRGRP | 0o040 | 组读 |
| S_IWGRP | 0o020 | 组写 |
| S_IXGRP | 0o010 | 组执行 |
| S_IROTH | 0o004 | 其他读 |
| S_IWOTH | 0o002 | 其他写 |
| S_IXOTH | 0o001 | 其他执行 |

### 示例

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::unistd::close;
use std::path::Path;

fn main() -> nix::Result<()> {
    // 以读写方式打开现有文件
    let fd1 = open(
        Path::new("/tmp/test.txt"),
        OFlag::O_RDWR,
        Mode::empty(),
    )?;

    // 创建新文件，权限 0644 (rw-r--r--)
    let fd2 = open(
        Path::new("/tmp/newfile.txt"),
        OFlag::O_WRONLY | OFlag::O_CREAT | OFlag::O_TRUNC,
        Mode::S_IRUSR | Mode::S_IWUSR | Mode::S_IRGRP | Mode::S_IROTH,
    )?;

    close(fd1)?;
    close(fd2)?;

    Ok(())
}
```

## close - 关闭文件

```rust
use nix::unistd::close;

// 关闭文件描述符
close(fd)?;
```

`close` 返回 `Result<(), Errno>`，使用 `?` 进行错误传播。

## read - 读取文件

```rust
use nix::unistd::read;

// read 返回实际读取的字节数
let n = read(fd, &mut buf)?;
```

### 示例

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::unistd::{read, close};
use std::path::Path;

fn main() -> nix::Result<()> {
    let fd = open(
        Path::new("/etc/passwd"),
        OFlag::O_RDONLY,
        Mode::empty(),
    )?;

    let mut buf = [0u8; 1024];

    loop {
        let n = read(fd, &mut buf)?;
        if n == 0 {
            break; // EOF
        }

        // 处理读取的数据
        let data = &buf[..n];
        // 例如打印到标准输出
        std::io::stdout().write_all(data).unwrap();
    }

    close(fd)?;
    Ok(())
}
```

## write - 写入文件

```rust
use nix::unistd::write;

// write 返回实际写入的字节数
let n = write(fd, &data)?;
```

### 示例

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::unistd::{write, close};
use std::path::Path;

fn main() -> nix::Result<()> {
    let fd = open(
        Path::new("/tmp/test.txt"),
        OFlag::O_WRONLY | OFlag::O_CREAT | OFlag::O_TRUNC,
        Mode::S_IRUSR | Mode::S_IWUSR | Mode::S_IRGRP | Mode::S_IROTH,
    )?;

    let msg = b"Hello, Rust nix library!\n";
    let n = write(fd, msg)?;
    println!("Written {} bytes", n);

    close(fd)?;
    Ok(())
}
```

## pread / pwrite - 定位读写

```rust
use nix::unistd::{pread, pwrite};
```

`pread` 和 `pwrite` 在指定偏移量处进行读写，**不改变文件当前偏移量**。

### 示例

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::unistd::{write, pread, pwrite, close, lseek, Whence};
use std::path::Path;

fn main() -> nix::Result<()> {
    let fd = open(
        Path::new("/tmp/test_pread.txt"),
        OFlag::O_RDWR | OFlag::O_CREAT | OFlag::O_TRUNC,
        Mode::S_IRUSR | Mode::S_IWUSR,
    )?;

    // 写入一些数据
    let data = b"0123456789ABCDEFGHIJ";
    write(fd, data)?;

    // 在偏移量 5 处读取 3 字节（不改变文件偏移量）
    let mut buf = [0u8; 3];
    let n = pread(fd, &mut buf, 5)?;
    println!("Read at offset 5: {}", String::from_utf8_lossy(&buf[..n]));
    // 输出: 567

    // 当前文件偏移量仍在末尾
    let pos = lseek(fd, 0, Whence::SeekCur)?;
    println!("Current offset: {}", pos); // 输出: 20

    // 在偏移量 10 处写入
    pwrite(fd, b"XXX", 10)?;

    close(fd)?;
    Ok(())
}
```

## readv / writev - Scatter/Gather I/O

```rust
use nix::sys::uio::{readv, writev, IoVec};
```

`IoVec` 是对字节数组切片的封装，用于表示 I/O 向量。

### 示例

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::sys::uio::{writev, readv, IoVec};
use nix::unistd::{lseek, Whence, close};
use std::path::Path;

fn main() -> nix::Result<()> {
    let fd = open(
        Path::new("/tmp/test_iov.txt"),
        OFlag::O_RDWR | OFlag::O_CREAT | OFlag::O_TRUNC,
        Mode::S_IRUSR | Mode::S_IWUSR,
    )?;

    // writev 示例：将多个缓冲区一次写入
    let part1 = b"Hello, ";
    let part2 = b"Scatter/Gather ";
    let part3 = b"I/O!\n";

    let iov = [
        IoVec::from_slice(part1),
        IoVec::from_slice(part2),
        IoVec::from_slice(part3),
    ];

    let nwritten = writev(fd, &iov)?;
    println!("Total written: {} bytes", nwritten);

    // readv 示例：读入多个缓冲区
    lseek(fd, 0, Whence::SeekSet)?;

    let mut buf1 = [0u8; 8];
    let mut buf2 = [0u8; 16];
    let mut buf3 = [0u8; 8];

    let mut iov = [
        IoVec::from_mut_slice(&mut buf1),
        IoVec::from_mut_slice(&mut buf2),
        IoVec::from_mut_slice(&mut buf3),
    ];

    let nread = readv(fd, &mut iov)?;
    println!("Total read: {} bytes", nread);

    println!("buf1: [{}]", String::from_utf8_lossy(&buf1));
    println!("buf2: [{}]", String::from_utf8_lossy(&buf2));
    println!("buf3: [{}]", String::from_utf8_lossy(&buf3));

    close(fd)?;
    Ok(())
}
```

## preadv / pwritev - 定位 Scatter/Gather I/O

```rust
use nix::sys::uio::{preadv, pwritev, IoVec};
```

`preadv` 和 `pwritev` 结合了定位读写和 scatter/gather I/O。

### 示例

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::sys::uio::{pwritev, preadv, IoVec};
use nix::unistd::close;
use std::path::Path;

fn main() -> nix::Result<()> {
    let fd = open(
        Path::new("/tmp/test_piov.txt"),
        OFlag::O_RDWR | OFlag::O_CREAT | OFlag::O_TRUNC,
        Mode::S_IRUSR | Mode::S_IWUSR,
    )?;

    // 准备数据
    let header = b"===HEADER===";
    let body = b"This is the body content";
    let footer = b"===FOOTER===";

    let iov = [
        IoVec::from_slice(header),
        IoVec::from_slice(body),
        IoVec::from_slice(footer),
    ];

    // 从偏移量 0 开始写入
    let n = pwritev(fd, &iov, 0)?;
    println!("Written {} bytes", n);

    // 读取中间部分（从 header 之后开始）
    let mut rdbuf = [0u8; 32];
    let mut iov = [IoVec::from_mut_slice(&mut rdbuf)];

    let n = preadv(fd, &mut iov, header.len() as i64)?;
    let read_str = String::from_utf8_lossy(&rdbuf[..n]);
    println!("Read body: [{}]", read_str);

    close(fd)?;
    Ok(())
}
```

## 完整示例：文件复制

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::unistd::{read, write, close};
use std::path::Path;

const BUFFER_SIZE: usize = 8192;

fn copy_file(src: &Path, dst: &Path) -> nix::Result<()> {
    // 打开源文件
    let src_fd = open(src, OFlag::O_RDONLY, Mode::empty())?;

    // 创建目标文件
    let dst_fd = open(
        dst,
        OFlag::O_WRONLY | OFlag::O_CREAT | OFlag::O_TRUNC,
        Mode::S_IRUSR | Mode::S_IWUSR | Mode::S_IRGRP | Mode::S_IROTH,
    )?;

    // 复制数据
    let mut buf = [0u8; BUFFER_SIZE];
    loop {
        let n = read(src_fd, &mut buf)?;
        if n == 0 {
            break;
        }
        write(dst_fd, &buf[..n])?;
    }

    close(src_fd)?;
    close(dst_fd)?;

    Ok(())
}

fn main() -> nix::Result<()> {
    copy_file(
        Path::new("/etc/hostname"),
        Path::new("/tmp/hostname_copy"),
    )?;
    println!("File copied successfully!");
    Ok(())
}
```

## 使用 OwnedFd 自动管理生命周期

`nix` 0.29+ 支持 `OwnedFd`，可以在 RAII 模式下自动关闭文件描述符：

```rust
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use std::os::unix::io::{AsFd, AsRawFd, FromRawFd, IntoRawFd};
use std::path::Path;

fn main() -> nix::Result<()> {
    // 获取 OwnedFd
    let fd = open(
        Path::new("/tmp/test.txt"),
        OFlag::O_RDWR | OFlag::O_CREAT | OFlag::O_TRUNC,
        Mode::S_IRUSR | Mode::S_IWUSR,
    )?;

    // 转换为 std::fs::File（自动管理关闭）
    let file = unsafe { std::fs::File::from_raw_fd(fd) };

    // 使用 std::fs::File 的方法
    use std::io::Write;
    file.write_all(b"Hello from Rust!\n")?;

    // file 离开作用域时自动关闭

    Ok(())
}
```

## 错误处理

`nix` 使用 `Result<T, Errno>` 进行错误处理，`Errno` 是对 `errno` 的类型安全封装：

```rust
use nix::errno::Errno;

fn main() {
    match open(Path::new("/nonexistent"), OFlag::O_RDONLY, Mode::empty()) {
        Ok(fd) => {
            close(fd).unwrap();
        }
        Err(Errno::ENOENT) => {
            eprintln!("File not found");
        }
        Err(Errno::EACCES) => {
            eprintln!("Permission denied");
        }
        Err(e) => {
            eprintln!("Error: {}", e);
        }
    }
}
```

### 常见 Errno

| Errno | 说明 |
|-------|------|
| ENOENT | 文件不存在 |
| EACCES | 权限不足 |
| EEXIST | 文件已存在 |
| EINTR | 被信号中断 |
| EINVAL | 参数无效 |
| EBADF | 无效文件描述符 |
| ENOSPC | 设备空间不足 |

## API 对照表

| C 系统调用 | nix 函数 | 模块 |
|-----------|----------|------|
| open() | open() | nix::fcntl |
| creat() | (使用 open + O_CREAT) | nix::fcntl |
| close() | close() | nix::unistd |
| read() | read() | nix::unistd |
| write() | write() | nix::unistd |
| pread() | pread() | nix::unistd |
| pwrite() | pwrite() | nix::unistd |
| readv() | readv() | nix::sys::uio |
| writev() | writev() | nix::sys::uio |
| preadv() | preadv() | nix::sys::uio |
| pwritev() | pwritev() | nix::sys::uio |
| lseek() | lseek() | nix::unistd |

## 与标准库对比

| 特性 | std::fs / std::io | nix |
|------|-------------------|-----|
| 抽象级别 | 高级 | 底层（接近系统调用） |
| 类型安全 | 高 | 高 |
| 错误处理 | std::io::Error | nix::errno::Errno |
| 灵活性 | 适中 | 高（完整访问 flags） |
| 跨平台 | 是 | Unix only |
| 学习曲线 | 简单 | 需要了解 Unix |

一般建议：
- 日常文件操作使用 `std::fs`
- 需要特定系统调用标志或底层控制时使用 `nix`
- 系统编程、网络编程、信号处理等场景首选 `nix`

## 参考资料

- [nix crate 文档](https://docs.rs/nix/)
- [nix GitHub 仓库](https://github.com/nix-rust/nix)
- man 2 open, man 2 read, man 2 write
- 《The Rust Programming Language》
