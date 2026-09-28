# 4-BIT INPUT FACTORIAL CALCULATOR

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This design implements a **combinational factorial calculator**. It accepts a 4-bit input `n` and produces a 32-bit factorial result:

$$
result = n!
$$

The factorial is calculated recursively using:

$$
n! =
\begin{cases}
1, & n \leq 1\\
n\times(n-1)!, & n>1
\end{cases}
$$

For example:

```text
5! = 5 × 4 × 3 × 2 × 1 = 120
```

The 32-bit output allows the design to represent the factorial values tested by the supplied testbench, from `0!` through `10!`.

### Applications

* Mathematical computation hardware
* Algorithm-to-RTL demonstrations
* Recursive-function learning
* Arithmetic datapath experimentation
* Educational examples of combinational RTL

---

# 2. CIRCUIT WORKING & RTL IMPLEMENTATION

The architecture is essentially:

```text
             ┌────────────────────────┐
n[3:0] ────> │   Recursive Factorial  │
             │       Function         │
             │                        │
             │ n × (n-1) × ... × 1   │
             └───────────┬────────────┘
                         │
                         ▼
                    result[31:0]
```

The main calculation is contained inside:

```verilog
function automatic integer fact(input integer i);
```

`automatic` gives each recursive invocation its own function-local storage.

### Base condition

```verilog
if (i > 1)
    fact = i * fact(i - 1);
else
    fact = 1;
```

When `i` reaches `1` or `0`, the recursion terminates:

```text
0! = 1
1! = 1
```

For `n = 5`, the recursive evaluation is conceptually:

```text
fact(5)
 = 5 × fact(4)
 = 5 × 4 × fact(3)
 = 5 × 4 × 3 × fact(2)
 = 5 × 4 × 3 × 2 × fact(1)
 = 5 × 4 × 3 × 2 × 1
 = 120
```

The result is then assigned in:

```verilog
always @(n)
    result = fact(n);
```

Therefore, whenever `n` changes, the factorial is recalculated.

---

# 3. VERIFICATION & TESTBENCH

The testbench uses:

```verilog
reg [3:0] n;
wire [31:0] result;
```

and instantiates:

```verilog
factorial dut(n, result);
```

The testbench generates inputs from `0` through `10`:

```verilog
initial
    for(x=0; x<11; x=x+1)
        #10 n=x;
```

So the expected sequence is:

|  n |      n! |
| -: | ------: |
|  0 |       1 |
|  1 |       1 |
|  2 |       2 |
|  3 |       6 |
|  4 |      24 |
|  5 |     120 |
|  6 |     720 |
|  7 |    5040 |
|  8 |   40320 |
|  9 |  362880 |
| 10 | 3628800 |

The `$monitor` continuously displays:

```verilog
$monitor("\t\t factorial of %d is %0d", n, result);
```

The simulation terminates after:

```verilog
#120 $finish;
```

which gives enough time for the 11 input values to be applied at 10 ns intervals.

### Verification limitation

The TB is **display-based**, not self-checking. It does not explicitly compare the calculated result against expected factorial values.

A stronger TB would automatically generate:

```text
PASS: 5! = 120
FAIL: expected ..., got ...
```

---

# 4. ADVANTAGES & LIMITATIONS

### Advantages

* Very compact implementation.
* Recursive function clearly represents the mathematical definition of factorial.
* `automatic` supports recursive function calls.
* No clock or reset is required.
* Easy to understand and simulate.
* 32-bit output provides sufficient range for the tested values.

### Limitations

The main hardware limitation is that recursive software-like code does **not necessarily translate into an efficient hardware architecture**.

For larger values, the synthesis tool may create a large combinational multiplication network.

Also, a 4-bit input can represent values up to:

```text
15
```

but:

$$
15! = 1,307,674,368,000
$$

which is far beyond the 32-bit unsigned range.

Therefore, although the input is 4-bit, the 32-bit output cannot correctly represent the factorial of every possible 4-bit input.

For this implementation:

```text
10! = 3,628,800   → fits in 32 bits
11! = 39,916,800  → fits
12! = 479,001,600 → fits
13! = 6,227,020,800 → does NOT fit
```

So **12 is the largest input whose factorial fits in an unsigned 32-bit result**.

---

# 5. INTERVIEW TAKEAWAYS

**Core concept:** Calculate `n!` using a recursive factorial function.

**Algorithm:**

```text
if n <= 1:
    result = 1
else:
    result = n × factorial(n-1)
```

**Key RTL concepts demonstrated:**

* Functions
* Recursive function calls
* `automatic` function
* Combinational `always`
* Multiplication
* Parameter/input-width versus output-width considerations

**One-line interview explanation:**

> “This RTL implements a combinational factorial calculator using an automatic recursive function, where each call multiplies the current input by the factorial of the previous integer until reaching the base case 0! or 1! = 1.”
