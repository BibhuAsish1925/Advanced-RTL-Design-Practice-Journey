# 2:1 MUX-BASED LOGIC GATE IMPLEMENTATION

1. CIRCUIT OVERVIEW & APPLICATIONS

---

The given design implements basic logic gates using only 2:1 multiplexers.

Instead of directly using AND, OR and NOT gates, the circuit uses three instances of a common `mux_2_1` module to implement:

```
AND
OR
NOT
```

The main concept is **logic-function implementation using multiplexers**.

A 2:1 MUX has:

```
y = select ? i[1] : i[0]
```

Therefore:

```
select = 0 -> y = i[0]
select = 1 -> y = i[1]
```

By appropriately connecting constants (`0` and `1`) and input signals to the MUX, different Boolean functions can be implemented.

Applications:

* Digital logic design
* ASIC/FPGA datapath construction
* Multiplexer-based logic synthesis
* Programmable logic structures
* Understanding universal logic implementation
* Interview questions on MUX-based Boolean functions

2. HOW THE CIRCUIT WORKS

---

The design uses three MUXes.

GENERAL 2:1 MUX:

```
i[0] ----\
          MUX ----> y_out
i[1] ----/
            ^
          select
```

The implemented equation is:

```
y_out = select ? i[1] : i[0]
```

## AND GATE USING MUX

The code is:

```
mux_2_1 mand({b, 1'b0}, a, and_out);
```

Here:

```
i[1] = b
i[0] = 0
select = a
```

Therefore:

If a = 0:

```
AND output = 0
```

If a = 1:

```
AND output = b
```

So:

```
AND = A.B
```

Truth table:

```
A B | AND
-----------
0 0 |  0
0 1 |  0
1 0 |  0
1 1 |  1
```

## OR GATE USING MUX

The code is:

```
mux_2_1 mor({1'b1, b}, a, or_out);
```

Here:

```
i[1] = 1
i[0] = b
select = a
```

Therefore:

If a = 0:

```
OR output = b
```

If a = 1:

```
OR output = 1
```

So:

```
OR = A + B
```

Truth table:

```
A B | OR
----------
0 0 |  0
0 1 |  1
1 0 |  1
1 1 |  1
```

## NOT GATE USING MUX

The code is:

```
mux_2_1 mnot({1'b0, 1'b1}, a, not_out);
```

Here:

```
i[1] = 0
i[0] = 1
select = a
```

Therefore:

If a = 0:

```
NOT output = 1
```

If a = 1:

```
NOT output = 0
```

So:

```
NOT = ~A
```

Truth table:

```
A | NOT
--------
0 |  1
1 |  0
```

## 3. RTL CODE EXPLANATION

2:1 MUX MODULE:

```
module mux_2_1(
    input [1:0] i,
    input select,
    output y_out
);
```

The module has:

```
i[1:0] -> two MUX data inputs
select -> selection signal
y_out  -> MUX output
```

The core logic is:

```
assign y_out = select ? i[1] : i[0];
```

This is a continuous assignment and therefore describes combinational logic.

The ternary operator means:

```
select = 0 -> i[0]
select = 1 -> i[1]
```

LOGIC GATE MODULE:

```
module logic_gate_using_mux(
    input a,b,
    output and_out,
    output or_out,
    output not_out
);
```

This module generates three outputs from the two inputs.

AND:

```
mux_2_1 mand({b, 1'b0}, a, and_out);
```

`{b, 1'b0}` is a concatenation:

```
i[1] = b
i[0] = 0
```

OR:

```
mux_2_1 mor({1'b1, b}, a, or_out);
```

Here:

```
i[1] = 1
i[0] = b
```

NOT:

```
mux_2_1 mnot({1'b0, 1'b1}, a, not_out);
```

Here:

```
i[1] = 0
i[0] = 1
```

## 4. TESTBENCH EXPLANATION

The testbench declares:

```
reg a, b;
```

These drive the DUT inputs.

The outputs are:

```
wire and_out, or_out, not_out;
```

The DUT is instantiated as:

```
logic_gate_using_mux dut(a, b, and_out, or_out, not_out);
```

The testbench applies all four possible combinations of two inputs.

TEST 1:

```
A = 0
B = 0

AND = 0
OR  = 0
NOT = 1
```

TEST 2:

```
A = 0
B = 1

AND = 0
OR  = 1
NOT = 1
```

TEST 3:

```
A = 1
B = 0

AND = 0
OR  = 1
NOT = 0
```

TEST 4:

```
A = 1
B = 1

AND = 1
OR  = 1
NOT = 0
```

The testbench therefore provides complete input coverage for the two-input AND and OR functions.

MONITOR:

```
$monitor("a: %b  b: %b  and: %b  or: %b  not: %b",
         a, b, and_out, or_out, not_out);
```

This continuously prints the input and output values whenever a monitored signal changes.

SIMULATION TERMINATION:

```
#40 $finish;
```

The simulation ends after 40 ns.

5. VERIFICATION LEVEL

---

The testbench is a simple directed testbench.

It verifies all possible combinations of:

```
a = 0/1
b = 0/1
```

Therefore, the AND and OR functions receive exhaustive 2-input testing.

The NOT function depends only on `a`, so both possible input values are also tested.

The testbench does not include:

* Automatic PASS/FAIL checking
* Assertions
* Functional coverage
* Random testing

For a stronger verification environment, the outputs could be compared against:

```
and_out == (a & b)
or_out  == (a | b)
not_out == (~a)
```

## 6. ADVANTAGES & DISADVANTAGES

ADVANTAGES:

* Demonstrates how a MUX can implement Boolean functions.
* Simple and fully combinational.
* Uses a reusable MUX module.
* Helps understand MUX-based logic synthesis.
* Easy to extend to other Boolean functions.
* Good example for RTL and digital-design interviews.

DISADVANTAGES:

* May require more hardware than directly implementing a simple gate.
* Adds MUX-related propagation delay.
* For simple functions such as NOT or AND, direct gates are generally more straightforward.
* Larger Boolean functions can require multiple MUX stages.

7. INTERVIEW TAKEAWAYS

---

ONE-LINE EXPLANATION:

A 2:1 multiplexer can implement different Boolean functions by using one input as the select signal and appropriately connecting its data inputs to constants or other signals.

IMPORTANT CONCEPT:

For a 2:1 MUX:

```
Y = S' I0 + S I1
```

Using this equation:

AND:

```
I0 = 0
I1 = B
S  = A

Y = A.B
```

OR:

```
I0 = B
I1 = 1
S  = A

Y = A + B
```

NOT:

```
I0 = 1
I1 = 0
S  = A

Y = ~A
```

## KEY INTERVIEW QUESTIONS

Why can a MUX implement logic gates?

Because the MUX equation can be configured to represent different Boolean functions by selecting suitable data inputs.

Why is a MUX useful in digital design?

A MUX provides controlled data selection and can also be used as a general-purpose Boolean-function building block.

What is the main advantage of this implementation?

It demonstrates that multiple logic functions can be constructed using a common reusable MUX structure.

What is the main disadvantage?

For simple logic functions, a direct gate implementation may require less hardware and provide lower delay.

CORE CONCEPT:

```
MUX + Constants + Input Signals
             |
             v
      Boolean Function
             |
             +---- AND
             +---- OR
             +---- NOT
```

MAIN VLSI CONCEPT:

```
A multiplexer is not only a data-selection element;
with appropriate input connections, it can also be
used as a general-purpose Boolean logic implementation
block.
```
