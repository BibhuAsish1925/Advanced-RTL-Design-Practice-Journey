# 8-BIT PALINDROME NUMBER DETECTOR

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This design is an **8-bit combinational palindrome detector**. It checks whether the input bit pattern is identical to its bit-reversed pattern.

```text
num = 10100101
reverse = 10100101
          ↓
     is_palindrome = 1
```

The design creates a reversed version of `num` and compares it with the original input.

### Applications

* Digital pattern recognition
* Data validation
* Bit-order checking
* Communication/data-processing circuits
* RTL learning for loops, bit manipulation, and combinational comparison

**Important:** This implementation checks **bit-pattern symmetry**, not decimal-digit palindrome symmetry.

For example:

```text
8'b10011001 → 153
```

is considered a palindrome because its **bits** are symmetric.

---

# 2. CIRCUIT WORKING & RTL IMPLEMENTATION

The main data path is:

```text
                 ┌──────────────────┐
num[7:0] ───────>│ Bit Reversal     │
                 │ Logic            │
                 └────────┬─────────┘
                          │
                    reverse_num
                          │
             ┌────────────┴────────────┐
             │                         │
          original                 reversed
             │                         │
             └──────────┬──────────────┘
                        ▼
                    Comparator
                        │
                        ▼
                 is_palindrome
```

The key RTL is:

```verilog
reverse_num = 8'b0;
```

This clears the temporary reverse value before constructing it.

Then:

```verilog
for (int i = 7; i >= 0; i = i - 1)
    reverse_num = reverse_num | (num[i] << (7 - i));
```

The loop maps each input bit to its mirrored position.

The mapping is:

```text
num[7] → reverse_num[0]
num[6] → reverse_num[1]
num[5] → reverse_num[2]
num[4] → reverse_num[3]
num[3] → reverse_num[4]
num[2] → reverse_num[5]
num[1] → reverse_num[6]
num[0] → reverse_num[7]
```

Therefore:

```text
reverse_num = bit_reverse(num)
```

Finally:

```verilog
assign is_palindrome = (num == reverse_num);
```

produces:

```text
1 → symmetric bit pattern
0 → non-symmetric bit pattern
```

### Example

For:

```text
num = 10011001
```

the reversal is:

```text
reverse_num = 10011001
```

Therefore:

```text
is_palindrome = 1
```

For:

```text
num = 10011000
```

the reversal is:

```text
reverse_num = 00011001
```

Therefore:

```text
is_palindrome = 0
```

---

# 3. VERIFICATION & TESTBENCH

The testbench instantiates the DUT with an 8-bit input:

```verilog
reg [7:0] num;
wire is_palindrome;
```

It uses `$monitor` to continuously display:

```text
time
input decimal value
input binary pattern
palindrome result
```

### Test cases

The supplied TB covers several useful patterns:

| Test | Input      | Result         |
| ---- | ---------- | -------------- |
| 1    | `01011010` | Palindrome     |
| 2    | `11001010` | Not palindrome |
| 3    | `00001000` | Not palindrome |
| 4    | `11100111` | Palindrome     |
| 5    | `00000000` | Palindrome     |
| 6    | `11111111` | Palindrome     |
| 7    | `10000000` | Not palindrome |
| 8    | `00000001` | Not palindrome |
| 9    | `10011001` | Palindrome     |
| 10   | `10011000` | Not palindrome |
| 11   | `10101010` | Not palindrome |
| 12   | `01100110` | Palindrome     |

This gives good coverage of:

* Symmetric patterns
* Asymmetric patterns
* All-zero input
* All-one input
* Single-bit patterns
* Alternating patterns
* Near-palindromes

### Verification limitation

The TB is **observation-based**, not self-checking. It displays the result but does not explicitly compare the DUT output against an expected value.

A stronger TB could calculate:

```verilog
expected = (num == bit_reverse(num));
```

and generate automatic `PASS`/`FAIL` messages.

---

# 4. ADVANTAGES & LIMITATIONS

### Advantages

* Very simple combinational architecture.
* No clock or reset required.
* Parameter-independent 8-bit implementation.
* Uses straightforward bit manipulation.
* Fast conceptual operation because all bits can be processed combinationally.
* Easy to synthesize and simulate.

### Limitations

* The implementation is fixed at **8 bits**.
* The `for (int i...)` declaration uses a SystemVerilog-style loop variable, rather than strict Verilog-2001.
* The entire reversal/comparison is combinational.
* For larger widths, the amount of reversal/comparison wiring increases.
* It checks **bit-level symmetry**, not decimal-number palindrome properties.

---

# 5. INTERVIEW TAKEAWAYS

**Core concept:** Generate the bit-reversed version of an input and compare it with the original.

**Main operation:**

$$
is\_palindrome = (num == bit\_reverse(num))
$$

**Key RTL concepts:**

* Combinational `always`
* `for` loop
* Bit indexing
* Shift operation
* Bitwise OR
* Equality comparison
* Continuous assignment

**One-line interview explanation:**

> “This is an 8-bit combinational palindrome detector that reverses the input bit-by-bit and asserts the output when the reversed pattern matches the original.”
