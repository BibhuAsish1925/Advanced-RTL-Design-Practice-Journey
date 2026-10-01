# 16-BIT GALOIS LFSR

## 1. Circuit Overview & Applications

This design implements a **16-bit Galois Linear Feedback Shift Register (LFSR)** with an enable control.

* **Width:** 16 bits
* **Architecture:** Galois LFSR
* **Seed:** `16'h0001`
* **Feedback taps:** `16'h002D`
* **Reset:** Asynchronous active-low
* **Enable:** `en`
* **Output:** `q[15:0]`
* **Storage:** 16 flip-flops + XOR feedback network

### Applications

* Built-In Self-Test (BIST)
* Pseudo-random test-pattern generation
* Scramblers
* CRC-related hardware
* Communication systems
* Digital/ASIC verification

---

## 2. Circuit Working & RTL Implementation

The state is stored in:

```systemverilog
logic [W-1:0] q;
```

The sequential block uses:

```systemverilog
always_ff @(posedge clk or negedge rst_n)
```

Therefore, the circuit has an **asynchronous active-low reset**.

### Reset

```systemverilog
if (!rst_n)
    q <= 'h1;
```

For `W=16`, this initializes:

```text
q = 0001
```

### Enabled operation

When `en=1`:

```systemverilog
q <= {q[W-2:0],1'b0} ^ (q[W-1] ? TAPS : '0);
```

The operation consists of two parts:

1. Shift the register left by one position.
2. If the outgoing MSB `q[15]` is `1`, XOR the configured tap mask `16'h002D`.

Conceptually:

```text
             q[15]
               │
               ▼
          ┌──────────┐
          │ TAPS     │
          │ 002D     │
          └────┬─────┘
               │
               XOR
               │
q[15:0] ──> Shift ──> Next State
```

This is the characteristic **Galois form** of an LFSR: feedback is distributed through XOR taps rather than calculating one single XOR feedback bit as in the Fibonacci form.

### Enable behavior

When:

```text
en = 0
```

there is no assignment to `q`, so the register **holds its current state**.

When:

```text
en = 1
```

the LFSR advances by one state on each rising clock edge.

---

## 3. Verification & Testbench

The testbench uses a **10 ns clock period**:

```systemverilog
always #5 clk = ~clk;
```

So:

```text
Clock frequency = 100 MHz
```

### Test sequence

The TB first applies:

```text
rst_n = 0
en    = 0
```

After 12 ns, reset is released.

It then checks:

```systemverilog
if (q !== 16'h0001)
```

to verify the reset seed.

After that:

```systemverilog
en = 1;
```

and the LFSR is allowed to run for **1000 clock cycles**.

The TB records the initial state:

```systemverilog
first_val = q;
```

and checks whether the sequence returns to that value prematurely.

It then disables the LFSR:

```systemverilog
en = 0;
```

and allows 20 ns before finishing.

### Verification strength

This TB is stronger than the previous observational LFSR testbench because it contains actual checks:

* ✅ Reset seed verification
* ✅ 1000-cycle repeat check
* ✅ Enable control
* ✅ `$monitor` for waveform/state observation

However, the comment says the TB checks the **full 65,535-cycle period**, but the actual loop only runs:

```text
1000 cycles
```

So it **does not verify the complete maximal-length period**.

Also, it does not independently calculate the expected next state, so it cannot detect an incorrect sequence that simply happens not to repeat within 1000 cycles.

---

## 4. Advantages & Limitations

### Advantages

* Galois architecture can provide efficient XOR feedback implementation.
* Parameterized width and tap mask.
* Enable allows controlled sequence advancement.
* Asynchronous reset provides deterministic initialization.
* Synthesizable SystemVerilog.
* Suitable for high-speed digital implementations.

### Limitations

* Sequence quality depends on the selected `TAPS` polynomial.
* Current TB does not prove that `16'h002D` produces a 65,535-state maximal-length sequence.
* Only 1000 states are checked for premature repetition.
* LFSR output is deterministic and therefore not cryptographically secure.
* The all-zero state would be a lock-up state for this XOR-based structure.

---

## 5. Interview Takeaways

**One-line explanation:**

> A Galois LFSR uses a shift register with conditional XOR tap feedback to generate a deterministic pseudo-random sequence with low hardware complexity.

### Galois vs. Fibonacci LFSR

| Galois LFSR                                 | Fibonacci LFSR                                   |
| ------------------------------------------- | ------------------------------------------------ |
| Feedback distributed through taps           | Feedback generated as a single XOR function      |
| Conditional XOR based on outgoing bit       | XOR of selected state bits                       |
| Often efficient for hardware implementation | Simple to understand mathematically              |
| This design uses this architecture          | Your earlier LFSRs used Fibonacci-style feedback |

### Important point about this specific code

The design is **parameterized**, but the testbench fixes:

```systemverilog
localparam W = 16;
```

and instantiates the default `TAPS=16'h002D`.

Therefore, the actual tested circuit is a **16-bit Galois LFSR with seed `0001` and tap mask `002D`**.

Also, the statement in the TB:

> “does eventually return after the full maximal-length period of 65535 cycles”

is a **comment/intention**, not something the current testbench actually verifies. The current 1000-cycle test only checks for premature repetition.
