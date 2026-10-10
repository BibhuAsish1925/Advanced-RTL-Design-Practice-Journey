# 32-BIT TRNG USING RING OSCILLATORS

## 1. Circuit Overview & Applications

This design is a **simulation-oriented True Random Number Generator (TRNG)** that uses two free-running **ring oscillators** with different numbers of inverter stages.

* **Ring oscillator 1:** 5 stages
* **Ring oscillator 2:** 3 stages
* **Entropy source:** XOR of the two oscillator outputs
* **Random word size:** 32 bits
* **Output interface:** `valid/ready` handshake
* **System clock:** `aclk`
* **Reset:** Active-low, synchronous to `aclk`
* **Simulation kick-start:** `force/release`
* **Storage:** 32-bit random-data register + 6-bit counter

### Basic architecture

```text
      5-Stage Ring Oscillator ──┐
                                XOR ──> random bit
      3-Stage Ring Oscillator ──┘
                                      │
                                      ▼
                              32-bit shift register
                                      │
                              32 bits collected
                                      │
                                      ▼
                             random_data_output
                                      │
                               valid / ready
```

### Applications

* Hardware security research
* Entropy-source experimentation
* TRNG architecture studies
* Cryptographic key/random-seed generation
* Security-oriented ASIC/FPGA research

**Important:** The RTL demonstrates the architecture, but it does **not establish that the generated sequence is cryptographically random or suitable for a production TRNG**.

---

## 2. Circuit Working & RTL Implementation

### A. Ring Oscillators

The first oscillator consists of five inverters connected in a feedback loop:

```verilog
assign #1 ring_bits5[0] = ~ring_bits5[4];
assign #1 ring_bits5[1] = ~ring_bits5[0];
assign #1 ring_bits5[2] = ~ring_bits5[1];
assign #1 ring_bits5[3] = ~ring_bits5[2];
assign #1 ring_bits5[4] = ~ring_bits5[3];
```

The second contains three stages:

```verilog
assign #1 ring_bits3[0] = ~ring_bits3[2];
assign #1 ring_bits3[1] = ~ring_bits3[0];
assign #1 ring_bits3[2] = ~ring_bits3[1];
```

The `#1` delays are important for this simulation model. Without propagation delay, the combinational feedback loops have no simulation-time delay and cannot oscillate normally.

The two oscillator outputs are:

```verilog
random_bit5 = ring_bits5[4];
random_bit3 = ring_bits3[2];
```

They are combined using:

```verilog
random_bit3 ^ random_bit5
```

to produce one bit that is shifted into the random-data register.

---

### B. Simulation Kick-Start

The following block is explicitly simulation-only:

```verilog
// synthesis translate_off
initial begin
    force ring_bits5[0] = 1'b0;
    force ring_bits3[0] = 1'b0;
    #10;
    release ring_bits5[0];
    release ring_bits3[0];
end
// synthesis translate_on
```

Its purpose is to prevent the ring oscillators from remaining at `X` indefinitely in simulation.

The comments correctly identify this as **non-synthesizable** and intended only for simulation.

---

### C. 32-Bit Random Data Collection

The main sequential logic operates from `aclk`:

```verilog
always @(posedge aclk)
```

When reset is asserted:

```verilog
random_data_reg <= 32'h0;
bit_count <= 6'd0;
random_data_valid <= 1'b0;
```

During normal operation, one XOR-derived bit is inserted every clock:

```verilog
random_data_reg <= {
    random_data_reg[30:0],
    random_bit3^random_bit5
};
```

Therefore:

```text
32-bit register
┌────────────────────────────────┐
│ old bits [30:0] │ random bit   │
└────────────────────────────────┘
```

The counter tracks how many bits have been collected.

When:

```verilog
bit_count == 6'd32
```

the design asserts:

```verilog
random_data_valid <= 1'b1;
random_data_output <= random_data_reg;
```

So the interface behaves approximately like:

```text
Collect 32 bits
      ↓
valid = 1
      ↓
consumer asserts ready
      ↓
start next collection
```

---

## 3. Verification & Testbench

The testbench generates:

```verilog
always #5 aclk = ~aclk;
```

giving:

```text
Clock period = 10 ns
Clock frequency = 100 MHz
```

### Test sequence

1. Start with `resetn = 0`.
2. Keep `random_data_ready = 0`.
3. Release reset after 12 ns.
4. Wait for `random_data_valid`.
5. Assert `random_data_ready`.
6. Allow another 32-bit word to be collected.
7. Repeat the handshake.
8. Finish the simulation.

The monitor displays:

```text
time | valid | ready | random data
```

### What the TB checks

The TB verifies the basic interface behavior:

* Reset operation
* 32-bit word collection
* `random_data_valid`
* `random_data_ready`
* Ability to begin another collection

However, the comment says:

> “confirm it differs from the first”

but the actual testbench **does not compare the first and second output words**.

So this claim is not actually verified by the current TB.

It also does not perform statistical/randomness testing such as:

* Frequency/uniformity analysis
* Autocorrelation
* Runs tests
* Entropy estimation
* NIST-style statistical testing

Those would be necessary for evaluating the quality of a TRNG entropy source.

---

## 4. Advantages & Limitations

### Advantages

* Uses physically motivated entropy-source architecture.
* Two ring oscillators provide independent-looking oscillatory signals in the simulation model.
* XOR combines the two sources.
* 32-bit output interface is simple.
* `valid/ready` handshake makes the output interface easy to integrate.
* `dont_touch` attributes indicate that the ring oscillator structures are intended to be preserved during FPGA synthesis.

### Important limitations

**1. This is not a complete production TRNG.**

The RTL does not include entropy conditioning, health tests, or statistical validation.

**2. `#1` delays are simulation constructs.**

The ring oscillator is modeled using explicit delays:

```verilog
assign #1 ...
```

This is not a normal synthesizable RTL representation of physical inverter delay.

**3. Ring oscillators are technology-dependent.**

Actual oscillator frequency and behavior depend on physical implementation, process, voltage, temperature, routing, and device characteristics.

**4. No synchronizer is used for the ring oscillator outputs.**

The oscillator signals are asynchronous relative to `aclk`. In a real implementation, the sampling architecture requires careful CDC/metastability consideration.

**5. The entropy quality is not demonstrated.**

XORing two oscillators does not by itself guarantee high-quality entropy.

**6. The TB does not actually compare two generated words.**

The comment describes such a check, but no comparison exists in the code.

---

## 5. Interview Takeaways

**One-line explanation:**

> This design models a 32-bit TRNG by sampling the XOR of two free-running ring oscillators and collecting the resulting bits into a 32-bit output word using a valid/ready interface.

### Key concepts to remember

* **Ring oscillator:** odd number of inverting stages creates oscillation.
* **Entropy source:** physical oscillator behavior can contain process/thermal/environmental variations.
* **Sampling:** asynchronous oscillator signals are sampled using `aclk`.
* **XOR:** combines the two oscillator outputs.
* **Bit accumulation:** 32 sampled bits form one output word.
* **Handshake:** `valid` indicates available data; `ready` acknowledges consumption.

### Important interview distinction

Your earlier **LFSR/PRNG** designs are deterministic:

```text
Seed → deterministic state transition → deterministic sequence
```

This design attempts to obtain entropy from a **physical oscillator source**:

```text
Physical variation/noise → oscillator behavior → sampling → random bits
```

Therefore, an LFSR is appropriate for **pseudo-random pattern generation**, while a TRNG attempts to provide **physical entropy**.
