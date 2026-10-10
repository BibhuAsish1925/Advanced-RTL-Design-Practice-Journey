# Dual-Port RAM with Dual Clock Domains — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **true dual-port RAM-style architecture with independent write and read clock domains**.

It has:

* `clk_wr` → write clock
* `clk_rd` → read clock
* `wr_en`, `wr_addr`, `data_in` → write interface
* `rd_en`, `rd_addr` → read interface
* `data_out` → registered read data
* `rst_n` → asynchronous active-low reset for the memory

Default memory organization:

```text
256 locations × 32 bits
= 8192 bits
= 1024 bytes
= 1 KB
```

Architecture:

```text
                    WRITE DOMAIN
                 +----------------+
 wr_addr ------->|                |
 data_in ------->|                |
 wr_en --------->|      RAM       |
 clk_wr -------->|                |
                 |                |
                 +-------+--------+
                         |
                    Shared memory
                         |
                 +-------+--------+
                 |                |
 rd_addr ------->|      RAM       |----> data_out
 rd_en --------->|                |
 clk_rd -------->|                |
                 +----------------+
                    READ DOMAIN
```

The key feature is that **the write and read operations use completely independent clocks**.

---

# 2. Memory Organization

The memory is declared as:

```systemverilog
logic [31:0] mem [0:255];
```

Therefore:

```text
Data width  = 32 bits
Depth       = 256 words
Address     = 8 bits
```

because:

```text
2^8 = 256
```

Total memory capacity:

```text
256 × 32 = 8192 bits
         = 1024 bytes
         = 1 KB
```

Valid address range:

```text
0 → 255
```

---

# 3. Write Clock Domain

The write process is:

```systemverilog
always_ff @(posedge clk_wr or negedge rst_n)
  if (!rst_n)
    for (int i = 0; i < 256; i++) mem[i] <= 32'h0;
  else if (wr_en)
    mem[wr_addr] <= data_in;
```

There are two operations.

### Reset

When:

```text
rst_n = 0
```

the entire memory is cleared:

```text
mem[0]   = 0
mem[1]   = 0
...
mem[255] = 0
```

The reset is **asynchronous with respect to `clk_wr`**, because `negedge rst_n` is in the sensitivity list.

### Write

When:

```text
wr_en = 1
```

the memory write occurs at the rising edge of:

```text
clk_wr
```

For example:

```text
wr_addr = 8'd5
data_in = 32'hA000_0005
```

gives:

```text
mem[5] = 32'hA000_0005
```

at the next `posedge clk_wr`.

---

# 4. Read Clock Domain

The read process is:

```systemverilog
always_ff @(posedge clk_rd)
  if (rd_en)
    data_out <= mem[rd_addr];
```

When:

```text
rd_en = 1
```

the selected memory location is sampled on the rising edge of:

```text
clk_rd
```

For example:

```text
rd_addr = 5
```

produces:

```text
data_out <= mem[5]
```

at the next read-clock edge.

Therefore, the read operation is **synchronous to `clk_rd`**.

---

# 5. Independent Clock Domains

The most important feature is:

```text
clk_wr ≠ clk_rd
```

The testbench uses:

```verilog
always #5   clk_wr = ~clk_wr;
always #3.5 clk_rd = ~clk_rd;
```

Therefore:

```text
Write clock period = 10 ns
Write frequency    = 100 MHz

Read clock period  = 7 ns
Read frequency     ≈ 142.86 MHz
```

The clocks are therefore asynchronous to each other.

This allows the write and read sides to operate at different rates.

Typical applications include:

* Data buffering between clock domains
* Video/image processing
* Producer-consumer memory systems
* Communication interfaces
* Multi-clock SoC subsystems
* FPGA dual-port memory structures

---

# 6. Important CDC Observation

There is an important distinction here.

The **clock domains are asynchronous**, but the memory itself is shared directly:

```text
clk_wr → mem[]
clk_rd → mem[]
```

There is no synchronizer between the two domains.

That is acceptable for a properly implemented **dual-port memory primitive/macro**, where the memory hardware provides defined dual-clock behavior.

However, this RTL does **not by itself define what happens if a read and write access the same address at nearly the same time**.

For example:

```text
Write domain:
mem[10] <= AAAAAAAA

Read domain:
data_out <= mem[10]
```

occurring around the same physical time creates a **read-during-write collision**.

The exact result could depend on the target RAM primitive/macro's documented collision mode.

So this code should not be interpreted as a general-purpose CDC synchronizer.

---

# 7. Testbench Clock Generation

The write clock:

```systemverilog
initial clk_wr = 1'b0;
always #5 clk_wr = ~clk_wr;
```

produces:

```text
0 ──5ns── 1 ──5ns── 0 ...
```

giving a 10 ns period.

The read clock:

```systemverilog
initial clk_rd = 1'b0;
always #3.5 clk_rd = ~clk_rd;
```

produces a 7 ns period.

The different periods ensure that the two clock domains are genuinely independent.

---

# 8. Reset Phase

Initially:

```systemverilog
rst_n = 1'b0;
```

so the RAM reset logic executes.

The testbench keeps reset active for:

```text
20 ns
```

and then:

```systemverilog
rst_n = 1'b1;
```

releases reset.

The memory therefore starts with:

```text
mem[0:255] = 0
```

according to this RTL.

---

# 9. Write Phase

The testbench enables writing:

```systemverilog
wr_en = 1'b1;
```

and executes:

```systemverilog
for (i = 0; i < 8; i = i + 1) begin
  @(posedge clk_wr);
  wr_addr = i[7:0];
  data_in = 32'hA000_0000 + i;
end
```

The intended data pattern is:

| Address | Data        |
| ------: | ----------- |
|       0 | `A000_0000` |
|       1 | `A000_0001` |
|       2 | `A000_0002` |
|       3 | `A000_0003` |
|       4 | `A000_0004` |
|       5 | `A000_0005` |
|       6 | `A000_0006` |
|       7 | `A000_0007` |

### Important testbench timing detail

There is a subtle scheduling issue in this loop.

The testbench does:

```systemverilog
@(posedge clk_wr);
wr_addr = i[7:0];
data_in = 32'hA000_0000 + i;
```

The address/data are changed **after** the clock edge, rather than before it.

Therefore, at the first `posedge clk_wr`, the RAM sees the **previous values** of `wr_en`, `wr_addr`, and `data_in`.

The first intended write does not occur at the same edge where the testbench assigns `wr_addr` and `data_in`.

A cleaner synchronous stimulus would set the address/data **before** waiting for the relevant clock edge.

This is important when interpreting the simulation.

---

# 10. Read Phase

After the writes, the TB waits:

```systemverilog
#50;
```

This gives the write side time to finish before reading.

Then:

```systemverilog
rd_en = 1'b1;
```

and:

```systemverilog
for (i = 0; i < 8; i = i + 1) begin
  @(posedge clk_rd);
  rd_addr = i[7:0];
end
```

The intended read sequence is:

```text
Address:
0 → 1 → 2 → 3 → 4 → 5 → 6 → 7
```

with corresponding expected values:

```text
A000_0000
A000_0001
A000_0002
A000_0003
A000_0004
A000_0005
A000_0006
A000_0007
```

Again, because `rd_addr` is assigned **after** each `posedge clk_rd`, the RAM samples the previous address at that edge. Therefore the observed `data_out` sequence is effectively one read-clock step behind the address assignments.

---

# 11. Registered Read Output

The line:

```systemverilog
data_out <= mem[rd_addr];
```

means `data_out` is a register.

So the read path is:

```text
rd_addr
   |
   v
mem[rd_addr]
   |
   | posedge clk_rd
   v
data_out
```

This gives a **one-read-clock-edge synchronous read behavior**.

---

# 12. Testbench Verification

The testbench uses:

```systemverilog
$monitor(...)
```

to display:

```text
wr_en
wr_addr
data_in
rd_en
rd_addr
data_out
```

This makes it useful for observing the interaction between the two clock domains.

However, it is **not self-checking**.

There is no reference model such as:

```systemverilog
expected = 32'hA000_0000 + address;
```

and no:

```systemverilog
if (data_out !== expected)
```

comparison.

So the testbench demonstrates functionality but does not automatically generate PASS/FAIL results.

---

# 13. Important RTL Considerations

### 1. Memory reset

This code resets all 256 × 32 bits:

```systemverilog
for (int i = 0; i < 256; i++)
    mem[i] <= 32'h0;
```

For a learning RTL model this is clear and useful.

For actual FPGA/ASIC implementation, resetting every memory word can interfere with inference of dedicated RAM resources or memory macros, depending on the technology.

---

### 2. Same-address read/write collision

This design does not specify behavior for:

```text
clk_wr → write mem[X]
clk_rd → read mem[X]
```

at overlapping times.

A real dual-port RAM should have a documented mode such as:

```text
WRITE_FIRST
READ_FIRST
NO_CHANGE
```

depending on the target memory primitive.

---

### 3. No reset for `data_out`

`data_out` is not reset:

```systemverilog
always_ff @(posedge clk_rd)
```

Therefore it can initially be `X` until a valid read occurs.

---

### 4. No `else` on the read block

When:

```text
rd_en = 0
```

`data_out` retains its previous value.

That is different from the earlier RAM examples where output was driven to `Z`.

So this module has:

```text
rd_en = 1 → update data_out
rd_en = 0 → hold previous data_out
```

---

# 14. Advantages & Limitations

### Advantages

* Independent write and read clocks
* 32-bit data path
* 256-word memory
* Synchronous write
* Synchronous read
* Useful for multi-clock architectures
* Separate read/write addresses
* Good model for dual-clock memory concepts

### Limitations

* No explicit read/write collision policy
* Direct shared-memory access across asynchronous clock domains
* Entire RAM is reset
* `data_out` has no reset
* Testbench has clock-edge stimulus scheduling issues
* Testbench is observational rather than self-checking
* Actual FPGA/ASIC implementation should use the target technology's dual-port RAM primitive/macro when appropriate

---

# 15. Interview Takeaways

### One-line explanation

> This is a dual-port, dual-clock RAM with independent synchronous write and read interfaces, allowing the write and read sides to operate in separate asynchronous clock domains.

### Key interview questions

**Q1. What is the memory capacity?**

```text
256 × 32 = 8192 bits = 1 KB
```

**Q2. Why are the addresses 8 bits?**

```text
2^8 = 256 memory locations
```

**Q3. Are the clocks synchronous with each other?**

No. `clk_wr` and `clk_rd` are independent clock domains.

**Q4. Is the write synchronous?**

Yes. Writing occurs on `posedge clk_wr`.

**Q5. Is the read synchronous?**

Yes. `data_out` is updated on `posedge clk_rd`.

**Q6. What happens when `rd_en=0`?**

`data_out` retains its previous value.

**Q7. What is the major real-hardware concern?**

The design needs a defined **dual-port RAM collision policy** for simultaneous/near-simultaneous read and write of the same address. The target FPGA/ASIC memory primitive determines the actual behavior unless it is explicitly architected otherwise.

**Q8. What is the most important difference from your previous dual-port RAM?**

The previous design used one clock. This one has:

```text
Write → clk_wr
Read  → clk_rd
```

so it specifically models a **dual-clock memory interface**, which is useful when two parts of a system operate at unrelated clock frequencies.
