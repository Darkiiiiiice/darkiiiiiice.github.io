---
title: "Rust 并发编程 (二)"
date: 2024-01-29T21:54:58+08:00
draft: false
description: "Rust 并发编程笔记"
keywords: "rust,atomics"
lastmod: 2024-01-29T21:54:58+08:00
---
## 原子

在 Rust 中，原子操作可以作为标准原子类型的方法使用，这些原子类型存在于 std::sync::atomic 中。它们的名称都以 Atomic 开头，例如 AtomicI32 或 AtomicUsize

每个原子操作都有一个 std::sync::atomic::Ordering 类型的参数，它决定了我们对操作的相对顺序有什么保证。保证最少的最简单的变体是 Relaxed 。 Relaxed 仍然保证单个原子变量的一致性，但不保证不同变量之间的相对操作顺序。

### 原子加载和存储操作

我们要看的前两个原子操作是最基本的： load 和 store 。它们的函数签名如下，以 AtomicI32 为例：

``` rust
impl AtomicI32 {
    pub fn load(&self, ordering: Ordering) -> i32;
    pub fn store(&self, value: i32, ordering: Ordering);
}
```

load 方法以原子方式加载存储在原子变量中的值， store 方法以原子方式将新值存储在其中。请注意 store 方法是如何采用共享引用 ( &T ) 而不是独占引用 ( &mut T )，即使它修改了值。

#### 示例：停止标志

``` rust
use std::sync::atomic::AtomicBool;
use std::sync::atomic::Ordering::Relaxed;

fn main() {
    static STOP: AtomicBool = AtomicBool::new(false);

    // Spawn a thread to do the work.
    let background_thread = thread::spawn(|| {
        while !STOP.load(Relaxed) {
            some_work();
        }
    });

    // Use the main thread to listen for user input.
    for line in std::io::stdin().lines() {
        match line.unwrap().as_str() {
            "help" => println!("commands: help, stop"),
            "stop" => break,
            cmd => println!("unknown command: {cmd:?}"),
        }
    }

    // Inform the background thread it needs to stop.
    STOP.store(true, Relaxed);

    // Wait until the background thread finishes.
    background_thread.join().unwrap();
}
```

#### 示例：进度报告

``` rust
use std::sync::atomic::AtomicUsize;

fn main() {
    let num_done = AtomicUsize::new(0);

    thread::scope(|s| {
        // A background thread to process all 100 items.
        s.spawn(|| {
            for i in 0..100 {
                process_item(i); // Assuming this takes some time.
                num_done.store(i + 1, Relaxed);
            }
        });

        // The main thread shows status updates, every second.
        loop {
            let n = num_done.load(Relaxed);
            if n == 100 { break; }
            println!("Working.. {n}/100 done");
            thread::sleep(Duration::from_secs(1));
        }
    });

    println!("Done!");
}
```

##### 同步化(Synchronization)

``` rust
fn main() {
    let num_done = AtomicUsize::new(0);

    let main_thread = thread::current();

    thread::scope(|s| {
        // A background thread to process all 100 items.
        s.spawn(|| {
            for i in 0..100 {
                process_item(i); // Assuming this takes some time.
                num_done.store(i + 1, Relaxed);
                main_thread.unpark(); // Wake up the main thread.
            }
        });

        // The main thread shows status updates.
        loop {
            let n = num_done.load(Relaxed);
            if n == 100 { break; }
            println!("Working.. {n}/100 done");
            thread::park_timeout(Duration::from_secs(1));
        }
    });

    println!("Done!");
}
```

我们已经通过 thread::current() 获得了主线程的句柄，后台线程在每次状态更新后都会使用这个句柄来取消主线程的停放。主线程现在使用 park_timeout 而不是 sleep ，这样它就可以被中断。

#### 示例：惰性初始化(Lazy Initialization)

为了简单起见，我们假设 x 永远不会为零，这样我们就可以在计算之前使用零作为占位符。

```rust
use std::sync::atomic::AtomicU64;

fn get_x() -> u64 {
    static X: AtomicU64 = AtomicU64::new(0);
    let mut x = X.load(Relaxed);
    if x == 0 {
        x = calculate_x();
        X.store(x, Relaxed);
    }
    x
}
```

### 获取和修改操作

现在我们已经看到了基本的 load 和 store 操作的一些用例，让我们继续进行更有趣的操作：获取和修改(fetch-and-modify)操作。这些操作修改原子变量，但也加载（获取）原始值，作为单个原子操作

``` rust
impl AtomicI32 {
    pub fn fetch_add(&self, v: i32, ordering: Ordering) -> i32;
    pub fn fetch_sub(&self, v: i32, ordering: Ordering) -> i32;
    pub fn fetch_or(&self, v: i32, ordering: Ordering) -> i32;
    pub fn fetch_and(&self, v: i32, ordering: Ordering) -> i32;
    pub fn fetch_nand(&self, v: i32, ordering: Ordering) -> i32;
    pub fn fetch_xor(&self, v: i32, ordering: Ordering) -> i32;
    pub fn fetch_max(&self, v: i32, ordering: Ordering) -> i32;
    pub fn fetch_min(&self, v: i32, ordering: Ordering) -> i32;
    pub fn swap(&self, v: i32, ordering: Ordering) -> i32; // "fetch_store"
}
```

下面是一个快速演示，展示了 fetch_add 如何在操作之前返回值：

``` rust
use std::sync::atomic::AtomicI32;

let a = AtomicI32::new(100);
let b = a.fetch_add(23, Relaxed);
let c = a.load(Relaxed);

assert_eq!(b, 100);
assert_eq!(c, 123);
```

这些操作的返回值并不总是相关的。如果您只需要将操作应用于原子值，但对值本身不感兴趣，则完全可以忽略返回值。


#### 示例：来自多个线程的进度报告

我们可以为每个线程使用单独的 AtomicUsize ，并将它们全部加载到主线程中，然后将它们相加，但更简单的解决方案是使用单个 AtomicUsize 来跟踪所有线程中已处理项目的总数。

``` rust
fn main() {
    let num_done = &AtomicUsize::new(0);

    thread::scope(|s| {
        // Four background threads to process all 100 items, 25 each.
        for t in 0..4 {
            s.spawn(move || {
                for i in 0..25 {
                    process_item(t * 25 + i); // Assuming this takes some time.
                    num_done.fetch_add(1, Relaxed);
                }
            });
        }

        // The main thread shows status updates, every second.
        loop {
            let n = num_done.load(Relaxed);
            if n == 100 { break; }
            println!("Working.. {n}/100 done");
            thread::sleep(Duration::from_secs(1));
        }
    });

    println!("Done!");
}
```

#### 示例：统计

继续这个通过原子报告其他线程正在做什么的概念，让我们扩展我们的示例，以收集和报告一些关于处理一个项目所花费的时间的统计数据。

``` rust
fn main() {
    let num_done = &AtomicUsize::new(0);
    let total_time = &AtomicU64::new(0);
    let max_time = &AtomicU64::new(0);

    thread::scope(|s| {
        // 四个后台线程处理 100 个项目，每个 25 个。
        for t in 0..4 {
            s.spawn(move || {
                for i in 0..25 {
                    let start = Instant::now();
                    process_item(t * 25 + i); // 假设这需要一些时间。
                    let time_taken = start.elapsed().as_micros() as u64;
                    num_done.fetch_add(1, Relaxed);
                    total_time.fetch_add(time_taken, Relaxed);
                    max_time.fetch_max(time_taken, Relaxed);
                }
            });
        }

        // 主线程每秒显示一次状态更新。
        loop {
            let total_time = Duration::from_micros(total_time.load(Relaxed));
            let max_time = Duration::from_micros(max_time.load(Relaxed));
            let n = num_done.load(Relaxed);
            if n == 100 { break; }
            if n == 0 {
                println!("Working.. nothing done yet.");
            } else {
                println!(
                    "Working.. {n}/100 done, {:?} average, {:?} peak",
                    total_time / n as u32,
                    max_time,
                );
            }
            thread::sleep(Duration::from_secs(1));
        }
    });

    println!("Done!");
}
```

### 比较和交换操作

最先进和灵活的原子操作是比较和交换操作。此操作检查原子值是否等于给定值，只有在这种情况下，它才会用新值替换它，所有操作都以原子方式进行。它会返回之前的值并告诉我们它是否替换了它。

它的签名比我们目前看到的要复杂一些。以 AtomicI32 为例，它看起来是这样的：

``` rust
impl AtomicI32 {
    pub fn compare_exchange(
        &self,
        expected: i32,
        new: i32,
        success_order: Ordering,
        failure_order: Ordering
    ) -> Result<i32, i32>;
}
```

暂时忽略内存顺序，它与以下实现基本相同，除了它都是作为单个不可分割的原子操作发生的：

``` rust
impl AtomicI32 {
    pub fn compare_exchange(&self, expected: i32, new: i32) -> Result<i32, i32> {
        // 实际上，加载、比较和存储，
        // 所有这些都是作为单个原子操作发生的。
        let v = self.load();
        if v == expected {
            // 值符合预期。
            // 替换它并报告成功。
            self.store(new);
            Ok(v)
        } else {
            // 该值不符合预期。
            // 保持不变并报告失败。
            Err(v)
        }
    }
}
```

使用它，我们可以从原子变量加载一个值，执行我们喜欢的任何计算，然后如果原子变量在此期间没有改变，则只存储新计算的值。如果我们把它放在一个循环中以在它确实发生变化时重试，我们可以使用它来实现所有其他原子操作，使它成为最通用的操作。

``` rust
fn increment(a: &AtomicU32) {
    let mut current = a.load(Relaxed); // 1
    loop {
        let new = current + 1; // 2
        match a.compare_exchange(current, new, Relaxed, Relaxed) { // 3
            Ok(_) => return, // 4
            Err(v) => current = v, // 5
        }
    }
}
```


### 总结

* 原子操作是不可分割的；他们要么已经完全完成，要么尚未发生。

* Rust 中的原子操作是通过 std::sync::atomic 中的原子类型完成的，例如 AtomicI32 。

* 并非所有原子类型都适用于所有平台。

* 当涉及多个变量时，原子操作的相对顺序很棘手。第 3 章中有更多内容。

* 简单的加载和存储非常适合非常基本的线程间通信，例如停止标志和状态报告。

* 惰性初始化可以作为一种竞争来完成，而不会导致数据竞争。

* 获取和修改操作允许进行一小组基本的原子修改，这在多个线程修改同一个原子变量时特别有用。

* 原子加法和减法在溢出时默默地环绕。

* 比较和交换操作是最灵活和通用的，并且是进行任何其他原子操作的构建块。

* 弱的比较和交换操作可能会稍微更有效率。
