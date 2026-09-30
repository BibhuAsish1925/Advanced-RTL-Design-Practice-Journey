# 16K × 8 RAM — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **16,384 × 8-bit synchronous RAM** with:

* 14-bit address bus
* 8-bit data bus
* Two chip-enable signals: `ce1`, `ce2`
* Write enable: `we`
* Output enable: `oe`
* Synchronous read and write
* Tri-state-style output when the RAM is not reading

Memory capacity:

```text
16384 locations × 8 bits
= 131072 bits
= 16 KB
```

The basic architecture is:

```text
                         +----------------------+
 addr[13:0] ------------>|                      |
 datain[7:0] ------------>|                      |
 ce1 -------------------->|                      |
 ce2 -------------------->|      16K × 8 RAM    |----> dataout[7:0]
 we --------------------->|                      |
 oe --------------------->|                      |
 clk -------------------->|                      |
                         +----------------------+
```

This type of interface resembles a memory macro interface where multiple enable conditions must be satisfied before a read/write operation is allowed.

---

# 2. Memory Organization

The memory declaration is:

```verilog
reg [7:0] mem [16383:0];
```

Therefore:

```text
Data width = 8 bits
Depth      = 16384
Address    = 14 bits
```

because:

```text
2^14 = 16384
```

Address range:

```text
0 → 16383
```

The maximum address is:

```text
14'b11111111111111
```

and the total capacity is:

```text
16384 × 8
= 131072 bits
= 16 KB
```

---

# 3. Control Signals

This design has two chip-enable signals:

```verilog
ce1
ce2
```

An operation is permitted only when:

```text
ce1 = 1
AND
ce2 = 1
```

Then `we` and `oe` determine the operation.

### Write

```text
ce1 = 1
ce2 = 1
we  = 1
```

→ Write `datain` into `mem[addr]`.

### Read

```text
ce1 = 1
ce2 = 1
we  = 0
oe  = 1
```

→ Read `mem[addr]` into `dataout`.

---

# 4. Write Operation

The main sequential block is:

```verilog
always @(posedge clk) begin
    if (ce1 && ce2 && we) begin
        mem[addr] <= datain;
    end
```

A write therefore occurs only on the **rising edge of `clk`**.

For example:

```text
ce1   = 1
ce2   = 1
we    = 1
addr  = 100
datain = 8'hAA
```

At the next rising edge:

```text
mem[100] = 8'hAA
```

So the write operation is synchronous.

---

# 5. Read Operation

The read section is:

```verilog
else if (ce1 && ce2 && oe) begin
    dataout <= mem[addr];
end
```

Because this is inside:

```verilog
always @(posedge clk)
```

the read is also **synchronous**.

For example:

```text
ce1  = 1
ce2  = 1
we   = 0
oe   = 1
addr = 100
```

At the rising clock edge:

```text
dataout <= mem[100]
```

So the read data is captured into the `dataout` register.

---

# 6. Output Disabled State

The final branch is:

```verilog
else begin
    dataout <= 8'bzzzzzzzz;
end
```

Therefore, whenever the RAM is neither performing a valid write nor a valid read:

```text
dataout = ZZZZZZZZ
```

This models a **high-impedance output**.

The intended behavior is:

```text
Valid read     → dataout = memory data
Otherwise      → dataout = Z
```

---

# 7. Operation Priority

The code uses:

```verilog
if (ce1 && ce2 && we)
    ...
else if (ce1 && ce2 && oe)
    ...
else
    ...
```

Therefore, **write has priority over read** if both `we` and `oe` are asserted simultaneously.

For example:

```text
ce1 = 1
ce2 = 1
we  = 1
oe  = 1
```

results in:

```text
WRITE
```

and not READ.

This priority comes directly from the `if ... else if` structure.

---

# 8. Testbench Analysis

The testbench generates a clock using:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

Initial conditions:

```verilog
ce1 = 0;
ce2 = 0;
we  = 0;
oe  = 0;
addr = 0;
datain = 0;
```

So initially the RAM is disabled.

---

# 9. Enabling the RAM

At:

```text
t = 10 ns
```

the testbench performs:

```verilog
ce1 = 1;
```

Then at:

```text
t = 30 ns
```

it performs:

```verilog
ce2 = 1;
```

Now:

```text
ce1 = 1
ce2 = 1
```

so the RAM is enabled for operations controlled by `we` and `oe`.

---

# 10. First Write

At:

```text
t = 60 ns
```

the testbench sets:

```verilog
we = 1;
```

Therefore the RAM enters write mode.

At each rising clock edge while `we=1`:

```verilog
mem[addr] <= datain;
```

is executed.

Initially:

```text
addr   = 0
datain = 0
```

so the first write stores:

```text
mem[0] = 8'h00
```

The testbench later changes:

```text
addr = 1
datain = 8'hAA
```

so the next write stores:

```text
mem[1] = 8'hAA
```

---

# 11. First Read

At:

```text
t = 150 ns
```

the testbench asserts:

```verilog
oe = 1;
```

while:

```text
we = 0
```

Therefore the RAM performs a read at the next rising clock edge.

If:

```text
addr = 1
```

then:

```text
dataout = mem[1]
        = 8'hAA
```

assuming the earlier write has occurred as intended.

---

# 12. Maximum Address Test

The testbench specifically tests:

```verilog
addr = 16383;
```

This is the maximum valid address because:

```text
2^14 - 1 = 16383
```

Then:

```verilog
we = 1;
datain = 8'h55;
```

so the RAM writes:

```text
mem[16383] = 8'h55
```

at the next rising edge.

Then:

```verilog
we = 0;
oe = 1;
```

causes a read of the same location.

Expected result:

```text
dataout = 8'h55
```

This is a useful boundary-address test because it verifies the upper end of the 14-bit address range.

---

# 13. Testbench Verification

The testbench uses:

```verilog
$monitor("t=%0t\t ce1=%b ce2=%b we=%b oe=%b addr=%0d datain=%h dataout=%h",
          $time, ce1, ce2, we, oe, addr, datain, dataout);
```

So it continuously observes:

* Clock-related simulation time
* `ce1`
* `ce2`
* `we`
* `oe`
* Address
* Input data
* Output data

However, this is an **observational testbench**, not a self-checking testbench.

There is no comparison such as:

```verilog
if (dataout !== 8'h55)
    $display("FAIL");
```

So correctness must be determined by examining the waveform/monitor output.

---

# 14. Important RTL Observations

### 1. Both reads and writes are synchronous

Because both operations are inside:

```verilog
always @(posedge clk)
```

the design is a **synchronous RAM**.

Unlike your previous `Async_RAM`, the output itself is registered:

```verilog
dataout <= mem[addr];
```

---

### 2. `dataout` is a `reg`

This is required because it is assigned procedurally:

```verilog
dataout <= ...
```

inside an `always` block.

---

### 3. Two chip enables

The expression:

```verilog
ce1 && ce2
```

means both enables must be active.

This can be useful when modeling a memory macro with multiple enable conditions.

---

### 4. No reset

There is no reset signal.

Therefore, memory locations that have never been written can contain `X` during simulation.

For example:

```text
mem[5000]
```

is unknown unless it has previously been written.

---

### 5. `oe` does not create a true external tri-state register

Although:

```verilog
dataout <= 8'bz;
```

models high impedance, `dataout` itself is declared as a normal output register.

For actual ASIC I/O or shared-bus implementation, tri-state behavior would generally be handled at the appropriate I/O/interface boundary rather than assuming arbitrary internal tri-state hardware.

---

# 15. Advantages & Limitations

### Advantages

* 16 KB memory capacity
* 14-bit address space
* 8-bit data path
* Synchronous read/write
* Two-stage chip-enable control
* Separate write/output enables
* Maximum-address test included in TB
* Simple memory-macro-style interface

### Limitations

* No reset/initialization
* No byte-enable
* No explicit read-during-write behavior
* Write has priority if `we` and `oe` are both high
* Testbench does not automatically check expected values
* `Z` modeling may not directly represent internal FPGA hardware

---

# 16. Interview Takeaways

### One-line explanation

> This is a 16K × 8 synchronous RAM with a 14-bit address bus, dual chip-enable control, separate read/write enables, and registered read data.

### Key interview questions

**Q1. What is the memory capacity?**

```text
16384 × 8 = 131072 bits = 16 KB
```

**Q2. Why is the address 14 bits?**

```text
2^14 = 16384 locations
```

**Q3. When does a write occur?**

When:

```text
ce1 = 1
ce2 = 1
we  = 1
```

at a rising clock edge.

**Q4. When does a read occur?**

When:

```text
ce1 = 1
ce2 = 1
oe  = 1
```

at a rising clock edge.

**Q5. What happens if both `we` and `oe` are high?**

The **write operation has priority** because it appears first in the `if/else if` structure.

**Q6. What is the maximum valid address?**

```text
16383 = 14'b11111111111111
```

**Q7. Is this synchronous or asynchronous RAM?**

**Synchronous RAM**, because both the write and read operations occur inside `always @(posedge clk)`.
