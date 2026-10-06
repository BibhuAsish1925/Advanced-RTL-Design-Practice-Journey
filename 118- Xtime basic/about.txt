## 1. Circuit Overview & Applications

This design implements the **AES `xtime` operation**, which performs multiplication by 2 in the finite field **GF(2⁸)** used by AES.

Mathematically:

$$
xtime(a)=a\times x \pmod{x^8+x^4+x^3+x+1}
$$

In AES hardware, this operation is heavily used in the **MixColumns transformation**.

The module is purely combinational:

```text
8-bit input
    │
    ▼
Left shift by 1
    │
    ├── MSB = 0 → no reduction
    │
    └── MSB = 1 → XOR with 8'h1B
    │
    ▼
8-bit result
```

---

## 2. Circuit Working & RTL Implementation

The basic multiplication-by-2 operation is implemented by:

```systemverilog
assign shifted = a << 1;
```

This corresponds to multiplying the polynomial representation by \(x\).

The important condition is the original MSB:

```systemverilog
assign result = (a[7]) ? (shifted ^ reduction) : shifted;
```

### Case 1 — MSB = 0

No modular reduction is required.

For example:

```text
01 << 1 = 02
```

Therefore:

```text
xtime(01) = 02
```

### Case 2 — MSB = 1

The shift produces a value beyond the 8-bit field, so AES reduction is required using:

```text
8'h1B
```

For example:

```text
57 << 1 = AE
```

Since `57` has MSB = 0:

```text
xtime(57) = AE
```

For:

```text
AE << 1 → 5C
```

Since `AE[7] = 1`:

```text
5C XOR 1B = 47
```

Therefore:

```text
xtime(AE) = 47
```

---

## 3. Verification & Testbench

The testbench uses a small directed verification strategy with both **FIPS-197 reference examples** and boundary cases.

### AES specification examples

```text
xtime(57) = AE
xtime(AE) = 47
```

These are particularly valuable because they validate the modular-reduction behavior against the AES specification.

### Additional test cases

| Input | Expected | Purpose                |
| ----- | -------- | ---------------------- |
| `00`  | `00`     | Zero                   |
| `01`  | `02`     | Simple shift           |
| `80`  | `1B`     | MSB/reduction boundary |
| `FF`  | `E5`     | Maximum-value case     |

The testbench uses a reusable task:

```systemverilog
task check(
    input [7:0] in_val,
    input [7:0] expected,
    input [127:0] label
);
```

Each test:

1. Drives `a`
2. Waits `#1`
3. Compares `result` with the expected value
4. Prints `PASS` or `FAIL`

Because the DUT is combinational, no clock is required.

---

## 4. Advantages & Limitations

### Advantages

* ✅ Very compact combinational RTL
* ✅ Direct implementation of AES GF(2⁸) arithmetic
* ✅ Synthesizable
* ✅ No clock required
* ✅ Low-latency operation
* ✅ Uses standard AES reduction constant `8'h1B`
* ✅ Includes specification-based verification
* ✅ Useful building block for AES MixColumns and other GF(2⁸) operations

### Limitations

* The module only performs multiplication by **2**; it is not a general GF(2⁸) multiplier.
* The irreducible polynomial is fixed to the AES polynomial.
* The testbench is directed and relatively small.
* There is no formal verification, functional coverage, or randomized testing.

---

## 5. Interview Takeaways

The key concept to remember is:

> **AES `xtime` is multiplication by 2 in GF(2⁸), implemented as a left shift followed by conditional XOR with `8'h1B` when the original MSB is 1.**

The RTL effectively implements:

```text
if (a[7] == 0)
    result = a << 1;
else
    result = (a << 1) XOR 8'h1B;
```

This is a particularly good small RTL example because it connects **finite-field mathematics directly to synthesizable hardware logic**.

### Current repo status

**AES GF(2⁸) `xtime` / Multiply-by-2 — DONE**

It also fits naturally with your existing **GF(2⁸) inverse** project: `xtime` demonstrates the fundamental field multiplication/reduction primitive, while the inverse design uses more extensive GF(2⁸) arithmetic.
