## 1. Circuit Overview & Applications

This project implements a **D flip-flop (DFF)** and verifies it using a **class-based SystemVerilog testbench**.

### DUT

* Positive-edge-triggered DFF.
* `rst` is a synchronous reset.
* When `rst = 1`, `dout` becomes `0`.
* Otherwise, `dout` captures `din` on `posedge clk`.

### Applications

* Registers and pipeline stages
* Data storage elements
* FSM state registers
* Synchronization and sequential logic
* Basic building block for larger RTL designs

---

## 2. Circuit Working & RTL Implementation

The DUT uses a SystemVerilog interface:

```systemverilog
interface dff_if;
  logic clk;
  logic rst;
  logic din;
  logic dout;
endinterface
```

The interface groups all DFF signals and is passed directly to the DUT:

```systemverilog
module dff(dff_if vif);
```

The sequential behavior is:

```systemverilog
always @(posedge vif.clk) begin
  if (vif.rst)
    vif.dout <= 1'b0;
  else
    vif.dout <= vif.din;
end
```

So:

| Clock | Reset | Operation                   |
| ----- | ----: | --------------------------- |
| ↑     |     1 | `dout = 0`                  |
| ↑     |     0 | `dout = din`                |
| No ↑  |     X | Output holds previous value |

The reset is therefore **synchronous**, because it is evaluated only at the rising clock edge.

---

## 3. Verification & Testbench

The testbench follows a basic **class-based SV verification architecture**:

```text
              Generator
                  │
             Mailbox
                  │
                  ▼
               Driver
                  │
          Virtual Interface
                  │
                  ▼
                 DFF
                  │
                  ▼
               Monitor
                  │
             Mailbox
                  │
                  ▼
             Scoreboard
                  ▲
                  │
          Reference Data
                  │
              Generator
```

### Transaction

Contains:

```systemverilog
rand bit din;
bit dout;
```

It also provides a `copy()` method and `display()` method.

### Generator

* Randomizes `din`.
* Creates separate copies of the transaction.
* Sends one copy to the driver.
* Sends another copy as the expected/reference transaction.
* Uses an event to wait for scoreboard completion.

### Driver

* Receives transactions through a mailbox.
* Drives `din` on the **negedge** of the clock.
* Provides a reset sequence.
* Uses a **virtual interface** to access DUT signals.

### Monitor

* Samples the DFF output on `posedge clk`.
* Uses `#1` to allow the DUT's nonblocking assignment to update.
* Sends the observed result to the scoreboard.

### Scoreboard

Compares:

```text
Actual DFF output
        vs
Expected generator input
```

For a DFF:

```text
dout == previous/current sampled din
```

under the timing used by this testbench.

### Environment

Integrates:

* Generator
* Driver
* Monitor
* Scoreboard
* Three mailboxes
* Synchronization events
* Virtual interface

This is effectively a **small non-UVM verification environment**.

---

## 4. Advantages & Limitations

### Advantages

* Uses a clean **class-based verification architecture**.
* Demonstrates **interface + virtual interface**.
* Uses **mailboxes** for component communication.
* Uses **randomized stimulus**.
* Separates stimulus generation, driving, monitoring, and checking.
* Uses a **reference transaction** for scoreboard comparison.
* Introduces synchronization between generator and scoreboard.
* Generates a VCD waveform for debugging.

### Limitations

* No functional coverage.
* No SystemVerilog assertions.
* Scoreboard uses direct transaction comparison rather than a separate reference-model class.
* Driver/monitor synchronization relies on explicit clock/event timing rather than a clocking block.
* No error/failure counter or final pass/fail summary.
* The testbench has only one basic randomized scenario.

---

## 5. Interview Takeaways

This is a good **first class-based SystemVerilog verification example** because it combines several important DV concepts:

* **Interface**
* **Virtual interface**
* **Class**
* **Transaction**
* **Inheritance-independent OOP structure**
* **Randomization**
* **Mailbox**
* **Generator**
* **Driver**
* **Monitor**
* **Scoreboard**
* **Reference transaction**
* **Event synchronization**
* **Environment**
* **VCD waveform generation**

The most important architecture to remember is:

> **Generator creates transactions → Driver drives DUT → Monitor observes DUT → Scoreboard compares actual vs expected.**

This DFF example is therefore a useful bridge from your individual SystemVerilog concepts into the **complete non-UVM verification environment** phase of your new repository.
