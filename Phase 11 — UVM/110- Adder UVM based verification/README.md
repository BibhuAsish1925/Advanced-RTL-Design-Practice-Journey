## 1. Circuit Overview & Applications

This is a **complete UVM-based functional verification environment for a 4-bit adder**.

The DUT is:

```text
4-bit A ──┐
          ├──► 4-bit Adder ──► 5-bit Y
4-bit B ──┘
```

The verification architecture is:

```text
              UVM TEST
                 │
            Generator
                 │
             Sequencer
                 │
              Driver
                 │
            Virtual IF
                 │
                DUT
                 │
            Virtual IF
                 │
              Monitor
                 │
          Analysis Port
                 │
             Scoreboard
```

This is an important milestone because it combines the major UVM components you've learned so far into one working environment.

---

## 2. Circuit Working & UVM Implementation

### DUT

```systemverilog
assign y = a + b;
```

Two 4-bit inputs produce a 5-bit result, allowing the carry bit to be retained.

For example:

```text
a = 15
b = 15
y = 30
```

### Interface

`add_if` provides the connection between the DUT and UVM testbench:

```text
a[3:0]
b[3:0]
y[4:0]
```

The UVM driver and monitor access this interface through a **virtual interface**.

---

### Transaction

```systemverilog
class transaction extends uvm_sequence_item;
```

The transaction represents one adder operation:

```text
a + b → y
```

`a` and `b` are randomized, while `y` is observed from the DUT.

The field macros allow UVM automation such as printing:

```systemverilog
`uvm_field_int(a, UVM_DEFAULT)
`uvm_field_int(b, UVM_DEFAULT)
`uvm_field_int(y, UVM_DEFAULT)
```

---

### Generator / Sequence

```systemverilog
class generator extends uvm_sequence #(transaction);
```

The sequence generates **10 randomized transactions**.

The standard sequence flow is correctly demonstrated:

```text
create transaction
      ↓
start_item()
      ↓
randomize()
      ↓
finish_item()
```

This transaction is then delivered by the sequencer to the driver.

---

### Driver

The driver gets transactions through:

```systemverilog
seq_item_port.get_next_item(tc);
```

and drives them onto the DUT interface:

```systemverilog
aif.a <= tc.a;
aif.b <= tc.b;
```

After allowing the DUT/monitor to process the transaction:

```systemverilog
#10;
```

it calls:

```systemverilog
seq_item_port.item_done();
```

So the driver follows the correct **sequencer → driver handshake**.

---

### Monitor

The monitor is passive; it does not drive the DUT.

It samples:

```systemverilog
t.a = aif.a;
t.b = aif.b;
t.y = aif.y;
```

and sends the transaction through:

```systemverilog
send.write(t);
```

This is the UVM **analysis port** mechanism.

---

### Scoreboard

The scoreboard receives transactions through:

```systemverilog
uvm_analysis_imp #(transaction, scoreboard) recv;
```

The monitor connects to it using:

```systemverilog
a.m.send.connect(s.recv);
```

The checking logic is:

```text
Expected = a + b
Actual   = y
```

If they match:

```text
TEST PASSED
```

Otherwise:

```text
TEST FAILED
```

This is a basic **reference-model-based checking mechanism**.

---

### Agent

The agent packages the active verification components:

```text
agent
├── monitor
├── driver
└── sequencer
```

The critical connection is:

```systemverilog
d.seq_item_port.connect(seqr.seq_item_export);
```

This creates:

```text
Sequence → Sequencer → Driver
```

---

### Environment

The environment contains:

```text
env
├── agent
└── scoreboard
```

and connects:

```systemverilog
a.m.send.connect(s.recv);
```

Therefore:

```text
Monitor → Analysis Port → Scoreboard
```

---

### Test

The test creates the environment and generator:

```text
test
├── generator
└── env
    ├── agent
    └── scoreboard
```

It raises an objection:

```systemverilog
phase.raise_objection(this);
```

starts the sequence:

```systemverilog
gen.start(e.a.seqr);
```

and finally drops the objection:

```systemverilog
phase.drop_objection(this);
```

This prevents the UVM run phase from terminating before the test completes.

---

## 3. Verification & Testbench

The virtual interface is configured using `uvm_config_db`:

```systemverilog
uvm_config_db #(virtual add_if)::set(
    null,
    "uvm_test_top.e.a*",
    "aif",
    aif
);
```

This allows the driver and monitor under the agent hierarchy to retrieve the interface.

The overall data flow is:

```text
Random Transaction
       ↓
   Generator
       ↓
   Sequencer
       ↓
     Driver
       ↓
  Virtual Interface
       ↓
      4-bit
      Adder
       ↓
  Virtual Interface
       ↓
     Monitor
       ↓
 Analysis Port
       ↓
   Scoreboard
       ↓
Expected vs Actual
```

### VCD

The testbench also generates:

```text
dump.vcd
```

using:

```systemverilog
$dumpfile("dump.vcd");
$dumpvars(0, adder_tb);
```

This allows waveform inspection in **GTKWave**.

---

## 4. Advantages & Limitations

### Advantages

* Complete UVM verification architecture.
* Uses `uvm_sequence_item`.
* Uses sequence + sequencer + driver.
* Uses virtual interface.
* Uses `uvm_config_db`.
* Uses monitor + analysis port.
* Uses scoreboard-based checking.
* Uses agent and environment hierarchy.
* Uses UVM objections.
* Uses factory-based component/object creation.
* Generates randomized stimulus.
* Supports waveform debugging.

### Limitations / Important Improvement Areas

The environment is functional, but it is still a **basic educational UVM testbench**.

The biggest limitation is the timing model:

```systemverilog
#10;
```

Both driver and monitor use fixed delays rather than a clocking/event-based synchronization mechanism.

For a more industry-style environment, you would eventually replace this with:

* Clocking block
* Proper synchronous interface
* Transaction timing
* Assertions/SVA
* Functional coverage
* Better scoreboard/reference model
* Pass/fail counters
* Multiple sequences
* Directed boundary tests

For this particular adder, useful directed cases would include:

```text
0 + 0
0 + 15
15 + 0
15 + 15
8 + 8
7 + 8
```

especially `15 + 15`, because it verifies the 5-bit carry output.

---

## 5. Interview Takeaways

**Q: What is the role of the sequence?**
A: Generates transaction-level stimulus.

**Q: What does the sequencer do?**
A: Arbitrates and delivers sequence items from sequences to the driver.

**Q: What does the driver do?**
A: Converts transaction-level data into DUT pin/interface activity.

**Q: What does the monitor do?**
A: Passively observes DUT activity and converts it back into transactions.

**Q: Why use an analysis port?**
A: To broadcast monitored transactions to components such as scoreboards or coverage collectors without tightly coupling them.

**Q: Why use `uvm_analysis_imp` in the scoreboard?**
A: It provides the implementation of the `write()` method that receives transactions from the monitor.

**Q: Why is `uvm_config_db` used?**
A: To pass configuration information—in this case the virtual interface—from the top-level testbench into UVM components.

**Q: Why use `raise_objection()` and `drop_objection()`?**
A: To control when the UVM run phase is allowed to end.

### Most important hierarchy to remember

```text
uvm_test
   │
   └── env
        │
        ├── agent
        │    ├── sequencer
        │    ├── driver
        │    └── monitor
        │
        └── scoreboard
```

And the two critical data paths are:

```text
STIMULUS:
Sequence → Sequencer → Driver → DUT
```

```text
CHECKING:
DUT → Monitor → Analysis Port → Scoreboard
```

### Repo status

✅ **Complete basic UVM verification environment — DONE**

This example is significantly more important than the previous individual UVM component examples because it brings together **Sequence Item → Sequence → Sequencer → Driver → Monitor → Scoreboard → Agent → Environment → Test → Virtual Interface → Config DB → Objections** in one complete flow.
