# Clock Glitch & Stall Monitor

## 1. Circuit Overview & Applications

This module is a **reference-clock-based monitor for an asynchronous clock**. It observes `clk_mon` using `clk_ref` and raises a sticky `fault` when the observed edge spacing falls outside the allowed period window.

The configured limits are:

```text
MIN_PERIOD = 10 reference-clock cycles
MAX_PERIOD = 100 reference-clock cycles
```

So the intended behavior is:

```text
Edge spacing < 10 cycles    → fault
10–100 cycles               → normal
Edge spacing > 100 cycles   → fault
No edge for >100 cycles     → fault
```

The architecture is:

```text
                    clk_mon
                       │
                       ▼
              +----------------+
              | 3-stage         |
              | synchronizer    |
              +--------+-------+
                       │
                       ▼
                 Edge detection
                       │
                       ▼
              +----------------+
              | Period counter  |
              +--------+-------+
                       │
             +---------+---------+
             │                   │
       Too-fast edge       Too-slow/stall
             │                   │
             +---------+---------+
                       │
                       ▼
                     fault
```

This type of circuit is relevant to:

* Clock/frequency monitoring
* Clock-stall detection
* Fault detection
* Safety-oriented digital systems
* Supervisory logic
* Clock health monitoring

---

# 2. Circuit Working & RTL Implementation

## A. Synchronizing `clk_mon`

The monitored clock is asynchronous to `clk_ref`, so the design first samples it through:

```verilog
reg [2:0] mon_sync;

always @(posedge clk_ref or negedge rst_n) begin
  if (!rst_n)
    mon_sync <= 3'b000;
  else
    mon_sync <= {mon_sync[1:0], clk_mon};
end
```

This creates a three-stage sampling pipeline:

```text
clk_mon
   │
   ▼
[FF0] → [FF1] → [FF2]
                  │
                  ▼
             edge detection
```

The intent is to reduce the probability that metastability propagates into the monitoring logic.

---

## B. Edge Detection

The code uses:

```verilog
wire mon_rise =
    (mon_sync[2:1] == 2'b01) ||
    (mon_sync[2:1] == 2'b10);
```

Despite the name `mon_rise`, this actually detects **either transition**:

```text
01 → one transition
10 → the other transition
```

Therefore it is more accurately described as:

> **synchronized edge detection**, not rising-edge detection.

For example:

```text
mon_sync[2:1]

00 → no edge
01 → edge
11 → no edge
10 → edge
```

So both rising and falling edges of `clk_mon` are monitored.

### Important consequence

The monitor measures the interval between **any consecutive edges**, not the full period between rising edges.

For a 50% duty-cycle clock:

```text
rising → falling = T/2
falling → rising = T/2
```

Therefore, if `MIN_PERIOD` and `MAX_PERIOD` are intended to represent the **full clock period**, this implementation does not measure that quantity.

It measures approximately **half-period spacing** for a symmetric clock.

---

# 3. Period Counter

The counter is:

```verilog
reg [CW-1:0] cnt;
```

It increments once per `clk_ref` cycle:

```verilog
cnt <= (cnt == {CW{1'b1}})
       ? cnt
       : cnt + 1'b1;
```

The counter saturates at its maximum value rather than wrapping around.

This is useful because a long clock stall should remain detectable rather than allowing the counter to overflow back to zero.

---

## Edge-based checking

When an edge is detected:

```verilog
if (mon_rise) begin
```

the counter is compared against the allowed window.

### Too-fast condition

```verilog
if (cnt < MIN_PERIOD[CW-1:0])
    fault <= 1'b1;
```

If too few reference-clock cycles have elapsed since the previous monitored edge, the monitored clock is considered too fast.

### Too-slow condition

```verilog
if (cnt > MAX_PERIOD[CW-1:0])
    fault <= 1'b1;
```

If the interval has exceeded the maximum allowed value, the fault is asserted.

Then:

```verilog
cnt <= {CW{1'b0}};
```

starts measuring the next interval.

---

# 4. Stall Detection

The important additional check is:

```verilog
if (cnt > MAX_PERIOD[CW-1:0])
    fault <= 1'b1;
```

This runs even when there is **no monitored-clock edge**.

Therefore:

```text
last clk_mon edge
       │
       ├── 1 cycle
       ├── 2 cycles
       ├── ...
       ├── 100 cycles
       └── >100 cycles → fault = 1
```

This detects a stopped or excessively slow monitored clock.

---

# 5. `fault` Is Sticky

Notice that there is no normal-operation assignment such as:

```verilog
fault <= 1'b0;
```

inside the main `else` block.

Therefore, once:

```verilog
fault <= 1'b1;
```

occurs, it remains HIGH until reset.

So:

```text
fault = 0
   │
   │ violation
   ▼
fault = 1
   │
   │ remains HIGH
   │
   └──── reset → fault = 0
```

This is useful for fault-monitoring logic because software or supervisory logic can inspect the fault after the actual violation has disappeared.

---

# 6. Testbench Analysis

The reference clock is:

```verilog
localparam REF_PERIOD = 10;
```

Therefore:

```text
Tref = 10 ns
fref = 100 MHz
```

The testbench generates:

```verilog
initial clk_ref = 1'b0;
always #(REF_PERIOD/2) clk_ref = ~clk_ref;
```

giving a clean 100-MHz reference clock.

---

## Test 1 — Healthy monitored clock

```verilog
repeat (6) begin
  #(REF_PERIOD*30);
  clk_mon = ~clk_mon;
end
```

The monitored clock changes state every:

```text
30 × 10 ns = 300 ns
```

Because every transition is monitored, consecutive edges are 30 reference-clock cycles apart.

The allowed window is:

```text
MIN_PERIOD = 10
MAX_PERIOD = 100
```

and:

```text
10 < 30 < 100
```

Therefore:

```text
Expected fault = 0
```

This verifies the normal operating window.

---

# 7. Test 2 — Too-Fast Edges

```verilog
repeat (6) begin
  #(REF_PERIOD*3);
  clk_mon = ~clk_mon;
end
```

Edges occur every:

```text
3 × 10 ns = 30 ns
```

or approximately:

```text
3 reference-clock cycles
```

Since:

```text
3 < MIN_PERIOD(10)
```

the monitor should assert:

```text
fault = 1
```

Because the fault is sticky, subsequent normal edges would not clear it.

---

# 8. Test 3 — Clock Stall

After resetting the fault:

```verilog
rst_n = 1'b0;
#(REF_PERIOD*2);
rst_n = 1'b1;
```

the testbench holds `clk_mon` constant:

```verilog
#(REF_PERIOD*150);
```

That corresponds to:

```text
150 × 10 ns = 1500 ns
```

with no monitored edge.

The maximum permitted interval is:

```text
100 reference-clock cycles
```

so the monitor should detect:

```text
150 > 100
```

and assert:

```text
fault = 1
```

This verifies the **stall detector**.

---

# 9. Test 4 — Fault Reset

Finally:

```verilog
rst_n = 1'b0;
#(REF_PERIOD*2);
rst_n = 1'b1;
```

checks that the sticky fault is cleared by reset.

Expected:

```text
Before reset: fault = 1
After reset : fault = 0
```

---

# 10. Important RTL Timing/Functional Considerations

There are a few points worth understanding carefully.

### 1. `mon_rise` is actually any-edge detection

The name is misleading:

```verilog
wire mon_rise = ...
```

It detects both `01` and `10`.

A better name would be:

```verilog
wire mon_edge = (mon_sync[2:1] == 2'b01) ||
                (mon_sync[2:1] == 2'b10);
```

---

### 2. It measures edge-to-edge spacing, not clock period

This is probably the most important architectural point.

For:

```text
clk_mon = 50 MHz
```

the full period is:

```text
20 ns
```

but consecutive rising/falling edges are separated by roughly:

```text
10 ns
```

Therefore, if you want:

```text
MIN_PERIOD = minimum clock period
MAX_PERIOD = maximum clock period
```

you normally need to measure **same-polarity edges**, typically synchronized rising edges.

The current implementation instead measures:

```text
rising → falling
falling → rising
```

---

### 3. The synchronizer limits measurement precision

Because `clk_mon` is sampled by `clk_ref`, the measured interval has quantization uncertainty of roughly a reference-clock cycle.

With:

```text
Tref = 10 ns
```

you cannot precisely distinguish arbitrary intervals such as:

```text
102 ns vs 105 ns
```

using only this counter architecture.

---

### 4. `CW` must be large enough

With:

```verilog
CW = 16
```

the counter can represent:

```text
0 → 65535
```

which is more than enough for `MAX_PERIOD = 100`.

For larger windows, `CW` must be increased accordingly.

---

# 11. Advantages & Limitations

### Advantages

* Parameterized minimum and maximum period limits.
* Detects both excessively fast operation and clock stalls.
* Uses a stable reference clock.
* Sticky fault simplifies fault logging.
* Saturating counter prevents rollover.
* Includes synchronization for the asynchronous monitored clock.
* Synthesizable RTL structure.

### Limitations

* Current design monitors **both edges**, not complete clock periods.
* Measurement resolution is limited by `clk_ref`.
* A monitored clock significantly faster than the reference clock cannot be reliably measured with this sampling architecture.
* Synchronization introduces latency.
* The testbench does not automatically perform PASS/FAIL checking.
* The design assumes that sampling `clk_mon` with `clk_ref` is sufficient for the intended monitoring accuracy.

---

# 12. ASIC / FPGA Relevance

This is a useful RTL example for **clock-health monitoring**, but in an actual ASIC/FPGA clock-monitoring architecture, the implementation depends heavily on the required frequency range and accuracy.

For example:

```text
Low-frequency monitoring
        ↓
Reference-clock sampling can work

High-frequency monitoring
        ↓
Reference-clock sampling becomes inadequate

High-accuracy clock measurement
        ↓
Dedicated counter/timer/clock-monitor architecture
```

For FPGA implementations, dedicated clock-management resources such as PLL/MMCM-related circuitry may be more appropriate when the requirement is actual clock-frequency/phase monitoring rather than simple digital fault detection.

---

# 13. Interview Takeaway

**One-line explanation:**

> “This module synchronizes an asynchronous monitored clock into a reference-clock domain and uses a saturating counter to detect edge intervals that are too short, too long, or absent for too long, generating a sticky fault.”

### Likely interview questions

1. Why is `clk_mon` synchronized before being used?
2. Why are three synchronization stages used?
3. Does this design measure clock period or edge-to-edge interval?
4. Why is the counter saturating?
5. Why is `fault` sticky?
6. What happens if `clk_mon` is faster than `clk_ref`?
7. How would you modify the design to measure **rising-edge-to-rising-edge period**?
8. What determines the measurement resolution?
9. What happens if `MAX_PERIOD >= 2^CW`?
10. Why is a reference-clock-based monitor unsuitable for very high-frequency monitored clocks?

**Most important correction to remember:** the current RTL's `mon_rise` is actually **any-edge detection**, so `MIN_PERIOD/MAX_PERIOD` describe **consecutive-edge spacing**, not the complete period of `clk_mon`.
