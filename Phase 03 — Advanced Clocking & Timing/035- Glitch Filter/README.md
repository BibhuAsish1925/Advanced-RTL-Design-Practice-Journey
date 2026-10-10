# GLITCH FILTER — RTL & TESTBENCH ANALYSIS

## 1. Circuit Overview & Applications

This design implements a **parameterized synchronous digital glitch filter** for an active-low input.

The basic idea is:

> A change in `in_n` is accepted only after that new level has remained stable for a specified number of clock samples.

Here:

```text
STABLE_CYCLES = 4
```

so the input must remain at the new level for the required number of clock samples before `out_n` changes.

### Applications

* Reset/debounce filtering
* Noisy control signals
* Fault/tamper input filtering
* Switch/button debouncing
* Asynchronous or noisy status inputs after appropriate synchronization
* Protection/control logic

---

# 2. Circuit Working & RTL Implementation

The important internal signals are:

```verilog
reg                last;
reg [CW-1:0]       cnt;
```

### `last`

`last` stores the **last observed input level**.

### `cnt`

`cnt` counts how long the input has remained at the same level.

The threshold is:

```verilog
localparam integer THRESH =
    (STABLE_CYCLES < 1) ? 1 : STABLE_CYCLES;
```

This guarantees that the effective threshold is at least 1.

For:

```text
STABLE_CYCLES = 4
```

we get:

```text
THRESH = 4
```

---

## Counter Width

```verilog
localparam integer CW = $clog2(THRESH + 1);
```

For `THRESH=4`:

$$
CW=\lceil\log_2(5)\rceil=3
$$

Therefore:

```text
cnt = 3 bits
```

which can represent:

```text
0 → 7
```

and is sufficient to represent the threshold value 4.

---

# 3. Reset Operation

The sequential block uses:

```verilog
always @(posedge clk or negedge rst_n)
```

Therefore, `rst_n` is an **active-low asynchronous reset**.

During reset:

```verilog
if (!rst_n) begin
    last  <= 1'b1;
    out_n <= 1'b1;
    cnt   <= 0;
end
```

The circuit assumes:

```text
in_n = 1 → input not asserted
out_n = 1 → output not asserted
```

So the reset state is the inactive/safe state.

---

# 4. Stability Tracking

After reset, the main operation is:

```verilog
if (in_n == last) begin
    if (cnt < THRESH[CW-1:0])
        cnt <= cnt + 1'b1;
end
else begin
    last <= in_n;
    cnt  <= 1;
end
```

### Case 1 — Input remains unchanged

If:

```text
in_n == last
```

the counter increments.

For example:

```text
cnt = 1 → 2 → 3 → 4
```

and then saturates at 4.

### Case 2 — Input changes

If:

```text
in_n != last
```

the circuit recognizes a new level:

```verilog
last <= in_n;
cnt  <= 1;
```

So the stability count starts again from 1.

---

# 5. Output Commitment

The output changes when:

```verilog
if (cnt == THRESH[CW-1:0])
    out_n <= last;
```

Therefore, the intended behavior is:

```text
Input changes
      │
      ▼
Start counter
      │
      ▼
Input remains stable?
      │
      ├── No → restart counter
      │
      └── Yes
           │
           ▼
      Reach threshold
           │
           ▼
      Update out_n
```

For `STABLE_CYCLES=4`, a new input level must survive the required sampling period before being committed.

---

# 6. Example: Short Glitch

The TB contains:

```verilog
in_n = 1'b0;
#(CLK_PERIOD*1);
in_n = 1'b1;
```

So the low pulse lasts for only one clock period.

The intended behavior is:

```text
in_n:
───────┐   ┌────────
       │   │
       └───┘

out_n:
────────────────────
        stays 1
```

Because the low level does not remain stable long enough to reach the threshold, it is filtered.

---

# 7. Example: Genuine Assertion

The testbench then performs:

```verilog
in_n = 1'b0;
#(CLK_PERIOD*6);
```

The low level remains asserted for six clock periods.

Since:

```text
STABLE_CYCLES = 4
```

the filter eventually accepts the low level:

```text
in_n:
────────┐
        │
        │
        └────────────

out_n:
────────────┐
            │
            └────────
```

So `out_n` transitions to `0` after the required stability interval.

---

# 8. Testbench Analysis

The testbench uses:

```verilog
localparam STABLE_CYCLES = 4;
localparam CLK_PERIOD    = 10;
```

The clock is:

```verilog
always #(CLK_PERIOD/2) clk = ~clk;
```

Therefore:

```text
Half period = 5 ns
Full period = 10 ns
Frequency   = 100 MHz
```

The testbench contains four major tests.

### Test 1 — Short glitch

```text
Low for 1 cycle
```

Expected:

```text
out_n remains 1
```

### Test 2 — Genuine assertion

```text
Low for 6 cycles
```

Expected:

```text
out_n → 0
```

### Test 3 — Genuine release

```text
High for 6 cycles
```

Expected:

```text
out_n → 1
```

### Test 4 — Another short glitch

```text
Low for 2 cycles
```

Expected:

```text
out_n remains 1
```

This is a good set of **directed functional tests** because it checks both filtering and acceptance behavior.

---

# 9. Important RTL Timing Observation

There is a subtle point in this implementation caused by **nonblocking assignments**.

Suppose the counter currently contains:

```text
cnt = 3
```

and the fourth stable sample arrives.

Inside the same clock edge:

```verilog
cnt <= cnt + 1;
```

schedules `cnt = 4`, but:

```verilog
if (cnt == THRESH)
```

still evaluates the **old** value `3`.

Therefore, `out_n` does not commit on that same edge. It commits on the subsequent clock edge when the old `cnt` is already equal to `THRESH`.

So the actual latency is slightly different from the intuitive interpretation of "4 samples."

This is important when specifying exact filter latency.

A more precise implementation can check the **next count** and commit exactly on the threshold sample.

---

# 10. Another Important Point: Synchronization

If `in_n` originates from another clock domain or an asynchronous external source, this filter alone should **not automatically be considered a synchronizer**.

The input can potentially violate setup/hold timing of the sampling flip-flops.

A typical robust architecture would be:

```text
Asynchronous input
       │
       ▼
Synchronizer
(2 FFs, typically)
       │
       ▼
Glitch filter
       │
       ▼
Filtered output
```

So the glitch filter and CDC synchronization solve related but different problems:

* **Synchronizer:** reduces metastability propagation risk.
* **Glitch filter:** rejects short-lived sampled transitions.

---

# 11. Advantages & Limitations

### Advantages

* Parameterized stability threshold.
* Simple synchronous architecture.
* Active-low asynchronous reset.
* Saturating counter prevents unnecessary overflow.
* Filters short pulses effectively.
* Supports both assertion and release filtering.
* Testbench includes multiple directed cases.

### Limitations

* Adds latency before accepting a new level.
* Requires counter storage.
* The input should be synchronized if it is asynchronous.
* Current implementation's exact threshold latency is affected by the nonblocking-assignment timing described above.
* It does not distinguish different glitch widths within the same clock-sampling interval; a glitch entirely between clock edges may never be observed.

---

# 12. Interview Takeaways

**One-line explanation:**

> This is a parameterized synchronous glitch filter that accepts a new input level only after it remains stable for a specified number of clock samples.

### Likely interview questions

**Q: What does `STABLE_CYCLES` control?**
It determines how many stable samples are required before the output follows the input.

**Q: Why is `CW` calculated using `$clog2(THRESH+1)`?**
To provide enough counter bits to represent the threshold value itself.

**Q: Why is the counter saturating?**

```verilog
if (cnt < THRESH)
    cnt <= cnt + 1'b1;
```

Once stability has been established, there is no need to continue increasing the counter.

**Q: What happens if the input changes before reaching the threshold?**
`last` is updated to the new level and the counter restarts from 1.

**Q: Is this an asynchronous glitch filter?**
No. It is a **clock-sampled synchronous filter**.

**Q: What is the clock frequency in the TB?**

$$
T=10ns
$$

so:

$$
f_{clk}=100MHz
$$

**Q: What is the key hardware concept?**

> **Temporal qualification:** a signal transition is accepted only when it persists for the required number of clock samples.
