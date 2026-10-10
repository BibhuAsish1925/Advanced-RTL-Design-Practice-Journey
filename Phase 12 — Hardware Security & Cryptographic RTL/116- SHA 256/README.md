## 1. Circuit Overview & Applications

This design implements a **single-block SHA-256 compression core**.

The important scope limitation is that the module accepts **exactly one already-padded 512-bit block (64 bytes)**. The caller is responsible for SHA-256 padding and for handling messages requiring multiple blocks.

For the supplied testbench, the block represents:

```text
SHA-256("abc")
```

with the expected digest:

```text
ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
```

### Main architecture

```text
64 input bytes
      │
      ▼
 Message Schedule
   W[0] ... W[63]
      │
      ▼
  64 Compression
     Rounds
      │
      ▼
 Updated H[0..7]
      │
      ▼
 256-bit hash_out
```

### Applications

* Hardware cryptographic accelerators
* Secure boot
* Digital signatures
* Hash-based authentication
* HMAC/SHA hardware engines
* Blockchain/cryptographic datapaths

---

## 2. Circuit Working & RTL Implementation

### 1. Message loading

The input interface provides:

```systemverilog
data_in
data_valid
```

with one byte accepted per cycle.

The 64 bytes are packed into `W[0]`–`W[15]` in **big-endian order**.

For example, the `"abc"` padded beginning:

```text
61 62 63 80
```

becomes:

```text
W[0] = 32'h61626380
```

The FSM then moves through:

```text
IDLE → LOAD → EXPAND → ROUND → FINAL
```

---

### 2. Message schedule expansion

The first 16 words come directly from the input block.

The remaining words `W[16]` through `W[63]` are generated using the SHA-256 schedule equation:

```text
W[t] = W[t-16] + σ0(W[t-15]) + W[t-7] + σ1(W[t-2])
```

where the RTL implements the required rotate-right and shift operations through:

```systemverilog
s0_exp
s1_exp
```

The implementation expands **one word per clock cycle**.

Therefore:

```text
16 input words
      +
48 expansion cycles
      =
64-word schedule
```

---

### 3. Compression round

The design maintains the eight SHA-256 working variables:

```text
a b c d e f g h
```

For every round it calculates:

```systemverilog
S1
chv
temp1
S0
majv
temp2
```

The core update is:

```text
T1 = h + Σ1(e) + Ch(e,f,g) + K[t] + W[t]

T2 = Σ0(a) + Maj(a,b,c)
```

followed by:

```text
a = T1 + T2
b = a(previous)
c = b(previous)
d = c(previous)
e = d(previous) + T1
f = e(previous)
g = f(previous)
h = g(previous)
```

The RTL uses nonblocking assignments, so the old values of the working registers are correctly used within the clocked update.

The design performs:

> **One SHA-256 compression round per clock cycle.**

Hence the compression phase requires **64 cycles**.

---

### 4. Hash initialization and finalization

The SHA-256 initial constants are stored in:

```systemverilog
H_INIT
```

representing the standard eight 32-bit initial hash values.

After the final compression round, the working variables are added back into `Hcur`:

```text
Hcur[i] = Hcur[i] + working_variable[i]
```

and concatenated into:

```systemverilog
hash_out
```

When the result is available:

```systemverilog
hash_valid <= 1'b1;
```

So the interface provides a simple **valid pulse indicating digest completion**.

---

## 3. Verification & Testbench

The testbench uses a **known-answer test (KAT)** for SHA-256.

It manually constructs the padded 64-byte block for `"abc"`:

```text
61626380
00000000
...
00000000
00000018
```

The final `0x18` represents the 24-bit message length:

```text
"abc" = 3 bytes = 24 bits
```

### Verification flow

```text
Reset
  ↓
Feed 64 bytes
  ↓
Wait for hash_valid
  ↓
Compare hash_out
  ↓
PASS / FAIL
```

The expected digest is:

```text
BA7816BF8F01CFEA414140DE5DAE222
B00361A396177A9CB410FF61F20015AD
```

The testbench therefore verifies the **complete load → schedule → 64-round compression → final hash path** rather than testing individual functions independently.

### Good verification aspects

* ✅ Known SHA-256 test vector
* ✅ Correct pre-padded block
* ✅ Big-endian byte stream
* ✅ 64-byte input
* ✅ Waits for `hash_valid`
* ✅ Exact 256-bit digest comparison
* ✅ Reset behavior exercised

---

## 4. Advantages & Limitations

### Advantages

* ✅ Standard SHA-256 compression structure
* ✅ 512-bit block processing
* ✅ One byte/cycle input interface
* ✅ One compression round/cycle
* ✅ Explicit FSM architecture
* ✅ Message schedule stored in registers
* ✅ Standard SHA-256 constants
* ✅ 256-bit output
* ✅ `hash_valid` completion indication
* ✅ Good cryptographic RTL practice example

### Limitations

**1. Single-block only**

This is the biggest architectural limitation.

The module does **not** implement the complete streaming SHA-256 algorithm for arbitrary-length messages.

For messages longer than the single-block range, an external controller must:

1. Split the message into 512-bit blocks.
2. Perform SHA-256 padding.
3. Maintain the intermediate hash state between blocks.
4. Feed each block into the compression core.

---

**2. Caller performs padding**

The DUT expects already-padded data.

For example, the testbench itself constructs the padded `"abc"` block.

Therefore this is specifically a:

> **SHA-256 compression core, not a complete SHA-256 message-processing engine.**

---

**3. Large combinational round logic**

Each round calculates several 32-bit additions, rotations, XORs, and Boolean functions.

Since one round is performed per cycle, the round logic forms an important timing path.

---

**4. `K` is implemented as an array initialized in an `initial` block**

```systemverilog
reg [31:0] K [0:63];

initial begin
    ...
end
```

This is convenient for simulation and many FPGA flows, but an ASIC implementation would generally handle the constants using a more implementation-conscious structure such as constant logic, ROM, or synthesized constant storage depending on the architecture.

---

**5. Limited verification**

Only `"abc"` is tested.

A stronger SHA-256 verification environment should include standard known-answer vectors such as:

* Empty message
* `"abc"`
* 55-byte message
* 56-byte message
* 64-byte message
* Multi-block messages

The 55/56-byte boundary is especially important because it exercises the transition from one padded block to two blocks.

---

## 5. Interview Takeaways

This is a strong **cryptographic RTL project** because it demonstrates substantially more than a basic datapath.

Important concepts to be able to explain:

* **SHA-256 512-bit message blocks**
* **Message schedule**
* **64 compression rounds**
* **Working variables `a`–`h`**
* **Σ0 / Σ1 functions**
* **Ch and Maj functions**
* **Round constants**
* **Big-endian message representation**
* **Hash initialization/finalization**
* **FSM-based multi-cycle datapath**
* **Known-answer testing**

The most important architectural point is:

> **This module implements the SHA-256 compression function for one pre-padded 512-bit block; it does not implement message padding or multi-block chaining.**

### Current repo status

**SHA-256 Single-Block Compression Core — DONE**

This is a particularly good repository example alongside your **GF(2⁸) inverse** and **APB firewall**, because the three demonstrate different security-oriented RTL areas:

```text
GF(2⁸) Inverse
      ↓
Cryptographic finite-field arithmetic

SHA-256 Core
      ↓
Cryptographic hash datapath

APB Firewall
      ↓
Hardware security / access control
```

That gives the repository a clear **security-oriented RTL/ASIC flavor**, rather than being only a collection of generic Verilog exercises.
