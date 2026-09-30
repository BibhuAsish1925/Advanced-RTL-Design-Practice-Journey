## 11001 Sequence Detector — Circuit Analysis

### 1. Circuit Overview & Applications

This RTL implements a **5-state Mealy FSM sequence detector** for the serial bit pattern **`11001`**.

* `din` → serial input bit
* `clk` → system clock
* `reset` → synchronous active-high reset
* `y` → detection output
* Pattern detected → `y = 1`
* Supports **overlapping detection**

The FSM stores how much of `11001` has been matched so far.

---

### 2. FSM State Meaning

| State | Matched sequence |
| ----- | ---------------- |
| `S0`  | Nothing matched  |
| `S1`  | `1`              |
| `S2`  | `11`             |
| `S3`  | `110`            |
| `S4`  | `1100`           |

The main detection path is:

```text
S0 --1--> S1 --1--> S2 --0--> S3 --0--> S4 --1--> S1
                                      |
                                      +---- y = 1
```

When the FSM is in `S4` and receives `1`:

```verilog
S4: if(din==1'b1)
begin
    nst <= S1;
    y   <= 1'b1;
end
```

The complete sequence is therefore:

```text
1 → 1 → 0 → 0 → 1
        11001
```

and `y` becomes `1` for that detection.

The transition back to `S1` rather than `S0` is what allows **overlapping sequences** to be detected.

---

## 3. How the RTL Works

### State register

```verilog
always @(posedge clk)
begin
    if(reset)
        cst <= S0;
    else
        cst <= nst;
end
```

This is the sequential part.

At every positive edge:

```text
reset = 1 → cst = S0
reset = 0 → cst = nst
```

Since `reset` is not in the sensitivity list, it is a **synchronous reset**.

---

### Next-state and output logic

```verilog
always @(cst or din)
```

This block examines:

* Current state `cst`
* Current input `din`

and determines:

* Next state `nst`
* Detection output `y`

For example:

```text
S0 + 1 → S1
S0 + 0 → S0

S1 + 1 → S2
S1 + 0 → S0

S2 + 0 → S3
S2 + 1 → S2

S3 + 0 → S4
S3 + 1 → S1

S4 + 1 → S1, y=1
S4 + 0 → S0
```

Because `y` depends on both `cst` and `din`, this is a **Mealy FSM**.

---

## 4. Example Detection

Suppose the input stream contains:

```text
din = 1 1 0 0 1
```

The FSM progresses as:

```text
Input       1    1    0    0    1
            ↓    ↓    ↓    ↓    ↓
State       S0   S1   S2   S3   S4
                 ↓    ↓    ↓    ↓
Next state   S1   S2   S3   S4   S1

y           0    0    0    0    1
```

So the final `1` produces the detection pulse.

---

# 5. Testbench Analysis

Your clock is:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

The testbench initially asserts reset:

```verilog
reset = 1'b1;
#10 reset = 1'b0;
```

So the FSM is reset during the first 10 ns.

The input sequence is then applied at 10 ns intervals.

The testbench uses:

```verilog
$monitor("\t\t clock: %d  input: %d   detect: %d",clk, din, y);
```

so you can observe:

```text
clock
input
detect
```

throughout simulation.

---

# 6. Important Issues in the Current Code

The FSM concept is correct, but there are a few RTL-style issues.

### Issue 1 — `y` is missing from `default`

Currently:

```verilog
default: nst<=S0;
```

If an illegal state occurs, `y` is not assigned.

Better:

```verilog
default: begin
    nst = S0;
    y   = 1'b0;
end
```

### Issue 2 — Nonblocking assignments in combinational logic

Your combinational block uses:

```verilog
nst <= ...
y   <= ...
```

For combinational logic, the conventional style is blocking assignment:

```verilog
nst = ...
y   = ...
```

The sequential state register should retain nonblocking assignment:

```verilog
cst <= nst;
```

### Issue 3 — `din` is initially unknown

Your testbench doesn't initialize `din` until:

```verilog
#5 din = 1'b0;
```

So `din` is `X` initially.

Use:

```verilog
reset = 1'b1;
din   = 1'b0;
```

at the beginning.

### Issue 4 — Testbench is not self-checking

The testbench only displays the result. It does not automatically determine whether `y` is correct.

For a stronger verification environment, you could add expected-output checking.

---

# 7. Advantages & Limitations

### Advantages

* Simple 5-state FSM
* Synthesizable
* Low hardware complexity
* Detects serial `11001`
* Supports overlapping detection
* Easy to modify for another sequence

### Limitations

* Fixed pattern
* Fixed 1-bit input
* No parameterization
* Current testbench is observation-only
* Illegal-state handling should also explicitly clear `y`

---

# 8. Interview Takeaways

**One-line explanation:**

> This is a 5-state Mealy FSM that detects the serial bit sequence `11001` and supports overlapping sequence detection.

### Common interview questions

**Why 5 states?**
To represent the matching progress: `"" → 1 → 11 → 110 → 1100`.

**Why is it Mealy?**
Because `y` depends on both the current state and `din`.

**Is reset synchronous?**
Yes. It is checked only at `posedge clk`.

**Does it support overlapping detection?**
Yes. After detecting `11001`, it transitions to `S1`, preserving the final `1` as a possible start of another sequence.

**What is the clock frequency?**

```text
Tclk = 5 ns + 5 ns = 10 ns
fclk = 1/10 ns = 100 MHz
```

**Main RTL improvement:** use blocking assignments and default assignments in the combinational FSM block, while retaining nonblocking assignments for the state register.
