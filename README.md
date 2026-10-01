# Advanced RTL Design Practice

A structured collection of **Verilog/SystemVerilog RTL, digital design, memory, arithmetic, DSP, verification, UVM, and hardware-security practice modules**.

The repository follows a progressive path from **RTL implementation → hardware architecture → verification → advanced digital design**.

---

## 📌 Repository Overview

This repository covers:

- Advanced RTL Design
- Arithmetic & Datapath Architectures
- Clocking & Timing
- FSM Design
- Memory & Storage
- LFSR & Randomization
- DSP & Data Processing
- Error Detection & Correction
- SystemVerilog
- Functional Coverage
- SystemVerilog Verification
- UVM
- Hardware Security & Cryptography

> Detailed circuit explanations, working principles, RTL analysis, testbench analysis, advantages, limitations, and interview notes are maintained inside the respective module folders.

---

## 🧭 Learning Path

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
````

---

## 📂 Repository Structure

```text
Advanced-RTL-Design-Practice/
│
├── 01_Advanced_RTL_Datapath/
├── 02_Advanced_Arithmetic/
├── 03_Clocking_and_Timing/
├── 04_Advanced_FSM/
├── 05_Memory_and_Storage/
├── 06_LFSR_and_Randomization/
├── 07_DSP_and_Data_Processing/
├── 08_Error_Detection_and_Correction/
├── 09_SystemVerilog/
├── 10_Functional_Coverage/
├── 11_SystemVerilog_Verification/
├── 12_UVM/
├── 13_Hardware_Security_and_Cryptography/
│
└── README.md
```

---

# 1️⃣ Advanced RTL Datapath

**Focus:** RTL modeling, reusable datapaths, timing, and modular hardware.

### Topics

* Advanced RTL Modeling
* Structural & Behavioral RTL
* Switch-Level Modeling
* Parameterized Registers
* Endianness Conversion
* Delay Modeling
* Pipeline Registers
* Pipeline Shift Registers
* Dual-Edge Flip-Flops
* Priority Resolution
* MUX-Based Logic

---

# 2️⃣ Advanced Arithmetic

**Focus:** Hardware-oriented arithmetic architectures and algorithm mapping.

### Topics

* Carry Select Adder
* Carry Skip Adder
* Carry Look-Ahead
* Booth Multiplication
* Sequential & Array Multiplication
* Pipelined Multiplication
* Division
* Fixed-Point Arithmetic
* Parameterized Arithmetic
* GCD
* Matrix Multiplication
* Prime Checking
* Palindrome Checking
* Factorial
* Square/Cube Root

---

# 3️⃣ Clocking & Timing

**Focus:** Clock generation, timing behavior, frequency control, and clock management.

### Topics

* Frequency Dividers
* Odd/Even Division
* Decimal Division
* Clock Phase Generation
* Edge Detection
* Delay Modeling
* Glitch Filtering
* Glitch-Free Clock Gating
* Clock-Gating Control
* Pulse-Width Qualification
* Frequency Monitoring
* Period Monitoring
* Randomized Clock Enable

---

# 4️⃣ Advanced FSM

**Focus:** State-machine architecture and sequence detection.

### Topics

* One-Hot FSM
* Sequence Generator
* Mealy FSM
* Moore FSM
* Overlapping Detection
* Non-Overlapping Detection
* Multiple Sequence Detection

---

# 5️⃣ Memory & Storage

**Focus:** Memory architectures, data storage, FIFO structures, and CDC concepts.

### ROM

* Asynchronous ROM
* ROM Using `case`
* ROM-Based ALU Decoder

### RAM

* Asynchronous RAM
* Large-Capacity RAM

### FIFO / Stack

* Advanced FIFO
* Asynchronous FIFO
* Almost-Full / Almost-Empty FIFO
* LIFO / Stack

---

# 6️⃣ LFSR & Randomization

**Focus:** Pseudo-random sequence generation and hardware randomness.

### Topics

* LFSR
* Pseudo-Random Sequence Generation
* Galois LFSR
* Tiny Galois LFSR
* FPGA-Based TRNG

---

# 7️⃣ DSP & Data Processing

**Focus:** Hardware implementation of signal-processing and computational algorithms.

### Topics

* PWM
* Sine-Wave Generation
* MAC
* Pipelined MAC
* FIR Filter
* Moving-Average Filter
* Digital Convolution
* CORDIC
* Fixed-Point DSP
* TPU-Style Hardware Acceleration

---

# 8️⃣ Error Detection & Correction

**Focus:** RTL implementation of digital error-control techniques.

### Topics

* CRC
* CRC-16
* CRC-32
* Hamming Code ECC
* Reed-Solomon Encoder
* Viterbi Decoder

---

# 9️⃣ SystemVerilog

**Focus:** Modern SystemVerilog language and verification features.

### Topics

* Randomization
* Constraints
* Pre/Post-Randomization
* Inline & Weighted Constraints
* `inside`
* Enumerations
* Fixed & Dynamic Arrays
* Packages
* Mailboxes
* Semaphores
* Classes
* Inheritance
* Encapsulation
* Polymorphism

---

# 🔟 Functional Coverage

**Focus:** Measuring functional verification completeness.

### Topics

* Implicit Coverage Bins
* Explicit Coverage Bins
* Coverpoints
* Functional Scenario Coverage

---

# 1️⃣1️⃣ SystemVerilog Verification

**Focus:** Automated and self-checking verification environments.

### Topics

* Self-Checking D Flip-Flop TB
* Self-Checking FIFO TB
* SystemVerilog TB Architecture
* Stimulus Generation
* Drivers
* Monitors
* Checkers
* Scoreboards

---

# 1️⃣2️⃣ UVM

**Focus:** Structured, reusable, object-oriented Design Verification.

### Topics

* UVM Macros
* Reporting & Verbosity
* Field Automation
* Integer / Enum / Array Fields
* Copy & Clone
* Shallow vs Deep Copy
* Factory Override
* Build Phase
* End-of-Elaboration
* Combinational Adder Environment
* Sequential Adder Environment
* APB Verification Environment

### Verification Flow

```text
Sequence
   ↓
Sequencer
   ↓
Driver
   ↓
DUT
   ↓
Monitor
   ↓
Scoreboard
```

---

# 1️⃣3️⃣ Hardware Security & Cryptography

**Focus:** Security-oriented RTL, cryptographic arithmetic, and secure hardware architectures.

### Topics

* Zeroizable Key Register
* APB Firewall
* True Random Number Generator
* Finite-Field Multiplication
* ITA Algorithm
* SHA-256
* Hardware Watermarking
* XTIME
* Galois-Field Multiplication
* Mastrovito Multiplier
* Montgomery Multiplication
* Montgomery Ladder
* Branch-Free Conditional Swap
* Karatsuba Multiplication
* Hardware Security Module Architecture

---

# 🧪 Simulation & Verification

The modules are intended for **simulation, functional verification, learning, and synthesis experimentation**.

### Tools

* **AMD Vivado**
* **EDA Playground**
* **Icarus Verilog**
* **Verilator**
* **Questa / ModelSim**

### General Workflow

```text
Understand
   ↓
Design RTL
   ↓
Create Testbench
   ↓
Simulate
   ↓
Verify
   ↓
Analyze Waveforms
   ↓
Synthesize
   ↓
Review RTL
```

### Verification Techniques

* Directed Testing
* Self-Checking Testbenches
* Reference Models
* Assertions
* Constrained Randomization
* Functional Coverage
* Scoreboards
* UVM

---

# 🛠️ Languages & Technologies

### HDL

* Verilog
* SystemVerilog

### Verification

* SystemVerilog Testbenches
* Self-Checking Verification
* Constrained Randomization
* Functional Coverage
* UVM

### Design

* Combinational & Sequential Logic
* FSM
* Datapaths
* Arithmetic Hardware
* Pipelining
* Memory & FIFO
* Clocking
* DSP
* ECC
* Hardware Security
* Cryptographic Hardware

---

# 📐 Design Philosophy

The repository emphasizes:

* **Synthesizable RTL**
* **Parameterized Designs**
* **Modular Architecture**
* **Reusable Hardware**
* **Verification-Oriented Development**
* **Progressive Complexity**
* **Hardware-Aware Algorithm Implementation**

```text
RTL
 ↓
Architecture
 ↓
Simulation
 ↓
Verification
 ↓
Synthesis
 ↓
Analysis
```

---

# 🎯 RTL / DV Career Relevance

This repository provides practical exposure to areas relevant to:

* RTL Design
* Design Verification
* Digital VLSI
* Memory Design
* SoC Design
* Hardware Security

### Design → Verification Progression

```text
RTL Design
   ↓
Datapath & Memory
   ↓
Pipelining & Clocking
   ↓
SystemVerilog
   ↓
Self-Checking Verification
   ↓
Constrained Randomization
   ↓
Functional Coverage
   ↓
UVM
   ↓
Protocol Verification
   ↓
Hardware Security
```

---

# 🚀 Future Extensions

### Verification

* SystemVerilog Assertions
* Advanced Functional Coverage
* Coverage-Driven Verification
* Advanced UVM
* RAL
* Formal Verification

### SoC / Interfaces

* AXI4
* AXI4-Lite
* APB
* AHB-Lite
* DMA
* Bus Interconnects
* Interrupt Controllers
* Cache Controllers
* Memory Controllers

### Digital Architecture

* RISC-V RTL
* CPU Datapaths
* Pipelined Processors
* Cache Hierarchy
* On-Chip Memory
* Hardware Accelerators

### Reliability / Low Power

* CDC
* RDC
* Low-Power RTL
* Power-Aware Verification
* DFT-Oriented RTL

### Hardware Security

* Secure Boot
* Cryptographic Accelerators
* Side-Channel-Resistant RTL
* Secure Key Management
* PUFs
* Hardware Security Modules

---

# ⚠️ Important Note

This repository is primarily a **learning and RTL practice collection**.

Some modules are based on concepts or reference implementations from publicly available educational resources. The purpose is to study the architecture, implement the concepts, simulate them, and improve RTL/DV skills.

Where external implementations are used or adapted, the original source and applicable license should be respected.

---

# 👨‍💻 Author

**Bibhu Asish Panda**

**B.Tech — Electronics & Communication Engineering**

### Areas of Interest

* RTL Design
* Design Verification
* Digital VLSI
* Memory Design
* SystemVerilog
* UVM
* Hardware Security

---

# ⭐ Repository Goal

> **Learn → Design → Simulate → Verify → Synthesize → Improve**

A continuous RTL/DV practice platform progressing from **advanced Verilog RTL to SystemVerilog verification, UVM, memory design, and industry-oriented digital hardware concepts**.

```

This version removes essentially all **circuit-level explanations** from the root README while still keeping enough information for someone visiting the repository to understand **what the repository contains, how it is organized, and what skills it covers**.

I would **not make the README any shorter than this** if it is intended as your main GitHub repository README—the individual folder/module documentation can now carry all the technical depth.
```
