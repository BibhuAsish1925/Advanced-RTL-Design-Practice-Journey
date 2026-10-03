## 1. Circuit Overview & Applications

This project implements a **parameterized streaming CRC generator**. The default configuration is **CRC-32/ISO-HDLC**, using the reflected polynomial:

```text
POLY    = 32'hEDB88320
INIT    = 32'hFFFFFFFF
XOR_OUT = 32'hFFFFFFFF
```

The module accepts a **byte stream** and updates the CRC only when `valid_i=1`.

```text
Byte stream
    │
    ▼
┌───────────────┐
│ CRC state     │
│ 32-bit LFSR   │
└───────┬───────┘
        │
        ▼
Final XOR
        │
        ▼
      crc_o
```

`last_i` identifies the final byte of a message. When that byte is processed, `valid_o` pulses and the resulting CRC appears on `crc_o`.

### Applications

* Ethernet/network protocols
* ZIP/archive formats
* PNG and other file formats
* Communication links
* Storage/data-integrity checking
* Packet/frame validation
* FPGA/ASIC streaming datapaths

---

# 2. Circuit Working & RTL Implementation

### A. CRC state initialization

The CRC register is initialized asynchronously with:

```verilog
if (!rst_n) begin
    crc <= INIT_VAL;
```

For the default configuration:

```text
CRC = FFFFFFFF
```

This allows the same CRC engine to process multiple messages.

---

### B. Byte processing

When:

```verilog
valid_i == 1
```

the module copies the current state and input byte into temporary variables:

```verilog
c = crc;
d = data_i;
```

Then it processes all 8 bits of the byte:

```verilog
for (i=0; i<8; i=i+1)
```

The key operation is:

```verilog
if (c[0] ^ d[0])
    c = (c >> 1) ^ POLY;
else
    c = (c >> 1);
```

This is a **reflected/right-shifting CRC implementation**.

The least-significant bit of the current CRC is XORed with the current data bit. If the result is `1`, the polynomial is XORed after shifting.

The data byte is also shifted:

```verilog
d = d >> 1;
```

So one input byte requires eight CRC iterations.

---

### C. State update

After processing the byte:

```verilog
crc <= c;
```

Therefore, the next valid byte starts from the CRC state produced by the previous byte.

Conceptually:

```text
CRC[n+1] = CRC_update(CRC[n], data[n])
```

This makes the design suitable for streaming data.

---

### D. End-of-message handling

When:

```verilog
last_i == 1
```

the calculated CRC is finalized:

```verilog
crc_o <= c ^ XOR_OUT;
valid_o <= 1'b1;
```

For CRC-32:

```text
Final CRC = calculated CRC XOR FFFFFFFF
```

The module then automatically reseeds:

```verilog
crc <= INIT_VAL;
```

This means the next message can begin without requiring another reset.

---

### E. Control interface

| Signal    | Function                                   |
| --------- | ------------------------------------------ |
| `valid_i` | Indicates that `data_i` is a valid byte    |
| `data_i`  | 8-bit input byte                           |
| `last_i`  | Indicates final byte of current message    |
| `valid_o` | One-cycle indication that `crc_o` is valid |
| `crc_o`   | Final CRC value                            |
| `rst_n`   | Active-low asynchronous reset              |

A useful interpretation is:

```text
valid_i + data_i
       │
       ▼
   CRC update
       │
   last_i = 1
       │
       ▼
valid_o + crc_o
```

---

# 3. Verification & Testbench

The testbench uses the classic CRC verification message:

```text
"123456789"
```

This is an important CRC test vector because the expected CRC-32/ISO-HDLC result is:

```text
CBF43926
```

The testbench sends the nine bytes sequentially:

```text
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
```

with:

```verilog
last_i = (i == 8);
```

Therefore only the final byte asserts `last_i`.

### Verification flow

```text
Reset
  ↓
Release reset
  ↓
Send "123456789"
  ↓
last_i on '9'
  ↓
valid_o
  ↓
Compare crc_o
  ↓
Expected = CBF43926
```

The TB performs a direct self-check:

```verilog
if (crc_o !== 32'hCBF43926)
    $display("FAIL...");
else
    $display("PASS...");
```

### Expected result

```text
PASS:
generic-CRC-32("123456789") = CBF43926
```

So the testbench verifies the complete streaming calculation for the configured CRC parameters.

### TB strengths

* Uses a known standard test vector
* Exercises all nine input bytes
* Tests `valid_i`
* Tests `last_i`
* Tests `valid_o`
* Checks the final CRC automatically
* Uses clocked streaming behavior rather than a purely combinational test

---

# 4. Advantages & Limitations

### Advantages

| Aspect                      | Description                                                 |
| --------------------------- | ----------------------------------------------------------- |
| **Parameterized**           | Width, polynomial, initial value and final XOR configurable |
| **Streaming**               | Processes one byte whenever `valid_i` is asserted           |
| **Reflected CRC**           | Implements right-shifting CRC calculation                   |
| **Message framing**         | `last_i` identifies the final byte                          |
| **Automatic reseed**        | Ready for another message after completion                  |
| **Self-checking TB**        | Verifies against known CRC-32 vector                        |
| **Synthesizable structure** | Suitable as a starting RTL CRC implementation               |

### Limitations

**1. Eight CRC iterations per byte**

The `for` loop is inside a clocked block, but synthesis will generally unroll the loop into combinational logic.

So one clock processes one byte using approximately eight CRC update stages.

For higher throughput, architectures can process multiple bytes per cycle or use lookup tables.

**2. Generic parameters do not mean every polynomial configuration is automatically valid**

The implementation assumes the selected polynomial and initialization/finalization parameters correspond to the intended CRC convention.

CRC standards can differ in:

* Polynomial representation
* Reflected/non-reflected processing
* Initial value
* Final XOR
* Input/output reflection

These parameters must therefore be chosen consistently.

**3. Temporary variables are procedural registers**

```verilog
reg [WIDTH-1:0] c;
reg [7:0] d;
```

are assigned using blocking assignments inside the sequential block. They function as temporary variables for the CRC calculation rather than pipeline state.

For clearer RTL style, they could alternatively be implemented as combinational next-state logic.

**4. `valid_o` is a pulse**

The consumer must sample `crc_o` when:

```text
valid_o = 1
```

rather than assuming `crc_o` is continuously valid.

**5. No backpressure**

There is no `ready_i` signal. Therefore, whenever `valid_i=1`, the module must accept the byte.

A more complete streaming interface could use:

```text
valid_i / ready_i
valid_o / ready_o
```

---

# 5. Interview Takeaways

### Key concept

> **A CRC is an LFSR-based error-detection mechanism in which input data bits modify a polynomial remainder; the final remainder becomes the CRC value.**

### Important interview questions

**Q: Why is `EDB88320` used instead of `04C11DB7`?**

Because this implementation uses the **reflected/right-shifting representation** of CRC-32/ISO-HDLC. The commonly cited normal representation is `04C11DB7`, while the reflected representation used by this RTL is `EDB88320`.

**Q: What does `last_i` do?**

It identifies the final byte so that the module can perform the final XOR and assert `valid_o`.

**Q: Why is `crc <= INIT_VAL` also assigned in the `last_i` branch?**

To automatically reinitialize the CRC engine for the next independent message.

**Q: Does CRC correct errors?**

No. CRC is primarily an **error-detection** mechanism. It detects many transmission/storage errors but does not itself correct the corrupted data.

**Q: Why is `"123456789"` useful?**

It is a widely used known-answer test vector for CRC implementations. For CRC-32/ISO-HDLC, the expected result is:

```text
CBF43926
```

### One-line interview explanation

> **“I implemented a parameterized streaming CRC generator with configurable polynomial, initialization and final-XOR parameters, byte-wise reflected CRC computation, message-boundary detection through `last_i`, and self-checking verification using the CRC-32 `123456789 → CBF43926` golden vector.”**
