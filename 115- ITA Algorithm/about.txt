## 1. Circuit Overview & Applications

This design implements a **combinational GF(2⁸) multiplicative inverse**, using the AES irreducible polynomial:

$$
x^8+x^4+x^3+x+1
$$

The inverse is calculated as:

$$
a^{-1}=a^{254}
$$

for non-zero `a`.

The design contains:

* `gf_mult()` — GF(2⁸) multiplication with modular reduction
* `gf_square()` — GF(2⁸) squaring
* Repeated squaring to generate `a²` through `a¹²⁸`
* Multiplication chain to obtain `a²⁵⁴`
* Explicit handling of `a = 0`

### Applications

This is directly relevant to **AES hardware**, particularly the mathematical operation underlying the **AES S-box**.

It is also useful for studying:

* Finite-field arithmetic
* Cryptographic hardware
* AES datapaths
* Combinational arithmetic architectures
* GF(2⁸) multiplier design

---

## 2. Circuit Working & RTL Implementation

### GF(2⁸) multiplication

The core operation is:

```systemverilog id="q5h1r9"
function automatic [7:0] gf_mult;
```

The algorithm processes all 8 bits of `y`.

When `y[i] = 1`:

```systemverilog id="t1c0fs"
product = product ^ temp;
```

Because GF(2⁸) has characteristic 2:

> **Addition = XOR**

The `temp` value is then multiplied by `x`. If its MSB is set, reduction by the AES polynomial is performed:

```systemverilog id="2r6y3k"
if (temp[7])
  temp = (temp << 1) ^ 8'h1B;
else
  temp = temp << 1;
```

So this is a **carry-less multiplication followed by modular reduction**.

### Squaring chain

The design generates:

```text id="j8uj7d"
a
│
├── a²
│
├── a⁴
│
├── a⁸
│
├── a¹⁶
│
├── a³²
│
├── a⁶⁴
│
└── a¹²⁸
```

using repeated GF squaring.

### Obtaining the inverse

Since:

$$
254=128+64+32+16+8+4+2
$$

the design calculates:

```text id="4xv0n9"
a¹²⁸ × a⁶⁴ × a³² × a¹⁶ × a⁸ × a⁴ × a²
```

which produces:

$$
a^{254}=a^{-1}
$$

for every non-zero element of GF(2⁸).

For zero:

```systemverilog id="v8o4ft"
assign inv = (a == 8'h00) ? 8'h00 : m6;
```

so the design follows the AES convention:

```text
Inv(00) = 00
```

---

## 3. Verification & Testbench

The testbench uses a reusable task:

```systemverilog id="i5m5mj"
task automatic check_inverse(
  input [7:0] test_a,
  input [7:0] expected_inv
);
```

This makes each test concise and consistent.

### Tested cases

| Input | Expected inverse |
| ----- | ---------------- |
| `00`  | `00`             |
| `01`  | `01`             |
| `02`  | `8D`             |
| `03`  | `F6`             |
| `53`  | `CA`             |
| `CA`  | `53`             |
| `FF`  | `1C`             |
| `10`  | `E1`             |
| `20`  | `A0`             |

The testbench therefore covers:

* Zero special case
* Multiplicative identity
* Several known GF(2⁸) inverse values
* Reciprocal pair `53 ↔ CA`
* Additional arbitrary non-zero values

The `#10` delay allows the combinational DUT to settle before comparison.

### Verification quality

For a small combinational cryptographic block, this is a good **directed sanity test**, but it is not exhaustive.

A stronger verification approach would test all:

```text
256 possible input values
```

and either compare against a reference model or verify:

$$
a \times inv = 1
$$

for every non-zero `a`.

That would provide much stronger confidence than checking only nine values.

---

## 4. Advantages & Limitations

### Advantages

* ✅ Pure combinational GF(2⁸) implementation
* ✅ Parameter-free AES-compatible field
* ✅ Carry-less multiplication
* ✅ Correct modular reduction approach
* ✅ Repeated-squaring exponentiation
* ✅ Explicit zero handling
* ✅ Uses synthesizable SystemVerilog functions
* ✅ Good cryptographic RTL practice example
* ✅ Testbench includes known AES field inverses

### Limitations

**1. Large combinational logic**

The design performs:

* 7 GF squaring operations
* 6 GF multiplications

Because each `gf_mult` itself contains an 8-iteration loop, synthesis can produce a relatively large combinational network.

For high-performance AES hardware, optimized inversion architectures such as composite-field implementations or more efficient addition chains may be preferable.

**2. No pipelining**

The entire inverse is calculated combinationally, so the critical path can become significant at higher clock frequencies.

**3. Limited verification**

Only a small set of known values is tested. Exhaustive 256-value verification would be better.

**4. No AES S-box affine transformation**

This block computes the **multiplicative inverse**, but the AES S-box additionally applies the affine transformation afterward.

So:

```text id="r5s3ne"
Input byte
   ↓
GF(2⁸) inverse
   ↓
Affine transformation
   ↓
AES S-box output
```

This module implements only the first major mathematical stage.

---

## 5. Interview Takeaways

This is a strong cryptographic RTL example because it demonstrates several concepts simultaneously:

* **Finite-field arithmetic**
* **GF(2⁸) multiplication**
* **Carry-less multiplication**
* **Polynomial modular reduction**
* **AES irreducible polynomial**
* **Repeated squaring**
* **Exponentiation**
* **Combinational SystemVerilog functions**
* **Cryptographic RTL verification**

The key interview statement is:

> **In GF(2⁸), addition is XOR, multiplication is carry-less multiplication followed by reduction using the AES irreducible polynomial, and the multiplicative inverse of a non-zero element can be obtained as \(a^{254}\).**

### Current repo status

**GF(2⁸) Inverse / AES Finite-Field Arithmetic — DONE**

This is a useful addition to the repository because it moves beyond conventional RTL blocks into **cryptographic hardware arithmetic**, which is particularly relevant for security-focused ASIC/RTL roles.
