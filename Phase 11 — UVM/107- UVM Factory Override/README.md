## 1. UVM Factory Override

This example demonstrates **UVM type override**, specifically:

```systemverilog
set_type_override_by_type()
```

The purpose is to tell the UVM factory:

> Whenever the testbench requests an object of type `first_fo`, create `first_mod_fo` instead.

The class hierarchy is:

```text
uvm_object
    │
    └── first_fo
          │
          └── first_mod_fo
```

`first_fo` contains:

```systemverilog
rand bit [3:0] data;
```

while the derived `first_mod_fo` adds:

```systemverilog
rand bit ack;
```

---

## 2. Factory Override Working

The important statement is:

```systemverilog
uvm_factory::get().set_type_override_by_type(
    first_fo::get_type(),
    first_mod_fo::get_type()
);
```

This establishes:

```text
Requested type       Factory creates
──────────────       ────────────────
first_fo       ───►  first_mod_fo
```

So although the component later asks for:

```systemverilog
f = first_fo::type_id::create("f");
```

the factory sees the override and actually creates a:

```text
first_mod_fo
```

object.

This is the key idea behind the **UVM Factory**: the code requesting the object does not necessarily have to know which concrete implementation the factory will instantiate.

---

## 3. Verification / Testbench Working

The component contains:

```systemverilog
first_fo f;
```

and creates it through the factory:

```systemverilog
f = first_fo::type_id::create("f");
```

Before this happens, the top module installs the override:

```systemverilog
uvm_factory::get().set_type_override_by_type(
    first_fo::get_type(),
    first_mod_fo::get_type()
);
```

Therefore the sequence is:

```text
tb6
 │
 ├── Set factory override
 │       │
 │       ▼
 │   first_fo → first_mod_fo
 │
 └── Create comp_fo
         │
         ▼
       new()
         │
         ▼
   f = first_fo::type_id::create("f")
         │
         ▼
   Factory applies override
         │
         ▼
      first_mod_fo
```

Then:

```systemverilog
f.randomize();
f.print();
```

Because the actual object is `first_mod_fo`, it contains both:

```text
data
ack
```

---

## 4. Important Factory Concept

There are **two different types involved**:

### Handle type

```systemverilog
first_fo f;
```

The handle is declared as `first_fo`.

### Actual object type

Because of the factory override:

```text
Actual object = first_mod_fo
```

So conceptually:

```text
first_fo handle
      │
      ▼
first_mod_fo object
 ├── data
 └── ack
```

This is possible because `first_mod_fo` derives from `first_fo`.

---

## 5. Interview Takeaways

The core interview definition is:

> **UVM factory override allows a derived implementation to replace a base type at object creation time without modifying the code that requests the base type.**

Important pieces in your example:

```systemverilog
`uvm_object_utils(first_fo)
```

registers the object with the factory.

```systemverilog
`uvm_object_utils(first_mod_fo)
```

registers the derived object.

And:

```systemverilog
first_fo::type_id::create("f");
```

requests creation through the factory.

Finally:

```systemverilog
set_type_override_by_type(
    first_fo::get_type(),
    first_mod_fo::get_type()
);
```

changes what the factory creates.

### Your UVM progression now

```text
UVM Object
   ↓
Field Macros
   ↓
copy / clone
   ↓
Nested Objects
   ↓
Factory
   ↓
Type Override
```

**This `FACTORY_OVERRIDE.sv` example is done for the repository.** The next natural factory topic is **instance override**, where only a specific component/object instance is replaced rather than every `first_fo` creation.
