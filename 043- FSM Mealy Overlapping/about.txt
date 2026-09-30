# 11001 Sequence Detector — RTL + Testbench Analysis

## 1. Circuit Overview & Applications

This design is a **synchronous FSM-based sequence detector** that detects the serial bit pattern **`11001`** in the input `din`.

* **Input:** `din` — serial data stream
* **Clock:** `clk`
* **Reset:** synchronous active-high `reset`
* **Output:** `y` — becomes `1` when `11001` is detected
* **FSM:** 5 states (`S0`–`S4`)
* **Detection type:** **overlapping sequence detector**

The five states represent how much of `11001` has currently been matched.

### Applications

* Serial pattern detection
* Communication protocol monitoring
* Packet/frame header detection
* Digital control logic
* Error/signature detection
* RTL/FSM design practice

---

# 2. Circuit Working & FSM Implementation

The FSM tracks the incoming bits progressively:

```text
S0 --1--> S1 --1--> S2 --0--> S3 --0--> S4 --1--> DETECT
```

More precisely, `S4` represents that the previous four relevant bits are `1100`. When the next input is `1`, the complete sequence `11001` has been received.

### State meaning

| State | Meaning         |
| ----- | --------------- |
| `S0`  | No useful match |
| `S1`  | `1` detected    |
| `S2`  | `11` detected   |
| `S3`  | `110` detected  |
| `S4`  | `1100` detected |

The important transitions are:

```text
S0 + 1 → S1
S1 + 1 → S2
S2 + 0 → S3
S3 + 0 → S4
S4 + 1 → S1, y=1
```

Notice the transition:

```text
S4 + 1 → S1
```

rather than returning to `S0`.

This allows the FSM to retain the final `1` as the beginning of another possible `11001` sequence. Therefore, the implementation supports **overlapping detection**.

---

## 3. RTL Structure

The RTL has two main parts.

### A. State register

```verilog
always @(posedge clk)
begin
    if(reset)
        cst <= S0;
    else
        cst <= nst;
end
```

This is the sequential portion of the FSM.

* State changes only on the rising edge of `clk`.
* `reset` is **synchronous**, because it is not present in the sensitivity list.
* Reset forces the FSM to `S0`.

### B. Next-state and output logic

```verilog
always @(cst or din)
```

This block determines:

1. The next state `nst`
2. Detection output `y`

For example:

```verilog
S3: if(din==1'b1)
begin
    nst<=S1;
    y<=1'b0;
end
else
begin
    nst<=S4;
    y<=1'b0;
end
```

If the FSM has already detected `110`:

* Input `0` → `1100` → `S4`
* Input `1` → the current matching path is changed to `S1`

---

## 4. Detection Operation

For the intended sequence:

```text
Input:  1  1  0  0  1
        ↓  ↓  ↓  ↓  ↓
State: S0 S1 S2 S3 S4
                 ↓
                y=1
```

The output `y` is asserted when:

```text
Current state = S4
din = 1
```

Therefore, `y` is a **combinational Moore/Mealy-style output based on current state and input**. More precisely, because `y` depends directly on `din` inside the state/output combinational block, this is a **Mealy FSM**.

The detection pulse occurs during the cycle in which the final `1` is applied.

---

# 5. Testbench Analysis

Your testbench generates:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

Reset:

```verilog
reset = 1'b1;
#10 reset = 1'b0;
```

So reset is active for the first `10 ns`.

The testbench then applies a sequence of input bits every `10 ns`.

The intended input stream is approximately:

```text
0 1 1 0 0 1 1 0 0 1 0 1 1 0 0 1
```

There are multiple opportunities to detect `11001`.

The monitor:

```verilog
$monitor("\t\t clock: %d  input: %d   detect: %d",clk, din, y);
```

continuously displays:

```text
clock
input
detect
```

So this testbench is primarily an **observational testbench**, rather than a self-checking verification environment.

---

# 6. Important RTL Issues

There are a few things I would improve in this implementation.

### 1. `y` is not assigned in the `default` case

You have:

```verilog
default: nst<=S0;
```

but `y` is not assigned.

This can result in `y` retaining its previous value if an illegal state occurs.

A safer version is:

```verilog
default: begin
    nst = S0;
    y = 1'b0;
end
```

### 2. Use blocking assignments in combinational logic

The current combinational block uses:

```verilog
nst <= ...
y   <= ...
```

For combinational next-state/output logic, conventional Verilog style is:

```verilog
nst = ...
y   = ...
```

Nonblocking assignments are normally reserved for sequential logic.

### 3. Give default assignments

A cleaner FSM style is:

```verilog
always @(*) begin
    nst = S0;
    y   = 1'b0;

    case(cst)
       ...
    endcase
end
```

This makes the combinational behavior complete and avoids inferred latches.

### 4. Testbench `din` starts as `X`

You don't initialize `din` immediately:

```verilog
reset=1'b1;
#10 reset=1'b0;
#5 din=1'b0;
```

Therefore `din` is `X` from `0` to `15 ns`.

Better:

```verilog
reset = 1'b1;
din   = 1'b0;
```

at the beginning.

---

# 7. Advantages & Limitations

### Advantages

* Simple FSM architecture
* Synthesizable RTL
* Only five states required
* Low hardware complexity
* Supports overlapping detection
* Easy to modify for other bit patterns

### Limitations

* Detects only one fixed pattern: `11001`
* Input width is fixed to one bit
* FSM is not parameterized
* Testbench does not automatically verify expected detections
* Current combinational block has incomplete/default-assignment issues
* Detection behavior depends on synchronous sampling of `din`

---

# 8. Interview Takeaways

**One-line explanation:**

> “This is a five-state Mealy FSM that detects the serial pattern `11001` and supports overlapping sequence detection.”

### Likely interview questions

**Q1. Why are five states required?**
Because the FSM tracks the matching progress from no match through `1`, `11`, `110`, and `1100`.

**Q2. Is this Moore or Mealy?**
**Mealy**, because `y` depends on both the current state and `din`.

**Q3. Is it overlapping?**
Yes. After detecting `11001`, the FSM goes to `S1`, retaining the final `1` as the beginning of another possible sequence.

**Q4. Is reset synchronous or asynchronous?**
Synchronous active-high reset, because the sensitivity list contains only:

```verilog
posedge clk
```

**Q5. What happens for `S4 + 0`?**

```text
S4 + 0 → S0
```

because `11000` does not provide a useful partial match for the beginning of `11001`.
