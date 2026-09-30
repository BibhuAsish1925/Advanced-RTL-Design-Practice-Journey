# Synchronous RAM — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **256 × 8 synchronous RAM** with:

* Asynchronous active-low reset
* Chip select (`cs`)
* Write enable (`we`)
* Output enable (`oe`)
* 8-bit address
* 8-bit data

Memory capacity:

```text
256 locations × 8 bits
= 2048 bits
= 256 bytes
```

Architecture:

```text
                    +----------------------+
 address ---------->|                      |
 data_in ---------->|                      |
 cs --------------->|                      |
 we --------------->|    256 × 8 RAM      |
 oe --------------->|                      |----> data_out
 clk --------------->|                      |
 rst_n ------------->|                      |
                    +----------------------+
```

The **write operation is synchronous**, and the **read data is also registered on the clock edge**, making this a synchronous RAM interface.

Applications include FPGA/ASIC memory blocks, small data buffers, embedded storage, register-file-like structures, and memory interface modeling.

---

# 2. Memory Organization

The memory is declared as:

```verilog
reg [7:0] ram [255:0];
```

Therefore:

```text
Address width = 8 bits
Number of locations = 2^8 = 256
Data width = 8 bits
```

Address range:

```text
0 → 255
```

Capacity:

```text
256 × 8 = 2048 bits
             = 256 bytes
```

---

# 3. Write Operation

The first sequential block is:

```verilog
always@(posedge clk, negedge rst_n)
begin
    if(~rst_n)
        for(i=0;i<256;i=i+1)
            ram[i]<=0;
    else if(cs & we)
        ram[address]<=data_in;
end
```

There are two possible events.

### Reset

When:

```text
rst_n = 0
```

the asynchronous reset immediately clears all 256 memory locations:

```text
ram[0]   = 0
ram[1]   = 0
...
ram[255] = 0
```

The reset does not wait for a clock edge.

### Write

When:

```text
rst_n = 1
cs    = 1
we    = 1
```

the selected location is written on the next rising clock edge:

```text
ram[address] <= data_in;
```

For example:

```text
address = 8'd5
data_in = 8'hAB
```

results in:

```text
ram[5] = 8'hAB
```

at the rising clock edge.

---

# 4. Read Operation

The second sequential block is:

```verilog
always@(posedge clk)
begin
    if(cs & oe)
        data_out<=ram[address];
    else 
        data_out<=8'hz;
end
```

When:

```text
cs = 1
oe = 1
```

the memory contents are captured into `data_out` at the rising edge:

```text
data_out <= ram[address];
```

Therefore the read is **synchronous**.

The read path is:

```text
address
   |
   v
ram[address]
   |
   | posedge clk
   v
data_out
```

If either `cs` or `oe` is low:

```text
data_out = Z
```

---

# 5. Control Signal Behavior

| `cs` | `we` | `oe` | Operation                      |
| ---: | ---: | ---: | ------------------------------ |
|    0 |    X |    X | No memory write/read; output Z |
|    1 |    1 |    X | Write on rising edge           |
|    1 |    0 |    1 | Read on rising edge            |
|    1 |    0 |    0 | Output Z                       |

One subtle point is that the **write block only uses `cs & we`**, while the **read block only uses `cs & oe`**.

Therefore, if:

```text
cs = 1
we = 1
oe = 1
```

both blocks are active on the same clock edge. The memory is written while `data_out` simultaneously samples the previous/current memory contents according to Verilog scheduling and the RAM's read-during-write behavior.

---

# 6. Testbench Analysis

The testbench starts with:

```verilog
clk=0;
rst=0;
cs=1;
oe=0;
we=0;
address=0;
data_in=0;
```

Because:

```text
rst = 0
```

the RAM is immediately reset.

The clock is generated using:

```verilog
initial repeat(500) #5 clk=~clk;
```

This produces a:

```text
10 ns clock period
100 MHz clock
```

for the duration of the test.

---

# 7. Reset Phase

Initially:

```text
rst = 0
```

so:

```text
ram[0:255] = 0
```

Then after:

```verilog
#10 rst=1;
```

reset is released.

The RAM is now ready for normal operation.

---

# 8. Write Phase

The testbench then does:

```verilog
we=1;
```

while:

```text
cs = 1
oe = 0
```

so it enters write mode.

The loop is:

```verilog
repeat (10)
begin
    #10 address=address+1;
    data_in=address;
end
```

This writes a sequence of values into memory.

There is an important Verilog scheduling detail here:

```verilog
address=address+1;
data_in=address;
```

Both are **blocking assignments**, so `data_in` receives the newly incremented address value.

Thus the intended sequence is approximately:

```text
Address    Data
-------    ----
1          1
2          2
3          3
...
10         10
```

Address 0 remains at its reset value of `0`.

---

# 9. Read Phase

After the write phase:

```verilog
#10 we=0;
oe=1;
address=0;
```

Now:

```text
cs = 1
we = 0
oe = 1
```

so the RAM is in read mode.

The first read accesses:

```text
address = 0
```

so:

```text
data_out = ram[0] = 0
```

Then:

```verilog
repeat (10)
begin
    #10 address=address+1;
end
```

increments the address.

The expected values are therefore approximately:

```text
Address 0  → 0
Address 1  → 1
Address 2  → 2
...
Address 10 → 10
```

---

# 10. Verification Mechanism

The testbench uses:

```verilog
$monitor("t=%0t\t rst_n=%b cs=%b oe=%b we=%b address=%0d data_in=%0d data_out=%0d",
          $time, rst, cs, oe, we, address, data_in, data_out);
```

This continuously displays:

* Simulation time
* Reset
* Chip select
* Output enable
* Write enable
* Address
* Input data
* Output data

So it is useful for observing the RAM waveform behavior.

However, it is **not a self-checking testbench** because there is no expected-value comparison such as:

```verilog
if (data_out !== expected)
```

Therefore, it relies on visual inspection of the simulation output.

---

# 11. Important RTL Observations

### 1. Resetting the entire RAM

This code:

```verilog
for(i=0;i<256;i=i+1)
    ram[i]<=0;
```

clears every memory location during reset.

This is straightforward for simulation, but for actual FPGA/ASIC RAM inference, **resetting an entire memory array this way can prevent inference of dedicated memory macros/blocks or create significant hardware**, depending on the target technology.

For an interview, this is an important implementation consideration.

---

### 2. `data_out` is registered

Because:

```verilog
always @(posedge clk)
```

is used, `data_out` changes only at clock edges.

Therefore this is not an asynchronous-read RAM.

---

### 3. `8'hz` on a registered output

The design uses:

```verilog
data_out <= 8'hz;
```

This models a high-impedance output.

It can be useful when modeling a memory connected to a shared external bus. For internal FPGA logic, however, actual internal tri-state resources are generally not available in the same way as external I/O tri-states.

---

### 4. Memory is not reset independently from `data_out`

The reset block clears:

```text
ram[]
```

but does not reset:

```text
data_out
```

because the second `always` block has no reset sensitivity.

Therefore `data_out` can initially be `X` until a clock edge executes the read/output logic.

---

# 12. Advantages & Limitations

### Advantages

* Simple 256 × 8 memory architecture
* Parameter-independent fixed implementation
* Synchronous read
* Synchronous write
* Asynchronous active-low reset
* Separate chip-select, read/output-enable, and write-enable controls
* Easy to simulate and understand

### Limitations

* Entire memory array is cleared during reset
* No byte-enable support
* No explicit collision/read-during-write policy
* High-impedance `data_out` may not be appropriate for internal FPGA logic
* Testbench is observational rather than self-checking
* Resetting every memory word may affect RAM inference in real hardware

---

# 13. Interview Takeaways

**One-line explanation:**

> This is a 256×8 synchronous RAM with synchronous read/write operations, asynchronous active-low reset, and separate chip-select, output-enable, and write-enable controls.

### Key questions

**Q1. What is the memory capacity?**

```text
256 × 8 = 2048 bits = 256 bytes
```

**Q2. Why is the address 8 bits?**

```text
2^8 = 256 locations
```

**Q3. Is the read synchronous?**

Yes. `data_out` is updated inside `always @(posedge clk)`.

**Q4. Is the reset synchronous?**

No. The memory reset block has:

```verilog
posedge clk, negedge rst_n
```

so `rst_n` is an **asynchronous active-low reset**.

**Q5. What happens when `cs=1` and `we=1`?**

`data_in` is written into `ram[address]` at the next rising clock edge.

**Q6. What happens when `cs=1` and `oe=1`?**

`ram[address]` is captured into `data_out` at the next rising clock edge.

**Q7. What is the main hardware concern with this implementation?**

The loop that resets all 256 memory words may make dedicated RAM inference less straightforward in a real FPGA/ASIC implementation.
