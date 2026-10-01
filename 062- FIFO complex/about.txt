# Parameterized Complex FIFO — Circuit Overview & Applications

This is a **parameterized synchronous FIFO** with configurable data width and depth, plus **full, empty, almost-full, and almost-empty status flags**.

* Default configuration: **32-bit × 16 entries**
* Testbench configuration: **8-bit × 8 entries**
* Storage for TB: `8 × 8 = 64 bits = 8 bytes`
* Uses separate read/write pointers and an occupancy counter.
* Supports **simultaneous read and write**.
* Reset: **asynchronous active-low**
* Verification: directed simulation with boundary, simultaneous-operation, and drain tests.

Typical applications include **data buffering, pipeline decoupling, packet buffering, rate matching, and producer-consumer interfaces**.

---

## 1. Circuit Working & RTL Implementation

### Parameterized architecture

```systemverilog
parameter DATA_WIDTH = 32,
parameter DEPTH = 16,
parameter ADDR_WIDTH = $clog2(DEPTH)
```

This allows the same FIFO RTL to be reused with different configurations.

For the supplied testbench:

```text
DATA_WIDTH = 8
DEPTH      = 8
ADDR_WIDTH = 3
```

So:

```text
Memory = 8 locations × 8 bits
```

### Memory

```systemverilog
logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
```

The memory stores the FIFO entries.

```text
                 ┌──────────────────┐
data_in ────────►│                  │
                 │   FIFO Memory    │
wr_ptr ─────────►│                  │
                 │                  │
rd_ptr ─────────►│                  │
                 └──────────────────┘
                         │
                         ▼
                      data_out
```

### Occupancy counter

```systemverilog
logic [ADDR_WIDTH:0] count;
```

Unlike the previous FIFO, this design explicitly tracks the number of stored entries.

For `DEPTH = 8`:

```text
count = 0 → FIFO empty
count = 1 → one item
...
count = 8 → FIFO full
```

The extra counter bit allows the counter to represent the full depth.

---

## 2. Status Flags

The thresholds are:

```systemverilog
localparam AF_THRESHOLD = DEPTH - 2;
localparam AE_THRESHOLD = 1;
```

For the testbench's `DEPTH = 8`:

```text
AF_THRESHOLD = 6
AE_THRESHOLD = 1
```

Therefore:

### Full

```systemverilog
full <= (count == DEPTH);
```

Full when:

```text
count = 8
```

### Empty

```systemverilog
empty <= (count == 0);
```

Empty when:

```text
count = 0
```

### Almost full

```systemverilog
almost_full <= (count >= AF_THRESHOLD);
```

For this test:

```text
count >= 6
```

### Almost empty

```systemverilog
almost_empty <= (count <= AE_THRESHOLD);
```

For this test:

```text
count <= 1
```

These early-warning flags are useful when downstream/upstream logic needs time to react before the FIFO reaches an actual boundary.

---

# 3. Read/Write Operation

### Write only

```systemverilog
else if (wr_en && (count != DEPTH)) begin
    mem[wr_ptr] <= data_in;
    wr_ptr <= wr_ptr + 1;
    count <= count + 1;
end
```

A write occurs only when the FIFO is not full.

The sequence is:

```text
data_in
   ↓
mem[wr_ptr]
   ↓
wr_ptr + 1
   ↓
count + 1
```

### Read only

```systemverilog
else if (rd_en && (count != 0)) begin
    data_out <= mem[rd_ptr];
    rd_ptr <= rd_ptr + 1;
    count <= count - 1;
end
```

A read occurs only when the FIFO is not empty.

---

# 4. Simultaneous Read + Write

This is one of the important features of this implementation:

```systemverilog
if (wr_en && (count != DEPTH) &&
    rd_en && (count != 0)) begin
```

When both operations are valid:

```text
Write → count + 1
Read  → count - 1
```

Therefore the net occupancy remains unchanged.

For example:

```text
Before: count = 5

write → +1
read  → -1

After:  count = 5
```

This is particularly useful for continuous streaming datapaths where data can leave the FIFO while new data enters it.

### Important edge condition

The simultaneous branch requires:

```text
count != DEPTH
count != 0
```

So simultaneous read/write is allowed only when the FIFO is **neither full nor empty**.

---

# 5. Important RTL Issue

There is one significant issue in the supplied implementation.

The flags are assigned inside the same sequential block:

```systemverilog
full         <= (count == DEPTH);
empty        <= (count == 0);
almost_full  <= (count >= AF_THRESHOLD);
almost_empty <= (count <= AE_THRESHOLD);
```

Because these are **nonblocking assignments**, the flags reflect the **old value of `count`** during that clock edge.

For example:

```text
Before edge: count = 7
Write occurs
After edge:  count = 8

full flag:   still reflects old count = 7
```

The `full` flag becomes correct on the following clock edge.

Your operation gating avoids using these potentially stale flags:

```systemverilog
wr_en && (count != DEPTH)
```

which is good. However, the externally visible status flags themselves are **one clock behind the updated count**.

For a production-quality FIFO, the flags would normally be derived combinationally from the current count, or calculated from the **next count** depending on the intended interface timing.

---

# 6. Verification & Testbench

The testbench uses:

```text
DATA_WIDTH = 8
DEPTH      = 8
```

and a **10 ns clock period**:

```systemverilog
always #5 clk = ~clk;
```

### Test 1 — Reset

```systemverilog
rst_n = 0;
...
#12;
rst_n = 1;
```

The asynchronous active-low reset clears the FIFO.

---

### Test 2 — Fill FIFO

```systemverilog
wr_en = 1;

for (i = 0; i < DEPTH; i = i + 1) begin
    data_in = i;
    @(posedge clk);
end
```

Eight values are written:

```text
0 1 2 3 4 5 6 7
```

The test observes `almost_full` and `full` while the FIFO fills.

Expected occupancy progression:

```text
0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8
```

`almost_full` should become active around count 6.

---

### Test 3 — Simultaneous Read + Write

```systemverilog
wr_en = 1;
rd_en = 1;
data_in = 8'hAA;

repeat (4) @(posedge clk);
```

Four simultaneous operations are attempted.

The intention is to verify that:

```text
count remains stable
```

while:

```text
old data is read
new 0xAA data is written
```

This is an important FIFO corner case.

---

### Test 4 — Drain FIFO

```systemverilog
rd_en = 1;
repeat (DEPTH) @(posedge clk);
```

The FIFO is then drained and the test observes:

```text
almost_empty
empty
```

as the occupancy approaches zero.

---

# 7. Testbench Limitation

The supplied TB is primarily **observational**, because it uses:

```systemverilog
$monitor(...)
```

It does not automatically verify:

```text
expected data == data_out
expected count == DUT count
expected full == actual full
expected empty == actual empty
```

So it is useful for waveform/console inspection, but it is **not a fully self-checking verification environment**.

A stronger TB would maintain a reference queue:

```text
Write → push expected data
Read  → pop expected data
Compare → expected data vs data_out
```

and explicitly check all four flags.

---

# 8. Advantages & Limitations

### Advantages

* Fully parameterized data width and depth.
* Occupancy counter simplifies full/empty detection.
* Supports simultaneous read/write.
* Provides almost-full and almost-empty early-warning flags.
* Prevents invalid writes when full.
* Prevents invalid reads when empty.
* Suitable as a reusable RTL FIFO component.

### Limitations

* Status flags are registered and can lag the current `count` by one cycle.
* `ADDR_WIDTH = $clog2(DEPTH)` assumes convenient depth sizing; non-power-of-two depths require careful pointer handling.
* No explicit pointer wrap logic for arbitrary non-power-of-two depths.
* Memory contents are not reset, although that is generally unnecessary for a FIFO because validity is determined by `count`.
* Testbench does not perform automated data integrity checking.
* No assertions or functional coverage.
* This is a **single-clock FIFO**, not an asynchronous/CDC FIFO.

---

# 9. Interview Takeaways

### One-line explanation

> **“This is a parameterized synchronous FIFO using read/write pointers and an occupancy counter, with full, empty, almost-full, almost-empty flags and support for simultaneous valid read/write operations.”**

### Key interview questions

**Q: Why use an occupancy counter?**
It directly tracks the number of valid entries, making full/empty and almost-full/almost-empty detection straightforward.

**Q: What happens during simultaneous read/write?**
When the FIFO is neither full nor empty, one entry is added and one is removed, so `count` remains unchanged.

**Q: Why is `count` `ADDR_WIDTH+1` bits?**
The pointer needs to address memory locations, while the counter must additionally represent the full depth. For depth 8, the counter must represent `0–8`.

**Q: What is the purpose of almost-full?**
It provides an early warning before the FIFO reaches full, allowing upstream logic to throttle or stop data generation.

**Q: What is the purpose of almost-empty?**
It warns downstream logic that the FIFO is close to running out of data.

**Q: What is the main issue with the current flag implementation?**
`full`, `empty`, `almost_full`, and `almost_empty` are registered using the **pre-update `count`**, so they can be one cycle stale relative to the newly updated occupancy.

**Q: Is this suitable for CDC?**
No. A multi-clock FIFO requires separate clock domains and CDC-safe pointer synchronization, commonly using **Gray-coded read/write pointers**.
