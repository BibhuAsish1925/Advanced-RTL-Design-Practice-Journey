# Asynchronous RAM — Circuit Analysis

## 1. Circuit Overview & Applications

This design is a **parameterized-style asynchronous-read RAM** with:

* 13-bit address
* 8-bit data
* 8192 memory locations
* Synchronous write
* Registered read address
* Combinational memory output

Memory organization:

```text
8192 locations × 8 bits
= 65,536 bits
= 8 KB
```

Architecture:

```text
                 +----------------------+
 address ------>|                      |
 data_in ------>|       RAM            |
 w_en --------->|                      |
 clk ---------->|                      |
                 +----------+-----------+
                            |
                       data_out
```

The memory declaration:

```verilog
reg [7:0] ram [8191:0];
```

creates:

```text
ram[0] ... ram[8191]
```

Since:

```text
2^13 = 8192
```

the 13-bit address is sufficient to select every location.

---

# 2. Write Operation

The sequential block is:

```verilog
always @(posedge clk)
begin
    if(w_en)
        ram[addr] <= data_in;
    else
        addr_reg <= addr;
end
```

When:

```text
w_en = 1
```

the selected location is written on the rising edge of `clk`.

For example:

```text
addr    = 13'd3
data_in = 8'hAB
w_en    = 1
```

At the next positive clock edge:

```text
ram[3] = 8'hAB
```

Therefore, **writing is synchronous**.

---

# 3. Read Operation

When:

```text
w_en = 0
```

the address is captured:

```verilog
addr_reg <= addr;
```

The output is then:

```verilog
assign data_out = ram[addr_reg];
```

So the read path is:

```text
address
   |
   v
addr_reg
   |
   v
ram[addr_reg]
   |
   v
data_out
```

There is no clocked `data_out` register.

Once `addr_reg` changes, the memory output can change according to the memory contents.

Thus, the design has:

> **Synchronous write + registered-address asynchronous read**

---

# 4. Why This Is Called Asynchronous RAM

The important part is:

```verilog
assign data_out = ram[addr_reg];
```

There is no:

```verilog
always @(posedge clk)
    data_out <= ...
```

for the output.

Therefore, once the read address has been registered, the memory contents are available through a combinational path.

Compare this with the previous synchronous RAM you provided:

```verilog
always @(posedge clk)
    data_out <= ram[address];
```

There, the **data output itself is clocked**.

Here:

```text
Previous synchronous RAM:
address → RAM → data_out
                 ↑
              clocked

This RAM:
address → addr_reg → RAM → data_out
            ↑
          clock
```

---

# 5. Testbench Analysis

The testbench generates a clock using:

```verilog
always #5 clk=~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

The initial conditions are:

```verilog
addr=0;
data_in=0;
clk=1;
w_en=0;
```

So the first operation is a read of address 0.

---

# 6. First Write

At:

```text
t = 10 ns
```

the TB applies:

```verilog
addr    = 13'b0000000000011;
data_in = 8'b10101011;
w_en    = 1;
```

which corresponds to:

```text
address = 3
data    = AB
```

At the next rising clock edge:

```text
ram[3] = 8'hAB
```

So the first memory write is:

```text
RAM[3] ← AB
```

---

# 7. Reading Address 3

After 20 ns, the TB changes:

```verilog
addr    = 13'b0000000000011;
data_in = 8'b11101100;
w_en    = 0;
```

Now the circuit executes:

```verilog
addr_reg <= addr;
```

Therefore:

```text
addr_reg = 3
```

and:

```verilog
assign data_out = ram[addr_reg];
```

gives:

```text
data_out = ram[3]
         = 8'hAB
```

So the previously written value should be observed at the output.

---

# 8. Second Write

The TB then performs:

```verilog
addr    = 13'b0111000100011;
data_in = 8'b11101000;
w_en    = 1;
```

The binary address is:

```text
0111000100011
```

which is:

```text
decimal 3619
```

So the operation is:

```text
RAM[3619] ← E8
```

at the next rising clock edge.

---

# 9. Random Read

Finally:

```verilog
addr = $random;
data_in = $random;
w_en = 0;
```

Since:

```text
w_en = 0
```

the random address is used for a read.

One important point is that `$random` produces a 32-bit signed value, but `addr` is only 13 bits wide. Therefore, only the lower 13 bits are retained when assigned to `addr`.

So the actual address is effectively:

```text
$random[12:0]
```

---

# 10. Important RTL Observation

The module name is:

```verilog
Async_RAM
```

but the address is not directly connected to the output:

```verilog
assign data_out = ram[addr];
```

Instead:

```verilog
addr → addr_reg → ram → data_out
```

because:

```verilog
else
    addr_reg <= addr;
```

is clocked.

Therefore, calling this a completely asynchronous-read RAM would be slightly imprecise.

A better description is:

> **RAM with synchronous write and registered read address followed by an asynchronous/combinational data path.**

---

# 11. Important `w_en` Behavior

This block:

```verilog
if(w_en)
    ram[addr] <= data_in;
else
    addr_reg <= addr;
```

means the circuit performs **either a write or a read-address update on each clock cycle**.

It cannot update `addr_reg` during a write cycle.

For example:

```text
w_en = 1 → write memory
w_en = 0 → capture read address
```

So this is not a true dual-port memory and cannot perform a read-address capture and write simultaneously through independent ports.

---

# 12. Testbench Limitation

The testbench does not contain:

```verilog
$monitor(...)
```

or explicit comparisons such as:

```verilog
if(data_out !== expected)
```

Therefore, it is mainly a **stimulus-only testbench**.

It applies:

1. Write `AB` to address 3
2. Read address 3
3. Write `E8` to address 3619
4. Perform a random read
5. Finish simulation

But it does not automatically verify that:

```text
data_out = AB
```

after the first read.

A stronger testbench would maintain expected values and generate PASS/FAIL messages.

---

# 13. Advantages & Limitations

### Advantages

* Large 8 KB memory capacity
* Simple RTL structure
* Synchronous write
* Registered read address
* Combinational data output
* Suitable for understanding RAM inference concepts
* Address and data widths are straightforward to modify

### Limitations

* No reset or memory initialization
* Read address cannot update during a write cycle
* Only one access operation per clock cycle
* No explicit collision/read-during-write behavior
* Testbench is not self-checking
* `$random` read address is not constrained to a known test case
* The design is not a conventional fully asynchronous-read RAM because the address is registered first

---

# 14. Interview Takeaways

### One-line explanation

> This design implements an 8 KB RAM with synchronous writes and a registered read address feeding a combinational memory-output path.

### Key interview questions

**Q1. Why is the address 13 bits?**

```text
2^13 = 8192 locations
```

**Q2. What is the memory capacity?**

```text
8192 × 8 = 65,536 bits
         = 8 KB
```

**Q3. Is the write synchronous?**

Yes. Memory is written only at `posedge clk`.

**Q4. Is the output registered?**

No. `data_out` is a continuous assignment.

**Q5. What does `w_en=0` do?**

It captures `addr` into `addr_reg` for reading.

**Q6. What happens when `w_en=1`?**

`data_in` is written into `ram[addr]` at the rising clock edge.

**Q7. What is the main architectural limitation?**

The same clock cycle is dedicated either to writing memory or capturing a read address because `w_en` selects between those two operations.
