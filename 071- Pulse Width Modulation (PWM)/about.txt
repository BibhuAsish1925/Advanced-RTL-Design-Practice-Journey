# 8-BIT PARAMETERIZED PWM GENERATOR

## 1. Circuit Overview & Applications

This design implements a **parameterized Pulse-Width Modulation (PWM) generator** using a free-running digital counter and a duty-cycle comparator.

* **Default counter width:** 8 bits
* **Counter range:** 0–255
* **PWM period:** 256 clock cycles
* **Duty-cycle input:** `duty_cycle`
* **Reset:** Synchronous active-high
* **Output:** `pwm_out`
* **Architecture:** Counter + magnitude comparator

### Applications

* Motor-speed control
* LED brightness control
* Power-converter control
* Servo/control systems
* Digital signal generation
* FPGA/ASIC control logic

---

## 2. Circuit Working & RTL Implementation

### A. Counter

The internal counter is:

```systemverilog
logic [COUNTER_WIDTH-1:0] counter;
```

It increments on every rising edge of `clk`:

```systemverilog
counter <= counter + 1'b1;
```

For the default 8-bit configuration:

```text
0 → 1 → 2 → ... → 254 → 255 → 0 → ...
```

The overflow naturally wraps around because the counter is only 8 bits wide.

Therefore, one PWM period contains:

```text
2^8 = 256 clock cycles
```

---

### B. Duty-Cycle Generation

The key comparison is:

```systemverilog
pwm_out = (counter < duty_cycle);
```

Therefore, while the counter is below the programmed duty-cycle value, the output is HIGH.

For an 8-bit counter:

| `duty_cycle` | Approx. duty cycle |
| -----------: | -----------------: |
|          `0` |                 0% |
|         `64` |                25% |
|        `128` |                50% |
|        `192` |                75% |
|        `255` |             ~99.6% |

The conceptual waveform is:

```text
Counter:  0 ────────────────> 255
           │
PWM:       ████████__________
           HIGH     LOW
```

The PWM frequency is:

```text
f_PWM = f_clk / 256
```

for the default 8-bit counter.

More generally:

```text
f_PWM = f_clk / 2^COUNTER_WIDTH
```

---

### C. Reset Behavior

The counter is reset synchronously:

```systemverilog
always_ff @(posedge clk) begin
    if (rst)
        counter <= '0;
```

The output is also forced LOW while reset is asserted:

```systemverilog
if (rst)
    pwm_out = 1'b0;
```

So reset produces a deterministic LOW PWM output.

---

## 3. Verification & Testbench

The TB generates a **10 ns clock period**:

```systemverilog
forever #5 clk = ~clk;
```

Therefore:

```text
Clock frequency = 100 MHz
```

With an 8-bit counter:

```text
PWM frequency = 100 MHz / 256
              ≈ 390.625 kHz
```

### Test procedure

The TB first applies reset:

```systemverilog
rst = 1'b1;
```

After two clock cycles, reset is released.

It then tests:

```text
25% → duty = 64
50% → duty = 128
75% → duty = 192
```

The task:

```systemverilog
test_duty_cycle()
```

counts the number of HIGH samples during **256 clock cycles**.

For example:

```text
25%:
HIGH ≈ 64 / 256

50%:
HIGH ≈ 128 / 256

75%:
HIGH ≈ 192 / 256
```

The `#1` delay after each positive edge:

```systemverilog
@(posedge clk);
#1;
```

allows the nonblocking counter update and combinational PWM calculation to settle before sampling.

### Verification strength

This is a useful **measurement-based testbench**, but it does not automatically issue PASS/FAIL based on tolerance. It simply displays:

```text
Duty Setting = ...
HIGH Cycles  = ...
Total        = 256
```

A stronger self-checking TB could calculate the expected high count and compare it with `high_count`.

---

## 4. Advantages & Limitations

### Advantages

* Very simple PWM architecture.
* Fully synthesizable.
* Parameterized counter resolution.
* No multiplication/division required.
* Duty cycle can be changed dynamically.
* Suitable for FPGA and ASIC digital control logic.

### Limitations

* PWM frequency decreases as counter width increases.
* Resolution and frequency trade off against each other.
* Current design has no separate enable.
* Duty-cycle changes are applied directly and can potentially alter the waveform during an active PWM period.
* The testbench measures duty cycle but does not automatically flag incorrect results.

### Important RTL observation

The PWM output is generated using `always_comb`, while the counter is sequential. This is a clean separation:

```text
Clock
  │
  ▼
Counter ──────┐
              │
Duty Cycle ───┤ Comparator
              ▼
           pwm_out
```

---

## 5. Interview Takeaways

**One-line explanation:**

> A counter-based PWM generator compares a free-running counter against a programmable duty-cycle value, producing a HIGH output while `counter < duty_cycle`.

### Key formula

For an `N`-bit counter:

```text
PWM frequency = Clock frequency / 2^N
```

and the duty-cycle resolution is:

```text
1 / 2^N
```

For this 8-bit implementation:

```text
Resolution = 1/256 ≈ 0.39%
```

### Important interview trade-off

**Increasing counter width:**

* Improves duty-cycle resolution
* Decreases PWM frequency for the same clock

So PWM design involves a direct **frequency vs. resolution trade-off**.
