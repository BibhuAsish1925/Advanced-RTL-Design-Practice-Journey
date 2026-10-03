this is **SystemVerilog inheritance**. Your example demonstrates **parent/child classes, `extends`, inherited properties/methods, and `super`**.

## 1. Parent class

```systemverilog
class parent;
  bit [3:0]  length;
  bit [4:0]  breadth;
  bit [31:0] peri;

  function void Peri();
    peri = 2 * (length + breadth);
    $display("perimeter=%0d", peri);
  endfunction
endclass
```

`parent` contains:

* `length`
* `breadth`
* `peri`
* `Peri()` function

The perimeter calculation is:

```text
Perimeter = 2 × (length + breadth)
```

---

## 2. Child class

```systemverilog
class child extends parent;
  bit [31:0] area;

  function void rectangle();
    area = length * breadth;
    $display("area=%0d", area);
    super.Peri();
  endfunction
endclass
```

The important statement is:

```systemverilog
class child extends parent;
```

This means `child` **inherits** the members of `parent`.

Therefore, `child` automatically has access to:

```text
length
breadth
peri
Peri()
```

in addition to its own:

```text
area
rectangle()
```

Conceptually:

```text
             parent
        ┌───────────────┐
        │ length        │
        │ breadth       │
        │ peri          │
        │ Peri()        │
        └───────┬───────┘
                │ extends
                ▼
             child
        ┌───────────────┐
        │ area          │
        │ rectangle()   │
        │               │
        │ + inherited   │
        │   members     │
        └───────────────┘
```

---

## 3. What does `super.Peri()` mean?

Inside `rectangle()`:

```systemverilog
super.Peri();
```

means:

> Call the `Peri()` method belonging to the parent class.

So:

```systemverilog
function void rectangle();
  area = length * breadth;
  $display("area=%0d", area);

  super.Peri();
endfunction
```

first calculates the **area**, then explicitly calls the parent's **perimeter** function.

---

## 4. What happens in your testbench?

```systemverilog
c = new();

c.length = 10;
c.breadth = 20;

c.rectangle();
```

Although `length` and `breadth` were declared in `parent`, the `child` object can access them because they are inherited.

### Area

```text
10 × 20 = 200
```

### Perimeter

```text
2 × (10 + 20) = 60
```

Expected output:

```text
area=200
perimeter=60
```

---

## 5. Why inheritance is useful in verification

This becomes very important when building a SystemVerilog verification environment.

For example, you might have:

```text
transaction
    │
    ├── read_transaction
    │
    └── write_transaction
```

The base transaction can contain common fields:

```systemverilog
class transaction;
  bit [31:0] addr;
  bit [31:0] data;
endclass
```

Then specialized transactions can extend it:

```systemverilog
class write_transaction extends transaction;
  bit [3:0] wstrb;
endclass
```

The child automatically gets `addr` and `data` while adding `wstrb`.

This is one of the foundations of **object-oriented verification environments and UVM**.

### Interview answer

> **Inheritance allows a child class to acquire the properties and methods of a parent class using `extends`. The child can add new members or override existing behavior, while `super` can be used to access the parent-class implementation.**

One terminology correction: this is simply **inheritance**, not “oops inheritance” — although it is indeed one of the core **OOP (Object-Oriented Programming)** concepts in SystemVerilog.
