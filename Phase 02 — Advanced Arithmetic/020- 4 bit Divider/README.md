# 4-BIT UNSIGNED DIVIDER

1. CIRCUIT OVERVIEW & APPLICATIONS

---

This RTL implements a 4-bit unsigned divider using the repeated-subtraction
method.

Inputs:

* dividend : 4-bit dividend
* divisor  : 4-bit divisor

Outputs:

* quotient  : 4-bit quotient
* remainder : 4-bit remainder

The basic relationship is:

dividend = (divisor × quotient) + remainder

The design repeatedly subtracts the divisor from the dividend/remainder and
increments the quotient until the remainder becomes smaller than the divisor.

Applications:

* ALUs
* Processor arithmetic units
* Digital arithmetic datapaths
* Embedded systems
* Hardware arithmetic learning

2. CIRCUIT WORKING

---

The algorithm starts with:

```text
quotient  = 0
remainder = dividend
```

Then it checks:

```text
divisor != 0
AND
remainder >= divisor
```

If both conditions are true:

```text
remainder = remainder - divisor
quotient  = quotient + 1
```

This repeats until:

```text
remainder < divisor
```

Example:

dividend = 13
divisor  = 3

```text
Initial:   remainder = 13, quotient = 0
Step 1:    remainder = 10, quotient = 1
Step 2:    remainder =  7, quotient = 2
Step 3:    remainder =  4, quotient = 3
Step 4:    remainder =  1, quotient = 4
```

Final:

quotient  = 4
remainder = 1

Therefore:

13 = (3 × 4) + 1

3. RTL IMPLEMENTATION

---

The main combinational block is:

```verilog
always@(dividend,divisor)
```

It executes whenever either input changes.

The initial conditions are:

```verilog
quotient = 0;
remainder = dividend;
```

Then:

```verilog
while(divisor!=0 && remainder>=divisor)
```

ensures that the loop only executes when division is possible.

Inside the loop:

```verilog
remainder = remainder - divisor;
quotient = quotient + 1;
```

Each subtraction represents one unit of the quotient.

There is no clock or reset, so this is a combinational implementation.

4. HARDWARE CONCEPT

---

The algorithm can be represented as:

```text
             dividend
                 |
                 v
          +--------------+
          |  Remainder   |
          +--------------+
                 |
                 v
        +-------------------+
        | remainder >=      |
        | divisor ?         |
        +-------------------+
             |          |
            YES         NO
             |           |
             v           v
       remainder -= D   Finish
       quotient++
             |
             +----------+
```

where D represents the divisor.

5. DIVIDE-BY-ZERO HANDLING

---

The condition:

```verilog
divisor != 0
```

prevents the loop from executing when the divisor is zero.

For:

```text
dividend = X
divisor  = 0
```

the current RTL produces:

```text
quotient  = 0
remainder = dividend
```

This avoids an infinite subtraction loop.

However, there is no separate error output indicating that a divide-by-zero
operation occurred. A production divider would normally define an explicit
error/status behavior.

6. TESTBENCH ANALYSIS

---

The testbench creates:

```verilog
reg [3:0] dividend,divisor;
wire [3:0] quotient,remainder;
```

and instantiates the DUT:

```verilog
four_bit_divider dut(dividend,divisor,quotient,remainder);
```

Random stimulus is generated continuously:

```verilog
always begin
    dividend =$random;
    divisor =$random;
    #10;
end
```

Therefore, a new dividend/divisor pair is applied every 10 ns.

The monitor:

```verilog
$monitor("%0d / %0d = %0d with remainder %0d ",
         dividend,divisor,quotient,remainder);
```

continuously prints the current inputs and outputs.

7. TESTBENCH STRENGTHS & LIMITATIONS

---

The monitor makes the simulation easy to observe because the quotient and
remainder are printed automatically.

The simulation terminates after:

```verilog
#100 $finish;
```

so the testbench runs for 100 ns.

However, it is not a self-checking testbench.

It does not calculate an expected value and compare it with the DUT output.

Also, because `$random` can generate zero for `divisor`, the testbench will
occasionally exercise the divide-by-zero behavior. This is useful for
observing the existing protection, but the testbench does not explicitly
label it as an error or special case.

8. VERIFICATION COVERAGE

---

Since the operands are 4 bits:

dividend: 0–15
divisor : 0–15

There are only:

16 × 16 = 256

possible input combinations.

Therefore, exhaustive verification is practical.

Important cases include:

```text
0 / 1
1 / 1
7 / 2
13 / 3
15 / 1
15 / 15
8 / 4
5 / 7
10 / 0
15 / 0
```

For every non-zero divisor, the expected result must satisfy:

```text
dividend = divisor × quotient + remainder
0 <= remainder < divisor
```

9. ADVANTAGES

---

* Very simple division algorithm.
* Easy to understand and implement.
* Purely combinational.
* Synthesizable for this small operand width.
* Produces both quotient and remainder.
* Explicitly prevents the loop from executing for divisor = 0.
* Good example for understanding iterative arithmetic algorithms.

10. LIMITATIONS

---

* Fixed 4-bit unsigned operands.
* Repeated subtraction can require many iterations.
* Large combinational delay compared with optimized divider architectures.
* Scaling to larger widths can significantly increase hardware complexity.
* No explicit divide-by-zero error output.
* Testbench uses random testing rather than exhaustive/self-checking
  verification.
* No clocked/iterative architecture is used.

11. INTERVIEW TAKEAWAYS

---

Key concept:

Repeated-subtraction division obtains the quotient by counting how many
times the divisor can be subtracted from the dividend.

Core equation:

Dividend = Divisor × Quotient + Remainder

Termination condition:

Remainder < Divisor

Architecture:

```text
Dividend
   |
   v
Remainder
   |
   v
Compare with Divisor
   |
   +---- remainder >= divisor ----+
   |                              |
   v                              |
Subtract divisor                  |
Increment quotient --------------+
   |
   v
Final quotient + remainder
```

One-line interview explanation:

"This RTL implements a 4-bit unsigned combinational divider using repeated
subtraction, where each successful subtraction increments the quotient and
the final value smaller than the divisor becomes the remainder."
