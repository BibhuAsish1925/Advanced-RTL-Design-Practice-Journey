## 1. Circuit Overview & Applications

This example demonstrates the **basic UVM component creation and UVM test execution flow**.

There is no DUT or actual circuit here. It focuses specifically on:

* Creating a class derived from `uvm_component`
* Registering the component with the UVM factory
* Implementing `build_phase()`
* Starting a UVM test using `run_test()`

**Main concept:** `uvm_component` is the base class for structural UVM elements such as environments, agents, drivers, monitors, and tests.

---

## 2. Circuit Working & RTL Implementation

### Component declaration

```systemverilog
class comp extends uvm_component;
```

`comp` inherits from `uvm_component`, so it becomes part of the UVM component hierarchy.

### Factory registration

```systemverilog
`uvm_component_utils(comp)
```

Registers `comp` with the **UVM factory**.

This allows:

```systemverilog
run_test("comp");
```

to create and execute the `comp` test through the factory.

### Constructor

```systemverilog
function new(string path = "comp", uvm_component parent = null);
  super.new(path,parent);
endfunction
```

Every UVM component has:

* `name` → component instance name
* `parent` → parent component in the UVM hierarchy

Here, `parent = null` because `comp` is the top-level test created by `run_test()`.

### Build phase

```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  `uvm_info("COMP", "Build phase of comp executed", UVM_NONE); 
endfunction
```

`build_phase()` is used to **construct/configure the UVM testbench hierarchy**.

The important sequence is:

```text
run_test("comp")
      ↓
UVM factory
      ↓
create comp
      ↓
build_phase()
      ↓
UVM_INFO message
```

`super.build_phase(phase)` allows the parent `uvm_component` implementation to execute.

---

## 3. Verification & Testbench

The testbench itself is:

```systemverilog
module tb7;
  initial begin
    run_test("comp");
  end
endmodule
```

`run_test("comp")` tells UVM:

> Find the registered component/test named `comp`, create it, and start the UVM phase mechanism.

Expected output will contain something similar to:

```text
UVM_INFO ... [COMP] Build phase of comp executed
```

### Important observation

Although `comp` extends `uvm_component`, it is being passed to:

```systemverilog
run_test("comp");
```

This works because `run_test()` expects a **UVM test component**, and `comp` is being used as the top-level test here.

For learning purposes, this demonstrates the basic relationship:

```text
tb7
 │
 └── run_test("comp")
          │
          ▼
        comp
          │
          └── build_phase()
```

---

## 4. Advantages & Limitations

### Advantages

* Simple introduction to `uvm_component`
* Demonstrates factory registration
* Demonstrates `build_phase()`
* Demonstrates `run_test()`
* Shows the basic UVM phase mechanism

### Limitations

This is **not yet a complete UVM verification environment**.

It does not contain:

* DUT
* Transaction / sequence item
* Sequence
* Sequencer
* Driver
* Monitor
* Agent
* Scoreboard
* Environment
* Virtual interface
* Configuration database
* Actual stimulus or checking

So this example should be classified as a **basic UVM component + phase demonstration**.

---

## 5. Interview Takeaways

**Q: What is `uvm_component`?**
A: Base class for structural elements of a UVM testbench.

**Q: Why use `` `uvm_component_utils(comp) ``?**
A: To register the component with the UVM factory and enable factory-based creation/overriding.

**Q: What is `build_phase()` used for?**
A: Creating and configuring the UVM component hierarchy.

**Q: Why call `super.build_phase(phase)`?**
A: To preserve the parent class's phase behavior.

**Q: What does `run_test("comp")` do?**
A: Starts the UVM test and asks the factory to create the specified test component.

### Repo status

✅ **UVM Component + `build_phase()` + `run_test()` — DONE**

This is a natural follow-up to your earlier **UVM Components/Hierarchy** example, but here the focus is specifically on the **top-level UVM test execution and build phase**.
