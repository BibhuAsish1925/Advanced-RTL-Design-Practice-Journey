# 16×16 Synchronous ROM — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **16-word × 16-bit synchronous Read-Only Memory (ROM)**.

```text
Memory depth  = 16 words
Data width    = 16 bits
Address       = 4 bits
Capacity      = 16 × 16 = 256 bits = 32 bytes
```

The ROM contains **predefined constant data**. Unlike RAM, there is no write interface; the testbench directly initializes the memory contents for simulation.

### Main signals

| Signal | Width | Purpose                     |
| ------ | ----: | --------------------------- |
| `clk`  |     1 | Read clock                  |
| `r_en` |     1 | Read enable                 |
| `addr` |     4 | Selects one of 16 locations |
| `data` |    16 | Registered ROM output       |

Typical applications include:

* Instruction/data lookup tables
* Microcontroller instruction ROM
* FPGA initialization tables
* Constant coefficient storage
* Address-to-data lookup tables
* Control/configuration tables

---

# 2. ROM Architecture

The memory is declared as:

```verilog
reg [15:0] mem [15:0];
```

This means:

```text
             4-bit address
                  |
                  v
        +-------------------+
        |                   |
        |    16 × 16 ROM    |
        |                   |
        +-------------------+
                  |
             16-bit data
                  |
                  v
               data
```

There are:

```text
2^4 = 16
```

locations.

Each location stores:

```text
16 bits
```

Therefore:

```text
16 × 16 = 256 bits
```

or:

```text
32 bytes
```

---

# 3. How the ROM Works

The core logic is:

```verilog
always@(posedge clk) begin
    if(r_en)
        data <= mem[addr];
    else
        data <= 'bz;
end
```

### When `r_en = 1`

At the rising edge of `clk`:

```text
data <= mem[addr]
```

For example:

```text
addr = 4
mem[4] = 16'h4839
```

At the next `posedge clk`:

```text
data = 16'h4839
```

Therefore, this is a **synchronous ROM read**.

### When `r_en = 0`

The code executes:

```verilog
data <= 'bz;
```

so the output is driven to high impedance (`Z`).

For simulation, this represents the ROM output being disconnected/tri-stated when reading is disabled.

---

# 4. ROM Contents

The testbench initializes all 16 locations:

```text
Address    Data
-------------------
0          0103
1          5200
2          E0B9
3          0412
4          4839
5          0112
6          0377
7          0572
8          CAFE
9          6225
10         1447
11         AEEC
12         52DD
13         1113
14         4444
15         5555
```

For example:

```verilog
dut.mem[8] = 16'hcafe;
```

means:

```text
ROM address 8 → CAFE
```

The testbench accesses the internal memory directly using the hierarchical reference:

```verilog
dut.mem[address]
```

This is convenient for simulation, but in actual ROM hardware the contents would normally be initialized through the ROM implementation/configuration rather than by a testbench.

---

# 5. Testbench Clock

The testbench generates:

```verilog
forever #5 clk <= ~clk;
```

Therefore:

```text
Half period = 5 ns
Full period = 10 ns
Frequency   = 100 MHz
```

Waveform:

```text
clk
    __      __      __
___/  \____/  \____/  \___
   5ns  5ns
```

The ROM only updates `data` at the rising edge.

---

# 6. Testbench Operation

Initially:

```verilog
addr = 0;
r_en = 0;
```

Therefore the first read is disabled.

After:

```verilog
#10 r_en = 1;
```

reading begins.

Then the testbench changes:

```text
addr = 1
addr = 2
addr = 3
...
addr = 15
```

every 10 ns.

So the intended sequence is:

```text
0 → 1 → 2 → 3 → ... → 15
```

and the expected ROM output is:

```text
0103 → 5200 → E0B9 → 0412 → ...
```

---

# 7. Important Timing Point

There is a useful timing detail in the testbench.

The address changes every:

```text
10 ns
```

which is exactly one clock period.

For example:

```verilog
#10 addr = 1;
#10 addr = 2;
```

Since the ROM samples `addr` only at `posedge clk`, each address remains stable for approximately one clock cycle.

Thus:

```text
Address stable
      |
      v
posedge clk
      |
      v
data <= mem[addr]
```

Because `data` is a nonblocking assignment, the new output appears immediately after the clock event in simulation.

---

# 8. Why This Is a Synchronous ROM

A purely asynchronous ROM would look conceptually like:

```verilog
assign data = mem[addr];
```

where changing `addr` immediately changes the output.

Your design instead has:

```verilog
always @(posedge clk)
    data <= mem[addr];
```

Therefore:

```text
Address changes
      ↓
Wait for rising clock edge
      ↓
ROM data is captured
      ↓
data changes
```

So it is a **synchronous-read ROM**.

---

# 9. Advantages

### Simple architecture

Only a memory array and read logic are required.

### Predictable timing

The output changes only on the clock edge.

### No write circuitry

Since it is a ROM, there is no `we` or write-data interface.

### Easy lookup-table implementation

The architecture is suitable for fixed constants and lookup tables.

### Small address/data interface

Only 4 address bits are required to select all 16 entries.

---

# 10. Limitations / RTL Considerations

### 1. `Z` on an internal registered output

This:

```verilog
data <= 'bz;
```

is primarily a simulation-style tri-state representation.

For FPGA internal logic, internal tri-states generally do not map to physical tri-state buses; synthesis typically converts them into muxing or equivalent logic.

For a normal synchronous ROM, it is often cleaner to **hold the previous output** or explicitly define a disabled-output value.

---

### 2. Memory is initialized from the testbench

The testbench uses:

```verilog
dut.mem[0] = ...
```

This is valid for simulation, but it does not itself describe how the ROM contents would physically be implemented.

For an FPGA, ROM contents can typically be initialized through an inferred ROM/initialization mechanism. For an ASIC, the ROM would normally be implemented using an appropriate ROM macro or synthesized structure.

---

### 3. No self-checking

The testbench uses:

```verilog
$monitor(...)
```

but does not compare the actual output against an expected value.

Therefore, it is an **observational testbench**, not a self-checking testbench.

A stronger verification environment would contain:

```text
Expected data
     ↓
Compare with data_out
     ↓
PASS / FAIL
```

---

# 11. Testbench Flow

```text
       Initialize ROM contents
                 |
                 v
          Apply reset-like
          read disable
                 |
                 v
             r_en = 1
                 |
                 v
       Address 0 → read 0103
                 |
                 v
       Address 1 → read 5200
                 |
                 v
       Address 2 → read E0B9
                 |
                ...
                 |
                 v
       Address 15 → read 5555
                 |
                 v
              $finish
```

One thing to note: this design has **no reset signal**. The initial `r_en=0` in the testbench simply prevents reading until the ROM test begins.

---

# 12. Interview Takeaways

### One-line explanation

> This is a 16×16 synchronous ROM where a 4-bit address selects one of sixteen predefined 16-bit words, and the selected data is registered on the rising edge of the clock.

### Important interview questions

**Q: What is the ROM capacity?**

```text
16 × 16 = 256 bits = 32 bytes
```

**Q: Why is the address 4 bits?**

```text
2^4 = 16 locations
```

**Q: Is the read synchronous or asynchronous?**

**Synchronous**, because `data` is updated inside `always @(posedge clk)`.

**Q: Does the ROM have a write operation?**

No. There is no write enable or write data interface.

**Q: What does `r_en` do?**

It enables the read operation. When asserted, the selected ROM word is loaded into `data`.

**Q: What happens when `r_en=0`?**

The supplied RTL assigns `Z` to `data`.

**Q: What is the main difference between this ROM and the RAM designs you provided earlier?**

```text
RAM:
Read + Write
Memory contents can change during operation

ROM:
Read only
Contents are predefined
```

### Interview-ready summary

> **16×16 synchronous ROM, 4-bit address, 16-bit registered output, read enable, and simulation-initialized constant memory contents.**
