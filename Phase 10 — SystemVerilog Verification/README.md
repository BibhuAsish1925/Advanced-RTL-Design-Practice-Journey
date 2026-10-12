# Phase 10 — SystemVerilog Verification

## Overview

This phase focuses on **functional verification of RTL designs using SystemVerilog**, applying verification concepts to sequential logic and memory-buffering structures.

The phase includes two verification examples: a D flip-flop and a synchronous FIFO. These provide opportunities to examine how SystemVerilog testbenches can validate state updates, sequential behavior, data storage, and control conditions.

The emphasis is on connecting RTL functionality with structured verification practices, including stimulus generation, output checking, clock and reset handling, and waveform analysis.

## Topics Covered

| No. | Topic | Description |
|---|---|---|
| 098 | D Flip-Flop — SystemVerilog-Based Verification | Verifies the behavior of a D flip-flop using a SystemVerilog-based testbench. |
| 099 | Synchronous FIFO — SystemVerilog-Based Verification | Applies SystemVerilog-based verification to a synchronous FIFO, a storage structure that preserves first-in-first-out data ordering. |

## Technical Areas Explored

### 1. D Flip-Flop Verification

A D flip-flop is a sequential circuit that stores a single bit of data and updates its output according to its clocking behavior.

Key verification concepts include:

- Clock generation and synchronization.
- Applying input stimulus.
- Checking output updates at the appropriate clock event.
- Reset behavior, if supported by the design.
- Comparing expected and observed outputs.
- Examining sequential behavior through simulation waveforms.

A useful testbench should check both transitions and stable conditions, ensuring that the output behaves according to the intended RTL specification.

### 2. Synchronous FIFO Verification

A synchronous FIFO stores multiple data items and returns them in the order in which they were written. Its read and write operations are coordinated using a common clock.

Key verification concepts include:

- Write and read transactions.
- Data ordering and integrity.
- Read and write control signals.
- FIFO empty and full conditions, where supported.
- Simultaneous read and write operations.
- Reset and initialization behavior.
- Checking data against expected results.

FIFO verification should cover normal operation as well as boundary conditions. For example, the testbench can examine behavior when the FIFO is empty, when it reaches capacity, and when reads and writes occur in the same clock cycle.

The exact supported operations and status signals depend on the FIFO implementation.

## Design and Verification Methodology

The following workflow provides a structured approach to the two verification examples:

1. **Understand the DUT:** Identify the module interface, clocking behavior, reset requirements, and expected functionality.
2. **Develop the testbench:** Create the clock and reset logic and define the required stimulus.
3. **Define expected behavior:** Establish the expected output for each input sequence or transaction.
4. **Apply stimulus:** Exercise normal operating conditions, boundary cases, and relevant input combinations.
5. **Check outputs:** Compare observed results against expected values using explicit testbench checks.
6. **Inspect waveforms:** Examine clock edges, state changes, control signals, and data movement.
7. **Review corner cases:** Verify reset behavior, sequential transitions, and FIFO boundary conditions where applicable.
8. **Report results:** Use clear pass/fail checks so that incorrect behavior is not hidden by visual waveform inspection alone.

A useful improvement for FIFO verification is a **reference queue** that records written data and checks each read against the oldest expected item. This provides a systematic way to detect data loss, duplication, corruption, or ordering errors.

## Applications

The verification concepts covered in this phase are relevant to:

- **Sequential RTL verification:** Checking registers and other clocked logic.
- **Memory-buffer verification:** Validating data storage and retrieval.
- **FIFO verification:** Checking ordering, capacity limits, and read/write behavior.
- **Digital subsystem testing:** Verifying components before integration.
- **ASIC and FPGA development:** Identifying functional errors before synthesis and implementation.
- **Reusable verification environments:** Applying systematic stimulus and checking techniques across different RTL modules.

## Learning Objectives

By completing this phase, the intended learning outcomes are:

- Understand how to verify sequential RTL using SystemVerilog.
- Develop testbenches for a D flip-flop and synchronous FIFO.
- Generate clocked stimulus and manage reset sequences.
- Check expected and observed outputs systematically.
- Understand the importance of FIFO data ordering and boundary conditions.
- Use waveforms to investigate sequential behavior.
- Apply self-checking techniques to reduce reliance on manual inspection.
- Develop a foundation for more advanced functional verification.

## Tools and Technologies

The following tools may be useful for working with these examples, depending on the source code and simulator support:

- **SystemVerilog:** Testbench development and functional checking.
- **Vivado Simulator:** RTL simulation and verification for supported constructs.
- **Verilator:** Linting and simulation workflows where applicable.
- **EDA Playground:** Running supported SystemVerilog examples.
- **GTKWave:** Inspecting clock, reset, control, and data waveforms.

The exact tools used for each example should be confirmed from its source files and project configuration.

## Scope and Limitations

- The folder names identify the verification targets but do not establish the testbench architecture, stimulus coverage, or simulation results.
- The D flip-flop's reset type, clock edge, and other behaviors must be confirmed from the RTL.
- The synchronous FIFO's depth, data width, status flags, and simultaneous read/write behavior depend on its implementation.
- Successful simulation of selected scenarios does not establish complete functional coverage.
- Waveform inspection should be supplemented by explicit self-checking testbench logic.
- Functional verification does not independently establish timing closure, power efficiency, or physical implementation quality.

## Key Takeaway

**Phase 10 — SystemVerilog Verification** applies SystemVerilog testbench techniques to sequential logic and FIFO storage, building practical skills in stimulus generation, output checking, clocked behavior, and data-integrity verification.

These skills form a foundation for progressing toward more comprehensive verification environments using constrained-random stimulus, assertions, reference models, and functional coverage.
