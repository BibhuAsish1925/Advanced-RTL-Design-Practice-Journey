# PARAMETERIZED REGISTER

=================================

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This module implements a **parameterized shift-register structure** using a chain of flip-flops.

The default parameter is:

```verilog
parameter WIDTH = 8;
```

So the design contains **8 one-bit registers** connected in series.

```text
        +----+    +----+    +----+          +----+
in ---> | FF0| -> | FF1| -> | FF2| -> ... -> | FF7| ---> op
        +----+    +----+    +----+          +----+
           ↑         ↑         ↑                ↑
                         CLK
```

On every rising edge of `clk`, the input moves one stage forward.

Applications include:

* Serial-to-parallel data movement
* Pipeline delay elements
* Data buffering
* Serial communication interfaces
* Digital signal-processing pipelines
* Configurable delay lines

---

# 2. HOW THE CIRCUIT WORKS

The register is declared as:

```verilog
reg [0:WIDTH-1] d_ff;
```

For `WIDTH = 8`:

```text
d_ff[0] ... d_ff[7]
```

The first stage receives the external input:

```verilog
d_ff[0] <= rst ? 0 : in;
```

The remaining stages receive the previous stage:

```verilog
d_ff[i+1] <= rst ? 0 : d_ff[i];
```

Therefore, on every positive clock edge:

```text
d_ff[0] <= in
d_ff[1] <= old d_ff[0]
d_ff[2] <= old d_ff[1]
...
d_ff[7] <= old d_ff[6]
```

Because these are **non-blocking assignments (`<=`)**, all stages use the values from the previous clock cycle.

---

# 3. RESET OPERATION

Each register has:

```verilog
always @(posedge clk,posedge rst)
```

Therefore, `rst` is **asynchronous active-high reset**.

When:

```text
rst = 1
```

the registers are cleared to zero.

For example:

```text
d_ff = 00000000
```

The expression:

```verilog
rst ? 0 : in
```

means:

```text
rst = 1 → 0
rst = 0 → input/value being shifted
```

So the reset operation does not have to wait for a clock edge.

---

# 4. GENERATE BLOCK

The code uses:

```verilog
genvar i;

generate
    for(i=0; i<WIDTH-1; i=i+1)
    begin
        always @(posedge clk,posedge rst)
            d_ff[i+1] <= rst ? 0 : d_ff[i];
    end
endgenerate
```

For:

```text
WIDTH = 8
```

the generate loop creates:

```text
d_ff[1] <= d_ff[0]
d_ff[2] <= d_ff[1]
d_ff[3] <= d_ff[2]
d_ff[4] <= d_ff[3]
d_ff[5] <= d_ff[4]
d_ff[6] <= d_ff[5]
d_ff[7] <= d_ff[6]
```

So there are effectively **8 flip-flops**.

The advantage of the parameter is that the same RTL can create different register-chain lengths.

For example:

```verilog
WIDTH = 4
```

creates:

```text
FF0 → FF1 → FF2 → FF3
```

while:

```verilog
WIDTH = 16
```

creates:

```text
FF0 → FF1 → ... → FF15
```

---

# 5. OUTPUT

The output is:

```verilog
assign op = d_ff[WIDTH-1];
```

Therefore, for `WIDTH=8`:

```text
op = d_ff[7]
```

The input reaches `op` after passing through all 8 stages.

Conceptually:

```text
Clock 1:  in → FF0
Clock 2:  in → FF1
Clock 3:  in → FF2
...
Clock 8:  in → FF7 → op
```

So it behaves as an approximately **WIDTH-cycle serial delay line**.

---

# 6. TESTBENCH

The testbench uses:

```verilog
localparam WIDTH = 8;
```

However, there is an important issue:

### The DUT parameter is not actually overridden.

You declare:

```verilog
localparam WIDTH = 8;
```

in the testbench, but the instantiation is:

```verilog
Parameterised_Register uut (
```

without:

```verilog
#(.WIDTH(WIDTH))
```

In this particular case it still works because the DUT's default is also `WIDTH=8`.

For a genuinely parameterized testbench, use:

```verilog
Parameterised_Register #(
    .WIDTH(WIDTH)
) uut (
    .in(in),
    .clk(clk),
    .rst(rst),
    .op(op)
);
```

This becomes important if you later change:

```verilog
localparam WIDTH = 16;
```

---

# 7. CLOCK GENERATION

The clock is:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Half period = 5 ns
Full period = 10 ns
```

So:

```text
Clock frequency = 100 MHz
```

The positive edges occur approximately at:

```text
5 ns, 15 ns, 25 ns, 35 ns, ...
```

---

# 8. TEST CASES

### Test 1 — All zeros

```verilog
in = 0;
#20;
```

The register chain remains:

```text
00000000
```

---

### Test 2 — Toggling input

```verilog
in = 0;
#10 in = 1;
#10 in = 0;
#10 in = 1;
#10 in = 0;
```

This allows you to observe the input pattern propagating through the register stages.

For example, after several clock cycles:

```text
in → FF0 → FF1 → FF2 → ... → FF7
```

---

### Test 3 — Constant high

```verilog
in = 1;
#20;
```

After enough clock cycles, the `1` propagates through the entire chain.

---

### Test 4 — Random input

```verilog
in = $random;
#20;
```

This applies a random value to the single-bit input.

Note that since `in` is only **1 bit**, `$random` is automatically truncated to its least-significant bit when assigned to `in`.

---

# 9. ONE TESTBENCH LIMITATION

The testbench does not contain:

```verilog
$monitor(...)
```

or a reference-model comparison.

Therefore, it does not automatically report whether the register is behaving correctly.

You would normally inspect `op` and/or the internal `d_ff` waveform.

For stronger verification, you could check that:

```text
op(t) = input(t - WIDTH clock cycles)
```

after reset and pipeline filling.

---

# 10. ADVANTAGES & LIMITATIONS

### Advantages

* Parameterized register depth.
* Simple and synthesizable.
* Uses non-blocking assignments correctly for sequential logic.
* Asynchronous reset.
* Generate loop avoids manually writing every register stage.
* Useful for configurable pipeline/delay structures.

### Limitations

* Uses one flip-flop per stage.
* `WIDTH` directly determines area.
* Output has `WIDTH` clock-cycle latency before a new input reaches the final stage.
* Current testbench has limited automatic checking.
* Multiple `always` blocks are generated, although synthesis tools generally handle this structure.

---

# 11. INTERVIEW TAKEAWAY

**Question: Why is a generate loop used here?**

> The generate loop creates a configurable number of register stages based on the `WIDTH` parameter, allowing the same RTL to implement different shift-register lengths.

**Question: Why are non-blocking assignments used?**

> Non-blocking assignments ensure that every stage captures the previous stage's value simultaneously at the clock edge, which gives the desired shift-register behavior.

### Core operation

```text
        WIDTH-stage shift register

in ──► FF0 ──► FF1 ──► FF2 ──► ... ──► FFn-1 ──► op
        │       │       │                │
        └───────┴───────┴──── CLK ───────┘
```

**Key concepts:** parameterization, generate blocks, flip-flop chains, non-blocking assignments, asynchronous reset, and configurable pipeline/delay depth.
