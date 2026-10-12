# Phase 08 — Error Detection & Correction

## Overview

This phase focuses on **error detection and correction techniques implemented using RTL**, with an emphasis on Hamming codes and Cyclic Redundancy Checks (CRC).

The designs explore how redundant bits can be generated and used to detect data corruption, and how selected coding schemes can support error correction. The phase covers Hamming-code-based error detection and correction, a general CRC generator, CRC-16, and CRC-32.

These techniques are important in digital systems where data integrity must be maintained during storage, processing, or transmission. They also provide practical experience in designing XOR-based logic, bitwise operations, and hardware circuits that implement coding algorithms.

## Topics Covered

| No. | Topic | Description |
|---|---|---|
| 080 | Error Detection and Correction Using Hamming Code Technique | Uses Hamming-code principles to generate and evaluate redundant parity bits for error detection and correction. |
| 081 | CRC Generator | Implements a Cyclic Redundancy Check generator for calculating a checksum from input data. |
| 082 | CRC-16 | Explores a CRC implementation using a 16-bit CRC register or result, depending on the design. |
| 083 | CRC-32 | Explores a CRC implementation using a 32-bit CRC register or result, depending on the design. |

## Technical Areas Explored

### 1. Hamming Code

Hamming codes introduce redundant parity bits into a data word to support error detection and, in suitable configurations, error correction.

Key concepts include:

- Data bits and parity bits.
- Parity-bit placement.
- Parity calculation using XOR operations.
- Syndrome generation and interpretation.
- Identification of potential bit errors.
- Error correction and corrected-data output, where supported.

A conventional Hamming code can correct a single-bit error under its intended assumptions. Extended Hamming codes can additionally support detection of certain multiple-bit errors, commonly using an overall parity bit.

The actual error-detection and correction capabilities depend on the specific code configuration and RTL implementation.

### 2. Cyclic Redundancy Check (CRC)

CRC is an error-detection technique that treats a data sequence as a polynomial over binary arithmetic and calculates a remainder using a selected generator polynomial.

Key concepts include:

- Generator polynomials.
- XOR-based feedback logic.
- Shift-register-based CRC computation.
- Data processing order.
- CRC initialization and finalization.
- Remainder generation and comparison.

A CRC value is appended to or associated with a data message. A receiving circuit can recompute or otherwise evaluate the CRC to determine whether the received data is consistent with the expected check value.

CRC is primarily an error-detection mechanism; it does not generally correct corrupted data by itself.

### 3. CRC Generator

The CRC generator topic provides a general foundation for implementing CRC calculations in hardware.

Depending on the implementation, the generator may process input data serially, one bit at a time, or in parallel, processing multiple bits per cycle.

Key concepts include:

- Input-data handling.
- Shift-register organization.
- Feedback-tap selection.
- XOR-network implementation.
- Sequential versus combinational computation.
- Output-valid timing and control, where applicable.

The selected generator polynomial and processing conventions determine the CRC result. Two CRC implementations with the same register width may produce different results if their polynomials, initialization values, bit ordering, or final XOR conventions differ.

### 4. CRC-16

CRC-16 refers to CRC configurations that use a 16-bit CRC result. Several CRC-16 variants exist, and the width alone does not identify a unique algorithm.

Key concepts include:

- A 16-bit CRC state or result.
- Generator-polynomial selection.
- Feedback and shift-register logic.
- Input-bit ordering.
- Initialization and finalization rules.
- Verification against expected CRC values.

The precise CRC-16 variant must be determined from the implementation's polynomial and configuration rather than inferred from the folder name.

### 5. CRC-32

CRC-32 uses a 32-bit CRC result and is commonly used in data-integrity checking.

Key concepts include:

- A 32-bit CRC state or result.
- Polynomial-based remainder calculation.
- Feedback logic and bitwise operations.
- Input-data ordering and processing width.
- Initialization, reflection, and final XOR conventions where applicable.
- Comparison against a trusted reference implementation.

CRC-32 implementations can differ in their polynomial and processing conventions. A design's correctness should therefore be evaluated against the specific CRC variant it intends to implement.

## Design and Verification Methodology

The following workflow can be used to study and evaluate the designs in this phase:

1. **Understand the coding scheme:** Identify the intended Hamming-code configuration or CRC variant.
2. **Review the RTL architecture:** Examine parity logic, XOR networks, shift registers, feedback connections, and output-control signals.
3. **Define expected behavior:** Establish the parity rules or CRC parameters, including polynomial, initialization, bit ordering, and finalization.
4. **Verify Hamming-code operation:** Test valid data, single-bit error scenarios, syndrome behavior, and correction functionality where supported.
5. **Verify CRC generation:** Apply known input messages and compare the generated CRC against independently calculated reference values.
6. **Test boundary conditions:** Examine reset behavior, empty or minimum-length messages where supported, and changes in input data.
7. **Check data ordering:** Confirm that bit order and byte order match the intended coding convention.
8. **Evaluate error cases:** Test corrupted messages and confirm the expected detection behavior without assuming that every possible error must be detected.
9. **Inspect implementation results:** Where synthesis is available, review the resulting combinational logic, registers, timing, and resource usage.

A software reference model can help verify CRC calculations and Hamming-code behavior. For CRC testing, the reference must use the same polynomial, initialization, reflection, and final XOR conventions as the RTL.

## Applications

The concepts covered in this phase are relevant to:

- **Memory systems:** Error detection and correction for stored data, depending on the implemented coding scheme.
- **Digital communication:** Checking data integrity across communication links.
- **Network protocols:** Detecting transmission errors in packets and frames.
- **Storage devices:** Identifying corrupted data using CRC-based checks.
- **Embedded systems:** Validating messages exchanged between digital components.
- **ASIC and FPGA design:** Implementing parity generation, syndrome logic, and CRC datapaths.
- **Data-processing systems:** Checking the consistency of data before or after processing.

## Learning Objectives

By completing this phase, the intended learning outcomes are:

- Understand the role of redundancy in error detection and correction.
- Learn how Hamming-code parity bits are generated.
- Understand syndrome-based error identification.
- Distinguish error detection from error correction.
- Understand CRC calculation using polynomial division over binary arithmetic.
- Explore XOR-based CRC logic and shift-register implementations.
- Recognize the differences between CRC-16 and CRC-32 configurations.
- Understand why CRC width alone does not uniquely identify a CRC algorithm.
- Develop reference-based verification for coding and data-integrity circuits.
- Evaluate the functional behavior of error-detection and correction logic.

## Tools and Technologies

The following tools may be useful for studying these designs, depending on their implementation:

- **Verilog HDL:** RTL description of parity logic, CRC generators, and error-checking circuits.
- **SystemVerilog:** Testbench development and functional verification.
- **Vivado:** RTL simulation and synthesis for supported FPGA targets.
- **Verilator:** RTL linting and simulation workflows where applicable.
- **GTKWave:** Inspection of parity signals, CRC states, and error-detection behavior.
- **Yosys:** Synthesis and inspection of the resulting digital logic, subject to supported constructs.
- **Python:** Independent reference calculations for Hamming codes and CRC algorithms.

The exact tools used for each design should be confirmed from its source files and project configuration.

## Scope and Limitations

- The directory names identify the intended topics but do not establish the exact Hamming-code variant, CRC polynomial, initialization value, bit order, or implementation architecture.
- Hamming-code correction capability depends on the selected code and its assumptions. Error correction should not be claimed without confirming the implemented logic.
- CRC-16 and CRC-32 each have multiple variants; register width alone is insufficient to determine the expected output.
- CRC detects many common data-corruption patterns but does not guarantee detection of every possible error.
- CRC is not an encryption or authentication mechanism.
- Functional simulation does not establish timing closure, power efficiency, or physical implementation quality.
- Verification results should be reported only after the corresponding RTL has been tested against defined expected behavior.

## Key Takeaway

**Phase 08 — Error Detection & Correction** builds a foundation in Hamming-code-based error handling and CRC-based data-integrity checking.

These techniques are important in designing reliable digital systems, where redundant information helps identify corrupted data and, in suitable coding schemes, correct selected errors. They also strengthen practical RTL skills in XOR-based logic, sequential datapaths, bitwise computation, and reference-driven verification.
