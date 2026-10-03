## 1. Circuit Overview & Applications

This project implements a **streaming CRC-16/MODBUS generator**.

It processes an 8-bit data stream one byte at a time and maintains a 16-bit CRC state.

The configured parameters are:

```text
Polynomial       = 0x8005
Reflected        = 0xA001
Initial value    = 0xFFFF
Final XOR        = None
```

The basic flow is:

```text
       data_i[7:0]
            │
            ▼
     ┌─────────────┐
     │ CRC-16 LFSR │
     │ 8 bit/byte  │
     └──────┬──────┘
            │
       last_i = 1
            │
            ▼
         crc_o
            │
         valid_o
```

The design is **combinationally unrolled for 8 bit-processing iterations inside each clocked byte update**, so one valid byte is consumed per clock.

### Applications

* MODBUS/RTU communication
* Industrial communication links
* Serial protocols
* Embedded controllers
* Data integrity checking
* Packet/frame validation
* FPGA/ASIC communication interfaces

---

# 2. Circuit Working & RTL Implementation

### A. CRC initialization

The CRC register is initialized on active-low reset:

```verilog
if (!rst_n) begin
    crc <= 16'hFFFF;
```

So each new message starts with:

```text
CRC = FFFF
```

---

### B. Byte-wise CRC calculation

When:

```verilog
valid_i == 1
```

the current CRC and input byte are copied into temporary variables:

```verilog
c = crc;
d = data_i;
```

The byte is then processed eight times:

```verilog
for (i=0;i<8;i=i+1)
```

The core operation is:

```verilog
if ((c[0] ^ d[0]) == 1'b1)
    c = (c >> 1) ^ 16'hA001;
else
    c = (c >> 1);

d = d >> 1;
```

This is the **reflected/right-shifting CRC implementation**.

The least-significant bit of the CRC is combined with the current data bit. If the result is `1`, the reflected polynomial `16'hA001` is XORed into the shifted CRC.

Conceptually:

```text
CRC state + input bit
        │
        ▼
   XOR decision
      /    \
     /      \
shift      shift + polynomial
     \      /
      \    /
        ▼
   next CRC state
```

Eight such operations process one complete input byte.

---

### C. Streaming state update

After the byte has been processed:

```verilog
crc <= c;
```

Therefore, consecutive valid bytes form a continuous CRC calculation:

```text
Byte 0 → CRC state 1
Byte 1 → CRC state 2
Byte 2 → CRC state 3
...
Byte N → final CRC
```

If `valid_i=0`, the CRC state remains unchanged.

---

### D. Final-byte handling

When the current byte is marked:

```verilog
last_i = 1
```

the module outputs:

```verilog
crc_o   <= c;
valid_o <= 1'b1;
```

There is **no final XOR/inversion**, consistent with the implementation comment.

After completing the message, it automatically reseeds:

```verilog
crc <= 16'hFFFF;
```

This allows the next message to start independently without requiring another reset.

---

### E. Control behavior

| Signal    | Function                       |
| --------- | ------------------------------ |
| `valid_i` | Input byte is valid            |
| `data_i`  | 8-bit input data               |
| `last_i`  | Current byte is the final byte |
| `valid_o` | Final CRC is valid             |
| `crc_o`   | Calculated 16-bit CRC          |
| `rst_n`   | Active-low asynchronous reset  |

The interface therefore behaves like:

```text
valid_i + data_i
       │
       ▼
 CRC calculation
       │
 last_i
       ▼
valid_o + crc_o
```

---

# 3. Verification & Testbench

The testbench uses the standard CRC-16/MODBUS check string:

```text
"123456789"
```

The expected CRC is:

```text
4B37
```

The nine ASCII bytes are sent sequentially:

```text
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
```

with:

```verilog
last_i = (i == 8);
```

Therefore, only the final byte (`9`) causes the CRC to be presented as valid output.

### Verification sequence

```text
Reset
  ↓
CRC = FFFF
  ↓
Send "123456789"
  ↓
Process 9 bytes
  ↓
last_i = 1
  ↓
crc_o = 4B37
valid_o = 1
  ↓
PASS/FAIL
```

The TB checks:

```verilog
if (crc_o !== 16'h4B37)
```

and prints either PASS or FAIL.

### Testbench strengths

* Uses a recognized CRC check vector
* Tests continuous multi-byte streaming
* Tests `valid_i`
* Tests `last_i`
* Tests `valid_o`
* Checks the final CRC automatically
* Uses clock-synchronized stimulus
* Tests the complete message rather than isolated bytes

---

# 4. Advantages & Limitations

### Advantages

| Aspect                       | Description                                             |
| ---------------------------- | ------------------------------------------------------- |
| **Streaming architecture**   | Processes one byte whenever `valid_i` is asserted       |
| **Simple interface**         | Valid/last framing makes message boundaries explicit    |
| **Low state storage**        | Only a 16-bit CRC state is required                     |
| **Reflected implementation** | Matches the MODBUS CRC calculation convention used here |
| **Automatic reseed**         | Ready for another message after completion              |
| **Self-checking TB**         | Uses known `123456789 → 4B37` result                    |
| **Synthesizable structure**  | Suitable as a basic RTL CRC implementation              |

### Limitations

**1. CRC does not correct errors**

CRC detects data corruption but does not identify and repair the original corrupted data.

**2. One byte per clock**

Although eight bit operations are performed internally, the external interface accepts only one byte per clock.

Higher-throughput implementations can process:

* Multiple bytes per cycle
* Wider input words
* Parallel CRC update logic
* Table/LUT-based CRC calculations

**3. Combinational CRC logic can become larger**

The eight iterations inside the clocked block are generally synthesized into combinational logic between registers.

Increasing the CRC width or processing more bytes per cycle increases the combinational complexity.

**4. Protocol parameters matter**

CRC implementations must match the exact convention for:

* Polynomial
* Reflection
* Initial value
* Final XOR
* Input/output bit ordering

A mismatch in any of these can produce a different CRC even when the polynomial itself is correct.

**5. No backpressure**

There is no `ready` input. Whenever `valid_i=1`, the module accepts the byte.

---

# 5. Interview Takeaways

### Key concept

> **This is a reflected CRC-16/MODBUS streaming engine that updates a 16-bit CRC state for every valid input byte and produces the final CRC when `last_i` is asserted.**

### Important interview questions

**Q: Why is `16'hA001` used?**

It is the **reflected representation** of the CRC polynomial used by this implementation.

**Q: Why does the loop execute eight times?**

Because `data_i` is one byte:

$$
8\text{ bits} = 8\text{ CRC update iterations}
$$

**Q: What does `last_i` indicate?**

It marks the final byte of the current message, causing the calculated CRC to be transferred to `crc_o` and `valid_o` to pulse.

**Q: Why does the module reset `crc` to `16'hFFFF` after the last byte?**

The design automatically reseeds itself so that the next independent message can be processed without another reset.

**Q: What is the expected CRC for `"123456789"`?**

For the configured CRC-16/MODBUS implementation:

```text
4B37
```

**Q: How would you increase throughput?**

Use a wider datapath, such as 16/32/64-bit input processing, with a parallel CRC transformation that computes the corresponding next CRC in one cycle.

### One-line interview explanation

> **“I implemented a streaming CRC-16/MODBUS RTL engine using reflected polynomial processing, byte-wise CRC updates, `valid/last` message framing, automatic reseeding, and self-checking verification against the standard `123456789 → 0x4B37` test vector.”**
