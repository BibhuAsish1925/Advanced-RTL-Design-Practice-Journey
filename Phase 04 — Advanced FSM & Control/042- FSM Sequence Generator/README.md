# 4-Bit Sequence Generator

## 1. Circuit Overview & Applications

This RTL implements a simple **synchronous sequence generator** using a 2-bit state machine. It generates a one-hot sequence on the lower four bits of an 8-bit output:

```text
00000001
00000010
00000100
00001000
00000001
...
```

The circuit consists of:

* A 3-bit internal state register
* An 8-bit registered output
* Four defined states
* Synchronous active-high reset
* Sequential state and output generation

The sequence is useful for demonstrating:

* FSM-based sequence generation
* One-hot output patterns
* Sequential logic
* State-controlled output generation
* Timing/control signal generation

---

# 2. Circuit Working & RTL Implementation

The internal state is:

```verilog
reg [2:0] state;
```

Although 3 bits are allocated, only four states are actually used:

```text
state = 0
state = 1
state = 2
state = 3
```

The state transitions are:

```text id="seqflow"
       ┌─────────┐
       │         ▼
     State 0 → State 1
       ▲           │
       │           ▼
     State 3 ← State 2
```

More directly:

```text
0 → 1 → 2 → 3 → 0 → ...
```

---

## State 0

```verilog
3'd0: begin
    seq_out <= 8'b00000001;
    state   <= 3'd1;
end
```

The output becomes:

```text
00000001
```

and the next state is `1`.

---

## State 1

```verilog
3'd1: begin
    seq_out <= 8'b00000010;
    state   <= 3'd2;
end
```

Output:

```text
00000010
```

---

## State 2

```verilog
3'd2: begin
    seq_out <= 8'b00000100;
    state   <= 3'd3;
end
```

Output:

```text
00000100
```

---

## State 3

```verilog
3'd3: begin
    seq_out <= 8'b00001000;
    state   <= 3'd0;
end
```

Output:

```text
00001000
```

and the sequence returns to state 0.

Thus:

```text
State       seq_out
-------------------------
0           00000001
1           00000010
2           00000100
3           00001000
0           00000001
...
```

---

# 3. Reset Behavior

The reset is inside:

```verilog
always @(posedge clk)
```

so it is a **synchronous active-high reset**.

```verilog
if (reset) begin
    state <= 0;
    seq_out <= 0;
end
```

This means `reset` only affects the circuit on a **rising edge of `clk`**.

During reset:

```text
state   = 000
seq_out = 00000000
```

Once reset is released, the first subsequent rising edge executes state `0` and produces:

```text
seq_out = 00000001
```

---

# 4. Clock and Timing

The testbench uses:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

The sequence advances once per positive clock edge.

So each output pattern remains active for one clock cycle:

```text id="timing"
Clock edge       seq_out
--------------------------------
15 ns            00000001
25 ns            00000010
35 ns            00000100
45 ns            00001000
55 ns            00000001
65 ns            00000010
...
```

The exact first transition follows the reset timing in the testbench.

---

# 5. Testbench Analysis

The testbench starts with:

```verilog
clk = 0;
reset = 1;
```

Reset is held for:

```verilog
#10 reset = 0;
```

Since the clock has a 10-ns period, there are positive edges at approximately:

```text
5 ns
15 ns
25 ns
...
```

The reset is therefore sampled at the 5-ns edge and the circuit is held in reset until reset is released at 10 ns.

At the next positive edge:

```text
15 ns
```

the sequence begins.

---

## `$monitor`

```verilog
$monitor("t=%0t\t reset=%b seq_out=%b",
         $time, reset, seq_out);
```

This continuously reports changes in the monitored signals.

It allows you to observe the sequence directly from the simulator console.

---

# 6. Expected Simulation

After reset:

```text
reset = 0
```

the output should cycle:

```text
00000001
00000010
00000100
00001000
00000001
00000010
...
```

Because the simulation runs for 200 ns after reset release, approximately 20 additional clock periods are available, giving several complete sequence repetitions.

---

# 7. Important RTL Observation

There is no `default` case in:

```verilog
case (state)
```

Only states `0–3` are handled.

The state register is 3 bits, so theoretically it can contain:

```text
000
001
010
011
100
101
110
111
```

but only:

```text
000–011
```

are defined.

If the state somehow becomes:

```text
100, 101, 110, or 111
```

none of the case branches executes. Since `state` and `seq_out` retain their previous registered values, the FSM can become stuck.

A safer implementation would include:

```verilog
default: begin
    seq_out <= 8'b0;
    state   <= 3'd0;
end
```

This provides **illegal-state recovery**.

---

# 8. Another Design Observation

Only four states are required, so:

```verilog
reg [2:0] state;
```

is larger than necessary.

A 2-bit state register is sufficient:

```verilog
reg [1:0] state;
```

because four states can be represented as:

```text
00
01
10
11
```

The existing 3-bit register is not functionally wrong; it simply provides one extra unused state bit.

---

# 9. Advantages & Limitations

### Advantages

* Very simple sequential architecture.
* Easy to understand and simulate.
* Deterministic output sequence.
* Synthesizable RTL.
* One output pattern per clock cycle.
* Useful for basic FSM/sequence-generator learning.

### Limitations

* Only generates four patterns.
* Output width is fixed at 8 bits.
* Internal state width is larger than necessary.
* No illegal-state recovery in the supplied version.
* No parameterization for sequence length or output width.
* Testbench is observational rather than self-checking.

---

# 10. ASIC / FPGA Relevance

The structure represents a common digital design pattern:

```text
Clock
  │
  ▼
State Register
  │
  ▼
State Decoder
  │
  ▼
Registered Output
```

It can be extended to implement:

* LED sequencing
* Control-state generation
* Timing patterns
* Digital pattern generators
* Test-mode control sequences
* Simple protocol/control sequencing

For FPGA learning, this is a straightforward example of a clocked FSM driving a registered output.

---

# 11. Interview Takeaway

**One-line explanation:**

> “This is a synchronous FSM-based sequence generator that cycles through four states and produces a one-hot 4-bit pattern on an 8-bit registered output.”

### Likely interview questions

1. Why is a 3-bit state register used when only four states exist?
2. How many flip-flops are required for the state and output?
3. Is the reset synchronous or asynchronous?
4. What happens if `state` becomes `3'd4`?
5. Why should a `default` case be added?
6. How would you make the sequence length parameterizable?
7. How would you generate the same sequence using a shift register instead of an FSM?
8. What is the difference between a registered and combinational `seq_out`?
9. What is the output sequence frequency relative to the input clock?
10. How would you modify this design to generate an 8-state one-hot sequence?
