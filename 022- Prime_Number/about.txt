# 32-BIT PRIME NUMBER DETECTOR

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This design is a **32-bit combinational prime-number detector**. It receives an unsigned 32-bit integer and produces:

```text
is_prime = 1 → number is prime
is_prime = 0 → number is not prime
```

The design determines primality by checking whether the number is divisible by any integer from `2` through `number/2`.

### Basic principle

A number is considered prime if:

```text
number > 1
```

and no value `i` in the tested range satisfies:

```text
number % i == 0
```

### Applications

* Mathematical/computational hardware
* Cryptographic number-generation support
* Hardware demonstrations of modulo/division operations
* Algorithm-to-RTL learning
* Combinational arithmetic datapath studies

---

# 2. CIRCUIT WORKING & RTL IMPLEMENTATION

The overall operation is:

```text
                 ┌─────────────────────────┐
number ─────────>│                         │
                 │  Check number <= 1      │
                 │                         │
                 │       ↓                 │
                 │  Try i = 2 ... N/2      │
                 │       ↓                 │
                 │    N % i == 0 ?         │
                 │      /      \            │
                 │    YES      NO           │
                 │     ↓        ↓           │
                 │  Not Prime  Continue     │
                 │                         │
                 └──────────┬──────────────┘
                            │
                            ▼
                       is_prime
```

### Initial assumption

```verilog
is_prime = 1;
```

The circuit initially assumes the number is prime.

Then:

```verilog
if (number <= 1)
    is_prime = 0;
```

Numbers `0` and `1` are therefore classified as non-prime.

---

### Divisibility checking

For valid candidates:

```verilog
for (i = 2; i <= number / 2; i = i + 1)
```

The design tests every integer from `2` through `number/2`.

For example, for:

```text
number = 13
```

it checks:

```text
13 % 2
13 % 3
13 % 4
13 % 5
13 % 6
```

None are zero, so:

```text
is_prime = 1
```

For:

```text
number = 20
```

the first checks include:

```text
20 % 2 = 0
```

Therefore:

```verilog
is_prime = 0;
break;
```

The `break` terminates the loop as soon as a divisor is found.

---

## Important RTL characteristics

### 1. Combinational design

```verilog
always @(*)
```

means the detector has no clock or reset. Its output changes according to the current `number`.

### 2. Modulo operator

```verilog
number % i
```

performs the divisibility test.

This is algorithmically simple, but `%` with variable operands can synthesize into substantial arithmetic hardware.

### 3. Division

```verilog
number / 2
```

is used to determine the upper limit of the loop.

Because the divisor is the constant `2`, synthesis can generally implement this efficiently compared with a variable divider.

### 4. Early termination

```verilog
break;
```

stops searching after finding the first divisor.

For example:

```text
20 → divisor 2 found → stop
```

This avoids unnecessary subsequent iterations during simulation/behavioral execution.

---

# 3. VERIFICATION & TESTBENCH

The testbench instantiates the detector:

```verilog
prime_number_detector dut(
    .number(number),
    .is_prime(is_prime)
);
```

It applies four test cases:

| Input | Expected  |
| ----: | --------- |
|    13 | Prime     |
|    20 | Not prime |
|    11 | Prime     |
|    18 | Not prime |

The `$display` statement reports:

```verilog
$display("Number %d is %s",
         number,
         (is_prime) ? "prime" : "not prime");
```

So the simulation produces messages conceptually like:

```text
Number 13 is prime
Number 20 is not prime
Number 11 is prime
Number 18 is not prime
```

### Verification limitation

The current testbench is **display-based rather than self-checking**.

It does not explicitly compare the DUT result with an expected result.

A stronger TB would do:

```text
actual result
     ↓
compare with expected result
     ↓
PASS / FAIL
```

It would also be useful to test:

```text
0, 1       → not prime
2          → prime
3          → prime
4          → not prime
5          → prime
9          → not prime
97         → prime
100        → not prime
```

---

# 4. ADVANTAGES & LIMITATIONS

### Advantages

* Simple and easy-to-understand primality algorithm.
* Fully combinational.
* Parameter-free 32-bit implementation.
* `break` avoids further checks once a divisor is found.
* Easy to simulate and verify.

### Limitations

The biggest issue is **hardware efficiency**.

For a 32-bit input, the loop can theoretically perform a very large number of divisibility checks. The `%` operator with a variable divisor can also result in significant synthesized hardware.

The current algorithm checks up to:

$$
\frac{N}{2}
$$

whereas a mathematical optimization would normally only need to check possible divisors up to:

$$
\sqrt{N}
$$

For a practical hardware implementation, an **iterative clocked architecture** would generally be much more area-efficient:

```text
                 ┌───────────────┐
number ─────────>│ Control / FSM │
                 └───────┬───────┘
                         │
                  divisor counter
                         │
                         ▼
                  modulo/divider
                         │
                    divisible?
                    /        \
                  YES         NO
                   │           │
                NOT PRIME    next divisor
```

That approach trades **latency for significantly lower hardware resource usage**.

---

# 5. INTERVIEW TAKEAWAYS

**Core concept:** 32-bit combinational primality detection using repeated divisibility checks.

**Algorithm:**

```text
if N <= 1:
    not prime
else:
    for i = 2 to N/2:
        if N % i == 0:
            not prime
            stop
    prime
```

**Key RTL concepts demonstrated:**

* Combinational `always @(*)`
* `for` loop
* Variable modulo operation
* Division by a constant
* `break` statement
* Boolean result generation

**One-line interview explanation:**

> “This RTL implements a combinational 32-bit prime detector by checking whether the input is divisible by any integer from 2 through N/2, terminating early when a divisor is found.”
