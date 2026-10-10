this is **OOP encapsulation in SystemVerilog**, specifically demonstrating the three access-control levels:

```text
public
protected
local
```

Your example is mainly showing how **`protected` members can be accessed by a child class but not directly from the testbench**.

---

## 1. Public members — default

Your original declaration:

```systemverilog
bit [3:0] a = 2;
bit [3:0] b = 3;
```

is **public by default**.

Therefore, all of these can access them:

```text
parent class
child class
testbench
```

For example:

```systemverilog
c.a
c.b
```

would be legal.

---

## 2. `local` members

If you change them to:

```systemverilog
local bit [3:0] a = 2;
local bit [3:0] b = 3;
```

then they can be accessed **only inside the class where they are declared**.

So:

```text
parent
  ✓ a, b

child
  ✗ a, b

testbench
  ✗ a, b
```

Even the derived `child` class cannot directly access the `local` members of `parent`.

---

## 3. `protected` members

Your active version is intended to use:

```systemverilog
protected bit [3:0] a = 2;
protected bit [3:0] b = 3;
```

With `protected`:

```text
parent
  ✓ a, b

child
  ✓ a, b

testbench
  ✗ a, b
```

This is why your child class can do:

```systemverilog id="tq1g8a"
function void add();
  c = a + b;
  $display("c=%0d", c);
endfunction
```

The child inherited access to the protected members.

---

## 4. Why use getter functions?

You added:

```systemverilog id="v2i5rd"
function bit [3:0] get_a();
  return a;
endfunction

function bit [3:0] get_b();
  return b;
endfunction
```

These are **public methods** because functions are public by default.

Therefore, the testbench cannot do:

```systemverilog id="6e4f2j"
d = c.a + c.b;   // Not allowed for protected a/b
```

but it can do:

```systemverilog id="gj0l4a"
d = c.get_a() + c.get_b();
```

The access path becomes:

```text
Testbench
    │
    │ calls public method
    ▼
get_a() / get_b()
    │
    │ accesses protected data
    ▼
a / b
```

This is the basic idea of **encapsulation**: hide internal data and expose controlled access through methods.

---

## 5. Your complete flow

With:

```systemverilog
protected bit [3:0] a = 2;
protected bit [3:0] b = 3;
```

the execution is:

```text
c = new()
   ↓
c.print()
   ↓
a=2, b=3
   ↓
c.add()
   ↓
c = a+b = 5
   ↓
c.get_a() + c.get_b()
   ↓
d = 2+3 = 5
```

Expected output:

```text
a=2 b=3
c=5
d=5
```

---

## 6. Access-control comparison

| Access type | Declaring class | Child class | Outside/Testbench |
| ----------- | --------------: | ----------: | ----------------: |
| `public`    |               ✓ |           ✓ |                 ✓ |
| `protected` |               ✓ |           ✓ |                 ✗ |
| `local`     |               ✓ |           ✗ |                 ✗ |

### Interview answer

> **Encapsulation is the mechanism of restricting direct access to class data and exposing controlled access through methods. In SystemVerilog, `protected` members are accessible within the declaring class and derived classes, while `local` members are accessible only within the declaring class. Members are public by default.**

For verification, this becomes useful when a **transaction/class should hide internal implementation details** while exposing only the fields and methods that other verification components are supposed to use.
