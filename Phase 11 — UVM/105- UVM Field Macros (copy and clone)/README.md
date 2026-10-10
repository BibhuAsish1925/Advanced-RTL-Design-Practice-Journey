## 1. UVM Object Copy & Clone

This example demonstrates two important UVM object operations:

* **`copy()`**
* **`clone()`**

Both are used to duplicate the contents of one `uvm_object` into another.

The class contains:

```systemverilog
rand bit [3:0] data;
```

and registers it using:

```systemverilog
`uvm_field_int(data, UVM_DEFAULT);
```

This field registration allows UVM's automation mechanism to copy the `data` field.

---

## 2. `copy()` Operation

The first block creates two objects:

```systemverilog
first f1, s1;

f1 = new("first");
s1 = new("second");
```

Then:

```systemverilog
f1.randomize();
s1.copy(f1);
```

The important direction is:

```text id="p9s7km"
f1  ──────────copy──────────►  s1
source                         destination
```

So after:

```systemverilog
s1.copy(f1);
```

`f1.data` and `s1.data` contain the same value.

But they are still **two separate objects**.

```text id="r4v2pu"
f1 ──► data = X
s1 ──► data = X

Different objects
Same field value
```

---

## 3. `clone()` Operation

The second block does:

```systemverilog
f2.randomize();

$cast(s2, f2.clone());
```

Unlike `copy()`, `clone()` **creates a new object and copies the contents into it**.

Conceptually:

```text id="8yq1cg"
          f2
          │
       clone()
          │
          ▼
       new object
          │
          ▼
          s2
```

The reason for `$cast` is that:

```systemverilog id="h7c7j1"
f2.clone()
```

returns a `uvm_object` handle, while `s2` is a `first` handle.

Therefore:

```systemverilog id="k5z0my"
$cast(s2, f2.clone());
```

safely converts the returned `uvm_object` handle to the `first` type.

---

## 4. `copy()` vs `clone()`

| Feature            | `copy()`                  | `clone()`               |
| ------------------ | ------------------------- | ----------------------- |
| Destination object | Already exists            | Created automatically   |
| Syntax             | `s1.copy(f1)`             | `f2.clone()`            |
| Copies fields      | ✅                         | ✅                       |
| Creates new object | ❌                         | ✅                       |
| Typical use        | Copy into existing object | Create duplicate object |

### Simple way to remember

```text id="qv3n4x"
copy()
Source ──────────► Existing Destination

clone()
Source ──────────► New Duplicate
```

---

## 5. Interview Takeaways

The most important point is that **field macros enable UVM automation**.

Your:

```systemverilog id="j0l9h3"
`uvm_field_int(data, UVM_DEFAULT);
```

allows UVM to know that `data` should participate in operations such as copying.

Your current UVM progression is now:

```text id="f6b4oh"
UVM Object
    ↓
Field Macros
    ├── int
    ├── enum
    ├── string
    ├── real
    └── arrays
          ↓
      copy()
          ↓
      clone()
```

### One important distinction

```systemverilog
s1.copy(f1);
```

means **copy `f1` into existing `s1`**.

```systemverilog
$cast(s2, f2.clone());
```

means **create a new duplicate of `f2` and assign it to `s2`**.

This example is therefore **done for the repository**. The next natural UVM object-automation topic is **`compare()`**, followed by **`print()/sprint()` and pack/unpack**.
