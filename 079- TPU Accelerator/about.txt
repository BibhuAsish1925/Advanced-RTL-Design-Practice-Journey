## 1. Circuit Overview & Applications

This is a **parameterized, sequential matrix-multiplication accelerator** with a TPU-style MAC datapath.

It computes:

$$
C=A\times B
$$

where:

$$
C_{row,col}=\sum_{k=0}^{N-1}A_{row,k}\times B_{k,col}
$$

For the default `MATRIX_SIZE=2`:

```text id="m0qzce"
C00 = A00×B00 + A01×B10
C01 = A00×B01 + A01×B11
C10 = A10×B00 + A11×B10
C11 = A10×B01 + A11×B11
```

Unlike a fully parallel matrix multiplier, this design reuses **one accumulator and one multiply operation per clock cycle**.

### Architecture

```text id="npsm4t"
                  matrix_a[row][index]
                         │
                         ×
                         │
                  matrix_b[index][col]
                         │
                         ▼
                ┌─────────────────┐
                │   Accumulator   │
                │ C[row][col] +   │
                │      A × B      │
                └────────┬────────┘
                         │
                         ▼
                    matrix_c
```

The FSM controls which matrix element is being calculated.

### Applications

* Matrix multiplication accelerators
* Neural-network/AI hardware
* DSP workloads
* Computer-vision processing
* FPGA/ASIC tensor processing
* Linear-algebra accelerators

---

# 2. Circuit Working & RTL Implementation

## A. FSM architecture

The accelerator has three states:

```text id="prm5wq"
       ┌──────┐
       │ IDLE │
       └──┬───┘
          │ start
          ▼
      ┌─────────┐
      │ COMPUTE │
      └────┬────┘
           │ final MAC
           ▼
     ┌──────────┐
     │ COMPLETE │
     └────┬─────┘
          │
          ▼
        IDLE
```

### IDLE

When `start=1`:

```systemverilog id="h4zq8q"
row   <= 0;
col   <= 0;
index <= 0;
```

and all elements of `matrix_c` are cleared.

Then:

```systemverilog id="czp9s4"
state <= COMPUTE;
```

`busy` is asserted.

---

## B. COMPUTE state

The core operation is:

```systemverilog id="e9w6rq"
matrix_c[row][col] <=
    matrix_c[row][col] +
    (matrix_a[row][index] *
     matrix_b[index][col]);
```

This performs one MAC operation per clock:

$$
C_{r,c}\leftarrow C_{r,c}+A_{r,k}B_{k,c}
$$

For a 2×2 matrix, calculating `C[0][0]` takes two compute cycles:

```text id="xhlg6b"
k=0 → C00 = A00×B00
k=1 → C00 = C00 + A01×B10
```

Then the controller moves to the next column.

---

## C. Row/column/index control

The three counters define the matrix traversal:

```text id="5s74qg"
row   → output row
col   → output column
index → inner-product index
```

The traversal is essentially:

```text id="jv5p2c"
(row=0,col=0,index=0)
(row=0,col=0,index=1)

(row=0,col=1,index=0)
(row=0,col=1,index=1)

(row=1,col=0,index=0)
(row=1,col=0,index=1)

(row=1,col=1,index=0)
(row=1,col=1,index=1)
```

Thus, for an `N×N` matrix, there are:

$$
N^3
$$

MAC operations.

For `N=2`:

$$
2^3=\boxed{8}
$$

compute cycles.

---

## D. COMPLETE state

After the final matrix element has received its final product, the FSM enters:

```systemverilog id="5g0a8s"
COMPLETE
```

and produces:

```systemverilog id="q8m4pi"
busy = 0;
done = 1;
```

Then it returns to `IDLE`.

`done` is cleared at the beginning of every normal clock cycle:

```systemverilog id="k5dzc5"
done <= 1'b0;
```

so it behaves as a **one-cycle completion pulse**.

---

## E. Why this is TPU-like

The important architectural idea is **MAC reuse**.

Instead of creating:

```text
N² × N multipliers
```

for a completely parallel implementation, this design uses a single multiply-accumulate datapath repeatedly.

That reduces hardware resources at the cost of increased execution latency.

It is therefore better described as a **simple sequential matrix-multiplication accelerator with a TPU-style MAC operation**, rather than a full systolic-array TPU.

---

# 3. Verification & Testbench

The testbench contains an **independent integer reference model**.

It calculates:

```systemverilog id="cq8p1f"
expected[i][j] =
    expected[i][j] +
    (matrix_a[i][k] * matrix_b[k][j]);
```

This directly implements the mathematical matrix multiplication.

### Tests performed

| Test   | Purpose                              |
| ------ | ------------------------------------ |
| Test 1 | Basic positive matrix multiplication |
| Test 2 | Identity matrix                      |
| Test 3 | Negative values                      |
| Test 4 | Zero matrix                          |
| Test 5 | Reset during operation               |
| Test 6 | Recovery after reset                 |

### Test 1

```text id="m0q0xj"
A = [1 2]      B = [5 6]
    [3 4]          [7 8]
```

Expected:

$$
C=
\begin{bmatrix}
1(5)+2(7) & 1(6)+2(8)\\
3(5)+4(7) & 3(6)+4(8)
\end{bmatrix}
$$

giving:

```text id="3n5hvo"
C = [19 22]
    [43 50]
```

### Identity test

The second test uses:

```text id="0f70xd"
B = [1 0]
    [0 1]
```

Therefore:

$$
A\times I=A
$$

which checks the indexing of the multiplication engine particularly well.

### Negative-value test

The third test verifies signed multiplication and accumulation.

This is important because both matrices are explicitly declared:

```systemverilog id="6ucfpu"
logic signed [DATA_WIDTH-1:0]
```

### Reset verification

The TB also resets the accelerator **mid-operation** and verifies:

```systemverilog id="5etjxr"
busy == 0
done == 0
```

It then runs the multiplication again.

This checks that partial results and FSM state are properly discarded after reset.

### Verification quality

The TB is strong for a basic accelerator because it includes:

* Independent reference model
* Directed functional tests
* Signed arithmetic testing
* Identity-matrix test
* Zero-matrix test
* Mid-operation reset
* Post-reset recovery
* `busy` verification
* `done` pulse verification
* Automatic PASS/FAIL checking

---

# 4. Advantages & Limitations

### Advantages

| Aspect                  | Description                                                       |
| ----------------------- | ----------------------------------------------------------------- |
| **Resource efficient**  | Reuses one MAC operation instead of fully parallel multiplication |
| **Parameterized**       | Matrix size and data width configurable                           |
| **Signed arithmetic**   | Supports negative matrix elements                                 |
| **FSM controlled**      | Clear sequential computation flow                                 |
| **Busy/done interface** | Easy accelerator-style integration                                |
| **Reset recovery**      | Can safely restart after reset                                    |
| **Scalable concept**    | Same algorithm works for larger matrices                          |

### Limitations

**1. Very high latency for large matrices**

The architecture requires:

$$
N^3
$$

MAC operations.

Therefore:

```text id="m7w6cv"
N = 2  →   8 MAC cycles
N = 4  →  64 MAC cycles
N = 8  → 512 MAC cycles
```

This is much slower than a highly parallel or systolic architecture.

**2. Only one MAC per cycle**

The design does not exploit parallelism between different matrix elements.

A true systolic TPU-style architecture would use multiple processing elements operating concurrently.

**3. Sequential output accumulation**

`matrix_c` itself acts as the accumulator storage. This makes the implementation simple but limits throughput.

**4. Matrix inputs are combinationally accessed**

The architecture assumes the complete matrices are available as array inputs. A practical accelerator would generally include:

* SRAM/register-file interfaces
* DMA/data movement
* tiling
* buffering
* streaming interfaces

**5. Width growth**

The default:

```systemverilog id="0c9ev4"
ACC_WIDTH = 2 * DATA_WIDTH + $clog2(MATRIX_SIZE)
```

provides additional accumulation bits, but width planning becomes important for larger matrices and signed arithmetic.

**6. `integer` control variables**

The controller uses:

```systemverilog id="3wqq40"
integer row;
integer col;
integer index;
```

This is convenient for learning RTL, but dedicated bounded-width counters are generally cleaner for synthesizable hardware:

```text
$clog2(MATRIX_SIZE)
```

based widths can reduce unnecessary state bits.

---

# 5. Interview Takeaways

### Key concept

> **This design implements sequential matrix multiplication using a reusable MAC datapath controlled by an FSM, trading hardware area for computation latency.**

### Important interview questions

**Q: Why are there three indices?**

Because matrix multiplication requires:

$$
C_{ij}=\sum_k A_{ik}B_{kj}
$$

So:

* `row` → \(i\)
* `col` → \(j\)
* `index` → \(k\)

**Q: How many MAC operations are required for an N×N matrix?**

$$
\boxed{N^3}
$$

**Q: Why use one MAC instead of many multipliers?**

To reduce hardware resource usage. The trade-off is increased execution time.

**Q: What is the difference between this and a systolic-array TPU?**

This design reuses a single MAC sequentially. A systolic array contains multiple processing elements that perform MAC operations concurrently and pass data between neighboring PEs.

**Q: What is the purpose of `busy` and `done`?**

`busy` indicates that computation is in progress, while `done` provides a completion pulse when the matrix result is ready.

**Q: How would you improve throughput?**

Possible approaches include:

* Multiple parallel MAC units
* Systolic-array architecture
* Pipelined processing elements
* Tiling/block matrix multiplication
* Local SRAM/register-file buffering
* Data reuse between matrix operations

### One-line interview explanation

> **“I implemented a parameterized sequential matrix-multiplication accelerator using an FSM-controlled reusable MAC datapath, with signed arithmetic, `busy/done` control, and a self-checking reference-model testbench including reset and corner-case verification.”**
