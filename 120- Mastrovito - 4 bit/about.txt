## 1. Circuit Overview & Applications

This design implements a **4-bit Mastrovito multiplier over GF(2⁴)** using the irreducible polynomial:

$$
P(x)=x^4+x+1
$$

represented as:

```text
10011
```

The function performed is:

$$
P=(A\times B)\bmod (x^4+x+1)
$$

Unlike the previous **iterative-style GF(2⁴) multiplier**, this implementation explicitly derives the polynomial product and reduction equations as **combinational Boolean logic**.

### Architecture

```text
        A[3:0] ─────┐
                    │
                    ▼
             Partial Product
               Generation
                    │
                    ▼
              partial[6:0]
                    │
                    ▼
             Mastrovito
          Modular Reduction
                    │
                    ▼
                 P[3:0]
```

This architecture is relevant to:

* Cryptographic hardware
* AES/Galois-field arithmetic
* Error-correcting codes
* Reed-Solomon implementations
* Hardware security accelerators

---

## 2. Circuit Working & RTL Implementation

### Polynomial multiplication

The design first generates the seven coefficients of the unreduced polynomial product.

For example:

```systemverilog
assign partial[2] =
    (A[2]&B[0]) ^
    (A[1]&B[1]) ^
    (A[0]&B[2]);
```

This corresponds to the \(x^2\) coefficient:

$$
A_2B_0 \oplus A_1B_1 \oplus A_0B_2
$$

Similarly, `partial[6]` is simply:

```systemverilog
assign partial[6] = A[3] & B[3];
```

because only \(A_3B_3x^6\) contributes to the highest-degree term.

So the multiplier produces:

```text id="v6sp5a"
partial[6:0]
```

before reduction.

### Modular reduction

For:

$$
x^4+x+1=0
$$

we have:

$$
x^4=x+1
$$

and therefore:

```text
x⁴ → x + 1
x⁵ → x² + x
x⁶ → x³ + x²
```

The design uses these relationships directly.

For example:

```systemverilog
assign r3 = partial[3] ^ partial[6];
```

because `partial[6]·x⁶` contributes an `x³` term after reduction.

Likewise:

```systemverilog
assign r2 = partial[2] ^ partial[6] ^ partial[5];
assign r1 = partial[1] ^ partial[5] ^ partial[4];
assign r0 = partial[0] ^ partial[4];
```

Finally:

```systemverilog
assign P = {r3, r2, r1, r0};
```

produces the reduced 4-bit field element.

### Important architectural distinction

Your previous `galois_mult4` uses:

```text
general polynomial multiplication
        ↓
loop-based modular reduction
```

whereas this Mastrovito implementation uses:

```text
explicit partial-product equations
        ↓
fixed modular-reduction equations
```

That makes the Mastrovito version much more **structurally oriented toward hardware implementation**.

---

## 3. Verification & Testbench

The testbench is essentially the same verification strategy as your previous GF(2⁴) multiplier, which is appropriate because it allows the two structurally different implementations to be compared against an independent algorithm.

### Independent reference model

The reference model uses a shift-and-reduce algorithm:

```systemverilog
function [3:0] ref_mult;
```

It is structurally different from the Mastrovito equations, reducing the risk of simply reproducing the same implementation mistake in the testbench.

### Test coverage

The testbench performs:

| Test                    |  Coverage |
| ----------------------- | --------: |
| Zero multiplication     |  32 cases |
| Identity                |  32 cases |
| Directed vectors        |  10 cases |
| Commutativity           | 256 pairs |
| Exhaustive verification | 256 pairs |
| Random testing          | 100 cases |

The most significant test is the exhaustive test:

```text
16 × 16 = 256 combinations
```

Since GF(2⁴) has only 16 possible operands, **all possible input combinations are covered**.

### Verification flow

```text
Zero cases
    ↓
Identity cases
    ↓
Directed vectors
    ↓
Commutativity
    ↓
All 256 combinations
    ↓
100 additional random cases
    ↓
FINAL RESULT
```

The final `errors` counter provides a simple aggregate pass/fail result.

---

## 4. Advantages & Limitations

### Advantages

* ✅ Fully combinational architecture
* ✅ Explicit Mastrovito-style equations
* ✅ No iterative multiplication loop in the DUT
* ✅ Fixed and predictable logic structure
* ✅ Synthesizable
* ✅ XOR/AND based implementation
* ✅ Independent reference model
* ✅ Exhaustive 256-case verification
* ✅ Mathematical property checking
* ✅ Useful for studying hardware-oriented finite-field multiplication

### Limitations

* The implementation is fixed to **GF(2⁴)**.
* The polynomial \(x^4+x+1\) is hard-coded.
* It is not parameterized for other field sizes or irreducible polynomials.
* No pipelining is included.
* No synthesis/PPA measurements are included in the supplied material.
* The random test adds limited additional functional value because exhaustive verification already covers the entire input space.

---

## 5. Interview Takeaways

The key interview concept here is the **Mastrovito multiplier architecture**.

A good explanation would be:

> “I implemented a combinational Mastrovito multiplier for GF(2⁴). The design first generates the seven coefficients of the polynomial product using AND/XOR logic, then performs modular reduction using the irreducible polynomial \(x^4+x+1\). Unlike a generic shift-and-reduce multiplier, the reduction is expressed as fixed Boolean equations, making the datapath directly suited to hardware implementation.”

### Comparison with your previous GF multiplier

| Feature            | `galois_mult4`         | `mastrovito_4bit`   |
| ------------------ | ---------------------- | ------------------- |
| Field              | GF(2⁴)                 | GF(2⁴)              |
| Polynomial         | `10011`                | `10011`             |
| Architecture       | Shift/reduce algorithm | Mastrovito          |
| DUT reduction      | Iterative loop         | Explicit equations  |
| Hardware structure | Algorithmic            | Structural          |
| Combinational      | Yes                    | Yes                 |
| Verification       | Exhaustive + random    | Exhaustive + random |

The important point is that **both should produce identical GF(2⁴) results**, but they represent two different hardware implementation approaches.

### Current repo status

**Mastrovito GF(2⁴) Multiplier — DONE**

This is a stronger VLSI-oriented addition than simply having another GF multiplier because it demonstrates that you understand not only **finite-field arithmetic**, but also how the mathematics can be transformed into a **fixed combinational hardware architecture**.
