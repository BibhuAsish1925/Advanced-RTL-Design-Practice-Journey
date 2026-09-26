# BOOTH MULTIPLICATION ALGORITHM — 4-BIT SIGNED MULTIPLIER

1. CIRCUIT OVERVIEW & APPLICATIONS

---

This RTL implements a 4-bit signed Booth multiplier.

Inputs:

* Q : 4-bit signed multiplier
* M : 4-bit signed multiplicand

Output:

* result : 8-bit signed multiplication result

The design uses Booth's recoding technique to perform signed multiplication.
Instead of directly multiplying the two operands, it examines adjacent bits
of the multiplier and performs either:

+M
-M
0

followed by an arithmetic right shift.

The 4-bit operands produce an 8-bit signed result.

Applications:

* ALUs and arithmetic units
* DSP datapaths
* MAC units
* Processor arithmetic units
* Low-area signed multipliers

2. HOW BOOTH MULTIPLICATION WORKS

---

The important pair is:

{Q[i], q0}

where:

Q[i] = current multiplier bit
q0   = previous multiplier bit

The Booth decision table used by the RTL is:

## Q[i] q0     Operation

```
00          0
01         +M
10         -M
11          0
```

This is implemented by:

```verilog
operation = { Q[i], q0 };

case(operation)
    2'b10 : result[7:4] = result[7:4] + M_comp;
    2'b01 : result[7:4] = result[7:4] + M;
endcase
```

where:

```verilog
M_comp = -M;
```

Therefore:

01 -> add M
10 -> add -M
00/11 -> no addition

3. RTL IMPLEMENTATION

---

The main registers/signals are:

```verilog
reg [1:0] operation;
integer i;
reg q0;
reg [3:0] M_comp;
```

`q0` stores the previous multiplier bit.

Initially:

```verilog
q0 = 1'b0;
```

The negative of the multiplicand is generated using:

```verilog
M_comp = -M;
```

The accumulator/result starts at zero:

```verilog
result = 8'd0;
```

The algorithm then executes four iterations:

```verilog
for (i=0; i<4; i=i+1)
```

because Q is 4 bits wide.

4. OPERATION IN EACH ITERATION

---

Each iteration performs:

1. Examine Q[i] and q0
2. Determine +M, -M, or 0
3. Modify the upper four bits of result
4. Arithmetic shift result right
5. Store Q[i] into q0

The shift operation is:

```verilog
result = result >> 1;
result[7] = result[6];
```

The second statement explicitly copies the previous sign bit into bit 7,
making the shift arithmetic rather than a simple logical shift.

Then:

```verilog
q0 = Q[i];
```

updates the previous-bit value for the next iteration.

Conceptually:

```text
        Q[i] + q0
              |
              v
        Booth Decoder
          /    |    \
        +M     0    -M
          \    |    /
              v
          Accumulator
              |
              v
       Arithmetic Shift
              |
              v
           Result
```

5. EXAMPLE: Q = 3, M = 7

---

The expected mathematical result is:

3 × 7 = 21

or:

8-bit result = 00010101

The multiplier Q is:

3 = 0011

Booth examines the multiplier bits together with the previous bit `q0`.

The corresponding transitions determine whether +7, -7, or 0 is added before
each arithmetic shift.

After four iterations, the result represents:

00010101 = 21

6. TESTBENCH ANALYSIS

---

The testbench applies six signed multiplication cases:

```verilog
Q= 3;  M= 7;
Q= 3;  M=-7;
Q=-3;  M=-7;
Q= 5;  M= 6;
Q= 5;  M=-6;
Q=-5; M=-6;
```

Expected results are:

3  × 7  = 21
3  × -7 = -21
-3 × -7 = 21
5  × 6  = 30
5  × -6 = -30
-5 × -6 = 30

Each test is separated by:

```verilog
#10;
```

The monitor continuously displays:

```verilog
$monitor("%d * %d = %d", Q,M,result);
```

Finally:

```verilog
#60 $finish;
```

terminates the simulation.

7. VERIFICATION QUALITY

---

The supplied testbench checks several important signed combinations:

Positive × Positive
Positive × Negative
Negative × Negative

This is useful because signed two's-complement multiplication is one of the
important aspects being demonstrated.

However, the testbench does not automatically compare the DUT result against
an expected value.

For example, it does not contain:

```verilog
if (result !== expected)
    ...
```

Therefore, it is primarily a stimulus/observation testbench rather than a
self-checking verification environment.

For stronger verification, additional boundary values should be tested,
especially:

0
1
-1
7
-8

because a signed 4-bit number has the range:

-8 to +7

8. IMPORTANT RTL OBSERVATION

---

The implementation uses:

```verilog
always @(Q,M)
```

This means the entire Booth computation is performed whenever Q or M changes.

Therefore, this is a combinational implementation of the algorithm.

The `for` loop does NOT represent four clock cycles. All four iterations are
evaluated during one execution of the `always` block.

So this design should be understood as:

Combinational Booth multiplier

rather than:

4-cycle sequential Booth multiplier.

A sequential Booth multiplier would normally have a clock, registers, and one
Booth iteration per clock cycle.

9. ADVANTAGES

---

* Supports signed multiplication.
* Uses Booth recoding to reduce unnecessary additions.
* Demonstrates two's-complement arithmetic.
* Combinational and straightforward to simulate.
* Synthesizable RTL.
* The algorithm is suitable for understanding hardware multiplication
  architectures.
* Can be extended to larger operand widths.

10. LIMITATIONS

---

* The supplied implementation is only 4-bit.
* Because it is fully combinational, increasing the width increases the
  combinational critical path.
* The design explicitly manipulates the result bits, making the implementation
  less modular than a structured accumulator/multiplier architecture.
* The testbench is not self-checking.
* No clocked/sequential implementation is provided.
* `M_comp = -M` relies on signed arithmetic and therefore requires careful
  width/sign handling when scaling the design.

11. INTERVIEW TAKEAWAYS

---

Key concept:

Booth multiplication reduces signed multiplication into a sequence of
add/subtract and arithmetic-shift operations.

Booth decision:

01 -> +M
10 -> -M
00/11 -> 0

Why Booth?

It can reduce the number of arithmetic operations when the multiplier
contains consecutive runs of 1s.

Architecture in this RTL:

Q,M
|
v
Booth decision
|
+---- +M / -M / 0
|
v
Result accumulator
|
v
Arithmetic right shift
|
v
8-bit signed result

One-line interview explanation:

"This design implements a 4-bit combinational signed Booth multiplier that
recodes adjacent multiplier bits to selectively add or subtract the
multiplicand followed by arithmetic right shifts, producing an 8-bit signed
product."
