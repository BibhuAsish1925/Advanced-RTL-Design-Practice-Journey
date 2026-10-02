# PARAMETERIZED MAC (MULTIPLY-ACCUMULATE) UNIT

## 1. Circuit Overview & Applications

This design implements a **Multiply-Accumulate (MAC) unit**, a fundamental datapath used to perform repeated:

**Multiply → Add → Accumulate**

operations.

* **Data width:** 8 bits
* **Product width:** 16 bits
* **Accumulator width:** 32 bits
* **Reset:** Synchronous active-high
* **Enable:** `en`
* **Operation:** `acc = acc + (a × b)`
* **Latency:** One clock cycle per MAC operation

### Applications

* DSP datapaths
* FIR/IIR filters
* Digital signal processing
* Neural-network accelerators
* Image processing
* Matrix multiplication
* Audio/video processing
* FPGA/ASIC arithmetic units

---

## 2. Circuit Working & RTL Implementation

### A. Multiplication

The product is generated combinationally:

```systemverilog
assign product = a * b;
```

With `DATA_WIDTH=8`:

```text
8-bit A × 8-bit B → 16-bit Product
```

The maximum unsigned product is:

```text
255 × 255 = 65025
```

which fits in 16 bits.

### B. Accumulation

On every rising clock edge:

```systemverilog
if (rst)
    acc <= '0;
else if (en)
    acc <= acc + product;
```

Therefore:

```text
                ┌─────────────┐
a ─────────────>│             │
                │ Multiplier  │─── product ──┐
b ─────────────>│             │              │
                └─────────────┘              ▼
                                         ┌────────┐
                                  acc ───>│  ADD   │
                                         └───┬────┘
                                             │
                                             ▼
                                         ACCUMULATOR
```

When `en=1`:

```text
ACC_next = ACC_current + (A × B)
```

When `en=0`, there is no assignment to `acc`, so it retains its previous value.

### C. Reset

The reset is synchronous because it appears only in:

```systemverilog
always_ff @(posedge clk)
```

When `rst=1` at a rising edge:

```text
acc = 0
```

---

## 3. Verification & Testbench

The testbench uses a **10 ns clock period**:

```text
Clock frequency = 100 MHz
```

The `apply_mac` task independently calculates the expected product:

```systemverilog
product_temp = a_in * b_in;
```

and updates the reference accumulator:

```systemverilog
expected_acc = expected_acc + product_temp;
```

The following operations are tested:

|  A |  B | Product | Expected ACC |
| -: | -: | ------: | -----------: |
|  5 |  3 |      15 |           15 |
| 10 |  2 |      20 |           35 |
|  7 |  4 |      28 |           63 |
| 12 |  5 |      60 |          123 |
| 20 | 10 |     200 |          323 |

After every operation, the TB compares:

```systemverilog
if (acc !== expected_acc)
```

Therefore this is a **self-checking testbench**.

### Enable test

The TB then sets:

```systemverilog
en = 1'b0;
```

while applying:

```text
A = 100
B = 100
```

Since the enable is LOW, the accumulator should remain:

```text
323
```

The testbench explicitly checks this condition.

### Verification coverage

The TB verifies:

* ✅ Reset to zero
* ✅ Multiple MAC operations
* ✅ Accumulation across cycles
* ✅ Correct multiplication
* ✅ Correct accumulator update
* ✅ Enable functionality
* ✅ Accumulator hold when disabled
* ✅ Automatic PASS/FAIL checking

---

## 4. Advantages & Limitations

### Advantages

* Simple and reusable datapath block.
* Parameterized input and accumulator widths.
* Uses one multiplier and one accumulator.
* `en` allows controlled accumulation.
* Self-checking verification environment.
* Directly applicable to DSP and AI datapaths.

### Limitations

* The multiplier is combinational, so its delay can affect the maximum clock frequency.
* A larger `DATA_WIDTH` increases multiplier area and delay.
* Accumulator overflow is possible if `ACC_WIDTH` is insufficient.
* The current implementation treats `a` and `b` as **unsigned** values.
* No saturation or overflow detection is implemented.

### Important width consideration

For the default configuration:

```text
8 × 8 → 16-bit product
```

but the accumulator is 32 bits:

```text
32-bit accumulator
```

So the design can accumulate many products before overflowing, but the exact safe number depends on the input range and whether the accumulated result exceeds `2^32-1`.

---

## 5. Interview Takeaways

**One-line explanation:**

> A MAC unit multiplies two input operands and accumulates the product into a register on each enabled clock cycle.

The core equation is:

```text
ACC[n+1] = ACC[n] + A[n] × B[n]
```

### Why MAC units are important

MAC operations are the basic computational kernel of many DSP algorithms:

```text
FIR filter:
y[n] = Σ h[k] × x[n-k]
```

A MAC can therefore repeatedly perform the multiply-and-add operations required by such algorithms.

### Key hardware trade-off

```text
Larger multiplier width
        ↓
Higher precision
        ↓
More area + potentially longer timing path
```

For high-performance implementations, MACs are commonly optimized using **pipelining, DSP blocks, parallelism, or fused multiply-accumulate hardware**.
