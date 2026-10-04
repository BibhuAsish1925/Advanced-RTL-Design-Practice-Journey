## 1. Circuit Overview & Applications

This project implements a **parameterized 32×8 synchronous FIFO** and verifies it using a **class-based SystemVerilog verification environment**.

### DUT architecture

* Data width: **8 bits**
* Depth: **32 entries**
* Write pointer: `wr_ptr`
* Read pointer: `rd_ptr`
* Occupancy counter: `count`
* Status flags: `full`, `empty`
* Synchronous reset
* Separate read/write controls
* Internal memory array `mem[0:DEPTH-1]`

### Applications

* Data buffering between blocks operating at the same clock
* Pipeline buffering
* Packet/data queues
* Producer-consumer communication
* Bus and peripheral interfaces

---

## 2. Circuit Working & RTL Implementation

The FIFO stores incoming data when:

```systemverilog
wr && !full
```

and reads data when:

```systemverilog
rd && !empty
```

The write operation stores data and advances `wr_ptr`:

```systemverilog
mem[wr_ptr] <= data_in;
wr_ptr      <= wr_ptr + 1'b1;
```

The read operation transfers memory data to `data_out` and advances `rd_ptr`:

```systemverilog
data_out <= mem[rd_ptr];
rd_ptr   <= rd_ptr + 1'b1;
```

The `count` tracks the number of occupied FIFO locations:

```text
Write only → count + 1
Read only  → count - 1
Both/neither → count unchanged
```

The flags are derived from the count:

```systemverilog
empty = (count == 0);
full  = (count == DEPTH);
```

`$clog2()` is used to automatically determine pointer width, making the FIFO **parameterized** rather than fixed to only 32 entries.

---

## 3. Verification & Testbench

The testbench follows this architecture:

```text
                 ┌─────────────┐
                 │  Generator  │
                 └──────┬──────┘
                        │
                     Mailbox
                        │
                        ▼
                 ┌─────────────┐
                 │   Driver    │
                 └──────┬──────┘
                        │
                 Virtual Interface
                        │
                        ▼
                    ┌───────┐
                    │ FIFO  │
                    └───┬───┘
                        │
                        ▼
                 ┌─────────────┐
                 │   Monitor   │
                 └──────┬──────┘
                        │
                     Mailbox
                        │
                        ▼
                 ┌─────────────┐
                 │ Scoreboard  │
                 │ + Reference │
                 │    Queue    │
                 └─────────────┘
```

### Transaction

Randomizes:

```systemverilog
rand bit wr;
rand bit rd;
rand bit [7:0] data_in;
```

and stores observed:

```text
data_out
full
empty
```

### Generator

* Randomizes FIFO operations.
* Sends transaction to the driver.
* Waits for the scoreboard through `sconext`.
* Generates **50 transactions** in this test.

### Driver

* Applies reset.
* Receives transactions through the mailbox.
* Drives `wr`, `rd`, and `data_in` on the **negedge**.
* Uses a **virtual interface**.

### Monitor

Samples:

```text
wr
rd
data_in
data_out
full
empty
```

on the rising edge and sends the transaction to the scoreboard.

### Scoreboard

This is the key part of this FIFO verification environment.

It maintains:

```systemverilog
bit [7:0] reference_queue[$];
```

This queue acts as a **reference model** of the FIFO.

For an accepted write:

```text
DUT FIFO:       push data
Reference:      push data
```

For an accepted read:

```text
DUT FIFO:       output data
Reference:      pop expected data
```

Then:

```text
Expected data == DUT data_out
```

is checked.

The scoreboard also checks the `empty` and `full` conditions against the reference queue size.

---

## 4. Advantages & Limitations

### Advantages

* Parameterized FIFO RTL.
* Uses `$clog2()` for automatic sizing.
* Proper separation of generator, driver, monitor and scoreboard.
* Uses **mailbox-based communication**.
* Uses **virtual interface**.
* Uses a **queue as a reference model**.
* Verifies:

  * FIFO data ordering
  * Write behavior
  * Read behavior
  * `full`
  * `empty`
* Randomized read/write stimulus.
* Generates VCD waveform for debugging.

### Limitations

The current environment does **not** yet include:

* Functional coverage
* SVA assertions
* Clocking block
* Dedicated reference-model class
* Error/pass counters
* Directed corner-case tests such as:

  * Write when full
  * Read when empty
  * Fill exactly to full
  * Drain exactly to empty
  * Simultaneous read/write at boundaries

Also, the transaction constraint:

```systemverilog
wr inside {0,1};
rd inside {0,1};
```

does not meaningfully constrain 1-bit variables because both values are already legal. It is therefore mainly illustrative.

---

## 5. Interview Takeaways

This is a **significant step beyond the DFF class-based testbench** because it introduces a real **reference-model-based scoreboard**.

The important verification flow is:

> **Random transaction → Generator → Driver → FIFO → Monitor → Scoreboard → Reference Queue**

Key concepts demonstrated:

* Parameterized RTL
* `$clog2`
* FIFO architecture
* Dynamic queue
* Constrained randomization
* Transaction class
* Mailbox
* Generator
* Driver
* Monitor
* Virtual interface
* Scoreboard
* Reference model
* Event synchronization
* Class-based SystemVerilog verification

### Most important interview point

The scoreboard's queue is a **predictive reference model**:

```text
                 Reference Queue
                       │
                       ▼
Expected ────────────► Compare ◄──────────── Actual
                                             │
                                            FIFO
```

For FIFO verification, this is much better than simply checking individual signals because it verifies the fundamental FIFO property:

**data must emerge in the same order in which valid data was accepted.**
