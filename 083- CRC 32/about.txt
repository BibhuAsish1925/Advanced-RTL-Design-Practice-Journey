## 1. Circuit Overview & Applications

This project implements a **streaming CRC-32 generator** using the reflected representation of the standard CRC-32 polynomial.

Configuration:

```text
Polynomial       = 0x04C11DB7
Reflected        = 0xEDB88320
Initial value    = 0xFFFFFFFF
Final XOR        = 0xFFFFFFFF
Input            = 8-bit byte stream
```

The architecture is:

```text
       data_i[7:0]
            │
            ▼
   ┌─────────────────┐
   │  CRC-32 Update  │
   │  8 bit steps    │
   └────────┬────────┘
            │
         CRC state
            │
       last_i = 1
            │
            ▼
     Final XOR (~c)
            │
            ▼
      crc_o / valid_o
```

It is a **clocked, byte-streaming error-detection block**. It does not correct corrupted data; it generates a CRC that can later be checked by a receiver or storage system.

### Applications

* Ethernet/network packets
* ZIP/archive formats
* PNG/file integrity
* Embedded communication
* Packet/frame validation
* FPGA/ASIC streaming datapaths
* Storage and data-integrity systems

---

# 2. Circuit Working & RTL Implementation

### A. CRC initialization

The internal CRC register is initialized to:

```verilog
crc <= 32'hFFFF_FFFF;
```

when `rst_n=0`.

Therefore, a new message begins with:

```text
CRC = FFFFFFFF
```

---

### B. Byte processing

When `valid_i=1`, the current CRC and input byte are copied into temporary variables:

```verilog
c = crc;
d = data_i;
```

The byte is processed over eight iterations:

```verilog
for (i=0; i<8; i=i+1)
```

The central CRC operation is:

```verilog
if ((c[0] ^ d[0]) == 1'b1)
    c = (c >> 1) ^ 32'hEDB88320;
else
    c = (c >> 1);

d = d >> 1;
```

This is the **reflected/right-shifting implementation**.

The LSB of the CRC is XORed with the current LSB of the data byte. Depending on that result, the reflected polynomial is XORed after the CRC shift.

So one byte produces eight CRC update operations:

```text
Byte
 │
 ├─ bit 0 → CRC update
 ├─ bit 1 → CRC update
 ├─ bit 2 → CRC update
 ├─ ...
 └─ bit 7 → CRC update
          │
          ▼
      New CRC state
```

---

### C. Streaming behavior

After processing each valid byte:

```verilog
crc <= c;
```

Thus the next byte continues from the previous CRC state.

For:

```text
"123456789"
```

the calculation effectively becomes:

```text
Initial CRC
    ↓
process '1'
    ↓
process '2'
    ↓
process '3'
    ↓
...
process '9'
    ↓
final CRC
```

If `valid_i=0`, the CRC state remains unchanged.

---

### D. Final XOR

When `last_i=1`, the calculated CRC is finalized using:

```verilog
crc_o <= ~c;
```

This is equivalent to:

```text
Final CRC = c XOR FFFFFFFF
```

and:

```verilog
valid_o <= 1'b1;
```

indicates that `crc_o` is now valid.

---

### E. Automatic reseeding

After the final byte:

```verilog
crc <= 32'hFFFF_FFFF;
```

This automatically prepares the CRC engine for another independent message.

This is explicitly tested by your second test case.

---

# 3. Verification & Testbench

The testbench uses two known-answer CRC-32 tests.

## Test 1 — `"123456789"`

The standard message is:

```text
123456789
```

The expected result is:

```text
CBF43926
```

The TB sends the characters one at a time:

```text
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
```

and asserts:

```verilog
last_i = 1
```

only for the final byte.

The testbench then waits for:

```verilog
valid_o == 1
```

and checks:

```verilog
crc_o === 32'hCBF43926
```

---

## Test 2 — `"A"`

The second message is:

```text
A
```

with:

```verilog
last_i = 1'b1;
```

immediately.

The expected CRC is:

```text
D3D99E8B
```

This test is particularly useful because it verifies **automatic reseeding** after the first message.

The sequence is:

```text
"123456789"
      │
      ▼
  CBF43926
      │
 automatic reseed
      ▼
     "A"
      │
      ▼
  D3D99E8B
```

So the second message should not inherit the CRC state from the first message.

### Verification coverage

The TB checks:

* Reset behavior
* Valid byte streaming
* `last_i`
* Final CRC generation
* `valid_o`
* Standard CRC-32 test vector
* Single-byte message
* Automatic reseeding

This is a good progression from basic functional verification to state-isolation verification.

---

# 4. Advantages & Limitations

### Advantages

| Aspect                         | Description                                       |
| ------------------------------ | ------------------------------------------------- |
| **Streaming**                  | Processes one byte whenever `valid_i` is asserted |
| **Standard CRC-32**            | Uses the reflected CRC-32 polynomial              |
| **Simple interface**           | `valid_i`/`last_i` provide message framing        |
| **Automatic reseed**           | Supports consecutive independent messages         |
| **Low storage**                | Only 32 bits of CRC state                         |
| **Known-answer verification**  | Uses standard CRC test vectors                    |
| **Synthesizable architecture** | Suitable as a basic RTL CRC implementation        |

### Limitations

**1. One byte per clock**

The external interface processes only 8 bits per cycle.

A high-throughput implementation could process 32, 64, or more bits per cycle.

**2. Eight CRC operations per byte**

The loop:

```verilog
for (i=0; i<8; i=i+1)
```

is generally synthesized into combinational logic between clocked CRC registers.

Therefore, although it takes one clock externally, the combinational CRC network can become a timing bottleneck.

**3. No error correction**

CRC provides error detection rather than correction.

**4. No backpressure**

There is no `ready` signal. The source must provide valid bytes according to the module's one-byte-per-cycle capability.

**5. Temporary variables**

The use of:

```verilog
reg [31:0] c;
reg [7:0] d;
```

with blocking assignments inside the sequential block is functional as temporary calculation storage, but a cleaner RTL architecture could separate the CRC next-state calculation into combinational logic.

---

# 5. Interview Takeaways

### Key concept

> **This design implements a reflected CRC-32 streaming engine that processes one byte per clock, performs eight internal CRC bit updates, applies the final XOR on the last byte, and automatically reseeds for the next message.**

### Important interview questions

**Q: Why is `EDB88320` used?**

It is the reflected representation of the standard CRC-32 polynomial:

```text
Normal:    04C11DB7
Reflected: EDB88320
```

**Q: Why is the CRC initialized to `FFFFFFFF`?**

That is part of the selected CRC-32 convention and determines the initial CRC state.

**Q: Why is `~c` used at the end?**

The configured CRC uses a final XOR of:

```text
FFFFFFFF
```

so:

```text
~c = c XOR FFFFFFFF
```

**Q: Why is the second `"A"` test important?**

It verifies that:

```verilog
crc <= 32'hFFFF_FFFF;
```

after the first message actually prevents the second message from inheriting the previous CRC state.

**Q: What is the difference between this CRC block and the previous CRC-16/MODBUS block?**

The architecture is essentially the same, but the CRC parameters differ:

| Parameter            |     CRC-32 | CRC-16/MODBUS |
| -------------------- | ---------: | ------------: |
| Width                |    32 bits |       16 bits |
| Reflected polynomial | `EDB88320` |        `A001` |
| Initial value        | `FFFFFFFF` |        `FFFF` |
| Final XOR            | `FFFFFFFF` |        `0000` |
| `"123456789"` result | `CBF43926` |        `4B37` |

### One-line interview explanation

> **“I implemented a streaming CRC-32 RTL engine using reflected polynomial processing, byte-wise CRC updates, `valid/last` framing, final XOR, automatic reseeding, and self-checking verification with standard `123456789` and single-byte `A` test vectors.”**
