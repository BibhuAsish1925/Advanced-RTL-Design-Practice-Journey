# 1011 Sequence Detector — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **5-state Moore FSM sequence detector** for the serial bit pattern **`1011`**.

* `din` → serial input
* `clk` → clock
* `rst` → **asynchronous active-high reset**
* `y` → sequence detection output
* Pattern → `1011`
* Detection type → **overlapping sequence detector**

The FSM progresses through states according to how much of `1011` has been matched.

### Applications

* Serial data pattern detection
* Communication interfaces
* Protocol/header detection
* Digital control circuits
* Error/signature detection
* FSM/RTL design practice

---

# 2. State Representation

The five states are:

| State | Meaning         |
| ----- | --------------- |
| `S0`  | No useful match |
| `S1`  | `1` detected    |
| `S2`  | `10` detected   |
| `S3`  | `101` detected  |
| `S4`  | `1011` detected |

The main path is:

```text id="n9f6wx"
S0 --1--> S1 --0--> S2 --1--> S3 --1--> S4
                                      |
                                      ↓
                                     y=1
```

Once `S4` is reached, `y` becomes `1`.

---

# 3. FSM Operation

### S0 — No match

```text id="6mxm1x"
din = 0 → S0
din = 1 → S1
```

A `1` can begin the desired sequence.

### S1 — Received `1`

```text id="pyw50v"
din = 0 → S2
din = 1 → S1
```

If another `1` arrives, the latest `1` can still be the beginning of `1011`.

### S2 — Received `10`

```text id="x6a1pf"
din = 1 → S3
din = 0 → S0
```

### S3 — Received `101`

```text id="i0k8oc"
din = 1 → S4
din = 0 → S2
```

The `1` completes `1011`.

### S4 — Received `1011`

```text id="y8c0cb"
din = 1 → S1
din = 0 → S2
```

The transitions preserve possible partial matches, allowing overlapping sequences.

---

# 4. Why This Is a Moore FSM

Your output logic is:

```verilog id="v6q0bj"
always @(cs)
begin
    case(cs)
        S0: y<=0;
        S1: y<=0;
        S2: y<=0;
        S3: y<=0;
        S4: y<=1;
        default: y<=0;
    endcase
end
```

`y` depends **only on the current state**, not directly on `din`.

Therefore this is a **Moore FSM**.

```text id="m3qj7d"
cs = S4 → y = 1
cs ≠ S4 → y = 0
```

This differs from your previous `11001` detector, where `y` was generated using both state and input and therefore behaved as a Mealy FSM.

---

# 5. State Register

```verilog id="r0s7t8"
always @(posedge clk, posedge rst)
begin
    if(rst)
        cs <= S0;
    else
        cs <= nst;
end
```

The sensitivity list contains:

```text id="w0s7kg"
posedge clk
posedge rst
```

Therefore `rst` is an **asynchronous active-high reset**.

Reset can force the FSM to `S0` without waiting for a clock edge.

---

# 6. Next-State Logic

The second `always` block implements the transition table:

```verilog id="z0i3d6"
always @(cs,din)
```

Conceptually:

```text id="k9t2ax"
Current State    din=0    din=1
--------------------------------
S0                S0       S1
S1                S2       S1
S2                S0       S3
S3                S2       S4
S4                S2       S1
```

This table is a useful way to remember the entire FSM for an interview.

---

# 7. Sequence Detection Example

For:

```text id="0h14x8"
din = 1 0 1 1
```

the FSM progresses:

```text id="0n9t5r"
Input:    1    0    1    1
          ↓    ↓    ↓    ↓
State:   S0   S1   S2   S3
               ↓    ↓    ↓
Next:    S1   S2   S3   S4

                       ↓
                      y=1
```

So when `S4` is reached:

```text id="qzqg8c"
y = 1
```

Because this is a Moore FSM, the output becomes associated with the state representing the completed sequence.

---

# 8. Testbench Analysis

Your clock generation is:

```verilog id="f8n2li"
always #5 clk = ~clk;
```

Therefore:

```text id="v0i0j4"
Clock period = 10 ns
Clock frequency = 100 MHz
```

Reset:

```verilog id="x2g1kl"
reset = 1'b1;
#10 reset = 1'b0;
```

Because reset is asynchronous, it immediately places the FSM in `S0`.

The input is then applied every `10 ns`.

The testbench contains multiple occurrences of:

```text id="q4y8yb"
1011
```

so it provides opportunities to observe the detector asserting `y`.

The monitor:

```verilog id="k2y4zo"
$monitor("\t\t clock: %d  input: %d   detect: %d",clk, din, y);
```

continuously displays the clock, input, and detection output.

---

# 9. Important RTL Issues

The basic FSM architecture is correct, but there are some style improvements worth making.

### 1. Use blocking assignments in combinational blocks

Currently:

```verilog id="2d4p1b"
nst <= S1;
```

and:

```verilog id="j4p8ms"
y <= 1;
```

are nonblocking assignments.

For combinational logic, conventional RTL style is:

```verilog id="z1f3j8"
nst = S1;
y   = 1'b1;
```

Keep `<=` for the clocked state register.

---

### 2. Add default assignments

Instead of relying entirely on every case branch, a safer structure is:

```verilog id="v8p5d2"
always @(*) begin
    nst = S0;

    case(cs)
        ...
    endcase
end
```

Likewise:

```verilog id="p7x8k2"
always @(*) begin
    y = 1'b0;

    case(cs)
        S4: y = 1'b1;
    endcase
end
```

This prevents unintended latch behavior and makes the combinational intent explicit.

---

### 3. Testbench `din` is initially unknown

You have:

```verilog id="h4q1zp"
reset = 1'b1;
#10 reset = 1'b0;
#5 din = 1'b0;
```

So `din` is `X` during the initial 15 ns.

Better initialize it:

```verilog id="1c6y5j"
reset = 1'b1;
din   = 1'b0;
```

---

### 4. Testbench is observational

The testbench uses `$monitor`, but doesn't automatically compare the actual output with an expected output.

A stronger verification testbench would explicitly check:

```text id="1y1kq8"
Expected y = 1 when 1011 is detected
Expected y = 0 otherwise
```

---

# 10. Advantages & Limitations

### Advantages

* Simple 5-state implementation
* Synthesizable
* Clear state progression
* Moore output is independent of instantaneous input
* Supports overlapping patterns
* Easy to modify for other sequences

### Limitations

* Fixed `1011` pattern
* Fixed 5-state architecture
* No parameterization
* Current combinational blocks use nonblocking assignments
* Testbench does not automatically verify correctness
* Output detection occurs through a state transition, so it has Moore-FSM timing characteristics

---

# 11. Interview Takeaways

**One-line explanation:**

> This is a 5-state Moore FSM that detects the serial sequence `1011` using an asynchronous active-high reset and supports overlapping pattern tracking.

### Key interview questions

**Q1. Why is this a Moore FSM?**
Because `y` depends only on `cs`; `y=1` only when `cs=S4`.

**Q2. What type of reset is used?**
Asynchronous active-high reset:

```verilog
@(posedge clk, posedge rst)
```

**Q3. What is the clock frequency?**

```text
T = 10 ns
f = 100 MHz
```

**Q4. What does `S3` represent?**
The FSM has received `101`.

**Q5. Why does `S1 + 1` return to `S1`?**
Because after receiving consecutive `1`s, the most recent `1` can still serve as the beginning of a new `1011` sequence.

**Q6. Why does `S4 + 0` go to `S2`?**
After `10110`, the trailing `10` can be retained as a partial match toward another `1011`.

**Q7. How is this different from the previous `11001` detector?**
The previous detector generated `y` directly from **state + input**, making it Mealy-style. This `1011` detector generates `y` from **state only**, making it Moore-style.
