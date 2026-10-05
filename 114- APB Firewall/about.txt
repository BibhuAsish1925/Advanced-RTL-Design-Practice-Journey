## 1. Circuit Overview & Applications

This design implements an **APB security firewall** that sits between an APB master and a protected downstream APB slave.

Its main purpose is **address-based access control**:

* Addresses inside the permitted range are forwarded to the downstream slave.
* Addresses outside the permitted range are blocked.
* Blocked transactions complete immediately with `PREADY = 1`.
* Blocked transactions return `PSLVERR = 1`.
* Blocked reads return `32'hDEAD_DEAD`.

### Default protected region

```text
ALLOW_BASE = 0x4000_0000
ALLOW_END  = 0x4000_FFFF
```

Therefore:

```text
0x4000_0000 ─────────────── 0x4000_FFFF
       Allowed APB address region
```

### Typical applications

* Secure peripheral access
* APB peripheral protection
* TrustZone/security-domain boundaries
* Access-control wrappers
* Safety/security monitoring blocks
* SoC peripheral firewalls

---

## 2. Circuit Working & RTL Implementation

### Address permission check

The core security decision is:

```systemverilog
assign addr_allowed =
    (PADDR >= ALLOW_BASE) &&
    (PADDR <= ALLOW_END);
```

So the range is **inclusive** at both boundaries.

For the configured range:

| Address       | Result    |
| ------------- | --------- |
| `0x3FFF_FFFC` | ❌ Blocked |
| `0x4000_0000` | ✅ Allowed |
| `0x4000_0010` | ✅ Allowed |
| `0x4000_FFFF` | ✅ Allowed |
| `0x5000_0000` | ❌ Blocked |

### Downstream forwarding

For an allowed address:

```systemverilog
assign M_PSEL    = PSEL && addr_allowed;
assign M_PENABLE = PENABLE && addr_allowed;
```

Therefore the protected slave sees the APB transaction only when the address is authorized.

The address and write data are passed through:

```systemverilog
assign M_PADDR  = PADDR;
assign M_PWDATA = PWDATA;
```

`M_PWRITE` is also passed directly from the master.

### Response behavior

For an allowed transaction:

```systemverilog
assign PREADY = M_PREADY;
assign PRDATA = M_PRDATA;
```

For a blocked transaction:

```systemverilog
PREADY  = 1
PRDATA  = DEAD_DEAD
PSLVERR = 1
```

This means the firewall **terminates unauthorized accesses locally** instead of sending them to the protected peripheral.

---

## 3. Verification & Testbench

The testbench contains **7 functional tests**.

### Test 1 — Allowed WRITE

Address:

```text
0x4000_0010
```

Checks that:

* `M_PSEL = 1`
* `M_PENABLE = 1`
* Address is forwarded
* Write data is forwarded
* No firewall error
* `PREADY = 1`

✅ Verifies normal write forwarding.

### Test 2 — Allowed READ

Address:

```text
0x4000_0020
```

Downstream returns:

```text
0xCAFE_BABE
```

The testbench verifies that the same data reaches `PRDATA`.

✅ Verifies read-data forwarding.

### Test 3 — Lower Boundary

Address:

```text
0x4000_0000
```

This is exactly `ALLOW_BASE`.

✅ Verifies the lower boundary is permitted.

### Test 4 — Upper Boundary

Address:

```text
0x4000_FFFF
```

This is exactly `ALLOW_END`.

✅ Verifies the upper boundary is permitted.

### Test 5 — Below Allowed Range

Address:

```text
0x3FFF_FFFC
```

Expected:

```text
M_PSEL   = 0
PREADY   = 1
PSLVERR  = 1
PRDATA   = DEAD_DEAD
```

✅ Verifies unauthorized access is blocked.

### Test 6 — Above Allowed Range

Address:

```text
0x5000_0000
```

Again, the transaction must not reach the downstream slave.

✅ Verifies upper-side access protection.

### Test 7 — Downstream Slave Error

The downstream slave generates:

```text
M_PSLVERR = 1
```

The current RTL does **not** propagate that error:

```systemverilog
assign PSLVERR = PRESETn &&
                 PSEL &&
                 PENABLE &&
                 !addr_allowed;
```

Therefore the testbench explicitly documents that the firewall itself does not generate an error for this case.

This is an important design limitation rather than a verification failure.

---

## 4. Advantages & Limitations

### Advantages

* ✅ Parameterized address protection range
* ✅ Simple combinational access-control logic
* ✅ Unauthorized transactions never reach the protected slave
* ✅ Immediate error response for blocked accesses
* ✅ Inclusive lower/upper boundary handling
* ✅ Both read and write accesses are protected
* ✅ Downstream `PRDATA`/`PREADY` are passed through for allowed accesses
* ✅ Straightforward directed testbench
* ✅ Good security-oriented RTL practice example

### Limitations / Important observations

**1. Downstream `PSLVERR` is not propagated**

Currently:

```systemverilog
PSLVERR = blocked_transaction;
```

rather than:

```text
firewall error OR downstream slave error
```

So if an authorized downstream peripheral reports an error, the APB master will not see it.

A more complete firewall would typically use logic equivalent to:

```text
PSLVERR = blocked_access OR M_PSLVERR
```

with appropriate transaction qualification.

---

**2. No protection based on `PWRITE`**

The firewall only checks the address.

Therefore an allowed address can perform both:

```text
READ  → allowed
WRITE → allowed
```

If the security policy requires **read-only or write-only regions**, additional access-control logic is needed.

---

**3. No master identity/security attribute**

The firewall cannot distinguish between different APB masters because the interface contains no requester/security attribute.

It implements:

> **Address-based authorization only.**

---

**4. Combinational security decision**

`addr_allowed` and the downstream signals are purely combinational. This makes the block simple and low-latency, but timing and glitch behavior should be considered in a production security architecture.

---

**5. Testbench is directed**

The testbench has good boundary and blocked-access coverage, but it does not currently include:

* Randomized address testing
* Assertions
* Functional coverage
* Multiple allowed windows
* Read/write permission policies
* Back-pressure testing with `M_PREADY = 0`
* Explicit verification of downstream `M_PSLVERR` propagation

---

## 5. Interview Takeaways

This is a strong small RTL example for discussing **hardware security + AMBA APB**.

Key concepts to remember:

* **Address-range access control**
* **APB SETUP/ACCESS forwarding**
* **Peripheral isolation**
* **Unauthorized transaction termination**
* **Inclusive address boundaries**
* **Downstream response forwarding**
* **Security policy vs protocol behavior**

The most important architectural concept is:

> **The firewall prevents an unauthorized APB transaction from reaching the protected peripheral and generates an immediate APB error response instead.**

### Current repo status

**APB Firewall + Address-Based Access Control — DONE**

The main improvement I would note for the repository documentation is **downstream `M_PSLVERR` propagation**. The current testbench intentionally documents this behavior, so it is best treated as a known limitation rather than silently changing the RTL.
