# CLOCK GATING — RTL & TESTBENCH ANALYSIS

## 1. Circuit Overview & Applications

This design implements **basic combinational clock gating** using a single AND gate:

```verilog
assign gated_clk = clk & enable;
```

The behavior is:

```text
enable = 0 → gated_clk = 0
enable = 1 → gated_clk = clk
```

So the clock is directly passed or blocked based on `enable`.

### Applications

* Basic clock gating concepts
* Reducing switching activity
* Low-power digital design
* Clock control for inactive logic blocks
* Demonstrating the difference between simple and glitch-free clock gating

---

# 2. Circuit Working & RTL Implementation

The complete DUT is essentially:

```text
          ┌───────┐
clk ─────►│  AND  │────► gated_clk
          │       │
enable ──►│       │
          └───────┘
```

The RTL:

```verilog
assign gated_clk = clk & enable;
```

implements:

$$
gated\_clk = clk \land enable
$$

### Case 1 — `enable = 0`

$$
clk \land 0 = 0
$$

Therefore:

```text
gated_clk = 0
```

regardless of the input clock.

### Case 2 — `enable = 1`

$$
clk \land 1 = clk
$$

Therefore:

```text
gated_clk = clk
```

The gated clock follows the input clock.

---

# 3. Why This Is NOT Glitch-Free

The critical difference from your previous `clock_gating_glitch_free` design is that **there is no latch**.

Here:

```verilog
assign gated_clk = clk & enable;
```

means `gated_clk` responds immediately to changes in either `clk` or `enable`.

Suppose:

```text
clk = 1
enable = 1
```

then:

```text
gated_clk = 1
```

Now if `enable` changes to `0` while `clk` is still HIGH:

```text
clk          ───────────────
enable       ────────┐
                     └── 0
gated_clk    ────────┐
                     └── 0
```

The current clock pulse is cut short.

If `enable` changes back to `1` while `clk` is still HIGH, `gated_clk` immediately goes HIGH again.

This can create an unwanted pulse:

```text
clk:
───────────────

enable:
───────┐   ┌────
       └───┘

gated_clk:
───────┐ ┌─┐
       └─┘ └────
```

That is the **glitch problem**.

---

# 4. Testbench Analysis

The clock is generated using:

```verilog
always #(CLK_PERIOD/2) clk = ~clk;
```

with:

```verilog
CLK_PERIOD = 10
```

Therefore:

```text
Half-period = 5 ns
Period      = 10 ns
Frequency   = 100 MHz
```

---

## Test 1 — Start Disabled

```verilog
enable = 1'b0;
#(CLK_PERIOD*3);
```

For the first 30 ns:

```text
enable = 0
```

Therefore:

```text
gated_clk = 0
```

even though `clk` continues toggling.

---

# 5. Test 2 — Enable During LOW Phase

The TB waits for:

```verilog
@(negedge clk);
enable = 1'b1;
```

Since the enable changes when the clock is LOW:

```text
clk = 0
```

the gated clock remains LOW at that moment.

On the next rising edge:

```text
clk:       0 → 1
enable:    1
gated_clk: 0 → 1
```

So the clock starts cleanly in this particular case.

This demonstrates that **simple AND gating can appear correct when enable changes at a safe time**.

---

# 6. Test 3 — Explicit Glitch Demonstration

This is the most important test:

```verilog
@(posedge clk);
#1;
enable = 1'b0;
#1;
enable = 1'b1;
```

After the positive edge, `clk` is HIGH.

Then:

```text
t = edge + 1 ns
```

`enable` becomes `0`.

Because the DUT has no latch:

```text
gated_clk = clk & 0 = 0
```

immediately.

One nanosecond later:

```verilog
enable = 1'b1;
```

Since `clk` is still HIGH:

```text
gated_clk = 1
```

again.

So the gated clock gets a short interruption:

```text id="4eB5zE"
Normal clock:

clk       ────────────────┐       ┌────
                          └───────┘

enable:
          ────────┐   ┌──────────
                  └───┘

gated_clk:
          ────────┐ ┌─┐──────────
                  └─┘ └──────────
                    ↑
                unwanted
                short pulse
```

This is exactly what your testbench is designed to demonstrate.

---

# 7. Test 4 — Clean Disable

The TB then waits for:

```verilog
@(negedge clk);
enable = 1'b0;
```

Because the clock is LOW, disabling the gate does not truncate an active HIGH pulse.

The subsequent clock cycles are blocked:

```text
enable = 0
       ↓
gated_clk = 0
```

This is a clean transition.

---

# 8. Comparison With Your Previous Glitch-Free Version

The difference between the two designs is important:

| Feature                                 | This design   | Previous latch-based design |
| --------------------------------------- | ------------- | --------------------------- |
| Basic logic                             | AND           | Latch + AND                 |
| Enable can directly affect gated clock? | Yes           | No during CLK HIGH          |
| Glitch protection                       | ❌             | ✅                           |
| Simple                                  | Very simple   | Slightly more complex       |
| Safe enable during HIGH                 | No            | Yes                         |
| Typical clock-gating concept            | Basic         | Glitch-free                 |
| ASIC clock-gating style                 | Not preferred | Closer to ICG concept       |

### Simple AND gating

```verilog
assign gated_clk = clk & enable;
```

### Latch-based gating

```text
enable → latch → AND ← clk
```

The latch isolates the clock from enable transitions during the active HIGH phase.

---

# 9. Advantages & Limitations

### Advantages

* Extremely simple.
* Minimal logic.
* Low hardware overhead.
* Easy to understand and simulate.
* Works correctly when `enable` is guaranteed to change only during the safe clock phase.

### Limitations

* **Not glitch-free.**
* Enable transitions during HIGH can create shortened or additional clock pulses.
* Can introduce clock-quality problems.
* Not appropriate as an unrestricted production clock-gating structure.
* No reset or control mechanism is present.

---

# 10. Interview Takeaways

**One-line explanation:**

> This is basic AND-based clock gating where `gated_clk = clk & enable`; unlike latch-based clock gating, an enable transition during the HIGH phase can produce a glitch or truncated clock pulse.

### Likely interview questions

**Q: What happens when enable is 0?**

$$
gated\_clk=0
$$

The clock is blocked.

**Q: What happens when enable is 1?**

$$
gated\_clk=clk
$$

The clock passes through.

**Q: Why is this not glitch-free?**

Because `enable` directly controls the AND gate and can change while `clk` is HIGH.

**Q: What does the previous latch-based design solve?**

It ensures the gating decision is held constant throughout the HIGH phase of the clock.

**Q: What is the input clock frequency in this TB?**

$$
T=10ns
$$

so:

$$
f_{clk}=100MHz
$$

**Q: What is the main practical lesson?**

> **Never treat `clk & enable` as inherently glitch-free clock gating.** For ASIC clock gating, the enable is typically latched during the inactive clock phase and implemented using a characterized integrated clock-gating cell.
