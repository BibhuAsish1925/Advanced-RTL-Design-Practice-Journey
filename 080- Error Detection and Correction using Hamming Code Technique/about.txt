## 1. Circuit Overview & Applications

This project implements a **(7,4) Hamming Error-Correcting Code (ECC)** consisting of:

* **Hamming encoder:** 4-bit data → 7-bit codeword
* **Hamming decoder:** 7-bit received word → 4-bit corrected data
* **Single-bit error detection and correction**

The 7-bit codeword contains:

```text
Position:   1  2  3  4  5  6  7
            P1 P2 D1 P3 D2 D3 D4
```

For the encoder's output vector `[6:0]`, this corresponds to:

```text
ham_data_encoder = {D4,D3,D2,D1,P3,D2? ...}
```

More precisely from the RTL:

```text
Bit index:       6   5   4   3   2   1   0
Position:        7   6   5   4   3   2   1
Content:         D4  D3  D2  P3  D1  P2  P1
```

The parity equations are:

$$
P_1=D_1\oplus D_2\oplus D_4
$$

$$
P_2=D_1\oplus D_3\oplus D_4
$$

$$
P_3=D_2\oplus D_3\oplus D_4
$$

### Applications

* ECC memories
* SRAM/DRAM error correction
* Communication systems
* Data storage
* Noisy digital links
* Reliable embedded systems
* Safety/reliability-oriented digital hardware

---

# 2. Circuit Working & RTL Implementation

## A. Hamming Encoder

The encoder is completely **combinational**.

There is no clock, reset, or state.

The input is:

```verilog
input [3:0] data
```

and the output is:

```verilog
output [6:0] ham_data_encoder
```

The parity bits are generated using XOR networks:

```verilog
assign ham_data_encoder[0] = data[0]^data[1]^data[3];
assign ham_data_encoder[1] = data[0]^data[2]^data[3];
assign ham_data_encoder[3] = data[1]^data[2]^data[3];
```

The remaining locations carry the original data:

```verilog
assign ham_data_encoder[2] = data[0];
assign ham_data_encoder[4] = data[1];
assign ham_data_encoder[5] = data[2];
assign ham_data_encoder[6] = data[3];
```

So the resulting codeword is:

```text
Position:       7   6   5   4   3   2   1
                D4  D3  D2  P3  D1  P2  P1
```

---

## B. Hamming Decoder

The decoder calculates three **syndrome bits**:

```verilog
assign c1 = ham_data_encoder[0] ^
            ham_data_encoder[2] ^
            ham_data_encoder[4] ^
            ham_data_encoder[6];

assign c2 = ham_data_encoder[1] ^
            ham_data_encoder[2] ^
            ham_data_encoder[5] ^
            ham_data_encoder[6];

assign c3 = ham_data_encoder[3] ^
            ham_data_encoder[4] ^
            ham_data_encoder[5] ^
            ham_data_encoder[6];
```

The syndrome is:

```verilog
assign error_position = {c3,c2,c1};
```

Therefore:

```text
c3 c2 c1 = 000 → no error
c3 c2 c1 = 001 → bit 1 error
c3 c2 c1 = 010 → bit 2 error
c3 c2 c1 = 011 → bit 3 error
c3 c2 c1 = 100 → bit 4 error
c3 c2 c1 = 101 → bit 5 error
c3 c2 c1 = 110 → bit 6 error
c3 c2 c1 = 111 → bit 7 error
```

`is_error` is generated as:

```verilog
assign is_error = c3 | c2 | c1;
```

So any non-zero syndrome indicates an error.

---

## C. Error Correction

An important feature of your decoder is that it does not merely detect the error — it **corrects the erroneous bit**.

```verilog
assign corrected =
    ham_data_encoder ^
    (is_error ?
        (7'b1 << (error_position - 1)) :
        7'b0);
```

For example, if:

```text
error_position = 3
```

then:

```text
7'b1 << 2
```

produces:

```text
0000100
```

XORing this with the received codeword flips bit position 3.

After correction, the data bits are extracted:

```verilog
assign data[0] = corrected[2];
assign data[1] = corrected[4];
assign data[2] = corrected[5];
assign data[3] = corrected[6];
```

Therefore the complete decoder flow is:

```text
Received 7-bit word
        │
        ▼
   Syndrome Logic
        │
        ▼
 Error Position
        │
        ▼
 Single-bit Correction
        │
        ▼
 Extract 4 Data Bits
```

---

# 3. Verification & Testbench

## Encoder TB

The encoder testbench performs an **exhaustive test**.

Since there are only four input bits:

$$
2^4=16
$$

possible inputs exist.

The TB contains the expected codeword for every input:

```verilog
expected[0]  = 7'b0000000;
expected[1]  = 7'b0000111;
...
expected[15] = 7'b1111111;
```

Then:

```verilog
for (i = 0; i < 16; i = i + 1)
```

tests every possible input.

This is stronger than random testing for a 4-bit encoder because **100% of the input space is covered**.

---

## Decoder TB

The decoder TB starts with the valid codeword:

```text
0110011
```

corresponding to:

```text
data = 0110
```

It then tests:

### No error

```text
0110011
```

Expected:

```text
is_error     = 0
error_pos    = 0
data         = 0110
```

### Single-bit errors

Each of the seven positions is flipped individually:

```text
Position 1 → 0110010
Position 2 → 0110001
Position 3 → 0110111
Position 4 → 0111011
Position 5 → 0100011
Position 6 → 0010011
Position 7 → 1110011
```

The TB verifies both:

1. Correct error position
2. Corrected data remains `0110`

Therefore it verifies the complete **SEC operation**:

> **Single Error Correction**

The decoder TB has eight cases total:

```text
1 no-error case
7 single-bit error cases
```

---

# 4. Advantages & Limitations

### Advantages

| Feature                   | Description                                          |
| ------------------------- | ---------------------------------------------------- |
| **Combinational**         | No clock or sequential state                         |
| **Low complexity**        | Only XOR-based parity/syndrome logic                 |
| **Exhaustive encoder TB** | All 16 possible data values tested                   |
| **Single-bit correction** | Decoder identifies and corrects one bit              |
| **Error location**        | Provides 1–7 bit error position                      |
| **Parameterized concept** | Architecture can be extended to larger Hamming codes |
| **Hardware efficient**    | Suitable for relatively small ECC blocks             |

### Limitations

**1. Cannot reliably correct two-bit errors**

Standard `(7,4)` Hamming code provides **single-error correction**.

With two corrupted bits, the syndrome can correspond to another bit position, potentially causing an incorrect correction.

For **SECDED** capability, an additional overall parity bit is normally added, producing an extended Hamming code.

**2. No explicit double-error detection**

Your interface only has:

```verilog
is_error
error_position
data
```

There is no separate indication such as:

```text
single_error
double_error
```

So the decoder cannot distinguish a valid single-bit error from more complicated corruption.

**3. Combinational delay**

The decoder has:

```text
XOR syndrome logic
       ↓
position decode
       ↓
bit correction
       ↓
data extraction
```

For larger ECC widths, this combinational path can become significant.

**4. `error_position` is zero when there is no error**

This is consistent with your testbench:

```text
no error → position = 0
```

while actual Hamming positions are 1–7.

---

# 5. Interview Takeaways

### Key concept

> **A (7,4) Hamming ECC adds three parity bits to four data bits, allowing the decoder to calculate a three-bit syndrome that identifies and corrects any single-bit error.**

### Important interview questions

**Q: Why are there three parity bits?**

Because three syndrome bits provide:

$$
2^3=8
$$

possible values:

```text
000 → no error
001–111 → seven possible error locations
```

**Q: What does the syndrome represent?**

The binary value of the syndrome identifies the **1-indexed position of the erroneous bit**.

**Q: How does correction happen?**

The decoder creates a one-hot mask from `error_position` and XORs it with the received codeword, flipping the erroneous bit.

**Q: What happens with no error?**

The syndrome is:

```text
000
```

so `is_error=0` and the correction mask is zero.

**Q: Can this correct two-bit errors?**

No. Standard `(7,4)` Hamming provides single-error correction. Two-bit error handling requires additional coding, such as **SECDED** with an overall parity bit.

### One-line interview explanation

> **“I implemented a combinational (7,4) Hamming ECC encoder/decoder with XOR-based parity generation, syndrome-based single-bit error localization and correction, and exhaustive verification of all encoder inputs plus every single-bit error position.”**
