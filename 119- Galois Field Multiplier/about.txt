## 1. Circuit Overview & Applications

This design implements a **4-bit Galois-field multiplier in GF(2⁴)** using the irreducible polynomial:

$$
P(x)=x^4+x+1
$$

represented as:

```text
10011
```

The multiplier performs:

$$
product=(a\times b)\bmod P(x)
$$

Unlike ordinary binary multiplication, addition in GF(2⁴) is performed using **XOR rather than integer addition**.

### Basic datapath

```text
       a ─────────┐
                  │
                  ▼
            Polynomial
             multiply
                  │
       b ─────────┘
                  │
                  ▼
          7-bit intermediate
                  │
                  ▼
       Modular reduction
          by 10011
                  │
                  ▼
             product[3:0]
```

This is a useful educational implementation of **finite-field arithmetic**, which is relevant to cryptography, error-correcting codes, and hardware security.

---

## 2. Circuit Working & RTL Implementation

### Step 1 — Polynomial multiplication

The RTL examines every bit of `b`:

```systemverilog
for (i = 0; i < 4; i = i + 1)
  if (b[i])
    tmp = tmp ^ (a << i);
```

If `b[i]` is `1`, the corresponding shifted version of `a` is XORed into `tmp`.

For example, conceptually:

```text
a × b
= a × (b3x³ + b2x² + b1x + b0)
```

becomes a collection of shifted polynomial terms combined with XOR.

The maximum intermediate polynomial degree is 6, hence:

```systemverilog
reg [6:0] tmp;
```

---

### Step 2 — Modular reduction

The irreducible polynomial is:

```text
x⁴ + x + 1
```

or:

```text
10011
```

The reduction loop checks the high-order bits:

```systemverilog
for (i = 6; i >= 4; i = i - 1)
  if (tmp[i])
    tmp = tmp ^ (7'b10011 << (i - 4));
```

This is equivalent to polynomial long division over GF(2).

The important point is that **subtraction and addition are identical in GF(2)**, so polynomial division uses XOR.

Finally:

```systemverilog
assign product = tmp[3:0];
```

leaves the remainder, which is a valid 4-bit GF(2⁴) element.

---

## 3. Verification & Testbench

This is actually a **strong verification setup for such a small combinational block**.

The testbench contains an independent reference implementation:

```systemverilog
function [3:0] ref_mult;
```

The reference model uses the classic shift-and-reduce GF multiplication algorithm and the same polynomial:

```text
x⁴ + x + 1
```

### Test 1 — Zero multiplication

It verifies:

```text
0 × a = 0
a × 0 = 0
```

for all 16 possible values.

**32 cases** are checked.

---

### Test 2 — Identity

It verifies:

```text
a × 1 = a
1 × a = a
```

for all 16 values.

Again, this gives **32 checks**.

---

### Test 3 — Directed cases

Specific combinations such as:

```text
2 × 2
3 × 4
5 × 7
A × B
F × F
```

are checked against the reference model.

---

### Test 4 — Commutativity

The testbench verifies the mathematical property:

$$
a\times b=b\times a
$$

for:

$$
16\times16=256
$$

input pairs.

---

### Test 5 — Exhaustive verification

This is the most important test.

Because GF(2⁴) has only 16 possible values:

```text
16 × 16 = 256
```

is the **entire input space**.

Therefore the testbench checks every possible `(a,b)` combination against `ref_mult`.

That means the functional input space is **exhaustively verified**, not merely sampled.

---

### Test 6 — Random testing

An additional 100 random combinations are tested.

Strictly speaking, these do not add input-space coverage beyond the exhaustive test, but they are still useful as an additional independent execution path.

---

## 4. Advantages & Limitations

### Advantages

* ✅ Fully combinational GF(2⁴) multiplier
* ✅ Correct polynomial arithmetic structure
* ✅ Synthesizable RTL
* ✅ Uses XOR-based GF addition
* ✅ Explicit modular reduction
* ✅ Independent reference model
* ✅ Mathematical property checking
* ✅ Exhaustive 256-case verification
* ✅ Additional randomized testing
* ✅ Good educational example of finite-field hardware

### Limitations

* The implementation is specifically fixed to **GF(2⁴)**.
* The irreducible polynomial is hard-coded as `10011`.
* No parameterization for field width or polynomial.
* The multiplier is combinational, so larger field sizes would increase logic complexity.
* The testbench uses a software-style reference model rather than assertions or functional coverage.
* The random test is somewhat redundant because all 256 possible input pairs have already been exhaustively tested.

---

## 5. Interview Takeaways

The most important distinction to remember is:

> **GF multiplication is polynomial multiplication over GF(2), followed by modular reduction using an irreducible polynomial.**

For this design:

```text
Field       : GF(2⁴)
Polynomial  : x⁴ + x + 1
Binary      : 10011
Addition    : XOR
Multiplication: Polynomial multiplication
Reduction   : XOR-based polynomial division
```

A particularly good interview explanation is:

> “I implemented a combinational GF(2⁴) multiplier where each set bit of the multiplier selects a shifted version of the multiplicand. These partial products are XORed because addition in GF(2) is XOR. The resulting polynomial is then reduced modulo the irreducible polynomial \(x^4+x+1\). I exhaustively verified all 256 possible input combinations against an independent reference model.”

### Current repo status

**GF(2⁴) Galois-Field Multiplier — DONE**

This also complements your existing finite-field work nicely:

```text
GF(2⁴) Multiplier → Fundamental finite-field multiplication
GF(2⁸) xtime       → AES multiplication by 2
GF(2⁸) Inverse     → AES-oriented finite-field inversion
SHA-256 Core       → Cryptographic hashing
```
