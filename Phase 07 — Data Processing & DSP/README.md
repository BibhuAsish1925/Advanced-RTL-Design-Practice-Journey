# Phase 07 — Data Processing & DSP

## Overview

This phase focuses on **digital data processing and Digital Signal Processing (DSP)** using RTL design techniques. It covers waveform generation, pulse-width modulation, multiply-accumulate architectures, digital filtering, convolution, fixed-point arithmetic, and accelerator-oriented datapaths.

The designs progress from fundamental signal-generation concepts to computationally intensive structures such as pipelined MAC units and a TPU accelerator. Together, these topics provide a foundation for understanding how mathematical operations and signal-processing algorithms can be represented as hardware.

The phase also introduces important hardware-design considerations, including arithmetic precision, datapath organization, pipeline latency, throughput, and resource usage.

## Topics Covered

| No. | Topic | Description |
|---|---|---|
| 071 | Pulse Width Modulation (PWM) | Digital generation of pulse signals with a controllable duty cycle. |
| 072 | Sine-Wave Generator | Generation of digital values representing a sine waveform. |
| 073 | MAC Unit | Multiply-Accumulate unit that performs multiplication and accumulation operations. |
| 074 | Pipelined MAC | Pipelined implementation of a multiply-accumulate datapath to explore latency and throughput. |
| 075 | Digital Convolution | Hardware implementation of convolution operations used in digital signal processing. |
| 076 | Moving Average Filter | Filtering structure that averages a sequence of input samples. |
| 077 | FIR Filter | Finite Impulse Response filter architecture for processing digital signals. |
| 078 | Fixed-Point DSP | DSP operations using fixed-point numerical representation. |
| 079 | TPU Accelerator | Hardware accelerator design associated with tensor-processing workloads. |

## Technical Areas Explored

### 1. Pulse Width Modulation (PWM)

PWM represents a control signal using a periodic digital waveform whose duty cycle can be varied.

Key concepts include:

- Counter-based waveform generation.
- Period and frequency control.
- Duty-cycle adjustment.
- Threshold comparison and output control.
- Timing relationships between the clock and generated waveform.

PWM is widely used in digital control systems, power-control interfaces, motor control, and LED brightness control. Actual switching frequency and duty-cycle resolution depend on the design parameters and implementation.

### 2. Sine-Wave Generation

A digital sine-wave generator produces a sequence of digital sample values corresponding to a sinusoidal waveform.

Depending on the implementation, this may use a lookup table, phase accumulator, arithmetic approximation, or another sample-generation method.

Key concepts include:

- Digital waveform representation.
- Sample sequencing.
- Phase and frequency control.
- Amplitude representation.
- Lookup-table-based generation.
- Numerical precision and waveform resolution.

The quality of the generated waveform depends on the implementation method, sample resolution, amplitude precision, and output update rate.

### 3. Multiply-Accumulate (MAC) Unit

A MAC unit combines multiplication and accumulation into a computational datapath. It is a fundamental building block in many DSP and machine-learning workloads.

Key concepts include:

- Multiplication of input operands.
- Accumulation of product values.
- Register-based or combinational datapath organization.
- Operand and accumulator widths.
- Signed and unsigned arithmetic.
- Overflow and truncation considerations.

MAC units are commonly used in digital filters, convolution engines, matrix computations, and neural-network processing.

### 4. Pipelined MAC

A pipelined MAC introduces registers between computational stages to divide a datapath into smaller timing stages.

Key concepts include:

- Pipeline-stage organization.
- Register placement.
- Clock-cycle latency.
- Throughput and initiation interval.
- Data alignment across stages.
- Timing-path considerations.

Pipelining can improve achievable clock frequency by reducing the amount of combinational logic between registers. However, it generally introduces additional latency and register overhead. The actual benefit depends on stage balancing, control logic, and synthesis results.

### 5. Digital Convolution

Convolution is a mathematical operation used to combine input samples with a set of coefficients. It forms the basis of many digital filters and signal-processing algorithms.

Key concepts include:

- Input-sample sequences.
- Coefficient storage and access.
- Multiplication and accumulation.
- Sample delay and alignment.
- Arithmetic precision.
- Sequential or parallel computation.

A direct hardware implementation may use multiple multipliers and adders, while resource-constrained designs may reuse arithmetic units across multiple cycles.

### 6. Moving Average Filter

A moving average filter smooths a sequence of input samples by calculating the average over a defined window.

Key concepts include:

- Sample-window management.
- Running-sum calculation.
- Addition and division or scaling.
- Storage of previous samples.
- Output latency and initialization behavior.
- Numerical precision.

An efficient implementation can maintain a running sum by adding each new sample and removing the sample that leaves the window. The required storage and arithmetic depend on the window length and input representation.

### 7. Finite Impulse Response (FIR) Filter

An FIR filter produces an output using a finite set of input samples and filter coefficients. Its structure commonly consists of delay elements, multipliers, and an adder network.

Key concepts include:

- Delay-line organization.
- Coefficient representation.
- Multiply-accumulate operations.
- Filter order and tap count.
- Accumulator width.
- Pipeline placement and timing.

FIR filters are used in applications such as noise reduction, signal conditioning, and digital communications. Filter response depends on the selected coefficients and implementation.

### 8. Fixed-Point DSP

Fixed-point arithmetic represents fractional and integer values using a fixed binary-point position. It is frequently used in hardware datapaths where predictable resource usage and arithmetic behavior are important.

Key concepts include:

- Signed and unsigned representations.
- Integer and fractional bits.
- Scaling and binary-point placement.
- Multiplication and accumulation precision.
- Rounding and truncation.
- Overflow and saturation considerations.

Correct fixed-point design requires tracking the numerical format of every intermediate result. Incorrect scaling or insufficient width can produce significant numerical errors even when the RTL is functionally consistent at the bit level.

### 9. TPU Accelerator

A Tensor Processing Unit (TPU) is associated with specialized hardware for tensor and machine-learning computations. Accelerator datapaths commonly rely on arithmetic units, data movement structures, control logic, and memory organization.

Key concepts relevant to this topic include:

- Computational datapath organization.
- Multiply-accumulate operations.
- Parallel arithmetic processing.
- Data reuse and buffering.
- Pipeline design.
- Fixed-point or other reduced-precision arithmetic.
- Throughput and resource considerations.

The exact architecture and supported operations of the listed TPU accelerator depend on its RTL implementation; the directory name alone does not establish whether it includes a complete tensor-processing architecture.

## Design and Verification Methodology

The following workflow can be used to study and evaluate the designs in this phase:

1. **Understand the mathematical operation:** Identify the required waveform, arithmetic function, filter equation, or processing sequence.
2. **Define numerical formats:** Specify operand widths, signedness, fixed-point scaling, and expected output width where applicable.
3. **Review the RTL architecture:** Identify counters, registers, multipliers, adders, coefficient storage, control logic, and pipeline stages.
4. **Develop functional test cases:** Use representative input values, boundary conditions, reset scenarios, and sustained input sequences.
5. **Verify arithmetic results:** Compare MAC, convolution, filtering, and fixed-point outputs against an independent reference calculation.
6. **Verify timing relationships:** Check PWM period and duty cycle, waveform sample progression, and pipeline latency.
7. **Evaluate sequential behavior:** Confirm that stored samples, accumulated values, and pipeline data remain correctly aligned.
8. **Inspect synthesis results:** Where synthesis is available, review arithmetic resource usage, register counts, inferred memories, and critical timing paths.
9. **Review numerical limitations:** Check for overflow, truncation, rounding errors, and initialization effects.

For DSP designs, a software reference model can be particularly useful. Python can calculate expected waveform samples, convolution results, moving averages, FIR outputs, and fixed-point results for comparison with RTL simulation.

## Applications

The concepts covered in this phase are relevant to:

- **Digital signal processing:** Filtering, convolution, and sample-based computation.
- **Communication systems:** Waveform processing and signal conditioning.
- **Embedded control:** PWM-based output control and digital timing.
- **Audio and sensor processing:** Filtering and numerical signal processing.
- **Image processing:** Convolution and related arithmetic datapaths.
- **Machine learning:** MAC arrays and accelerator-oriented computation.
- **ASIC and FPGA design:** Arithmetic datapaths, pipelining, and hardware resource optimization.

## Learning Objectives

By completing this phase, the intended learning outcomes are:

- Understand how mathematical and signal-processing operations are translated into RTL.
- Develop an understanding of PWM generation and digital waveform representation.
- Understand the role of MAC units in DSP and accelerator datapaths.
- Distinguish combinational MAC structures from pipelined implementations.
- Understand the hardware organization of convolution and digital filtering.
- Learn the basic architecture of moving average and FIR filters.
- Understand fixed-point representation, scaling, and arithmetic precision.
- Recognize the trade-offs between latency, throughput, and hardware resources.
- Develop a systematic approach to verifying arithmetic and sequential DSP circuits.
- Understand the computational concepts associated with accelerator-oriented RTL.

## Tools and Technologies

The following tools may be useful for working with these designs, depending on their implementation:

- **Verilog HDL:** RTL description of datapaths, waveform generators, and digital filters.
- **SystemVerilog:** Testbench development and functional verification.
- **Vivado:** RTL simulation and synthesis for supported FPGA targets.
- **Verilator:** RTL linting and simulation workflows where applicable.
- **GTKWave:** Inspection of waveforms, arithmetic signals, and pipeline behavior.
- **Yosys:** Synthesis and inspection of the resulting digital logic, subject to supported constructs.
- **Python:** Independent reference calculations and numerical verification of DSP algorithms.

The exact tools used for each design should be confirmed from its source files and project configuration.

## Scope and Limitations

- The directory names identify the intended topics but do not establish the exact algorithms, numerical formats, filter coefficients, pipeline structure, or verification results.
- A sine-wave generator's accuracy depends on its sample-generation method, numerical precision, and output resolution.
- MAC, convolution, and filter designs require careful handling of intermediate widths, signedness, overflow, and truncation.
- Pipelining may improve timing and throughput but can increase latency and register usage.
- Fixed-point implementations require explicit scaling and precision analysis.
- A design named TPU Accelerator should not automatically be interpreted as a complete or production-ready TPU architecture.
- Functional simulation does not establish timing closure, power efficiency, or physical implementation quality.
- Performance and hardware-resource claims should be based on synthesis or implementation reports rather than inferred from RTL alone.

## Key Takeaway

**Phase 07 — Data Processing & DSP** develops an understanding of digital waveform generation, arithmetic datapaths, multiply-accumulate operations, convolution, digital filters, fixed-point arithmetic, and accelerator-oriented computation.

These concepts form an important foundation for designing efficient RTL datapaths used in signal processing, communication systems, and computational hardware accelerators.
