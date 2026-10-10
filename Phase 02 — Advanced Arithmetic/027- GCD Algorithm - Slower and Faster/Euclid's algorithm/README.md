# PARAMETERIZED ITERATIVE GCD UNIT

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This design implements the **Greatest Common Divisor (GCD)** of two unsigned numbers using the **iterative subtraction form of Euclid's algorithm**.

The basic algorithm is:

```text
while x != 0 and y != 0:
    if x > y:
        x = x - y
    else:
        y = y - x

GCD = remaining non-zero value
```

For example:

```text
GCD(48,18)

48 - 18 = 30
30 - 18 = 12
18 - 12 = 6
12 - 6  = 6
6  - 6   = 0

GCD = 6
```

Unlike the earlier combinational arithmetic examples, this implementation is a **clocked iterative architecture**. It performs one subtraction step per clock cycle.

### Applications

* Digital arithmetic units
* Cryptographic hardware
* Number-theoretic processors
* Modular arithmetic systems
* Hardware accelerators requiring GCD calculations

---

# 2. CIRCUIT WORKING & RTL IMPLEMENTATION

The architecture is controlled by a simple FSM:

```text
             ┌──────────┐
   start ───>│  S_IDLE  │
             └────┬─────┘
                  │
                  ▼
             ┌──────────┐
             │  S_RUN   │
             │          │
             │ x > y ?  │
             └──┬───┬───┘
                │   │
             x>y│   │y>=x
                ▼   ▼
             x=x-y y=y-x
                │   │
                └─┬─┘
                  │
             x==0 or y==0
                  │
                  ▼
             ┌──────────┐
             │ S_DONE   │
             └────┬─────┘
                  │
                  ▼
               S_IDLE
```

The internal registers are:

```verilog
reg [WIDTH-1:0] x, y;
```

These hold the current values being reduced.

---

### S_IDLE — Load operands

When `start` is asserted:

```verilog
x    <= A;
y    <= B;
busy <= 1'b1;
st   <= S_RUN;
```

So the input operands are captured into internal registers and the unit begins processing.

---

### S_RUN — Euclidean subtraction

First, the design checks termination:

```verilog
if (x == 0) begin
    gcd <= y;
    st  <= S_DONE;
end
else if (y == 0) begin
    gcd <= x;
    st  <= S_DONE;
end
```

If neither is zero, it performs one subtraction:

```verilog
if (x > y)
    x <= x - y;
else
    y <= y - x;
```

Because these are nonblocking assignments, the subtraction occurs at the clock edge and the updated value is available for the next iteration.

For:

```text
A = 48
B = 18
```

the internal sequence is:

```text
x=48, y=18
x=30, y=18
x=12, y=18
x=12, y=6
x=6,  y=6
x=0,  y=6
```

Then:

```text
gcd = 6
```

---

### S_DONE — Report result

The DONE state performs:

```verilog
busy <= 1'b0;
done <= 1'b1;
st   <= S_IDLE;
```

Thus:

* `busy = 1` while calculation is running.
* `done = 1` for one clock cycle when the result is ready.
* `gcd` contains the calculated result.

The line:

```verilog
done <= 1'b0;
```

at the beginning of every active clock cycle ensures that `done` behaves as a **one-cycle pulse**.

---

## Reset

The module uses an active-low asynchronous reset:

```verilog
always @(posedge clk or negedge rst_n)
```

When `rst_n = 0`, the FSM and registers are cleared.

---

# 3. VERIFICATION & TESTBENCH

The testbench uses:

```verilog
parameter WIDTH = 32;
```

and passes the parameter to the DUT:

```verilog
gcd_basic #(.WIDTH(WIDTH)) dut (...)
```

Therefore, the same RTL can be reused for different operand widths.

### Clock

```verilog
always #5 clk = ~clk;
```

creates a:

```text
Period = 10 ns
Frequency = 100 MHz
```

clock.

---

### `run_test` task

The testbench uses a reusable task:

```verilog
task run_test(
    input [WIDTH-1:0] a_val,
    input [WIDTH-1:0] b_val,
    input [WIDTH-1:0] expected
);
```

The task:

1. Waits for a safe clock edge.
2. Loads `A` and `B`.
3. Pulses `start`.
4. Waits for `done`.
5. Compares the DUT result with the expected value.
6. Prints `PASS` or `FAIL`.

The important check is:

```verilog
if (gcd === expected)
```

So this testbench is **self-checking**, unlike several of the earlier examples.

---

### Test cases

|    A |   B | Expected GCD |
| ---: | --: | -----------: |
|   48 |  18 |            6 |
|    0 |   5 |            5 |
|    7 |   0 |            7 |
|    1 |   1 |            1 |
|   17 |  13 |            1 |
| 1000 | 500 |          500 |
|    0 |   0 |            0 |

The zero cases are particularly important because the RTL explicitly handles:

$$
GCD(0,B)=B
$$

$$
GCD(A,0)=A
$$

and the implementation also defines:

$$
GCD(0,0)=0
$$

through its termination logic.

---

# 4. ADVANTAGES & LIMITATIONS

### Advantages

* **Parameterized width** using `WIDTH`.
* Iterative architecture requires only one subtraction datapath.
* Much less combinational hardware than a fully unrolled subtraction implementation.
* Simple FSM control.
* Supports zero operands.
* Provides `busy` and `done` handshake signals.
* Self-checking testbench.
* Synthesizable clocked RTL structure.

### Limitations

The main disadvantage is **latency**.

Subtractive Euclid's algorithm can require many iterations, particularly when the operands have an unfavorable ratio.

For example:

```text
GCD(1000000, 1)
```

would require a very large number of subtraction operations.

A modulo-based Euclidean algorithm:

```text
x, y = y, x % y
```

usually reaches the answer in substantially fewer iterations, but requires a modulo/division datapath.

Therefore, this design trades:

```text
Lower hardware complexity
        ↕
Potentially higher execution latency
```

---

# 5. INTERVIEW TAKEAWAYS

**Core concept:** Clocked iterative implementation of Euclid's GCD algorithm using repeated subtraction.

**Algorithm:**

```text
Load A and B

while x != 0 and y != 0:
    if x > y:
        x = x - y
    else:
        y = y - x

GCD = non-zero value
```

**Key RTL concepts demonstrated:**

* Parameterized RTL
* FSM-based control
* Sequential registers
* Asynchronous active-low reset
* Iterative arithmetic
* `busy/done` handshake
* One-cycle completion pulse
* Self-checking testbench
* Task-based testbench reuse

**One-line interview explanation:**

> “This is a parameterized clocked GCD unit that implements Euclid's algorithm using repeated subtraction, with an FSM controlling operand loading, iterative computation, and a one-cycle `done` indication when the GCD is available.”
