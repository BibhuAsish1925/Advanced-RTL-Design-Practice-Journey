## Synchronous FIFO — Circuit Overview & Applications

This RTL implements a **parameterized synchronous FIFO** using a memory array, read/write pointers, and an occupancy counter.

* **Default:** 16 entries × 8 bits
* **Parameterizable:** `WIDTH` and `DEPTH`
* **Read/write:** synchronous to the same `clk`
* **Status:** `empty` and `full`
* **Reset:** synchronous active-high
* **Simultaneous read/write:** supported when FIFO is neither full nor empty
* **Pointer wrap:** implemented using modulo `% DEPTH`

Typical applications include **buffering between RTL blocks, pipeline decoupling, producer-consumer data transfer, packet buffering, and rate matching**.

---

# 1. Circuit Working & RTL Implementation

### Memory

```verilog
reg [WIDTH-1:0] mem [0:DEPTH-1];
```

This creates:

```text
DEPTH × WIDTH
```

storage.

With the defaults:

```text
16 × 8 = 128 bits = 16 bytes
```

---

### Read and write pointers

```verilog
reg [PTR_WIDTH-1:0] rd_ptr = 0;
reg [PTR_WIDTH-1:0] wr_ptr = 0;
```

The pointers identify the current read and write locations.

```text
wr_ptr → location where new data is written
rd_ptr → location from which data is read
```

`PTR_WIDTH` is calculated using:

```verilog
$clog2(DEPTH)
```

For `DEPTH = 16`:

```text
PTR_WIDTH = 4
```

---

### Occupancy counter

```verilog
reg [CNT_WIDTH-1:0] num_items = 0;
```

`num_items` tracks the number of valid entries currently stored in the FIFO.

```text
0     → empty
1     → one item
...
16    → full
```

The counter width is:

```verilog
$clog2(DEPTH+1)
```

so it can represent the full value `DEPTH`.

---

# 2. FIFO Operation

### Reset

```verilog
if (rst) begin
    rd_ptr <= 0;
    wr_ptr <= 0;
    next_rd_ptr <= 0;
    next_wr_ptr <= 0;
    num_items <= 0;
    empty <= 1;
    full <= 0;
end
```

The FIFO is returned to its initial state:

```text
read pointer  = 0
write pointer = 0
items         = 0
empty         = 1
full          = 0
```

Because `rst` is not in the sensitivity list, reset is **synchronous**.

---

### Status generation

```verilog
empty <= (num_items == 0);
full  <= (num_items == DEPTH);
```

The FIFO is empty when there are zero stored entries and full when the number of entries equals the configured depth.

---

### Write

```verilog
else if (wr_en && !full) begin
    mem[wr_ptr] <= wr_data;
    next_wr_ptr <= (wr_ptr + 1) % DEPTH;
    num_items <= num_items + 1;
end
```

The write sequence is:

```text
wr_data
   ↓
mem[wr_ptr]
   ↓
wr_ptr advances
   ↓
num_items + 1
```

The modulo operation wraps the pointer back to zero after the final memory location.

For `DEPTH = 16`:

```text
14 → 15 → 0 → 1 → ...
```

---

### Read

```verilog
else if (rd_en && !empty) begin
    rd_data <= mem[rd_ptr];
    next_rd_ptr <= (rd_ptr + 1) % DEPTH;
    num_items <= num_items - 1;
end
```

The oldest FIFO entry is placed into `rd_data`, and the read pointer advances.

---

# 3. Simultaneous Read and Write

The first operation checks:

```verilog
if (wr_en && !full && rd_en && !empty)
```

This allows both operations during the same clock cycle.

For example:

```text
Before:
num_items = 8

WRITE → +1
READ  → -1

After:
num_items = 8
```

This is important for streaming applications because the FIFO can consume and accept data during the same cycle.

The comment in the RTL correctly describes the intended behavior:

```verilog
// num_items unchanged: one entry in, one entry out
```

---

# 4. Important RTL Issue

There is a **significant bug** in the current implementation concerning `num_items`.

In the simultaneous read/write branch:

```verilog
if (wr_en && !full && rd_en && !empty)
begin
    ...
    // num_items unchanged
end
```

leaving `num_items` unchanged is correct.

However, `full` and `empty` are **registered outputs**:

```verilog
empty <= (num_items == 0);
full  <= (num_items == DEPTH);
```

Because nonblocking assignments use the old value of `num_items`, the flags describe the **previous occupancy**, not the occupancy after the current operation.

For example:

```text
num_items = 15
wr_en = 1

At clock edge:
    write occurs
    num_items becomes 16
    full still receives (15 == 16) → 0

Next clock:
    full becomes 1
```

Therefore, `full` can become valid **one cycle after the FIFO actually becomes full**.

The same issue occurs for `empty` when the FIFO transitions from one entry to zero.

This is especially important because the write/read gating uses:

```verilog
!full
!empty
```

which are themselves registered.

---

# 5. Another Important Issue: `next_*_ptr`

The design has both:

```verilog
rd_ptr
wr_ptr
```

and:

```verilog
next_rd_ptr
next_wr_ptr
```

The actual pointers are updated here:

```verilog
rd_ptr <= next_rd_ptr;
wr_ptr <= next_wr_ptr;
```

while the next pointers are calculated from the **old pointers**.

This adds an unnecessary extra state layer and makes the pointer behavior harder to reason about.

A simpler implementation would normally update:

```verilog
wr_ptr <= (wr_ptr + 1) % DEPTH;
rd_ptr <= (rd_ptr + 1) % DEPTH;
```

directly when the corresponding operation occurs.

---

# 6. Parameterization Limitation

This line:

```verilog
localparam PTR_WIDTH = $clog2(DEPTH);
```

works naturally for power-of-two depths such as:

```text
8, 16, 32, 64...
```

but arbitrary depths require care.

For example:

```text
DEPTH = 10
PTR_WIDTH = 4
```

A 4-bit pointer can represent `0–15`, so the modulo operation is necessary to prevent invalid addresses.

The current:

```verilog
(wr_ptr + 1) % DEPTH
```

and:

```verilog
(rd_ptr + 1) % DEPTH
```

handles this functionally, although modulo hardware can be more expensive than simple wrap logic, particularly for non-power-of-two depths.

---

# 7. Advantages & Limitations

### Advantages

* Parameterized FIFO width and depth.
* Explicit occupancy tracking.
* Supports simultaneous read/write.
* Simple synchronous architecture.
* Correctly prevents writes when `full`.
* Correctly prevents reads when `empty`.
* Pointer wrapping supports configurable depth.

### Limitations

* `full` and `empty` are registered and can be one cycle stale.
* `next_rd_ptr` and `next_wr_ptr` add unnecessary complexity.
* `% DEPTH` may synthesize to relatively expensive logic for arbitrary depths.
* Memory is not reset, which is normally acceptable because `num_items` determines validity.
* No `almost_full` / `almost_empty` indicators.
* No data-count output.
* This is **not an asynchronous FIFO** and cannot directly cross clock domains.
* A testbench is not supplied with this RTL, so data ordering and boundary behavior are not independently verified here.

---

# 8. Interview Takeaways

### One-line explanation

> **“This is a parameterized synchronous FIFO that uses read/write pointers and an occupancy counter to manage storage, with support for simultaneous read/write and configurable FIFO depth and data width.”**

### Key interview questions

**Q: Why is `CNT_WIDTH = $clog2(DEPTH+1)`?**
Because the counter must represent values from `0` through `DEPTH`, inclusive.

**Q: Why is simultaneous read/write handled separately?**
Because one item enters and one item leaves in the same cycle, so the occupancy count must remain unchanged.

**Q: Why use `% DEPTH`?**
To wrap the pointer back to zero after reaching the last FIFO location, particularly for non-power-of-two depths.

**Q: Is `empty` combinational?**
No. It is registered inside the clocked `always` block.

**Q: What is the main weakness of this implementation?**
The registered `full`/`empty` flags can lag the actual `num_items` state by one clock cycle, and the extra `next_*_ptr` registers make the control logic more complicated than necessary.

**Q: What would you use for a dual-clock FIFO?**
Separate read/write clocks with CDC-safe pointer synchronization, typically using **Gray-coded pointers**.
