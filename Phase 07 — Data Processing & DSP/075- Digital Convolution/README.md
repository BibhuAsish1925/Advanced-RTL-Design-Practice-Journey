## 1. Circuit Overview & Applications

This is a **parameterized combinational digital convolution engine** that computes the sum of element-wise products between an input data vector and a coefficient vector.

For `TAPS = 4`:

$$
result = \sum_{i=0}^{3} data\_in[i]\times coeff[i]
$$

Architecture:

```text
data_in[0] ─×─ coeff[0] ─┐
data_in[1] ─×─ coeff[1] ─┤
data_in[2] ─×─ coeff[2] ─┤──► Adder ──► result
data_in[3] ─×─ coeff[3] ─┘
```

This is essentially the **multiply-and-accumulate structure of a FIR filter**, although this module itself has no delay line or clocked sample history.

### Applications

* FIR/digital filters
* DSP datapaths
* Audio processing
* Image processing
* Neural-network computations
* Correlation/convolution kernels
* Hardware accelerators

---

## 2. Circuit Working & RTL Implementation

### Parameterization

The design supports:

```text
DATA_WIDTH   = 8
COEFF_WIDTH  = 8
TAPS         = 4
OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + clog2(TAPS)
```

With the defaults:

```text
8-bit data × 8-bit coefficient → 16-bit product
4 products → 18-bit result
```

The extra `$clog2(TAPS)` bits provide additional accumulator headroom.

### Multiplication stage

Inside the `always_comb` block:

```systemverilog
products[i] = data_in[i] * coeff[i];
```

Each input sample is multiplied by its corresponding coefficient.

For example:

```text
data = [1, 2, 3, 4]
coeff = [1, 1, 1, 1]

products = [1, 2, 3, 4]
```

### Accumulation

The products are accumulated sequentially in the combinational process:

```systemverilog
sum = sum + products[i];
```

Therefore:

$$
sum = P_0+P_1+P_2+\cdots+P_{TAPS-1}
$$

Finally:

```systemverilog
result = sum;
```

There are **no registers or clock signals**, so the result changes combinationally whenever the inputs or coefficients change.

### Important hardware interpretation

Although the RTL uses a `for` loop, this does **not** mean the hardware performs the operations over multiple clock cycles.

For `TAPS=4`, synthesis conceptually creates:

```text
4 multipliers
     +
adder network
     ↓
  result
```

The exact synthesized adder structure depends on the synthesis tool and optimization settings.

---

## 3. Verification & Testbench

The testbench uses a **self-checking reference model**.

The reference calculation is:

```systemverilog
product = data_in[j] * coeff[j];
temp_sum = temp_sum + product;
```

The DUT result is then compared against:

```systemverilog
expected_result
```

using:

```systemverilog
if (result !== expected_result)
```

This is preferable to simply displaying the result because the testbench can automatically detect failures.

### Tests performed

| Test   | Purpose                          |
| ------ | -------------------------------- |
| Test 1 | Basic positive-value convolution |
| Test 2 | Different coefficients           |
| Test 3 | Larger positive values           |
| Test 4 | Zero coefficients                |
| Test 5 | Signed/negative values           |

### Test 1

```text
Data   = [1,2,3,4]
Coeff  = [1,1,1,1]

Result = 1+2+3+4 = 10
```

### Test 2

```text
Data   = [2,4,6,8]
Coeff  = [1,2,3,4]

Result = 2 + 8 + 18 + 32
       = 60
```

### Test 3

```text
Data   = [10,20,30,40]
Coeff  = [4,3,2,1]

Result = 40 + 60 + 60 + 40
       = 200
```

### Test 4

All coefficients are zero, so:

```text
Result = 0
```

### Test 5

The signed test is particularly useful because the DUT explicitly declares both arrays as `logic signed`.

Products are:

```text
(-2) ×  2 = -4
 3  × (-1) = -3
(-4) ×  3 = -12
 5  × (-2) = -10
```

Therefore:

$$
result=-4-3-12-10=\boxed{-29}
$$

The testbench checks this automatically.

### Verification strength

The TB is good for a basic module because it has:

* Directed tests
* Signed-value testing
* Zero-coefficient corner case
* Independent reference calculation
* Automatic PASS/FAIL checking
* `$finish`

For stronger verification, you could add **randomized tests and exhaustive tests for reduced parameter widths**.

---

## 4. Advantages & Limitations

### Advantages

| Aspect                   | Description                                         |
| ------------------------ | --------------------------------------------------- |
| **Parameterized**        | Data, coefficient and number of taps can be changed |
| **Signed arithmetic**    | Supports positive and negative values               |
| **Combinational**        | No clock or control logic required                  |
| **Parallel computation** | Products can be calculated concurrently             |
| **Reusable**             | Suitable as a DSP/accelerator building block        |

### Limitations

**1. Large hardware for high `TAPS`**

Increasing `TAPS` increases the number of multipliers and adders:

```text
TAPS = 4   → 4 multipliers
TAPS = 16  → 16 multipliers
TAPS = 64  → 64 multipliers
```

This can significantly increase area and power.

**2. Long combinational path**

A large number of multiplications and additions can create a long critical path, limiting maximum frequency.

A practical implementation could use:

```text
Multiplier → Register → Adder → Register → ...
```

or a **balanced adder tree**.

**3. No pipelining**

The current design is completely combinational. For high-speed DSP hardware, pipelining would usually be considered.

**4. No actual sample-delay line**

Despite the name convolution, this module only calculates:

$$
\sum data[i]\times coeff[i]
$$

It does not contain the sequential delay elements normally found in a streaming FIR convolution implementation.

---

## 5. Interview Takeaways

### Key concept

> **This RTL implements a parameterized combinational sum-of-products datapath, which forms the computational core of digital convolution and FIR filtering.**

### Important interview questions

**Q: Why is `always_comb` used?**
Because the output depends combinationally on the current inputs and coefficients and there is no clocked state.

**Q: What does the `for` loop synthesize into?**
Parallel multiplier and adder hardware, not sequential software-style iterations.

**Q: Why is `OUTPUT_WIDTH` larger than the product width?**
Multiple products are accumulated, so additional bits are required to reduce overflow risk.

**Q: Why are `data_in` and `coeff` declared `signed`?**
To correctly represent negative samples and coefficients and perform signed multiplication.

**Q: How would you improve timing for many taps?**
Use a **balanced adder tree and pipeline registers** rather than a long serial accumulation path.

**Q: Is this a complete FIR filter?**
No. It implements the **sum-of-products/convolution kernel**. A streaming FIR additionally requires a sample delay line and usually clocked state.

### One-line interview explanation

> “I implemented a parameterized signed convolution datapath using parallel multipliers and accumulation, with configurable data, coefficient, tap, and output widths and a self-checking SystemVerilog reference-model testbench.”
