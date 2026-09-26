# VERILOG DELAY MODELING

=================================

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This example demonstrates different types of **delay modeling in Verilog**, rather than implementing a complex functional circuit.

The module compares:

* Gate delay
* Minimum/typical/maximum delay
* Rise/fall delay
* Continuous-assignment delay
* Procedural delay
* Intra-assignment delay

The basic logic being modeled is:

```text
out = p OR q
```

The main purpose is to understand how different Verilog delay specifications affect **when an output changes during simulation**.

These constructs are primarily useful for:

* Gate-level simulation
* Timing-model understanding
* Cell/library modeling
* Propagation-delay analysis
* Learning Verilog simulation semantics

---

# 2. GATE DELAY

Your first statement is:

```verilog
or #3 (out_gate_delay, p, q);
```

This is a **primitive gate with a 3-time-unit propagation delay**.

Conceptually:

```text
p ──┐
    ├── OR ── #3 ──► out_gate_delay
q ──┘
```

If the OR result changes at:

```text
t = 10
```

the output changes approximately at:

```text
t = 13
```

So:

```text
Input change → 3 time units → Output change
```

---

# 3. MINIMUM / TYPICAL / MAXIMUM DELAY

You have:

```verilog
or #(2:3:4) (out_mtm_delay, p, q);
```

This specifies:

```text
Minimum = 2
Typical = 3
Maximum = 4
```

The format is:

```text
(minimum : typical : maximum)
```

This allows a timing model to represent different propagation-delay conditions.

So conceptually:

```text
OR input changes
       │
       ├── 2 → minimum
       ├── 3 → typical
       └── 4 → maximum
```

The simulator uses the appropriate value according to the Verilog delay semantics and simulation configuration.

---

# 4. RISE / FALL DELAY

Your next statement is:

```verilog
or #(2, 4) (out_rf_delay, p, q);
```

Here the two values represent:

```text
Rise delay = 2
Fall delay = 4
```

Therefore:

```text
Output 0 → 1 : 2 time units
Output 1 → 0 : 4 time units
```

This is useful when a real circuit does not have identical rising and falling propagation delays.

For example:

```text
             Rise
0 ───────────────► 1
      delay = 2

             Fall
1 ───────────────► 0
      delay = 4
```

---

# 5. CONTINUOUS-ASSIGNMENT DELAY

You have:

```verilog
assign #2 out_netd_delay = (p | q);
```

This is a **net/continuous-assignment delay**.

The OR operation is evaluated continuously, and a change in the resulting expression is delayed by 2 time units before appearing at the output.

Conceptually:

```text
p ──┐
    ├── OR ── #2 ──► out_netd_delay
q ──┘
```

This differs from the primitive gate examples because the delay is attached to a **continuous assignment** rather than an instantiated gate primitive.

---

# 6. PROCEDURAL DELAY

Your code contains:

```verilog
always @(*) begin
    #3 out_reg_delay = p | q;
end
```

This is a **procedural delay**.

Whenever `p` or `q` changes, the `always @(*)` block executes:

```text
Evaluate p | q
       ↓
Wait 3 time units
       ↓
Assign out_reg_delay
```

So it models a 3-time-unit delay inside a procedural block.

### Important distinction

This is different from:

```verilog
assign #3 out = p | q;
```

because the former introduces a delay in **procedural execution**, while the latter models a delay on a continuous assignment.

Also, `out_reg_delay` is declared as a `reg` because it is assigned procedurally.

---

# 7. INTRA-ASSIGNMENT DELAY

Inside the `initial` block:

```verilog
a <= #5 b;
```

This is an **intra-assignment delay**.

The important sequence is:

```text
Evaluate RHS b
       ↓
Store/schedule that value
       ↓
Wait 5 time units
       ↓
Update a
```

For example, if:

```text
b = 10
```

when the statement executes, the value `10` is captured for the delayed assignment.

It is different from:

```verilog
#5 a <= b;
```

which means:

```text
Wait 5
  ↓
Evaluate b
  ↓
Schedule a
```

### Easy way to remember

```text
#5 a <= b;       → WAIT → EVALUATE → ASSIGN

a <= #5 b;       → EVALUATE → WAIT → ASSIGN
```

---

# 8. THE `initial` BLOCK

The module also contains:

```verilog
initial begin
    $monitor($time, " a=%0d, b=%0d, c=%0d",a, b, c);

    b <= 10;

    #6 a <= 5;

    a <= #5 b;

    #15 c <= 12;

    #100 $finish;
end
```

Let's trace it.

### At t = 0

```verilog
b <= 10;
```

Because this is a non-blocking assignment without delay:

```text
b → 10
```

at the appropriate NBA update.

---

### At t = 6

```verilog
a <= 5;
```

So:

```text
t = 6 → a becomes 5
```

Then immediately:

```verilog
a <= #5 b;
```

The current value of `b` is evaluated and scheduled for `a` after 5 time units.

Therefore:

```text
t = 6  → evaluate b = 10
t = 11 → a becomes 10
```

So the delayed assignment eventually overwrites the value assigned by:

```verilog
a <= 5;
```

---

### Then:

```verilog
#15 c <= 12;
```

This occurs 15 time units after the previous statement completes.

Approximately:

```text
t = 26 → c = 12
```

---

# 9. TESTBENCH CLOCK-LIKE SIGNALS

Your testbench generates two independent signals.

For `p`:

```verilog
always #5 p = ~p;
```

So:

```text
Period = 10 ns
Frequency = 100 MHz
```

For `q`:

```verilog
always #7 q = ~q;
```

So:

```text
Period = 14 ns
Frequency ≈ 71.43 MHz
```

They are **not actually clocks used by the DUT**; they are simply periodically changing stimulus signals.

---

# 10. TESTBENCH STIMULUS

The initial block also contains:

```verilog
p = 0;
q = 0;

#10 p = 1;
#20 q = 1;
#30 p = 0;
#40 q = 0;
#50 $finish;
```

There is an important issue here.

At the same time, you already have:

```verilog
always #5 p = ~p;
always #7 q = ~q;
```

So `p` and `q` are being driven by **two different procedural blocks**:

```text
always #5 → drives p
initial    → also drives p

always #7 → drives q
initial    → also drives q
```

This creates **multiple procedural drivers on variables**, which is not a good testbench structure and can make the waveform difficult to interpret.

For a clean timing experiment, use either the periodic generators or the explicit stimulus, not both for the same signal.

---

# 11. MONITORING

The testbench uses:

```verilog
always @(posedge p or posedge q)
```

This triggers whenever either `p` or `q` changes from `0 → 1`.

It then prints:

```text
a
b
c
out_gate_delay
out_mtm_delay
out_rf_delay
out_netd_delay
out_reg_delay
```

This allows you to compare the various delayed outputs.

However, because the outputs intentionally change **after** the input event, printing immediately at `posedge p/q` may show the output values **before their respective delays have expired**.

For timing analysis, waveform viewing is generally more informative.

---

# 12. COMPARISON OF ALL DELAYS

| Construct        | Code             | Meaning                            |
| ---------------- | ---------------- | ---------------------------------- |
| Gate delay       | `or #3 (...)`    | 3-unit gate propagation delay      |
| Min/typ/max      | `or #(2:3:4)`    | 2/3/4-unit timing model            |
| Rise/fall        | `or #(2,4)`      | 2-unit rise, 4-unit fall           |
| Net delay        | `assign #2 ...`  | 2-unit continuous-assignment delay |
| Procedural       | `#3 out = ...`   | 3-unit procedural delay            |
| Intra-assignment | `out <= #5 expr` | Evaluate now, assign after 5       |

---

# 13. IMPORTANT SYNTHESIS POINT

These explicit delays such as:

```verilog
#3
#2
#5
```

are primarily **simulation/timing-model constructs**.

They generally do not represent physical delay in ordinary synthesizable RTL.

For example:

```verilog
assign #2 out = p | q;
```

should not be interpreted as "make the hardware exactly 2 ns slower."

Actual physical delay is determined by:

* Cell implementation
* Technology/library
* Routing
* Load
* Placement
* Process/voltage/temperature conditions

Therefore, these constructs are especially useful for understanding **simulation timing and gate-level timing models**, rather than RTL hardware timing implementation.

---

# 14. INTERVIEW TAKEAWAY

The most important concepts from this example are:

```text
Gate delay
    ↓
or #3 (...)

Min/Typical/Max
    ↓
or #(2:3:4) (...)

Rise/Fall
    ↓
or #(2,4) (...)

Continuous assignment delay
    ↓
assign #2 ...

Procedural delay
    ↓
#3 out = ...

Intra-assignment delay
    ↓
out <= #5 expression
```

### Most important distinction

```text
Inter-assignment:
#5 a <= b;

WAIT → evaluate b → assign a


Intra-assignment:
a <= #5 b;

evaluate b → WAIT → assign a
```

This example is therefore mainly about **Verilog timing semantics and delay modeling**, not about designing a particular functional datapath.
