## 1. Circuit Overview & Applications

This is a **parameterized recursive Karatsuba multiplier** supporting arbitrary operand widths above a configurable leaf size.

For:

```text
WIDTH = 32
BASE  = 8
```

the design recursively decomposes the 32-bit multiplication until reaching 8-bit leaf multipliers.

The basic Karatsuba relation is:

```text
z0 = a0 × b0
z2 = a1 × b1
z1 = (a0+a1)(b0+b1) − z0 − z2

P = (z2 << 2·LOW) + (z1 << LOW) + z0
```

**Applications:**

* Large integer arithmetic
* Cryptographic accelerators
* RSA/ECC datapaths
* DSP/arithmetic architectures
* Hierarchical multiplier design
* Studying recursive RTL/generate structures

This is a significant step beyond your previous fixed **16×16 Karatsuba multiplier**, because the architecture itself recursively instantiates smaller Karatsuba multipliers.

---

## 2. Circuit Working & RTL Implementation

### Base-case architecture

The key generate condition is:

```systemverilog
if (WIDTH <= BASE)
    assign p = a * b;
```

With `BASE = 8`, an 8×8 operation becomes the leaf multiplier.

So for `WIDTH = 16`:

```text
16×16
 ├── 8×8 → z0
 ├── 8×8 → z2
 └── 9×9 → middle
```

For `WIDTH = 32`, the hierarchy goes deeper:

```text
32×32
 ├── 16×16 Karatsuba
 ├── 16×16 Karatsuba
 └── 17×17 Karatsuba
       ...
       → 8×8 leaves
```

### Operand decomposition

The design calculates:

```systemverilog
LOW  = WIDTH / 2;
HIGH = WIDTH - LOW;
```

This is important because it also supports **odd widths** rather than assuming both halves are equal.

The operands become:

```text
a = a1 · 2^LOW + a0
b = b1 · 2^LOW + b0
```

### Three recursive products

`U_Z0` calculates:

```text
a0 × b0
```

`U_Z2` calculates:

```text
a1 × b1
```

and `U_MIDDLE` calculates:

```text
(a0+a1)(b0+b1)
```

The cross product is then recovered through:

```systemverilog
z1 = middle - z0_ext - z2_ext;
```

which gives:

```text
z1 = a0b1 + a1b0
```

### Result reconstruction

Finally:

```text
P = z2·2^(2LOW) + z1·2^LOW + z0
```

The explicit zero extension and shifting in `part_z2`, `part_z1`, and `part_z0` correctly align the three components before addition.

---

## 3. Verification & Testbench

The testbench instantiates **two configurations simultaneously**:

### 16-bit DUT

```text
WIDTH = 16
BASE  = 8
```

### 32-bit DUT

```text
WIDTH = 32
BASE  = 8
```

This is useful because it verifies both the first recursive level and the deeper recursive hierarchy.

### Directed tests

The TB covers:

* Zero operands
* One
* Small values
* Cross-half patterns
* Maximum values
* `0x8000 × 0x8000`
* `0xFFFFFFFF × 0xFFFFFFFF`

### Random verification

It additionally performs:

* **100 random 16-bit tests**
* **100 random 32-bit tests**

The reference is:

```systemverilog
expected = test_a * test_b;
```

and the result is checked using:

```systemverilog
p !== expected
```

So the testbench provides good functional coverage for the implemented configurations.

---

## 4. Advantages & Limitations

### Advantages

* **Recursive architecture**
* Parameterized `WIDTH`
* Configurable leaf `BASE`
* Supports widths where `WIDTH` is not necessarily a power of two
* Hierarchical decomposition is synthesizable
* Reduces the number of recursive multiplication operations
* Reusable for larger arithmetic datapaths
* Good example of SystemVerilog/Verilog generate-based structural design

### Limitations

**1. PPA benefit is technology-dependent**

The recursive architecture does not automatically mean better area, timing, or power than:

```systemverilog
assign p = a * b;
```

The actual advantage must be demonstrated through synthesis.

**2. Addition/subtraction overhead**

Karatsuba trades multiplication complexity for additional:

* Adders
* Subtractors
* Wiring
* Intermediate storage/logic

**3. Fully combinational**

The entire recursive tree is combinational. At larger widths, timing can become challenging.

**4. Leaf multiplier still uses `*`**

At `WIDTH <= BASE`, the design relies on the synthesis tool's multiplier implementation:

```systemverilog
assign p = a * b;
```

So this is a **hybrid recursive Karatsuba architecture**, rather than a completely gate-level multiplier.

**5. No signed arithmetic**

The current implementation is explicitly for **unsigned operands**.

---

## 5. Interview Takeaways

* **What is the difference from the previous 16×16 design?**
  The previous design had a fixed decomposition. This one recursively instantiates itself until `WIDTH <= BASE`.

* **What controls recursion?**

```systemverilog
if (WIDTH <= BASE)
```

The generate block determines whether the current level becomes a leaf multiplier or another Karatsuba stage.

* **Why are there three multiplications instead of four?**

```text
a0b0
a1b1
(a0+a1)(b0+b1)
```

The third product contains both cross terms, allowing them to be recovered by subtraction.

* **Why is `sa`/`sb` one bit wider?**
  Because adding two `HIGH`-bit values can generate a carry.

* **What happens with `WIDTH = 32, BASE = 8`?**
  The 32-bit multiplication recursively decomposes into smaller 16/17-bit operations until the 8-bit leaf multipliers are reached.

* **What would you do next for an industry-style version?**
  Synthesize `karatsuba_mul` against a conventional `a*b` multiplier at 16/32/64/128-bit widths and compare **area, timing, power, and multiplier/DSP utilization**.

### Repository classification

**Status: DONE — Parameterized Recursive Karatsuba Multiplier**

This is a stronger and more technically interesting version of your previous Karatsuba project because it demonstrates **recursive RTL generation, parameterization, hierarchical arithmetic decomposition, and scalable multiplier architecture**.
