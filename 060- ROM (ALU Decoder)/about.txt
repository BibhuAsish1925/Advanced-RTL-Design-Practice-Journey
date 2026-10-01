## ALU Decoder ROM — Circuit Analysis

### 1. Circuit Overview & Applications

This design implements a **16-word × 8-bit asynchronous ROM** used as an **ALU/control decoder**.

* **Input:** 4-bit `alu_opcode` → 16 possible instructions
* **ROM:** `16 × 8 = 128 bits = 16 bytes`
* **Output:** 8-bit `control_signals`
* **Read type:** Asynchronous/combinational
* **ROM contents:** Fixed control patterns corresponding to ALU/instruction operations

The ROM maps each opcode to a predefined 8-bit control word.

Typical applications include **ALU control decoding, instruction decoding, microcoded control logic, lookup tables, and fixed control-signal generation**.

---

### 2. Circuit Working & RTL Implementation

The architecture is essentially:

```text
              alu_opcode[3:0]
                    │
                    ▼
             ┌─────────────┐
             │ 16 × 8 ROM  │
             │             │
             │ Opcode →    │
             │ Control     │
             └──────┬──────┘
                    │
                    ▼
          control_signals[7:0]
```

The ROM is declared as:

```verilog
reg [7:0] mem [0:15];
```

This means:

* 16 locations
* Each location stores 8 bits

Therefore:

```text
16 × 8 = 128 bits = 16 bytes
```

The `initial` block programs the ROM contents:

| Opcode | Operation           | Control    |
| ------ | ------------------- | ---------- |
| `0000` | ADD                 | `00000001` |
| `0001` | SUBTRACT            | `00000101` |
| `0010` | AND                 | `00001001` |
| `0011` | OR                  | `00001101` |
| `0100` | XOR                 | `00010001` |
| `0101` | Complement          | `00010101` |
| `0110` | Shift left logical  | `00011001` |
| `0111` | Shift right logical | `00011101` |
| `1000` | Rotate left         | `00100001` |
| `1001` | Rotate right        | `00100101` |
| `1010` | Load immediate      | `00101001` |
| `1011` | Load register       | `00101101` |
| `1100` | Store register      | `00110001` |
| `1101` | Branch              | `00110101` |
| `1110` | Jump                | `11111001` |
| `1111` | Branch if equal     | `11111101` |

The actual decoding operation is very simple:

```verilog
always @(*) begin
    control_signals = mem[alu_opcode];
end
```

Whenever `alu_opcode` changes, the corresponding ROM location is read and placed on `control_signals`.

For example:

```text
alu_opcode = 0010
        ↓
mem[2]
        ↓
control_signals = 00001001
```

There is **no clock**, so the ROM provides an asynchronous lookup.

---

### 3. Verification & Testbench

The testbench instantiates the ROM and tests six opcode values:

```text
0000
0010
1111
0001
0011
0100
```

For each opcode, it waits 10 ns and displays the generated control word.

For example:

```verilog
alu_opcode = 4'b0010;
#10;
$display(...);
```

Expected result:

```text
Control signals for opcode 0010 is 00001001
```

The testbench then tests the remaining selected operations and terminates with:

```verilog
$finish;
```

### Verification strength

The testbench is **directed and observational**.

It confirms the output visually through `$display`, but it does **not automatically check** whether the output matches the expected control word.

A stronger testbench could test all 16 opcodes and use expected values:

```text
opcode → expected control → actual control → PASS/FAIL
```

Since there are only 16 possible addresses, **exhaustive testing of all 16 opcodes is very easy**.

---

### 4. Advantages & Limitations

**Advantages**

* Simple and readable ROM implementation.
* Direct opcode-to-control mapping.
* Asynchronous lookup gives immediate combinational response.
* Easy to modify the control table.
* Suitable for small fixed lookup tables.
* Exhaustive verification is straightforward because only 16 entries exist.

**Limitations**

* The ROM contents are initialized using an `initial` block, which is suitable for simulation and may map appropriately on some FPGA flows, but ASIC ROM implementation would normally use a technology-specific ROM/memory structure.
* The testbench checks only 6 of 16 possible opcodes.
* No automatic PASS/FAIL checking.
* A large ROM implemented this way may synthesize into substantial combinational logic rather than a dedicated ROM structure, depending on the target technology and synthesis tool.
* No reset is required because the ROM contents are fixed and `control_signals` is combinational.

---

### 5. Interview Takeaways

**What is this circuit?**
A **16×8 asynchronous ROM used as an ALU/instruction decoder**.

**Why is the ROM 16 entries deep?**
Because the opcode is 4 bits:

```text
2^4 = 16 possible opcodes
```

**Why is it 8 bits wide?**
Each opcode generates an 8-bit control word.

**Is this a synchronous or asynchronous ROM?**
Asynchronous, because there is no clock and the output directly depends on `alu_opcode`.

**What does `mem[alu_opcode]` do?**
It uses the opcode as the ROM address and retrieves the corresponding 8-bit control word.

**One-line interview explanation:**

> “I implemented a 16×8 asynchronous ALU decoder ROM where a 4-bit opcode indexes a fixed lookup table to generate the corresponding 8-bit control signals for arithmetic, logical, shift, data-transfer, and branch operations.”
