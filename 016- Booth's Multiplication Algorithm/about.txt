# BOOTH MULTIPLIER — 4-BIT SIGNED MULTIPLIER

1. CIRCUIT OVERVIEW & APPLICATIONS

---

This design implements a 4-bit signed Booth multiplier using Booth's
recoding algorithm.

Inputs:
A : 4-bit signed multiplier
B : 4-bit signed multiplicand

Output:
PRODUCT : 8-bit signed multiplication result

The design examines pairs of bits `{A[i], e}` and decides whether to:

01 -> Add B
10 -> Add -B
00 -> No operation
11 -> No operation

After each operation, PRODUCT is shifted right arithmetically.

Applications:

* Processor arithmetic units
* ALUs
* DSP datapaths
* MAC units
* Hardware multiplier design
* Low-complexity signed arithmetic

2. BOOTH ALGORITHM USED

---

The important part of the implementation is:

```verilog
temp = { A[i], e };

case(temp)
    2'd2 : PRODUCT[7:4] = PRODUCT[7:4] + B1;
    2'd1 : PRODUCT[7:4] = PRODUCT[7:4] + B;
endcase
```

Here:

`e` = previous multiplier bit
`A[i]` = current multiplier bit

Therefore:

## A[i] e     Operation

00          0
01         +B
10         -B
11          0

`B1` is calculated as:

```verilog
B1 = -B;
```

so it represents the two's-complement negative of B.

3. CIRCUIT WORKING

---

The computation begins with:

```verilog
PRODUCT = 8'd0;
e = 1'b0;
B1 = -B;
```

Thus:

PRODUCT = 00000000
e       = 0
B1      = -B

The `for` loop executes four times:

```verilog
for (i=0; i<4; i=i+1)
```

because A is 4 bits wide.

Each iteration performs four main operations:

1. Examine `A[i]` and `e`

2. Add B or -B when required

3. Arithmetic-right-shift PRODUCT

4. Update `e` with the current A bit

5. IMPORTANT RTL BLOCKS

---

A. Combinational execution

```verilog
always @(A,B)
```

The complete Booth multiplication is recalculated whenever A or B changes.

There is no clock in this implementation, so this is a combinational Booth
multiplier.

The four Booth iterations occur within one execution of the `always` block;
they do not represent four clock cycles.

B. Booth decision

```verilog
temp = { A[i], e };
```

This forms the two-bit Booth encoding pair.

Then:

```verilog
2'd2 : PRODUCT[7:4] = PRODUCT[7:4] + B1;
```

`2'd2` is binary `10`, so this performs:

PRODUCT upper half = PRODUCT upper half - B

And:

```verilog
2'd1 : PRODUCT[7:4] = PRODUCT[7:4] + B;
```

`2'd1` is binary `01`, so this performs:

PRODUCT upper half = PRODUCT upper half + B

C. Arithmetic shift

```verilog
PRODUCT = PRODUCT >> 1;
PRODUCT[7] = PRODUCT[6];
```

The first statement shifts PRODUCT right by one bit.

The second statement copies bit 6 into bit 7, preserving the sign during the
right shift.

Therefore, the combined operation implements an arithmetic-right shift.

D. Previous-bit update

```verilog
e = A[i];
```

The current multiplier bit becomes the previous-bit value for the next Booth
iteration.

5. EXAMPLE: A = 3, B = 4

---

Expected result:

3 × 4 = 12

A = 0011
B = 0100

The algorithm processes A from the least-significant bit toward the
most-significant bit.

At every iteration it examines:

{A[i], e}

and performs +B, -B, or nothing.

After four iterations:

PRODUCT = 00001100

which represents:

12

6. TESTBENCH ANALYSIS

---

The testbench instantiates:

```verilog
Booth_Multiplier dut(Y, A, B);
```

and applies five directed tests.

Test 1:
A = 2
B = 2
Expected = 4

Test 2:
A = 3
B = 4
Expected = 12

Test 3:
A = 3
B = -4
Expected = -12

Test 4:
A = 0
B = 0
Expected = 0

Test 5:
A = 7
B = 7
Expected = 49

Each test waits 10 ns:

```verilog
#10;
```

before checking the result.

The testbench is self-checking because it compares the DUT output against
the expected value:

```verilog
if (Y == 12)
    $display("PASS...");
else
    $display("FAIL...");
```

This is better than a testbench that only displays the waveform.

7. TESTBENCH SIGNEDNESS OBSERVATION

---

The DUT declares A and B as signed:

```verilog
input signed [3:0] A, B;
```

and PRODUCT is also signed:

```verilog
output reg signed [7:0] PRODUCT;
```

However, the testbench declares:

```verilog
reg [3:0] A, B;
wire [7:0] Y;
```

These testbench signals are unsigned.

This is important for displaying negative values.

For example, `-12` in 8-bit two's complement is:

11110100

The bit pattern is correct, but an unsigned `Y` can be displayed as 244
instead of -12.

For clearer signed verification, the testbench can declare:

```verilog
reg signed [3:0] A, B;
wire signed [7:0] Y;
```

The actual multiplication hardware does not change; this mainly makes the
testbench interpretation of signed values explicit.

8. VERIFICATION COVERAGE

---

The supplied tests cover:

Positive × Positive
Positive × Negative
Zero × Zero
Maximum positive × Maximum positive

The test `7 × 7 = 49` is particularly useful because +7 is the maximum
positive value representable by a signed 4-bit number.

The testbench could additionally cover:

-8 × 1
-8 × -1
-8 × 7
-8 × -8
1 × -1
0 × positive
0 × negative
negative × negative

9. ADVANTAGES

---

* Supports signed multiplication.
* Uses Booth recoding.
* Reduces unnecessary add/subtract operations for suitable multiplier
  patterns.
* Fully synthesizable combinational RTL.
* Simple implementation for learning and architectural study.
* Produces the full 8-bit signed product from two 4-bit operands.
* Testbench includes automatic PASS/FAIL checking.

10. LIMITATIONS

---

* Only 4-bit operands are supported.
* Fully combinational implementation can become expensive for larger widths.
* No clocked/iterative architecture is used.
* Increasing operand width increases combinational logic and delay.
* The testbench has only a small number of directed tests.
* The RTL relies on careful signed/width handling, particularly around
  `B1 = -B` and the 4-bit upper-half arithmetic.

11. INTERVIEW TAKEAWAYS

---

Key concept:

Booth multiplication converts signed multiplication into a sequence of
addition/subtraction and arithmetic-shift operations.

Booth encoding:

01 -> +B
10 -> -B
00 -> 0
11 -> 0

Architecture:

A,B
|
v
Booth Encoder
|
+---- +B / -B / 0
|
v
PRODUCT accumulator
|
v
Arithmetic right shift
|
v
8-bit PRODUCT

Important distinction:

This particular RTL is a COMBINATIONAL Booth multiplier. The four iterations
happen during one combinational evaluation; they are not four clock cycles.

One-line interview explanation:

"This RTL implements a 4-bit signed combinational Booth multiplier that examines
adjacent multiplier bits to select addition, subtraction, or no operation,
followed by arithmetic shifting to generate the 8-bit two's-complement product."
