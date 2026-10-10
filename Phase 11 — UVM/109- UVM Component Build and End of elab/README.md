## 1. Circuit Overview & Applications

This example demonstrates **UVM component hierarchy creation and `end_of_elaboration_phase()`**.

The hierarchy is:

```text
c
├── a_inst
└── b_inst
```

Here:

* `a` → child UVM component
* `b` → child UVM component
* `c` → parent component that creates `a` and `b`
* `tb8` → starts the UVM test using `run_test("c")`

The main new concept is **printing the complete UVM topology after elaboration**.

---

## 2. Circuit Working & UVM Implementation

### Classes `a` and `b`

Both classes extend `uvm_component` and are factory registered:

```systemverilog
`uvm_component_utils(a)
`uvm_component_utils(b)
```

Their `build_phase()` simply prints a message:

```text
[a] Class a executed
[b] Class b executed
```

They don't create any further components.

### Class `c`

`c` contains handles for its child components:

```systemverilog
a a_inst;
b b_inst;
```

Inside `build_phase()`:

```systemverilog
a_inst = a::type_id::create("a_inst",this);
b_inst = b::type_id::create("b_inst",this);
```

The important part is:

```systemverilog
this
```

It specifies that `c` is the **parent** of both components.

Therefore:

```text
c
├── a_inst
└── b_inst
```

is created in the UVM hierarchy.

### Factory creation

Notice that the code uses:

```systemverilog
a::type_id::create(...)
b::type_id::create(...)
```

rather than:

```systemverilog
new(...)
```

This is important because **factory-based creation allows later factory overrides** without modifying the component construction code.

---

## 3. Verification & Testbench

The new phase demonstrated here is:

```systemverilog
virtual function void end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.print_topology();
endfunction
```

### What happens?

UVM first executes the build phase:

```text
run_test("c")
      ↓
create c
      ↓
c.build_phase()
      ↓
create a_inst
create b_inst
```

After the component hierarchy has been constructed, UVM reaches:

```text
end_of_elaboration_phase
```

At this point:

```systemverilog
uvm_top.print_topology();
```

prints the complete UVM hierarchy.

Conceptually, the output will look similar to:

```text
uvm_test_top
  c
    a_inst
    b_inst
```

The exact formatting depends on the simulator/UVM version.

### Why is `end_of_elaboration_phase()` useful?

It is a good place to inspect the **final component hierarchy after construction but before simulation starts**.

This is particularly useful for debugging large UVM environments.

---

## 4. Advantages & Limitations

### Advantages

* Demonstrates parent-child UVM hierarchy.
* Uses factory-based component creation.
* Demonstrates `build_phase()`.
* Introduces `end_of_elaboration_phase()`.
* Uses `uvm_top.print_topology()` to inspect the hierarchy.
* Shows how `this` establishes the parent component.

### Limitations

This is still a structural UVM example. It does not contain:

* Sequence item
* Sequence
* Sequencer
* Driver
* Monitor
* Agent
* Scoreboard
* DUT
* TLM connections
* Configuration database

---

## 5. Interview Takeaways

**Q: Why is `this` passed to `create()`?**
A: It specifies the current component `c` as the parent of the newly created component.

**Q: What does `uvm_top.print_topology()` do?**
A: Prints the complete UVM component hierarchy.

**Q: Why use `end_of_elaboration_phase()` for topology printing?**
A: By this phase, the component hierarchy has been constructed, so the final hierarchy can be inspected.

**Q: What is the difference between `build_phase()` and `end_of_elaboration_phase()`?**

| Phase                        | Purpose                                    |
| ---------------------------- | ------------------------------------------ |
| `build_phase()`              | Create/configure components                |
| `end_of_elaboration_phase()` | Inspect/finalize the constructed hierarchy |

**Q: Why use `type_id::create()` instead of `new()`?**
A: It uses the UVM factory, enabling factory overrides and more flexible testbench configuration.

### Repo status

✅ **UVM Component Hierarchy + `build_phase()` + `end_of_elaboration_phase()` + `print_topology()` — DONE**

This is a good progression from the previous `COMPONENT_Build` example: **single component → parent-child hierarchy → topology inspection**.
