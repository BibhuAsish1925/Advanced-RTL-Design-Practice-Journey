This example demonstrates **endianness conversion in Verilog**, specifically converting a 32-bit word between **little-endian byte ordering and big-endian byte ordering**.

# 32-BIT ENDIANNESS CONVERTER

================================

## 1. CIRCUIT OVERVIEW & APPLICATIONS

The `Endianess` module takes a 32-bit input word and produces two 32-bit outputs:

```text
data_in
   |
   +----> little_e
   |
   +----> big_e
```

The circuit operates at the **byte level**. Since 32 bits = 4 bytes:

```text
data_in = [31:24] [23:16] [15:8] [7:0]
            B3       B2       B1      B0
```

The module produces:

```text
little_e = B0 B1 B2 B3
big_e    = B3 B2 B1 B0
```

This type of byte reordering is useful in:

* Processor and memory interfaces
* Network protocols
* Communication interfaces
* File/data-format conversion
* CPU architectures with different byte-order conventions
* RTL datapath and bus adaptation

---

## 2. HOW THE CIRCUIT WORKS

### Big-endian output

The code is:

```verilog
assign big_e = {data_in[31:24],
                data_in[23:16],
                data_in[15:8],
                data_in[7:0]};
```

The byte order is unchanged.

For example:

```text
data_in = 32'h12_34_56_78

big_e  = 32'h12_34_56_78
```

So:

```text
Big-endian = MSB byte → LSB byte
             12 34 56 78
```

### Little-endian output

The code is:

```verilog
assign little_e = {data_in[7:0],
                   data_in[15:8],
                   data_in[23:16],
                   data_in[31:24]};
```

The four bytes are reversed:

```text
Input:
12 34 56 78

Output:
78 56 34 12
```

Therefore:

```text
little_e = 32'h78_56_34_12
```

---

## 3. IMPORTANT POINT ABOUT ENDianness

The RTL is performing a **byte-order transformation**.

It does NOT reverse individual bits inside each byte.

For example:

```text
12 34 56 78
```

becomes:

```text
78 56 34 12
```

and not:

```text
48 2C 6A 1E
```

So the operation is:

```text
BYTE REVERSAL
```

not:

```text
BIT REVERSAL
```

---

# 4. TESTBENCH

The testbench declares:

```verilog
reg  [31:0] data_in;
wire [31:0] little_e;
wire [31:0] big_e;
```

The DUT is instantiated as:

```verilog
Endianess uut0(data_in,little_e,big_e);
```

The first stimulus is:

```verilog
data_in = 32'b0;
#10;
```

So initially:

```text
data_in  = 00000000
little_e = 00000000
big_e    = 00000000
```

Then the testbench continuously generates random input values:

```verilog
always begin
    data_in = $random;
    #50;
end
```

Every 50 time units, a new random 32-bit value is applied.

---

## 5. ONE IMPORTANT ISSUE WITH THE TESTBENCH

Your testbench does **not display or check the outputs**.

There is no:

```verilog
$monitor
```

or:

```verilog
$display
```

and there is no PASS/FAIL comparison.

Therefore, the testbench mainly generates stimulus. You need to inspect `little_e` and `big_e` in the waveform window.

For example, a better basic monitoring version would be:

```verilog
initial begin
    $monitor("[%0t] data_in=%h little_e=%h big_e=%h",
             $time, data_in, little_e, big_e);

    data_in = 32'b0;
    #10;
end
```

Then you can directly observe the conversion.

---

# 6. EXAMPLE

Suppose:

```text
data_in = 32'h12_34_56_78
```

Then:

```text
Byte representation:

[31:24] = 12
[23:16] = 34
[15:8]  = 56
[7:0]   = 78
```

Therefore:

```text
little_e = 78 56 34 12
          = 32'h78_56_34_12

big_e    = 12 34 56 78
          = 32'h12_34_56_78
```

---

# 7. ADVANTAGES & LIMITATIONS

Advantages:

* Very simple combinational implementation.
* No clock or sequential logic required.
* Byte reversal is performed directly using concatenation.
* Synthesizable.
* Essentially just wiring/routing, so there is little computational logic.

Limitations:

* Current implementation is fixed at 32 bits.
* Only byte-level endian conversion is implemented.
* Testbench does not automatically verify correctness.
* No configurable byte width or selectable endian mode.

---

# 8. INTERVIEW TAKEAWAY

**Question:** What does an endian converter do?

**Answer:**

> An endian converter rearranges the byte ordering of a multi-byte data word. In this 32-bit design, little-endian conversion reverses the order of the four 8-bit bytes, while the big-endian output preserves the original byte ordering.

### Key RTL concept

```verilog
{data_in[7:0],
 data_in[15:8],
 data_in[23:16],
 data_in[31:24]}
```

is simply **byte swapping using concatenation**.

### Complexity

```text
Logic computation : Essentially none
Hardware          : Wiring/routing
Clock required    : No
Type              : Combinational
```
