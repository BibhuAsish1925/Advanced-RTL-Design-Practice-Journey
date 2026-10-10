## 1. Circuit Overview & Applications

This code demonstrates the **basic UVM component hierarchy** rather than verifying an actual DUT.

The hierarchy is:

```text
uvm_test
   │
   └── my_test
          │
          └── my_env
                 ├── my_driver
                 └── my_monitor
```

It introduces the fundamental UVM component types:

* `uvm_test`
* `uvm_env`
* `uvm_driver`
* `uvm_monitor`
* UVM factory registration
* UVM phases
* UVM objections
* UVM reporting/macros

This is essentially a **UVM component skeleton** that you can later extend into a real verification environment.

---

## 2. Circuit Working & RTL Implementation

There is no DUT or RTL circuit in this example. The focus is entirely on **UVM architecture**.

### Driver

```systemverilog
class my_driver extends uvm_driver #(uvm_sequence_item);
```

The driver inherits from `uvm_driver`.

Its main purpose in a real environment will be:

```text
Sequence Item
     ↓
Sequencer
     ↓
Driver
     ↓
DUT Interface
```

Currently it only prints messages in `run_phase()`.

### Monitor

```systemverilog
class my_monitor extends uvm_monitor;
```

The monitor will eventually observe DUT signals and convert them into transactions.

Current flow:

```text
DUT Interface
     ↓
 Monitor
     ↓
Transaction
```

For now, it only prints messages.

### Environment

```systemverilog
class my_env extends uvm_env;
```

The environment creates the driver and monitor using the **UVM factory**:

```systemverilog
drv_h = my_driver::type_id::create("drv_h", this);
mon_h = my_monitor::type_id::create("mon_h", this);
```

This is important because UVM components are normally created through the factory rather than directly using `new`.

### Test

```systemverilog
class my_test extends uvm_test;
```

The test creates the environment:

```systemverilog
env_h = my_env::type_id::create("env_h", this);
```

Then `run_phase()` controls the test duration using an objection:

```systemverilog
phase.raise_objection(this);

#100;

phase.drop_objection(this);
```

This prevents the UVM simulation from ending while the test is still running.

---

## 3. Verification & Testbench

The UVM phase flow demonstrated here is:

```text
             UVM TEST
                │
         build_phase()
                │
                ▼
          ┌──────────┐
          │  my_env  │
          └────┬─────┘
               │
        ┌──────┴──────┐
        ▼             ▼
     Driver         Monitor
        │             │
   build_phase   build_phase
        │             │
        └──────┬──────┘
               ▼
        connect_phase()
               │
               ▼
          run_phase()
```

### Build phase

Used to **construct/configure components**.

Here:

```text
my_test
   ↓
my_env
   ↓
driver + monitor
```

### Connect phase

Currently only prints a message:

```systemverilog
`uvm_info("ENV",
          "connect_phase executed",
          UVM_MEDIUM);
```

Later this is where connections such as:

```text
Monitor → Scoreboard
Sequencer → Driver
```

will be established.

### Run phase

This is where time-consuming simulation activity occurs.

The driver and monitor contain:

```systemverilog
forever begin
  #10;
  ...
end
```

while the test waits for:

```systemverilog
#100;
```

### UVM reporting

The code uses:

```systemverilog
`uvm_info(...)
```

with different verbosity levels:

* `UVM_LOW`
* `UVM_MEDIUM`
* `UVM_HIGH`

And the top module enables:

```systemverilog
uvm_top.set_report_verbosity_level(UVM_HIGH);
```

Therefore, messages at `UVM_HIGH` and below can be displayed.

---

## 4. Advantages & Limitations

### Advantages

* Demonstrates basic UVM hierarchy.
* Uses `uvm_component_utils`.
* Demonstrates factory-based component creation.
* Demonstrates `build_phase()`.
* Demonstrates `connect_phase()`.
* Demonstrates `run_phase()`.
* Demonstrates objections.
* Demonstrates UVM reporting.
* Clearly separates test, environment, driver and monitor.

### Limitations

This is **not yet a functional UVM verification environment**.

Missing components include:

* ❌ Sequence item
* ❌ Sequence
* ❌ Sequencer
* ❌ Driver ↔ Sequencer connection
* ❌ Virtual interface
* ❌ Config DB
* ❌ Analysis port
* ❌ Scoreboard
* ❌ Agent
* ❌ Reference model
* ❌ Functional coverage
* ❌ Assertions
* ❌ Actual DUT

So this should be considered a **UVM Components / Hierarchy practice example**, not a complete UVM testbench.

---

## 5. Interview Takeaways

The most important concept from this example is the **UVM hierarchy and component lifecycle**:

```text
uvm_test
   ↓
uvm_env
   ↓
uvm_driver / uvm_monitor
```

And the basic phase progression introduced here:

```text
build_phase
      ↓
connect_phase
      ↓
run_phase
```

Three particularly important pieces to remember:

**1. Factory registration**

```systemverilog
`uvm_component_utils(my_driver)
```

**2. Factory creation**

```systemverilog
my_driver::type_id::create("drv_h", this);
```

**3. Objection control**

```systemverilog
phase.raise_objection(this);
...
phase.drop_objection(this);
```

This is a good **basic UVM-components example** for the repository. The next UVM code should naturally build on this by introducing the **UVM object vs component distinction and a proper `uvm_sequence_item`**, rather than jumping directly into a large UVM testbench.
