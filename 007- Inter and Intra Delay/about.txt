These two examples demonstrate the difference between **inter-assignment delay** and **intra-assignment delay** in Verilog/SystemVerilog, specifically with **non-blocking assignments (`<=`)**.

# INTER-ASSIGNMENT vs INTRA-ASSIGNMENT DELAY

## 1. Inter-assignment Delay

Your first module:

```verilog
#5 a <= 1;
   c <= 1;

#5 q <= a & b | c;
```

### What happens

At `t = 0`:

```text
a = 0
b = 0
c = 0
q = 0
```

At `t = 5`:

```verilog
#5 a <= 1;
   c <= 1;
```

The `#5` delays execution of the assignments until `t=5`.

Both assignments are scheduled at `t=5`, so:

```text
a = 1
c = 1
```

At `t = 10`:

```verilog
q <= a & b | c;
```

The RHS is evaluated using the current values:

```text
a & b | c
= 1 & 0 | 1
= 0 | 1
= 1
```

Therefore:

```text
q = 1
```

### Timeline

```text
Time       a   b   c   q
-------------------------
0          0   0   0   0
5          1   0   1   0
10         1   0   1   1
```

The important point is:

```verilog
#5 q <= expression;
```

means **wait first, then evaluate the RHS and schedule the assignment**.

---

# 2. Intra-assignment Delay

The second module contains:

```verilog
q <= #5 a & b | c;
```

This is an **intra-assignment delay**.

Conceptually:

```text
Evaluate RHS
     ↓
Store/schedule evaluated value
     ↓
Wait 5 time units
     ↓
Update q
```

This is different from:

```verilog
#5 q <= a & b | c;
```

which means:

```text
Wait 5 time units
     ↓
Evaluate RHS
     ↓
Update q
```

---

## First intra-assignment statement

At `t = 5`, the code reaches:

```verilog
q <= #5 a & b | c;
```

At this point:

```text
a = 1
b = 0
c = 1
```

So the RHS is evaluated immediately:

```text
a & b | c
= 1 & 0 | 1
= 1
```

The value `1` is then scheduled to be assigned to `q` at:

```text
t = 5 + 5 = 10
```

So:

```text
t=5  → evaluate RHS → value = 1
t=10 → q becomes 1
```

---

# 3. Important Difference

The simplest way to remember it:

### Inter-assignment delay

```verilog
#5 q <= a & b | c;
```

```text
WAIT 5
  ↓
EVALUATE RHS
  ↓
ASSIGN q
```

### Intra-assignment delay

```verilog
q <= #5 a & b | c;
```

```text
EVALUATE RHS
  ↓
WAIT 5
  ↓
ASSIGN q
```

This distinction becomes important when the RHS signals can change during the delay period.

---

# 4. Your Blocking Assignment Example

Later you have:

```verilog
#10 a = 1;
    c = 1;
    q <= #5 a & b | c;
```

Here:

```verilog
a = 1;
c = 1;
```

are **blocking assignments**.

Therefore, when execution reaches:

```verilog
q <= #5 a & b | c;
```

both `a` and `c` have already been updated in the current procedural flow.

The RHS evaluates to:

```text
1 & 0 | 1 = 1
```

and `q` is scheduled to receive `1` after another 5 time units.

---

# 5. Why `$monitor` Is Used

Both examples contain:

```verilog
$monitor("[%0t] a=%0b b=%0b c=%0b q=%0b",
         $time, a, b, c, q);
```

`$monitor` automatically prints whenever one of its listed arguments changes.

For example:

```text
[0]  a=0 b=0 c=0 q=0
[5]  a=1 b=0 c=1 q=0
[10] a=1 b=0 c=1 q=1
```

It is useful for observing how delayed assignments affect signal values over simulation time.

---

# 6. Key Interview Point

| Type             | Example         | RHS evaluation                                             |
| ---------------- | --------------- | ---------------------------------------------------------- |
| Inter-assignment | `#5 q <= expr;` | After delay                                                |
| Intra-assignment | `q <= #5 expr;` | Before delay                                               |
| Blocking         | `q = expr;`     | Immediate procedural update                                |
| Non-blocking     | `q <= expr;`    | RHS evaluated immediately, LHS updated later in NBA region |

### One-line memory trick

```text
Inter-assignment:  DELAY → EVALUATE → ASSIGN
Intra-assignment:  EVALUATE → DELAY → ASSIGN
```

Also note that your comments call `#5 a <= 1;` an **inter-assignment delay**, which is the correct terminology.
