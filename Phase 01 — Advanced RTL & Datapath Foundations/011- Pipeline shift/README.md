# PARAMETERIZED PIPELINE SHIFT REGISTER

=================================

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This design implements a **parameterized pipeline/shift register** containing `N` flip-flop stages.

For the default:

```verilog
parameter N = 15;
```

the circuit contains **15 sequential stages**:

```text
a → FF0 → FF1 → FF2 → FF3 → ... → FF14 → y
```

At every positive clock edge, the input data moves forward by one stage.

Applications include:

* Pipeline delay elements
* Data synchronization pipelines
* Serial data movement
* Digital signal-processing pipelines
* Configurable latency generation
* Timing alignment between datapath signals

---

# 2. HOW THE CIRCUIT WORKS

The pipeline storage is:

```verilog
reg [N-1:0] temp;
```

For `N=15`:

```text
temp[14:0]
```

The first stage captures the input:

```verilog
always @(posedge clk) begin
    temp[0] <= a;
end
```

The remaining stages are generated automatically:

```verilog
for (i = 1; i < N; i = i + 1)
begin
    always @(posedge clk) begin
        temp[i] <= temp[i-1];
    end
end
```

So the hardware becomes:

```text
        ┌────┐   ┌────┐   ┌────┐                 ┌─────┐
a ────► │ FF0│──►│ FF1│──►│ FF2│──► ... ───────►│ FF14│──► y
        └────┘   └────┘   └────┘                 └─────┘
           ▲        ▲        ▲                       ▲
           └────────────── CLK ─────────────────────┘
```

Because all assignments are **non-blocking (`<=`)**, the stages shift simultaneously.

For example, if:

```text
Before clock:
temp = 000000000000000
a    = 1
```

After one rising edge:

```text
temp[0] = 1
```

After the next rising edge:

```text
temp[1] = 1
```

and so on.

---

# 3. OUTPUT

The output is:

```verilog
assign y = temp[N-1];
```

For `N=15`:

```verilog
assign y = temp[14];
```

Therefore, a value applied at `a` propagates through the pipeline until it reaches `y`.

Conceptually:

```text
Clock edge       Data position
--------------------------------
1                FF0
2                FF1
3                FF2
...
15               FF14 → y
```

So the design provides approximately **15 clock cycles of pipeline latency** from the input to the output.

---

# 4. WHY `generate` IS USED

The design could manually instantiate 15 flip-flops, but that would be repetitive.

Instead:

```verilog
genvar i;

generate
    begin
        for (i = 1; i < N; i = i + 1)
```

creates the required stages automatically.

For:

```verilog
N = 15
```

the loop generates:

```text
temp[1] <= temp[0]
temp[2] <= temp[1]
temp[3] <= temp[2]
...
temp[14] <= temp[13]
```

If you change:

```verilog
.N(15)
```

to:

```verilog
.N(8)
```

the same RTL becomes an 8-stage pipeline.

This is the main benefit of parameterization.

---

# 5. TESTBENCH

The testbench instantiates the DUT with:

```verilog
pipeline_shift #(
    .N(15)
) dut (
    .clk(clk),
    .a(a),
    .y(y)
);
```

So the pipeline has 15 stages.

### Clock

```verilog
always #5 clk = ~clk;
```

The clock changes every 5 ns:

```text
Clock period = 10 ns
Frequency    = 100 MHz
```

Positive edges occur at:

```text
5 ns, 15 ns, 25 ns, 35 ns, ...
```

---

# 6. INPUT STIMULUS

The testbench applies:

```verilog
clk = 0;
a = 0;

#10 a = 1;
#20 a = 0;
#30 a = 1;
#40 a = 0;
#50 $finish;
```

So `a` changes at:

```text
t=0   → 0
t=10  → 1
t=30  → 0
t=60  → 1
t=100 → 0
t=150 → finish
```

The input pattern is therefore shifted through the pipeline.

---

# 7. MONITOR

The testbench contains:

```verilog
always @(posedge clk) begin
    $display("At time %t, y = %b", $time, y);
end
```

This prints `y` at every positive clock edge.

### Important simulation detail

Because the DUT uses non-blocking assignments:

```verilog
temp[i] <= temp[i-1];
```

the `$display` block and DUT sequential blocks execute in the same simulation time step.

Therefore, the displayed `y` can represent the **pre-clock-update value** rather than the newly shifted value.

For simply observing the pipeline, this is generally okay, but for precise verification a small sampling delay or clocking block is preferable.

---

# 8. IMPORTANT BEHAVIOR OF THIS TESTBENCH

There is a significant timing point in the stimulus.

The pipeline has:

```text
N = 15 stages
```

but the input changes relatively quickly:

```text
0 → 1 at 10 ns
1 → 0 at 30 ns
0 → 1 at 60 ns
1 → 0 at 100 ns
```

Each input transition therefore takes about **15 clock cycles** to reach `y`.

For a 100 MHz clock:

```text
15 cycles × 10 ns = 150 ns
```

The simulation ends at:

```text
150 ns
```

So the final input transition does not have enough time to fully propagate to the output before `$finish`.

This is expected behavior, not a DUT error.

---

# 9. ADVANTAGES & LIMITATIONS

### Advantages

* Parameterized pipeline depth.
* Simple synthesizable RTL.
* Uses non-blocking assignments correctly.
* Generate loop makes the design scalable.
* Useful for creating controlled latency.
* Each stage can help break a long combinational path in a larger datapath.

### Limitations

* Requires `N` flip-flops.
* Larger `N` means greater area and clock power.
* Introduces `N` cycles of latency.
* Current testbench does not automatically perform PASS/FAIL checking.
* There is no reset in the design, so `temp` can initially contain `X` values in simulation until enough clock cycles have shifted known data through the pipeline.

---

# 10. IMPORTANT DIFFERENCE FROM THE PREVIOUS REGISTER EXAMPLE

Your previous `Parameterised_Register` had:

```verilog
input rst
```

and asynchronously cleared the pipeline.

This `pipeline_shift` has **no reset**.

Therefore, at simulation start:

```text
temp = XXXXX...
```

Initially:

```text
y = X
```

until the pipeline becomes filled with known values.

For example, after enough `a=0` clock cycles, all stages eventually become:

```text
000000000000000
```

and:

```text
y = 0
```

---

# 11. INTERVIEW TAKEAWAY

**Question: What does this circuit implement?**

> It implements a parameterized N-stage pipeline shift register. The input is captured into the first flip-flop on each rising clock edge and propagates one stage per clock cycle until reaching the output.

**Question: Why use non-blocking assignments?**

> Non-blocking assignments ensure all pipeline stages update simultaneously using the previous clock-cycle values.

**Question: What determines the latency?**

> The parameter `N` determines the number of sequential stages and therefore the pipeline latency.

### Core concept

```text
a
│
▼
FF0 → FF1 → FF2 → ... → FF(N-1)
                              │
                              ▼
                              y
```

For this implementation:

```text
N = 15
Clock = 100 MHz
Pipeline depth = 15 stages
Approx. latency = 15 clock cycles = 150 ns
```

This is a good example of **parameterized sequential RTL, generate constructs, pipeline latency, and non-blocking assignment behavior**.
