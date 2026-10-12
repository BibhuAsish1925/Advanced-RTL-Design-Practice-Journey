# Phase 05 — Memory & Storage

## Overview

This phase focuses on RTL design concepts related to **memory structures and storage elements**, including Random Access Memory (RAM), Read-Only Memory (ROM), First-In First-Out (FIFO), and Last-In First-Out (LIFO) architectures.

The phase explores different memory configurations, access methods, clocking schemes, parameterization, and data-storage organizations. It also introduces queue-based storage structures and SystemVerilog-based verification through the FIFO environment.

These designs provide a foundation for understanding how storage components are described in RTL and used in digital systems, processors, controllers, and memory subsystems.

## Topics Covered

| No. | Topic | Description |
|---|---|---|
| 048 | 16×16 RAM | RAM organization with a 16×16 memory structure. |
| 049 | Parameterized RAM | Configurable memory architecture using parameters for reusable RTL design. |
| 050 | Single-Port RAM | Memory access through a single port for read and write operations, depending on the implementation. |
| 051 | Dual-Port RAM | Memory architecture with two access ports, allowing flexible memory access. |
| 052 | Synchronous RAM | RAM operations controlled by a clock, with timing determined by the implementation. |
| 053 | Asynchronous RAM | RAM access without a clock-controlled read path, depending on the implementation. |
| 054 | RAM 16384 Words | RAM organization with a capacity of 16,384 addressable words. |
| 055 | Dual-Clock Dual-Port RAM | Dual-port memory architecture using separate clocks for its ports. |
| 056 | 16×16 ROM | ROM organization with a 16×16 structure. |
| 057 | Simple ROM | Basic read-only memory design for storing predefined data. |
| 058 | Asynchronous ROM | ROM with an asynchronous read path. |
| 059 | ROM Using Case | ROM contents described using a Verilog `case` statement. |
| 060 | ROM (ALU Decoder) | ROM-based structure associated with ALU decoding. |
| 061 | FIFO (SV Environment) | FIFO design associated with a SystemVerilog verification environment. |
| 062 | FIFO Complex | A more involved FIFO design, with details determined by its RTL implementation. |
| 063 | Synchronous FIFO | FIFO storage and control operating within a synchronous clocking scheme. |
| 064 | Asynchronous FIFO | FIFO architecture intended to support data transfer between separate clock domains. |
| 065 | LIFO | Last-In First-Out storage organization, commonly implemented as a stack. |

## Technical Areas Explored

### 1. RAM Architecture and Configuration

The RAM designs cover several memory organizations and access configurations, from a 16×16 structure to a memory containing 16,384 words.

Key concepts include:

- Memory arrays and address-based word selection.
- Read and write operations.
- Memory depth, word width, and storage capacity.
- Parameterized memory dimensions for reusable RTL.
- Single-port and dual-port access configurations.
- Synchronous and asynchronous read behavior.
- Dual-clock memory access and its timing considerations.

Parameterized memory design is particularly useful when the same RTL structure must support different data widths or memory depths without duplicating the entire implementation.

### 2. ROM Architecture and RTL Description

The ROM designs explore how predefined data can be represented and accessed using RTL.

The listed implementations include simple ROM structures, asynchronous ROM, ROM described using a `case` statement, and a ROM associated with ALU decoding.

Key concepts include:

- Storing constant or predefined values.
- Address-to-data mapping.
- Combinational read behavior.
- Describing lookup tables in RTL.
- Using ROM structures for decoding and control-related functions.

A ROM-based ALU decoder can associate an input code or operation field with a predefined output pattern, depending on the implementation.

### 3. FIFO — First-In First-Out

A FIFO is a storage structure in which data is read in the same order in which it was written. The phase includes a FIFO with a SystemVerilog environment, a complex FIFO, a synchronous FIFO, and an asynchronous FIFO.

Important design concepts include:

- Write and read operations.
- Data ordering.
- Read and write pointer management.
- Empty and full conditions.
- Storage occupancy and control logic.
- Synchronous versus asynchronous FIFO operation.
- Verification of FIFO behavior using a SystemVerilog environment.

FIFO control logic must coordinate storage access with the current state of the buffer. Correct handling of boundary conditions is important to avoid invalid reads, writes beyond available capacity, or incorrect status reporting.

### 4. Synchronous and Asynchronous Storage

The phase includes storage designs with different clocking and access behaviors.

- **Synchronous storage:** Operations are coordinated with a clock, subject to the implemented timing and control logic.
- **Asynchronous read structures:** Read data may respond to address changes without waiting for a clock edge.
- **Dual-clock dual-port RAM:** The two ports use separate clocks, requiring careful consideration of access timing and simultaneous operations.
- **Asynchronous FIFO:** Used when data must be transferred between clock domains that may operate at different frequencies or phases.

Asynchronous FIFOs require particular attention to clock-domain crossing, pointer synchronization, and full/empty detection. Their correctness cannot be established merely by testing each clock domain independently.

### 5. LIFO — Last-In First-Out

The LIFO design represents a stack-oriented storage structure. Unlike a FIFO, a LIFO returns the most recently stored item first.

Key concepts include:

- Push and pop operations.
- Stack ordering.
- Stack pointer management.
- Empty and full boundary conditions, where supported.
- Storage access and control sequencing.

LIFO structures are useful in stack-based processing, temporary data storage, and control-flow implementations.

## Design and Verification Methodology

The following workflow provides a consistent way to study and evaluate the designs in this phase:

1. **Understand the specification:** Identify the memory dimensions, port configuration, clocking scheme, and expected read/write behavior.
2. **Review the RTL structure:** Examine the memory array, address handling, control signals, and storage-management logic.
3. **Define functional scenarios:** Cover normal operations, boundary addresses, repeated accesses, and simultaneous operations where applicable.
4. **Verify RAM and ROM behavior:** Check address selection, stored values, read behavior, and predefined lookup outputs.
5. **Verify FIFO and LIFO behavior:** Test insertion, removal, ordering, and supported empty/full conditions.
6. **Evaluate clocking behavior:** For multi-clock designs, examine interactions between clock domains and the handling of asynchronous control conditions.
7. **Review synthesizability:** Determine whether the RTL is compatible with the intended synthesis flow and whether the target tool can infer an appropriate memory structure.
8. **Inspect results:** Use simulation and available synthesis reports to identify functional issues and understand the resulting hardware structure.

For the FIFO design with a SystemVerilog environment, useful verification improvements include a reference queue, assertions for legal operations, and coverage of boundary conditions if these features are not already present.

## Applications

The memory and storage structures covered in this phase are relevant to:

- **Processor and SoC design:** RAM, ROM, instruction storage, and control lookup tables.
- **Memory subsystems:** Configurable storage blocks and multiple-port memory access.
- **Digital signal processing:** Buffers for intermediate samples and processing data.
- **Communication interfaces:** FIFOs for buffering incoming and outgoing data.
- **Clock-domain crossing:** Asynchronous FIFOs for controlled data transfer between independent clock domains.
- **Control logic:** ROM-based decoding and predefined lookup operations.
- **Stack-based architectures:** LIFO structures for temporary storage and ordered data retrieval.

## Learning Objectives

By completing this phase, the intended learning outcomes are:

- Understand basic RAM and ROM organization.
- Explore fixed-size and parameterized memory designs.
- Distinguish single-port, dual-port, synchronous, and asynchronous memory configurations.
- Understand address-based memory access and predefined ROM contents.
- Learn the functional differences between FIFO and LIFO storage.
- Understand FIFO pointers, ordering, and boundary conditions.
- Recognize the additional design considerations of dual-clock RAM and asynchronous FIFO architectures.
- Develop a structured approach to RTL simulation and functional verification.
- Understand how RTL coding style can influence memory inference during synthesis.

## Tools and Technologies

The following tools and technologies may be used to work with these designs, depending on the individual implementation:

- **Verilog HDL:** RTL description of memory and storage structures.
- **SystemVerilog:** Verification environments and testbench development.
- **Vivado:** RTL simulation and synthesis for supported FPGA targets.
- **Verilator:** RTL linting and simulation workflows where applicable.
- **GTKWave:** Inspection of waveform activity during simulation.
- **Yosys:** Synthesis and inspection of inferred hardware structures, subject to supported constructs.

The exact tools used for each design should be confirmed from its source files and project configuration.

## Scope and Limitations

- The directory names identify the intended design topics but do not establish the exact RTL implementation, supported operations, or verification results.
- The term **16×16 RAM** is interpreted as a memory with 16 words of 16 bits each; the actual module definition should be checked to confirm this interpretation.
- The **RAM 16384 Words** entry identifies the word count, but its word width and total storage capacity are not specified by the directory name.
- Dual-port and dual-clock RAM designs may have implementation-specific restrictions on simultaneous accesses, read-during-write behavior, and port conflicts.
- Asynchronous FIFO correctness requires careful clock-domain-crossing design and verification.
- RTL simulation alone does not establish timing closure, physical memory inference, or silicon-level performance.
- Synthesis results and implementation characteristics depend on the target technology, synthesis tool, and coding style.

## Key Takeaway

**Phase 05 — Memory & Storage** builds a foundation in RTL-based data storage, covering RAM and ROM configurations, parameterized memory structures, synchronous and asynchronous access, FIFO buffering, and LIFO organization.

These concepts are essential for developing reliable storage components and understanding how memory structures integrate into larger digital systems, processors, and SoC architectures.
