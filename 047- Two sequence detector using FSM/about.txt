# `101_0110` Sequence Detector — Circuit Analysis

## 1. Circuit Overview & Applications

This RTL implements a **sequence detector for the patterns `101` and `0110`** using a **6-state FSM**.

* **Input:** `din` — serial input bit
* **Clock:** `clk`
* **Reset:** `reset` — synchronous active-high
* **Output:** `y` — detection output
* **States:** `S0`–`S5`
* **Clock:** 100 MHz in the testbench

The FSM shares states between the two target sequences, allowing both patterns to be detected using the same state machine.

### Applications

* Serial pattern detection
* Communication/protocol monitoring
* Digital control logic
* Header/signature detection
* RTL/FSM design practice

---

# 2. What the States Represent

The state transitions can be understood as tracking partial matches.

| State | Partial sequence represented |
| ----- | ---------------------------- |
| `S0`  | Initial/no useful match      |
| `S1`  | `1`                          |
| `S2`  | `0`                          |
| `S3`  | `01`                         |
| `S4`  | `101`                        |
| `S5`  | `1011`                       |

The two target patterns are:

```text
101
0110
```

The important paths are:

```text id="0j8l1b"
For 101:

S0 --1--> S1 --0--> S3 --1--> S4
                                  |
                                  y=1
```

and:

```text id="3axgk2"
For 0110:

S0 --0--> S2 --1--> S4 --1--> S5 --0--> S3
                                  |
                                  y=1
```

However, there is an important point about your actual RTL: **the output is generated on particular transitions rather than simply indicating that the state represents a completed sequence.**

---

# 3. How the RTL Detects the Patterns

### Starting from `S0`

```verilog
S0: if(din==1'b1)
begin
    nst<=S1;
    y<=1'b0;
end
else
begin
    nst<=S2;
    y<=1'b0;
end
```

Therefore:

```text
din=1 → S1
din=0 → S2
```

So the first input bit determines which pattern-matching path is entered.

---

### Detecting `101`

The relevant path is:

```text id="qz7hqp"
S0 → S1 → S3 → S4
```

Specifically:

```text id="j6a2pu"
S0 + 1 → S1
S1 + 0 → S3
S3 + 1 → S4, y=1
```

Therefore, when the input sequence `101` is completed, the RTL asserts:

```text
y = 1
```

---

### Continuing toward `0110`

The relevant progression is:

```text id="x8d5h6t"
S0 → S2 → S4 → S5 → S3
```

with:

```text
0 → 1 → 1 → 0
```

The final transition is:

```verilog id="qwr5g8"
S5: if(din==1'b1)
begin
    nst<=S1;
    y<=1'b0;
end
else
begin
    nst<=S3;
    y<=1'b1;
end
```

Thus:

```text id="i3j5ip"
S5 + 0 → S3, y=1
```

corresponds to completion of **`0110`**.

---

# 4. Why This Is a Mealy-Style Detector

Unlike the previous `1011` design, `y` is calculated inside:

```verilog id="x4q8ty"
always @(cst or din)
```

and depends on the current state **and input**.

For example:

```verilog id="z2y0w1"
S3: if(din==1'b1)
begin
    nst<=S4;
    y<=1'b1;
end
```

and:

```verilog id="5r5n9u"
S5: if(din==1'b0)
begin
    nst<=S3;
    y<=1'b1;
end
```

Therefore this is a **Mealy FSM**.

The output is asserted on the same input transition that completes the target pattern.

---

# 5. State Transition Table

A compact representation of your RTL is:

| Current state | `din=0` → next/y | `din=1` → next/y |
| ------------- | ---------------- | ---------------- |
| `S0`          | `S2 / 0`         | `S1 / 0`         |
| `S1`          | `S3 / 0`         | `S1 / 0`         |
| `S2`          | `S2 / 0`         | `S4 / 0`         |
| `S3`          | `S2 / 0`         | `S4 / 1`         |
| `S4`          | `S3 / 0`         | `S5 / 0`         |
| `S5`          | `S3 / 1`         | `S1 / 0`         |

This table is particularly useful for understanding and debugging the design.

---

# 6. State Register

```verilog id="6a0c4p"
always @(posedge clk)
begin
    if(reset)
        cst<=S0;
    else
        cst<=nst;
end
```

The reset is **synchronous active-high** because only `posedge clk` is in the sensitivity list.

```text id="8n9h1s"
reset = 1 → S0
reset = 0 → normal FSM operation
```

---

# 7. Testbench Analysis

The clock:

```verilog id="qf7xnp"
always #5 clk = ~clk;
```

gives:

```text id="5b7e0u"
Tclk = 10 ns
fclk = 100 MHz
```

The testbench applies:

```text id="m5p5zi"
0 1 1 0 1 1 0 0 1 0 1 0 1 1 0
```

This stream contains opportunities for detecting both target patterns.

The monitor:

```verilog id="w3h3w0"
$monitor("\t\t clock: %d  input: %d   detect: %d",clk, din, y);
```

shows the clock, input, and detection output during simulation.

The simulation ends after:

```verilog id="e5q5fa"
#180 $finish;
```

---

# 8. Important RTL Issues

### 1. `y` is not assigned in the `default` case

Your default is:

```verilog id="h0o8v2"
default: nst<=S0;
```

but `y` is not assigned.

If an illegal state occurs, `y` can retain its previous value.

A safer form is:

```verilog id="5h3z2v"
default: begin
    nst = S0;
    y   = 1'b0;
end
```

### 2. Nonblocking assignments in combinational logic

You use:

```verilog id="4y7z8k"
nst <= ...
y   <= ...
```

inside the combinational block.

For conventional combinational RTL, use blocking assignments:

```verilog id="l5h3s8"
nst = ...
y   = ...
```

Keep `<=` for the clocked state register.

### 3. `din` is initially uninitialized

The testbench starts with:

```verilog id="5l3k2j"
reset = 1'b1;
```

but `din` isn't assigned until 15 ns.

Initialize it:

```verilog id="n7v1pm"
reset = 1'b1;
din   = 1'b0;
```

This avoids `X` values at the beginning of simulation.

### 4. Testbench is observational

The `$monitor` shows whether detection occurs, but there is no automatic PASS/FAIL comparison.

For verification practice, a self-checking testbench would be better.

---

# 9. Advantages & Limitations

### Advantages

* Detects two sequences using one FSM
* Six-state implementation
* Synthesizable
* Mealy output gives immediate transition-based detection
* Shared states reduce duplicated detection logic
* Useful for learning multi-pattern sequence detection

### Limitations

* Fixed patterns
* Non-parameterized
* Current combinational coding style can be improved
* No self-checking testbench
* Illegal-state output handling is incomplete

---

# 10. Interview Takeaway

> **This is a 6-state Mealy FSM that detects the serial patterns `101` and `0110`, asserting `y` when either target sequence is completed.**

### Key interview questions

**Q1. Why is this a Mealy FSM?**
Because `y` depends on both the current state and `din`.

**Q2. Where is `101` detected?**

```text id="u7a9tx"
S0 --1--> S1 --0--> S3 --1--> S4
                                  y=1
```

**Q3. Where is `0110` detected?**

```text id="e2k8jh"
S0 --0--> S2 --1--> S4 --1--> S5 --0--> S3
                                             y=1
```

**Q4. What is the clock frequency?**

```text id="j8r7bw"
T = 10 ns
f = 100 MHz
```

**Q5. What type of reset is used?**
Synchronous active-high reset.

**Q6. Why can multiple patterns be detected with fewer states than simply creating two separate FSMs?**
Because common prefixes/partial matches can share states and transitions.
