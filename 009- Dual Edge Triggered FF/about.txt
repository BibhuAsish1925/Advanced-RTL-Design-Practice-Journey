# DUAL-EDGE TRIGGERED FLIP-FLOP

=================================

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This RTL implements a **dual-edge-triggered storage element** that captures input `d` on **both edges of the clock**:

```text
        posedge clk ──> q1
                         │
                         ├──> Q
                         │
        negedge clk ──> q2
                         │
                         └──> Q
```

The key idea is to use **two separate registers**:

* `q1` captures `d` on the **positive edge**
* `q2` captures `d` on the **negative edge**
* A MUX-like selection chooses which register drives `q`

This can approximately provide **two data-capture opportunities per clock cycle**.

Potential applications include:

* Double-data-rate (DDR) data paths
* Clock/data transfer interfaces
* High-throughput datapaths
* Clock-edge-based sampling circuits

---

# 2. HOW THE RTL WORKS

### Positive-edge register

```verilog
always @(posedge clk)
begin
    if(reset)
        q1 <= 1'b0;
    else
        q1 <= d;
end
```

Whenever:

```text
clk: 0 → 1
```

`q1` captures `d`.

---

### Negative-edge register

```verilog
always @(negedge clk)
begin
    if(reset)
        q2 <= 1'b0;
    else
        q2 <= d;
end
```

Whenever:

```text
clk: 1 → 0
```

`q2` captures `d`.

Therefore:

```text
Positive edge → q1 captures D
Negative edge → q2 captures D
```

---

# 3. OUTPUT SELECTION

The important line is:

```verilog
assign q = clk ? q1 : q2;
```

This behaves like a **2:1 MUX**.

When:

```text
clk = 1
```

we get:

```text
q = q1
```

When:

```text
clk = 0
```

we get:

```text
q = q2
```

Therefore the output continuously selects the register corresponding to the current clock level.

### Conceptual operation

```text
             +---------+
 D --------->| posedge |---- q1 ---+
             |   FF    |            |
             +---------+            |
                                    +---- MUX ---- Q
             +---------+            |      ^
 D --------->| negedge |---- q2 ---+       |
             |   FF    |                   |
             +---------+                  CLK
```

---

# 4. RESET OPERATION

Both registers use:

```verilog
if(reset)
    q1 <= 1'b0;
```

and:

```verilog
if(reset)
    q2 <= 1'b0;
```

The reset is **synchronous to the respective clock edge**, because `reset` is not included in the sensitivity lists.

For example:

```verilog
always @(posedge clk)
```

means `q1` responds to reset only when a positive clock edge occurs.

Similarly, `q2` responds to reset only at a negative clock edge.

So this is **not an asynchronous reset**.

---

# 5. TESTBENCH OPERATION

The testbench generates the clock using:

```verilog
forever #9 clk = ~clk;
```

Therefore the clock changes every 9 ns:

```text
t=0   clk=0
t=9   clk=1   ↑ positive edge
t=18  clk=0   ↓ negative edge
t=27  clk=1
t=36  clk=0
...
```

So the complete clock period is:

```text
T = 18 ns
```

and the frequency is approximately:

```text
55.56 MHz
```

---

## Data generation

The testbench uses:

```verilog
forever #6 d = ~d;
```

Therefore `d` changes every 6 ns:

```text
t=0   d=0
t=6   d=1
t=12  d=0
t=18  d=1
t=24  d=0
...
```

This is useful because `d` changes at a different rate from the clock, allowing you to observe whether the DUT captures it at both clock edges.

---

# 6. RESET TIMING

The testbench starts with:

```verilog
rst = 1;
#10;
rst = 0;
```

So reset is asserted from:

```text
t=0 → t=10
```

There is a positive clock edge at:

```text
t=9
```

Therefore at `t=9`, `q1` is reset to `0`.

There is a negative edge at:

```text
t=18
```

but by then:

```text
rst = 0
```

so `q2` captures the current `d` instead of being reset.

### Important observation

Because reset is synchronous, **both registers are not necessarily reset at the same time** in this testbench.

This is an important simulation/RTL point.

---

# 7. TESTBENCH MONITOR

The testbench contains:

```verilog
$monitor("\t\t\t clk: %d  D: %d  Q: %d", clk, d, Q);
```

`$monitor` prints whenever any monitored signal changes.

You can therefore observe:

```text
clk
D
Q
```

throughout the simulation.

The simulation terminates at:

```verilog
#80 $finish;
```

so the total simulation time is 80 ns.

---

# 8. IMPORTANT RTL CONSIDERATION

This design demonstrates the **concept** of dual-edge triggering, but it is important to distinguish that from a dedicated hardware **dual-edge-triggered flip-flop**.

The RTL actually describes:

```text
1 positive-edge FF
+
1 negative-edge FF
+
1 clock-controlled output MUX
```

rather than necessarily mapping to a single physical DET flip-flop.

For ASIC implementation, the synthesis flow may transform this structure depending on the standard-cell library and available cells.

For FPGA implementation, using both edges of a clock this way can be problematic because FPGA fabric generally prefers dedicated clocking resources and dedicated edge-triggered flip-flops.

---

# 9. ADVANTAGES & LIMITATIONS

### Advantages

* Captures data on both clock edges.
* Can increase effective data-transfer opportunities.
* Simple RTL structure.
* Useful for understanding DDR concepts.
* Fully synthesizable in principle, subject to target technology.

### Limitations

* Uses two storage elements instead of one.
* Output MUX introduces additional logic.
* Clock is used as a data-path control signal.
* FPGA synthesis may not map this efficiently.
* Reset behavior requires careful consideration.
* Timing analysis is more complicated than a conventional single-edge FF.

---

# 10. INTERVIEW TAKEAWAY

**Question: How does this design achieve dual-edge operation?**

> It uses two registers, one triggered by the positive edge and one by the negative edge of the clock. A clock-controlled MUX selects the appropriate register output, allowing the circuit to capture data on both clock edges.

### Core architecture

```text
             POSITIVE EDGE
D ───────────────► q1 ──┐
                         ├──► Q
D ───────────────► q2 ──┘
             NEGATIVE EDGE
                    ↑
                    │
                   CLK
```

### Key point

```text
posedge → q1 captures D
negedge → q2 captures D
CLK=1   → Q=q1
CLK=0   → Q=q2
```

This is a good RTL example for understanding **dual-edge data capture, DDR concepts, multiple-edge sensitivity, and clock-controlled output selection**.
