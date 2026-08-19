# Advanced RTL Design Practice

A structured collection of **advanced Verilog and SystemVerilog RTL design, digital hardware architecture, memory design, DSP, functional verification, UVM, and hardware security practice modules**.

This repository represents the progression from basic RTL implementation toward **industry-oriented RTL Design and Design Verification (DV)** concepts. The modules are organized in a phased manner so that each section builds upon concepts introduced in the previous sections.

---

## 📌 Repository Overview

This repository contains a curated collection of RTL design and verification exercises covering:

- Advanced RTL design techniques
- Datapath and arithmetic architectures
- Clocking and timing circuits
- Advanced FSM design
- Memory and storage architectures
- LFSR and random-number generation
- DSP and hardware acceleration
- Error detection and correction
- SystemVerilog programming
- Functional coverage
- SystemVerilog-based verification
- UVM fundamentals and verification environments
- Hardware security and cryptographic RTL

The repository is intended primarily for **learning, experimentation, simulation, and RTL design practice**.

---

# 🧭 Learning Path

The repository is arranged into **13 progressive phases**:

```text
Advanced RTL Datapath
        ↓
Advanced Arithmetic
        ↓
Clocking & Timing
        ↓
Advanced FSM
        ↓
Memory & Storage
        ↓
LFSR & Randomization
        ↓
DSP & Data Processing
        ↓
Error Detection & Correction
        ↓
SystemVerilog
        ↓
Functional Coverage
        ↓
SystemVerilog Verification
        ↓
UVM
        ↓
Hardware Security & Cryptography
```

The intention is to move from **RTL implementation → architecture → verification → advanced hardware design**.

---

# 📂 Repository Structure

```text
Advanced-RTL-Design-Practice/
│
├── 01_Advanced_RTL_Datapath/
│
├── 02_Advanced_Arithmetic/
│
├── 03_Clocking_and_Timing/
│
├── 04_Advanced_FSM/
│
├── 05_Memory_and_Storage/
│
├── 06_LFSR_and_Randomization/
│
├── 07_DSP_and_Data_Processing/
│
├── 08_Error_Detection_and_Correction/
│
├── 09_SystemVerilog/
│
├── 10_Functional_Coverage/
│
├── 11_SystemVerilog_Verification/
│
├── 12_UVM/
│
├── 13_Hardware_Security_and_Cryptography/
│
└── README.md
```

---

# 1️⃣ Advanced RTL Datapath

This section focuses on improving RTL coding skills beyond basic combinational and sequential circuits.

### Topics Include

- Advanced RTL modeling
- Structural RTL
- Datapath design
- Parameterized registers
- Endianness conversion
- Inter-module and intra-module delays
- Pipeline registers
- Pipeline shift registers
- Dual-edge triggered flip-flops
- Priority resolution
- MUX-based logic implementation

### Key Objective

To understand how individual RTL components are combined to construct **larger datapaths and synthesizable hardware architectures**.

---

# 2️⃣ Advanced Arithmetic

This section focuses on hardware implementations of arithmetic algorithms and optimized arithmetic architectures.

### Topics Include

- Carry Select Adder
- Carry Skip Adder
- Carry Look-Ahead Generator
- Booth multiplication
- Sequential multiplication
- Array multiplication
- Pipelined multiplication
- Division algorithms
- Fixed-point arithmetic
- Parameterized arithmetic
- GCD
- Matrix multiplication
- Prime-number checking
- Palindrome checking
- Factorial
- Square/cube-root computation

### Key Objective

To understand the difference between **algorithmic arithmetic and hardware-oriented arithmetic architectures**, including considerations such as latency, resource utilization, and pipelining.

---

# 3️⃣ Clocking and Timing

Clocking is a critical part of synchronous digital design.

This section contains RTL implementations related to clock generation, frequency division, timing measurement, and clock-event detection.

### Topics Include

- Even frequency divider
- Odd frequency divider
- Decimal frequency divider
- Clock phase generation
- Clock edge detection
- Delay modeling
- Glitch filtering
- Glitch-free clock gating
- Clock-gating controller
- Pulse-width qualification
- Frequency monitoring
- Period monitoring
- Randomized clock enable

### Key Objective

To develop an understanding of **clock-domain behavior, timing-related RTL, clock gating, and reliable synchronous design techniques**.

---

# 4️⃣ Advanced FSM

This section moves beyond basic FSM implementations toward more complex state-machine architectures.

### Topics Include

- One-hot FSM
- FSM sequence generator
- Mealy overlapping sequence detector
- Mealy non-overlapping sequence detector
- Moore overlapping sequence detector
- Moore non-overlapping sequence detector
- Multiple sequence detection

### Key Objective

To understand:

- FSM encoding
- State transitions
- Mealy vs. Moore architectures
- Overlapping vs. non-overlapping detection
- One-hot state encoding
- Synthesizable FSM coding styles

---

# 5️⃣ Memory and Storage

This is one of the major sections of the repository.

The focus is on extending basic memory concepts into more advanced memory architectures.

## ROM

- Asynchronous ROM
- ROM using `case`
- ROM-based ALU decoder

## RAM

- Asynchronous RAM
- Large-capacity RAM

## FIFO / Stack

- Advanced FIFO
- Asynchronous FIFO
- Almost-Full / Almost-Empty FIFO
- LIFO / Stack

### Key Objective

To understand:

- Memory organization
- Address decoding
- Read/write behavior
- Synchronous vs. asynchronous memory
- FIFO status management
- Cross-clock-domain FIFO concepts
- Stack-based storage

This section also provides a foundation for larger **memory subsystem and SoC projects**.

---

# 6️⃣ LFSR and Randomization

This section covers deterministic and non-deterministic random-data generation techniques.

### Topics Include

- Linear Feedback Shift Register
- Pseudo-random sequence generation
- Galois LFSR
- Tiny Galois LFSR
- FPGA-based TRNG

### Key Objective

To understand how LFSRs and random-number generators are implemented in hardware and how they can be used for:

- Test-pattern generation
- Scrambling
- Built-in self-test
- Security applications
- Random-data generation

---

# 7️⃣ DSP and Data Processing

This section introduces hardware implementations of signal-processing and computational algorithms.

### Topics Include

- PWM
- Sine-wave generation
- MAC unit
- Pipelined MAC
- FIR filter
- Moving-average filter
- Digital convolution
- CORDIC
- Fixed-point DSP
- TPU-style hardware acceleration

### Key Objective

To understand how mathematical algorithms are mapped onto **parallel and pipelined digital hardware**.

Particular attention is given to:

- Fixed-point arithmetic
- Pipelining
- Throughput
- Hardware parallelism
- Computational datapaths

---

# 8️⃣ Error Detection and Correction

Reliable digital systems require mechanisms for detecting and correcting errors.

### Topics Include

- CRC
- CRC-16
- CRC-32
- Hamming Code ECC
- Reed-Solomon Encoder
- Viterbi Decoder

### Key Objective

To understand how error-control algorithms are translated into RTL for applications such as:

- Communication systems
- Memory systems
- Data transmission
- Storage systems
- Digital signal processing

---

# 9️⃣ SystemVerilog

This section transitions from traditional Verilog into **SystemVerilog**, with emphasis on features used in modern RTL and verification environments.

### Topics Include

- Randomization
- Pre-randomization
- Post-randomization
- Inline constraints
- Weighted constraints
- `inside` operator
- Enumerated types
- Fixed arrays
- Dynamic arrays
- Packages
- Mailboxes
- Semaphores
- Classes
- Inheritance
- Encapsulation
- Polymorphism

### Key Objective

To develop familiarity with SystemVerilog constructs used in **modern RTL development and functional verification**.

---

# 🔟 Functional Coverage

Functional coverage is an important part of verification methodology.

### Topics Include

- Implicit coverage bins
- Explicit coverage bins

### Key Objective

To understand how verification environments measure whether important functional scenarios have been exercised during simulation.

---

# 1️⃣1️⃣ SystemVerilog Verification

This section focuses on writing verification environments using SystemVerilog.

### Topics Include

- Self-checking D flip-flop testbench
- Self-checking FIFO testbench
- SystemVerilog testbench architecture

### Key Objective

To move from simple waveform-based verification toward **automated, self-checking verification environments**.

---

# 1️⃣2️⃣ UVM

This section introduces the **Universal Verification Methodology (UVM)**.

### Topics Include

- UVM macros
- Reporting and verbosity
- UVM field macros
- Integer field handling
- Enum field handling
- Array field handling
- Copy and clone
- Shallow vs. deep copy
- Factory override
- Build phase
- End-of-elaboration phase
- Combinational-adder UVM environment
- Sequential-adder UVM environment
- APB verification environment

### Key Objective

To build a foundation for developing **reusable, scalable, object-oriented verification environments**.

---

# 1️⃣3️⃣ Hardware Security and Cryptography

The final section contains some of the most advanced designs in the repository.

### Topics Include

- Zeroizable key register
- APB firewall
- True random number generator
- Finite-field multiplication
- ITA algorithm
- SHA-256
- Hardware watermarking
- XTIME operation
- Galois-field multiplication
- Mastrovito multiplier
- Montgomery multiplication
- Montgomery ladder
- Branch-free conditional swap
- Karatsuba multiplication
- Hardware Security Module architecture

### Key Objective

To explore how **cryptographic and security algorithms are mapped into hardware**, with emphasis on:

- Finite-field arithmetic
- Hardware security
- Constant-time operations
- Cryptographic datapaths
- Secure key handling
- Hardware accelerators

---

# 🧪 Simulation and Verification

The RTL modules can be simulated using standard Verilog/SystemVerilog simulators.

### Recommended Tools

- **AMD Vivado**
- **EDA Playground**
- **Icarus Verilog**
- **Verilator**
- **Questa/ModelSim** where available

### Recommended Workflow

```text
RTL Design
    ↓
Testbench
    ↓
Compilation
    ↓
Simulation
    ↓
Waveform Analysis
    ↓
Functional Verification
    ↓
Synthesis
```

For SystemVerilog/UVM modules, a simulator with proper SystemVerilog/UVM support should be used.

---

# 🛠️ Languages and Technologies

### HDL

- Verilog HDL
- SystemVerilog

### Verification

- SystemVerilog Testbench
- Functional Coverage
- UVM

### Design Concepts

- Combinational Logic
- Sequential Logic
- FSM
- Datapath
- Pipelining
- Memory
- FIFO
- Clocking
- DSP
- Error Correction
- Cryptographic Hardware

---

# 📊 Design Philosophy

The repository follows several important RTL design principles.

### 1. Synthesizable RTL

Where applicable, designs are written with synthesis in mind rather than purely behavioral simulation.

### 2. Parameterization

Where useful, modules are designed to support configurable:

- Data width
- Address width
- Counter width
- Memory depth
- Arithmetic width

### 3. Modular Design

Complex designs are divided into reusable RTL blocks.

### 4. Verification-Oriented Development

Designs are accompanied by testbenches wherever practical.

### 5. Progressive Complexity

The repository deliberately moves from:

```text
RTL Fundamentals
      ↓
Advanced RTL
      ↓
Hardware Architecture
      ↓
SystemVerilog
      ↓
Verification
      ↓
UVM
      ↓
Security Hardware
```

---

# 📈 Learning Objectives

After working through this repository, the learner should have practical exposure to:

- Advanced Verilog RTL coding
- Synthesizable hardware design
- Datapath architecture
- Arithmetic hardware
- Pipelined architectures
- FSM design
- Memory architecture
- FIFO design
- Clocking and timing concepts
- LFSR/PRNG architectures
- DSP hardware
- Error-control hardware
- SystemVerilog programming
- Constrained randomization
- Functional coverage
- Self-checking testbenches
- UVM fundamentals
- Cryptographic hardware architectures

---

# 🎯 Relation to RTL/DV Career Preparation

This repository is particularly focused on skills relevant to:

- **RTL Design**
- **Design Verification**
- **Digital VLSI**
- **SoC Design**
- **Memory Design**
- **Hardware Security**
- **Digital Design Research**

The later sections provide a transition toward industry-oriented concepts such as:

```text
Parameterized RTL
       ↓
Pipelining
       ↓
Memory & FIFO
       ↓
SystemVerilog
       ↓
Functional Coverage
       ↓
UVM
       ↓
Advanced Interfaces
       ↓
Hardware Security
```

---

# 📚 Practice Methodology

For each module, the recommended workflow is:

1. Understand the hardware architecture.
2. Derive the required logic.
3. Write the RTL.
4. Create a testbench.
5. Simulate the design.
6. Inspect waveforms.
7. Verify corner cases.
8. Synthesize where applicable.
9. Review RTL quality.
10. Document the implementation.

For more advanced designs, additional verification techniques such as **assertions, constrained randomization, and functional coverage** can be incorporated.

---

# 🔬 Future Extensions

This repository can be extended with more advanced topics such as:

- SystemVerilog Assertions (SVA)
- Advanced CDC
- AXI4
- APB/AHB
- DMA architectures
- Cache controllers
- RISC-V RTL
- Bus interconnects
- DFT-oriented RTL
- Formal verification
- Advanced UVM
- Low-power RTL
- Clock-domain crossing verification

---

# ⚠️ Important Note

This repository is primarily intended as a **learning and practice collection**.

Some designs are based on concepts and reference implementations studied from publicly available educational RTL resources. The purpose of including them here is to understand the underlying architecture, implement the concepts, simulate them, and improve RTL and verification skills.

Where external implementations are used or adapted, the original source and applicable license should be respected.

---

# 👨‍💻 Author

**Bibhu Asish Panda**

**B.Tech — Electronics & Communication Engineering**

### Areas of Interest

- RTL Design
- Design Verification
- Digital VLSI
- Memory Design
- SystemVerilog
- UVM
- Hardware Security

---

# ⭐ Repository Goal

> **Learn → Design → Simulate → Verify → Synthesize → Improve**

This repository is a continuous RTL design practice platform aimed at progressing from **advanced Verilog development to SystemVerilog-based verification and industry-oriented digital hardware design**.
