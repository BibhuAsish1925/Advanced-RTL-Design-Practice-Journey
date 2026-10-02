# 8-BIT SINE WAVE GENERATOR USING PHASE ACCUMULATOR & LUT

## 1. Circuit Overview & Applications

This design implements a **digital sine-wave generator** using a **phase accumulator and a 16-entry sine lookup table (LUT)**.

* **Phase width:** 8 bits
* **Output width:** 8-bit signed
* **LUT depth:** 16 samples
* **Phase accumulator:** 8-bit
* **Phase increment:** `phase_step`
* **Output range:** approximately `-127` to `+127`
* **Reset:** Synchronous active-high
* **Architecture:** NCO/DDS-style phase accumulator + ROM/LUT

### Applications

* Direct Digital Synthesis (DDS)
* Digital waveform generation
* Function generators
* Communications/DSP
* FPGA signal generation
* Modulation systems
* Test-signal generation

---

## 2. Circuit Working & RTL Implementation

### A. Phase Accumulator

The phase is stored in:

```systemverilog
logic [PHASE_WIDTH-1:0] phase_acc;
```

Every clock:

```systemverilog
phase_acc <= phase_acc + phase_step;
```

With the TB:

```text
phase_step = 16
```

the phase progresses:

```text
0 → 16 → 32 → 48 → 64 → ...
```

Since the accumulator is 8 bits, it naturally wraps around after `255`.

The phase increment therefore controls the output frequency:

```text
Larger phase_step → higher output frequency
Smaller phase_step → lower output frequency
```

---

### B. LUT Address

The upper four phase bits select one of the 16 LUT entries:

```systemverilog
assign lut_address = phase_acc[PHASE_WIDTH-1 -: 4];
```

For `PHASE_WIDTH=8`, this becomes:

```text
phase_acc[7:4]
```

Therefore:

```text
8-bit phase
   │
   ├── upper 4 bits ──> LUT address
   │
   └── lower 4 bits ──> phase resolution
```

There are 16 equally spaced samples covering one complete sine cycle.

---

### C. Sine LUT

The LUT contains the sampled sine values:

```text
Address     Value
  0            0
  1           49
  2           90
  3          117
  4          127
  ...
  8            0
  ...
 12         -127
  ...
 15          -49
```

The values form one complete sinusoidal cycle.

The output is registered:

```systemverilog
always_ff @(posedge clk) begin
    if (rst)
        sine_out <= '0;
    else
        sine_out <= sine_lut[lut_address];
end
```

So the architecture is:

```text
phase_step
    │
    ▼
┌──────────────┐
│Phase          │
│Accumulator    │
└──────┬───────┘
       │
       │ upper 4 bits
       ▼
┌──────────────┐
│ 16-entry LUT │
└──────┬───────┘
       │
       ▼
  Registered
   sine_out
```

---

## 3. Verification & Testbench

The testbench generates a:

```text
10 ns clock period
100 MHz clock frequency
```

It initially holds reset for two clock cycles:

```systemverilog
rst = 1'b1;
repeat (2)
    @(posedge clk);
rst = 1'b0;
```

Then it sets:

```systemverilog
phase_step = 8'd16;
```

and captures **64 output samples**.

The TB displays:

```text
Time    Phase    Sine
```

using:

```systemverilog
$display(
    "%0t\t%0d\t%0d",
    $time,
    dut.phase_acc,
    sine_out
);
```

The `#1` delay after the clock edge allows the nonblocking assignments to update before the values are displayed.

### Expected phase behavior

Because:

```text
phase_step = 16
```

and:

```text
2^8 = 256
```

the accumulator advances by:

```text
16 / 256 = 1/16
```

of a complete phase cycle per clock.

Therefore, approximately **16 clock updates correspond to one complete phase cycle**.

The LUT itself contains exactly 16 phase samples, so this configuration steps through the LUT addresses approximately as:

```text
0 → 1 → 2 → ... → 15 → 0 → ...
```

### Verification limitation

The TB is primarily **observational**. It prints phase and sine values but does not automatically compare them against expected LUT values.

A stronger TB could verify:

* Correct reset output
* Correct phase accumulation
* Correct LUT addressing
* Expected sine samples
* Phase wraparound
* Different `phase_step` values

---

## 4. Advantages & Limitations

### Advantages

* Simple and synthesizable DDS-style architecture.
* Frequency controlled digitally through `phase_step`.
* LUT avoids expensive real-time sine calculation.
* Parameterized phase and output widths.
* Phase accumulator naturally supports continuous phase wrapping.
* Suitable for FPGA/ASIC digital signal-generation applications.

### Limitations

* Only **16 LUT samples**, so the generated sine wave has relatively low amplitude/phase resolution.
* LUT storage increases with higher waveform resolution.
* Output frequency and waveform quality depend on the phase width and LUT address width.
* Current implementation uses an `initial` block to populate the LUT, which is commonly suitable for FPGA ROM initialization but may require a technology-specific ROM/memory implementation for ASIC.
* No amplitude control or output scaling is provided.

---

## 5. Interview Takeaways

**One-line explanation:**

> A phase-accumulator-based sine generator adds a programmable phase increment every clock and uses the upper phase bits to address a sine LUT, converting digital phase progression into a periodic sinusoidal waveform.

### Important equations

For an accumulator of width `N`:

```text
f_out = (phase_step × f_clk) / 2^N
```

For this design:

```text
f_clk    = 100 MHz
phase_step = 16
N        = 8

f_out = (16 × 100 MHz) / 256
      = 6.25 MHz
```

So the configured testbench is intended to generate approximately a **6.25 MHz digital sine waveform**.

### Key trade-off

```text
Higher PHASE_WIDTH
      ↓
Better frequency resolution

More LUT address bits
      ↓
More sine samples
      ↓
Better waveform fidelity
      ↓
More ROM/LUT resources
```

This is essentially a compact **DDS/NCO architecture**, which is an important digital-design and DSP concept for VLSI/FPGA interviews.
