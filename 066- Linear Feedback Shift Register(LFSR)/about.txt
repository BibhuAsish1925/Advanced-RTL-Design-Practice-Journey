# 8-BIT LFSR (LINEAR FEEDBACK SHIFT REGISTER)

## 1. Circuit Overview & Applications

This design implements an **8-bit Linear Feedback Shift Register (LFSR)** that generates a deterministic pseudo-random binary sequence.

* **Width:** 8 bits
* **Type:** Synchronous sequential circuit
* **Reset value:** `8'hFF`
* **Feedback:** XOR of bits `7, 5, 4, 3`
* **Shift direction:** Left
* **Output:** Current 8-bit LFSR state
* **Storage:** 8 flip-flops

### Applications

* Pseudo-random pattern generation
* Built-In Self-Test (BIST)
* Digital/ASIC verification
* CRC and error-detection-related logic
* Scramblers
* Communication systems
* Hardware security/randomized test patterns

---

## 2. Circuit Working & RTL Implementation

The LFSR stores its current state in the 8-bit register `data`.

On every **positive edge of `clk`**:

### Reset

```verilog
if (reset)
    data <= 8'hff;
```

When reset is asserted, the LFSR is loaded with:

```text
11111111
```

### Normal Operation

```verilog
data <= {data[6:0], data[7] ^ data[5] ^ data[4] ^ data[3]};
```

The register shifts toward the MSB side:

```text
Old: [7][6][5][4][3][2][1][0]
New: [6][5][4][3][2][1][0][Feedback]
```

where:

```text
Feedback = data[7] XOR data[5] XOR data[4] XOR data[3]
```

So the architecture is essentially:

```text
       ┌─────────────────────────────┐
       │        XOR Feedback         │
       │                             │
       │  bit7 ─┐                    │
       │  bit5 ─┼─ XOR ─┐            │
       │  bit4 ─┤       ├──> New bit0
       │  bit3 ─┘       │            │
       └───────────────┼─────────────┘
                       │
             ┌─────────▼─────────┐
             │  8-bit Shift Reg  │
             │ [7:0]             │
             └───────────────────┘
                    │
                    ▼
                lfsr_out
```

The output is simply connected to the internal register:

```verilog
assign lfsr_out = data;
```

### Important characteristic

An LFSR is **deterministic**, not truly random. Starting from the same non-zero seed produces the same sequence.

The XOR feedback taps determine the sequence length. For a properly selected primitive polynomial, an 8-bit LFSR can achieve a **maximum-length sequence of 255 non-zero states**.

---

## 3. Verification & Testbench

The testbench provides:

* `clk` with a **10 ns period**
* Initial reset assertion
* Reset release after **10 ns**
* Continuous monitoring of `lfsr_out`
* Simulation termination at **115 ns**

Clock:

```verilog
always #5 clk = ~clk;
```

Therefore:

```text
Clock period = 10 ns
Frequency    = 100 MHz
```

The monitor:

```verilog
$monitor("\t\t clk: %b   lfsr_out: %b", clk, lfsr_out);
```

continuously displays the clock and current LFSR state.

### Expected behavior

After reset:

```text
lfsr_out = 11111111
```

Then the register changes on every positive clock edge.

For example, starting from `FF`:

```text
11111111
11111110
11111100
11111000
...
```

The exact sequence continues according to the selected XOR taps.

### Testbench limitation

The current TB is **observational**, not self-checking. It does not verify:

* Expected LFSR sequence
* Maximum sequence length
* Repetition after 255 states
* Lock-up at zero
* Correct feedback polynomial

A stronger verification environment would maintain a reference LFSR and automatically compare every generated state.

---

## 4. Advantages & Limitations

### Advantages

* Very small hardware: only **8 flip-flops + XOR gates**
* Simple and fast
* Synthesizable RTL
* Useful for pseudo-random test-pattern generation
* Easily parameterized for larger LFSR widths

### Limitations

* Sequence is deterministic
* XOR tap selection determines sequence quality
* Current design does not explicitly prevent the all-zero state
* Not a cryptographically secure random-number generator
* Current testbench does not automatically detect an incorrect sequence

---

## 5. Interview Takeaways

**Key concept:** An LFSR generates pseudo-random sequences using a shift register and XOR feedback taps.

**Architecture:**
`8 FFs + XOR feedback network`

**Why use it?**
It provides pseudo-random patterns using very little hardware, making it useful for **BIST, test-pattern generation, scramblers, and verification**.

**Important interview question:**

> What happens if an LFSR enters the all-zero state?

For an XOR-based LFSR, the feedback remains zero, so:

```text
00000000 → 00000000 → 00000000 → ...
```

It becomes a **lock-up state**. Therefore, a non-zero seed is normally required. Your design uses `8'hFF`, so it starts from a non-zero state.
