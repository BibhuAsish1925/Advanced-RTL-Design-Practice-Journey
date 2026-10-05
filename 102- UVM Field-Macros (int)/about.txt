## 1. Circuit Overview & Applications

This example demonstrates **`uvm_object` and UVM field macros**, specifically how UVM can automatically handle class properties for operations such as **printing, copying, comparing, packing/unpacking**, etc.

There is no DUT here; this is a **UVM object-level practice example**.

The class is:

```systemverilog
class obj extends uvm_object;
```

and contains two randomized fields:

```systemverilog
rand bit [3:0] a;
rand bit [7:0] b;
```

---

## 2. UVM Object & Field Registration

The important part is:

```systemverilog
`uvm_object_utils_begin(obj)

`uvm_field_int(a, UVM_DEFAULT | UVM_BIN);
`uvm_field_int(b, UVM_DEFAULT | UVM_DEC);

`uvm_object_utils_end
```

### `uvm_object_utils_begin/end`

These register the class with the **UVM factory** and allow the field macros to be associated with the object.

Compared with the earlier simple form:

```systemverilog
`uvm_object_utils(obj)
```

the `begin/end` form allows you to register individual class fields.

### `uvm_field_int`

```systemverilog
`uvm_field_int(a, UVM_DEFAULT | UVM_BIN);
```

registers `a` as an integer-like field and requests **binary formatting** when printed.

```systemverilog
`uvm_field_int(b, UVM_DEFAULT | UVM_DEC);
```

registers `b` and requests **decimal formatting**.

So the same object contains:

```text
a → printed in binary
b → printed in decimal
```

---

## 3. Verification / Testbench Working

The top module creates the object:

```systemverilog
o = new("obj");
```

Then randomizes it:

```systemverilog
o.randomize();
```

Finally:

```systemverilog
o.print(uvm_default_table_printer);
```

prints the registered fields using the UVM table printer.

The flow is:

```text
        obj
         │
         ├── a [3:0]
         └── b [7:0]
              │
              ▼
        randomize()
              │
              ▼
        UVM field macros
              │
              ▼
          o.print()
              │
              ▼
       UVM table output
```

For example, you should see a table containing the object name and fields similar to:

```text
--------------------------------------------
Name    Type      Size    Value
--------------------------------------------
a       integral  4       xxxx
b       integral  8       xxxx
--------------------------------------------
```

The actual randomized values will vary.

---

## 4. Advantages & Limitations

### Advantages

* Demonstrates `uvm_object`.
* Demonstrates UVM field registration.
* Demonstrates `uvm_object_utils_begin/end`.
* Demonstrates `uvm_field_int`.
* Shows different field print formats.
* Demonstrates `uvm_default_table_printer`.
* Uses randomized object fields.

### Limitations

This example only demonstrates **field registration and printing**.

It does not yet demonstrate:

* `copy()`
* `clone()`
* `compare()`
* `pack()`
* `unpack()`
* `sprint()`
* Custom printers
* Sequence items
* UVM components
* Factory override

Those should be separate examples because they are important UVM concepts.

---

## 5. Interview Takeaways

The key distinction from your previous UVM code is:

```text
UVM Component                         UVM Object
───────────────                      ──────────
uvm_component                        uvm_object
Driver                               Transaction
Monitor                              Sequence item
Environment                          Sequence
Test
```

Your previous example used:

```systemverilog
uvm_driver
uvm_monitor
uvm_env
uvm_test
```

This example introduces:

```systemverilog
uvm_object
```

and specifically **field automation**.

### One important point

You have commented out:

```systemverilog
// `uvm_object_utils(obj)
```

because you are instead using:

```systemverilog
`uvm_object_utils_begin(obj)
...
`uvm_object_utils_end
```

That is correct. **Don't use both registration forms for the same class.**

Also, the field macros are particularly important because they become useful later for:

**`print → copy/clone → compare → pack/unpack`**

So this is a good next entry in your current UVM practice sequence: **UVM Object + Field Macros**.
