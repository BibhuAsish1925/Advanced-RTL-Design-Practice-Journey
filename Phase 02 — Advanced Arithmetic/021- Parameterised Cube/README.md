## PARAMETERIZED PIPELINED CUBE DESIGN

### 1. CIRCUIT OVERVIEW & APPLICATIONS

This design implements a **parameterized pipelined cube operation**:

$$
out = in^3
$$

For `width = 4`, the input is 4-bit (`0–15`) and the output is 12-bit because:

$$
3 \times width = 12
$$

The architecture separates the operation into stages:

* `in_reg` — captures the input.
* `sq_temp` — combinational square calculation: `in_reg × in_reg`.
* `pipe[0]` — stores the square together with the original input.
* `pipe[1]` — multiplies the stored square by the stored input, producing the cube.
* Remaining pipeline registers — delay the cube result.
* `out_reg` — stores the final output.

**Applications:** pipelined arithmetic units, DSP datapaths, mathematical accelerators, configurable RTL datapaths, and designs where a long arithmetic operation needs additional latency stages.

---

### 2. CIRCUIT WORKING & RTL IMPLEMENTATION

The important data path is:

```text
                 ┌─────────────────┐
in ──> in_reg ──>│ Square Multiplier│
        │        │  in_reg × in_reg│
        │        └───────┬─────────┘
        │                │ sq_temp
        │                ▼
        └────────────> pipe[0]
                         │
                         ▼
                  ┌──────────────┐
                  │ Cube Multiply│
                  │ square × input│
                  └──────┬───────┘
                         │
                         ▼
                     pipe[1]
                         │
                         ▼
                 pipeline registers
                         │
                         ▼
                      out_reg
                         │
                         ▼
                        out
```

For an input `x`:

```text
in_reg = x

sq_temp = x × x = x²

pipe[0] = {x², x}

pipe[1] = x² × x = x³

out_reg = delayed x³
```

For example:

```text
in = 5

5² = 25
25 × 5 = 125

out = 125
```

#### Important RTL details

```verilog
reg [width-1:0] in_reg;
```

Stores the input before multiplication.

```verilog
assign sq_temp = in_reg * in_reg;
```

This is the first combinational multiplication.

```verilog
pipe[0] <= {sq_temp, in_reg};
```

Stores both:

```text
[square | original input]
```

inside the first pipeline register.

The cube multiplication is then:

```verilog
pipe[1] <= pipe[0][width-1:0] *
           pipe[0][3*width-1:width];
```

For `width=4`:

```text
pipe[0][3:0]  = original input
pipe[0][11:4] = square
```

Therefore:

```text
pipe[1] = square × input
        = input³
```

The remaining registers:

```verilog
pipe[i] <= pipe[i-1];
```

simply add latency without changing the value.

---

### 3. PIPELINE LATENCY

With:

```verilog
pipeline_width = 9
```

the design intentionally introduces several clock stages between calculation and output.

Conceptually:

```text
Cycle       Operation
--------------------------------
C0          Input captured
C1          Square available
C2          Cube calculated
C3-C9       Cube propagated through pipeline
...
```

The exact observable latency depends on how the generated register stages interact with `in_reg`, `pipe[0]`, `pipe[1]`, and `out_reg`.

One important point: **`pipeline_width` is not simply equal to the mathematical latency of the cube operation.** It controls the number of storage stages, while the actual arithmetic stages are separately implemented.

---

## 4. VERIFICATION & TESTBENCH

The testbench instantiates:

```verilog
parameterised_cube #(
    .width(4),
    .pipeline_width(9)
)
```

Therefore:

```text
Input  = 4 bits
Output = 12 bits
Pipeline stages = 9
```

The clock has:

```verilog
always #5 clk = ~clk;
```

so the clock period is:

```text
10 ns
```

or:

```text
100 MHz
```

### Test cases

The TB applies:

```text
Input    Expected cube
----------------------
2        8
5        125
7        343
0        0
15       3375
```

The final `#200` delay gives the pipeline enough time to propagate the final values before simulation ends.

The `$monitor` continuously displays:

```text
time
input
output
```

so the pipeline behavior can be observed in simulation.

### Verification limitation

The current testbench is **not self-checking**. It prints values but does not automatically compare:

```text
actual output == expected input³
```

A stronger verification environment would calculate the expected cube and generate `PASS/FAIL`.

---

## 5. ADVANTAGES & LIMITATIONS

### Advantages

* **Parameterized input width**
* **Parameterized pipeline depth**
* Suitable for synthesizable RTL
* Arithmetic operation is divided into pipeline stages
* Higher clock frequency can potentially be achieved by inserting pipeline registers
* Demonstrates generate-based parameterized RTL
* Useful for studying **latency vs. throughput**

### Limitations

* Multiplication operators may synthesize into relatively large multiplier hardware.
* Additional pipeline registers increase **area and clock power**.
* The current TB does not automatically verify correctness.
* The generated structure is more complicated than necessary for a simple cube.
* The design description says the pipeline contents are shifted, but the actual RTL has special handling for `pipe[1]` and `out_reg`; therefore, it is better to understand the code itself rather than treating it as a completely uniform shift register.
* There is no explicit handling or documentation of what should happen for `pipeline_width < 2`.

### Important RTL observation

The reset only explicitly clears:

```verilog
in_reg
pipe[0]
out_reg
```

For `pipeline_width = 9`, registers such as `pipe[1]` through `pipe[7]` are also generated, but their reset branches **do clear them**, so the instantiated 9-stage version is properly initialized.

---

## 6. INTERVIEW TAKEAWAYS

**Core concept:** Parameterized pipelined arithmetic datapath for calculating `in³`.

**Why pipeline it?**
To break the arithmetic/data path into multiple clock stages, allowing higher operating frequency at the cost of additional latency and registers.

**Key equation:**

$$
in^3 = (in^2)\times in
$$

**Key RTL concepts demonstrated:**

* Parameterized module
* Generate blocks
* Pipeline registers
* Combinational multiplication
* Asynchronous active-low reset
* Nonblocking sequential assignments
* Configurable pipeline depth

**One-line interview explanation:**

> “This is a parameterized pipelined cube unit that first computes the square of the registered input, multiplies it by the original input to obtain the cube, and then passes the result through configurable pipeline stages to trade latency and register area for timing performance.”
