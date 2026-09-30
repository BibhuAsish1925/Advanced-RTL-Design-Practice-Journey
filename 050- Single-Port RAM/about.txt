# Single-Port RAM — Circuit Analysis

## 1. Circuit Overview & Applications

This design implements a **parameterized single-port synchronous RAM**.

Default configuration:

```text
Address width = 7 bits
Data width    = 8 bits
Depth         = 128 locations
Capacity      = 128 × 8 = 1024 bits = 128 bytes
```

The same module can be reused for different memory sizes by changing:

```verilog
parameter addr_width = 7;
parameter data_width = 8;
parameter depth      = 128;
```

### Main signals

| Signal    | Function           |
| --------- | ------------------ |
| `data`    | Data to be written |
| `address` | Memory location    |
| `we`      | Write enable       |
| `clk`     | Clock              |
| `q`       | Read data          |

The architecture is:

```text
                 +---------------------+
 data ---------->|                     |
 address ------->|   Single-Port RAM   |----> q
 we ------------>|                     |
 clk ------------>|                     |
                 +---------------------+
```

Applications include small buffers, register files, embedded memory blocks, FPGA RAM inference, and ASIC memory-wrapper logic.

---

# 2. Memory Organization

The memory declaration is:

```verilog
reg [data_width-1:0] ram [depth-1:0];
```

With the default parameters this becomes:

```verilog
reg [7:0] ram [127:0];
```

So there are:

```text
128 memory locations
×
8 bits per location
=
1024 bits
```

The 7-bit address can represent:

```text
0000000 → address 0
0000001 → address 1
...
1111111 → address 127
```

---

# 3. Write Operation

The main sequential block is:

```verilog
always @(posedge clk)
begin
    if(we)
        ram[address] <= data; 
    else
        addr_reg <= address;
end
```

When:

```text
we = 1
```

the RAM performs a write at the rising clock edge:

```text
ram[address] ← data
```

For example:

```text
we      = 1
address = 7'd2
data    = 8'hD2
```

At the next rising edge:

```text
ram[2] = 8'hD2
```

---

# 4. Read Operation

When:

```text
we = 0
```

the address is registered:

```verilog
addr_reg <= address;
```

Then:

```verilog
assign q = ram[addr_reg];
```

provides the contents of the selected memory location.

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
   q
```

This gives the design a **registered-address read path**.

An important point is that `q` itself is not registered. The address is registered, and the memory contents are then continuously assigned to `q`.

---

# 5. Why `addr_reg` Is Used

The register:

```verilog
reg [addr_width-1:0] addr_reg;
```

stores the read address when `we=0`.

For example:

```text
Cycle 1:
we = 0
address = 0
       ↓
addr_reg = 0
       ↓
q = ram[0]
```

Then:

```text
Cycle 2:
we = 0
address = 2
       ↓
addr_reg = 2
       ↓
q = ram[2]
```

This structure is commonly used when describing synchronous-read memory.

---

# 6. Important Behavior: Single-Port RAM

The RAM has only one `address` port:

```verilog
input [addr_width-1:0] address
```

Therefore, it is a **single-port RAM**.

The control signal determines whether that port is used for:

```text
we = 1 → WRITE
we = 0 → READ
```

It cannot perform an independent read and write through separate ports in the same cycle.

---

# 7. Testbench Analysis

The testbench uses:

```text
addr_width = 7
data_width = 8
depth      = 128
```

The clock is generated using:

```verilog
always #5 clk=~clk;
```

Therefore:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

The clock starts at:

```verilog
clk = 1'b1;
```

so the first falling edge occurs at 5 ns and the first rising edge occurs at 10 ns.

---

## Write 1

```verilog
data    = 8'hf0;
address = 7'd0;
we      = 1'b1;
```

At the rising edge:

```text
ram[0] = F0
```

---

## Write 2

```verilog
data    = 8'he1;
address = 7'd1;
```

Since `we` remains `1`:

```text
ram[1] = E1
```

---

## Write 3

```verilog
data    = 8'hd2;
address = 7'd2;
```

Therefore:

```text
ram[2] = D2
```

At this point the relevant memory contents are:

```text
Address     Data
-------     ----
0           F0
1           E1
2           D2
```

---

# 8. Read Operation

The testbench then changes:

```verilog
data = 8'hz;
address = 7'd0;
we = 1'b0;
```

The `data = 8'hz` assignment is irrelevant to the RAM during read because `data` is only used when `we=1`.

With:

```text
we = 0
address = 0
```

the RAM captures:

```text
addr_reg = 0
```

and:

```text
q = ram[0] = F0
```

Then it reads address 2:

```text
address = 2
```

giving:

```text
q = D2
```

Then address 1:

```text
q = E1
```

So the expected read sequence is:

```text
F0 → D2 → E1
```

---

# 9. Important RTL Observations

### 1. `data = 8'hz` in the testbench

You have:

```verilog
data = 8'hz;
```

This is legal Verilog, but it isn't necessary.

Since `we=0`, `data` is ignored during the read operation. A cleaner testbench could simply leave `data` unchanged.

---

### 2. `addr_reg` is only updated during reads

Notice:

```verilog
if(we)
    ram[address] <= data;
else
    addr_reg <= address;
```

Therefore, while writing, `addr_reg` does not change.

That's intentional in this architecture because the address register is used for the read path.

---

### 3. `q` is not explicitly registered

The output is:

```verilog
assign q = ram[addr_reg];
```

So `q` is a continuous assignment.

The **address** is registered, rather than the output data itself.

This distinction is useful in an interview:

> The design uses a registered read address followed by a combinational memory-output path.

---

### 4. No reset

There is no reset signal for:

```verilog
ram
addr_reg
```

Therefore, unwritten memory locations can contain `X` in simulation.

This is normal for a simple RAM model unless memory initialization/reset behavior is specifically required.

---

# 10. Testbench Verification

The testbench uses:

```verilog
$monitor("write enable: %b  address: %b  data: %b  output: %b",
         we, address, data, q);
```

This allows you to observe:

* Write enable
* Address
* Input data
* Read output

However, it is **not self-checking**.

A stronger testbench would explicitly verify:

```text
ram[0] → F0
ram[1] → E1
ram[2] → D2
```

and report PASS/FAIL.

---

# 11. Advantages & Limitations

### Advantages

* Parameterized address width
* Parameterized data width
* Parameterized depth
* Simple single-port architecture
* Synchronous write
* Registered read address
* Suitable for RAM inference
* Easy to scale

### Limitations

* Only one memory access port
* No simultaneous independent read/write
* No byte-enable
* No reset/initialization
* Testbench does not perform automatic checking
* Unwritten locations may produce `X` in simulation

---

# 12. Interview Takeaways

**One-line explanation:**

> This is a parameterized single-port RAM with synchronous writes and a registered read address, allowing the same RTL to model different memory configurations.

### Key interview questions

**Q1. What is the default capacity?**

```text
128 × 8 = 1024 bits = 128 bytes
```

**Q2. Why is the address 7 bits?**

```text
2^7 = 128 locations
```

**Q3. What does `we=1` mean?**

Write `data` into `ram[address]` at the rising clock edge.

**Q4. What does `we=0` mean?**

Register the address for a read:

```verilog
addr_reg <= address;
```

**Q5. Is `q` registered?**

No. `q` is continuously assigned from:

```verilog
ram[addr_reg]
```

The **read address** is registered.

**Q6. What values should the testbench read back?**

```text
Address 0 → F0
Address 2 → D2
Address 1 → E1
```

**Q7. What type of RAM is this?**

A **single-port, parameterized synchronous RAM**.
