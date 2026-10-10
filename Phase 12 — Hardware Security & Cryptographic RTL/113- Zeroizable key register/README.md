## 1. Circuit Overview & Applications

This design implements a **parameterized key storage register with secure zeroization and parity-based integrity checking**.

### Main functions

* Stores a cryptographic key of configurable width `W`.
* Supports normal key loading through `load`.
* Clears the stored key through:

  * **Active-low reset** `rst_n`
  * **Asynchronous tamper signal** `tamper`
  * **Synchronous software zeroization** `soft_zeroize`
* Generates `parity_ok` to indicate whether the stored key contains an **even number of 1s**.

### Typical applications

* Secure key registers in cryptographic accelerators
* Hardware security modules
* Secure boot/key-management blocks
* Tamper-resistant embedded systems
* Security-sensitive SoCs

---

## 2. Circuit Working & RTL Implementation

The key storage is implemented using:

```systemverilog
always_ff @(posedge clk or negedge rst_n or posedge async_zeroize)
```

This gives the register three event-driven clearing mechanisms:

| Condition                           | Action        | Type         |
| ----------------------------------- | ------------- | ------------ |
| `rst_n = 0`                         | Clear key     | Asynchronous |
| `tamper = 1`                        | Clear key     | Asynchronous |
| `soft_zeroize = 1` at `posedge clk` | Clear key     | Synchronous  |
| `load = 1` at `posedge clk`         | Load `key_in` | Synchronous  |
| Otherwise                           | Retain key    | —            |

The priority is:

**Reset → Tamper → Software zeroize → Load**

So even if `load` is asserted simultaneously with a zeroization request, the key is cleared rather than loaded.

### Parameterization

```systemverilog
parameter int W = 128
```

allows the same RTL to implement different key widths, provided the parity-generation condition is satisfied.

For the default `W = 128`:

* 128-bit key
* 16 × 8-bit lanes
* One parity bit generated per lane
* Final parity is obtained by XORing all lane parities

The parity logic effectively determines whether the **total number of 1s in `key_out` is even**.

genui{"learning_viz":{"type_id":"TRIG_IDENTITY_PYTHAGOREAN"}}

The visualization above is not directly related to the RTL; for this design, the important integrity concept is simply the XOR-reduction parity calculation rather than a mathematical identity.

---

## 3. Verification & Testbench

The testbench performs **8 directed tests**:

1. **Reset**

   * Verifies that `key_out` becomes zero.

2. **Load Key**

   * Loads:
     `0123_4567_89AB_CDEF_1122_3344_5566_7788`
   * Checks that the key is stored correctly.

3. **Key Retention**

   * Removes `load`.
   * Confirms that the key remains unchanged.

4. **Software Zeroization**

   * Asserts `soft_zeroize`.
   * Checks that the key is synchronously cleared.

5. **Reload Key**

   * Loads a second test key.

6. **Asynchronous Tamper Zeroization**

   * Asserts `tamper` without waiting for a clock edge.
   * Confirms that `key_out` becomes zero immediately.

7. **Reload After Tamper**

   * Verifies that a new key can be loaded after tamper is released.

8. **Final Reset**

   * Asserts `rst_n = 0`.
   * Confirms final key clearance.

The testbench uses `$error` for failures and `$display` for successful checks, making it straightforward to inspect in Vivado simulation or another SystemVerilog simulator.

### Important observation

Although the DUT generates:

```systemverilog
output logic parity_ok
```

the current testbench **does not actually verify `parity_ok`**.

So parity generation exists in the RTL, but parity functionality is currently **unverified by the testbench**.

A useful addition would be tests for:

* Even number of `1`s → `parity_ok = 1`
* Odd number of `1`s → `parity_ok = 0`
* Zero key → `parity_ok = 1`

---

## 4. Advantages & Limitations

### Advantages

* ✅ Parameterized key width
* ✅ Dedicated asynchronous tamper zeroization
* ✅ Synchronous firmware zeroization
* ✅ Reset-based key clearing
* ✅ Simple key-loading interface
* ✅ Parity-based integrity indication
* ✅ Directed verification covers the major zeroization paths
* ✅ Synthesizable RTL structure

### Limitations / Interview-level observations

**1. Multiple asynchronous controls**

```systemverilog
posedge async_zeroize
negedge rst_n
```

in the same sequential block is security-oriented but implementation-sensitive. Real ASIC flows require careful consideration of the target library's available sequential-cell structures and reset/clear implementation.

**2. `tamper` is assumed asynchronous**

The comment correctly identifies it as asynchronous. In a real SoC, the tamper path would need dedicated security architecture rather than treating it like an ordinary functional input.

**3. Parity is detection, not correction**

`parity_ok` can indicate an odd/even parity mismatch, but it cannot identify or correct the corrupted bit.

**4. Parity is combinational**

`parity_ok` changes whenever `key_out` changes. It is not itself registered.

**5. Non-byte-aligned widths**

For:

```systemverilog
W % 8 != 0
```

the design deliberately sets:

```systemverilog
parity_ok = 1'b0;
```

So parity checking is only implemented for widths divisible by 8.

---

## 5. Interview Takeaways

This is a good **security-oriented RTL practice example** because it combines several concepts in one small design:

* **Parameterized RTL**
* **Sequential storage**
* **Asynchronous reset**
* **Asynchronous security/tamper response**
* **Synchronous control**
* **Priority of security controls**
* **Generate blocks**
* **Part-select with `+:`**
* **Reduction XOR**
* **Directed testbench verification**

The most important interview point is the **zeroization priority**:

> A tamper or reset event must take precedence over normal key loading so that a security event cannot leave the secret key stored.

### Current repo status

**Key Register + Secure Zeroization + Parity — DONE**

The only meaningful verification gap is that **`parity_ok` should be explicitly tested**.
