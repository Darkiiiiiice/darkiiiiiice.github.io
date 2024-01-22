---
title: "Systemd"
date: 2023-03-30T15:47:39+08:00
lastmod: 2023-03-30T15:47:39+08:00
author: "MarioMang"
keywords: "linux,systemdd"
categories:
    - linux
    - systemd
tags:
  - linux
  - systemdd

toc: true
---

# Systemd

*systemd* 是一个 Linux 系统下的系统和服务管理器，它用于启动、停止和管理系统内各个服务进程。相比之前使用的 SysVinit 和 Upstart 两种系统初始化方案，systemd 提供了更快、更简单、更强大的系统管理功能，成为了现代化 Linux 发行版的标配。

![hello](/images/systemd_cover.png)


## systemd 的主要特点

### 启动速度快

systemd 使用并行加载机制，可以同时启动多个服务，从而加速系统启动时间。

### 增强的任务控制

systemd 提供了一种称为“单位”的方式来管理系统中的服务、挂载点、设备等。这种方式可以帮助管理员更好地管理任务，并通过依赖关系自动启动和停止相关任务。

例如，我们可以使用以下命令查看 Nginx 服务的状态信息：

``` shell
systemctl status nginx
```

也可以使用以下命令启动或停止 Nginx 服务：

``` shell
systemctl start nginx
systemctl stop nginx
```

### 更严格的资源限制和管理

systemd 引入了 cgroups 和 namespaces 技术，能够为每个进程分配独立的资源，并限制其可用资源。这样做可以避免某个进程占用过多的 CPU、内存或磁盘 IO 等资源，导致系统运行缓慢或不稳定的情况。

### 更简单的配置文件格式

systemd 使用 .service 文件作为配置文件来定义服务和任务。相比之前的脚本或配置文件，.service 文件更容易修改和管理，同时也支持更多的操作和属性。

例如，以下是一个简单的 Nginx 服务的 .service 文件示例：

``` ini
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/start-stop-daemon --start --quiet --pidfile /run/nginx.pid --exec /usr/sbin/nginx -- -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/usr/sbin/start-stop-daemon --stop --quiet --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

可以看到，这个文件包含了三个部分：Unit、Service 和 Install，分别用来定义服务的描述信息、执行命令以及开机自启动方式等。

### 更好的日志记录和分析

systemd 引入了 journald 日志系统，它可以接收和存储各种来源的系统日志信息，并提供更好的查询和分析功能。在 systemd 中，我们可以使用以下命令查看系统中的日志信息：

``` shell
journalctl
```

## 组件

---

### systemd 守护进程(systemd daemon)

这是 systemd 的核心组件，它启动所有其他组件，并处理来自操作系统的事件。

systemd 守护进程（systemd daemon）是 systemd 的核心组件之一，它负责启动所有其他组件，并处理来自操作系统的事件。systemd 守护进程由 systemd 二进制文件（通常位于 /sbin/systemd 或 /usr/lib/systemd/systemd）运行并维护。

当系统启动时，Linux 内核会将控制权移交给 systemd 守护进程。systemd 守护进程会按照预定义的顺序启动各个服务单元，以实现系统的完整初始化。同时 systemd 守护进程还负责管理计时器、套接字激活、网络管理、用户管理等多个方面的系统任务。

在运行时，systemd 守护进程会不断监听各个系统事件，例如服务启动、崩溃、关闭、文件系统挂载、设备节点添加/删除等等，以及系统的定期任务等。它会根据这些事件相应地调度和执行服务单元，并且记录所有事件生成的详细日志。管理员可以使用 journalctl 命令来查询和分析这些日志。

### systemd 单元文件(systemd units)

systemd 使用单元文件来指定要管理的系统服务。单元文件包括配置文件（.conf 文件）、服务文件（.service 文件）、套接字文件（.socket 文件）等多种类型。

下面是一些常见的单元文件类型：

1. .service 文件：描述系统服务，包括启动、停止、重启、重载等操作，并定义了服务（如 Nginx、MySQL、SSH 服务）需要的资源和配置等信息。
2. .target 文件：描述系统状态，例如多用户模式（multi-user.target）、图形界面模式（graphical.target）等。.target 文件也可以包含其他单元文件，从而控制多个服务同时启动。
3. .socket 文件：描述套接字（socket），用于在系统间通信。
4. .mount 文件：描述要挂载的文件系统。您可以在这里定义如何挂载文件系统以及文件系统的挂载点等信息。
5. .automount 文件：类似于 .mount 文件，但自动挂载。
6. .path 文件：描述路径（path），当该路径上创建或变化文件时，相关的服务将自动启动或重新加载。
7. .timer 文件：描述与时间相关的任务（task），例如定期备份等。
8. .device 文件：描述设备（device），用于在系统间通信。

---

### systemctl 命令

systemctl 命令用于管理、控制和监视系统服务的状态，例如启动或停止服务，检查服务状态，重启或重新加载服务，展示服务状态等操作

以下是 systemctl 常用的子命令：

* systemctl start <unit>: 启动一个服务或任务。
* systemctl stop <unit>: 停止一个服务或任务。
* systemctl restart <unit>: 重启一个服务或任务。
* systemctl reload <unit>: 重新加载一个服务或任务的配置文件，不会停止服务
* systemctl enable <unit>: 设置一个服务或任务开机自启动。
* systemctl disable <unit>: 取消一个服务或任务开机自启动
* systemctl status <unit>: 查看一个服务或任务的状态信息
* systemctl mask <unit>: 禁用指定的服务单元，使其无法启动。
* systemctl unmask <unit>: 取消禁用指定服务单元。
* systemctl list-unit-files: 列出所有已安装的服务单元及其状态
* systemctl list-dependencies <unit>: 列出指定服务单元所依赖的其他服务单元。
* systemctl daemon-reload: 重新加载 systemd 的配置文件，以便系统可以使用新的单元文件和配置更改。

---

### 服务管理器(service manager)

这是 systemd 的核心组件之一，负责启动、停止和管理系统服务。服务管理器可以按照依赖顺序启动并控制多个服务

---

### 日志记录系统(journald)

systemd 使用 journald 记录和存储系统日志。 journald 允许管理员轻松搜索、分析和过滤日志条目，也支持外部的日志收集工具，比如 GELF 或者 syslog

journalctl，它可以让管理员查看和管理系统日志，并提供了一些强大的过滤和搜索功能。

以下是 journalctl 常用的命令和选项：

* journalctl: 列出所有的日志条目。

* journalctl -u <unit>: 列出指定服务或其他单元的日志。

* journalctl --boot: 列出当前引导的日志。

* journalctl -f: 实时显示最新的日志信息。

* journalctl -n <number>: 列出最近的若干条日志记录（默认为 10 条）。

* journalctl --since <date>: 列出指定日期之后的日志记录。

* journalctl --until <date>: 列出指定日期之前的日志记录。

* journalctl -p <priority>: 列出指定优先级的日志记录。

* journalctl -k: 列出内核日志。

* journalctl --vacuum-size=<size>: 清理过期的日志数据，以便释放磁盘空间。

---

### 计时器(timer)

systemd 可以使用计时器来执行预定任务，例如定期备份文件、清除临时文件或定期清理日志

systemd 的计时器管理器可以通过 systemctl 命令来使用，以下是一些常见的 systemctl 子命令：

* systemctl list-timers: 列出所有的计时器及其下一次执行的时间。

* systemctl start <timer>: 立即启动指定的计时器。

* systemctl stop <timer>: 停止指定的计时器。

* systemctl enable <timer>: 将指定的计时器添加到启动列表中，使其在系统启动时自动启动。

* systemctl disable <timer>: 从启动列表中删除指定的计时器，使其不再在系统启动时自动启动。

* systemctl status <timer>: 显示指定计时器的当前状态。

以下是 systemd 计时器常见的高级功能：

* 延迟启动（OnStartupSec、OnUnitActiveSec）：可以设置在服务或系统启动后，经过一定的时间后再开始执行计时器中的任务。例如："OnStartupSec=30min" 表示在系统启动后 30 分钟执行任务。

* 随机化启动时间（RandomizedDelaySec）：可以设置一个随机化的时间延迟，以避免多个计时器同时启动造成的负载突增。例如："RandomizedDelaySec=10min" 表示在计时器的基础时间上随机增加 0 至 10 分钟的延迟。

* 范围化启动时间（AccuracySec）：可以将计时器的触发时间限制在一定的范围内，以保持较好的精度。例如："AccuracySec=1min" 表示计时器的触发时间不会偏差超出 1 分钟。

* 调节启动间隔（OnCalendar）：可以根据日历来调节任务的启动时间。例如："OnCalendar=--* 8,12:00" 表示在每天的上午 8 点和下午 12 点执行任务。

* 关联执行（Unit）：可以将计时器关联到一个服务单元上，当服务单元启动时，计时器也会自动启动。例如："Unit=httpd.service" 表示当 httpd 服务启动时，计时器也会启动。

---

### systemd-networkd

systemd-networkd 是 systemd 系统中的网络管理器，它可以管理和配置系统的网络接口、连接、路由和网桥等。

与传统的网络管理器相比，systemd-networkd 具有以下优点：

* 集成性好：systemd-networkd 与 systemd 系统紧密集成，可以更好地利用 systemd 的功能实现网络管理。

* 简化配置：systemd-networkd 的配置文件简洁明了，易于理解和编辑。管理员可以通过简单的配置文件来管理网络接口、连接、路由和网桥等。

* 启动速度快：systemd-networkd 采用并行启动方式，可以在系统启动时快速加载并管理网络接口和连接，从而提高系统启动速度和效率。

* 支持 IPv6：systemd-networkd 提供了对 IPv6 的完整支持，可以更好地管理和配置 IPv6 网络环境。

* 安全性高：systemd-networkd 对网络安全有很好的支持，可以提供非常灵活的网络访问控制和过滤功能，保护系统免受网络攻击。

---

### systemd-resolved

systemd-resolved 是 systemd 系统中的域名解析服务，它可以将域名解析请求转发到适当的 DNS 服务器，并缓存解析结果以提高性能和效率。

与传统的域名解析工具相比，systemd-resolved 具有以下优点：

* 集成性好：systemd-resolved 与 systemd 系统紧密集成，可以更好地利用 systemd 的功能实现域名解析。

* 缓存机制好：systemd-resolved 可以缓存解析结果，以提高解析性能和效率。缓存时间可以根据实际情况进行配置，从而更好地控制缓存大小和过期时间。

* 支持多种协议：systemd-resolved 支持多种协议，如 DNS-over-TLS、DNS-over-HTTPS、LLMNR 和 mDNS 等，可以更好地满足不同场景下的域名解析需求。

* 容错性好：systemd-resolved 可以自动检测并切换到备用 DNS 服务器，以提高容错性和可靠性。同时，它还支持本地解析，可以在网络不可用时解析本地主机名

---

### 交互式登录管理器(logind)

systemd 提供了一个名为 logind 的组件，它可以接管系统上的用户会话，并管理用户态电源管理、会话控制等相关的系统任务

与传统的登录管理器相比，logind 具有以下优点：

* 集成性好：logind 与 systemd 系统紧密集成，可以更好地利用 systemd 的功能实现登录管理。

* 安全性高：logind 对系统安全有很好的支持，可以提供非常灵活的访问控制和过滤功能，保护系统免受恶意用户的攻击。

* 功能强大：logind 可以管理多个用户会话、多个虚拟控制台和多个输入设备等，可以更好地满足不同场景下的登录需求。

* 可扩展性好：logind 支持插件机制，可以方便地扩展其功能，从而更好地适应各种场景的需求

---

### 安全访问组件

systemd 包含了 systemd-sysusers 和 systemd-tmpfiles 等组件，它们可以用于创建用户、组、设备节点、文件、目录等系统资源，并设置对应的权限信息，以及设置 SELinux 安全标签等任务

---

### 挂载单元(mount units)

systemd 还支持挂载文件系统，并根据需要在需要时自动挂载特定挂载点下的文件系统

通过挂载单元，可以在系统启动时自动挂载指定的文件系统，或者在运行时手动挂载文件系统。

通常情况下，挂载单元的配置文件位于 /etc/systemd/system/ 目录下，文件名以 .mount 后缀结尾。

下面是一个简单的挂载单元示例：

``` ini
[Unit]
Description=Mount Data Partition
After=local-fs.target

[Mount]
What=/dev/sda2
Where=/mnt/data
Type=ext4

[Install]
WantedBy=multi-user.target
```

上述配置文件指定了将 /dev/sda2 文件系统挂载到 /mnt/data 目录中，挂载类型为 ext4。同时，该挂载单元在系统启动时自动挂载，并加入到 multi-user.target 目标单元中。

## 配置文件

一个 Systemd 单元文件通常由三个段落组成：[Unit]、[Service] 和 [Install]。下面是一个完整的 Systemd 单元文件，并对每个段落进行了详细介绍：

``` ini
[Unit]
Description=My Sample Service
After=network.target

[Service]
ExecStart=/usr/local/bin/sample-service
Restart=always
User=myuser
Group=mygroup

[Install]
WantedBy=multi-user.target
```

* [Unit] 段落定义了单元的元数据信息，例如描述、依赖情况等。
* [Service] 段落定义了服务的具体行为。
* [Install] 段落定义如何安装单元服务。

### [Unit]段落

[Unit] 部分是单元的元数据，包含单元的描述和依赖关系等信息。

下面是 Systemd 单元文件的 [Unit] 段落完整配置

``` ini
[Unit]
Description=My Service
Documentation=https://example.com/docs
Requires=network-online.target
After=network-online.target syslog.target
Before=some-other-service.target
Wants=some-optional-service.target
BindsTo=another-service.target
Conflicts=conflicting-service.service
IgnoreOnIsolate=true
JobTimeoutSec=60s
ConditionPathExists=/path/to/required/file
ConditionPathIsDirectory=/path/to/required/directory
ConditionPathIsSymbolicLink=/path/to/required/link
```

* Description=：单元的简短描述。
* Documentation=：单元相关文档或链接。
* After=：指定该单元所依赖的其他单元，network.target 意味着这个服务会在网络服务启动之后启动。
* Requires=：类似于 After=，但如果相应的单元失败，它会导致此单元不可用，而不仅仅是延迟其启动。
* Wants=：同样依赖于另一个单元，但是如果该单元出现故障，它不会阻止它自己被激活。
* Conflicts=：如果同时激活另一个单元，该单元将禁用该单元。
* BindsTo=：同样禁用另一个单元，但如果它没有依赖关系，则它还将被终止。
* Before=：类似于 After=，但是它表示启动该服务之前必须启动的单元。
* Requisite=：类似于 Requires=，但如果相应的单元不存在，则无法启动此单元。
* Also=：指定单元所处组的其他单元。
* IgnoreOnIsolate=：指定是否在系统隔离时忽略此单元。
* JobTimeoutSec: 在任务被认为 failed 之前等待的时间
* ConditionPathExists: 服务在此路径上必须存在一个文件或目录，否则不会启动。
* ConditionPathIsDirectory: 指定服务应该是一个目录，否则不会启动。
* ConditionPathIsSymbolicLink: 指定服务应该是一个符号链接，否则不会启动。

### [Service]

systemd 单元文件中的 Service 段落是用于定义服务或任务的执行方式和属性。
以下是一个完整的 Service 段落示例：

``` ini
[Service]
Type=simple/forking/oneshot/notify/dbus
User=username
Group=groupname
WorkingDirectory=/path/to/working/directory
ExecStart=/path/to/executable [args]
ExecStartPre=/path/to/executable [args]
ExecStartPost=/path/to/executable [args]
ExecReload=/path/to/executable [args]
ExecStop=/path/to/executable [args]
TimeoutStartSec=5min
TimeoutStopSec=5s
Restart=always/on-success/on-failure/on-abnormal/on-watchdog/no
RestartSec=time
StartLimitInterval=0
StartLimitBurst=5
StartLimitAction=none/reboot/halt/poweroff/panic
PermissionsStartOnly=true/false
PrivateTmp=true/false
ProtectSystem=true/false
ProtectHome=true/false
NoNewPrivileges=true/false
ReadOnlyDirectories=/path/to/dir1 /path/to/dir2
ReadWriteDirectories=/path/to/dir1 /path/to/dir2
```

* WorkingDirectory: 服务所在的工作目录；
* Type 参数指定服务或任务的类型。
  * simple  默认值，表示主进程将一直运行，直到服务被停止或出现异常，systemd 会监视该进程并在需要时重启它；
  * forking 表示主进程将以 fork 的形式运行。用于某些服务需要后台进程的情况，比如 Web 服务器或数据库服务。在这种情况下，要求主进程在启动子进程后立即退出；
  * oneshot 表示主进程将只运行一次，并在完成后退出。它通常用于一些短暂的脚本，例如数据备份或网络配置等；
  * notify 表示主进程会向 systemd 发送一个特定的信号，以表明服务已准备好接收请求。这种方式通常用于服务需要长时间启动的情况，例如 Web 服务器和数据库服务
  * dbus 表示主进程将通过 D-Bus 进行管理。
* ExecStartPre: 在主命令 ExecStart 之前执行的命令；
* ExecStart 参数指定服务或任务启动时执行的命令
* ExecStartPost: 在主命令 ExecStart 之后执行的命令；
* ExecReload: 重新加载服务配置文件的命令；
* ExecStop: 停止服务的命令；
* User 参数指定服务或任务运行时的用户
* Group 参数指定服务或任务运行时的用户组
* Restart 参数指定服务或任务应该如何重启
  * no: 禁止自动重启服务，即使服务异常退出也不会自动重启；
  * on-success: 当服务以成功的状态退出时（即退出状态码为 0），systemd 才会自动重启服务；
  * on-failure: 当服务以非正常状态退出（即退出状态码非 0）时，systemd 才会自动重启服务；
  * on-abnormal: 当服务因信号而退出时（如 SIGSEGV），systemd 才会自动重启服务；
  * on-watchdog: 当 watchdog 定时器超时时，systemd 才会自动重启服务；
  * always: 无论服务以何种方式退出，systemd 都会自动重启服务。
* RestartSec 参数指定服务或任务重启间隔
* TimeoutStopSec 当该服务被强制停止时，systemd 等待完成停止的时间
* PermissionsStartOnly: 设置为 true，则仅在服务启动时设置权限，而不是每次运行时都设置；
* PrivateTmp: 如果设置为 true，则在私有临时文件系统中运行服务。
* StartLimitInterval: 等待 StartLimitBurst 个单位时间间隔后再尝试重新启动服务，0 表示禁用限制；
* StartLimitBurst: 在 StartLimitInterval 时间内尝试重新启动服务的最大次数；
* StartLimitAction: 如果达到StartLimitBurst次启动失败，应采取的操作；
* ProtectSystem: 如果设置为 true，则进程将无法修改文件系统根目录的内容；
* ProtectHome: 如果设置为 true，则进程将无法修改除自己主目录外的其他用户主目录的内容；
* NoNewPrivileges: 如果设置为 true，则进程将不允许获取新权限；
* ReadOnlyDirectories: 需要保护并设置为只读的目录，可以设置多个目录，用空格分隔；
* ReadWriteDirectories: 需要保护并设置为可读写的目录，可以设置多个目录，用空格分隔。

### [Install]

``` shell
[Install]
WantedBy=multi-user.target
Alias=my-alias.service
Also=some-other-unit.service
RequiredBy=some-requiring.unit.service
DefaultInstance=default@.service
RequiredByAll=my-required-target.target
AlsoBy=my-also-enabled-unit.service
```

* WantedBy: 指定服务应该自动启动的目标。当用户启用自启动服务时，systemd 将检查默认的 WantedBy 值，查找支持自启动的 target。
* Alias: 此服务的别名，它可以与其他服务重名，但必须是唯一的，不能包含任何文件扩展名。可以将别名视为对服务的符号链接。
* Also: 当安装此服务时，还安装其他指定的服务。
* RequiredBy: 如果您的服务仅在特定条件下才需要启动，则在此指定。例如，在特定设备上才需要启动某些服务。如果特定设备不存在，则此服务不会启动。
* DefaultInstance: 为类型化服务指定默认实例，并在安装时创建符号链接。这是一个模板单元，它允许您在安装单元时通过模板规则启动该单元。
* RequiredByAll: 如果此服务应该作为其他服务的必须依赖项，则在此处指定。当所有使用者都停止时，此服务将自动停止。
* AlsoBy: 此服务的替代服务列表，与 Also 相似。

## 结尾

如果你正在寻找一个能让你更深入学习 systemd 的指南，那么这篇文章就是你需要的。

总之，systemd 系统具有许多特征和功能，使其成为 Linux 发行版中最常见、必要和受欢迎的初始化系统和服务管理器。能够理解和掌握 systemd 的配置、管理和故障排除技能是系统管理员必备的技能之一。希望这篇博客可以对您有所帮助！
