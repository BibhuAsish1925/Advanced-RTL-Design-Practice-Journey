# FREQUENCY DIVIDER BY 2 — RTL & TESTBENCH ANALYSIS

## 1. Circuit Overview & Applications

This design implements a **divide-by-2 frequency divider** using a D flip-flop.

The key idea is:

$$
D=\overline{Q}
$$

Therefore, on every active clock edge, the flip-flop toggles its output:

```text
Q: 0 → 1 → 0 → 1 → ...
```

So the output frequency becomes:

$$
f_Q=\frac{f_{clk}}{2}
$$

### Applications

* Clock/frequency division
* Clock-generation circuits
* Counters
* Timing circuits
* Digital clock-management structures
* Basic sequential-logic design

---

# 2. Circuit Working & RTL Implementation

## D Flip-Flop

The first module is:

```verilog
module d_ff(
    input in,
    input clk,
    input rst,
    output reg q,
    output qbar
);
```

It has:

* `in` → D input
* `clk` → clock
* `rst` → active-high reset
* `q` → flip-flop output
* `qbar` → inverted output

The complement output is generated using:

```verilog
assign qbar = ~q;
```

So:

```text
q = 0 → qbar = 1
q = 1 → qbar = 0
```

### Sequential operation

```verilog
always @(posedge clk, posedge rst)
begin
    if(rst)
        q <= 0;
    else
        q <= in;
end
```

This describes a **positive-edge-triggered D flip-flop with asynchronous active-high reset**.

The sensitivity list contains:

```text
posedge clk
posedge rst
```

Therefore, reset does not have to wait for a clock edge.

---

# 3. How Divide-by-2 Works

The second module instantiates the D flip-flop:

```verilog
d_ff d1(t,clk,reset,q,qn);
```

The connections are:

```text
d_ff input `in` → t
d_ff clock      → clk
d_ff reset      → reset
d_ff Q          → q
d_ff Qbar       → qn
```

Then:

```verilog
assign t = qn;
```

Therefore:

$$
D=Q_n=\overline{Q}
$$

The complete feedback structure is:

```text
             ┌──────────────┐
        t ──►│      D       │
             │     D-FF     │───► Q
       clk ─►│    clk       │
             │              │───► QN
             └──────▲───────┘
                    │
                    └── QN → D
```

### State sequence

Assume reset makes:

```text
Q = 0
QN = 1
```

After the first rising clock edge:

```text
D = QN = 1
Q → 1
QN → 0
```

After the second rising edge:

```text
D = QN = 0
Q → 0
QN → 1
```

So:

```text
Clock edge:  1   2   3   4   5   6
Q:           1   0   1   0   1   0
```

Hence Q toggles once for every two clock cycles.

---

# 4. Testbench Analysis

The testbench creates:

```verilog
clk = 0;
reset = 1;
```

Initially, reset is asserted.

After:

```verilog
#10;
reset = 0;
```

reset is released at 10 ns.

### Clock generation

```verilog
always
begin
    #20;
    clk = ~clk;
end
```

The clock toggles every 20 ns.

Therefore:

```text
Half-period = 20 ns
Clock period = 40 ns
```

So the simulated input clock frequency is:

$$
f_{clk}=\frac{1}{40ns}=25MHz
$$

The expected divide-by-2 output frequency is:

$$
f_Q=\frac{25MHz}{2}=12.5MHz
$$

The Q waveform should therefore look approximately like:

```text
clk:  _|‾‾|__|‾‾|__|‾‾|_
Q:    ____|‾‾‾‾|____|‾‾‾‾
```

with Q changing state only at the positive clock edges.

---

# 5. Important Testbench Limitation

Your testbench **does not contain `$finish`**.

Therefore, this:

```verilog
always
begin
    #20;
    clk = ~clk;
end
```

continues forever, and the simulation will keep running unless you manually stop it.

It also does not have:

* `$monitor`
* `$display`
* Expected-value checking
* PASS/FAIL mechanism

So it verifies the circuit mainly by observing the waveform.

For a learning RTL testbench, a better version would include a finite simulation time and automatic checking.

---

# 6. Advantages & Limitations

### Advantages

* Very simple divide-by-2 architecture.
* Uses only one D flip-flop.
* Minimal hardware overhead.
* Asynchronous reset provides immediate initialization.
* `q` and `qn` are complementary outputs.
* Fully synthesizable RTL.

### Limitations

* This architecture only divides frequency by **2**.
* For arbitrary division ratios, a counter or other divider architecture is required.
* The generated `q` is a divided clock, so in larger synchronous designs it should be handled carefully rather than treated like an ordinary data signal.
* The current TB is not self-checking.

---

# 7. Interview Takeaways

**One-line explanation:**

> A D flip-flop can operate as a divide-by-2 frequency divider by feeding its inverted output back to the D input, causing Q to toggle on every rising clock edge.

### Important interview questions

**Q: Why does the frequency divide by 2?**
Because Q changes state once per clock edge, requiring two clock cycles for a complete Q waveform cycle.

**Q: Why connect QN to D?**
Because `D = ~Q` forces the flip-flop to take the opposite state at every rising edge.

**Q: What type of reset is used?**
An **asynchronous active-high reset**, because `posedge rst` is present in the sensitivity list.

**Q: What is the input clock frequency in this TB?**
With a 20 ns half-period:

$$
T=40ns,\quad f=25MHz
$$

and the divided output is:

$$
12.5MHz
$$

**Q: What hardware does this synthesize to?**
Essentially **one D flip-flop with an inverter/feedback path**.
