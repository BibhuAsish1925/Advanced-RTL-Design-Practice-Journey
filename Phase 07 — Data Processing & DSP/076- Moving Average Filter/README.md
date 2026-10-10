## 1. Circuit Overview & Applications

This is a **parameterized moving-average digital filter** that calculates the average of the most recent `WINDOW_SIZE` input samples.

For the default 4-sample window:

$$
y[n]=\frac{x[n]+x[n-1]+x[n-2]+x[n-3]}{4}
$$

Instead of summing all samples every cycle, the RTL uses a **running-sum optimization**:

```text
              ┌───────────────┐
data_in ─────►│               │
              │  Running Sum  │──► / WINDOW_SIZE ─► data_out
oldest ──────►│               │
              └───────────────┘
                    ▲
                    │
             Sample Buffer
```

The sample buffer stores the previous `WINDOW_SIZE` samples.

### Applications

* Sensor-data smoothing
* Audio filtering
* Noise reduction
* ADC data processing
* Embedded DSP
* Low-pass filtering
* Digital signal conditioning

---

## 2. Circuit Working & RTL Implementation

### Sample buffer

```systemverilog
logic [DATA_WIDTH-1:0] sample_buffer [WINDOW_SIZE];
```

The buffer stores the current window.

For `WINDOW_SIZE=4`:

```text
sample_buffer[0] = newest sample
sample_buffer[1] = previous sample
sample_buffer[2] = older sample
sample_buffer[3] = oldest sample
```

The oldest sample is:

```systemverilog
assign oldest_sample = sample_buffer[WINDOW_SIZE-1];
```

### Running-sum optimization

The key operation is:

```systemverilog
sum <= sum + data_in - oldest_sample;
```

Instead of calculating:

$$
x[n]+x[n-1]+x[n-2]+x[n-3]
$$

from scratch every cycle, it performs:

$$
S_{new}=S_{old}+x[n]-x[n-W]
$$

where `x[n-W]` is the sample leaving the window.

This reduces the amount of addition hardware required.

### Buffer shifting

```systemverilog
for (i = WINDOW_SIZE-1; i > 0; i = i - 1)
    sample_buffer[i] <= sample_buffer[i-1];

sample_buffer[0] <= data_in;
```

So a new sample enters at index `0`, while existing samples move toward the oldest position.

### Average calculation

The design calculates:

```systemverilog
data_out <= (sum + data_in - oldest_sample)
            / WINDOW_SIZE;
```

Notice that it uses the **new running sum expression**, rather than the old `sum`.

This is important because `sum <= ...` is a nonblocking assignment. Without this expression, `data_out` would use the previous sum and be one sample behind.

For `WINDOW_SIZE=4`:

$$
data\_out=\frac{S_{new}}{4}
$$

The division is implemented as combinational division by a parameterized constant. For powers of two such as 4, synthesis can generally optimize this to a shift.

### Reset

Reset clears:

* `sum`
* `data_out`
* every element of `sample_buffer`

Therefore, the filter starts with a zero-filled window.

### Enable

When:

```systemverilog
en = 0
```

the entire filter state holds:

```text
sum          → holds
sample_buffer → holds
data_out     → holds
```

The input sample is therefore **not incorporated into the window**.

---

## 3. Verification & Testbench

The testbench uses an **independent reference model** rather than reproducing the DUT's running-sum optimization.

This is a good verification approach.

The reference model:

```systemverilog
for (j = WINDOW_SIZE-1; j > 0; j = j - 1)
    reference_buffer[j] = reference_buffer[j-1];

reference_buffer[0] = sample;
```

then performs a complete summation:

```systemverilog
reference_sum = 0;

for (j = 0; j < WINDOW_SIZE; j = j + 1)
    reference_sum = reference_sum + reference_buffer[j];
```

and calculates:

```systemverilog
expected_average = reference_sum / WINDOW_SIZE;
```

So the reference model independently verifies whether the DUT's optimized running-sum implementation produces the correct result.

### Test coverage

| Test             | Purpose                               |
| ---------------- | ------------------------------------- |
| Ramping input    | Checks normal moving-average behavior |
| Constant `100`   | Checks steady-state convergence       |
| `en=0`           | Confirms state/output hold            |
| Re-enable        | Confirms previous window is preserved |
| Mid-stream reset | Confirms complete state clearing      |
| Post-reset input | Confirms correct restart              |

### Example

For:

```text
10, 20, 30, 40
```

the 4-sample average becomes:

$$
\frac{10+20+30+40}{4}=25
$$

Next sample `50` produces:

$$
\frac{20+30+40+50}{4}=35
$$

The running-sum implementation performs this efficiently:

```text
Old sum = 100
New sum = 100 + 50 - 10
        = 140

Average = 140 / 4
        = 35
```

### Enable test

The TB applies `200` while `en=0`.

Because the filter is disabled:

```text
200 is NOT inserted into the buffer
```

and `data_out` remains unchanged.

The subsequent `90` sample therefore operates on the previously preserved window.

### Reset test

The TB asserts reset during operation and checks:

```systemverilog
if (data_out !== 0)
```

It then clears the reference model as well and verifies that normal filtering resumes.

---

## 4. Advantages & Limitations

### Advantages

| Aspect                     | Description                                                                |
| -------------------------- | -------------------------------------------------------------------------- |
| **Efficient accumulation** | Adds new sample and removes oldest instead of re-summing the entire window |
| **Parameterized**          | Data width and window size are configurable                                |
| **Low-pass behavior**      | Smooths short-term input variations                                        |
| **Synchronous**            | Easy integration into clocked datapaths                                    |
| **Enable support**         | Allows filtering to pause without losing state                             |
| **Self-checking TB**       | Independently verifies the optimized implementation                        |

### Limitations

**1. Buffer shifting**

Every enabled cycle shifts the entire sample buffer:

```text
WINDOW_SIZE-1 assignments
```

For a large window, this creates unnecessary data movement.

A **circular/ring buffer** could avoid physically shifting every sample.

**2. Division hardware**

```systemverilog
/ WINDOW_SIZE
```

can synthesize into division logic when `WINDOW_SIZE` is not a convenient constant.

For powers of two:

```text
WINDOW_SIZE = 4  → >> 2
WINDOW_SIZE = 8  → >> 3
WINDOW_SIZE = 16 → >> 4
```

which is much cheaper.

**3. Integer truncation**

The average uses integer division, so fractional results are discarded.

For example:

$$
7/4=1
$$

rather than `1.75`.

**4. Unsigned samples**

The current implementation uses:

```systemverilog
logic [DATA_WIDTH-1:0]
```

so it is designed for **unsigned input data**. A signed moving-average filter would require signed declarations and appropriate signed arithmetic.

**5. Sum-width consideration**

The default:

```text
SUM_WIDTH = DATA_WIDTH + clog2(WINDOW_SIZE)
```

is appropriate for many power-of-two window sizes, but the exact maximum representable sum should be considered carefully for arbitrary `WINDOW_SIZE`.

---

## 5. Interview Takeaways

### Key concept

> **A moving-average filter smooths input data by averaging a sliding window of samples; this implementation improves hardware efficiency using a running sum.**

### Important interview questions

**Q: Why not add all samples every cycle?**
Because that requires `WINDOW_SIZE` additions every cycle. The running-sum method only adds the new sample and subtracts the outgoing sample.

**Q: What is the running-sum equation?**

$$
S_{new}=S_{old}+x[n]-x[n-W]
$$

**Q: Why does `data_out` use `sum + data_in - oldest_sample` instead of simply `sum / WINDOW_SIZE`?**
Because `sum` is updated with a nonblocking assignment, so the current `sum` inside the same clocked block is still the old value.

**Q: What happens when `en=0`?**
The buffer, sum, and output all hold their previous values.

**Q: How would you optimize a large window?**
Replace the shifting buffer with a **circular buffer**, reducing data movement from `O(W)` to `O(1)` per sample.

**Q: How would you improve timing?**
Pipeline the datapath and/or optimize the division. For power-of-two windows, implement division as a right shift.

### One-line interview explanation

> **“I implemented a parameterized synchronous moving-average filter using a sample buffer and running-sum update, reducing each window update to one addition and one subtraction instead of recomputing the complete sum.”**
