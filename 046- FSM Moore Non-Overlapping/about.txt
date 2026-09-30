# 1011 Sequence Detector — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **5-state Moore FSM** that detects the serial bit pattern **`1011`**.

* **Input:** `din`
* **Clock:** `clk`
* **Reset:** synchronous active-high `rst`
* **Output:** `y`
* **FSM states:** `S0`–`S4`
* **Detection:** `y = 1` when the FSM reaches `S4`
* **Clock frequency:** 100 MHz from the testbench

The circuit is useful for serial pattern detection in communication/control logic, protocol monitoring, and RTL FSM design.

---

## 2. FSM Working

Each state represents the portion of `1011` that has already been received:

| State | Meaning         |
| ----- | --------------- |
| `S0`  | No match        |
| `S1`  | `1` received    |
| `S2`  | `10` received   |
| `S3`  | `101` received  |
| `S4`  | `1011` received |

The main sequence is:

```text
S0 --1--> S1 --0--> S2 --1--> S3 --1--> S4
                                             |
                                             v
                                           y = 1
```

The complete transition table is:

| Current State | `din=0` | `din=1` |
| ------------- | ------- | ------- |
| `S0`          | S0      | S1      |
| `S1`          | S2      | S1      |
| `S2`          | S0      | S3      |
| `S3`          | S2      | S4      |
| `S4`          | S2      | S1      |

The transitions from `S4` preserve useful partial matches, so the FSM can detect overlapping occurrences.

---

## 3. RTL Implementation

### State register

```verilog
always @(posedge clk)
begin
    if(rst)
        cs <= S0;
    else
        cs <= nst;
end
```

Here, `rst` is checked only on `posedge clk`, so **the reset is synchronous active-high**, despite the signal being named `rst`.

The operation is:

```text
rst = 1 → cs = S0
rst = 0 → cs = nst
```

### Next-state logic

```verilog
always @(cs,din)
```

This block determines `nst` based on the current state and input.

For example:

```text
S2 + 1 → S3
```

means that after receiving `10`, another `1` gives `101`.

Then:

```text
S3 + 1 → S4
```

completes `1011`.

### Output logic

```verilog
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

The output depends **only on the current state**:

```text
S4 → y=1
all other states → y=0
```

Therefore, this is a **Moore FSM**.

---

# 4. Detection Example

For the input sequence:

```text
1 0 1 1
```

the FSM progresses as:

```text
Input:    1    0    1    1
          ↓    ↓    ↓    ↓
State:   S0 → S1 → S2 → S3 → S4
                                     
Output:   0    0    0    0    1
```

So after the FSM enters `S4`, `y` becomes `1`.

Because this is a Moore implementation, the detection output is associated with the **state after the final input bit has been clocked in**.

---

# 5. Testbench Analysis

The clock is generated using:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

The testbench starts with:

```verilog
reset = 1'b1;
#10 reset = 1'b0;
```

Since reset is synchronous, it is actually sampled on the clock edge while it is high.

The input is then applied at 10 ns intervals:

```text
0 → 1 → 0 → 1 → 1 → 0 → 1 → 1 → 0 → 1 → 1 → 0 → 1
```

There are multiple `1011` occurrences in this stream.

The monitor:

```verilog
$monitor("\t\t clock: %d  input: %d   detect: %d",clk, din, y);
```

continuously displays the clock, input, and detector output.

The simulation terminates after:

```verilog
#150 $finish;
```

---

# 6. Important RTL Observations

### 1. Your reset is synchronous

The code has:

```verilog
always @(posedge clk)
```

not:

```verilog
always @(posedge clk or posedge rst)
```

Therefore:

> `rst` is a synchronous active-high reset.

### 2. `din` is initially `X`

The testbench does not initialize `din` until 15 ns:

```verilog
#10 reset=1'b0;
#5 din=1'b0;
```

It is better to start with:

```verilog
reset = 1'b1;
din   = 1'b0;
```

### 3. Combinational blocks use nonblocking assignments

You currently use:

```verilog
nst <= S1;
y   <= 1'b0;
```

For combinational logic, conventional Verilog style is:

```verilog
nst = S1;
y   = 1'b0;
```

while the sequential state register should continue using:

```verilog
cs <= nst;
```

### 4. The testbench is not self-checking

It observes `y` but doesn't automatically compare it against expected detection points. For learning FSMs, this is fine; for verification, a self-checking testbench would be stronger.

---

# 7. Advantages & Limitations

### Advantages

* Simple 5-state FSM
* Synthesizable RTL
* Easy-to-understand state progression
* Moore output gives state-based detection
* Supports overlapping pattern tracking
* Low hardware complexity

### Limitations

* Fixed `1011` pattern
* Non-parameterized
* Testbench is observation-based
* Combinational logic should preferably use blocking assignments
* `din` should be initialized in the testbench

---

# 8. Interview Takeaway

> **This is a 5-state Moore FSM-based serial sequence detector that detects `1011`, using a synchronous active-high reset and state-dependent output generation.**

### Key interview questions

**Why Moore?**
Because `y` depends only on `cs`.

**What does `S3` represent?**
The sequence `101` has been received.

**When does `y` become 1?**
When `cs = S4`, representing the completed `1011` sequence.

**What is the clock frequency?**

```text
T = 10 ns
f = 1/T = 100 MHz
```

**Is the reset asynchronous?**
No. It is synchronous because only `posedge clk` appears in the sensitivity list.
