## 1. Circuit Overview & Applications

This design implements a **simple sequential hardware watermark / proof-of-ownership detector**.

The circuit continuously shifts incoming trigger bits into a **64-bit shift register**. When the accumulated bit sequence exactly matches a predefined `MAGIC` pattern, the circuit:

* asserts `sig_valid` for one clock cycle
* outputs the predefined `SIGN` value through `sig_value`

### Basic operation

```text
Serial trigger bits
       │
       ▼
  64-bit Shift Register
       │
       ▼
 Compare with MAGIC
       │
   ┌───┴───┐
   │       │
 Match   No match
   │
   ▼
sig_valid = 1
sig_value = SIGN
```

### Possible applications

* RTL/IP watermarking
* Hardware intellectual-property identification
* Proof-of-ownership mechanisms
* Educational hardware-security experiments
* Detecting a proprietary trigger sequence

---

## 2. Circuit Working & RTL Implementation

The central storage element is:

```systemverilog id="5djvjq"
reg [63:0] sr;
```

Whenever `tr_we` is asserted:

```systemverilog id="a3e8k2"
sr <= {sr[62:0], tr_bit};
```

This shifts the existing contents left and inserts the new serial bit at the LSB.

The newly formed shift-register value is then compared against `MAGIC`:

```systemverilog id="n9m6a1"
if ({sr[62:0], tr_bit} == MAGIC) begin
    sig_value <= SIGN;
    sig_valid <= 1'b1;
end
```

Using `{sr[62:0], tr_bit}` rather than `sr` is important because the comparison must include the **newly received bit during the same clock cycle**.

### Trigger behavior

If the pattern matches:

```text
sig_valid = 1
sig_value = SIGN
```

Otherwise:

```text
sig_valid = 0
```

At the beginning of every active clock cycle:

```systemverilog id="j8a2si"
sig_valid <= 1'b0;
```

Therefore `sig_valid` naturally becomes a **one-cycle pulse** when a match occurs.

### Reset

The active-low asynchronous reset clears:

```text
sr        → 0
sig_valid → 0
sig_value → 0
```

So the watermark detector starts from a known state.

---

## 3. Verification & Testbench

The testbench overrides the default 64-bit parameters with an easy-to-check 8-bit pattern:

```text id="f3o5l2"
TEST_MAGIC = A5
```

Binary representation:

```text id="0k3s8v"
10100101
```

and:

```text id="6e6vba"
TEST_SIGN = CAFEBABE
```

This makes the basic functionality easy to verify while the DUT itself remains 64-bit.

### Test 1 — Wrong sequence

The testbench shifts in:

```text id="1v9k6p"
11111111
```

Expected:

```text id="e1r0v5"
sig_valid = 0
```

This verifies that an incorrect sequence does not trigger the watermark.

### Test 2 — Correct sequence

The testbench then shifts:

```text id="wq9s0e"
10100101
```

Expected:

```text id="2gr1sa"
sig_valid = 1
sig_value = CAFEBABE
```

This verifies the actual watermark detection.

### Test 3 — Pulse width

The following cycle is checked to ensure:

```text id="t1l7s3"
sig_valid = 0
```

Therefore the testbench verifies that the detection signal is only asserted for one cycle.

### Verification flow

```text id="x6m1p4"
Reset
  ↓
Wrong sequence
  ↓
No trigger
  ↓
Correct sequence
  ↓
sig_valid + signature
  ↓
Next cycle → sig_valid = 0
```

This is a compact but effective directed test for the implemented behavior.

---

## 4. Advantages & Limitations

### Advantages

* ✅ Very simple sequential architecture
* ✅ Parameterized `MAGIC` and `SIGN`
* ✅ Serial trigger interface
* ✅ One-cycle detection pulse
* ✅ Asynchronous reset
* ✅ Easy to synthesize
* ✅ Small hardware footprint
* ✅ Testbench verifies correct and incorrect sequences
* ✅ Useful hardware-security/IP-protection concept

### Limitations

**1. The implementation is actually 64-bit**

Although the testbench overrides `MAGIC` with an 8-bit value, the shift register remains:

```systemverilog
reg [63:0] sr;
```

So the production implementation still requires **64 trigger bits** before the full `MAGIC` comparison can succeed.

The 8-bit test works because the parameter is zero-extended:

```text
MAGIC = 64'h00000000000000A5
```

and the preceding 56 shifted bits must therefore be zero.

This is important when describing the design.

---

**2. The trigger is not a unique sequence detector**

The circuit compares the entire 64-bit shift register.

It does not implement a conventional pattern-matching FSM such as:

```text
IDLE → MATCH_1 → MATCH_2 → ... → DETECT
```

Instead, it continuously maintains a sliding 64-bit window.

---

**3. No protection against repeated triggering**

If the matching 64-bit pattern is shifted in again, the detector can trigger again.

There is no:

* lockout
* one-time trigger
* authentication counter
* retry limit

---

**4. No tamper or anti-brute-force mechanism**

Anyone who knows or discovers `MAGIC` can potentially reproduce the trigger sequence.

For a real security mechanism, the trigger value would need to be protected and the architecture would need additional security controls.

---

**5. Signature is fixed**

`SIGN` is simply a parameterized constant:

```systemverilog
parameter [63:0] SIGN
```

It is not cryptographically generated.

So this should be described as a **watermark/proof-of-ownership marker**, not as cryptographic authentication.

---

## 5. Interview Takeaways

This is a useful example for discussing **hardware IP protection and sequential pattern detection**.

Key concepts:

* **Serial pattern recognition**
* **Shift registers**
* **Parameterized RTL**
* **Sliding-window comparison**
* **One-cycle event generation**
* **Asynchronous reset**
* **Hardware watermarking**
* **IP/provenance identification**

The most important implementation detail to explain in an interview is:

> The comparison uses `{sr[62:0], tr_bit}` so the current input bit is included immediately, allowing the watermark to be detected on the same clock edge that receives the final trigger bit.

### Current repo status

**Hardware Watermark / IP Protection Detector — DONE**

This is a good security-oriented addition to the repository, especially alongside your:

```text
GF(2⁸) Inverse       → Cryptographic arithmetic
SHA-256 Core         → Cryptographic hashing
APB Firewall         → Access control
Key Zeroization      → Secret protection
Hardware Watermark   → IP protection
```

That gives the security section of the repository a fairly coherent progression from **cryptographic primitives → security controls → hardware IP protection**.
