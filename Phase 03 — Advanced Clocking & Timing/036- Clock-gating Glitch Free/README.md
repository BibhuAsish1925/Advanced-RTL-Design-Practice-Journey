# GLITCH-FREE CLOCK GATING — RTL & TESTBENCH ANALYSIS

## 1. Circuit Overview & Applications

This design implements **glitch-free clock gating** using a level-sensitive latch and an AND gate.

The basic idea is:

> The `enable` signal is allowed to change the gating decision only while the clock is LOW. Once the clock becomes HIGH, the latch holds its value, preventing `enable` transitions from creating glitches on the gated clock.

Architecture:

```text
                 ┌─────────────────┐
enable ─────────►│ Enable Latch    │
                 │ transparent     │
                 │ when clk = 0    │
                 └────────┬────────┘
                          │ enable_latch
                          ▼
clk ─────────────────────►AND ─────► gated_clk
```

### Applications

* Dynamic power reduction
* Clock gating in low-power ASIC designs
* Disabling inactive datapaths
* Processor/peripheral clock control
* Power-management structures

---

# 2. Circuit Working & RTL Implementation

## Enable Latch

The internal storage element is:

```verilog
reg enable_latch;
```

The latch is described by:

```verilog
always @(clk or enable)
begin
    if(!clk) begin
        enable_latch = enable;
    end
end
```

This is a **level-sensitive latch**.

### When `clk = 0`

The latch is transparent:

```text
enable_latch = enable
```

Therefore, changes in `enable` can propagate into `enable_latch`.

### When `clk = 1`

The `if(!clk)` condition is false, so there is no assignment.

The latch therefore **holds its previous value**.

Conceptually:

```text
clk = 0 → latch follows enable
clk = 1 → latch holds enable_latch
```

---

# 3. Why This Prevents Clock Glitches

The gated clock is:

```verilog
assign gated_clk = enable_latch & clk;
```

The important timing relationship is:

```text
             CLK LOW              CLK HIGH
             ────────             ─────────
enable       can change           can change,
                                  but ignored by latch

enable_latch follows enable      HOLD

gated_clk    LOW                  either follows CLK
                                  or remains LOW
```

Suppose `enable` changes while `clk` is HIGH:

```text
clk          ──────────────
enable       ────0────1────
```

The latch is closed during the HIGH phase, so:

```text
enable_latch does NOT change
```

Therefore the AND gate cannot create a mid-cycle transition in `gated_clk`.

This is the essential principle of **glitch-free clock gating**.

---

# 4. Clock Gating Operation

### Enable = 0

When the latch captures:

```text
enable_latch = 0
```

then:

$$
gated\_clk=0\land clk=0
$$

So the clock is blocked.

### Enable = 1

When the latch captures:

```text
enable_latch = 1
```

then:

$$
gated\_clk=1\land clk=clk
$$

So:

```text
gated_clk = clk
```

The gated clock therefore either:

```text
stays LOW
```

or:

```text
follows the original clock
```

with the gating decision changing only during the safe LOW phase.

---

# 5. Testbench Analysis

The testbench uses:

```verilog
localparam CLK_PERIOD = 10;
```

and:

```verilog
always #(CLK_PERIOD/2) clk = ~clk;
```

Therefore:

```text
Half-period = 5 ns
Period      = 10 ns
Frequency   = 100 MHz
```

---

## Test 1 — Clock Disabled

```verilog
enable = 1'b0;
#(CLK_PERIOD*3);
```

The expected result is:

```text
enable_latch = 0
gated_clk    = 0
```

even though the input clock continues toggling.

---

## Test 2 — Enable During LOW Phase

The TB waits for:

```verilog
@(negedge clk);
enable = 1'b1;
```

At the negative edge, the clock has entered its LOW phase.

Therefore the latch can capture:

```text
enable_latch = 1
```

During subsequent HIGH phases:

```text
gated_clk follows clk
```

So the clock resumes cleanly.

---

# 6. Test 3 — Enable Changes During HIGH Phase

The testbench deliberately performs:

```verilog
@(posedge clk);
#1;
enable = 1'b0;
```

This changes `enable` **one nanosecond after the rising edge**, while `clk` is still HIGH.

Because the latch is closed:

```text
clk = 1
```

the internal `enable_latch` remains:

```text
enable_latch = 1
```

Therefore the current high pulse is not truncated.

The gated clock remains HIGH until the normal falling edge.

Once `clk` goes LOW, the latch becomes transparent and captures the new:

```text
enable = 0
```

This is the key **glitch-free test** in your TB.

---

# 7. Test 4 — Re-enable During LOW Phase

The TB then waits for:

```verilog
@(negedge clk);
enable = 1'b1;
```

Again, the enable changes during the safe LOW phase.

The latch captures it, and the gated clock resumes on a subsequent complete HIGH phase.

This verifies that gating can be stopped and restarted without producing partial clock pulses.

---

# 8. Advantages & Limitations

### Advantages

* Prevents glitches caused by enable transitions during the active clock phase.
* Simple latch + AND implementation.
* Reduces switching activity in downstream logic when disabled.
* Widely representative of the basic principle behind integrated clock-gating structures.
* Testbench specifically exercises enable transitions in both safe and unsafe phases.

### Limitations

* The RTL does not contain a reset for `enable_latch`.
* At time zero, `enable_latch` can initially be `X` until the latch becomes transparent and `enable` is evaluated.
* The latch itself has timing requirements around the closing edge of the clock.
* For ASIC implementation, standard-cell **integrated clock-gating (ICG)** cells are generally preferred over manually constructing clock-gating logic.
* Gated clocks require proper clock-tree/timing treatment during physical implementation.

---

# 9. Important RTL Observation

Your latch uses:

```verilog
always @(clk or enable)
```

This is an older explicit sensitivity-list style.

For this particular two-input combinational/latch behavior, it is functionally appropriate because both signals that affect the latch are included.

The latch uses a **blocking assignment**:

```verilog
enable_latch = enable;
```

which is conventional for modeling combinational/latch behavior in this style.

The key inference is the absence of an `else` assignment:

```verilog
if(!clk)
    enable_latch = enable;
```

When `clk=1`, the value must be retained, causing synthesis to infer a latch.

---

# 10. Verification Summary

Your TB checks four important behaviors:

| Test | Enable transition | Expected behavior              |
| ---- | ----------------- | ------------------------------ |
| 1    | Disabled          | `gated_clk` stays LOW          |
| 2    | During LOW        | Clock starts cleanly           |
| 3    | During HIGH       | Current pulse is not truncated |
| 4    | During LOW        | Clock resumes cleanly          |

The most important verification case is **Test 3**, because it demonstrates the actual reason for using a latch-based clock-gating structure.

---

# 11. Interview Takeaways

**One-line explanation:**

> Glitch-free clock gating uses a latch that captures `enable` only while the clock is LOW, followed by an AND gate, preventing enable changes during the HIGH phase from creating malformed clock pulses.

### Likely interview questions

**Q: Why can't we simply write `assign gated_clk = clk & enable`?**

Because if `enable` changes while `clk` is HIGH, `gated_clk` can transition in the middle of the clock pulse, creating a glitch or shortened clock pulse.

**Q: Why is the latch transparent when `clk=0`?**

LOW is the safe phase in this active-high clock-gating arrangement. The enable decision is allowed to settle before the next rising edge.

**Q: What happens when enable changes while CLK is HIGH?**

The latch is closed, so `enable_latch` does not change until CLK goes LOW.

**Q: What hardware does this infer?**

A **level-sensitive latch + AND gate**.

**Q: What is the main ASIC implementation practice?**

Use a characterized **integrated clock-gating (ICG) cell** rather than arbitrary RTL clock-gating logic, so the implementation and timing tools can properly handle clock-gating checks and clock-tree integration.
