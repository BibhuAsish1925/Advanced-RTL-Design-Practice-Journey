# 3-BIT MAGNITUDE COMPARATOR

1. CIRCUIT OVERVIEW & APPLICATIONS

---

This RTL implements a 3-bit unsigned magnitude comparator.

Inputs:

* a : 3-bit input
* b : 3-bit input

Outputs:

* grth : indicates a > b
* lsth : indicates a < b
* eq   : indicates a = b
* none : default/invalid-condition indicator

Each output is 2 bits wide, but only `2'b01` is used to indicate an active
condition.

For valid binary inputs, exactly one of these conditions should be active:

a > b  -> grth = 01
a < b  -> lsth = 01
a = b  -> eq   = 01

The `none` output is intended as a fallback condition.

2. CIRCUIT WORKING

---

The comparison is performed using:

```verilog
if (a==b)
    eq=2'b01;
else if (a>b)
    grth=2'b01;
else if (a<b)
    lsth=2'b01;
else
    none=2'b01;
```

The priority of these conditions is:

```text
             Compare a and b
                    |
              +-----+-----+
              |           |
            a == b       a != b
              |           |
           eq = 01     Compare magnitude
                          |
                    +-----+-----+
                    |           |
                  a > b        a < b
                    |           |
               grth = 01    lsth = 01
```

For normal 0/1 binary values, the final `else` is effectively unreachable
because either `a>b`, `a<b`, or `a==b` must be true.

3. RTL IMPLEMENTATION

---

The outputs are declared as registers:

```verilog
output reg [1:0] grth,lsth,eq,none;
```

because they are assigned inside an `always` block.

The block is:

```verilog
always@(a,b)
```

Therefore, the comparator is purely combinational. Whenever either input
changes, the outputs are recalculated.

First, all outputs are cleared:

```verilog
grth=0;
lsth=0;
eq=0;
none=0;
```

This is important because it ensures that only the currently valid condition
is asserted.

Then the comparator evaluates the inputs.

Example:

```text
a = 101 = 5
b = 011 = 3

a > b

grth = 01
lsth = 00
eq   = 00
none = 00
```

Another example:

```text
a = 010 = 2
b = 010 = 2

a == b

grth = 00
lsth = 00
eq   = 01
none = 00
```

4. OUTPUT ENCODING

---

The output behavior is:

```text
Condition       grth   lsth   eq   none
-----------------------------------------
a > b            01     00    00    00
a < b            00     01    00    00
a = b            00     00    01    00
none             00     00    00    01
```

Although each output is 2 bits, the design only uses:

01 = active
00 = inactive

A simpler hardware interface could instead use one bit for each output, since
there are no other encoded values being used.

5. TESTBENCH ANALYSIS

---

The testbench declares:

```verilog
reg [2:0] a;
reg [2:0] b;
wire [1:0] grth,lsth,eq,none;
```

and instantiates the DUT:

```verilog
Comparator uut0(a,b,grth,lsth,eq,none);
```

The first test is:

```verilog
a=0;
b=0;
#10;
```

Therefore:

0 = 0

and `eq` should become `2'b01`.

After that, random values are generated:

```verilog
always begin
    a=$random;
    b=$random;
    #50;
end
```

A new pair of inputs is applied every 50 time units.

6. IMPORTANT TESTBENCH LIMITATIONS

---

The testbench does not automatically check the outputs.

It only generates random stimulus.

There is no:

* `$display`
* `$monitor`
* expected-value calculation
* PASS/FAIL mechanism
* `$finish`

Also, the `always` block runs forever, so the simulation must be stopped
manually.

A self-checking testbench would calculate the expected comparison and verify
that exactly the correct output is asserted.

For example, conceptually:

```text
if (a > b)   -> grth = 01
if (a < b)   -> lsth = 01
if (a == b)  -> eq   = 01
```

Since both inputs are only 3 bits, there are only:

2^3 × 2^3 = 64

possible input combinations.

Therefore, an exhaustive testbench is very practical for this design.

7. UNSIGNED COMPARISON

---

The inputs are declared:

```verilog
input [2:0]a;
input [2:0]b;
```

They are unsigned because the `signed` keyword is not used.

Therefore, the valid range is:

000 = 0
...
111 = 7

For example:

a = 111 -> 7
b = 001 -> 1

so:

a > b

8. ADVANTAGES

---

* Very simple combinational design.
* Easy to understand.
* Directly implements magnitude comparison.
* Synthesizable RTL.
* Supports all 64 possible 3-bit input combinations.
* Can easily be parameterized for larger widths.
* Useful as a basic building block for control and datapath logic.

9. LIMITATIONS

---

* Fixed at 3-bit inputs.
* Outputs are unnecessarily 2 bits wide when only one bit is required.
* The `none` condition is effectively unreachable for known binary inputs.
* The testbench is not self-checking.
* The random testbench does not guarantee coverage of all 64 combinations.
* No reset or clock is required because the design is combinational.

10. INTERVIEW TAKEAWAYS

---

Key concept:

A magnitude comparator determines whether A is greater than, less than,
or equal to B.

For this implementation:

A > B -> grth
A < B -> lsth
A = B -> eq

Architecture:

```text
        a[2:0]
           |
           v
     +-------------+
     |  Comparator |
     +-------------+
           ^
           |
        b[2:0]
           |
     +-----+-----+-----+
     |     |     |     |
    A>B   A<B   A=B   None
     |     |     |     |
   grth  lsth    eq   none
```

One-line interview explanation:

"This design implements a 3-bit unsigned combinational magnitude comparator
that generates mutually exclusive greater-than, less-than, and equal status
outputs for two input operands."
