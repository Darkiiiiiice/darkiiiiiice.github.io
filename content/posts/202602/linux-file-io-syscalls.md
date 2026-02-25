---
title: "Linux 文件 I/O 系统调用"
date: 2026-02-25T10:00:00+08:00
draft: false
---

本文介绍 Linux 中用于文件 I/O 的系统调用，包括基础的 open、read、write、close，以及更高级的 scatter/gather I/O 和定位读写操作。

## 文件描述符

在 Linux 中，所有打开的文件都通过**文件描述符**（File Descriptor）来引用。文件描述符是一个非负整数。

内核为每个进程维护一个文件描述符表，其中包含三个预定义的描述符：

| 描述符 | 名称 | 宏定义 | 说明 |
|--------|------|--------|------|
| 0 | 标准输入 | STDIN_FILENO | 默认从键盘输入 |
| 1 | 标准输出 | STDOUT_FILENO | 默认输出到终端 |
| 2 | 标准错误 | STDERR_FILENO | 默认输出到终端 |

## open - 打开/创建文件

```c
#include <fcntl.h>

int open(const char *pathname, int flags);
int open(const char *pathname, int flags, mode_t mode);
```

### flags 参数

flags 参数由以下常量通过位或运算组合：

**必选其一（访问模式）：**

| 常量 | 说明 |
|------|------|
| O_RDONLY | 只读打开 |
| O_WRONLY | 只写打开 |
| O_RDWR | 读写打开 |

**可选标志：**

| 常量 | 说明 |
|------|------|
| O_CREAT | 文件不存在则创建，需要 mode 参数 |
| O_EXCL | 与 O_CREAT 一起使用，文件存在则报错 |
| O_TRUNC | 文件存在且以写方式打开，则截断为 0 长度 |
| O_APPEND | 追加模式，每次写入都在文件末尾 |
| O_NONBLOCK | 非阻塞模式 |
| O_SYNC | 同步写入，确保数据写入磁盘 |
| O_DSYNC | 同步写入，确保数据完整性 |
| O_CLOEXEC | 设置 close-on-exec 标志 |

### mode 参数

当使用 O_CREAT 时，需要指定文件权限：

| 常量 | 值 | 说明 |
|------|-----|------|
| S_IRUSR | 0400 | 用户读权限 |
| S_IWUSR | 0200 | 用户写权限 |
| S_IXUSR | 0100 | 用户执行权限 |
| S_IRGRP | 0040 | 组读权限 |
| S_IWGRP | 0020 | 组写权限 |
| S_IXGRP | 0010 | 组执行权限 |
| S_IROTH | 0004 | 其他读权限 |
| S_IWOTH | 0002 | 其他写权限 |
| S_IXOTH | 0001 | 其他执行权限 |

### 示例

```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main() {
    // 以读写方式打开现有文件
    int fd1 = open("/tmp/test.txt", O_RDWR);
    if (fd1 == -1) {
        perror("open");
        return 1;
    }

    // 创建新文件，权限 0644 (rw-r--r--)
    int fd2 = open("/tmp/newfile.txt",
                   O_WRONLY | O_CREAT | O_TRUNC,
                   S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
    if (fd2 == -1) {
        perror("open create");
        close(fd1);
        return 1;
    }

    close(fd1);
    close(fd2);
    return 0;
}
```

## creat - 创建文件

```c
#include <fcntl.h>

int creat(const char *pathname, mode_t mode);
```

`creat` 等价于：

```c
open(pathname, O_WRONLY | O_CREAT | O_TRUNC, mode);
```

由于 `open` 可以完全替代 `creat`，现代代码中很少直接使用 `creat`。

## close - 关闭文件

```c
#include <unistd.h>

int close(int fd);
```

关闭文件描述符，释放相关资源。成功返回 0，失败返回 -1。

## read - 读取文件

```c
#include <unistd.h>

ssize_t read(int fd, void *buf, size_t count);
```

从文件描述符 `fd` 读取最多 `count` 字节到缓冲区 `buf`。

### 返回值

- 成功：返回实际读取的字节数（可能小于 count）
- 到达文件末尾：返回 0
- 失败：返回 -1，并设置 errno

### 示例

```c
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>

int main() {
    int fd = open("/etc/passwd", O_RDONLY);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    char buf[1024];
    ssize_t n;

    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        // 处理读取的数据
        write(STDOUT_FILENO, buf, n);
    }

    if (n == -1) {
        perror("read");
    }

    close(fd);
    return 0;
}
```

## write - 写入文件

```c
#include <unistd.h>

ssize_t write(int fd, const void *buf, size_t count);
```

将缓冲区 `buf` 中 `count` 字节写入文件描述符 `fd`。

### 返回值

- 成功：返回实际写入的字节数
- 失败：返回 -1，并设置 errno

### 示例

```c
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

int main() {
    int fd = open("/tmp/test.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    const char *msg = "Hello, Linux System Calls!\n";
    ssize_t n = write(fd, msg, strlen(msg));
    if (n == -1) {
        perror("write");
    }

    close(fd);
    return 0;
}
```

## pread / pwrite - 定位读写

```c
#include <unistd.h>

ssize_t pread(int fd, void *buf, size_t count, off_t offset);
ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset);
```

`pread` 和 `pwrite` 在指定偏移量处进行读写，**不改变文件当前偏移量**。

这相当于原子地执行了 `lseek` + `read`/`write`，在多线程环境下特别有用。

### 示例

```c
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>

int main() {
    int fd = open("/tmp/test.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    // 写入一些数据
    const char *data = "0123456789ABCDEFGHIJ";
    write(fd, data, strlen(data));

    // 在偏移量 5 处读取 3 字节（不改变文件偏移量）
    char buf[4] = {0};
    ssize_t n = pread(fd, buf, 3, 5);
    printf("Read at offset 5: %s\n", buf);  // 输出: 567

    // 当前文件偏移量仍在末尾
    off_t pos = lseek(fd, 0, SEEK_CUR);
    printf("Current offset: %ld\n", pos);  // 输出: 20

    // 在偏移量 10 处写入
    pwrite(fd, "XXX", 3, 10);

    close(fd);
    return 0;
}
```

## readv / writev - Scatter/Gather I/O

```c
#include <sys/uio.h>

ssize_t readv(int fd, const struct iovec *iov, int iovcnt);
ssize_t writev(int fd, const struct iovec *iov, int iovcnt);
```

`readv` 将数据读入多个不连续的缓冲区（scatter），`writev` 将多个缓冲区的数据写入文件（gather）。

### iovec 结构

```c
struct iovec {
    void  *iov_base;  // 缓冲区起始地址
    size_t iov_len;   // 缓冲区长度
};
```

### 示例

```c
#include <sys/uio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

int main() {
    int fd = open("/tmp/test_iov.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    // writev 示例：将多个缓冲区一次写入
    char part1[] = "Hello, ";
    char part2[] = "Scatter/Gather ";
    char part3[] = "I/O!\n";

    struct iovec iov[3];
    iov[0].iov_base = part1;
    iov[0].iov_len = strlen(part1);
    iov[1].iov_base = part2;
    iov[1].iov_len = strlen(part2);
    iov[2].iov_base = part3;
    iov[2].iov_len = strlen(part3);

    ssize_t nwritten = writev(fd, iov, 3);
    printf("Total written: %zd bytes\n", nwritten);

    // readv 示例：读入多个缓冲区
    lseek(fd, 0, SEEK_SET);

    char buf1[8], buf2[16], buf3[8];
    iov[0].iov_base = buf1;
    iov[0].iov_len = sizeof(buf1) - 1;
    iov[1].iov_base = buf2;
    iov[1].iov_len = sizeof(buf2) - 1;
    iov[2].iov_base = buf3;
    iov[2].iov_len = sizeof(buf3) - 1;

    ssize_t nread = readv(fd, iov, 3);
    printf("Total read: %zd bytes\n", nread);

    buf1[7] = buf2[15] = buf2[4] = '\0';
    printf("buf1: [%s]\n", buf1);
    printf("buf2: [%s]\n", buf2);
    printf("buf3: [%s]\n", buf3);

    close(fd);
    return 0;
}
```

## preadv / pwritev - 定位 Scatter/Gather I/O

```c
#include <sys/uio.h>

ssize_t preadv(int fd, const struct iovec *iov, int iovcnt, off_t offset);
ssize_t pwritev(int fd, const struct iovec *iov, int iovcnt, off_t offset);
```

`preadv` 和 `pwritev` 结合了定位读写和 scatter/gather I/O 的功能，在指定偏移量执行操作，且不改变文件当前偏移量。

### 示例

```c
#include <sys/uio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

int main() {
    int fd = open("/tmp/test_piov.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    // 准备数据
    char header[] = "===HEADER===";
    char body[] = "This is the body content";
    char footer[] = "===FOOTER===";

    struct iovec iov[3];
    iov[0].iov_base = header;
    iov[0].iov_len = strlen(header);
    iov[1].iov_base = body;
    iov[1].iov_len = strlen(body);
    iov[2].iov_base = footer;
    iov[2].iov_len = strlen(footer);

    // 从偏移量 0 开始写入
    ssize_t n = pwritev(fd, iov, 3, 0);
    printf("Written %zd bytes\n", n);

    // 读取中间部分
    char rdbuf[32];
    iov[0].iov_base = rdbuf;
    iov[0].iov_len = sizeof(rdbuf);

    n = preadv(fd, iov, 1, strlen(header));  // 从 header 之后开始读
    rdbuf[n < sizeof(rdbuf) ? n : sizeof(rdbuf) - 1] = '\0';
    printf("Read body: [%s]\n", rdbuf);

    close(fd);
    return 0;
}
```

## 系统调用对比总结

| 系统调用 | 功能 | 特点 |
|----------|------|------|
| open | 打开/创建文件 | 灵活的标志和权限控制 |
| creat | 创建文件 | 等价于 O_WRONLY\|O_CREAT\|O_TRUNC |
| close | 关闭文件 | 释放文件描述符 |
| read | 读取数据 | 从当前偏移量读取 |
| write | 写入数据 | 从当前偏移量写入 |
| pread | 定位读取 | 不改变文件偏移量 |
| pwrite | 定位写入 | 不改变文件偏移量 |
| readv | Scatter 读 | 读入多个缓冲区 |
| writev | Gather 写 | 写入多个缓冲区 |
| preadv | 定位 Scatter 读 | 结合 pread + readv |
| pwritev | 定位 Gather 写 | 结合 pwrite + writev |

## 错误处理

所有这些系统调用在失败时返回 -1，并设置 `errno`。常见的错误码：

| errno | 说明 |
|-------|------|
| EACCES | 权限不足 |
| EEXIST | 文件已存在（O_EXCL） |
| ENOENT | 文件不存在 |
| ENOSPC | 设备空间不足 |
| EINTR | 被信号中断 |
| EINVAL | 参数无效 |
| EBADF | 无效的文件描述符 |

```c
#include <errno.h>
#include <string.h>

// 错误处理示例
int fd = open("/some/file", O_RDONLY);
if (fd == -1) {
    // 方式1：使用 perror
    perror("open");

    // 方式2：使用 strerror
    fprintf(stderr, "Error: %s\n", strerror(errno));

    // 方式3：检查特定错误
    if (errno == ENOENT) {
        printf("File not found\n");
    }
}
```

## 参考资料

- man 2 open, man 2 read, man 2 write
- man 2 pread, man 2 pwrite
- man 2 readv, man 2 writev
- man 2 preadv, man 2 pwritev
- 《Advanced Programming in the UNIX Environment》(APUE)
