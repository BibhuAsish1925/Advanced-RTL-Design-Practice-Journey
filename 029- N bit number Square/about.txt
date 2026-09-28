# N-BIT SQUARE — RTL & TESTBENCH ANALYSIS

## 1. Circuit Overview & Applications

This design implements a **parameterized combinational N-bit squaring circuit**.

It takes an `N`-bit unsigned number and calculates:

$$
result = num^2
$$

### Key features

* `n` → input width, default = **4 bits**
* Input range for `n=4`: **0–15**
* Output width = `2n` bits
* No clock or reset
* Fully combinational
* Synthesizable RTL

### Applications

* DSP and arithmetic datapaths
* Address/index calculations
* Polynomial and numerical processing
* Signal-processing hardware
* FPGA/ASIC arithmetic units

---

# 2. Circuit Working & RTL Implementation

The module is:

```verilog
module n_bit_square(num, result);
    parameter n=4;
    input [n-1:0] num;
    output reg [2*n-1:0] result;
    reg [2*n-1:0] tmp;
```

For the default:

```text
n = 4

num    = 4 bits
result = 8 bits
tmp    = 8 bits
```

The 8-bit result is required because:

$$
15^2 = 225 = 11100001_2
$$

which requires 8 bits.

---

### Main computation

```verilog
always @(*) begin
    tmp = num * num;
    result = tmp;
end
```

Whenever `num` changes:

1. `num * num` is calculated.
2. The multiplication result is stored in `tmp`.
3. `tmp` is assigned to `result`.

So:

```text
num
 │
 ├──► multiplier ───► tmp
 │                    │
 │                    ▼
 │                  result
```

For example:

```text
num = 5

5 × 5 = 25

result = 8'b00011001
```

---

## Why use `tmp`?

Functionally, the module could simply use:

```verilog
assign result = num * num;
```

The current `tmp` register is therefore mainly an **intermediate combinational variable**. It does **not** create a flip-flop because it is assigned inside `always @(*)` without a clock.

---

# 3. Testbench Analysis

The testbench uses:

```verilog
parameter n=4;
reg [n-1:0]num;
wire [2*n-1:0]result;
```

So it matches the DUT:

```text
num    = 4 bits
result = 8 bits
```

The DUT is instantiated as:

```verilog
n_bit_square dut(num, result);
```

Because `n` is not explicitly passed, the DUT uses its default:

```verilog
n = 4
```

### Random stimulus

```verilog
always begin
    num=$random;
    #10;
end
```

A new random value is assigned to `num` every 10 ns.

Since `num` is only 4 bits wide, the random value is truncated to the lower 4 bits.

Therefore, the actual tested values are between:

```text
0 → 15
```

---

### Monitoring

```verilog
$monitor("%d^2 = %0d ",num, result);
```

`$monitor` automatically prints whenever one of its arguments changes.

Example:

```text
5^2 = 25
12^2 = 144
3^2 = 9
15^2 = 225
```

---

### Simulation duration

```verilog
#80 $finish;
```

The simulation stops after 80 ns.

Because the random stimulus changes every 10 ns, approximately eight random input values are applied.

---

# 4. Advantages & Limitations

### Advantages

* Simple and easy-to-understand RTL.
* Parameterized for different input widths.
* Fully combinational.
* Synthesizable.
* Output width naturally supports the full square of an unsigned `N`-bit input.
* Useful as a basic arithmetic RTL example.

### Limitations

* Uses a hardware multiplier, which can consume significant area for large `n`.
* No pipelining, so a large multiplier can become a critical timing path.
* Testbench is **not self-checking**; it only displays results.
* Random testing does not guarantee that all input combinations are covered.
* Inputs are unsigned; signed squaring is not explicitly supported.

---

# 5. Verification Observation

For `n=4`, there are only:

$$
2^4=16
$$

possible inputs.

Therefore, an **exhaustive testbench** would actually be better than random testing here because all 16 values can easily be checked.

For example:

```text
0²  = 0
1²  = 1
2²  = 4
...
14² = 196
15² = 225
```

For larger parameter values, randomized testing becomes more practical.

---

# 6. Interview Takeaways

**One-line explanation:**

> This is a parameterized combinational N-bit unsigned squaring unit that uses multiplication to generate a 2N-bit square.

### Likely interview questions

**Q: Why is the output `2*n` bits?**
A: The product of two N-bit unsigned numbers can require up to 2N bits.

**Q: Is `tmp` a register physically?**
A: No. Although declared as `reg`, it is combinational because it is assigned inside `always @(*)`; synthesis can implement it as combinational wiring/multiplier logic.

**Q: Is this synthesizable?**
A: Yes. The multiplication operator can synthesize into multiplier hardware or map to dedicated DSP resources on an FPGA.

**Q: How would you improve the testbench?**
A: Make it self-checking and use exhaustive verification for the 4-bit case rather than only random stimulus.
