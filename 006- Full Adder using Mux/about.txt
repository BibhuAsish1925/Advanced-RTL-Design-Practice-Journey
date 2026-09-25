# MUX-BASED FULL ADDER

1. CIRCUIT OVERVIEW & APPLICATIONS

---

The given circuit implements a **1-bit Full Adder using only 2:1 Multiplexers**.

A conventional Full Adder uses XOR, AND and OR gates. This design replaces those direct logic gates with multiple 2:1 MUXes.

Inputs:

```
a
b
cin
```

Outputs:

```
sum
carry
```

The circuit uses:

```
1 × 2:1 MUX module
7 × 2:1 MUX instances
```

The main concept is **implementing Boolean logic using multiplexers**.

Applications:

* Digital logic design
* Arithmetic datapaths
* ALUs
* ASIC logic synthesis
* MUX-based Boolean-function implementation
* Understanding alternative implementations of Full Adders

2. HOW THE CIRCUIT WORKS

---

A normal Full Adder performs:

```
sum   = a XOR b XOR cin

carry = ab + cin(a XOR b)
```

This design generates the same functions using MUXes.

The MUX equation is:

```
Y = sel ? n : m
```

or:

```
Y = sel' m + sel n
```

## SUM GENERATION

First:

```
mux2_1 m0(1'b1, 1'b0, a, w[0]);
```

This produces:

```
w[0] = ~a
```

because:

```
a = 0 -> w[0] = 1
a = 1 -> w[0] = 0
```

Next:

```
mux2_1 m1(a, w[0], b, w[1]);
```

Since `w[0] = ~a`:

```
b = 0 -> w[1] = a
b = 1 -> w[1] = ~a
```

Therefore:

```
w[1] = a XOR b
```

Next:

```
mux2_1 m2(1'b1, 1'b0, w[1], w[2]);
```

This produces:

```
w[2] = ~(a XOR b)
```

Finally:

```
mux2_1 m3(w[1], w[2], cin, sum);
```

Since:

```
w[1] = a XOR b
w[2] = ~(a XOR b)
```

the MUX produces:

```
sum = (a XOR b) XOR cin
```

Therefore:

```
SUM = a XOR b XOR cin
```

## CARRY GENERATION

First:

```
mux2_1 m4(1'b0, w[1], cin, w[3]);
```

Since:

```
w[1] = a XOR b
```

this produces:

```
w[3] = cin AND (a XOR b)
```

Next:

```
mux2_1 m5(1'b0, a, b, w[4]);
```

This produces:

```
w[4] = a AND b
```

Finally:

```
mux2_1 m6(w[3], w[4], w[4], carry);
```

Here `w[4]` is used both as the select signal and as one data input.

If:

```
w[4] = 0
```

then:

```
carry = w[3]
```

If:

```
w[4] = 1
```

then:

```
carry = 1
```

Therefore:

```
carry = ab + cin(a XOR b)
```

which is the standard Full Adder carry equation.

Overall:

```
SUM   = a XOR b XOR cin

CARRY = ab + cin(a XOR b)
```

## 3. RTL CODE EXPLANATION

## 2:1 MUX MODULE

```
module mux2_1(
    input m,n,
    input sel,
    output y_out
);
```

This defines a reusable 2:1 MUX.

The inputs are:

```
m   -> MUX input 0
n   -> MUX input 1
sel -> select signal
```

The output is:

```
y_out
```

The core logic is:

```
assign y_out = sel ? n : m;
```

Therefore:

```
sel = 0 -> y_out = m
sel = 1 -> y_out = n
```

## FULL ADDER MODULE

```
wire [4:0]w;
```

Five intermediate signals are declared:

```
w[0]
w[1]
w[2]
w[3]
w[4]
```

These signals connect the MUX stages.

## MUX INSTANCES

```
mux2_1 m0(1'b1, 1'b0, a, w[0]);
```

Generates:

```
w[0] = ~a


mux2_1 m1(a, w[0], b, w[1]);
```

Generates:

```
w[1] = a XOR b


mux2_1 m2(1'b1, 1'b0, w[1], w[2]);
```

Generates:

```
w[2] = ~(a XOR b)


mux2_1 m3(w[1], w[2], cin, sum);
```

Generates:

```
sum = a XOR b XOR cin
```

Carry path:

```
mux2_1 m4(1'b0, w[1], cin, w[3]);
```

Generates:

```
w[3] = cin(a XOR b)


mux2_1 m5(1'b0, a, b, w[4]);
```

Generates:

```
w[4] = ab


mux2_1 m6(w[3], w[4], w[4], carry);
```

Combines the two carry terms:

```
carry = ab + cin(a XOR b)
```

## IMPORTANT DESIGN OBSERVATION

The design uses only MUXes to implement the Full Adder logic.

It does not directly instantiate:

```
XOR
AND
OR
NOT
```

Instead, these Boolean functions are constructed from MUX connections and constant `0`/`1` values.

4. VERIFICATION

---

No testbench was provided with this RTL.

Therefore, the supplied source only defines the DUT and does not provide simulation evidence.

A suitable verification strategy would test all 8 possible combinations of:

```
a
b
cin
```

Expected Full Adder behavior:

```
a b cin | sum carry
-------------------
0 0  0  |  0    0
0 0  1  |  1    0
0 1  0  |  1    0
0 1  1  |  0    1
1 0  0  |  1    0
1 0  1  |  0    1
1 1  0  |  0    1
1 1  1  |  1    1
```

The expected result can be checked using:

```
{carry, sum} == a + b + cin
```

Since there are only 3 inputs, exhaustive verification requires only:

```
2^3 = 8 combinations
```

## 5. ADVANTAGES & DISADVANTAGES

ADVANTAGES:

* Implements a Full Adder using only MUXes.
* Demonstrates the flexibility of multiplexers.
* Reusable `mux2_1` module keeps the design modular.
* Fully combinational.
* Synthesizable RTL.
* Useful for understanding Boolean-function decomposition.
* Good example for digital-design interviews.

DISADVANTAGES:

* Requires 7 MUXes for only one Full Adder.
* More hardware than a conventional optimized Full Adder.
* Multiple MUX levels introduce propagation delay.
* May consume more area and power than a standard gate-level implementation.
* The MUX-only structure may not map as efficiently as direct XOR/AND/OR logic depending on the target technology.

6. INTERVIEW TAKEAWAYS

---

ONE-LINE EXPLANATION:

A Full Adder can be implemented using only 2:1 MUXes by configuring the MUX inputs with constants and intermediate Boolean signals to realize the required sum and carry functions.

KEY EQUATIONS:

```
Sum = A XOR B XOR Cin

Carry = AB + Cin(A XOR B)
```

IMPORTANT CONCEPT:

A MUX can implement Boolean functions by appropriately choosing:

```
- Select input
- Data input 0
- Data input 1
```

For example:

```
MUX(0, B, A) = A.B
```

and:

```
MUX(B, 1, A) = A + B
```

## KEY INTERVIEW QUESTIONS

Why can a Full Adder be implemented using MUXes?

Because a MUX is a universal Boolean-function building block and can realize different logic functions through suitable input connections.

How many MUXes are used here?

```
7 × 2:1 MUXes
```

What does `w[1]` represent?

```
w[1] = A XOR B
```

What does `w[3]` represent?

```
w[3] = Cin(A XOR B)
```

What does `w[4]` represent?

```
w[4] = A.B
```

What is the final carry equation?

```
Carry = AB + Cin(A XOR B)
```

Why use this architecture?

It demonstrates how arithmetic logic can be constructed from a common reusable hardware primitive, which is useful for understanding logic synthesis and datapath design.

MAIN VLSI CONCEPT:

```
Conventional Full Adder
        |
        v
XOR + AND + OR logic

MUX-based Full Adder
        |
        v
   2:1 MUX network
```

The key trade-off is:

```
MUX-only implementation
-> More structural hardware
-> Potentially higher delay/area
-> Demonstrates flexible Boolean implementation
```

This is primarily a **digital-design and logic-synthesis learning circuit**, showing how a fundamental arithmetic block can be constructed using multiplexers alone.
