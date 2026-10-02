## 1. Circuit Overview & Applications

This is a **parameterized synchronous FIR (Finite Impulse Response) filter** implemented using a **direct-form multiply-and-accumulate architecture**.

For `TAPS = 4`, the filter implements:

$$
y[n]=h_0x[n]+h_1x[n-1]+h_2x[n-2]+h_3x[n-3]
$$

The key convention in this implementation is:

```text
coeff[0] → current input
coeff[1] → previous sample
coeff[2] → sample from 2 cycles ago
coeff[3] → sample from 3 cycles ago
```

### Architecture

```text
                    ┌──── × coeff[0]
data_in ────────────┤
                    │
                    ├──── × coeff[1] ◄── delay[0]
                    │
                    ├──── × coeff[2] ◄── delay[1]
                    │
                    └──── × coeff[3] ◄── delay[2]
                              │
                              ▼
                       ┌────────────┐
                       │   Adder     │
                       │    Tree     │
                       └─────┬──────┘
                             │
                         data_out
```

The delay line provides the previous input samples required for convolution.

### Applications

* Digital audio filtering
* Noise reduction
* Communication systems
* Equalizers
* Sensor signal processing
* DSP accelerators
* FPGA/ASIC signal-processing datapaths

---

# 2. Circuit Working & RTL Implementation

### A. Delay line

The design stores `TAPS-1` previous samples:

```systemverilog
logic signed [DATA_WIDTH-1:0] delay_line [TAPS-1];
```

For four taps:

```text
delay_line[0] → x[n-1]
delay_line[1] → x[n-2]
delay_line[2] → x[n-3]
```

At every enabled clock:

```systemverilog
for (i = TAPS-2; i > 0; i = i - 1)
    delay_line[i] <= delay_line[i-1];

delay_line[0] <= data_in;
```

So the newest sample enters `delay_line[0]`, and older samples move toward the end.

---

### B. Parallel multiplication

The combinational block calculates all tap products:

```systemverilog
products[0] = data_in * coeff[0];
```

and:

```systemverilog
products[i] = delay_line[i-1] * coeff[i];
```

Therefore:

$$
P_0=x[n]h_0
$$

$$
P_1=x[n-1]h_1
$$

$$
P_2=x[n-2]h_2
$$

$$
P_3=x[n-3]h_3
$$

---

### C. Accumulation

The products are accumulated into `sum`:

```systemverilog
sum = products[0];

for (i = 1; i < TAPS; i = i + 1)
    sum = sum + products[i];
```

Conceptually:

$$
sum=P_0+P_1+\cdots+P_{TAPS-1}
$$

Then the result is registered:

```systemverilog
data_out <= sum;
```

This makes the filter output **synchronous**.

---

### D. Important clock behavior

A subtle but important point is that the delay line and output register are updated on the same clock edge.

Because the sequential block uses nonblocking assignments:

```systemverilog
delay_line[0] <= data_in;
data_out <= sum;
```

the `sum` used for `data_out` corresponds to the **current input plus the previous contents of the delay line**.

That is exactly what is required for:

$$
y[n]=h_0x[n]+h_1x[n-1]+\cdots
$$

The new `data_in` does not overwrite `delay_line[0]` until after `sum` has been evaluated.

---

### E. Reset and enable

When `rst=1`:

```text
delay_line → 0
data_out   → 0
```

When `en=1`:

```text
new sample → delay line
current convolution → data_out
```

When `en=0`:

```text
delay line → holds
data_out   → holds
```

Thus, disabling the filter effectively **freezes its state**.

---

# 3. Verification & Testbench

The testbench uses an **independent reference delay line** and calculates the expected FIR output before the DUT clock edge.

This is a good verification structure because the reference model does not simply reproduce the DUT's internal `products` and `sum` logic.

### Reference calculation

The TB computes:

```systemverilog
temp_sum = new_sample * coeff[0];

for (j = 1; j < TAPS; j = j + 1)
    temp_sum = temp_sum +
               (reference_delay[j-1] * coeff[j]);
```

For:

```text
h = [1, 2, 3, 4]
```

and samples:

```text
1, 2, 3, 4
```

once the pipeline is filled, the calculation becomes:

$$
y[n]=x[n]+2x[n-1]+3x[n-2]+4x[n-3]
$$

For example, with `x[n]=4`:

$$
4(1)+3(2)+2(3)+1(4)
$$

depending on the sample history and coefficient convention. The TB explicitly follows the DUT's documented convention:

```text
coeff[0] → current sample
coeff[1] → 1-cycle-old sample
coeff[2] → 2-cycle-old sample
coeff[3] → 3-cycle-old sample
```

### Tests performed

| Test                    | Purpose                            |
| ----------------------- | ---------------------------------- |
| Ramping samples `1–8`   | Normal FIR operation               |
| Negative samples        | Signed arithmetic                  |
| Mixed positive/negative | Signed multiplication/accumulation |
| `en=0`                  | State/output hold                  |
| Mid-stream reset        | State clearing                     |
| Post-reset sample       | Recovery after reset               |

### Self-checking mechanism

The testbench compares:

```systemverilog
if (data_out !== expected_result)
```

and reports either:

```text
PASS
```

or:

```text
FAIL
```

This makes the TB automatically detect incorrect DUT behavior.

---

# 4. Advantages & Limitations

### Advantages

| Feature                  | Benefit                                             |
| ------------------------ | --------------------------------------------------- |
| **Parameterized**        | Supports different data widths and tap counts       |
| **Signed arithmetic**    | Supports positive and negative coefficients/samples |
| **Direct-form FIR**      | Simple and easy-to-understand architecture          |
| **Parallel multipliers** | All tap products are calculated concurrently        |
| **Registered output**    | Provides synchronous filter output                  |
| **Enable control**       | Can freeze the filter state                         |
| **Self-checking TB**     | Automatically validates functionality               |

### Limitations

**1. Multiplier count**

For `TAPS = N`, the direct implementation requires approximately:

$$
N\text{ multipliers}
$$

For large filters, this can consume substantial FPGA DSP resources or ASIC area.

**2. Combinational critical path**

The accumulation:

```text
P0 → + → P1 → + → P2 → + → ...
```

can become long as `TAPS` increases.

A **balanced adder tree** or pipelined adder tree would improve timing.

**3. Delay-line shifting**

The current architecture shifts:

```text
delay_line[TAPS-2] ← ... ← delay_line[0]
```

every enabled cycle. For very large tap counts, a circular buffer can reduce unnecessary movement.

**4. Coefficients are runtime inputs**

The coefficients are provided through:

```systemverilog
input logic signed [COEFF_WIDTH-1:0] coeff [TAPS]
```

If the coefficients are fixed, synthesis may be able to optimize constant multiplications much more aggressively.

**5. Output width**

The expression:

```systemverilog
DATA_WIDTH + COEFF_WIDTH + $clog2(TAPS)
```

provides accumulator headroom, but width selection should still be based on the actual maximum magnitude of the signed products and their sum.

---

# 5. Interview Takeaways

### Key concept

> **A FIR filter computes a weighted sum of the current input and a finite number of previous samples. This implementation uses a delay line, parallel signed multipliers, an accumulator, and a registered output.**

### Important interview questions

**Q: Why does a FIR filter need a delay line?**
To retain previous input samples so each sample can be multiplied by its corresponding filter coefficient.

**Q: What does `TAPS=4` mean?**

It means the filter uses four coefficients and four samples:

$$
x[n],x[n-1],x[n-2],x[n-3]
$$

**Q: Why is `delay_line` only `TAPS-1` deep?**
The current sample `data_in` is directly used for `coeff[0]`. Only the previous `TAPS-1` samples need storage.

**Q: Why is `data_out` registered?**
To make the filter output synchronous and provide a sequential boundary after the combinational multiply-accumulate datapath.

**Q: How would you make this FIR faster?**
Use a **balanced adder tree**, pipeline the multiplier/adder stages, or exploit FPGA DSP blocks/ASIC MAC structures.

**Q: What happens when `en=0`?**
The delay line and output hold their previous values, so no new sample enters the filter.

**Q: Is this a complete streaming FIR implementation?**
Yes, at the basic datapath level: it has the sample delay line, coefficients, multiply-accumulate operation, and clocked output. It does not include external streaming protocol logic such as AXI-Stream.

### One-line interview explanation

> **“I implemented a parameterized signed direct-form FIR filter using a `TAPS-1` sample delay line, parallel multipliers, combinational accumulation, and a registered output, with a self-checking reference-model testbench for functional verification.”**
