## FIFO — Circuit Overview & Applications

This design implements a **32-depth × 8-bit synchronous FIFO** using a register-based memory array.

* **Depth:** 32 entries
* **Data width:** 8 bits
* **Storage:** `32 × 8 = 256 bits = 32 bytes`
* **Pointers:** 5-bit write and read pointers
* **Operations:** independent read/write requests
* **Status flags:** `full` and `empty`
* **Reset:** synchronous active-high reset
* **Verification:** SystemVerilog class-based testbench using randomization, mailbox communication, virtual interface, monitor, and scoreboard.

Typical applications include **data buffering between processing stages, rate matching, producer-consumer interfaces, packet buffering, and temporary storage in RTL/SoC designs**.

---

## 1. Circuit Working & RTL Implementation

### FIFO storage

```verilog
reg [7:0] mem [31:0];
```

This creates **32 memory locations**, each storing 8 bits.

```text
Write side                         Read side

data_in ──► mem[wr_ptr]       mem[rd_ptr] ──► data_out
                ▲                     ▲
                │                     │
             wr_ptr                 rd_ptr
```

### Write operation

```verilog
if ((wr == 1'b1) && (full == 1'b0)) begin
    mem[wr_ptr] <= data_in;
    wr_ptr <= wr_ptr + 1;
end
```

Data is written only when:

* `wr = 1`
* FIFO is not full.

The write pointer then advances to the next location.

### Read operation

```verilog
if ((rd == 1'b1) && (empty == 1'b0)) begin
    data_out <= mem[rd_ptr];
    rd_ptr <= rd_ptr + 1;
end
```

Data is read only when:

* `rd = 1`
* FIFO is not empty.

The read pointer then advances.

Because both operations are inside the same `always @(posedge clock)`, this is a **single-clock synchronous FIFO**.

### Empty detection

```verilog
assign empty = ((wr_ptr - rd_ptr) == 0) ? 1'b1 : 1'b0;
```

When the number of pending entries is zero:

```text
wr_ptr - rd_ptr = 0
```

the FIFO is considered empty.

### Full detection

```verilog
assign full = ((wr_ptr - rd_ptr) == 31) ? 1'b1 : 1'b0;
```

The implementation treats **31 stored entries as full**, so one location is effectively unused.

Therefore, although the memory contains 32 locations, the implemented usable FIFO capacity is **31 entries**.

### Reset

```verilog
if (rst == 1'b1) begin
    data_out <= 0;
    rd_ptr <= 0;
    wr_ptr <= 0;

    for(int i = 0; i < 32; i++)
        mem[i] <= 0;
end
```

Reset clears:

* read pointer
* write pointer
* output data
* all 32 memory locations

Since reset is **not in the sensitivity list**, it is **synchronous** and takes effect only on a rising clock edge.

---

# 2. Verification & Testbench

The testbench is significantly more advanced than a simple procedural FIFO testbench. It uses a basic **SystemVerilog verification environment**.

### Main components

```text
                ┌─────────────┐
                │  Generator  │
                └──────┬──────┘
                       │
                 mailbox
                       │
                ┌──────▼──────┐
                │   Driver    │
                └──────┬──────┘
                       │
                       ▼
                  ┌─────────┐
                  │   FIFO  │
                  └────┬────┘
                       │
                ┌──────▼──────┐
                │   Monitor   │
                └──────┬──────┘
                       │
                 mailbox
                       │
                ┌──────▼──────┐
                │ Scoreboard  │
                └─────────────┘
```

### Transaction

The `transaction` class contains:

```systemverilog
rand bit rd, wr;
rand bit [7:0] data_in;
bit full, empty;
bit [7:0] data_out;
```

It represents one FIFO operation.

The constraint:

```systemverilog
rd != wr;
```

ensures that **read and write are never simultaneously asserted**.

The data constraint:

```systemverilog
data_in > 1;
data_in < 5;
```

restricts generated data to:

```text
2, 3, 4
```

The `copy()` function creates an independent transaction object before putting it into the mailbox.

---

### Generator

The generator:

1. Randomizes the transaction.
2. Copies it.
3. Sends it through the generator-driver mailbox.
4. Waits for the `next` event.
5. Repeats for the configured transaction count.

Here:

```systemverilog
env.gen.count = 20;
```

so **20 transactions** are generated.

---

### Driver

The driver receives transactions and applies them to the DUT through the virtual interface.

It first performs reset:

```systemverilog
repeat(5) @(posedge fif.clock);
```

Then it applies each generated transaction for two clock cycles.

The virtual interface allows the class-based testbench to communicate with the RTL signals.

---

### Monitor

The monitor samples:

```text
wr
rd
data_in
data_out
full
empty
```

and sends the observed transaction to the scoreboard through another mailbox.

This separates **stimulus generation** from **DUT observation**.

---

### Scoreboard

The scoreboard maintains a SystemVerilog queue:

```systemverilog
bit [7:0] din[$];
```

For a write:

```systemverilog
din.push_front(tr.data_in);
```

For a read:

```systemverilog
temp = din.pop_back();
```

This models FIFO behavior:

```text
WRITE → push
READ  → pop oldest entry
```

It then compares:

```systemverilog
if(tr.data_out == temp)
    $display("[SCO] : DATA MATCH");
else
    $error("[SCO] : DATA MISMATCH");
```

So the scoreboard acts as a **reference model** for checking FIFO data ordering.

---

## 3. Important Verification Observations

There are a few important limitations in the supplied verification environment.

### 1. Read/write are never simultaneous

Because:

```systemverilog
rd != wr;
```

the testbench never verifies the important case:

```text
wr = 1
rd = 1
```

A real FIFO should normally be tested for simultaneous read/write when it is neither empty nor full.

### 2. Full condition is not really exercised

Only 20 transactions are generated, and the constraint prevents simultaneous operations.

Therefore, the FIFO is unlikely to reach its 31-entry full condition.

### 3. Empty handling is only partially tested

The scoreboard handles:

```systemverilog
if(tr.empty == 1'b0)
```

but the constrained sequence may not generate enough reads to thoroughly exercise repeated empty reads.

### 4. Data coverage is very small

Only:

```text
2, 3, 4
```

can be generated.

A stronger test would cover values such as:

```text
00, 01, 02, 7F, 80, FE, FF
```

### 5. The scoreboard assumes valid writes

The scoreboard does:

```systemverilog
if(tr.wr == 1'b1)
    din.push_front(tr.data_in);
```

without checking `full`.

The DUT itself blocks writes when `full=1`, so a more robust scoreboard should only model a write when:

```text
wr && !full
```

### 6. FIFO capacity is 31, not 32

This line:

```verilog
(wr_ptr - rd_ptr) == 31
```

means the implementation reserves one memory location to distinguish full from empty.

---

# 4. Advantages & Limitations

### Advantages

* Simple FIFO architecture.
* Parameterization could be added easily for width/depth.
* Synchronous operation simplifies timing.
* Separate read/write pointers provide straightforward control.
* Class-based SV verification is more scalable than a basic procedural TB.
* Mailboxes provide clean generator-driver and monitor-scoreboard communication.
* Randomization introduces stimulus variation.
* Queue-based scoreboard checks FIFO ordering.
* Can be synthesized as register-based storage for small FIFOs.

### Limitations

* Current FIFO capacity is 31 rather than 32.
* Memory is explicitly reset, which can become expensive for larger FIFOs.
* Pointer arithmetic is relatively simplistic.
* No simultaneous read/write verification.
* No assertions or functional coverage.
* Test data range is extremely limited.
* Full/empty boundary conditions are not thoroughly tested.
* This is a **single-clock FIFO**; it is not suitable as-is for clock-domain crossing.
* For larger FIFOs, dedicated FPGA BRAM or ASIC SRAM/macros would generally be preferable to flip-flop/register storage.

---

# 5. Interview Takeaways

### One-line explanation

> **“This is a 32×8 synchronous FIFO with 5-bit read/write pointers, full/empty detection, and a SystemVerilog class-based verification environment using constrained random stimulus, mailboxes, a monitor, and a queue-based scoreboard.”**

### Key interview questions

**Q: Why are the pointers 5 bits?**
Because 32 memory locations require `log2(32) = 5` address bits.

**Q: Why is the FIFO effectively 31 entries?**
Because the design declares full when the pointer difference reaches 31, leaving one location unused.

**Q: What makes this FIFO synchronous?**
Both read and write operations occur only on `posedge clock`.

**Q: Why use a virtual interface?**
It allows class-based verification components to access the DUT's interface signals without directly connecting class objects to module ports.

**Q: Why use a mailbox?**
It provides communication and synchronization between verification components such as generator → driver and monitor → scoreboard.

**Q: What is the scoreboard doing?**
It maintains a reference queue and compares the expected oldest FIFO data against the DUT's `data_out`.

**Q: Is this an asynchronous FIFO?**
No. Both sides use the same `clock`. An asynchronous FIFO would require separate read/write clocks and CDC-safe pointer synchronization, typically using Gray-coded pointers.
