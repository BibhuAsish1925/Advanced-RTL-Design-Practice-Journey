# 8-BIT PRNG / PRBS GENERATOR

## 1. Circuit Overview & Applications

This design is an **8-bit pseudo-random bit sequence generator** based on an LFSR structure.

* **Width:** 8 bits
* **Type:** Synchronous sequential circuit
* **Reset:** Asynchronous active-low
* **Reset/seed value:** `8'hFF`
* **Feedback:** `temp[7] ^ temp[5] ^ temp[4] ^ temp[3]`
* **Output:** 8-bit `prbs`
* **Hardware:** 8 flip-flops + XOR feedback logic

### Applications

* Digital BIST
* Pseudo-random test-pattern generation
* Communication scramblers
* Error testing
* RTL/ASIC verification
* Noise-like stimulus generation

---

## 2. Circuit Working & RTL Implementation

The internal register is:

```verilog
reg [7:0] temp;
```

### Reset

The sensitivity list is:

```verilog
always @(posedge clk or negedge rst_n)
```

Therefore, reset is **asynchronous active-low**.

When `rst_n = 0`:

```verilog
temp <= 8'hFF;
```

So the initial state is:

```text
11111111
```

### PRNG Operation

When reset is inactive, the register updates on every positive clock edge:

```verilog
temp <= {temp[6:0],
         temp[7] ^ temp[5] ^ temp[4] ^ temp[3]};
```

The operation is:

```text
Current state:
[7][6][5][4][3][2][1][0]

             XOR feedback
                │
                ▼
Next state:
[6][5][4][3][2][1][0][FB]
```

where:

```text
FB = bit7 XOR bit5 XOR bit4 XOR bit3
```

The output is continuously connected to the register:

```verilog
assign prbs = temp;
```

Thus `prbs` always represents the current PRNG state.

---

## 3. Verification & Testbench

The testbench uses:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

Initially:

```verilog
rst_n = 1'b0;
```

After 10 ns:

```verilog
rst_n = 1'b1;
```

The PRNG then starts shifting on each positive clock edge.

Simulation runs for another 300 ns and terminates with:

```verilog
$finish;
```

The monitor continuously displays:

```text
Time    Reset    PRBS
```

### Verification type

This is an **observational testbench**. It verifies visually that the PRBS output changes, but it does not automatically check whether each state is correct.

A stronger TB could verify:

* Correct reset value (`FF`)
* Correct feedback sequence
* No unexpected zero lock-up
* Sequence repetition
* Maximum-length sequence, if the chosen taps are intended to provide it

---

## 4. Advantages & Limitations

### Advantages

* Very small hardware implementation
* Simple XOR-based feedback
* Asynchronous reset provides immediate initialization
* Synthesizable RTL
* Suitable for high-speed pseudo-random pattern generation

### Limitations

* Output is deterministic rather than truly random
* Sequence depends on the selected feedback taps
* Current TB does not automatically verify the generated sequence
* Not suitable as a cryptographic random-number generator
* An XOR LFSR entering `00000000` would remain there

---

## 5. Interview Takeaways

**One-line explanation:**

> An 8-bit PRNG implemented using an LFSR generates a deterministic pseudo-random sequence through XOR feedback and a shift-register structure.

### Key difference from your previous LFSR

The actual LFSR logic is essentially the **same**. The main RTL difference is the reset implementation:

| Previous LFSR                 | This PRNG                      |
| ----------------------------- | ------------------------------ |
| Synchronous active-high reset | Asynchronous active-low reset  |
| `posedge clk`                 | `posedge clk or negedge rst_n` |
| `reset = 1` activates reset   | `rst_n = 0` activates reset    |
| Output named `lfsr_out`       | Output named `prbs`            |

So, architecturally, this is best described as an **8-bit LFSR-based PRNG/PRBS generator** rather than a fundamentally different PRNG architecture.
