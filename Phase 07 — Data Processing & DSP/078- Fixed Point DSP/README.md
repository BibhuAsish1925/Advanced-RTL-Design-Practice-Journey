## 1. Circuit Overview & Applications

This is a **parameterized fixed-point DSP processing unit** supporting four operations through a 2-bit opcode:

| Opcode | Operation |
| ------ | --------- |
| `00`   | ADD       |
| `01`   | SUBTRACT  |
| `10`   | MULTIPLY  |
| `11`   | MAC       |

The design uses **signed fixed-point arithmetic** with:

```text
DATA_WIDTH    = 8
FRACTION_BITS = 4
```

So the default format is effectively **Q4.4**: 8 total bits with 4 fractional bits.

For example:

```text
2.5 → 2.5 × 16 = 40 → 8'b0010_1000
1.25 → 1.25 × 16 = 20 → 8'b0001_0100
```

### Architecture

```text
                 ┌──────────────┐
       a ───────►│              │
                 │ Fixed-Point  │
       b ───────►│  Operations  │
                 │              │
    opcode ─────►│ ADD/SUB/MUL  │
                 │     /MAC     │
                 └──────┬───────┘
                        │
                    next_result
                        │
                  ┌─────▼─────┐
                  │  Register │
                  │  result   │
                  └───────────┘
```

### Applications

* DSP datapaths
* Audio processing
* Sensor processing
* Embedded signal processing
* Image processing
* FPGA DSP accelerators
* Neural-network arithmetic

---

# 2. Circuit Working & RTL Implementation

### A. Sign extension

The inputs are extended from `DATA_WIDTH` to `OUTPUT_WIDTH`:

```systemverilog id="6g1p8h"
a_ext = {{(OUTPUT_WIDTH-DATA_WIDTH){a[DATA_WIDTH-1]}}, a};
b_ext = {{(OUTPUT_WIDTH-DATA_WIDTH){b[DATA_WIDTH-1]}}, b};
```

This preserves the sign when performing addition and subtraction.

For example, a negative 8-bit value is extended with `1`s rather than `0`s.

---

### B. Fixed-point multiplication

The multiplication produces a wider result:

```systemverilog id="w7z6pb"
mult_result = a * b;
```

If both operands have `FRACTION_BITS = 4`, their product has effectively **8 fractional bits**.

Therefore the result is shifted right by four:

```systemverilog id="1d9dbr"
mult_result >>> FRACTION_BITS
```

Conceptually:

$$
(a\times 2^F)(b\times 2^F)
=
(a b)2^{2F}
$$

and shifting right by \(F\) restores the original fixed-point scaling:

$$
\frac{ab2^{2F}}{2^F}=ab2^F
$$

So the hardware representation remains in the original fixed-point scale.

---

### C. ADD

For:

```text id="6x2h9b"
opcode = 00
```

the design performs:

```systemverilog id="c0ggme"
next_result = a_ext + b_ext;
```

Example:

$$
2.5+1.25=3.75
$$

With Q4.4 representation:

```text
2.5  → 40
1.25 → 20
3.75 → 60
```

---

### D. SUBTRACT

For:

```text id="9l1t6g"
opcode = 01
```

the operation is:

```systemverilog id="jjm2ay"
next_result = a_ext - b_ext;
```

Example:

$$
5.5-2.25=3.25
$$

---

### E. MULTIPLY

For:

```text id="t5j1fw"
opcode = 10
```

the design performs:

```systemverilog id="g8bzv7"
next_result = mult_result >>> FRACTION_BITS;
```

This restores the fixed-point scale after multiplication.

For:

$$
2.5\times1.5=3.75
$$

the expected fixed-point representation is `3.75 × 16 = 60`.

---

### F. MAC

The most interesting operation is:

```systemverilog id="5d0u7s"
next_result =
    result +
    (mult_result >>> FRACTION_BITS);
```

Therefore:

$$
result_{next}=result_{current}+(a\times b)
$$

in fixed-point representation.

The testbench verifies:

```text id="3dbqgv"
1.5 × 2.0  = 3.0
0.5 × 4.0  = 2.0
-1.0 × 1.5 = -1.5
```

giving:

$$
3.0+2.0-1.5=\boxed{3.5}
$$

---

### G. Output register

The result is registered:

```systemverilog id="8hhy9r"
always_ff @(posedge clk) begin
    if (rst)
        result <= '0;
    else if (en)
        result <= next_result;
end
```

Therefore:

* `rst=1` → result clears
* `en=1` → result updates on the clock edge
* `en=0` → result holds

The arithmetic itself is combinational; the **output interface is synchronous**.

---

# 3. Verification & Testbench

The testbench is a **self-checking fixed-point verification environment** that uses real-number calculations to construct expected fixed-point values.

### Fixed-point conversion

The function:

```systemverilog id="vqm3ic"
real_to_fixed(value)
```

performs:

$$
Fixed = Real\times2^{FRACTION\_BITS}
$$

With four fractional bits:

$$
2.5\times16=40
$$

The reverse conversion:

```systemverilog id="9d3r1g"
fixed_to_real(value)
```

is primarily used for readable simulation output.

### Tests performed

| Test                               | Purpose                         |
| ---------------------------------- | ------------------------------- |
| Addition                           | Basic fixed-point addition      |
| Subtraction                        | Fixed-point subtraction         |
| Multiplication                     | Scaling restoration             |
| Negative values                    | Signed arithmetic               |
| Negative fractional multiplication | Arithmetic-right-shift behavior |
| MAC sequence                       | Accumulation correctness        |
| Enable test                        | Output/state hold               |

### Particularly useful test

The test:

```text id="w4k4se"
-0.5 × 0.3125
```

is specifically intended to exercise the difference between **flooring and truncation toward zero** when the DUT performs an arithmetic right shift.

That is a useful fixed-point corner case.

### MAC reference model

For opcode `11`, the TB maintains:

```systemverilog id="xqtr2b"
reference_accumulator
```

and updates it with:

```systemverilog id="t0z2j9"
expected = reference_accumulator + product_fixed;
reference_accumulator = expected;
```

This provides an independent expected MAC result.

---

# 4. Advantages & Limitations

### Advantages

| Aspect                  | Description                                      |
| ----------------------- | ------------------------------------------------ |
| **Parameterized**       | Data width and fractional precision configurable |
| **Multiple operations** | ADD, SUB, MUL and MAC in one datapath            |
| **Signed arithmetic**   | Supports negative fixed-point values             |
| **Synchronous output**  | Easy integration into clocked systems            |
| **Enable control**      | Allows state/output to hold                      |
| **Self-checking TB**    | Automatically detects arithmetic errors          |

### Limitations

**1. Overflow is not detected**

The design simply stores the result in `OUTPUT_WIDTH`.

For example, an addition exceeding the representable range will wrap around rather than saturate.

A production DSP block may require:

* saturation
* overflow flag
* wider accumulator

**2. Fixed-point precision is limited**

With `FRACTION_BITS=4`, the resolution is:

$$
2^{-4}=0.0625
$$

So values that cannot be represented exactly are quantized.

**3. MAC accumulator width**

`MAC_WIDTH` is declared:

```systemverilog
localparam int MAC_WIDTH = OUTPUT_WIDTH;
```

but is not actually used separately. The accumulator is simply `result`.

For a high-precision DSP MAC, it is often preferable to have a **wider accumulator than the output** to prevent accumulated products from overflowing.

**4. Variable fixed-point scaling**

The design assumes both operands use the same `FRACTION_BITS`. This is appropriate for this architecture but would need additional scaling logic if operands had different Q formats.

**5. Arithmetic-right-shift rounding**

The multiplication uses:

```systemverilog
>>> FRACTION_BITS
```

which effectively discards fractional bits. For negative values, this corresponds to arithmetic shifting rather than rounding-to-nearest.

---

# 5. Interview Takeaways

### Key concept

> **This design implements a parameterized signed fixed-point DSP datapath supporting addition, subtraction, multiplication, and multiply-accumulate operations with configurable fractional precision.**

### Important interview questions

**Q: Why shift the multiplication result right?**
Because multiplying two fixed-point numbers doubles the number of fractional bits. The right shift restores the original fixed-point scaling.

**Q: Why use `>>>` instead of `>>`?**
`>>>` performs an arithmetic right shift and preserves the sign for signed operands.

**Q: What does `FRACTION_BITS=4` mean?**
Four bits represent the fractional portion, giving a resolution of:

$$
1/16=0.0625
$$

**Q: Why sign-extend before addition/subtraction?**
To preserve the two's-complement sign when increasing the operand width.

**Q: What is the main difference between this MAC and the previous pipelined MAC?**
This design combines **multiple selectable fixed-point operations** into one datapath and has a single registered output, whereas the previous pipelined MAC explicitly separated multiplication and accumulation into two pipeline stages.

**Q: What would you improve for a production DSP implementation?**

* Wider MAC accumulator
* Saturation/overflow detection
* Pipeline multiplier and accumulator
* Configurable rounding modes
* Efficient constant-shift implementation
* DSP-block inference on FPGA

### One-line interview explanation

> **“I implemented a parameterized signed fixed-point DSP datapath supporting ADD, SUB, MUL, and MAC operations, including fixed-point scaling restoration, sign extension, registered output, and a self-checking real-number-based verification model.”**
