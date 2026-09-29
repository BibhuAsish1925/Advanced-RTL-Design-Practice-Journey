# One-Shot FSM — 4-State One-Hot Moore FSM

## 1. Circuit Overview & Applications

This RTL implements a **4-state finite-state machine using one-hot encoding**. The FSM continuously cycles through four states:

```text
IDLE → STATE1 → STATE2 → STATE3 → IDLE → ...
```

Each state has a unique 4-bit one-hot representation:

| State  | Encoding | `out1` | `out2` |
| ------ | -------- | -----: | -----: |
| IDLE   | `0001`   |      0 |      0 |
| STATE1 | `0010`   |      1 |      0 |
| STATE2 | `0100`   |      0 |      1 |
| STATE3 | `1000`   |      1 |      1 |

The outputs depend **only on the current state**, making this a **Moore FSM**.

The design is useful for demonstrating:

* FSM design
* One-hot state encoding
* Moore output decoding
* Sequential state transitions
* Reset recovery
* FPGA-oriented FSM implementation

---

# 2. Circuit Working & RTL Implementation

### State definitions

```verilog
parameter [3:0] IDLE   = 4'b0001;
parameter [3:0] STATE1 = 4'b0010;
parameter [3:0] STATE2 = 4'b0100;
parameter [3:0] STATE3 = 4'b1000;
```

Only one bit is HIGH in every valid state.

This is the defining characteristic of **one-hot encoding**.

For example:

```text
IDLE   → 0001
STATE1 → 0010
STATE2 → 0100
STATE3 → 1000
```

---

# 3. Sequential State Register

The state is updated here:

```verilog
always @(posedge clk, posedge reset)
```

This means the FSM changes state on the **rising edge of `clk`** and has an **asynchronous active-high reset**.

### Reset

```verilog
if (reset)
    state <= IDLE;
```

Whenever `reset = 1`, the FSM immediately enters:

```text
state = 0001
```

---

## State transition logic

```verilog
case(state)
  IDLE:    state <= STATE1;
  STATE1:  state <= STATE2;
  STATE2:  state <= STATE3;
  STATE3:  state <= IDLE;
  default: state <= IDLE;
endcase
```

Therefore:

```text
          ┌──────────┐
          │          │
          ▼          │
       ┌──────┐   ┌───────┐   ┌───────┐   ┌───────┐
       │ IDLE │ → │STATE1 │ → │STATE2 │ → │STATE3 │
       └──────┘   └───────┘   └───────┘   └───────┘
          ▲                                      │
          └──────────────────────────────────────┘
```

There are no external inputs controlling the transitions. The FSM simply cycles through the states on every clock edge.

---

# 4. Moore Output Logic

The output block is:

```verilog
always @(*) begin
  case(state)
```

The outputs are completely determined by `state`.

```verilog
IDLE:
  out1 = 0;
  out2 = 0;

STATE1:
  out1 = 1;
  out2 = 0;

STATE2:
  out1 = 0;
  out2 = 1;

STATE3:
  out1 = 1;
  out2 = 1;
```

So the output sequence is:

```text
State     out1 out2
--------------------
IDLE       0    0
STATE1     1    0
STATE2     0    1
STATE3     1    1
IDLE       0    0
...
```

Because outputs depend only on the state, this is a **Moore FSM** rather than a Mealy FSM.

---

# 5. Why One-Hot Encoding?

With one-hot encoding, each state gets its own flip-flop/bit.

For four states:

```text
Binary encoding:
00
01
10
11

One-hot:
0001
0010
0100
1000
```

### Advantages

* Simple state decoding
* Simple next-state logic
* Often efficient on FPGAs because flip-flops are abundant
* Can provide straightforward timing for larger FSMs
* Easy to debug by observing the state bits

### Disadvantage

One-hot uses more flip-flops.

For example:

```text
4 states:
Binary → 2 state bits
One-hot → 4 state bits
```

For a large number of states, this can increase register usage.

---

# 6. Testbench Analysis

The testbench declares:

```verilog
reg clk, reset;
wire [3:0] state;
wire out1, out2;
```

The DUT is instantiated normally.

---

## Clock generation

```verilog
clk = 0;
always #5 clk = ~clk;
```

This produces:

```text
5 ns HIGH
5 ns LOW
10 ns period
```

Therefore:

```text
fclk = 100 MHz
```

---

## Reset

Initially:

```verilog
reset = 1;
```

so the FSM is forced to:

```text
IDLE = 0001
```

After:

```verilog
#10 reset = 0;
```

the FSM is released from reset.

At the next positive clock edge, it transitions:

```text
IDLE → STATE1
```

---

# 7. Expected Simulation Sequence

Because the clock period is 10 ns and reset is released at 10 ns, the expected sequence is approximately:

|  Time | State  | `out1` | `out2` |
| ----: | ------ | -----: | -----: |
|  0 ns | IDLE   |      0 |      0 |
| 15 ns | STATE1 |      1 |      0 |
| 25 ns | STATE2 |      0 |      1 |
| 35 ns | STATE3 |      1 |      1 |
| 45 ns | IDLE   |      0 |      0 |
| 55 ns | STATE1 |      1 |      0 |
| 65 ns | STATE2 |      0 |      1 |
| 75 ns | STATE3 |      1 |      1 |
|   ... | ...    |    ... |    ... |

The reason the first transition occurs at approximately **15 ns** is that the reset is released at 10 ns, while the next positive clock edge occurs at 15 ns.

---

# 8. About the "One-Shot" Name

Despite the module name:

```verilog
module one_shot_fsm
```

this circuit is **not a conventional one-shot pulse generator**.

A traditional one-shot generally generates a single pulse in response to an event.

This module instead continuously cycles:

```text
IDLE → STATE1 → STATE2 → STATE3 → IDLE
```

So technically, it is better described as a:

> **4-state cyclic one-hot Moore FSM**

The supplied RTL itself does not implement a one-shot trigger/input mechanism.

---

# 9. Testbench Strengths & Limitations

### Strengths

* Simple clock generation.
* Applies reset.
* Allows the FSM to run through multiple complete cycles.
* `$monitor` continuously displays state and outputs.
* `$finish` terminates simulation.

### Limitation

The testbench is **observation-based rather than self-checking**.

It does not explicitly verify:

```text
IDLE    → STATE1
STATE1  → STATE2
STATE2  → STATE3
STATE3  → IDLE
```

or verify that each output combination is correct.

A stronger verification environment would automatically check expected state/output values and flag a `PASS`/`FAIL`.

---

# 10. Important RTL Detail

The `default` branch:

```verilog
default:
    state <= IDLE;
```

provides recovery if the state register somehow contains an invalid one-hot value such as:

```text
0000
0011
1010
1111
```

Instead of remaining in an illegal state, the FSM returns to:

```text
0001 = IDLE
```

This is a useful **illegal-state recovery mechanism**.

---

# 11. ASIC / FPGA Relevance

This is a basic but important FSM architecture for RTL design.

### FPGA

One-hot encoding is commonly attractive because FPGA fabrics generally contain many flip-flops and relatively abundant routing resources. The simpler decoding can also be timing-friendly.

### ASIC

The choice between one-hot and binary encoding is more implementation-dependent. One-hot can consume more sequential area, while binary encoding requires fewer state registers but potentially more decoding logic.

The actual choice should be based on:

```text
Area
Timing
Power
Number of states
Technology/library characteristics
Synthesis results
```

---

# 12. Interview Takeaway

**One-line explanation:**

> “This is a 4-state cyclic Moore FSM using one-hot encoding, where one state bit is active at a time and the two outputs are combinationally decoded from the current state.”

### Likely interview questions

1. What is one-hot encoding?
2. Why are four flip-flops required for four states?
3. What is the difference between Moore and Mealy FSMs?
4. Why might one-hot encoding be preferred on an FPGA?
5. What are the area disadvantages of one-hot encoding?
6. What happens if the FSM enters `0000`?
7. Why is the `default` case important?
8. Is the reset synchronous or asynchronous?
9. Why is this technically not a conventional one-shot circuit?
10. How would you modify it to generate a **single-cycle pulse** in response to an input trigger?
