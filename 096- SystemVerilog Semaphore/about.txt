## Semaphore in SystemVerilog

A **semaphore** is a synchronization mechanism used in SystemVerilog to control access to a shared resource between concurrent processes.

Your example models a **single shared key**:

```systemverilog
semaphore key = new(1);
```

Here, `1` means the semaphore initially contains **one key/token**, so only **one process can access the protected resource at a time**.

### How your code works

You have two concurrent processes, **A** and **B**:

```text
             Semaphore
              key = 1
                 │
        ┌────────┴────────┐
        ↓                 ↓
   Process A          Process B
   key.get(1)         key.get(1)
        │                 │
    gets key          waits if key
        │              unavailable
      #10                 │
        │                 │
   key.put(1)             │
        │                 ↓
     releases          gets key
        key              │
                       #10
                         │
                     key.put(1)
```

### Important methods

| Method       | Purpose                              |
| ------------ | ------------------------------------ |
| `new(1)`     | Creates semaphore with 1 key         |
| `get(1)`     | Requests/acquires 1 key              |
| `put(1)`     | Returns/releases 1 key               |
| `try_get(1)` | Attempts to acquire without blocking |

The important behavior is:

```systemverilog
key.get(1);
```

If the key is available, the process gets it immediately.

If another process already owns the key, `get()` **blocks** until the key is returned.

---

### Expected behavior of your example

At time `0`, both A and B start.

One process gets the only key:

```text
[A] process A is trying to get the key 0
[A] process A got the key 0
```

B may then print:

```text
[B] process B is trying to get the key 0
```

but its:

```systemverilog
key.get(1);
```

blocks because A owns the key.

After:

```systemverilog
#10;
key.put(1);
```

A releases the key at time 10, allowing B to acquire it:

```text
[A] process A has drop the key 10
[B] process B got the key 10
```

B then releases it at time 20.

Because you have:

```systemverilog
repeat(2)
```

the whole `fork...join` sequence is repeated twice.

**One important point:** the simulator is free to schedule A or B first, so don't assume A always gets the key first. The synchronization guarantee is that **both cannot own the single key simultaneously**.

### Semaphore vs Mailbox

You just studied mailbox, so this distinction is important:

| Mailbox                          | Semaphore                           |
| -------------------------------- | ----------------------------------- |
| Transfers data between processes | Controls access to resources        |
| `put()` / `get()` data           | `get()` / `put()` keys              |
| Communication mechanism          | Synchronization mechanism           |
| Example: transaction passing     | Example: shared bus/resource access |

### VLSI/DV relevance

Semaphores are useful when multiple verification processes need controlled access to a **shared resource**, such as a shared bus model, memory model, or other exclusive verification resource.

**Interview takeaway:**

> A semaphore provides synchronization by controlling a finite number of keys. A process must acquire a key before accessing a protected shared resource and return it afterward. With `new(1)`, it effectively provides mutual exclusion similar to a lock.
