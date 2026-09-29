# CLOCK EDGE DETECTOR — RTL & TESTBENCH ANALYSIS

## 1. Circuit Overview & Applications

This circuit detects **positive, negative, and both edges** of a clock by comparing the current clock signal `clk` with a delayed version `temp_clk`.

The key idea is:

```text
Current clock ───────────────┐
                             │
                             ▼
                        Edge Logic
                             ▲
                             │
Clock delayed by 1 ns ───────┘
```

It generates three outputs:

* `posedge_detect` → HIGH around a rising edge
* `negedge_detect` → HIGH around a falling edge
* `dualedge_detect` → HIGH around either edge

### Applications

* Clock edge detection
* Event/transition detection
* Pulse generation
* Timing-modeling concepts
* Synchronization and interface logic
* Simulation-oriented edge detection

---

# 2. Circuit Working & RTL Implementation

The delayed clock is represented by `temp_clk`.

The three equations are:

```verilog
assign posedge_detect = clk & (~temp_clk);
assign negedge_detect = (~clk) & temp_clk;
assign dualedge_detect = clk ^ temp_clk;
```

## Positive-edge detection

```verilog
clk & (~temp_clk)
```

When the clock has just transitioned:

```text
clk       = 1
temp_clk  = 0
```

the output becomes:

```text
posedge_detect = 1
```

Therefore, this identifies a **0 → 1 transition**.

---

## Negative-edge detection

```verilog
(~clk) & temp_clk
```

Immediately after a falling transition:

```text
clk       = 0
temp_clk  = 1
```

so:

```text
negedge_detect = 1
```

This identifies a **1 → 0 transition**.

---

## Dual-edge detection

```verilog
clk ^ temp_clk
```

XOR is HIGH whenever the two signals differ:

```text
clk temp_clk | dualedge
-----------------------
 0     0     |    0
 0     1     |    1
 1     0     |    1
 1     1     |    0
```

Therefore, it detects **both rising and falling transitions**.

---

# 3. Testbench Analysis

The clock is generated using:

```verilog
initial forever #5 clk <= ~clk;
```

Therefore:

```text
Half-period = 5 ns
Full period = 10 ns
```

So the input clock frequency is:

$$
f_{clk}=\frac{1}{10ns}=100MHz
$$

The delayed version is generated using:

```verilog
always @(clk)
    temp_clk <= #1 clk;
```

Every time `clk` changes, `temp_clk` follows it **1 ns later**.

Therefore, around every clock transition, there is a 1 ns interval during which:

```text
clk != temp_clk
```

During that interval, the edge detectors become active.

---

# 4. Expected Operation

### Rising edge

At approximately:

```text
t = 5 ns
```

the clock changes:

```text
clk:       0 → 1
temp_clk:  0
```

For the next 1 ns:

```text
clk       = 1
temp_clk  = 0

posedge_detect = 1
negedge_detect = 0
dualedge_detect = 1
```

After 1 ns, `temp_clk` becomes 1 and the outputs return to zero.

### Falling edge

At approximately:

```text
t = 10 ns
```

the clock changes:

```text
clk:       1 → 0
temp_clk:  1
```

For the next 1 ns:

```text
clk       = 0
temp_clk  = 1

posedge_detect = 0
negedge_detect = 1
dualedge_detect = 1
```

Thus:

```text
Rising edge → posedge_detect + dualedge_detect
Falling edge → negedge_detect + dualedge_detect
```

---

# 5. Important Hardware/Synthesis Observation

The `#1` delay is the most important point in this design:

```verilog
temp_clk <= #1 clk;
```

This is primarily **simulation/timing-modeling behavior**, not a synthesizable way to create a physical 1 ns delay.

In ordinary synthesizable RTL, you generally cannot specify:

> "Make this signal exactly 1 ns slower."

The actual hardware delay depends on:

* Cell delays
* Routing
* Process/voltage/temperature
* FPGA implementation resources
* ASIC physical implementation

Therefore, this is best treated as a **simulation-oriented edge detector demonstration**.

For actual synchronous hardware, edge detection is normally implemented using registers and clocked sampling rather than explicit `#` delays.

---

# 6. Testbench Verification

The testbench uses:

```verilog
$monitor(
    "clock: %b  posedge: %b  negedge: %b  dualedge: %b",
    clk, posedge_detect, negedge_detect, dualedge_detect
);
```

This continuously reports changes in the monitored signals.

Simulation terminates after:

```verilog
#30 $finish;
```

With a 10 ns clock period, approximately three clock cycles are observed.

However, the TB is **not self-checking**. It does not automatically determine whether the outputs are correct.

A stronger TB would explicitly verify:

```text
Rising edge  → posedge=1, negedge=0, dualedge=1
Falling edge → posedge=0, negedge=1, dualedge=1
Stable clock → all outputs=0
```

---

# 7. Advantages & Limitations

### Advantages

* Very simple edge-detection equations.
* Positive and negative edges are independently identified.
* XOR naturally provides dual-edge detection.
* Easy to visualize in simulation.
* Useful for understanding transition detection.

### Limitations

* Relies on an explicit `#1` simulation delay.
* Not a robust synthesizable implementation of a physical edge detector.
* Output pulse width is determined by the modeled delay.
* No reset or initialization logic inside the DUT.
* Testbench does not contain automatic PASS/FAIL checking.

---

# 8. Interview Takeaways

**One-line explanation:**

> This circuit detects clock transitions by comparing the current clock with a 1 ns delayed version; AND logic identifies individual rising/falling edges and XOR identifies either edge.

### Important interview questions

**Q: Why does XOR detect both edges?**

Because:

$$
clk\oplus temp\_clk=1
$$

whenever the current and delayed clocks are different, which occurs during either transition.

**Q: Why does `clk & ~temp_clk` detect a rising edge?**

After a rising transition, the current clock is already `1` while the delayed clock remains `0`.

**Q: Why is the output pulse 1 ns wide?**

Because `temp_clk` follows `clk` after the modeled `#1` delay.

**Q: Is `#1` synthesizable?**

Not as a guaranteed physical 1 ns delay in normal RTL synthesis. It is primarily a **simulation timing construct**.

**Q: What is the input clock frequency in this TB?**

$$
T=10ns
$$

so:

$$
f=100MHz
$$

**Q: What is the main practical concern?**

Using delayed clock signals and combinational logic to generate edge-related pulses is generally unsuitable for production clocking because physical delays, glitches, skew, and PVT variation must be handled explicitly.
