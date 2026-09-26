# PRIORITY RESOLVER / PRIORITY ARBITER

1. CIRCUIT OVERVIEW & APPLICATIONS

---

This RTL implements a 4-request priority resolver using a finite-state machine (FSM).

Inputs:

* req_a, req_b, req_c, req_d : Four request signals
* clk                        : Clock
* rst                        : Synchronous active-high reset

Outputs:

* gnt_a, gnt_b, gnt_c, gnt_d : Grant signals

Priority:
req_a > req_b > req_c > req_d

If multiple requests are active, the highest-priority request is granted.

The resolver remembers the currently granted requester. While that requester
continues asserting its request, the grant remains active. When the request
is released, the FSM returns to IDLE and selects the next active request.

Applications:

* Bus arbitration
* Shared-memory access
* DMA controllers
* Peripheral arbitration
* Multi-master interconnects
* Resource-sharing control logic

2. FSM ARCHITECTURE & WORKING

---

The design contains five states:

IDLE  = 000
GNTa  = 001
GNTb  = 010
GNTc  = 011
GNTd  = 100

Basic state flow:

```
              req_a
          +----------+
          |          v
        IDLE -----> GNTa
          |          |
          |          | req_a
          |          +----+
          |               |
          |          req_a=0
          |               |
          |               v
          +---------- IDLE
```

From IDLE:

if req_a = 1 -> GNTa
else if req_b = 1 -> GNTb
else if req_c = 1 -> GNTc
else if req_d = 1 -> GNTd
else -> IDLE

Therefore, A has the highest priority and D has the lowest.

3. RTL IMPLEMENTATION

---

The RTL uses the standard FSM structure:

p_s = present state
n_s = next state

There are three major sections.

A. STATE REGISTER

```verilog
always @ (posedge clk)
begin
    if(rst)
        p_s=idle;
    else
        p_s=n_s;
end
```

At every rising clock edge:

rst = 1 -> state becomes IDLE
rst = 0 -> present state becomes next state

This stores the FSM state in flip-flops.

NOTE:
The code uses blocking assignment (`=`) in the sequential block.
For synthesizable sequential RTL, nonblocking assignment (`<=`) is normally
preferred:

```verilog
p_s <= idle;
p_s <= n_s;
```

B. NEXT-STATE LOGIC

```verilog
always @ (p_s,req_a,req_b,req_c,req_d)
```

This block determines the next FSM state.

For IDLE:

```verilog
if(req_a)
    n_s=GNTa;
else if(req_b)
    n_s=GNTb;
else if(req_c)
    n_s=GNTc;
else if(req_d)
    n_s=GNTd;
else
    n_s=idle;
```

The `if-else if` ordering implements the priority:

A > B > C > D

For example:

req_a = 1
req_b = 1
req_c = 0
req_d = 1

The FSM selects:

GNTa

because `req_a` is checked first.

Once in GNTa:

```verilog
if(req_a)
    n_s=GNTa;
else
    n_s=idle;
```

So the grant remains with A as long as A keeps requesting.

The same behavior exists for B, C and D.

C. OUTPUT LOGIC

The final `always` block decodes the current state into grant signals.

For example:

```verilog
else if(p_s==GNTb)
begin
    gnt_a=0;
    gnt_b=1;
    gnt_c=0;
    gnt_d=0;
end
```

Therefore, only one grant can be active for each valid FSM state.

State/output relationship:

IDLE -> 0000
GNTa -> 1000
GNTb -> 0100
GNTc -> 0010
GNTd -> 0001

This is a Moore FSM because the outputs depend only on the current state.

4. TESTBENCH ANALYSIS

---

The testbench creates:

* Clock
* Reset
* Four random request signals
* DUT instance

Initial conditions:

```verilog
rst=1'b1;
clk=1'b0;
req_a=1'b0;
req_b=1'b0;
req_c=1'b0;
req_d=1'b0;
```

Reset remains active for 100 time units:

```verilog
#100;
rst=1'b0;
```

The clock is generated using:

```verilog
always
begin
    #5 clk=~clk;
```

Therefore:

Half period = 5 time units
Full period = 10 time units

5. RANDOM REQUEST GENERATION

---

The testbench generates random requests:

```verilog
req_a=$random;
req_b=$random;
req_c=$random;
req_d=$random;
```

Since each request is one bit, the generated value is effectively reduced to
a 0/1 value.

However, the requests are generated inside the same `always` block that
toggles the clock:

```verilog
#5 clk=~clk;
req_a=$random;
...
```

So the request signals change immediately after every clock toggle.

This provides random stimulus, but the testbench does not contain an explicit
checker or PASS/FAIL mechanism.

6. IMPORTANT TESTBENCH ISSUE

---

The testbench has no `$finish`.

Therefore, after reset is released, this block:

```verilog
always
begin
    ...
end
```

runs forever.

Simulation must be manually stopped or a `$finish` statement should be added.

Also, there is no `$monitor`, `$display`, scoreboard, or assertion, so the
testbench mainly generates stimulus rather than automatically verifying the
priority behavior.

A better verification strategy would explicitly check:

If req_a = 1 -> gnt_a should eventually be selected
Else if req_b = 1 -> gnt_b
Else if req_c = 1 -> gnt_c
Else if req_d = 1 -> gnt_d
Else -> no grant

and verify that:

gnt_a + gnt_b + gnt_c + gnt_d <= 1

7. ADVANTAGES

---

* Simple FSM-based implementation
* Clear priority structure
* Supports four independent requesters
* Only one grant is generated at a time
* Easy to extend to additional requesters
* Synthesizable RTL
* Useful for bus/resource arbitration
* State-based grant persistence prevents changing grants while the current
  requester continues asserting its request

8. LIMITATIONS

---

* Fixed priority can cause starvation of lower-priority requesters.

Example:

If req_a remains continuously HIGH, GNTa remains active and B/C/D cannot
receive the resource.

* Priority is not fair.
* More requesters increase priority logic complexity.
* The supplied testbench does not automatically verify correctness.
* The sequential block uses blocking assignments instead of the conventional
  nonblocking assignments.
* The combinational sensitivity list is written manually; `always @(*)` would
  be safer and clearer.
* There is no explicit `default` state recovery in the FSM case statement.

9. INTERVIEW TAKEAWAYS

---

Key concept:
4-request fixed-priority FSM-based arbiter.

Priority:
A > B > C > D

FSM type:
Moore FSM.

Main architecture:
Requests -> Next-State Logic -> State Register -> Output Decoder

Important trade-off:
Fixed priority provides simple and fast arbitration but can cause starvation
of lower-priority requesters.

One-line interview explanation:

"This design implements a four-request fixed-priority arbiter using a Moore FSM,
where request A has the highest priority and the current grant is maintained
until that request is released."
