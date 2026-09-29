# 4-PHASE CLOCK GENERATOR — RTL & TESTBENCH ANALYSIS

## 1. Circuit Overview & Applications

This design attempts to generate four related clock phases:

```text
clk_0
clk_90
clk_180
clk_270
```

The intended phase relationship is:

```text
clk_0 → 0°
clk_90 → 90°
clk_180 → 180°
clk_270 → 270°
```

The circuit uses:

* A 2-bit state counter `count`
* A divide-by-2 register `div_2`
* XOR and inversion logic to generate the four outputs

### Applications

* Multi-phase clocking concepts
* Timing/control circuits
* Clock-phase generation experiments
* Digital communication/timing architectures
* Understanding phase relationships in synchronous circuits

---

# 2. Circuit Working & RTL Implementation

## A. `count` State Machine

The first sequential block is:

```verilog
always @(posedge clk or posedge rst) 
begin
    if(rst)
        count <= 0;
    else 
        count <= {~count[0], count[1]};
end
```

Reset initializes:

```text
count = 00
```

The next-state expression is:

```verilog
{~count[0], count[1]}
```

For the two bits:

```text
count[1]next = ~count[0]
count[0]next = count[1]
```

Starting from `00`, the sequence becomes:

```text
Current → Next
00      → 10
10      → 11
11      → 01
01      → 00
```

Therefore:

```text
00 → 10 → 11 → 01 → 00 → ...
```

This is a four-state sequence.

---

# 3. `div_2` Register

The second sequential block is:

```verilog
always @(posedge clk or posedge rst) 
begin
    if (rst) 
        div_2 <= 0;
    else 
        div_2 <= ~div_2;
end
```

`div_2` toggles on every rising edge:

```text
Reset → 0

Clock edge:
0 → 1
1 → 0
0 → 1
1 → 0
...
```

Therefore, `div_2` is effectively a divide-by-2 state signal.

---

# 4. Output Generation

The outputs are:

```verilog
assign clk_0   = count[1];
assign clk_90  = count[1] ^ div_2;
assign clk_180 = ~count[1];
assign clk_270 = ~clk_90;
```

### `clk_0`

```verilog
clk_0 = count[1]
```

This directly uses the MSB of the state.

### `clk_180`

```verilog
clk_180 = ~count[1]
```

Therefore, `clk_180` is the logical complement of `clk_0`.

That gives the expected 180° inversion relationship:

```text
clk_0    = 0 → 1 → 0 → ...
clk_180  = 1 → 0 → 1 → ...
```

### `clk_90`

```verilog
clk_90 = count[1] ^ div_2
```

The XOR combines the two state signals.

### `clk_270`

```verilog
clk_270 = ~clk_90
```

Therefore:

```text
clk_270 = complement of clk_90
```

---

# 5. Important Observation About the "90° Phase" Claim

The RTL generates **four related logic waveforms**, but it does **not guarantee physically accurate 90° phase-shifted clocks**.

A true 90° phase relationship means that transitions should be separated by one-quarter of the clock period.

This RTL instead derives the outputs from flip-flop state bits and combinational XOR/inversion logic.

So the appropriate description is:

> **A digital four-phase clock-like waveform generator demonstrating phase relationships using sequential state and combinational logic.**

It should not automatically be considered a true hardware 4-phase clock generator.

For practical FPGA/ASIC clock generation, dedicated clocking resources such as PLL/MMCM/DLL structures or carefully designed clock-generation circuits are normally used.

---

# 6. Testbench Analysis

The clock is generated using:

```verilog
initial begin
    clk = 0;
    forever #1 clk = ~clk;
end
```

Therefore:

```text
Half-period = 1 ns
Full period = 2 ns
```

So:

$$
f_{clk}=\frac{1}{2ns}=500MHz
$$

The reset is initially asserted:

```verilog
rst = 1;
```

and released after:

```verilog
#5 rst = 0;
```

So reset is active for the first 5 ns.

Simulation then continues for another 50 ns:

```verilog
#50 $finish;
```

Thus, the total simulation duration is approximately **55 ns**.

---

# 7. Expected State Sequence

After reset is released, the `count` state follows:

```text
Clock edge     count
----------     -----
Reset           00
1               10
2               11
3               01
4               00
5               10
6               11
7               01
...
```

Meanwhile:

```text
div_2:
0 → 1 → 0 → 1 → 0 → ...
```

The outputs are continuously derived from these signals.

A waveform viewer is therefore the most useful way to inspect this design.

---

# 8. Testbench Limitations

The testbench currently has no:

* `$monitor`
* `$display`
* Automatic phase verification
* PASS/FAIL checking

So it is essentially a **waveform-based testbench**.

For example, it could be improved by monitoring:

```verilog
$monitor("t=%0t clk=%b count=%b div2=%b clk0=%b clk90=%b clk180=%b clk270=%b",
         $time, clk, dut.count, dut.div_2,
         clk_0, clk_90, clk_180, clk_270);
```

That would make the state and output relationships directly visible in the simulator console.

---

# 9. Advantages & Limitations

### Advantages

* Simple RTL implementation.
* Uses only two small sequential state elements.
* Generates four related output waveforms.
* `clk_180` is directly complementary to `clk_0`.
* `clk_270` is complementary to `clk_90`.
* Demonstrates sequential state generation and combinational phase logic.

### Limitations

* Does not guarantee precise 90° phase shifts.
* XOR/inverter paths introduce combinational propagation delay.
* Generated clock-like signals can have skew/glitch concerns.
* The outputs are not generated using dedicated clock-management resources.
* No output verification is implemented in the TB.
* At the chosen TB clock of 500 MHz, physical implementation timing would require careful analysis.

---

# 10. Interview Takeaways

**One-line explanation:**

> This RTL generates four related clock-like waveforms from a four-state sequential sequence and a divide-by-2 signal, using XOR and inversion to derive the phase outputs.

### Likely interview questions

**Q: What is the `count` sequence?**

```text
00 → 10 → 11 → 01 → 00
```

**Q: What does `div_2` do?**

It toggles on every positive clock edge, giving a divide-by-2 state signal.

**Q: Why is `clk_180` the inverse of `clk_0`?**

```verilog
assign clk_180 = ~count[1];
```

so it is logically complementary to `clk_0`.

**Q: Why is `clk_270` the inverse of `clk_90`?**

```verilog
assign clk_270 = ~clk_90;
```

**Q: Is this a true 90° phase-shifted clock generator?**

Not strictly. It generates related digital waveforms, but the RTL does not guarantee precise physical 90° phase separation. Dedicated clock-management circuitry is normally used when accurate phase shifts are required.

**Q: What is the input clock frequency in the TB?**

$$
T=2ns
$$

therefore:

$$
f_{clk}=500MHz
$$
