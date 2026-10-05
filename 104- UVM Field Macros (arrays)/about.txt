## 1. UVM Object & Array Types

This example extends **UVM field automation to different SystemVerilog array types**.

The class contains four array categories:

```text
arr1 → Static array
arr2 → Dynamic array
arr3 → Queue
arr4 → Associative array
```

The purpose is to demonstrate how each array type is registered using its corresponding UVM field macro.

---

## 2. UVM Field Macros for Arrays

### Static array

```systemverilog
int arr1[3] = {1,2,3};
```

Registered with:

```systemverilog
`uvm_field_sarray_int(arr1, UVM_DEFAULT);
```

`sarray` means **static array**.

---

### Dynamic array

```systemverilog
int arr2[];
```

It is allocated inside `run()`:

```systemverilog
arr2 = new[3];

arr2[0] = 2;
arr2[1] = 2;
arr2[2] = 2;
```

Registered with:

```systemverilog
`uvm_field_array_int(arr2, UVM_DEFAULT);
```

So after `run()`:

```text
arr2 = {2, 2, 2}
```

---

### Queue

```systemverilog
int arr3[$];
```

Values are added using:

```systemverilog
arr3.push_front(3);
arr3.push_front(3);
```

Registered with:

```systemverilog
`uvm_field_queue_int(arr3, UVM_DEFAULT);
```

The queue therefore contains two elements:

```text
arr3 = {3, 3}
```

---

### Associative array

```systemverilog
int arr4[int];
```

Values are inserted using integer indices:

```systemverilog
arr4[1] = 4;
arr4[2] = 4;
arr4[3] = 4;
arr4[4] = 4;
```

Registered with:

```systemverilog
`uvm_field_aa_int_int(arr4, UVM_DEFAULT);
```

Conceptually:

```text
Index → Value

1 → 4
2 → 4
3 → 4
4 → 4
```

---

## 3. Verification / Testbench Working

The complete flow is:

```text
             array object
                  │
        ┌─────────┼──────────┐
        ▼         ▼          ▼
    arr2=new   queue       assoc.
        │       push        insert
        └─────────┼──────────┘
                  ▼
           UVM field macros
                  │
                  ▼
              a.print()
                  │
                  ▼
          UVM formatted output
```

The top module performs:

```systemverilog
a = new("array");
a.run();
a.print();
```

Therefore, all four array types are populated first and then printed through UVM's field automation.

---

## 4. Advantages & Limitations

### Advantages

* Demonstrates static-array registration.
* Demonstrates dynamic-array registration.
* Demonstrates queue registration.
* Demonstrates associative-array registration.
* Shows how UVM field automation handles different collection types.
* Useful preparation for UVM transaction/sequence-item classes.

### Limitations

This example does not yet demonstrate:

* Array copying
* Array comparison
* Array packing/unpacking
* Nested objects
* Arrays of objects
* Multi-dimensional arrays
* Custom `do_print()`

Also, `arr1` is initialized directly while the other arrays are populated in `run()`, so the example is primarily demonstrating **field registration**, not randomized array generation.

---

## 5. Interview Takeaways

The important mapping from this example is:

| SystemVerilog array | UVM macro              |
| ------------------- | ---------------------- |
| Static array        | `uvm_field_sarray_int` |
| Dynamic array       | `uvm_field_array_int`  |
| Queue               | `uvm_field_queue_int`  |
| Associative array   | `uvm_field_aa_int_int` |

So your UVM field-macro coverage is now:

```text
UVM Field Macros
│
├── Scalar
│   └── uvm_field_int
│
├── Enum
│   └── uvm_field_enum
│
├── String
│   └── uvm_field_string
│
├── Real
│   └── uvm_field_real
│
└── Arrays / Collections
    ├── Static array
    ├── Dynamic array
    ├── Queue
    └── Associative array
```

**This example is done for the repository.** The next logical UVM topic is **copy/clone**, where these registered fields become useful for demonstrating how UVM automatically copies object data.
