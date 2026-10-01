## ROM Using `case` — Circuit Analysis

### 1. Circuit Overview & Applications

This design implements an **8-word × 4-field ROM**, where:

* **Address:** 3 bits → 8 possible locations (`000`–`111`)
* **Chip Enable (`ce`):** Enables the ROM
* **Read Enable (`read_en`):** Enables reading
* **Outputs:** Four separate 1-bit fields: `F1`, `F2`, `F3`, `F4`
* **Read type:** Asynchronous/combinational
* **Storage implementation:** `case` statement rather than an explicit memory array

The ROM effectively stores **4-bit words**, although each field is declared as an 8-bit `reg`. Since the assigned values are only `0` or `1`, only the LSB of each output is actually used.

Typical applications include **lookup tables, control-code ROMs, instruction decoding, configuration tables, and fixed-function control logic**.

---

### 2. Circuit Working & RTL Implementation

The basic operation is:

```text
              address[2:0]
                   │
                   ▼
            ┌─────────────┐
ce ────────►│             │
read_en ──►│  CASE ROM   │
            │             │
            └──────┬──────┘
                   │
        ┌──────────┼──────────┬──────────┐
        ▼          ▼          ▼          ▼
       F1         F2         F3         F4
```

The condition:

```verilog
if (ce && read_en)
```

means the ROM produces its stored value only when **both enables are HIGH**.

When enabled, `address` selects one of eight predefined entries.

| Address | F1 | F2 | F3 | F4 |
| ------- | -: | -: | -: | -: |
| `000`   |  0 |  1 |  0 |  0 |
| `001`   |  0 |  1 |  1 |  0 |
| `010`   |  1 |  0 |  0 |  0 |
| `011`   |  1 |  1 |  0 |  1 |
| `100`   |  0 |  0 |  1 |  0 |
| `101`   |  0 |  0 |  0 |  1 |
| `110`   |  1 |  1 |  0 |  1 |
| `111`   |  1 |  0 |  1 |  1 |

For example:

```text
address = 011
```

produces:

```text
F1 = 1
F2 = 1
F3 = 0
F4 = 1
```

If either `ce` or `read_en` is LOW, all outputs become zero:

```verilog
else begin
    data_F1=0;
    data_F2=0;
    data_F3=0;
    data_F4=0;
end
```

There is **no clock**, so this is an **asynchronous/combinational ROM model**.

### Important RTL observations

The sensitivity list:

```verilog
always @(ce,read_en,address)
```

contains all signals read by the combinational block, so the outputs update whenever any of them changes.

The declaration:

```verilog
reg [7:0] data;
```

is unused and can be removed.

Also, the four outputs could logically be only **1 bit wide**, because the ROM stores only `0/1` values:

```verilog
output reg data_F1,
output reg data_F2,
output reg data_F3,
output reg data_F4
```

However, with the current code, each output is 8 bits and receives `0` or `1`.

---

### 3. Verification & Testbench

The testbench performs a **directed address sweep**.

Initially:

```verilog
r_en = 0;
chip_en = 0;
addr = 3'bx;
```

Therefore, the ROM outputs all zero.

After 20 ns:

```verilog
r_en = 1;
addr = 3'b000;
chip_en = 1;
```

The testbench then sequentially applies:

```text
000 → 001 → 010 → 011
    → 100 → 101 → 110 → 111
```

The `$monitor` continuously displays:

```text
chip_en
r_en
address
F1
F2
F3
F4
```

So it verifies that every ROM address produces the corresponding stored pattern.

The testbench is **observational**, not self-checking: it displays the outputs but does not automatically compare them against expected values.

A stronger verification approach would use:

```verilog
if (data_F1 !== expected_F1)
    $display("FAIL");
```

for every address.

---

### 4. Advantages & Limitations

**Advantages**

* Very simple RTL structure.
* Easy to understand and modify.
* Combinational/asynchronous read.
* `case` statement makes ROM contents explicit.
* `ce` and `read_en` provide two levels of read control.

**Limitations**

* The ROM contents are hard-coded in the `case`.
* It does not use a conventional memory array.
* Outputs are unnecessarily 8 bits for 1-bit stored values.
* `data` is unused.
* No `default` case is present. For a 3-bit address all eight binary values are covered, but a `default` is still good defensive RTL style.
* Large ROMs implemented with a huge `case` can become inefficient compared with dedicated ROM/block-memory structures.
* The testbench does not automatically detect incorrect output values.

---

### 5. Interview Takeaways

**What is this circuit?**
An **8-entry asynchronous ROM implemented using a Verilog `case` statement**, with chip-enable and read-enable controls.

**Why is it asynchronous?**
There is no clock; output depends directly on `ce`, `read_en`, and `address`.

**What happens when `ce = 0`?**
All four outputs are forced to `0`.

**What happens when `ce = 1` and `read_en = 1`?**
The address selects one of the eight predefined output patterns.

**Why use a `case` statement?**
It is a straightforward way to describe a small fixed lookup table/ROM in RTL.

**One-line interview explanation:**

> “This is an 8×4 asynchronous ROM modeled using a combinational `case` statement, with chip-enable and read-enable controls and four 8-bit output fields carrying predefined lookup values.”
