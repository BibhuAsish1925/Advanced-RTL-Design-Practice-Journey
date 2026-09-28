# 32-BIT SQUARE & CUBE ROOT CALCULATOR

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This design calculates the **square root** and **cube root** of a 32-bit input number.

It produces two 32-bit outputs:

```text
number ──────┬────> Square Root ───> sq_root
             │
             └────> Cube Root ──────> cube_root
```

The calculation is performed using exponentiation:

$$
\sqrt{N}=N^{0.5}
$$

and

$$
\sqrt[3]{N}=N^{1/3}
$$

For example:

```text
121  → √121 = 11
512  → ∛512 = 8
1000 → ∛1000 = 10
```

### Applications

* Mathematical computation
* Numerical-processing demonstrations
* Algorithm-to-RTL experimentation
* Hardware arithmetic studies
* Learning Verilog tasks and real-number operations

---

# 2. CIRCUIT WORKING & RTL IMPLEMENTATION

The main module receives:

```verilog
input [31:0] number
```

and produces:

```verilog
output reg [31:0] sq_root, cube_root
```

Whenever `number` changes:

```verilog
always @(number) begin
    find_sq_root(number, sq_root);
    find_cube_root(number, cube_root);
```

both calculations are performed.

### Square-root task

```verilog
task find_sq_root;
    input [31:0] num;
    output [31:0] res;
    begin
        res = num**(0.5);
    end
endtask
```

The expression:

```text
num ** 0.5
```

represents:

$$
num^{0.5}=\sqrt{num}
$$

The result is assigned to `res`.

---

### Cube-root task

```verilog
task find_cube_root;
    input [31:0] num;
    output [31:0] res;
    begin
        res = num**(1.0/3.0);
    end
endtask
```

Here:

$$
num^{1/3}=\sqrt[3]{num}
$$

Therefore, both tasks are essentially wrappers around exponentiation operations.

---

### `$display`

The module also prints:

```verilog
$display("\n \t\t Square Root of %0d is %0d", number, sq_root);
$display(" \t\t Cube Root of   %0d is %0d ", number, cube_root);
```

This makes the DUT itself responsible for displaying the calculated values during simulation.

---

# 3. VERIFICATION & TESTBENCH

The testbench applies eight input values:

| Input | Expected √N | Expected ∛N |
| ----: | ----------: | ----------: |
|    27 |          ~5 |           3 |
|   121 |          11 |          ~4 |
|   961 |          31 |          ~9 |
|   512 |         ~22 |           8 |
|  1764 |          42 |         ~12 |
|  1000 |         ~31 |          10 |
|  4761 |          69 |         ~16 |
|  5832 |         ~76 |          18 |

The particularly useful cases are the exact roots:

```text
27   → cube root = 3
121  → square root = 11
512  → cube root = 8
1764 → square root = 42
1000 → cube root = 10
4761 → square root = 69
5832 → cube root = 18
```

The input changes every 10 ns:

```verilog
#10 number = 27;
#10 number = 121;
...
```

and simulation ends after the final test.

### Verification limitation

The TB is **not self-checking**. It only provides inputs and relies on the DUT's `$display`.

Also, the supplied comments/code do not explicitly define whether the desired result for non-perfect roots is intended to be:

* truncated integer root,
* rounded root, or
* real-valued root.

Because `sq_root` and `cube_root` are 32-bit integer vectors, fractional portions cannot be represented.

---

# 4. IMPORTANT RTL/SYNTHESIS OBSERVATION

This is an important distinction for an RTL/VLSI interview.

Although the module is written in Verilog, this is **primarily simulation-oriented behavioral code rather than practical synthesizable arithmetic RTL**.

The expressions:

```verilog
num**(0.5)
```

and:

```verilog
num**(1.0/3.0)
```

use real-number exponentiation semantics. A conventional synthesis flow cannot generally turn these directly into practical square-root/cube-root hardware.

The declaration:

```verilog
real red;
```

is also unused.

Similarly, `task` is perfectly useful for simulation organization, but the actual root calculation inside these tasks is not a normal synthesizable square-root/cube-root implementation.

For real hardware, the design would normally use an algorithm such as:

```text
Square Root:
  binary-search / digit-recurrence / Newton-Raphson

Cube Root:
  iterative arithmetic / Newton-Raphson / lookup-based architecture
```

and, for a practical RTL implementation, typically introduce registers and an FSM for iterative calculation.

---

# 5. ADVANTAGES & LIMITATIONS

### Advantages

* Very compact code.
* Clearly separates square-root and cube-root operations using tasks.
* Easy to simulate.
* Simple mathematical representation.
* Demonstrates Verilog tasks and exponentiation.

### Limitations

* Not a practical synthesizable square/cube-root hardware implementation.
* Uses real-number exponentiation.
* No clock or reset.
* No explicit error/valid signal.
* Fractional roots cannot be represented by the integer outputs.
* Testbench is not self-checking.
* `real red` is unused.

---

# 6. INTERVIEW TAKEAWAYS

**Core concept:** Calculate square and cube roots using mathematical exponentiation.

**Equations:**

$$
\sqrt{N}=N^{1/2}
$$

$$
\sqrt[3]{N}=N^{1/3}
$$

**Key Verilog concepts demonstrated:**

* Tasks
* Combinational `always`
* Exponentiation operator `**`
* Integer/vector outputs
* `$display`
* Simulation-oriented behavioral modeling

**One-line interview explanation:**

> “This module behaviorally calculates the square and cube roots of a 32-bit input using exponentiation inside Verilog tasks; it is useful as a simulation model but would require an iterative or arithmetic root algorithm for practical synthesizable RTL.”
