# Parameterized RAM — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **parameterized synchronous RAM** with configurable:

* Address width
* Data width
* Memory depth
* Chip-select (`cs`)
* Write enable (`we`)
* Output enable (`oe`)

With the default parameters:

```text
ADDR_WIDTH = 4
DATA_WIDTH = 16
DEPTH      = 16
```

the memory contains:

```text
16 locations × 16 bits = 256 bits = 32 bytes
```

The basic architecture is:

```text
                 +----------------------+
 data_in ------->|                      |
 addr ---------->|  Parameterized RAM   |----> data_out
 cs ------------>|                      |
 we ------------>|                      |
 oe ------------>|                      |
 clk ------------>|                      |
                 +----------------------+
```

This type of RTL is useful for **memory modeling, register files, small embedded memories, FPGA RAM inference, and ASIC memory-wrapper design**.

---

# 2. Parameterization

The module defines:

```verilog
parameter ADDR_WIDTH=4;
parameter DATA_WIDTH=16;
parameter DEPTH=16;
```

These parameters control the memory configuration.

### Address width

```text
ADDR_WIDTH = 4
```

gives:

```text
2^4 = 16 possible addresses
```

### Data width

```text
DATA_WIDTH = 16
```

means each memory location stores 16 bits.

### Depth

```text
DEPTH = 16
```

creates:

```verilog
reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
```

which becomes:

```verilog
reg [15:0] mem [15:0];
```

So:

```text
mem[0]  → 16 bits
mem[1]  → 16 bits
...
mem[15] → 16 bits
```

---

# 3. Write Operation

The write block is:

```verilog
always @(posedge clk) 
begin
    if(cs & we)
        mem[addr] <= data_in;    
end
```

A write occurs only when:

```text
cs = 1
we = 1
```

and the operation happens at the **rising edge of `clk`**.

For example:

```text
cs      = 1
we      = 1
addr    = 2
data_in = 16'h9ABC
```

At the next rising clock edge:

```text
mem[2] = 16'h9ABC
```

So this is a **synchronous write**.

---

# 4. Read Operation

The read block is:

```verilog
always @(posedge clk) 
begin
    if(cs & !we)
        tmp_data <= mem[addr];
end
```

A memory read is performed when:

```text
cs = 1
we = 0
```

At the rising clock edge:

```text
tmp_data <= mem[addr]
```

Therefore, the internal `tmp_data` register stores the selected memory word.

This makes the read operation **synchronous**.

---

# 5. Output Enable

The actual external output is controlled by:

```verilog
assign data_out = cs & oe & !we ? tmp_data : 'hz;
```

This means:

```text
cs = 1
oe = 1
we = 0
        ↓
data_out = tmp_data
```

Otherwise:

```text
data_out = Z
```

So the output interface behaves like a tri-state memory bus.

### Control behavior

| `cs` | `we` | `oe` | Operation/output            |
| ---: | ---: | ---: | --------------------------- |
|    0 |    X |    X | `data_out = Z`              |
|    1 |    1 |    X | Write                       |
|    1 |    0 |    0 | Read internally, output `Z` |
|    1 |    0 |    1 | Read + drive `data_out`     |

Notice that `oe` does **not** control the memory read itself. It controls whether the previously captured `tmp_data` is driven externally.

---

# 6. Complete Data Flow

For a read:

```text
             rising edge
                 |
                 v
addr ──────> mem[addr]
                 |
                 v
             tmp_data
                 |
          cs & oe & !we
                 |
                 v
             data_out
```

For a write:

```text
data_in ──────────────┐
                      ↓
addr ───────────> mem[addr]
                      ↑
                   cs & we
                      ↑
                    clk
```

---

# 7. Testbench Analysis

The testbench uses the default parameters:

```verilog
ADDR_WIDTH = 4;
DATA_WIDTH = 16;
DEPTH = 16;
```

The clock is:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

---

## Test 1 — Write `1234` to Address 0

The TB applies:

```verilog
cs = 1;
we = 1;
oe = 0;
data_in = 16'h1234;
addr = 4'h0;
```

At the next rising edge:

```text
mem[0] = 16'h1234
```

---

## Test 2 — Read Address 0

Then:

```verilog
cs = 1;
we = 0;
oe = 1;
addr = 4'h0;
```

At the next rising edge:

```text
tmp_data = mem[0]
         = 16'h1234
```

and because `cs=1`, `oe=1`, and `we=0`:

```text
data_out = 16'h1234
```

---

## Test 3 — Write `9ABC` to Address 2

The TB then performs:

```verilog
cs = 1;
we = 1;
oe = 0;
data_in = 16'h9abc;
addr = 4'h2;
```

At the next rising edge:

```text
mem[2] = 16'h9ABC
```

---

## Test 4 — Read Address 2

Then:

```verilog
cs = 1;
we = 0;
oe = 1;
addr = 4'h2;
```

The RAM captures:

```text
tmp_data = mem[2] = 16'h9ABC
```

and drives:

```text
data_out = 16'h9ABC
```

The testbench checks:

```verilog
if (data_out !== 16'h9abc)
    $display("got %h", data_out);
```

So if the value is correct, nothing is printed by that `if`.

---

# 8. Important RTL Observations

### 1. This is a synchronous-read RAM

Unlike a simple asynchronous memory:

```verilog
assign data_out = mem[addr];
```

your design captures the memory value on a clock edge:

```verilog
tmp_data <= mem[addr];
```

So changing `addr` alone does not immediately change `tmp_data`.

---

### 2. `oe` controls the external bus

The memory can internally capture read data while:

```text
oe = 0
```

but `data_out` remains:

```text
Z
```

until `oe` is asserted.

This resembles a memory interface with an output-enable control.

---

### 3. `data_out` is tri-stated

```verilog
assign data_out = ... ? tmp_data : 'hz;
```

This is appropriate for modeling a shared external bus.

For modern FPGA internal logic, however, internal tri-state buses are generally synthesized into multiplexing rather than actual internal tri-state hardware.

---

### 4. Address width and depth should match

Your default values are consistent:

```text
ADDR_WIDTH = 4
DEPTH      = 16
```

because:

```text
2^ADDR_WIDTH = DEPTH
2^4 = 16
```

If these parameters are changed independently, an invalid/out-of-range address can become possible.

---

# 9. Testbench Limitation

The testbench has only a limited correctness check:

```verilog
if (data_out !== 16'h9abc)
    $display("got %h", data_out);
```

It does not explicitly print **PASS** when the value is correct.

Also, address `0` is read but not checked, while address `2` is checked twice.

A stronger RAM verification environment would:

1. Write multiple addresses.
2. Store expected values in a reference array.
3. Read every address.
4. Compare actual vs expected.
5. Test `cs=0`.
6. Test `oe=0`.
7. Test different parameter configurations.

---

# 10. Advantages & Limitations

### Advantages

* Parameterized architecture
* Configurable memory depth and data width
* Synchronous write
* Synchronous read
* Separate chip-select, write-enable, and output-enable controls
* Tri-state output behavior
* Simple synthesizable RTL

### Limitations

* No byte-enable support
* No reset/initialization of memory
* No explicit handling of simultaneous read/write
* `ADDR_WIDTH` and `DEPTH` are independently configurable
* Testbench provides limited automatic verification
* Internal tri-state modeling may not map to actual FPGA internal tri-state hardware

---

# 11. Interview Takeaways

**One-line explanation:**

> This is a parameterized synchronous RAM with configurable address/data widths and separate chip-select, write-enable, and output-enable controls.

### Key interview questions

**Q1. What is the default memory capacity?**

```text
16 × 16 = 256 bits = 32 bytes
```

**Q2. Is the read synchronous?**

Yes. `mem[addr]` is sampled into `tmp_data` on `posedge clk`.

**Q3. What does `oe` do?**

It controls whether `tmp_data` is driven onto `data_out`.

**Q4. What happens when `cs=0`?**

No read/write occurs and:

```text
data_out = Z
```

**Q5. What happens when `cs=1, we=1`?**

A write occurs on the next rising clock edge.

**Q6. What happens when `cs=1, we=0, oe=1`?**

A synchronous read occurs and the captured data is driven onto `data_out`.

**Q7. Why use parameters?**

They allow the same RTL to represent different memory configurations without rewriting the module.
