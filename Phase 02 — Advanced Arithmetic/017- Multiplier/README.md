# 4-BIT SHIFT-AND-ADD MULTIPLIER

1. CIRCUIT OVERVIEW & APPLICATIONS

---

This RTL implements a 4-bit unsigned multiplier using the conventional
shift-and-add multiplication technique.

Inputs:

* a : 4-bit multiplicand
* b : 4-bit multiplier

Output:

* out : 8-bit product

The multiplier examines each bit of `b`. If a bit is `1`, the multiplicand
`a` is shifted by that bit position and added to the final result.

Conceptually:

out = (b[0] ? a<<0 : 0)
+ (b[1] ? a<<1 : 0)
+ (b[2] ? a<<2 : 0)
+ (b[3] ? a<<3 : 0)

Applications:

* ALUs
* Arithmetic datapaths
* Embedded processors
* DSP hardware
* Educational multiplier architectures

2. CIRCUIT WORKING

---

The design generates four partial products:

t1 = a × b[0]
t2 = a × b[1] × 2
t3 = a × b[2] × 4
t4 = a × b[3] × 8

These partial products are then added:

out = t1 + t2 + t3 + t4

For example:

a = 4'b1010 = 10
b = 4'b0101 = 5

Since:

b[0] = 1 -> t1 = 10
b[1] = 0 -> t2 = 0
b[2] = 1 -> t3 = 40
b[3] = 0 -> t4 = 0

Therefore:

out = 10 + 40 = 50

3. RTL IMPLEMENTATION

---

The four temporary registers are:

```verilog
reg [7:0] t1,t2,t3,t4;
```

They store the four shifted partial products.

Initially:

```verilog
t1=0; t2=0; t3=0; t4=0;
```

This prevents an old partial-product value from being retained.

For bit 0:

```verilog
if(b[0]) 
    t1 = a<<0;
```

If `b[0]` is 1, `a` contributes directly.

For bit 1:

```verilog
if(b[1]) 
    t2 = a<<1;
```

The multiplicand is shifted left by one position, equivalent to multiplying
it by 2.

Similarly:

```verilog
if(b[2]) 
    t3 = a<<2;

if(b[3]) 
    t4 = a<<3;
```

Finally:

```verilog
out = t1+t2+t3+t4;
```

adds all partial products.

This is a combinational circuit because the sensitivity list is:

```verilog
always@(a,b)
```

There is no clock.

4. HARDWARE INTERPRETATION

---

The RTL can be viewed as:

```text
             a
             |
       +-----+-----+-----+
       |     |     |     |
      <<0   <<1   <<2   <<3
       |     |     |     |
      t1    t2    t3    t4
       |     |     |     |
       +-----+-----+-----+
                 |
              Adder Tree
                 |
                out
```

The `b` bits act as enables for the corresponding partial products.

For a synthesis implementation, the shifts by constant amounts are generally
just wiring, while the additions form the main arithmetic logic.

5. TESTBENCH ANALYSIS

---

The testbench declares:

```verilog
reg [3:0] a,b;
wire [7:0] out;
```

and connects them to the DUT:

```verilog
Multiplier uut0(.a(a),.b(b),.out(out));
```

Initially:

```verilog
a=4'b0;
b=4'b0;
#100;
```

so the multiplier starts with:

0 × 0 = 0

After every 100 time units:

```verilog
a=$random;
b=$random;
```

random values are assigned to the two inputs.

Therefore, the testbench provides random stimulus to the multiplier.

6. IMPORTANT TESTBENCH LIMITATIONS

---

The current testbench does NOT check whether the output is correct.

It only changes:

```verilog
a
b
```

and allows the waveform viewer to show:

```verilog
out
```

There is no:

* `$display`
* `$monitor`
* expected-value calculation
* PASS/FAIL check
* `$finish`

Also, this block:

```verilog
always begin
    #100;
    a=$random;
    b=$random;
end
```

runs forever.

So the simulation does not terminate automatically.

A stronger testbench should calculate:

```verilog
expected = a * b;
```

and compare it against `out`.

7. DATA TYPE OBSERVATION

---

The design uses:

```verilog
input [3:0] a,b
```

rather than signed inputs.

Therefore, this implementation is an unsigned multiplier.

For 4-bit inputs:

Range = 0 to 15

Maximum product:

15 × 15 = 225

which fits inside the 8-bit output:

225 = 8'b11100001

8. ADVANTAGES

---

* Very simple multiplier architecture.
* Easy to understand and implement.
* Fully combinational.
* Synthesizable RTL.
* Uses basic shift and addition operations.
* Easy to scale conceptually to larger operand widths.
* Useful for understanding how binary multiplication maps to hardware.

9. LIMITATIONS

---

* This is an unsigned multiplier.
* Four separate partial-product paths are generated.
* Multiple additions can create a relatively long combinational path.
* Larger widths increase area and delay.
* It does not exploit Booth encoding or other multiplier optimizations.
* The testbench does not automatically verify correctness.
* No clocked/iterative implementation is used.

10. INTERVIEW TAKEAWAYS

---

Key concept:

Binary multiplication can be implemented by conditionally shifting the
multiplicand according to each multiplier bit and adding the partial
products.

For an N-bit multiplier:

Product = Σ (multiplier[i] ? multiplicand << i : 0)

Architecture:

```text
Multiplier bits
      |
      v
Conditional shifts
      |
      v
Partial products
      |
      v
Addition
      |
      v
    Product
```

One-line interview explanation:

"This RTL implements a 4-bit unsigned combinational shift-and-add multiplier,
where each multiplier bit conditionally generates a shifted partial product
and the four partial products are summed to produce the 8-bit result."
