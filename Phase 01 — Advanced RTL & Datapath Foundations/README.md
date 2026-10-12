# Phase 01 — Advanced RTL & Datapath Foundations

## Overview

This phase focuses on the practical implementation and analysis of digital hardware using Verilog HDL. It builds upon fundamental digital logic concepts and progresses toward arithmetic architectures, datapath components, sequential circuits, timing behavior, and control-oriented logic.

The implementations explore multiple approaches to realizing the same hardware functionality, including NAND-based arithmetic circuits, multiplexer-based logic, and optimized adder architectures. The phase also introduces parameterized designs, pipeline fundamentals, clocking concepts, endianness, and priority resolution.

The objective is to develop a stronger understanding of how RTL descriptions represent digital hardware, how architectural choices affect circuit behavior, and how combinational and sequential elements contribute to larger digital systems.

## Topics Covered

| No. | Topic | Description |
|---:|---|---|
| 001 | Adders and Subtractors Using NAND | Implements half adders, full adders, half subtractors, and full subtractors using NAND gates. Demonstrates universal-gate design and Boolean logic realization. |
| 002 | Carry Select Adder | Explores an adder architecture that computes alternative carry-dependent results in parallel and selects the appropriate result to reduce carry-propagation delay. |
| 003 | Carry Skip Adder | Examines carry propagation optimization using block propagate conditions, allowing the carry to bypass selected groups of bits. |
| 004 | Carry Look-Ahead Generator | Implements carry-generation logic using generate and propagate signals to calculate carries more efficiently than simple ripple propagation. |
| 005 | Basic Logic Gates Using MUX | Demonstrates how multiplexers can realize basic Boolean functions through appropriate input selection and control signals. |
| 006 | Full Adder Using MUX | Explores multiplexer-based implementation of full-adder sum and carry functions, connecting Boolean expressions with structural hardware design. |
| 007 | Inter and Intra Delay | Introduces delay concepts associated with signal propagation within and between logic elements, helping explain timing behavior in digital circuits. |
| 008 | Endianness | Examines big-endian and little-endian byte ordering and their implications for data representation, storage, and communication. |
| 009 | Dual Edge Triggered Flip-Flop | Studies sequential behavior associated with positive and negative clock edges and the concepts involved in dual-edge-triggered designs. |
| 010 | Parameterized Register | Develops configurable register logic using parameters, enabling reusable RTL with different data widths. |
| 011 | Pipeline Shift | Explores sequential data movement through pipeline stages using registers and clock-controlled updates. |
| 012 | Delays | Examines Verilog delay controls and their effects on event scheduling and simulation behavior. |
| 013 | Clock Phase | Introduces clock phase relationships and their relevance to clock-controlled operations and timing analysis. |
| 014 | Priority Resolver | Implements priority-based selection or resolution logic, where competing requests are handled according to a defined priority scheme. |

## Technical Areas Explored

### 1. Arithmetic Circuit Architectures

The arithmetic designs explore different implementations of addition and subtraction, from fundamental gate-level circuits to architectures intended to improve carry propagation.

Key concepts include:
- Half-adder and full-adder logic.
- Half-subtractor and full-subtractor logic.
- NAND-only arithmetic implementation.
- Carry generation and propagation.
- Carry-select, carry-skip, and carry-look-ahead architectures.
- Trade-offs between logic complexity, propagation delay, and hardware resources.

These concepts are relevant to the arithmetic datapaths found in processors, ALUs, address-generation units, and digital signal processing hardware.

### 2. Combinational Logic Realization

The multiplexer-based designs demonstrate that Boolean functions can be implemented using different structural approaches.

Key concepts include:
- Boolean function decomposition.
- Multiplexer-based logic implementation.
- Gate-level versus structural RTL.
- Signal selection and combinational dependencies.
- Alternative implementations of arithmetic functions.

Understanding these approaches helps develop the ability to interpret logic equations and translate them into hardware structures.

### 3. Sequential Logic and Datapath Elements

The register, flip-flop, and pipeline examples introduce clock-controlled data storage and movement.

Key concepts include:
- Parameterized register design.
- Clock-edge-triggered behavior.
- Sequential data transfer.
- Pipeline stages and register boundaries.
- Clock phase relationships.
- Distinguishing combinational behavior from sequential behavior.

These fundamentals support the development of pipelined datapaths, control registers, processor execution stages, and other synchronous digital systems.

### 4. Timing and Data Representation

The delay, clock phase, and endianness examples cover concepts that influence the interpretation and timing of digital hardware.

Key concepts include:
- Simulation delay controls.
- Signal propagation and timing behavior.
- Clock-edge relationships.
- Byte ordering in multi-byte data.
- The distinction between simulation timing and physical timing characteristics.

RTL simulation delays do not, by themselves, establish real silicon timing. Physical delay evaluation requires appropriate synthesis, timing constraints, and static timing analysis.

### 5. Priority-Based Control Logic

The priority resolver introduces logic for handling multiple competing requests or conditions according to a defined ordering.

Key concepts include:
- Priority selection.
- Conditional logic and arbitration fundamentals.
- Deterministic resolution of simultaneous requests.
- Control-path behavior.

Priority-resolution logic is useful in bus arbitration, interrupt controllers, resource allocation, and control-oriented digital systems.

## Design and Verification Methodology

The implementations can be studied through a consistent hardware development workflow:

1. **Conceptual analysis:** Understand the circuit's purpose, input/output behavior, Boolean equations, or sequential timing requirements.
2. **RTL development:** Implement the intended functionality using suitable Verilog constructs, including structural gate instantiation where appropriate.
3. **Functional simulation:** Apply input combinations or clock sequences and inspect the resulting outputs.
4. **Correctness checking:** Compare observed behavior against truth tables, expected arithmetic results, or specified sequential behavior.
5. **Waveform analysis:** Examine signal transitions, carry propagation, clock edges, register updates, and delay effects.
6. **Design evaluation:** Consider logic depth, propagation delay, resource usage, parameter flexibility, and implementation trade-offs where applicable.

The precise verification methods and achieved results depend on the individual project and its accompanying testbench.

## Applications

The concepts developed in this phase are applicable to several digital design domains:

- **Processor datapaths:** Arithmetic units, registers, and pipeline stages.
- **Arithmetic Logic Units (ALUs):** Addition, subtraction, and Boolean operations.
- **Digital signal processing:** Arithmetic building blocks and datapath structures.
- **Control systems:** Priority resolution and selection logic.
- **Memory and data interfaces:** Register-based storage and byte-order interpretation.
- **Synchronous digital systems:** Clock-controlled state updates and sequential data movement.
- **RTL optimization:** Exploring alternative architectures for carry propagation and combinational logic implementation.

## Learning Objectives

By completing this phase, the learner should be able to:

- Implement basic arithmetic circuits using NAND gates and multiplexers.
- Explain the operating principles of carry-select, carry-skip, and carry-look-ahead adders.
- Compare arithmetic architectures in terms of carry propagation and structural complexity.
- Develop reusable parameterized register designs.
- Understand the fundamental behavior of flip-flops and pipeline registers.
- Analyze Verilog delay controls and clock-related simulation behavior.
- Explain endianness and its role in multi-byte data representation.
- Implement and reason about priority-based logic.
- Use simulation and waveform analysis to investigate RTL functionality.
- Recognize the distinction between functional correctness, simulated timing, and physical implementation results.

## Tools and Technologies

- **Hardware Description Language:** Verilog HDL
- **Simulation:** Compatible Verilog simulators
- **Debugging:** Simulation waveforms and signal inspection
- **Design analysis:** Boolean equations, truth tables, RTL structure, and timing concepts

Specific tools, synthesis results, and verification coverage should be documented individually when confirmed for each implementation.

## Scope and Limitations

This phase emphasizes foundational and intermediate RTL design concepts, with selected topics introducing architectural optimization and timing considerations.

The implementations should not automatically be interpreted as physically optimized or silicon-validated designs. For example, a carry-select or carry-look-ahead architecture provides an opportunity to study reduced carry-propagation delay, but its actual performance and area depend on the implementation and target technology.

Similarly, Verilog delay statements primarily describe simulation behavior and are not a substitute for physical timing constraints or static timing analysis. Dual-edge-triggered behavior and clock-phase relationships also require careful consideration of synthesis-tool and target-library support when intended for hardware implementation.

## Key Takeaway

Phase 01 establishes the digital design foundation for the repository. By progressing from gate-level arithmetic and Boolean logic to optimized adder architectures, sequential datapath elements, timing concepts, and priority-based control, it prepares the learner for more advanced RTL topics involving arithmetic processing, memory systems, clocking, DSP, hardware security, and SystemVerilog-based verification.