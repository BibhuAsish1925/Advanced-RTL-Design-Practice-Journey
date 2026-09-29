# Minimum Pulse-Width Qualifier

## 1. Circuit Overview & Applications

This module is a **synchronous minimum-pulse-width qualifier**. It prevents short glitches on `sig_i` from changing the qualified output `sig_o`.

With the current parameters:

* `MIN_PW_ASSERT = 2` → input must remain HIGH for at least **2 clock samples** before `sig_o` asserts.
* `MIN_PW_DEASSERT = 2` → input must remain LOW for at least **2 clock samples** before `sig_o` deasserts.
* A short HIGH or LOW pulse is therefore filtered out.
* The circuit operates entirely in the `clk` domain.

**Typical applications:**

* Glitch filtering
* Reset/control-signal qualification
* Enable qualification
* Fault/alarm filtering
* Debouncing slow digital control signals
* Rejecting short asynchronous/noisy pulses after synchronization

Conceptually:

```text
              +-----------------------+
sig_i ------->| High/Low Duration     |
              | Counters              |
              +-----------+-----------+
                          |
                          v
              +-----------------------+
              | Threshold Detection   |
              +-----------+-----------+
                          |
                          v
                      sig_o
```

---

# 2. Circuit Working & RTL Implementation

### Main parameters

```verilog
parameter integer MIN_PW_ASSERT   = 2;
parameter integer MIN_PW_DEASSERT = 2;
```

These define the minimum number of consecutive clock samples required for a transition.

The protection:

```verilog
localparam integer TH_A = (MIN_PW_ASSERT < 1) ? 1 : MIN_PW_ASSERT;
localparam integer TH_D = (MIN_PW_DEASSERT < 1) ? 1 : MIN_PW_DEASSERT;
```

ensures that the thresholds cannot become zero.

Counter widths are calculated using:

```verilog
localparam integer CWA = $clog2(TH_A + 1);
localparam integer CWD = $clog2(TH_D + 1);
```

For threshold `2`:

```text
$clog2(3) = 2 bits
```

So both counters can represent:

```text
00 → 0
01 → 1
10 → 2
11 → 3
```

---

## Internal registers

### `last`

```verilog
reg last;
```

Stores the previous sampled value of `sig_i`.

It is used to determine whether the current sample continues the previous HIGH/LOW run or represents a transition.

### `cnt_a`

```verilog
reg [CWA-1:0] cnt_a;
```

Counts consecutive HIGH samples.

### `cnt_d`

```verilog
reg [CWD-1:0] cnt_d;
```

Counts consecutive LOW samples.

---

## Reset behavior

```verilog
if (!rst_n) begin
  sig_o <= 1'b0;
  last  <= 1'b0;
  cnt_a <= 0;
  cnt_d <= 0;
end
```

The reset is **active-low asynchronous** because `negedge rst_n` appears in the sensitivity list.

The qualified output is deliberately reset LOW.

---

## HIGH-duration counting

When:

```verilog
if (sig_i)
```

the module is observing a HIGH input.

If the HIGH level continues:

```verilog
if (sig_i == last)
```

the counter increments:

```verilog
if (cnt_a < TH_A[CWA-1:0])
    cnt_a <= cnt_a + 1'b1;
```

If HIGH has just started, the counter is initialized to one:

```verilog
cnt_a <= {{(CWA-1){1'b0}}, 1'b1};
```

At the same time:

```verilog
cnt_d <= 0;
```

because there is no longer a LOW run.

---

## LOW-duration counting

The LOW side works similarly:

```verilog
else begin
```

The low counter is incremented while consecutive LOW samples are detected.

The HIGH counter is cleared:

```verilog
cnt_a <= 0;
```

This prevents the two duration measurements from interfering with each other.

---

## Output qualification

The key logic is:

```verilog
if (sig_i && !sig_o &&
    (cnt_a == TH_A[CWA-1:0]))
    sig_o <= 1'b1;
```

The output can transition LOW → HIGH only when:

1. `sig_i` is HIGH
2. `sig_o` is currently LOW
3. The HIGH counter has reached the assertion threshold

Similarly:

```verilog
if (!sig_i && sig_o &&
    (cnt_d == TH_D[CWD-1:0]))
    sig_o <= 1'b0;
```

requires the LOW-duration threshold before deasserting.

---

# 3. Important Timing Detail

There is an important **nonblocking-assignment timing subtlety** in this RTL.

The counter is updated using:

```verilog
cnt_a <= cnt_a + 1'b1;
```

but the qualification check:

```verilog
cnt_a == TH_A
```

reads the **old value** of `cnt_a` during that clock edge.

Therefore, the actual transition can occur **one clock sample later than the intuitive threshold count**.

For example, with:

```text
MIN_PW_ASSERT = 2
```

the conceptual sequence is:

```text
Clock edge       cnt_a used for comparison
------------------------------------------------
1st HIGH sample       0
2nd HIGH sample       1
3rd HIGH sample       2 → sig_o asserts
```

So the current RTL effectively commits the transition after the counter has already reached the threshold on the previous clock edge.

This is not a simulation bug; it results from normal **nonblocking assignment semantics**.

If the intended specification is strictly:

> "Assert on the clock edge that observes the Nth consecutive HIGH sample"

then the comparison should use the **next counter value**, rather than the currently stored value.

---

# 4. Testbench Analysis

The testbench uses:

```verilog
localparam CLK_PERIOD = 10;
```

Therefore:

```text
Clock frequency = 1 / 10 ns
                = 100 MHz
```

The clock is generated as:

```verilog
initial clk = 1'b0;
always #(CLK_PERIOD/2) clk = ~clk;
```

giving:

```text
5 ns LOW
5 ns HIGH
10 ns period
```

---

## Test 1 — Short HIGH glitch

```verilog
sig_i = 1'b1;
#(CLK_PERIOD*1);
sig_i = 1'b0;
```

The input stays HIGH for only one clock period.

Since:

```text
MIN_PW_ASSERT = 2
```

the pulse is too short.

Expected:

```text
sig_i : ___|‾‾‾|________
sig_o : __________________
```

`sig_o` should remain LOW.

---

## Test 2 — Sustained HIGH

```verilog
sig_i = 1'b1;
#(CLK_PERIOD*5);
```

The HIGH input lasts five clock periods.

Therefore it exceeds the two-cycle qualification requirement and `sig_o` eventually becomes HIGH.

Conceptually:

```text
sig_i : ___|‾‾‾‾‾‾‾‾‾‾‾
sig_o : _________|‾‾‾‾‾‾
```

The exact transition edge is affected by the counter/NBA timing described above.

---

## Test 3 — Short LOW glitch

```verilog
sig_i = 1'b0;
#(CLK_PERIOD*1);
sig_i = 1'b1;
```

Because the LOW pulse lasts only one clock period:

```text
1 cycle < 2 cycles
```

the output should remain HIGH.

```text
sig_i : ‾‾‾|___|‾‾‾‾‾
sig_o : ‾‾‾‾‾‾‾‾‾‾‾
```

This demonstrates **deassertion filtering**.

---

## Test 4 — Sustained LOW

```verilog
sig_i = 1'b0;
#(CLK_PERIOD*5);
```

The LOW input remains active long enough to satisfy:

```text
MIN_PW_DEASSERT = 2
```

so `sig_o` eventually returns LOW.

---

# 5. Verification Assessment

The testbench is useful because it covers the two fundamental cases in both directions:

| Test | Input condition     | Expected `sig_o` |
| ---- | ------------------- | ---------------- |
| 1    | 1-cycle HIGH glitch | Remains LOW      |
| 2    | 5-cycle HIGH        | Becomes HIGH     |
| 3    | 1-cycle LOW glitch  | Remains HIGH     |
| 4    | 5-cycle LOW         | Becomes LOW      |

The `$monitor` provides waveform-equivalent textual observation:

```verilog
$monitor("t=%0t\t sig_i=%b sig_o=%b",
         $time, sig_i, sig_o);
```

and:

```verilog
$finish;
```

properly terminates simulation.

### One limitation

The TB is primarily **observational**. It does not contain explicit assertions or PASS/FAIL checks such as:

```verilog
if (sig_o !== expected)
    $display("FAIL");
```

So it verifies behavior by inspection rather than automatically proving correctness.

---

# 6. Advantages & Limitations

### Advantages

* Filters short HIGH and LOW pulses.
* Parameterized qualification time.
* Small hardware implementation.
* Uses only counters, registers, and comparison logic.
* Synthesizable RTL.
* Separate assertion/deassertion thresholds allow asymmetric qualification.

### Limitations

* `sig_i` is sampled synchronously; very narrow pulses occurring entirely between clock edges may never be observed.
* If `sig_i` is asynchronous to `clk`, it should normally pass through a **synchronizer** before this qualifier to reduce metastability risk.
* Counter-based qualification introduces latency.
* The current counter comparison introduces an additional clock of apparent qualification latency.
* This is a **digital sampled filter**, not an analog minimum-pulse-width detector.
* The generated hardware grows with the required threshold/counter width.

---

# 7. ASIC / FPGA Relevance

This is a good **practical RTL design exercise** because it combines:

```text
Parameterized RTL
       ↓
Clocked state
       ↓
Counters
       ↓
Threshold comparison
       ↓
Glitch / pulse qualification
       ↓
Verification of corner cases
```

For ASIC design, this type of logic can be useful for qualifying control/status signals, although asynchronous inputs and clock-domain crossings need proper front-end handling.

For FPGA, the RTL is straightforward to synthesize, but `sig_i` should still be synchronized when it originates from another clock domain or an external source.

---

# 8. Interview Takeaway

**One-line explanation:**

> “This is a parameterized synchronous pulse-width qualifier that counts consecutive HIGH and LOW samples and changes the output only after the corresponding minimum-duration threshold is satisfied, thereby filtering short glitches.”

### Likely interview questions

1. Why are separate assertion and deassertion counters used?
2. Why is `$clog2(THRESHOLD+1)` used?
3. What happens if the input changes before the threshold is reached?
4. Why should an asynchronous `sig_i` be synchronized first?
5. What is the effect of nonblocking assignment semantics on the threshold timing?
6. How would you modify the RTL to assert exactly on the Nth valid sample?
7. What happens if `MIN_PW_ASSERT = 1`?
8. What is the difference between this digital filter and an actual hardware minimum-pulse-width detector?
9. How does the required counter width scale with the qualification threshold?
10. Why can a very narrow asynchronous pulse be completely missed by this design?
