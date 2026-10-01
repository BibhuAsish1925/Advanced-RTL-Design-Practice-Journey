# LIFO (Stack) — Circuit Overview & Applications

This design implements a **4-bit × 4-entry LIFO stack**, where data follows **Last-In, First-Out (LIFO)** behavior.

* **Data width:** 4 bits
* **Depth:** 4 entries
* **Storage:** `4 × 4 = 16 bits = 2 bytes`
* **Operations:** write (`wr_en`) and read (`rd_en`)
* **Status:** `full` and `empty`
* **Reset:** synchronous active-high
* **Clock:** single synchronous clock
* **Pointer:** 3-bit `stack_ptr`
* **Behavior:** newest stored value is read first

Typical applications include **stack-based processors, expression evaluation, function/call stacks, temporary data storage, undo/rollback structures, and stack-based algorithms**.

---

# 1. Circuit Working & RTL Implementation

The core storage is:

```verilog id="2wqvca"
reg [3:0] stack_mem[0:3];
```

So there are four 4-bit stack locations:

```text id="q5s0z5"
stack_mem[0]
stack_mem[1]
stack_mem[2]
stack_mem[3]
```

The important difference from a FIFO is the direction of data access:

```text id="c0tds6"
FIFO:
First written → First read

LIFO:
Last written → First read
```

---

## Stack pointer

```verilog id="w5rcx8"
reg [2:0] stack_ptr;
```

The pointer uses a somewhat unusual representation.

After reset:

```verilog id="7es1y6"
stack_ptr = 3'd4;
```

So:

```text id="kzv7ol"
stack_ptr = 4 → EMPTY
```

As data is pushed, the pointer decreases:

```text id="5g2o3j"
4 → 3 → 2 → 1 → 0
```

Thus the pointer effectively indicates the next available stack location.

---

# 2. Write / PUSH Operation

The write condition is:

```verilog id="t8is6a"
if (full == 1'b0 && wr_en == 1'b1 && rd_en == 1'b0)
```

So writing occurs only when:

* FIFO/stack is not full
* `wr_en = 1`
* `rd_en = 0`

The pointer is decremented first:

```verilog id="gkz1n6"
stack_ptr = stack_ptr - 1'b1;
```

Then data is stored:

```verilog id="s6p1qb"
stack_mem[stack_ptr] = dataIn;
```

For example:

```text id="f8z0e4"
Initial:
stack_ptr = 4

PUSH 3:
stack_ptr = 3
stack_mem[3] = 3

PUSH 7:
stack_ptr = 2
stack_mem[2] = 7

PUSH A:
stack_ptr = 1
stack_mem[1] = A
```

The logical stack is therefore:

```text id="2e6c9w"
TOP → A
      7
      3
```

---

# 3. Read / POP Operation

The read condition is:

```verilog id="0g9r7w"
else if (empty == 1'b0 && rd_en == 1'b1)
```

The current top element is read:

```verilog id="5s1zru"
dataOut = stack_mem[stack_ptr];
```

Then that memory location is cleared:

```verilog id="8hxjzd"
stack_mem[stack_ptr] = 0;
```

Finally, the pointer increases:

```verilog id="o4bq3m"
stack_ptr = stack_ptr + 1;
```

Therefore the most recently pushed item is removed first.

For the previous example:

```text id="9r2prn"
Stack:
A
7
3

POP → A
POP → 7
POP → 3
```

That is the defining **LIFO** behavior.

---

# 4. Full and Empty Detection

### Full

```verilog id="trh8o7"
full = stack_ptr ? 0 : 1;
```

Since `stack_ptr == 0` evaluates as false:

```text id="5i5q9d"
stack_ptr = 0 → full = 1
stack_ptr ≠ 0 → full = 0
```

Therefore, all four locations have been occupied when the pointer reaches zero.

### Empty

```verilog id="3p7w2s"
empty = stack_ptr[2];
```

Because the pointer is 3 bits:

```text id="20i4qj"
stack_ptr = 4 = 100₂
```

so:

```text id="1e7xuq"
empty = 1
```

When the pointer decreases to 3, 2, 1, or 0, the MSB becomes zero and `empty` becomes zero.

---

# 5. Reset Operation

The reset is synchronous because:

```verilog id="0mtb7n"
always @(posedge clk)
```

does not contain `rst` in the sensitivity list.

During reset:

```verilog id="s1f5me"
stack_ptr = 3'd4;
empty = stack_ptr[2];
dataOut = 4'h0;
```

and every stack location is cleared:

```verilog id="4tw9py"
for (i=0; i<4; i=i+1)
    stack_mem[i] = 0;
```

Thus the stack starts empty.

---

# 6. Testbench Operation

The testbench uses a **20 ns clock period**:

```verilog id="7a7m9j"
always #10 clk = ~clk;
```

The stimulus performs:

### Reset phase

```text id="2rj8gf"
rst = 1
```

for approximately 40 ns.

### Write phase

`wr_en` is enabled and the input data changes:

```text id="1v8d1u"
0
3
7
A
```

The intended stack contents after the meaningful writes are:

```text id="4t7y9u"
TOP → A
      7
      3
```

### Read phase

Then:

```verilog id="k1hj5g"
rd_en = 1;
```

The expected output order is:

```text id="1a7e4r"
A → 7 → 3 → ...
```

which demonstrates LIFO behavior.

---

# 7. Important Testbench Observation

The testbench is **not self-checking**.

It only displays:

```verilog id="pxh7xz"
$display("Data in: %d  Data out: %d  Empty: %d  Full: %d",
         dataIn, dataOut, empty, full);
```

There is no expected-value comparison such as:

```text
expected == dataOut
```

Therefore, it demonstrates the waveform/console behavior but does not automatically detect a wrong output.

A stronger LIFO verification would maintain a reference stack and compare every POP against the expected top element.

---

# 8. Important RTL Issues

There are several coding-style and functional concerns worth knowing.

### 1. Blocking assignments in sequential logic

The design uses:

```verilog
stack_ptr = ...
dataOut = ...
stack_mem[...] = ...
```

inside a clocked `always` block.

For synthesizable sequential RTL, **nonblocking assignments (`<=`) are normally preferred**.

For example:

```verilog
stack_ptr <= stack_ptr - 1'b1;
```

This better models flip-flop behavior and avoids simulation-order dependencies.

---

### 2. `full` is not explicitly initialized during reset

Inside reset, the code sets:

```verilog
empty = stack_ptr[2];
```

but does not explicitly assign:

```verilog
full
```

So `full` can initially be unknown until the non-reset branch executes.

A robust reset should explicitly set:

```verilog
full <= 1'b0;
```

---

### 3. Simultaneous read/write is not supported

The write condition explicitly requires:

```verilog
rd_en == 1'b0
```

Therefore a cycle with:

```text
wr_en = 1
rd_en = 1
```

does not perform a write.

Because the read branch is an `else if`, a simultaneous operation is treated only as a read if the stack isn't empty.

---

### 4. Pointer representation is unconventional

Using:

```verilog
stack_ptr = 4
```

to represent the empty state works for this small 4-entry stack, but it makes the pointer both an address and a boundary/count indicator.

A more conventional implementation would use:

* a 2-bit memory address pointer, plus
* a count or occupancy flag.

That becomes particularly useful when scaling the stack depth.

---

# 9. Advantages & Limitations

### Advantages

* Simple LIFO architecture.
* Small memory footprint.
* Easy-to-understand push/pop behavior.
* Explicit full/empty status.
* Synchronous operation.
* Suitable for demonstrating stack fundamentals in RTL.

### Limitations

* Fixed 4-bit data width and 4-entry depth.
* No simultaneous push/pop.
* Blocking assignments are used in sequential logic.
* `full` is not explicitly reset.
* Pointer representation is unconventional.
* Testbench is observational rather than self-checking.
* Memory reset is unnecessary for a real stack if validity is tracked separately.
* Scaling this exact architecture requires careful pointer-width/boundary redesign.

---

# 10. Interview Takeaways

### One-line explanation

> **“This is a 4×4 synchronous LIFO stack where the stack pointer moves downward during PUSH and upward during POP, ensuring that the most recently stored value is read first.”**

### Key interview questions

**Q: What is the difference between FIFO and LIFO?**

```text
FIFO → First In, First Out
LIFO → Last In, First Out
```

**Q: Why does the pointer decrement during a write?**
The implementation initializes the pointer at `4`, representing an empty stack, and uses the next lower location as the new top.

**Q: What happens when `stack_ptr = 0`?**
The stack is full because all four memory locations have been occupied.

**Q: Why is `stack_ptr = 4` used for empty?**
It provides a sentinel position just above the valid memory addresses `0–3`.

**Q: Is the reset asynchronous?**
No. It is **synchronous active-high reset** because reset is checked only at `posedge clk`.

**Q: What is the main behavioral characteristic of this circuit?**

```text id="e3d8j8"
PUSH: data → stack
POP : stack top → dataOut
```

The last pushed item is always the first one popped.
