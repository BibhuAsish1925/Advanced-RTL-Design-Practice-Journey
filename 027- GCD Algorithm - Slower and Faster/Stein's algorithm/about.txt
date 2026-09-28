# PARAMETERIZED BINARY GCD UNIT

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This design implements the **Binary GCD algorithm**, also called **Stein's algorithm**, for two unsigned `WIDTH`-bit numbers.

Unlike the previous `gcd_basic` design, which repeatedly subtracts one operand from the other, this version also exploits the fact that division by 2 can be implemented as a simple right shift.

The core operations are:

```text
Both even:
    u = u >> 1
    v = v >> 1
    k = k + 1

u even:
    u = u >> 1

v even:
    v = v >> 1

Both odd:
    subtract smaller from larger
```

The common powers of two are tracked in `k`, and the final result is:

$$
GCD(A,B)=u\times2^k
$$

when the algorithm reaches `u == v`.

### Applications

* Digital arithmetic units
* Number-theoretic hardware
* Cryptographic hardware
* Modular arithmetic systems
* Hardware accelerators
* Low-complexity GCD computation

---

# 2. CIRCUIT WORKING & RTL IMPLEMENTATION

The design uses four FSM states:

```text id="c3f71d"
S_IDLE
   │
   │ start
   ▼
S_INIT
   │
   │ both odd
   ▼
S_RUN
   │
   │ subtraction
   └──────────> S_INIT
                    │
                    │ u == v
                    ▼
                  S_DONE
                    │
                    ▼
                  S_IDLE
```

The main internal registers are:

```verilog id="zhbupm"
reg [WIDTH-1:0] u, v;
```

These contain the current reduced operands.

`k` stores the number of common factors of 2 removed from both operands.

---

## S_IDLE — Load operands

When `start` is asserted:

```verilog id="k8q05f"
u <= A;
v <= B;
k <= 0;
busy <= 1'b1;
st <= S_INIT;
```

The operands are captured and computation begins.

---

## S_INIT — Binary GCD reduction

This is the main normalization stage.

### Case 1: `u == 0`

```verilog id="jgxq9c"
if (u == 0) begin
    gcd <= v;
    st <= S_DONE;
end
```

The remaining non-zero operand is the GCD.

Similarly:

```verilog id="2p1k2v"
else if (v == 0) begin
    gcd <= u;
    st <= S_DONE;
end
```

handles the other zero case.

---

### Case 2: Both operands are even

```verilog id="y9b3kx"
else if (~u[0] && ~v[0]) begin
    u <= u >> 1;
    v <= v >> 1;
    k <= k + 1'b1;
end
```

An LSB of `0` indicates an even number.

For example:

```text id="f5abkw"
u = 48
v = 18

both even

u = 24
v = 9
k = 1
```

The common factor of 2 is removed and remembered in `k`.

---

### Case 3: Only `u` is even

```verilog id="64k9jc"
else if (~u[0])
    u <= u >> 1;
```

Only `u` is divided by 2.

---

### Case 4: Only `v` is even

```verilog id="q4sm1v"
else if (~v[0])
    v <= v >> 1;
```

Only `v` is divided by 2.

---

### Case 5: Both operands are odd

```verilog id="p6u9hr"
else
    st <= S_RUN;
```

The design moves to `S_RUN`.

---

# 3. S_RUN — SUBTRACTION

When both values are odd:

```verilog id="f0up1g"
if (u == v) begin
    gcd <= u << k;
    st <= S_DONE;
end
```

If they are equal, the algorithm has reached the GCD after restoring the common powers of two.

Otherwise:

```verilog id="8q7wwu"
if (u > v)
    u <= u - v;
else
    v <= v - u;
```

For example:

```text id="h2sq6w"
u = 27
v = 9

u > v

u = 27 - 9
u = 18
```

The FSM returns to `S_INIT`:

```verilog id="t8f7b2"
st <= S_INIT;
```

so the new values are normalized again by removing powers of two.

---

# 4. WHY `k` IS REQUIRED

This is one of the most important concepts in this implementation.

Suppose:

```text id="y1w6s1"
A = 48
B = 18
```

Both are even:

```text
48 = 2 × 24
18 = 2 × 9
```

So:

```text
k = 1
u = 24
v = 9
```

Eventually the algorithm reaches:

```text
u = v = 3
k = 1
```

The GCD is therefore:

$$
3\times2^1=6
$$

The RTL performs this restoration using:

```verilog id="q2j7ps"
gcd <= u << k;
```

because shifting left by `k` is equivalent to multiplying by \(2^k\).

---

# 5. VERIFICATION & TESTBENCH

The testbench is essentially the same verification structure as the previous GCD design.

The clock is:

```verilog id="gqf6fn"
always #5 clk = ~clk;
```

giving:

```text id="rwh8vh"
Period = 10 ns
Frequency = 100 MHz
```

The reusable `run_test` task:

1. Loads operands.
2. Generates a `start` pulse.
3. Waits for `done`.
4. Compares `gcd` with the expected value.
5. Prints `PASS` or `FAIL`.

The tests are:

|    A |   B | Expected GCD |
| ---: | --: | -----------: |
|   48 |  18 |            6 |
|    0 |   5 |            5 |
|    7 |   0 |            7 |
|    1 |   1 |            1 |
|   17 |  13 |            1 |
| 1000 | 500 |          500 |
|    0 |   0 |            0 |

For example:

```text id="lvj5ex"
GCD(48,18) = 6
GCD(0,5)  = 5
GCD(7,0)  = 7
GCD(1,1)  = 1
GCD(17,13) = 1
GCD(1000,500) = 500
GCD(0,0) = 0
```

The comparison:

```verilog id="qgq9z1"
if (gcd === expected)
```

makes the testbench **self-checking**.

---

# 6. ADVANTAGES & LIMITATIONS

### Advantages

* Parameterized for different operand widths.
* Uses shifts instead of explicit division by 2.
* Exploits binary properties of the operands.
* Iterative architecture reduces combinational hardware.
* Uses an FSM for clear control.
* Handles zero operands.
* Provides `busy` and one-cycle `done`.
* Self-checking testbench.

### Limitations

* It is still an **iterative algorithm**, so the result requires multiple clock cycles.
* Subtraction is still required when both operands are odd.
* Latency depends on the input values.
* The `k` counter introduces additional state/storage.
* A modulo-based Euclidean implementation may require fewer iterations, although it requires more complex arithmetic hardware.

---

# 7. IMPORTANT CODE OBSERVATION

The function:

```verilog id="b2d04h"
function [WIDTH-1:0] rshift_1(input [WIDTH-1:0] x);
    rshift_1 = x >> 1;
endfunction
```

is defined but **never used** in the actual RTL.

The design directly performs:

```verilog id="z6v2x0"
u <= u >> 1;
v <= v >> 1;
```

So `rshift_1` is currently redundant and can be removed without changing the behavior of the supplied implementation.

Similarly, the custom:

```verilog id="lqzj3g"
function integer clog2
```

is used to determine the width of `k`:

```verilog id="wzq0fj"
reg [clog2(WIDTH+1)-1:0] k;
```

For `WIDTH = 32`:

```text id="2g0v7b"
clog2(33) = 6
```

so `k` is 6 bits wide.

---

# 8. INTERVIEW TAKEAWAYS

**Core concept:** Iterative Binary GCD/Stein's algorithm using shifts and subtraction.

**Key mathematical idea:**

$$
GCD(2u,2v)=2GCD(u,v)
$$

and:

$$
GCD(2u,v)=GCD(u,v)
$$

when `v` is odd.

**Key RTL concepts:**

* FSM-based iterative datapath
* Parameterized operand width
* Right shifts for division by 2
* Left shift for restoring common powers of 2
* Operand comparison/subtraction
* `busy/done` handshake
* One-cycle completion pulse
* Self-checking testbench

**One-line interview explanation:**

> “This is a parameterized iterative Binary GCD unit that removes common powers of two using shifts and reduces odd operands through subtraction, while tracking the removed powers in `k` and restoring them when the GCD is obtained.”
