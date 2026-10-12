# Phase 06 — LFSR & Random Number Generation

## Overview

This phase focuses on **Linear Feedback Shift Registers (LFSRs), pseudo-random number generation, random number generation concepts, and data whitening** using RTL design techniques.

The phase introduces different approaches to generating bit sequences and random-like data, including conventional LFSRs, pseudo-random number generators (PRNGs), Galois LFSRs, and true random number generator (TRNG) concepts. It also explores data whitening, a technique used to improve the statistical characteristics of data streams in communication and digital systems.

These topics provide a foundation for understanding sequence-generation circuits, feedback logic, deterministic pseudo-random behavior, and applications that require suitable data patterns.

## Topics Covered

| No. | Topic | Description |
|---|---|---|
| 066 | Linear Feedback Shift Register (LFSR) | Shift-register architecture that uses feedback logic to generate a sequence of bit patterns. |
| 067 | Pseudo-Random Number Generator (PRNG) | A deterministic sequence generator designed to produce pseudo-random values from an initial state. |
| 068 | Galois LFSR (a PRNG variant) | An LFSR implementation style in which feedback is distributed through selected stages of the register. |
| 069 | True Random Number Generator (TRNG) | A random-number-generation concept that relies on physical entropy sources rather than only deterministic state transitions. |
| 070 | Data Whitener | A circuit that transforms data using a defined sequence or scrambling operation to improve data-stream characteristics. |

## Technical Areas Explored

### 1. Linear Feedback Shift Register (LFSR)

An LFSR is a sequential circuit built from shift-register stages and feedback logic. The feedback is commonly calculated using XOR or XNOR operations on selected register bits, determined by the chosen feedback polynomial and implementation.

Key concepts include:

- Shift-register operation and feedback logic.
- Tap selection and feedback-polynomial concepts.
- State transitions and sequence generation.
- Initial-state selection and reset behavior.
- Sequence repetition and period.
- Avoiding invalid or locked states where applicable.

The sequence produced by an LFSR depends on its width, feedback configuration, initial state, and implementation conventions.

### 2. Pseudo-Random Number Generation (PRNG)

A PRNG generates a repeatable sequence of values from an initial state and a deterministic update rule. LFSRs are commonly used as hardware building blocks for lightweight pseudo-random sequence generation.

Key concepts include:

- Deterministic state evolution.
- Seed or initial-state handling.
- Generating successive output values.
- Sequence repetition and periodicity.
- Reproducibility during simulation and verification.
- Potential use in test-pattern generation and digital data processing.

A pseudo-random sequence is not automatically cryptographically secure. Its suitability depends on the generator architecture and the application's statistical and security requirements.

### 3. Galois LFSR

The Galois LFSR is an alternative LFSR architecture in which feedback is applied to selected register stages rather than being implemented only as a single external feedback network.

Key concepts include:

- Distributed feedback logic.
- Shift-register state updates.
- Feedback-tap configuration.
- Differences between Fibonacci-style and Galois-style implementations.
- Sequence equivalence under compatible polynomial and state conventions.
- Potential differences in logic structure and timing.

The exact sequence and output behavior depend on the selected taps, register orientation, shift direction, and initial state.

### 4. True Random Number Generator (TRNG)

A TRNG aims to obtain randomness from physical phenomena rather than relying exclusively on a deterministic digital recurrence.

Potential entropy sources include oscillator jitter, metastability-based structures, and other physical noise mechanisms, depending on the implementation and target technology.

Important concepts include:

- Physical entropy sources.
- Entropy collection and sampling.
- Conditioning or post-processing of raw entropy.
- Statistical evaluation of generated data.
- The distinction between physical randomness and deterministic pseudo-randomness.
- Hardware-specific implementation and validation requirements.

A synthesizable RTL block alone does not guarantee a true source of randomness. A practical TRNG requires a suitable physical entropy source and careful assessment of entropy quality, bias, correlations, and implementation effects.

### 5. Data Whitening

Data whitening transforms a data stream using a defined sequence or operation, often involving an XOR operation with a pseudo-random sequence. The purpose is to improve data-stream characteristics, such as reducing long runs or patterns that may be undesirable for a particular communication system.

Key concepts include:

- Data transformation using a generated sequence.
- XOR-based whitening and de-whitening.
- Sequence generation and synchronization.
- Maintaining consistent transmitter and receiver state.
- Reset and initialization requirements.
- Applications in communication and digital data paths.

Whitening does not provide encryption or confidentiality by itself. Its effectiveness depends on the whitening sequence, data format, and system requirements.

## Design and Verification Methodology

The following workflow can be used to study and evaluate the designs in this phase:

1. **Understand the design objective:** Identify the intended sequence generator, feedback configuration, output format, or data-transformation behavior.
2. **Inspect the RTL structure:** Review registers, feedback logic, state initialization, control signals, and output-generation logic.
3. **Define expected behavior:** Establish the initial state, feedback rules, and expected state transitions or output sequence.
4. **Verify LFSR and PRNG operation:** Check state updates, output generation, reset behavior, and sequence repetition.
5. **Compare LFSR architectures:** Where applicable, examine how Fibonacci-style and Galois-style feedback structures differ.
6. **Verify data whitening:** Confirm that whitening and de-whitening operations are consistent when configured with the same sequence and initial conditions.
7. **Evaluate TRNG assumptions:** Distinguish digital RTL behavior from the physical entropy source required for genuine randomness.
8. **Inspect simulation results:** Use waveforms and testbench checks to identify incorrect state transitions, initialization issues, or sequence mismatches.

Useful verification extensions include reference-model comparison, assertions for legal state behavior, checks for unexpected sequence repetition, and coverage of reset and initialization scenarios.

For a TRNG implementation, simulation should be supplemented by physical entropy assessment and appropriate statistical testing; ordinary functional simulation is insufficient to establish randomness quality.

## Applications

The concepts covered in this phase are relevant to:

- **Digital verification:** Generating pseudo-random stimulus and test patterns.
- **Built-in self-test (BIST):** Supporting test-pattern generation in suitable hardware architectures.
- **Communication systems:** Data whitening and sequence generation.
- **Digital signal processing:** Generating deterministic sequences for selected processing tasks.
- **Hardware testing:** Producing repeatable pseudo-random input patterns.
- **Embedded and digital systems:** Lightweight sequence-generation circuits.
- **Security-related hardware:** Randomness generation, subject to the security requirements and quality of the underlying implementation.

## Learning Objectives

By completing this phase, the intended learning outcomes are:

- Understand the architecture and operation of an LFSR.
- Learn how feedback logic determines register-state transitions.
- Understand the role of initial states and feedback configurations.
- Distinguish pseudo-random sequence generation from true random number generation.
- Explore the Galois LFSR architecture.
- Understand sequence periodicity and repeatability.
- Learn the purpose of data whitening and the role of sequence synchronization.
- Develop testbenches for checking sequential state transitions and generated outputs.
- Recognize the physical implementation and validation requirements of TRNG designs.

## Tools and Technologies

The following tools may be useful for studying these designs, depending on the implementation:

- **Verilog HDL:** RTL description of shift registers, feedback networks, and sequence generators.
- **SystemVerilog:** Testbench development and functional verification.
- **Vivado:** RTL simulation and synthesis for supported FPGA targets.
- **Verilator:** RTL linting and simulation workflows where applicable.
- **GTKWave:** Waveform inspection and analysis of state transitions.
- **Yosys:** Synthesis and inspection of the resulting digital logic, subject to supported constructs.

The exact tools used for each design should be confirmed from its source files and project configuration.

## Scope and Limitations

- The folder names identify the design topics but do not establish the exact register widths, feedback polynomials, seeds, output formats, or verification results.
- The sequence period of an LFSR depends on its configuration and initial state; maximum-length behavior should not be assumed without verification.
- A PRNG's deterministic output is useful for repeatable testing but does not inherently provide cryptographic security.
- A TRNG requires a physical entropy source and appropriate validation. Pure RTL simulation cannot demonstrate that a design produces genuine physical randomness.
- Data whitening improves certain data-stream characteristics but does not encrypt data or guarantee a particular statistical distribution.
- Synthesis results, timing, power, and physical behavior depend on the implementation and target technology.
- Functional simulation does not replace hardware-level validation where physical entropy or analog effects are essential.

## Key Takeaway

**Phase 06 — LFSR & Random Number Generation** develops an understanding of feedback-based sequence generation, pseudo-random number generation, Galois LFSR structures, true random number generation concepts, and data whitening.

These concepts are useful in RTL verification, digital communication, hardware testing, and the development of sequence-generation blocks for larger digital systems.
