## 1. Circuit Overview & Applications

This example continues the **UVM Object + Field Macros** topic.

The previous example covered:

* `uvm_field_int`

This example expands field automation to:

* `uvm_field_enum`
* `uvm_field_string`
* `uvm_field_real`

There is no DUT here. It is a **UVM object field-registration practice example**.

---

## 2. UVM Object & Field Registration

The class contains three different field types:

```systemverilog
typedef enum bit [1:0] {s0, s1, s2, s3} state_type;
rand state_type state;

real temp = 12.34;
string str = "UVM";
```

So the object contains:

```text
state → enum
temp  → real
str   → string
```

They are registered using:

```systemverilog
`uvm_object_utils_begin(obj)

`uvm_field_enum(state_type, state, UVM_DEFAULT);
`uvm_field_string(str, UVM_DEFAULT);
`uvm_field_real(temp, UVM_DEFAULT);

`uvm_object_utils_end
```

### `uvm_field_enum`

```systemverilog
`uvm_field_enum(state_type, state, UVM_DEFAULT);
```

Registers the `state` enum field with UVM.

Because `state` is randomized:

```systemverilog
o.randomize();
```

one of:

```text
s0
s1
s2
s3
```

can be selected.

### `uvm_field_string`

```systemverilog
`uvm_field_string(str, UVM_DEFAULT);
```

Registers the string:

```text
"UVM"
```

### `uvm_field_real`

```systemverilog
`uvm_field_real(temp, UVM_DEFAULT);
```

Registers the real-valued field:

```text
12.34
```

---

## 3. Verification / Testbench Working

The testbench performs:

```systemverilog
o = new("obj");
o.randomize();
o.print(uvm_default_table_printer);
```

The flow is:

```text
Create UVM object
       ↓
   randomize()
       ↓
state gets s0/s1/s2/s3
       ↓
UVM field registration
       ↓
      print()
       ↓
UVM table output
```

The important difference from the previous example is that UVM is now handling **multiple data types** through their corresponding field macros.

Conceptually, the output will contain something similar to:

```text
-----------------------------------------
Name      Type       Value
-----------------------------------------
state     enum       s0
temp      real       12.34
str       string     UVM
-----------------------------------------
```

The actual `state` value will vary because it is randomized.

---

## 4. Advantages & Limitations

### Advantages

* Demonstrates `uvm_object`.
* Demonstrates enum field registration.
* Demonstrates string field registration.
* Demonstrates real field registration.
* Demonstrates UVM automatic printing.
* Reinforces `uvm_object_utils_begin/end`.

### Limitations

This still only demonstrates **field registration + printing**.

Not yet covered here:

* `uvm_field_array_*`
* `copy()`
* `clone()`
* `compare()`
* `pack()`
* `unpack()`
* `sprint()`

Those can be handled in their respective examples.

---

## 5. Interview Takeaways

You now have the basic UVM field-macro mapping:

| SystemVerilog type         | UVM field macro    |
| -------------------------- | ------------------ |
| `int`, `bit`, `logic` etc. | `uvm_field_int`    |
| `enum`                     | `uvm_field_enum`   |
| `string`                   | `uvm_field_string` |
| `real`                     | `uvm_field_real`   |

The main idea is:

> **UVM field macros register object properties so UVM automation methods can operate on those fields.**

So your UVM progression is now:

```text
UVM Components
      ↓
UVM Object
      ↓
UVM Field Macros
      ├── int
      ├── enum
      ├── string
      └── real
```

This example is therefore **done for the current repository**.
