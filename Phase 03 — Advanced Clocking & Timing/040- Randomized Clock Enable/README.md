# Randomized Clock Enable

## 1. Circuit Overview & Applications

This module generates a **pseudo-randomly stalled version of an enable signal**. It uses an LFSR to create a deterministic pseudo-random sequence and suppresses `en_i` whenever a selected LFSR pattern occurs.

The main behavior is:

```text
             +----------------+
             | 8-bit LFSR     |
             | pseudo-random  |
             | sequence       |
             +-------+--------+
                     |
                  LSB[2:0]
                     |
                     v
              000 pattern?
                     |
              +------+------+
              | Stall       |
              +------+------+
                     |
en_i ----------------AND----------> en_o
```

With the default configuration:

```text
LFSR_W = 8
stall condition = lfsr[2:0] == 3'b000
```

So, assuming a sufficiently uniform LFSR sequence, the intended stall probability is approximately:

```text
1 / 8 = 12.5%
```

Potential applications include:

* Pseudo-random stress testing
* Clock/enable-path robustness testing
* Randomized workload generation
* Verification of logic under intermittent enables
* Power-management experimentation
* Fault-injection-style simulation

---

# 2. Circuit Working & RTL Implementation

## A. LFSR State

The internal pseudo-random state is:

```verilog
reg [LFSR_W-1:0] lfsr;
```

For the default:

```text
LFSR_W = 8
```

so:

```text
lfsr = [7:0]
```

The reset value is:

```verilog
lfsr <= {LFSR_W{1'b1}};
```

Therefore:

```text
11111111
```

is used as the initial non-zero state.

A non-zero seed is important because an LFSR can become locked in an all-zero state for many conventional feedback structures.

---

# 3. LFSR Feedback

The feedback equation is:

```verilog
wire feedback =
    lfsr[LFSR_W-1] ^
    lfsr[5] ^
    lfsr[3] ^
    lfsr[0];
```

For `LFSR_W=8`:

```text
feedback = lfsr[7] ^ lfsr[5] ^ lfsr[3] ^ lfsr[0]
```

The next state is:

```verilog
lfsr <= {lfsr[LFSR_W-2:0], feedback};
```

So the register shifts and inserts the feedback bit.

Conceptually:

```text
       feedback
          │
          ▼
+---+---+---+---+---+---+---+---+
|   | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
+---+---+---+---+---+---+---+---+
  └───────────────────────────────┘
             shift
```

More simply:

```text
old lfsr[6:0] + new feedback
        ↓
new lfsr[7:0]
```

The resulting sequence is deterministic but appears pseudo-random.

---

# 4. Stall Generation

The stall condition is:

```verilog
wire stall = (lfsr[2:0] == 3'b000);
```

Therefore:

```text
lfsr[2:0] = 000 → stall = 1
anything else  → stall = 0
```

There are eight possible 3-bit combinations:

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

Only one causes a stall.

Hence the intended probability is approximately:

```text
P(stall) = 1/8 = 12.5%
```

assuming the LFSR visits its states with a sufficiently uniform distribution.

---

# 5. Randomized Enable Output

The final output is:

```verilog
assign en_o = en_i & ~stall;
```

Therefore:

| `en_i` | `stall` | `en_o` |
| -----: | ------: | -----: |
|      0 |       0 |      0 |
|      0 |       1 |      0 |
|      1 |       0 |      1 |
|      1 |       1 |      0 |

So the circuit **never creates an enable when `en_i` is LOW**.

It only suppresses some original enable cycles.

---

# 6. Important Point: This Is Not Actually a Clock Gating Circuit

Despite the module name containing `clk_enable`, the circuit does **not** gate `clk`.

It generates:

```text
randomized enable
```

not:

```text
randomized clock
```

The clock remains:

```text
clk → unchanged
```

and only `en_o` is modified.

This is generally much safer than directly generating:

```verilog
assign gated_clk = clk & en_o;
```

because directly manipulating a clock with pseudo-random logic can create undesirable clock glitches.

---

# 7. Testbench Analysis

The testbench uses:

```verilog
localparam CLK_PERIOD = 10;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

It tests the design for:

```verilog
NUM_CYCLES = 2000;
```

which provides a reasonably large sample for observing the approximate stall percentage.

---

## Test 1 — LFSR Reset

The testbench initially asserts reset:

```verilog
rst_n = 1'b0;
```

and then releases it:

```verilog
rst_n = 1'b1;
```

After a small delay:

```verilog
#1;
```

it directly checks:

```verilog
if (dut.lfsr !== {LFSR_W{1'b1}})
```

This is a useful verification technique because it checks the internal LFSR state.

Expected:

```text
PASS: LFSR correctly reset to all-ones seed
```

---

# 8. Test 2 — Statistical Stall Test

The input enable is continuously asserted:

```verilog
en_i = 1'b1;
```

Then the testbench observes 2000 clock cycles:

```verilog
for (i = 0; i < NUM_CYCLES; i = i + 1) begin
    @(posedge clk);
    #1;
    if (en_i && !en_o)
        stall_count = stall_count + 1;
end
```

Every time:

```text
en_i = 1
en_o = 0
```

the testbench counts one stall.

At the end:

```verilog
$display("Observed stall count = ...");
```

prints the measured percentage.

The expected value is approximately:

```text
12.5%
```

For 2000 cycles, the rough expected count is:

```text
2000 × 0.125 = 250 stalls
```

The actual number does not need to be exactly 250 because the LFSR is deterministic and finite-length.

---

# 9. Test 3 — Enable Deassertion

The testbench then sets:

```verilog
en_i = 1'b0;
```

and checks 20 cycles:

```verilog
if (en_o !== 1'b0)
    $display("FAIL...");
```

The expected behavior is:

```text
en_i = 0
      ↓
en_o = 0
```

regardless of the LFSR state.

This verifies that the randomized logic can **only suppress** the enable and cannot generate one.

---

# 10. Verification Assessment

The testbench covers three useful properties:

### Reset property

```text
Reset → LFSR = all ones
```

### Statistical behavior

```text
Long run → approximately 12.5% stalled cycles
```

### Functional masking

```text
en_i = 0 → en_o must always be 0
```

The testbench is therefore stronger than a simple waveform-only TB because it contains actual checks and a measured statistical result.

One limitation is that it does not explicitly verify that the LFSR sequence is maximal-length or that the expected LFSR state sequence is correct.

---

# 11. Important RTL Limitation

There is a significant parameterization issue here.

The feedback uses fixed bit positions:

```verilog
lfsr[5]
lfsr[3]
lfsr[0]
```

Therefore, although the module has:

```verilog
parameter integer LFSR_W = 8
```

it is **not genuinely parameterizable to arbitrary LFSR widths**.

For example, if:

```text
LFSR_W = 4
```

then:

```verilog
lfsr[5]
```

is out of range.

So this design is effectively intended for:

```text
LFSR_W = 8
```

unless the tap structure is changed for each width.

---

# 12. Another Important Point — Is the LFSR Actually Maximal-Length?

The comment says:

```verilog
// Simple Fibonacci LFSR
```

but the chosen taps should not automatically be assumed to produce a maximal-length 8-bit sequence.

For an 8-bit maximal-length LFSR, the feedback polynomial/tap convention must be selected consistently with the shift direction and implementation.

This matters because the stall distribution depends on the actual sequence.

If the LFSR does not traverse all non-zero states uniformly, the observed stall percentage may differ significantly from exactly 12.5%.

Therefore, the TB's:

```text
expected ~12.5%
```

is an **expected statistical target**, not a guarantee from the RTL as currently written.

---

# 13. Advantages & Limitations

### Advantages

* Very small hardware.
* No true random-number generator required.
* Deterministic and repeatable after reset.
* Useful for pseudo-random verification scenarios.
* Only suppresses existing enables.
* Does not directly manipulate the clock.
* Statistical behavior can be measured easily.

### Limitations

* LFSR is deterministic, not truly random.
* Fixed taps make the parameterization incomplete.
* Exact 12.5% stall probability depends on the actual LFSR sequence.
* Short observation windows can produce noticeable statistical variation.
* The stall pattern is predictable if the LFSR state is known.
* Not suitable as a security-grade random source.
* No explicit control over stall rate beyond changing the matching pattern.

---

# 14. ASIC / FPGA Relevance

This is a useful **verification-oriented RTL pattern** rather than a conventional clock-generation circuit.

A practical use could be:

```text
Normal enable
     │
     ▼
Pseudo-random enable suppression
     │
     ▼
Functional block
     │
     ▼
Observe behavior under intermittent operation
```

For example, a verification environment could use this concept to stress:

* FIFO interfaces
* Pipeline enables
* Power-management controls
* Handshake logic
* Memory interfaces
* Peripheral controllers

For ASIC implementation, the LFSR itself is inexpensive: essentially a bank of flip-flops plus XOR feedback logic.

---

# 15. Interview Takeaway

**One-line explanation:**

> “This module uses an LFSR to generate a deterministic pseudo-random sequence and probabilistically suppress an existing enable signal, providing approximately 12.5% stalled cycles for stress and verification purposes.”

### Likely interview questions

1. What is an LFSR and why is it used here?
2. Why must the LFSR seed be non-zero?
3. Is this truly random?
4. How is the 12.5% stall probability obtained?
5. What happens if the LFSR enters the all-zero state?
6. Why is `en_o` implemented as `en_i & ~stall`?
7. Why shouldn't this logic directly gate the clock?
8. Is `LFSR_W` really parameterized in this implementation?
9. How would you select taps for a maximal-length LFSR?
10. How would you verify that the LFSR has a maximal-length sequence?
11. What happens to the measured stall percentage if the observation window is short?
12. How would you make the stall probability configurable, e.g. 5%, 10%, or 25%?
