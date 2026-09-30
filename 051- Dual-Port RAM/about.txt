# Dual-Port RAM — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **parameterized dual-port RAM** where two independent ports can access the same memory array.

Default configuration:

```text
Data width  = 8 bits
Address     = 4 bits
Depth       = 16 locations
Capacity    = 16 × 8 = 128 bits = 16 bytes
```

The important feature is that **port 0 and port 1 have separate addresses and enables**, while both access the same `ram` array.

```text
                         +----------------------+
                         |                      |
 addr_in_0 ------------->|                      |----> data_out_0
 port_en_0 ------------->|                      |
                         |     Dual-Port RAM    |
 addr_in_1 ------------->|                      |----> data_out_1
 port_en_1 ------------->|                      |
                         |                      |
 data_in --------------->|                      |
 wr_en ----------------->|                      |
 clk ------------------->|                      |
                         +----------------------+
```

Typical applications include **buffer sharing, packet/data buffering, video processing, register-file structures, and memory systems where two consumers need simultaneous access**.

---

# 2. Memory Organization

The memory declaration is:

```verilog
reg [data_width-1:0] ram [0:depth-1];
```

With the default parameters:

```verilog
reg [7:0] ram [0:15];
```

Therefore:

```text
Address 0  → 8-bit data
Address 1  → 8-bit data
...
Address 15 → 8-bit data
```

The 4-bit addresses provide:

```text
2^4 = 16 locations
```

and total capacity is:

```text
16 × 8 = 128 bits
```

---

# 3. Write Operation

The only sequential block is:

```verilog
always @(posedge clk)
begin
    if(port_en_0 == 1 && wr_en == 1)    
        ram[addr_in_0] <= data_in;
end
```

A write occurs when:

```text
port_en_0 = 1
wr_en     = 1
```

at the rising edge of `clk`.

For example:

```text
addr_in_0 = 4
data_in   = 8'h0A
port_en_0 = 1
wr_en     = 1
```

At the next rising edge:

```text
ram[4] = 8'h0A
```

### Important point

Although the module has two ports, **only port 0 is capable of writing** in this implementation.

Port 1 is read-only.

So technically this is a:

> **Simple dual-port RAM: one write port + two read/access outputs**

rather than a fully independent true dual-port RAM.

---

# 4. Port 0 Read

The first output is:

```verilog
assign data_out_0 = port_en_0 ? ram[addr_in_0] : 'dZ;
```

When:

```text
port_en_0 = 1
```

port 0 directly reads:

```text
ram[addr_in_0]
```

Otherwise:

```text
data_out_0 = Z
```

So port 0 can both **write and read**.

---

# 5. Port 1 Read

Port 1 is:

```verilog
assign data_out_1 = port_en_1 ? ram[addr_in_1] : 'dZ;
```

When:

```text
port_en_1 = 1
```

it reads:

```text
ram[addr_in_1]
```

Port 1 does not have a separate write enable, so it is effectively a **read-only port**.

---

# 6. Overall Operation

The architecture can be summarized as:

```text
                     COMMON MEMORY
                  +----------------+
                  |                |
PORT 0 ADDRESS -->|                |--> DATA_OUT_0
PORT 1 ADDRESS -->|     RAM        |--> DATA_OUT_1
                  |                |
DATA_IN --------->|                |
                  +----------------+
                       ^
                       |
                 WRITE PORT 0
```

### Port behavior

| Port   | Read | Write |
| ------ | ---- | ----- |
| Port 0 | Yes  | Yes   |
| Port 1 | Yes  | No    |

Both ports can read **different addresses simultaneously** because they have separate address inputs.

---

# 7. Testbench Analysis

The testbench uses the default:

```text
16 locations × 8 bits
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

## Initial State

The TB initially sets:

```verilog
port_en_0 = 0;
port_en_1 = 0;
wr_en     = 0;
data_in   = 0;
```

Therefore both outputs are:

```text
Z
```

because both ports are disabled.

---

# 8. Writing 1–16 into RAM

After 20 ns:

```verilog
port_en_0 = 1;
wr_en = 1;
```

Then:

```verilog
for(i=1; i <= 16; i=i+1)
begin
    data_in = i;
    addr_in_0 = i-1;
    #10;
end
```

This performs:

| Address | Data |
| ------: | ---: |
|       0 |    1 |
|       1 |    2 |
|       2 |    3 |
|       3 |    4 |
|     ... |  ... |
|      14 |   15 |
|      15 |   16 |

So after the write phase:

```text
ram[0]  = 1
ram[1]  = 2
ram[2]  = 3
...
ram[15] = 16
```

Because the address and data remain stable for 10 ns and the clock period is 10 ns, each value is captured on a rising edge.

---

# 9. Reading Through Port 1

The TB then changes:

```verilog
wr_en = 0;
port_en_0 = 0;
port_en_1 = 1;
```

Now only port 1 is enabled.

The loop:

```verilog
for(i=1; i <= 16; i=i+1)
begin
    addr_in_1 = i-1;
    #10;
end
```

reads addresses sequentially:

```text
0 → 1 → 2 → ... → 15
```

Therefore `data_out_1` should show:

```text
1 → 2 → 3 → ... → 16
```

This verifies that the values written through port 0 can be accessed through port 1.

---

# 10. Important Difference from the Previous Single-Port RAM

The previous single-port RAM had:

```text
one address
one access port
```

This design has:

```text
Port 0 → addr_in_0 → data_out_0
Port 1 → addr_in_1 → data_out_1
```

Both addresses access the same memory array:

```verilog
ram[addr_in_0]
ram[addr_in_1]
```

Therefore, two different locations can be read concurrently.

For example:

```text
port_en_0 = 1
addr_in_0 = 3

port_en_1 = 1
addr_in_1 = 12
```

gives:

```text
data_out_0 = ram[3]
data_out_1 = ram[12]
```

at the same time.

---

# 11. Important RTL Observations

### 1. Read is asynchronous

Unlike the previous synchronous-read RAM, here:

```verilog
assign data_out_0 = port_en_0 ? ram[addr_in_0] : 'dZ;
assign data_out_1 = port_en_1 ? ram[addr_in_1] : 'dZ;
```

means the outputs change immediately when the address changes.

The **write** is synchronous, but the **read** is asynchronous.

So the design is:

> **Synchronous write + asynchronous dual read**

---

### 2. Port 0 has read-after-write behavior

Port 0 can write:

```text
wr_en = 1
port_en_0 = 1
```

and its output simultaneously reads:

```verilog
ram[addr_in_0]
```

The exact observed value around a write edge can depend on simulation/synthesis memory semantics, so if deterministic read-during-write behavior is required, it should be explicitly specified.

---

### 3. Port 1 can read while port 0 writes

For example:

```text
port 0:
write ram[3]

port 1:
read ram[10]
```

There is no conflict because the addresses are different.

However, if both access:

```text
ram[3]
```

while port 0 is writing, the read-during-write behavior needs to be defined if deterministic behavior is required.

---

# 12. Testbench Verification

The testbench uses:

```verilog
$monitor(...)
```

so it is primarily an **observational testbench**.

It writes known values:

```text
1 through 16
```

and then reads them back.

This is a good basic functional test because it verifies that:

```text
Port 0 write → shared memory → Port 1 read
```

works.

However, there is no explicit:

```verilog
if (data_out_1 !== expected)
```

comparison.

So it does not automatically report PASS/FAIL.

---

# 13. Advantages & Limitations

### Advantages

* Parameterized memory architecture
* Two independent address ports
* Simultaneous reads possible
* Port 0 supports read/write
* Port 1 supports read
* Simple RTL
* Useful for shared-memory architectures

### Limitations

* Only port 0 can write
* Reads are asynchronous
* No independent write port for port 1
* No collision handling
* No explicit read-during-write behavior
* No reset/initialization
* Internal tri-state (`Z`) may not map to actual FPGA internal tri-state hardware
* Testbench is not self-checking

---

# 14. Interview Takeaways

### One-line explanation

> This RTL implements a parameterized simple dual-port RAM with one synchronous write port and two asynchronous read paths sharing a common memory array.

### Key interview questions

**Q1. What is the default memory capacity?**

```text
16 × 8 = 128 bits = 16 bytes
```

**Q2. Can both ports read simultaneously?**

Yes. They have independent addresses and outputs.

**Q3. Can both ports write?**

No. Only port 0 has write functionality.

**Q4. Is the read synchronous?**

No. The outputs are generated through continuous assignments, so the reads are asynchronous.

**Q5. Is the write synchronous?**

Yes. The memory is updated only at `posedge clk`.

**Q6. What happens if both ports access different addresses?**

Both accesses can occur independently.

**Q7. What happens if port 0 writes while port 1 reads the same address?**

That is a **read-during-write collision**, and this RTL does not explicitly define the required memory behavior.

**Q8. What type of RAM is this?**

More precisely, a **simple dual-port RAM / 1-write-2-read-access memory structure**, because only port 0 can perform writes while both ports can read.
