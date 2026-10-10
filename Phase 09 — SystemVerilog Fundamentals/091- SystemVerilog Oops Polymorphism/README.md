this is **OOP polymorphism**, specifically **runtime polymorphism through virtual methods** in SystemVerilog.

## 1. What is polymorphism?

Polymorphism means:

> **One parent-class handle can refer to objects of different derived classes, and the appropriate overridden method is selected at runtime.**

Your key declarations are:

```systemverilog
parent p;
child  c;
```

and:

```systemverilog
p = c;
```

Here, `p` is a **parent handle**, but it points to a **child object**.

---

## 2. Why `virtual` is important

In the parent:

```systemverilog
virtual function void print();
  $display("We are inside the parent class");
endfunction
```

The `virtual` keyword enables **dynamic method dispatch**.

The child overrides it:

```systemverilog
function void print();
  $display("We are inside the child class");
endfunction
```

Now:

```systemverilog
p.print();
```

looks like you're calling the parent method because `p` is declared as:

```systemverilog
parent p;
```

But the actual object is a `child`:

```text id="l8nqv0"
p ───────────────┐
                 │
                 ▼
          ┌──────────────┐
          │ child object │
          │              │
          │ print()      │
          └──────────────┘
```

Therefore, SystemVerilog calls:

```text id="5f7zqg"
We are inside the child class
```

This is **runtime polymorphism**.

---

## 3. `c.print()`

You also have:

```systemverilog id="8v2jmc"
c.print();
```

Here `c` is directly a child handle:

```systemverilog
child c;
```

So the child implementation is naturally called:

```text id="j4m9h8"
We are inside the child class
```

Therefore your output is:

```text id="v8c6f2"
We are inside the child class
We are inside the child class
```

---

## 4. Why `c = p` is illegal

You correctly commented:

```systemverilog
// c = p;
```

The reason is that:

```text id="3e0q8f"
parent handle
      ↓
may point to parent OR child objects
```

while:

```text id="j8a0p7"
child handle
      ↓
must point to a child object
```

So SystemVerilog cannot safely assume that `p` currently points to a child.

However, if `p` actually points to a child object, you can perform a **downcast** using `$cast`:

```systemverilog
$cast(c, p);
```

For example:

```systemverilog
p = c;

if ($cast(c, p))
  c.print();
```

Here `$cast` checks whether the object can legally be assigned to the child handle.

---

## 5. Static vs dynamic behavior

Without `virtual`:

```systemverilog
function void print();
```

the method binding is based on the **handle's declared type**.

With:

```systemverilog
virtual function void print();
```

the method binding is based on the **actual object type**.

That's the key idea:

```text id="j3t6az"
Without virtual
      ↓
Handle type

With virtual
      ↓
Actual object type
      ↓
Runtime polymorphism
```

---

## 6. Why this matters in verification

This is extremely important for a SystemVerilog verification environment.

For example, you can have:

```text id="c5q8k2"
              transaction
                  │
          ┌───────┴───────┐
          ↓               ↓
     read_transaction  write_transaction
```

A generator can hold:

```systemverilog
transaction tr;
```

and `tr` can point to either a read or write transaction.

Virtual methods allow the appropriate derived implementation to execute without the generator needing to know the exact derived type.

This is one of the concepts that later becomes very important in **UVM**, where base-class handles and derived transaction/component classes are used extensively.

### Interview answer

> **Polymorphism allows a base-class handle to reference a derived-class object. With virtual methods, SystemVerilog performs dynamic dispatch, so an overridden derived-class method is selected according to the actual object type at runtime. `$cast` can be used for safe downcasting from a parent handle to a child handle.**

So your OOP sequence is now:

```text id="g3q9xw"
Inheritance
    ↓
Encapsulation
    ↓
Polymorphism
    ↓
Abstraction
```


