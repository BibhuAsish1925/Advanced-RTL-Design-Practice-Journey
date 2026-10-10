# 4-BIT DIVIDER

1. CIRCUIT OVERVIEW & APPLICATIONS

---

This RTL implements a 4-bit unsigned divider using a repeated-subtraction
algorithm.

Inputs:

* dividend : 4-bit dividend
* divisor  : 4-bit divisor

Outputs:

* quotient  : 4-bit quotient
* remainder : 4-bit remainder

The basic mathematical relationship is:

dividend = (divisor × quotient) + remainder

with:

0 <= remainder < divisor

The design repeatedly subtracts the divisor from the remainder until the
remaining value becomes smaller than the divisor.

Applications:

* ALUs
* Arithmetic datapaths
* Processor division units
* Embedded arithmetic
* Basic hardware arithmetic learning

2. CIRCUIT WORKING

---

The algorithm starts with:

```verilog
quotient  = 0;
remainder = dividend;
```

Then:

```verilog
while(divisor!=0 && remainder>=divisor)
begin
    remainder = remainder - divisor;
    quotient = quotient + 1;
end
```

The operation is therefore:

```text
                  dividend
                     |
                     v
              remainder = dividend
                     |
                     v
             Is divisor != 0?
                 /       \
               No         Yes
               |           |
               |      remainder >= divisor?
               |          /       \
               |        No         Yes
               |        |           |
               |        |      remainder
               |        |       -= divisor
               |        |           |
               |        |      quotient++
               |        |           |
               |        +<----------+
               |
               v
          Final outputs
```

For example:

dividend = 13
divisor  = 3

Iterations:

13 - 3 = 10    quotient = 1
10 - 3 = 7     quotient = 2
7 - 3 = 4     quotient = 3
4 - 3 = 1     quotient = 4

Final:

quotient  = 4
remainder = 1

Therefore:

13 = (3 × 4) + 1

3. RTL IMPLEMENTATION

---

The design is combinational:

```verilog
always@(dividend,divisor)
```

It has no clock or reset.

Whenever either input changes, the complete division operation is executed.

Initial values:

```verilog
quotient = 0;
remainder = dividend;
```

This establishes the starting point for repeated subtraction.

The `while` loop continues only when:

```verilog
divisor != 0
```

and:

```verilog
remainder >= divisor
```

The first condition is particularly important because it prevents an actual
division-by-zero situation from occurring inside the algorithm.

When the conditions are satisfied:

```verilog
remainder = remainder - divisor;
quotient = quotient + 1;
```

Each successful subtraction corresponds to one increment of the quotient.

4. EXAMPLE

---

Consider:

dividend = 7
divisor  = 2

Initial:

quotient  = 0
remainder = 7

Iteration 1:

remainder = 7 - 2 = 5
quotient  = 1

Iteration 2:

remainder = 5 - 2 = 3
quotient  = 2

Iteration 3:

remainder = 3 - 2 = 1
quotient  = 3

Now:

1 < 2

so the loop stops.

Result:

quotient  = 3
remainder = 1

Therefore:

7 = (2 × 3) + 1

5. DIVISION-BY-ZERO BEHAVIOR

---

The loop explicitly checks:

```verilog
divisor != 0
```

Therefore, if:

divisor = 0

the loop is skipped.

Since:

```verilog
remainder = dividend;
quotient = 0;
```

the resulting behavior is:

quotient  = 0
remainder = dividend

This prevents the loop from executing indefinitely, but it is not necessarily
a complete error-handling mechanism for a real divider. A production design
would typically provide a divide-by-zero status/error output.

6. TESTBENCH ANALYSIS

---

The testbench instantiates the divider:

```verilog
Divider uut0(
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient),
    .remainder(remainder)
);
```

Initially:

```verilog
dividend=4'b0000;
divisor=4'b0000;
```

Then random values are generated:

```verilog
always begin
    dividend=$random;
    divisor=$random;
    #50;
end
```

So new dividend and divisor values are applied every 50 time units.

7. IMPORTANT TESTBENCH LIMITATIONS

---

The testbench does not verify the result automatically.

There is no:

* `$display`
* `$monitor`
* expected quotient/remainder calculation
* PASS/FAIL checking
* `$finish`

Therefore, the testbench only provides random stimulus and requires waveform
inspection to determine whether the DUT is working correctly.

For a 4-bit divider there are only:

16 × 16 = 256

possible input combinations.

So exhaustive verification is practical.

A useful self-check would verify:

quotient  == dividend / divisor
remainder == dividend % divisor

for non-zero divisors.

For divisor = 0, the testbench should explicitly check the behavior defined
by the RTL.

8. IMPORTANT SYNTHESIS OBSERVATION

---

The `while` loop is algorithmically simple, but it is important to understand
what this means for hardware.

For example, dividing:

15 / 1

requires 15 subtraction iterations.

Because this is a combinational loop in the RTL, synthesis must create
hardware capable of representing the required repeated operations.

As operand width increases, this can lead to:

* Large combinational logic
* Longer critical paths
* Increased area
* Potentially poor timing

A practical hardware divider would commonly use an iterative clocked
architecture, restoring/non-restoring division, or another optimized divider
architecture rather than an unbounded combinational repeated-subtraction
implementation.

9. ADVANTAGES

---

* Very simple division algorithm.
* Easy to understand.
* Purely combinational.
* Synthesizable for this small width.
* Directly produces quotient and remainder.
* Explicitly prevents the subtraction loop when divisor is zero.
* Useful for understanding the relationship between quotient and remainder.

10. LIMITATIONS

---

* Fixed 4-bit unsigned operands.
* Repeated subtraction can require many iterations.
* Large combinational delay for unfavorable input combinations.
* Scaling to larger widths can significantly increase hardware complexity.
* No divide-by-zero error output.
* Current testbench is not self-checking.
* No clocked/iterative implementation is used.

11. INTERVIEW TAKEAWAYS

---

Key concept:

Repeated-subtraction division calculates the quotient by counting how many
times the divisor can be subtracted from the dividend.

Core relationship:

Dividend = Divisor × Quotient + Remainder

Termination condition:

Remainder < Divisor

Architecture:

```text
      Dividend
          |
          v
   Remainder Register
          |
          v
   Compare with Divisor
       /       \
     >=         <
      |          |
   Subtract      |
   Quotient++    |
      |          |
      +----------+
          |
          v
   Quotient + Remainder
```

One-line interview explanation:

"This RTL implements a 4-bit unsigned combinational divider using repeated
subtraction, where each successful subtraction increments the quotient and
the final value below the divisor becomes the remainder."
