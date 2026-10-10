## 1. Circuit Overview & Applications

This is a **complete UVM verification environment for an APB-connected 32-bit × 32-word RAM**.

The DUT combines:

* **APB-style interface**
* 32 memory locations
* 32-bit data width
* Read/write operations
* Reset handling
* Invalid-address error handling through `PSLVERR`

The verification architecture is:

```text
                         APB TEST
                            │
                     ┌──────┴──────┐
                     │   Sequences │
                     └──────┬──────┘
                            │
                        Sequencer
                            │
                         Driver
                            │
                       APB Interface
                            │
                         APB RAM
                            │
                       APB Interface
                            │
                         Monitor
                            │
                     Analysis Port
                            │
                       Scoreboard
                            │
                    Reference Memory
```

The transaction model supports **READ, WRITE, and RESET** operations. 

---

## 2. Circuit Working & UVM Implementation

### DUT: APB RAM

The RAM contains:

```systemverilog
reg [31:0] mem [32];
```

So the memory is:

```text
32 locations × 32 bits
```

The DUT uses a state machine:

```text
IDLE → SETUP → ACCESS → TRANSFER → SETUP
```

The important APB operation occurs in the `ACCESS` state.

### Write

For a valid write:

```text
PSEL = 1
PENABLE = 1
PWRITE = 1
```

The DUT performs:

```text
mem[paddr] ← pwdata
```

For an invalid address (`paddr >= 32`), it asserts:

```text
PSLVERR = 1
```

### Read

For a valid read:

```text
PSEL = 1
PENABLE = 1
PWRITE = 0
```

The DUT returns:

```text
PRDATA = mem[paddr]
```

For an invalid address, it returns an `X` value and asserts `PSLVERR`.

### Reset

When:

```text
PRESETN = 0
```

the DUT:

* Returns to `IDLE`
* Clears `PRDATA`
* Clears `PREADY`
* Clears `PSLVERR`
* Clears all 32 memory locations

---

### APB Configuration

The configuration object contains:

```systemverilog
uvm_active_passive_enum is_active = UVM_ACTIVE;
```

This is an important UVM concept because it allows the agent to be configured as either:

```text
ACTIVE  → Driver + Sequencer + Monitor
PASSIVE → Monitor only
```

The agent uses this configuration when creating the driver and sequencer. 

---

### Transaction

`apb_transaction` represents one APB operation.

It contains:

```text
PADDR
PWDATA
PWRITE
OP
PREADY
PSLVERR
PRDATA
```

The operation type is:

```text
APB_READ
APB_WRITE
APB_RESET
```

The transaction also demonstrates **constraint-mode control**:

```systemverilog
valid_addr_c
invalid_addr_c
```

Valid transactions constrain:

```text
PADDR = 0–31
```

while error transactions constrain:

```text
PADDR > 31
```

This is a good practical example of dynamically enabling/disabling constraints. 

---

## 3. Verification & Testbench

### Sequences

This example is much more advanced than the previous adder environment because it contains **multiple directed/randomized sequences**.

You have:

| Sequence               | Purpose                        |
| ---------------------- | ------------------------------ |
| `apb_write_seq`        | 15 valid writes                |
| `apb_read_seq`         | 15 valid reads                 |
| `apb_write_read_seq`   | Write followed by read         |
| `apb_writeb_readb_seq` | 15 writes followed by 15 reads |
| `apb_write_err_seq`    | Invalid-address writes         |
| `apb_read_err_seq`     | Invalid-address reads          |
| `apb_reset_seq`        | Reset operations               |

The default test currently executes:

```systemverilog
bulk_seq.start(env.agent.seqr);
```

so the active test is:

```text
15 WRITE transactions
        ↓
15 READ transactions
```

This is explicitly how the supplied test is configured. 

---

### Driver

The driver obtains the virtual interface through `uvm_config_db`.

It then implements the APB transaction timing:

```text
WRITE / READ

SETUP
  PSEL = 1
  PENABLE = 0
       ↓
ACCESS
  PENABLE = 1
       ↓
TRANSFER COMPLETE
  PREADY
       ↓
Finish transaction
```

The driver also contains a separate `reset_dut()` task and handles reset transactions. 

This is an important step up from your previous adder driver because the driver is now **protocol-aware**.

---

### Monitor

The monitor observes the APB interface on every positive clock edge.

It identifies:

```text
RESET
WRITE
READ
```

and creates corresponding transactions.

For completed transfers, it captures:

```text
PREADY
PSLVERR
PRDATA
```

and sends the transaction through:

```systemverilog
send.write(...)
```

So:

```text
APB Interface
      ↓
   Monitor
      ↓
Analysis Port
      ↓
 Scoreboard
```

The monitor implementation is shown in the supplied source. 

---

### Scoreboard

This is one of the most important parts of the project.

The scoreboard maintains its own:

```systemverilog
bit [31:0] reference_mem [32];
```

This acts as a **reference model** for the DUT memory. 

For a successful write:

```text
reference_mem[address] = write_data
```

For a successful read:

```text
reference_mem[address] == PRDATA
```

Therefore:

```text
                 WRITE
                   ↓
             Reference RAM
                   ↓
                 READ
                   ↓
       Expected data = reference_mem[address]
                   ↓
             Compare PRDATA
```

This is much closer to an industry-style memory scoreboard than the simple `expected = a+b` checker in your previous adder example.

Reset also clears the reference memory so that the reference model stays synchronized with the DUT. 

---

### Agent

The APB agent contains:

```text
apb_agent
├── monitor
├── driver
└── sequencer
```

when configured as `UVM_ACTIVE`.

The connection is:

```text
Sequence
   ↓
Sequencer
   ↓
Driver
   ↓
APB DUT
```

The monitor remains present in both active and passive modes. 

---

### Environment

The environment contains:

```text
apb_env
├── agent
└── scoreboard
```

and connects:

```systemverilog
agent.mon.send.connect(scoreboard.recv);
```

Therefore:

```text
Monitor → Analysis Port → Scoreboard
```

This follows the standard UVM verification architecture. 

---

## 4. Advantages & Limitations

### Advantages

This is a **strong UVM practice project** because it demonstrates:

* ✅ APB-style protocol verification
* ✅ UVM transaction
* ✅ Multiple sequences
* ✅ Constraint randomization
* ✅ `constraint_mode()`
* ✅ Active/passive agent configuration
* ✅ Virtual interface
* ✅ `uvm_config_db`
* ✅ Protocol-aware driver
* ✅ Passive monitor
* ✅ Analysis port
* ✅ Reference-memory scoreboard
* ✅ Error-response testing
* ✅ Reset testing
* ✅ Factory-based object/component creation
* ✅ UVM objections
* ✅ Clock generation
* ✅ VCD waveform dumping

### Limitations / things to notice

There are a few areas that are still suitable for later improvement:

1. **No functional coverage** is present.
2. **No SVA assertions** are present.
3. The scoreboard reports data mismatches, but there is no explicit accumulated **pass/fail counter**.
4. The APB implementation is an educational/custom model rather than a complete production APB VIP.
5. The driver/monitor synchronization uses `@(posedge)` and `@(negedge pready)` rather than a dedicated **clocking block**.
6. The test creates all seven sequences, but only `bulk_seq` is currently executed by default. 

One particularly useful next improvement would therefore be **functional coverage + assertions**, because the basic UVM architecture is already quite complete.

---

## 5. Interview Takeaways

### Q1. Why does the scoreboard need a reference memory?

Because the DUT itself is a memory. The scoreboard needs an independent model to determine what data **should** be returned during a read.

### Q2. Why are there separate valid and invalid address constraints?

To deliberately generate both:

```text
valid → 0–31
invalid → >31
```

and verify the DUT's `PSLVERR` behavior. 

### Q3. Why use an active/passive agent?

It makes the verification component reusable.

```text
ACTIVE  → drive + monitor
PASSIVE → monitor only
```

### Q4. What is the role of `uvm_config_db` here?

It passes the APB virtual interface from the top-level testbench to the driver and monitor.

### Q5. What is the main scoreboard check?

```text
Expected = reference_mem[PADDR]
Actual   = PRDATA
```

Then:

```text
Expected == Actual → PASS
Expected != Actual → ERROR
```

### Q6. What is the major difference from your previous 4-bit adder UVM project?

The adder had:

```text
single mathematical operation
```

while this project verifies a **protocol-driven stateful DUT**:

```text
Sequence
   ↓
APB protocol
   ↓
Memory state
   ↓
Readback
   ↓
Reference-model comparison
```

That makes this a considerably better **industry-oriented UVM practice example**.

### Repo status

✅ **APB RAM UVM Verification — DONE**

This example effectively combines the UVM concepts you've been building toward: **transaction → constraints → multiple sequences → sequencer → protocol-aware driver → monitor → analysis port → reference-model scoreboard → active/passive agent → environment → test → config DB**.
