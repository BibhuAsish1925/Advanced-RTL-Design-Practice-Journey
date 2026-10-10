# 16×16 RAM — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **16-word × 16-bit synchronous RAM**, giving a total storage capacity of:

```text
16 locations × 16 bits = 256 bits
```

### Main signals

| Signal    |  Width | Function                    |
| --------- | -----: | --------------------------- |
| `data_in` | 16-bit | Data written into memory    |
| `address` |  4-bit | Selects one of 16 locations |
| `r_en`    |  1-bit | Enables read                |
| `w_en`    |  1-bit | Enables write               |
| `clk`     |  1-bit | Clock                       |
| `d_out`   | 16-bit | Read data                   |

The memory array is:

```verilog
reg [15:0] mem[15:0];
```

which represents:

```text
mem[0]  → 16-bit word
mem[1]  → 16-bit word
...
mem[15] → 16-bit word
```

### Applications

* Register files
* Small buffers
* Lookup/storage blocks
* Embedded memory structures
* FPGA/ASIC memory design practice

---

# 2. How the RAM Works

The entire memory operation is controlled by:

```verilog
always @(posedge clk)
```

Therefore, both reading and writing occur synchronously with the rising edge of `clk`.

### Read operation

```verilog
if(r_en)
    d_out <= mem[address];
```

When `r_en = 1`, the memory location selected by `address` is read at the rising clock edge.

For example:

```text
address = 4'b0101
r_en    = 1
```

gives:

```text
d_out = mem[5]
```

---

### Write operation

```verilog
else if(w_en)
    mem[address] <= data_in;
```

When `w_en = 1` and `r_en = 0`, data is written into the selected memory location on the rising clock edge.

Example:

```text
address = 4
data_in = ABCD
w_en    = 1
```

results in:

```text
mem[4] = 16'hABCD
```

---

### No operation

```verilog
else
    d_out <= 16'bz;
```

When neither enable is asserted, `d_out` is driven to high impedance (`Z`).

So the intended behavior is:

```text
r_en=1, w_en=X → READ
r_en=0, w_en=1 → WRITE
r_en=0, w_en=0 → d_out=Z
```

Because `r_en` has priority, if both `r_en` and `w_en` are `1`, the design performs a **read**, not a write.

---

# 3. RAM Architecture

The address width is 4 bits:

```text
2^4 = 16 addresses
```

Therefore:

```text
Address 0000 → mem[0]
Address 0001 → mem[1]
...
Address 1111 → mem[15]
```

Architecture:

```text
                 +------------------+
data_in[15:0] ->|                  |
address[3:0] -->|   16 × 16 RAM    |--> d_out[15:0]
w_en ---------->|                  |
r_en ---------->|                  |
clk ------------>|                  |
                 +------------------+
```

Total capacity:

```text
16 × 16 = 256 bits = 32 bytes
```

---

# 4. Testbench Analysis

The testbench generates the clock using:

```verilog
always #5 clk=~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

Initially:

```verilog
data_in=0;
w_en=0;
r_en=0;
clk=0;
addr=0;
```

Then the testbench waits:

```verilog
#10;
```

---

## Write Phase

The first loop:

```verilog
for(i=0;i<=15;i=i+1)
begin
    w_en=1;
    addr=i;
    data_in=$random;
    #10;
end
```

writes random 16-bit values into all 16 memory locations.

Conceptually:

```text
Address       Data
-------       ----
0             random
1             random
2             random
...
15            random
```

Each address is held for one complete 10 ns clock period, so each value gets written on a rising edge.

---

## Read Phase

After writing:

```verilog
w_en=0;
```

and:

```verilog
for(i=0;i<=15;i=i+1)
begin
    r_en=1;
    addr=i;
    #10;
end
```

reads every address sequentially:

```text
mem[0]
mem[1]
mem[2]
...
mem[15]
```

The `$monitor` displays the address and corresponding `data_out`.

---

# 5. Important Timing Point

This is a **synchronous read RAM**.

For example:

```text
Before rising edge:
address = 5
r_en = 1

          ↑ rising edge
          |
          +---- d_out <= mem[5]
```

Because the assignment is nonblocking:

```verilog
d_out <= mem[address];
```

the output updates after the clock event in simulation.

This is different from an asynchronous-read RAM, where:

```verilog
assign d_out = mem[address];
```

could change whenever the address changes.

---

# 6. Important RTL Observations

### 1. `r_en` has priority over `w_en`

Your code says:

```verilog
if(r_en)
    ...
else if(w_en)
    ...
```

Therefore:

```text
r_en=1, w_en=1 → READ
```

There is no simultaneous read/write behavior defined.

---

### 2. `16'bz` is questionable for an internal registered output

You have:

```verilog
d_out <= 16'bz;
```

This models a high-impedance value when there is no read.

For an internal RAM output, it is generally more conventional to either:

* hold the previous `d_out`, or
* explicitly drive a known value.

For example, holding the previous value:

```verilog
else
    d_out <= d_out;
```

Although even this explicit self-assignment is usually unnecessary in a clocked block.

The `Z` behavior is more appropriate when modeling a **tri-state bus interface** rather than an internal RAM output.

---

### 3. The testbench does not verify the stored data

The testbench writes random values and later displays the read values, but it does not save the expected random values and compare them.

So it is an **observational testbench**, not a self-checking testbench.

A stronger TB would maintain a reference array:

```text
expected[address] = data written
```

and compare:

```text
data_out == expected[address]
```

during the read phase.

---

### 4. `$random` is suitable for this basic test

```verilog
data_in = $random;
```

generates a random value that is assigned to the 16-bit `data_in`.

For a basic RAM simulation, this provides varying data patterns rather than repeatedly writing the same value.

---

# 7. Advantages & Limitations

### Advantages

* Simple RTL representation of RAM
* Fully synthesizable memory structure
* 16 independent addresses
* 16-bit data width
* Synchronous read/write operation
* Easy to scale by changing address/data widths
* Suitable for understanding memory inference

### Limitations

* Only 256 bits of storage
* No byte-enable/write-mask support
* No simultaneous read/write policy
* `Z` output behavior may not be appropriate for inferred internal RAM
* Testbench does not automatically check correctness
* No reset/initialization of memory contents

---

# 8. Interview Takeaways

**One-line explanation:**

> This is a 16×16 synchronous single-port RAM with a 4-bit address, 16-bit data path, and separate read/write enables.

### Common interview questions

**Q1. Why is the address 4 bits?**

Because:

```text
2^4 = 16 locations
```

**Q2. What is the total memory capacity?**

```text
16 × 16 = 256 bits = 32 bytes
```

**Q3. Is the read synchronous or asynchronous?**

**Synchronous**, because the read occurs inside:

```verilog
always @(posedge clk)
```

**Q4. What happens if both `r_en` and `w_en` are high?**

Read occurs because `r_en` is checked first.

**Q5. Why is `d_out` declared `reg`?**

Because it is assigned inside a procedural `always` block.

**Q6. What does `mem[address]` mean?**

It selects the 16-bit memory word corresponding to the 4-bit address.

**Q7. What is the main improvement for the testbench?**

Store every random write value in a reference array and automatically compare it during the read phase.
