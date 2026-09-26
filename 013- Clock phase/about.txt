# 4-PHASE CLOCK GENERATOR

=================================

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This RTL generates four clock-phase signals:

```text
clk_0
clk_90
clk_180
clk_270
```

from a single input clock `clk`.

The intended phases are:

```text
clk_0   → 0°
clk_90  → 90°
clk_180 → 180°
clk_270 → 270°
```

The design uses:

* A 2-bit counter-like state register `count`
* A divide-by-2 register `div_2`
* XOR/inverter logic to derive the four outputs

Conceptually:

```text
                 ┌─────────────┐
clk ────────────►│ 2-bit state │──► clk_0
                 │   count     │
                 └─────────────┘
                        │
                        ├──────────────► clk_180
                        │
                 ┌──────▼──────┐
clk ────────────►│   div_2     │
                 └──────┬──────┘
                        │
                     XOR logic
                        │
                  ┌─────┴─────┐
                  ▼           ▼
               clk_90      clk_270
```

Potential applications include:

* Multi-phase clocking concepts
* Clock distribution studies
* Timing/control circuits
* Digital communication systems
* Understanding clock division and phase relationships

---

# 2. COUNTER OPERATION

The first sequential block is:

```verilog
always @(posedge clk or negedge rst)
```

So:

* `posedge clk` → state updates
* `negedge rst` → asynchronous reset

Reset is active-low:

```verilog
if(~rst)
    count <= 0;
```

The counter update is:

```verilog
count <= {~count[0], count[1]};
```

If:

```text
count = {count[1], count[0]}
```

then after the clock:

```text
new count[1] = ~old count[0]
new count[0] = old count[1]
```

Starting from:

```text
00
```

the sequence becomes:

```text
00 → 10 → 11 → 01 → 00 → ...
```

So it cycles through four states.

---

# 3. DIVIDE-BY-2 REGISTER

The second sequential block is:

```verilog
always @(posedge clk or negedge rst) begin
    if (~rst)
        div_2 <= 0;
    else
        div_2 <= ~div_2;
end
```

Every rising edge toggles `div_2`.

Therefore:

```text
clk edge     div_2
-------------------
reset        0
1            1
2            0
3            1
4            0
...
```

This creates a signal that changes state once every clock edge and therefore has half the frequency of the input clock.

---

# 4. OUTPUT GENERATION

### `clk_0`

```verilog
assign clk_0 = count[1];
```

So:

```text
clk_0 = count[1]
```

---

### `clk_180`

```verilog
assign clk_180 = ~count[1];
```

Therefore:

```text
clk_180 = ~clk_0
```

So these two outputs are complementary.

```text
clk_0   :  ___----____----...
clk_180 :  ---____----____...
```

---

### `clk_90`

```verilog
assign clk_90 = count[1] ^ div_2;
```

The XOR combines the two internal signals.

---

### `clk_270`

```verilog
assign clk_270 = ~clk_90;
```

Therefore:

```text
clk_270 = ~clk_90
```

So `clk_90` and `clk_270` are also complementary.

---

# 5. STATE TABLE

After reset:

```text
count = 00
div_2 = 0
```

Then the internal states evolve as:

| Clock edge | count | div_2 |
| ---------: | :---: | :---: |
|      Reset |   00  |   0   |
|          1 |   10  |   1   |
|          2 |   11  |   0   |
|          3 |   01  |   1   |
|          4 |   00  |   0   |
|          5 |   10  |   1   |

For example, after the first edge:

```text
count[1] = 1
div_2    = 1
```

Therefore:

```text
clk_0   = 1
clk_90  = 1 ^ 1 = 0
clk_180 = 0
clk_270 = 1
```

---

# 6. TESTBENCH

The testbench instantiates:

```verilog
clk_phase uut (
    .clk(clk),
    .rst(rst),
    .clk_0(clk_0),
    .clk_90(clk_90),
    .clk_180(clk_180),
    .clk_270(clk_270)
);
```

It generates the clock using:

```verilog
forever #0.625 clk = ~clk;
```

Therefore:

```text
Half period = 0.625 ns
Full period = 1.25 ns
Frequency   = 800 MHz
```

So this is a very fast simulated clock.

---

# 7. RESET GENERATION

The testbench uses:

```verilog
rst = 0;
#20 rst = 1;
```

Therefore:

```text
t = 0 ns → rst = 0
t = 20 ns → rst = 1
```

Since the DUT uses:

```verilog
negedge rst
```

the reset is **asynchronous active-low**.

At the beginning, `rst=0`, so the internal registers are held/reset to zero.

Once `rst` becomes `1`, normal operation begins on the next positive edge of `clk`.

---

# 8. WHY `fork...join` IS USED

The testbench has:

```verilog
fork
    begin
        clk = 0;
        forever #0.625 clk = ~clk;
    end

    begin
        rst = 0;
        #20 rst = 1;
    end
join
```

`fork` starts the two blocks **in parallel**.

Therefore:

```text
Process 1 → continuously generates clock
Process 2 → controls reset
```

This is useful because the clock and reset need to operate independently.

### Important point

The `forever` clock process never terminates, so the `join` statement itself never completes. There is also no `$finish` in this testbench.

Therefore, the simulation will continue indefinitely unless you manually stop it or specify a simulation run time.

For example:

```text
run 100ns
```

in Vivado/XSim will simulate the first 100 ns.

---

# 9. IMPORTANT TECHNICAL LIMITATION

There is a significant distinction between this RTL and a **true 4-phase clock generator with 0°, 90°, 180°, and 270° phase-shifted clocks**.

The code generates four related signals using synchronous state and combinational logic, but it does **not inherently guarantee four clocks separated by exactly 90° in physical time**.

For a real 90° phase shift, especially at high frequency, designs commonly use dedicated clock-generation circuitry such as:

```text
PLL / MMCM / DLL
```

depending on the target technology.

Therefore, this RTL is best understood as a **digital demonstration of multi-phase clock/state generation**, rather than a physically accurate clock-management circuit.

Also, using ordinary combinational logic to generate clocks can introduce glitches/skew and is generally not preferred for production clock distribution.

---

# 10. ADVANTAGES & LIMITATIONS

### Advantages

* Simple RTL implementation.
* Generates four related phase/state signals.
* Uses only flip-flops, XOR and inverter logic.
* Active-low asynchronous reset.
* Useful for learning clock division and phase relationships.

### Limitations

* Not a true physical 90° clock generator.
* Combinational logic is used to form clock-like outputs.
* Clock skew and glitches can be problematic in real hardware.
* Dedicated clock-management resources are preferable for actual multi-phase clocks.
* Testbench has no `$finish` or automatic checking.

---

# 11. INTERVIEW TAKEAWAY

**Question: How are the four outputs generated?**

> A 2-bit state register and a divide-by-2 register are updated on every rising edge of the input clock. The outputs are then formed using direct, complementary, and XOR-based combinational logic.

### Core equations

```text
clk_0   = count[1]

clk_180 = ~count[1]

clk_90  = count[1] ^ div_2

clk_270 = ~clk_90
```

### Key concepts

```text
2-bit state machine
       ↓
00 → 10 → 11 → 01 → 00
       ↓
Clock-related output phases
```

The most important interview caveat is: **RTL-generated clock-like signals are not equivalent to true phase-shifted clocks from a PLL/MMCM/DLL.** For production clocking, dedicated clock-generation and clock-distribution resources are normally used.
