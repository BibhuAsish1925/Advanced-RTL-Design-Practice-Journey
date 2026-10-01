# 8×16 Asynchronous ROM — Circuit Analysis

This design implements a **small asynchronous ROM** with:

```text
Memory depth  = 8 words
Data width    = 16 bits
Address       = 3 bits
Capacity      = 8 × 16 = 128 bits = 16 bytes
```

Unlike the previous synchronous ROM, this ROM has **no clock and no read enable**. The output changes whenever the address changes.

---

## 1. Circuit Overview & Applications

The architecture is:

```text
             address[2:0]
                  |
                  v
          +---------------+
          |               |
          |    8 × 16     |
          |      ROM      |
          |               |
          +-------+-------+
                  |
                  v
              data[15:0]
```

The 3-bit address selects one of eight 16-bit words.

```text
2^3 = 8 locations
```

The stored contents are:

| Address |       Data |
| ------: | ---------: |
|       0 | `16'h0001` |
|       1 | `16'h0002` |
|       2 | `16'h0003` |
|       3 | `16'h0001` |
|       4 | `16'h0002` |
|       5 | `16'h0003` |
|       6 | `16'h00FE` |
|       7 | `16'h00FF` |

Possible applications include:

* Lookup tables
* Constant-data storage
* Decoder tables
* Small control tables
* FPGA/ASIC ROM structures
* Combinational constant mapping

---

# 2. ROM Memory Declaration

The memory is:

```verilog
reg [15:0] mem [0:7];
```

This means:

```text
8 memory locations
×
16 bits per location
```

Total:

```text
8 × 16 = 128 bits
```

or:

```text
16 bytes
```

The address range is:

```text
000 → 111
 0     7
```

---

# 3. ROM Initialization

The `initial` block defines the ROM contents:

```verilog
initial begin
    mem[0] = 16'h0001;
    mem[1] = 16'h0002;
    mem[2] = 16'h0003;
    mem[3] = 16'h0001;
    mem[4] = 16'h0002;
    mem[5] = 16'h0003;
    mem[6] = 16'h00FE;
    mem[7] = 16'h00FF;
end
```

Therefore:

```text
address = 3'b000 → data = 0001
address = 3'b001 → data = 0002
address = 3'b010 → data = 0003
...
address = 3'b111 → data = 00FF
```

The memory contents are fixed; there is no write interface.

---

# 4. Asynchronous Read Operation

The most important part is:

```verilog
always @(*) begin
    data = mem[address];
end
```

Because this is a combinational `always @(*)` block, there is **no clock involved**.

The operation is simply:

```text
address
   |
   v
mem[address]
   |
   v
data
```

For example:

```text
address = 3'b110
```

selects:

```text
mem[6]
```

which contains:

```text
16'h00FE
```

so:

```text
data = 16'h00FE
```

---

# 5. Why It Is Called Asynchronous ROM

There is no:

```text
clk
```

and no:

```text
always @(posedge clk)
```

Therefore, the output does not wait for a clock edge.

Conceptually:

```text
Synchronous ROM:

address → wait for clock → data


Asynchronous ROM:

address ───────────────→ data
          immediate
```

So when `address` changes, `data` responds through combinational logic.

---

# 6. Testbench Operation

The testbench has only:

```verilog
reg [2:0] address;
wire [15:0] data;
```

There is no clock because the DUT does not require one.

The DUT is instantiated:

```verilog
asynchronous_rom dut (
    .address(address),
    .data(data)
);
```

---

## Address 0 Test

```verilog
address = 3'b000;
#10;
$display(...)
```

Expected:

```text
Address = 0
Data    = 0001
```

---

## Address 1 Test

```verilog
address = 3'b001;
```

Expected:

```text
Address = 1
Data    = 0002
```

---

## Address 6 Test

```verilog
address = 3'b110;
```

Expected:

```text
Address = 6
Data    = 00FE
```

---

## Address 7 Test

```verilog
address = 3'b111;
```

Expected:

```text
Address = 7
Data    = 00FF
```

So the TB tests:

```text
0
1
6
7
```

including the upper two addresses.

---

# 7. Why `#10` Is Used

For example:

```verilog
address = 3'b000;
#10;
$display(...);
```

The `#10` is simply allowing simulation time to pass before displaying the result.

It is **not required by the RTL for synchronization**, because the ROM itself is asynchronous.

The output should respond as soon as the combinational logic evaluates after the address change.

In real hardware, the output would have a finite **combinational propagation delay**, but this RTL does not explicitly model that delay.

---

# 8. Testbench Flow

```text
             START
               |
               v
          address = 0
               |
              #10
               |
          display data
               |
               v
          address = 1
               |
              #10
               |
          display data
               |
               v
          address = 6
               |
              #10
               |
          display data
               |
               v
          address = 7
               |
              #10
               |
          display data
               |
               v
        All tests completed
               |
               v
            $finish
```

---

# 9. Expected Simulation

The expected output is approximately:

```text
Data at address 0 is 0001
Data at address 1 is 0002
Data at address 6 is 00fe
Data at address 7 is 00ff
All tests completed.
```

The `%h` formatting causes the address and data to be displayed in hexadecimal.

---

# 10. Advantages

### Simple

The implementation is extremely compact:

```verilog
data = mem[address];
```

### No clock required

Useful when the ROM must provide combinational lookup data.

### Low interface complexity

Only address and data are required.

### Easy lookup-table implementation

The structure naturally represents a fixed mapping between addresses and values.

---

# 11. Limitations

### 1. No self-checking

The testbench only uses:

```verilog
$display(...)
```

It does not compare actual data with expected data.

For example, there is no:

```verilog
if (data !== expected)
```

So a wrong output would still result in:

```text
All tests completed.
```

even if the ROM were incorrect.

---

### 2. Only four addresses are tested

The ROM has eight addresses:

```text
0–7
```

but the TB tests only:

```text
0, 1, 6, 7
```

An exhaustive test of all eight addresses would be very easy.

---

### 3. `initial` memory initialization

The `initial` block is convenient for simulation and can be supported by some FPGA ROM inference flows. For ASIC implementation, ROM contents would normally be implemented using an appropriate ROM structure/macro rather than relying on an RTL simulation initialization block.

---

### 4. No explicit timing model

The RTL describes functional asynchronous behavior but does not model actual ROM propagation delay.

---

# 12. Interview Takeaways

### One-line explanation

> **This is an 8×16 asynchronous ROM in which a 3-bit address directly selects one of eight predefined 16-bit data words without requiring a clock.**

### Key questions

**Q: What is the ROM capacity?**

```text
8 × 16 = 128 bits = 16 bytes
```

**Q: Why is the address 3 bits?**

```text
2^3 = 8 locations
```

**Q: Is the read synchronous?**

No. It is **asynchronous/combinational**.

**Q: Why is there no clock?**

Because the output is directly determined by the address:

```text
data = mem[address]
```

**Q: What happens when the address changes?**

The selected ROM word changes at the output after the combinational propagation/evaluation delay.

**Q: How does this differ from your previous `simple_rom`?**

| Feature     | `simple_rom` | `asynchronous_rom` |
| ----------- | ------------ | ------------------ |
| Depth       | 256          | 8                  |
| Data width  | 32 bits      | 16 bits            |
| Address     | 8 bits       | 3 bits             |
| Clock       | Yes          | No                 |
| Read        | Synchronous  | Asynchronous       |
| Output      | Registered   | Combinational      |
| Read enable | Yes          | No                 |
| Reset       | Yes          | No                 |

**Interview summary:** This is a basic **asynchronous lookup ROM**, whereas your previous `simple_rom` was a **synchronous registered-output ROM**.
