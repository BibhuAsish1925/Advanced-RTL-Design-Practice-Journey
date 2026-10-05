## 1. Circuit Overview & Applications

This is a **4-bit registered/sequential adder**.

Unlike the previous combinational adder, the output is stored in a register and updates only on the **rising edge of `clk`**.

```text
        a[3:0] ──┐
                 │
                 ▼
              ┌───────┐
        b[3:0] ─►  +  │
              │       │
              └───┬───┘
                  │
               5-bit
               result
                  │
              ┌───▼───┐
 clk ────────►│ Register│──► y[4:0]
 rst ────────►│         │
              └─────────┘
```

This is useful for learning **clocked DUT verification with UVM**, which is the natural next step after your previous combinational-adder UVM environment.

---

## 2. Circuit Working & RTL Implementation

### Clocked operation

The core logic is:

```systemverilog
always @(posedge clk) begin
```

Therefore, `y` changes only at the rising edge of `clk`.

### Reset

```systemverilog
if (rst)
    y <= 5'b00000;
```

When `rst = 1` at a rising clock edge:

```text
y = 0
```

This is a **synchronous active-high reset** because reset is checked inside the `posedge clk` block.

### Addition

When reset is inactive:

```systemverilog
else
    y <= a + b;
```

At every rising edge:

```text
y(next) = a + b
```

For example:

```text
a = 7
b = 9

At rising edge:
y = 16
```

Because `y` is 5 bits, the carry is preserved.

### Important difference from the previous adder

Previous DUT:

```text
a + b → y immediately
```

Current DUT:

```text
a + b → y only after a clock edge
```

So the verification environment now needs to understand **clock and reset timing**.

---

## 3. Verification & Testbench

The interface now contains:

```systemverilog
logic       clk;
logic       rst;
logic [3:0] a;
logic [3:0] b;
logic [4:0] y;
```

This is appropriate for connecting the sequential DUT to a UVM environment through a virtual interface.

The eventual UVM flow will become:

```text
Sequence
   ↓
Sequencer
   ↓
Driver
   ↓
a, b, rst
   ↓
Clock edge
   ↓
Sequential Adder
   ↓
y
   ↓
Monitor
   ↓
Scoreboard
```

### Important verification point

Because this is a registered output, the scoreboard **must not simply compare `y` with the currently driven `a+b` at an arbitrary time**.

It needs to account for the clocked behavior:

```text
At rising edge:
    if rst = 1 → expected_y = 0
    else       → expected_y = a + b
```

That makes this DUT a good exercise for introducing:

* Clock generation
* Reset sequencing
* Clock-synchronized driver
* Clock-synchronized monitor
* Sequential scoreboard/reference model
* Eventually clocking blocks

---

## 4. Advantages & Limitations

### Advantages

* Introduces sequential RTL verification.
* Includes synchronous reset.
* Preserves carry using a 5-bit output.
* Provides a natural transition from combinational to clocked UVM verification.
* Simple enough to understand the timing behavior clearly.

### Current limitations

The supplied code contains only:

* DUT
* Interface

It does **not yet contain**:

* Clock generation
* Reset generation
* Transaction
* Sequence
* Driver
* Monitor
* Scoreboard
* Agent
* Environment
* Test
* Top-level UVM configuration

So this is currently the **DUT/interface portion** of the next UVM example.

---

## 5. Interview Takeaways

**Q: Is the reset synchronous or asynchronous?**
A: **Synchronous active-high reset**, because `rst` is evaluated inside `always @(posedge clk)`.

**Q: When does `y` change?**
A: Only on the rising edge of `clk`.

**Q: Why is `y` 5 bits?**
A: Two 4-bit numbers can produce a maximum value of 30, requiring 5 bits.

**Q: What is the main verification difference from the previous 4-bit adder?**
A: The checker must consider **clock and reset timing**, not just the mathematical `a+b` relationship.

### Repo status

🟡 **Sequential DUT + interface — IN PROGRESS**

This is the correct starting point for the next UVM exercise: **clock/reset-aware UVM verification of a sequential DUT**.
