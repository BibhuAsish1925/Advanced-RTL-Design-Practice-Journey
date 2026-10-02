## 1. Circuit Overview & Applications

This is a **2-stage pipelined Multiply-Accumulate (MAC)** unit.

**Purpose:**
It separates multiplication and accumulation into two clocked stages so the multiplier and accumulator do not have to operate in the same combinational path.

### Architecture

```text
        a ─────┐
               │
        b ─────┤
               ▼
        ┌─────────────┐
        │ Multiplier  │  Stage 1
        │    a × b    │
        └──────┬──────┘
               │
          product_reg
               │
               ▼
        ┌─────────────┐
        │ Accumulator │  Stage 2
        │ ACC + PROD  │
        └──────┬──────┘
               │
              acc
```

### Applications

* DSP and FIR filters
* Matrix multiplication
* Neural-network MAC operations
* Image/audio processing
* Signal processing accelerators

---

## 2. Circuit Working & RTL Implementation

The important difference from a normal MAC is that the multiplication result is **registered before accumulation**.

### Stage 1 — Multiplication

```systemverilog
product_reg <= a * b;
```

At clock cycle `N`:

$$
P_N = A_N \times B_N
$$

The result is stored in `product_reg`.

### Stage 2 — Accumulation

```systemverilog
acc <= acc + product_reg;
```

At the same clock edge, the accumulator sees the **previous value** of `product_reg` because nonblocking assignments (`<=`) update registers after the clocked blocks evaluate.

Therefore:

$$
ACC_N = ACC_{N-1} + P_{N-1}
$$

So there is effectively **one cycle of latency between an input multiplication and its contribution to `acc`**.

### Example

| Clock |         Input | `product_reg` after edge | `acc` after edge |
| ----- | ------------: | -----------------------: | ---------------: |
| 1     |    5 × 3 = 15 |                       15 |                0 |
| 2     |   10 × 2 = 20 |                       20 |               15 |
| 3     |    7 × 4 = 28 |                       28 |               35 |
| 4     |   12 × 5 = 60 |                       60 |               63 |
| 5     | 20 × 10 = 200 |                      200 |              123 |
| 6     |             — |                        — |              323 |

This is exactly why the testbench maintains `expected_product`: it models the **one-cycle pipeline delay**.

### Key RTL blocks

* `product_reg` → Stage-1 pipeline register
* `acc` → Stage-2 accumulation register
* `en` → controls both stages
* `rst` → synchronously clears both registers

### Important consequence of `en`

Because both stages use the same `en`:

```systemverilog
else if (en)
    product_reg <= a * b;
```

and

```systemverilog
else if (en)
    acc <= acc + product_reg;
```

when `en=0`, **both pipeline stages stop**.

That means the current product remains in `product_reg` rather than being automatically flushed.

---

## 3. Verification & Testbench

The testbench is a **self-checking directed testbench**.

### What it verifies

It tests:

* Reset operation
* Sequential MAC accumulation
* Pipeline latency
* Pipeline flush
* Enable functionality
* Final expected vs actual accumulator

The expected model maintains:

```systemverilog
expected_acc
expected_product
```

The important verification operation is:

```systemverilog
expected_acc = expected_acc + expected_product;
expected_product = product;
```

This mirrors the DUT's pipeline behavior.

### Tested operations

```text
5 × 3   = 15
10 × 2  = 20
7 × 4   = 28
12 × 5  = 60
20 × 10 = 200
```

The final accumulated result is:

$$
15+20+28+60+200=\boxed{323}
$$

The additional flush cycle ensures that the final `200` product stored in the pipeline is added to the accumulator.

### Enable test

The testbench applies:

```text
100 × 100
en = 0
```

and verifies that the accumulator remains unchanged at `323`.

This is a good test because it confirms that disabled operation does not modify the MAC state.

### Verification quality

The TB is stronger than a simple monitor because it uses:

* Directed stimulus
* Reference-model calculation
* Automatic PASS/FAIL checking
* Pipeline-aware expected values
* Enable corner-case testing
* `$finish`

One useful additional test would be **back-to-back operations with `en` toggling between cycles**, because that exercises pipeline bubbles.

---

## 4. Advantages & Limitations

### Advantages

| Aspect               | Description                                            |
| -------------------- | ------------------------------------------------------ |
| **Timing**           | Multiplier and accumulator are separated by a register |
| **Throughput**       | Can accept a new multiplication every enabled clock    |
| **Scalability**      | `DATA_WIDTH` and `ACC_WIDTH` are parameterized         |
| **RTL simplicity**   | Very compact two-stage architecture                    |
| **Hardware mapping** | Multiplier can map to FPGA DSP blocks                  |

### Limitation

The pipeline improves timing/throughput, but introduces **latency**.

A normal single-stage MAC conceptually performs:

```text
a × b → accumulator
```

in one clocked operation.

This design performs:

```text
Cycle N:   a × b → product_reg
Cycle N+1: product_reg → accumulator
```

Another limitation is **overflow**. With the default parameters:

```text
8-bit × 8-bit → 16-bit product
16-bit product → 32-bit accumulator
```

The 32-bit accumulator can eventually overflow after enough accumulated products.

Also, if `ACC_WIDTH < 2*DATA_WIDTH`, the parameter combination requires careful width handling because the product cannot be fully represented in the accumulator.

---

## 5. Interview Takeaways

### Key concept

> **A pipelined MAC separates multiplication and accumulation into two sequential stages, reducing the critical combinational path while introducing one cycle of latency.**

### Why pipeline it?

The multiplication operation can have significant delay. Registering its result prevents the multiplier and accumulator from forming one long combinational path.

### Important interview questions

**Q: Why does `acc` receive the previous product?**
Because `product_reg` and `acc` are updated using nonblocking assignments on the same clock edge.

**Q: What is the pipeline latency?**
One clock cycle from the input multiplication to its contribution to `acc`.

**Q: Can it accept new inputs every cycle?**
Yes. Once the pipeline is filled, a new multiplication can be accepted every enabled cycle.

**Q: What happens when `en=0`?**
Both pipeline registers hold their previous values.

**Q: Why is `expected_product` required in the TB?**
Because the accumulator operates on the **previous cycle's product**, so the reference model must account for the pipeline latency.

**One-line interview explanation:**

> “I implemented a parameterized two-stage pipelined MAC where multiplication is registered in Stage 1 and accumulated in Stage 2, improving timing while maintaining one-operation-per-cycle throughput after pipeline fill.”
