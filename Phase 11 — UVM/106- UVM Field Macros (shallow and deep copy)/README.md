## 1. UVM Object Structure & Copy Types

This example demonstrates **shallow copy vs deep copy** when a UVM object contains another UVM object.

The structure is:

```text
second
  │
  └── f
       │
       └── first
             └── data
```

`second` contains an object handle:

```systemverilog
first f;
```

and registers it using:

```systemverilog
`uvm_field_object(f, UVM_DEFAULT);
```

This is important because copying `second` now involves its nested `first` object.

---

## 2. Shallow Copy

The commented portion demonstrates:

```systemverilog
s2 = s1;
```

This is a **shallow handle assignment**.

It does **not create a new `first` object**.

Conceptually:

```text
s1 ────────┐
           │
           ▼
        first object
        data = X
           ▲
           │
s2 ────────┘
```

Both `s1.f` and `s2.f` refer to the **same `first` object**.

Therefore:

```systemverilog
s2.f.data = 12;
```

will also change what `s1.f.data` sees.

So:

```text
s1.f.data → 12
s2.f.data → 12
```

because both handles point to the same nested object.

---

## 3. Deep Copy Using `clone()`

The active code uses:

```systemverilog
$cast(s2, s1.clone());
```

Here `clone()` creates a new object and, because `f` is registered using:

```systemverilog
`uvm_field_object(f, UVM_DEFAULT);
```

the nested object is copied as part of the UVM field automation.

Conceptually:

```text
s1                         s2
 │                          │
 ▼                          ▼
first object              first object
data = X                   data = X
```

These are **different `first` objects**.

Therefore:

```systemverilog
s2.f.data = 12;
```

changes only `s2.f.data`.

After the modification:

```text
s1.f.data → X
s2.f.data → 12
```

This is the key demonstration of **deep copying** in this example.

---

## 4. `copy()` vs `clone()` for Nested Objects

The commented code also shows:

```systemverilog
s2.copy(s1);
```

This is another way to perform UVM's field-based object copying.

So the three operations in your file are:

| Operation               | Result                                  |
| ----------------------- | --------------------------------------- |
| `s2 = s1`               | Shallow handle assignment               |
| `s2.copy(s1)`           | UVM field-based copy into existing `s2` |
| `$cast(s2, s1.clone())` | Creates a cloned object                 |

For this example, the important distinction is:

```text
s2 = s1
   ↓
same nested object

s2.copy(s1)
   ↓
UVM copies registered fields

s1.clone()
   ↓
new object + registered nested object copied
```

---

## 5. Interview Takeaways

The most important concept from this example is **object handles vs object contents**.

### Shallow assignment

```systemverilog
s2 = s1;
```

copies the **handle**, not the object.

### Deep UVM copy/clone

```systemverilog
s2.copy(s1);
```

or:

```systemverilog
$cast(s2, s1.clone());
```

uses UVM's registered fields.

The nested object is registered with:

```systemverilog
`uvm_field_object(f, UVM_DEFAULT);
```

which is what allows UVM's automation to include `f`.

### Current UVM progression

```text
UVM Objects
   ↓
Field Macros
   ↓
Scalar / Enum / String / Real
   ↓
Arrays
   ↓
copy()
   ↓
clone()
   ↓
Nested Objects
   ↓
Shallow vs Deep Copy
```

**This example is done for the repository.** The next logical topic is **`compare()`**, where you can compare two UVM objects—including their registered nested objects.
