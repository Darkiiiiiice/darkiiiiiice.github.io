---
title: Rust 并发编程 (一)
date: 2024-01-22T16:26:06+08:00
draft: false
description: "Rust 并发编程笔记"
keywords: "rust,atomics"
lastmod: 2024-01-22T16:26:06+08:00
---

## Basic

> 阅读 Rust Atomics and Locks 笔记

### Rust中的线程

每个程序都从一个线程开始：主线程。这个线程将执行你的 main 函数，并且可以用来创建更多的线程。

在Rust中，使用标准库的 std::thread::spawn 函数来创建新线程。它接受一个参数：新线程将执行的函数。一旦该函数返回，线程就会停止。

``` rust
use std::thread;

fn main() {
    thread::spawn(f);
    thread::spawn(f);


    println!("Hello, this is from the main thread");
}

fn f() {
    println!("Hello from another thread.");

    let id = thread::current().id();
    println!("This is my thread id: {id:?}");
}
```

> Rust标准库为每个线程分配一个唯一的标识符。这个标识符可以通过 Thread::id() 访问，类型为 ThreadId 。除了复制和检查相等性之外，你不能对 ThreadId 做太多操作。不能保证这些ID会连续分配，只能确保每个线程的ID都不同。

如果我们想要确保线程在从 main 返回之前完成，我们可以通过加入它们来等待。为了这样做，我们必须使用 spawn 函数返回的 JoinHandle 。

``` rust
fn main() {
    let t1 = thread::spawn(f);
    let t2 = thread::spawn(f);

    println!("Hello from the main thread.");

    t1.join().unwrap();
    t2.join().unwrap();
}
```

该方法等待线程执行完毕并返回一个 std::thread::Result 。如果线程由于恐慌而未能成功完成其功能，则其中将包含恐慌消息。

> println 宏使用 std::io::Stdout::lock() 来确保其输出不会被中断。一个 println!() 表达式会等待任何同时运行的表达式完成后再输出任何内容。

``` rust
let numbers = vec![1, 2, 3];

thread::spawn(move || {
    for n in &numbers {
        println!("{n}");
    }
}).join().unwrap();
```

 numbers 的所有权被转移到新创建的线程，因为我们使用了一个 move 闭包。如果我们没有使用 move 关键字，闭包将会通过引用捕获 numbers 。这将导致编译器错误，因为新线程可能会超过该变量的生命周期

由于线程可能一直运行到程序执行的最后， spawn 函数对其参数类型有一个 'static 的生命周期限制。换句话说，它只接受可能永远保留的函数。通过引用捕获局部变量的闭包可能无法永远保留，因为一旦局部变量不存在，该引用将变为无效。

通过从闭包中返回值来获取线程的返回值。可以从 Result 方法返回的 join 中获取此返回值。

``` rust
let numbers = Vec::from_iter(0..=1000);

let t = thread::spawn(move || {
    let len = numbers.len();
    let sum = numbers.iter().sum::<usize>();
    sum / len  // 1
});

let average = t.join().unwrap(); // 2

println!("average: {average}");
```

这里，线程闭包返回的值（1）通过 join 方法（2）发送回主线程。

如果 numbers 为空，线程在尝试除以零时会出现恐慌(1)， join 将返回该恐慌消息，导致主线程也因 unwrap 而恐慌(2)。

> Thread Builder
> std::thread::spawn 函数实际上只是 std::thread::Builder::new().spawn().unwrap() 的一个方便的简写形式。
> 一个 std::thread::Builder 允许您在生成新线程之前设置一些设置。您可以使用它来配置新线程的堆栈大小，并为新线程命名。线程的名称可以通过 std::thread::current().name() 获得，在恐慌消息中使用，并且在大多数平台上的监控和调试工具中可见。
> 此外， Builder 的 spawn 函数返回一个 std::io::Result ，允许您处理创建新线程失败的情况。这可能发生在操作系统内存不足或资源限制已应用于您的程序的情况下。如果 std::thread::spawn 函数无法创建新线程，它将简单地引发错误。

### 作用域线程

如果我们确定一个生成的线程绝对不会超出特定的范围，那么该线程可以安全地借用那些不会永远存在的东西，比如局部变量，只要它们超出了那个范围。

Rust标准库提供了 std::thread::scope 函数来生成这样的作用域线程。它允许我们生成不能超出我们传递给该函数的闭包作用域的线程，从而可以安全地借用局部变量。

``` rust
let numbers = vec![1, 2, 3];

thread::scope(|s| {
    s.spawn(|| {
        println!("length: {}", numbers.len());
    });
    s.spawn(|| {
        for n in &numbers {
            println!("{n}");
        }
    });
});
```

### 共享所有权和引用计数(Shared Ownership and Reference Counting)

#### 静态(Statics)

一个 static 值，它由整个程序“拥有”，而不是一个单独的线程。在下面的示例中，两个线程都可以访问 X ，但都不拥有它：

``` rust
static X: [i32; 3] = [1, 2, 3];

thread::spawn(|| dbg!(&X));
thread::spawn(|| dbg!(&X));
```

static 项有一个常量初始值设定项，永远不会被丢弃，甚至在程序的主函数启动之前就已经存在。每个线程都可以借用它，因为它保证永远存在。

#### 泄露(Leaking)

共享所有权的另一种方法是泄露分配。使用 Box::leak，可以释放 Box 的所有权，承诺永远不会丢弃它。从那时起，Box 将永远存在，没有所有者，只要程序运行，任何线程都可以借用它。

``` rust
let x: &'static [i32; 3] = Box::leak(Box::new([1, 2, 3]));

thread::spawn(move || dbg!(x));
thread::spawn(move || dbg!(x));
```

> 引用是 Copy ，这意味着当你 move 它们时，原来的仍然存在，就像整数或布尔值一样。

#### 引用计数

Rust 标准库通过 std::rc::Rc 类型（“reference counted”的缩写）提供共享所有权的功能。它与 Box 非常相似，除了克隆它不会分配任何新的东西，而是递增存储在包含值旁边的计数器。原始的和克隆的 Rc 将引用同一个分配；他们共享所有权。

``` rust
let a = Rc::new([1, 2, 3]);
let b = a.clone();

assert_eq!(a.as_ptr(), b.as_ptr());
```

删除 Rc 将使计数器递减。只有最后一个 Rc ，它会看到计数器降为零，才会丢弃和释放所包含的数据。

我们可以使用 std::sync::Arc ，它代表“原子引用计数”。它与 Rc 相同，除了它保证对引用计数器的修改是不可分割的原子操作，使其可以安全地用于多线程

``` rust
use std::sync::Arc;

let a = Arc::new([1, 2, 3]); // 1
let b = a.clone(); // 2

thread::spawn(move || dbg!(a)); // 3
thread::spawn(move || dbg!(b)); // 3
```

### 借用和数据竞争

在 Rust 中，可以通过两种方式借用值：

* 不可变借用：用 & 借用的东西会给出一个不可变的引用。这样的引用是可以复制的。对它所引用的数据的访问是在这种引用的所有副本之间共享的。
* 可变借用：用 &mut 借用的东西会给出一个可变的引用。可变借用保证它是该数据的唯一有效借用。

### 内部可变性

#### Cell

std::cell::Cell<T> 简单地包装了 T ，但允许通过共享引用进行更改。为避免未定义的行为，它只允许您将值复制出来（如果 T 为 Copy ），或将其整体替换为另一个值。此外，它只能在单线程内使用。

``` rust
fn f(a: &Cell<i32>, b: &Cell<i32>) {
    let before = a.get();
    b.set(b.get() + 1);
    let after = a.get();
    if before != after {
        x(); // might happen
    }
}
```

Cell 上的限制并不总是很容易处理。由于它不能直接让我们借用它持有的值，我们需要移出一个值（在原处留下一些东西），修改它，然后再放回去，以改变它的内容：

``` rust
fn f(v: &Cell<Vec<i32>>) {
    let mut v2 = v.take(); // 用一个空的 Vec 替换 Cell 的内容
    v2.push(1);
    v.set(v2); // 把修改后的 Vec 放回去
}
```

#### RefCell

 std::cell::RefCell 允许您以较小的运行时成本借用其内容。 RefCell<T> 不仅包含 T ，而且还包含一个计数器，用于跟踪任何未完成的借用。如果你试图在它已经被可变地借用时借用它，它会发生恐慌，从而避免未定义的行为。就像 Cell 一样， RefCell 只能在单个线程中使用。

``` rust
use std::cell::RefCell;

fn f(v: &RefCell<Vec<i32>>) {
    v.borrow_mut().push(1); // 我们可以直接修改`Vec`
}
```

#### Mutex 和 RwLock

RwLock 或读写锁是 RefCell 的并发版本。 `RwLock<T>` 持有 T 并跟踪任何未完成的借用。然而，与 `RefCell` 不同的是，它不会对冲突的借用产生恐慌。相反，它会阻塞当前线程——使其进入睡眠状态——同时等待冲突借用消失。在其他线程处理完数据后，我们只需要耐心等待轮到我们处理数据。

借用 RwLock 的内容称为锁定。通过锁定它，我们暂时阻止了并发的冲突借用，允许我们在不引起数据竞争的情况下借用它。

`Mutex` 非常相似，但概念上稍微简单一些。它不像 `RwLock` 那样跟踪共享和独占借用的数量，它只允许独占借用。

#### Atomics

原子类型表示 Cell 的并发版本，

与 `Cell` 一样，它们通过让我们把值作为一个整体复制进去，而不是让我们直接借用内容来避免未定义行为

与 `Cell` 不同的是，它们不能是任意大小。因此，任何 `T` 都没有通用的 `Atomic<`T`>` 类型，只有 `AtomicU32` 和 `AtomicPtr<`T`>` 等特定的原子类型。哪些可用取决于平台，因为它们需要处理器的支持以避免数据竞争。

#### UnsafeCell

UnsafeCell 是内部可变性的原始构建块。

`UnsafeCell<T>` 包装 `T` ，但没有任何条件或限制来避免未定义的行为。相反，它的 `get()` 方法只是提供一个指向它包装的值的原始指针，它只能在 `unsafe` 块中有意义地使用。它让用户以不会导致任何未定义行为的方式使用它。

### 线程安全：`Send`和`Sync`

该语言使用两个特殊特征来跟踪可以跨线程安全使用的类型：

* Send：
如果一个类型可以被发送到另一个线程，它就是 `Send` 。换句话说，如果该类型的值的所有权可以转移到另一个线程。例如， `Arc<i32>` 是 `Send` ，而 `Rc<i32`> 不是。
* Sync：
如果一个类型可以与另一个线程共享，则它是 `Sync` 。换句话说，类型 `T` 是 `Sync` 当且仅当对该类型 `&T` 的共享引用是 `Send` 时。例如， `i32` 是 `Sync` ，而 `Cell<i32>` 不是。 （但是， `Cell<i32>` 是 Send 。）

`i32`、 `bool` 和 `str` 等所有原始类型都是 `Send` 和 `Sync`

两个特征都是自动特征，这意味着它们会根据它们的字段自动为您的类型实现。字段全为 `Send` 和 `Sync` 的 `struct` 本身也是 `Send` 和 `Sync`

选择不使用这两种方法的方法是给你的类型添加一个不实现该特征的字段。为此，特殊的 `std::marker::PhantomData<T>` 类型通常会派上用场。该类型被编译器视为 `T` ，但它在运行时实际上并不存在。它是零大小的类型，不占用空间。

``` rust
use std::marker::PhantomData;

struct X {
    handle: i32,
    _not_sync: PhantomData<Cell<()>>,
}
```

原始指针（ `*const T` 和 `*mut T` ）既不是 `Send` 也不是 `Sync`

### 锁：互斥锁和读写锁

在线程之间共享（可变）数据的最常用工具是互斥锁(mutex)，它是“mutual exclusion”的缩写。互斥锁的作用是通过暂时阻塞同时尝试访问它的其他线程，来确保线程可以独占访问某些数据。

从概念上讲，互斥锁只有两种状态：锁定和解锁。当线程锁定未锁定的互斥体时，互斥锁被标记为已锁定并且线程可以立即继续。当一个线程随后试图锁定一个已经锁定的互斥锁时，该操作将被阻塞。线程在等待互斥体解锁时进入休眠状态。解锁只能在锁定的互斥锁上进行，并且应该由锁定它的同一个线程完成。如果其他线程正在等待锁定互斥锁，解锁将导致其中一个线程被唤醒，因此它可以再次尝试锁定互斥锁并继续其过程。

#### Rust 的互斥锁

Rust 标准库通过 `std::sync::Mutex<T>` 提供了这个功能。它在 `T` 类型上是通用的，这是互斥体保护的数据类型。通过使 `T` 成为互斥锁的一部分，数据只能通过互斥锁访问，从而提供一个安全接口，可以保证所有线程都遵守协议。

为确保锁定的互斥锁只能由锁定它的线程解锁，它没有 unlock() 方法。相反，它的 lock() 方法返回一个称为 MutexGuard 的特殊类型。这个守卫代表我们已经锁定互斥锁的保证。它的行为类似于通过 DerefMut 特征的独占引用，使我们能够独占访问互斥锁保护的数据。解锁互斥锁是通过放弃守卫来完成的。当我们放弃守卫时，我们就放弃了访问数据的能力，守卫的 Drop 实现将解锁互斥锁。

``` rust
use std::sync::Mutex;

fn main() {
    let n = Mutex::new(0);
    thread::scope(|s| {
        for _ in 0..10 {
            s.spawn(|| {
                let mut guard = n.lock().unwrap();
                for _ in 0..100 {
                    *guard += 1;
                }
            });
        }
    });
    assert_eq!(n.into_inner().unwrap(), 1000);
}
```

为了清楚地看到互斥锁的效果，我们可以让每个线程在解锁互斥锁之前等待一秒钟

``` rust
use std::time::Duration;

fn main() {
    let n = Mutex::new(0);
    thread::scope(|s| {
        for _ in 0..10 {
            s.spawn(|| {
                let mut guard = n.lock().unwrap();
                for _ in 0..100 {
                    *guard += 1;
                }
                thread::sleep(Duration::from_secs(1)); // New!
            });
        }
    });
    assert_eq!(n.into_inner().unwrap(), 1000);
}
```

#### 锁中毒(Lock Poisoning)

当线程在持有锁时发生恐慌时，Rust 中的 Mutex 会被标记为中毒。发生这种情况时， Mutex 将不再被锁定，但调用它的 lock 方法将导致 Err 表明它已中毒。

在中毒的互斥锁上调用 lock() 仍然会锁定互斥锁。 lock() 返回的 Err 包含 MutexGuard ，允许我们在必要时纠正不一致的状态。

#### 读写锁

互斥锁只涉及独占访问。 MutexGuard 将为我们提供一个受保护数据的独占引用 ( &mut T )，即使我们只想查看一下数据，一个共享引用 ( &T ) 就足够了。

读写锁是互斥锁的稍微复杂的版本，它理解独占访问和共享访问之间的区别，并且可以提供其中任何一种。它具有三种状态：未锁定、由单个写入者锁定（用于独占访问）和由任意数量的读取器锁定（用于共享访问）。它常用于经常被多个线程读取，但只是偶尔更新一次的数据。

Rust 标准库通过 `std::sync::RwLock<T>` 类型提供这种锁。它的工作方式类似于标准的 Mutex ，除了它的接口主要分为两部分。它不是单一的 lock() 方法，而是一个 read() 和 write() 方法用于锁定为读取器或写入器。它带有两种守卫类型，一种用于读，一种用于写： RwLockReadGuard 和 RwLockWriteGuard 。前者仅实现 Deref ，使其表现得像对受保护数据的共享引用，而后者还实现 DerefMut ，表现得像独占引用。

它实际上是 RefCell 的多线程版本，动态跟踪引用数量以确保遵守借用规则。

`Mutex<T>` 和 `RwLock<T>` 都要求 T 为 Send ，因为它们可用于将 T 发送到另一个线程。 `RwLock<T>` 还要求 T 也实现 Sync ，因为它允许多个线程持有对受保护数据的共享引用 ( &T )。 （严格来说，您可以为不满足这些要求的 T 创建一个锁，但您不能在线程之间共享它，因为锁本身不会实现 Sync 。）

### 等待： 停放和条件变量

当数据被多个线程改变时，在很多情况下，它们需要等待某个事件，等待数据的某些条件变为真。例如，如果我们有一个保护 Vec 的互斥锁，我们可能希望等到它包含任何东西。

#### 线程停放(Thread Praking)

等待来自另一个线程的通知的一种方法称为线程停放(Thread parking)。线程可以自行停放(park)，使其进入睡眠状态，从而停止消耗任何 CPU 周期。然后另一个线程可以取消停放的线程，将其从睡眠中唤醒。

线程停放可通过 `std::thread::park()` 函数获得。对于 unparking，您可以在表示要 unpark 的线程的 Thread 对象上调用 unpark() 方法。这样的对象可以从 spawn 返回的join handle中获取，也可以通过 std::thread::current() 由线程自己获取。

``` rust
use std::collections::VecDeque;

fn main() {
    let queue = Mutex::new(VecDeque::new());

    thread::scope(|s| {
        // Consuming thread
        let t = s.spawn(|| loop {
            let item = queue.lock().unwrap().pop_front();
            if let Some(item) = item {
                dbg!(item);
            } else {
                thread::park();
            }
        });

        // Producing thread
        for i in 0.. {
            queue.lock().unwrap().push_back(i);
            t.thread().unpark();
            thread::sleep(Duration::from_secs(1));
        }
    });
}
```

线程停放的一个重要属性是在线程停放自身之前对 unpark() 的调用不会丢失。取消停放的请求仍然被记录下来，下次线程尝试停放自己时，它会清除该请求并直接继续，而不会真正进入睡眠状态。

为什么这对正确操作至关重要，让我们来看看两个线程执行的步骤的可能顺序：

1. 消费线程——我们称它为 C——锁定队列。

2. C 试图从队列中弹出一个项目，但它是空的，导致 None 。

3. C 解锁队列。

4. 生产线程，我们称之为 P，锁定队列。

5. P 将一个新项目推送到队列中。

6. P 再次解锁队列。

7. P 调用 unpark() 通知 C 有新项目。

8. C 调用 park() 进入睡眠状态，等待更多项目。

unpark 请求不会叠加。调用 unpark() 两次然后再调用 park() 两次仍然会导致线程进入休眠状态。第一个 park() 清除请求直接返回，但是第二个照常休眠。

如果在 park() 返回之后立即调用 unpark() ，但在队列被锁定和清空之前， unpark() 调用是不必要的，但仍会导致下一个 park() 调用立即返回。这导致（空）队列被额外锁定和解锁。虽然这不会影响程序的正确性，但会影响其效率和性能。

#### 条件变量

条件变量是一个更常用的选项，用于等待受互斥锁保护的数据发生某些事情。它们有两个基本操作：等待和通知。线程可以等待一个条件变量，之后当另一个线程通知同一个条件变量时它们可以被唤醒。多个线程可以等待同一个条件变量，通知可以发送给一个等待线程，也可以发送给所有线程。

Rust 标准库提供了一个条件变量 std::sync::Condvar 。它的 wait 方法接受一个 MutexGuard 来证明我们已经锁定了互斥锁。它首先解锁互斥锁并进入休眠状态。稍后，当被唤醒时，它会重新锁定互斥锁并返回一个新的 MutexGuard （这证明互斥锁再次被锁定）

它有两个通知函数： notify_one 只唤醒一个等待线程（如果有的话）， notify_all 唤醒所有线程。

``` rust
use std::sync::Condvar;

let queue = Mutex::new(VecDeque::new());
let not_empty = Condvar::new();

thread::scope(|s| {
    s.spawn(|| {
        loop {
            let mut q = queue.lock().unwrap();
            let item = loop {
                if let Some(item) = q.pop_front() {
                    break item;
                } else {
                    q = not_empty.wait(q).unwrap();
                }
            };
            drop(q);
            dbg!(item);
        }
    });

    for i in 0.. {
        queue.lock().unwrap().push_back(i);
        not_empty.notify_one();
        thread::sleep(Duration::from_secs(1));
    }
});
```

* 我们现在不仅有一个包含队列的 Mutex ，还有一个用于传达“非空”条件的 Condvar 。

* 我们不再需要知道唤醒哪个线程，所以我们不再存储 spawn 的返回值。相反，我们使用 notify_one 方法通过条件变量通知消费者。

* 解锁、等待、重锁都是 wait 方法完成的。我们不得不稍微重组控制流，以便能够将守卫传递给 wait 方法，同时在处理项目之前仍然将其丢弃。

### 总结

* 多个线程可以在同一个程序中并发运行，并且可以在任何时候生成。

* 当主线程结束时，整个程序就结束了。

* 数据竞争是未定义的行为，Rust 的类型系统完全阻止了（在安全代码中）

* Send 的数据可以发送给其他线程， Sync 的数据可以在线程之间共享。

* 常规线程可能会在程序运行时运行，因此只能借用 'static 数据，例如静态和泄漏分配

* 常规线程可能会在程序运行时运行，因此只能借用 'static 数据，例如静态和泄漏分配

* 作用域线程对于限制线程的生命周期以允许它借用非 'static 数据（例如局部变量）很有用。

* &T 是共享引用。 &mut T 是独占引用。常规类型不允许通过共享引用进行修改。

* 由于 UnsafeCell ，某些类型具有内部可变性，它允许通过共享引用进行改变。

* Cell 和 RefCell 是单线程内部可变性的标准类型。 Atomics、 Mutex 和 RwLock 是它们的多线程等价物。

* Cell 和原子只允许替换整个值，而 RefCell 、 Mutex 和 RwLock 允许您通过动态执行访问规则直接改变值。

* 线程停放是等待某些条件的便捷方式。

* 当条件是关于受 Mutex 保护的数据时，使用 Condvar 比线程停放更方便，也更有效。
