# Phase 12 — Hardware Security & Cryptographic RTL

## Overview

This phase focuses on **hardware security, cryptographic algorithms, finite-field arithmetic, and specialized arithmetic architectures** implemented using RTL design concepts.

The topics span secure key storage, bus-access protection, cryptographic hashing, hardware watermarking, Galois Field operations, and multiplication algorithms used in cryptographic computations. The phase also introduces Montgomery arithmetic and ladder-based computation, along with Karatsuba multiplication for efficient large-operand arithmetic.

These topics demonstrate how digital hardware can support security-sensitive operations while exploring the architectural trade-offs involved in arithmetic complexity, resource utilization, control logic, and implementation efficiency.

## Topics Covered

| No. | Topic | Description |
|---|---|---|
| 113 | Zeroizable Key Register | Explores secure key storage with a mechanism intended to clear sensitive key material. |
| 114 | APB Firewall | Introduces access-control logic for protecting an APB-connected peripheral or address region. |
| 115 | ITA Algorithm | Covers an algorithm identified by the project folder as ITA; its exact expansion and implementation require source-code confirmation. |
| 116 | SHA-256 | Explores RTL implementation concepts associated with the SHA-256 cryptographic hash algorithm. |
| 117 | Watermarking | Examines hardware watermarking concepts for embedding identifying information in a design. |
| 118 | Xtime Basic | Introduces the Xtime operation commonly associated with multiplication by \(x\) in a binary finite field. |
| 119 | Galois Field Multiplier | Explores multiplication over a finite field, where arithmetic follows field-specific rules. |
| 120 | Mastrovito — 4-bit | Covers a 4-bit Mastrovito multiplier architecture, commonly associated with finite-field multiplication. |
| 121 | Montgomery Basic | Introduces Montgomery arithmetic for efficient modular multiplication. |
| 122 | Montgomery Ladder | Explores the ladder-based structure used in modular arithmetic and cryptographic computations. |
| 123 | Branch-Free Conditional Swap | Examines a conditional-swap helper associated with the Montgomery ladder and branch-free computation. |
| 124 | Karatsuba Multiplier Basic | Introduces the Karatsuba multiplication algorithm for reducing the number of recursive partial multiplications. |
| 125 | Recursive Karatsuba Multiplier | Explores recursive application of Karatsuba multiplication to larger operands. |

## Technical Areas Explored

### 1. Secure Key Storage and Zeroization

Cryptographic hardware may store sensitive values such as secret keys, intermediate key material, or other security-critical state. A zeroizable key register introduces a mechanism for clearing stored key data when required.

Key concepts include:

- Register-based storage of sensitive information.
- Controlled access to key registers.
- Zeroization control and clearing of stored values.
- Reset and control-signal behavior.
- Verification of key loading, retention, and clearing operations.

A zeroization mechanism can reduce the time sensitive data remains in a register, but it does not by itself guarantee complete protection against information leakage. Security also depends on reset behavior, access controls, data paths, residual copies, and the overall threat model.

### 2. APB Firewall

An APB firewall is associated with access-control logic around an Advanced Peripheral Bus (APB) interface. Depending on its design, it can restrict access to selected peripherals, address ranges, or transactions based on configured policies.

Key concepts include:

- Address and control-signal inspection.
- Access permission checks.
- Transaction acceptance or rejection.
- Protection of memory-mapped peripherals.
- Handling of permitted and denied transactions.
- Verification of access-control behavior.

The exact protection policy depends on the implementation. A firewall that checks only address ranges, for example, provides different security guarantees from one that also evaluates privilege attributes or other transaction metadata.

### 3. SHA-256 Cryptographic Hashing

SHA-256 is a cryptographic hash algorithm that maps an input message to a 256-bit digest. An RTL implementation must represent the algorithm's operations as digital logic and sequential processing.

Key concepts include:

- Message block processing.
- Message schedule generation.
- Fixed-width arithmetic.
- Bitwise logical operations.
- Rotation and shift operations.
- Round-based computation.
- Digest generation and output checking.

Correctness depends on implementing the specified word widths, constants, message padding, schedule, and round transformations accurately. Verification should compare generated digests against trusted reference vectors, including boundary cases involving message length and padding.

A hash function is not encryption: SHA-256 does not provide a way to recover the original message from its digest.

### 4. Hardware Watermarking

Hardware watermarking concerns embedding identifying information into a hardware design or its implementation. Depending on the method, the watermark may be associated with functional logic, design structure, or implementation-specific characteristics.

Key concepts include:

- Identifying information in a hardware design.
- Integration of watermark-related logic or structures.
- Design ownership and provenance.
- Functional correctness after watermark insertion.
- Potential effects on hardware overhead.
- Verification that the intended watermark can be detected.

The precise watermarking method used in this project is not established by the folder name alone. A complete assessment would require examining how the watermark is inserted, detected, and evaluated, including its effect on functionality and implementation cost.

### 5. Xtime and Galois Field Arithmetic

Galois Field arithmetic operates over a finite set of elements with defined addition and multiplication rules. Binary extension fields such as \(GF(2^m)\) are particularly relevant to cryptographic hardware.

In a common binary-field representation, addition corresponds to bitwise XOR. Multiplication involves polynomial operations followed by reduction using a field-defining polynomial.

The Xtime operation commonly denotes multiplication by \(x\), or the field element represented by the polynomial \(x\). Its RTL implementation typically involves a shift and conditional reduction, with the exact logic determined by the selected field polynomial and bit representation.

Key concepts include:

- Binary polynomial representation.
- XOR-based addition.
- Polynomial multiplication and reduction.
- Finite-field element representation.
- Conditional reduction logic.
- Fixed-width implementation of field operations.

The field polynomial and bit ordering must match the intended algorithm. A correct implementation for one field cannot automatically be assumed correct for another.

### 6. Galois Field and Mastrovito Multipliers

A Galois Field multiplier performs multiplication according to the rules of a specified finite field. The Mastrovito multiplier is a hardware architecture used for finite-field multiplication, including binary extension fields.

The listed 4-bit Mastrovito example provides a small-width context for studying the architecture.

Key concepts include:

- Finite-field multiplication.
- Partial-product generation.
- XOR-based logic structures.
- Polynomial reduction.
- Mapping mathematical expressions into combinational logic.
- Exploring architecture scaling with operand width.

Finite-field multiplication differs from ordinary unsigned integer multiplication because the result is reduced according to the field polynomial. The exact gate structure and resource requirements depend on the chosen field, architecture, and RTL coding style.

### 7. Montgomery Arithmetic

Montgomery arithmetic is a method for performing modular multiplication efficiently by representing values in a transformed domain and using a suitable reduction procedure.

It is useful in cryptographic computations involving repeated modular operations, including certain public-key cryptographic algorithms.

Key concepts include:

- Modular arithmetic.
- Montgomery representation.
- Modular multiplication.
- Reduction of intermediate results.
- Operand and modulus constraints.
- Conversion into and out of the Montgomery domain.

The implementation must satisfy the algorithm's mathematical assumptions, including the applicable modulus requirements. Word width, intermediate-product width, and reduction logic must be chosen carefully to avoid truncation and incorrect modular results.

### 8. Montgomery Ladder and Branch-Free Conditional Swap

The Montgomery ladder is a structured method for performing repeated operations in certain modular arithmetic and cryptographic algorithms. Ladder-based approaches can support regular computation patterns across successive input bits.

The branch-free conditional-swap helper is related to selecting or exchanging values without relying on a conventional data-dependent software branch.

Key concepts include:

- Ladder-based arithmetic sequencing.
- Conditional state or operand selection.
- Modular arithmetic operations.
- Fixed-width data manipulation.
- Control-flow regularity.
- Verification of conditional-swap correctness.

A branch-free implementation does not automatically guarantee constant-time execution or resistance to side-channel attacks. Hardware timing, switching activity, synthesis transformations, and the complete cryptographic datapath must also be evaluated.

### 9. Karatsuba Multiplication

Karatsuba multiplication is a divide-and-conquer algorithm that reduces the number of partial multiplications required when multiplying large operands.

Instead of directly calculating all partial products of a conventional split multiplication, the algorithm uses a different decomposition and additional additions or subtractions to reduce the multiplication count.

Key concepts include:

- Splitting operands into smaller portions.
- Computing partial products.
- Recombining intermediate results.
- Recursive arithmetic decomposition.
- Managing intermediate widths.
- Evaluating area and timing trade-offs.

The basic multiplier example provides an introduction to the algorithm, while the recursive multiplier explores applying the decomposition to progressively smaller subproblems.

In hardware, fewer multiplications do not necessarily mean a smaller or faster circuit in every implementation. Adders, multiplexers, routing, recursion depth, and synthesis decisions can significantly influence the final result.

## Design and Verification Methodology

A structured methodology for these examples can include the following steps:

1. **Understand the algorithm or security requirement:** Identify the mathematical operation, access policy, or sensitive-data handling requirement.
2. **Define the RTL interface:** Establish input operands, control signals, clocking, reset behavior, and output-valid or completion signaling as applicable.
3. **Determine arithmetic widths:** Account for intermediate products, carry propagation, modular reduction, and truncation.
4. **Implement the core logic:** Translate the algorithm into synthesizable combinational or sequential RTL as appropriate.
5. **Develop a reference model:** Use a trusted algorithmic model for hashing, finite-field operations, modular arithmetic, and multiplication.
6. **Create directed tests:** Exercise representative inputs, boundary values, reset behavior, and special conditions.
7. **Check security-related behavior:** Verify access denial, key clearing, and control-state transitions where those features are implemented.
8. **Compare against reference results:** Use known-answer tests or independently calculated expected values.
9. **Inspect waveforms and failures:** Examine control sequencing, intermediate results, arithmetic widths, and completion conditions.
10. **Evaluate implementation trade-offs:** Where tools and constraints are available, compare resource use and timing rather than assuming an architecture is inherently optimal.

Security-oriented RTL benefits from both functional verification and explicit security analysis. Passing functional tests alone does not establish resistance to side-channel attacks, fault injection, unauthorized access, or other hardware threats.

## Applications

The concepts covered in this phase are relevant to:

- **Cryptographic accelerators:** Implementing hashing and arithmetic operations in dedicated hardware.
- **Secure embedded systems:** Protecting sensitive data and controlling peripheral access.
- **Hardware security modules:** Supporting key storage and cryptographic operations.
- **Public-key cryptography:** Applying modular arithmetic and multiplication architectures.
- **Finite-field datapaths:** Implementing arithmetic used in cryptographic and coding applications.
- **IP protection:** Exploring hardware watermarking for design identification.
- **Arithmetic acceleration:** Investigating Karatsuba and specialized multiplier architectures.
- **Security verification:** Testing key-management behavior and access-control logic.

## Learning Objectives

By completing this phase, the intended learning outcomes are:

- Understand the purpose of zeroizable key registers and access-control firewalls.
- Recognize the main computational stages of SHA-256.
- Understand the distinction between hashing and encryption.
- Explore hardware watermarking concepts.
- Understand binary finite-field arithmetic and the Xtime operation.
- Study Galois Field and Mastrovito multiplier architectures.
- Understand the fundamentals of Montgomery modular arithmetic.
- Explore ladder-based computation and branch-free conditional swaps.
- Understand the basic and recursive forms of Karatsuba multiplication.
- Develop verification strategies for arithmetic and security-related RTL.
- Recognize the importance of operand width, reference models, and known-answer tests.
- Appreciate the difference between functional correctness and demonstrated hardware security.

## Tools and Technologies

The following tools and technologies may be relevant, depending on the actual implementation and simulator support:

- **Verilog/SystemVerilog:** RTL development and testbench creation.
- **RTL simulator:** Functional simulation and waveform generation.
- **Reference models:** Independent checking of cryptographic and arithmetic results.
- **Waveform viewer:** Inspection of sequential behavior, intermediate values, and control signals.
- **Synthesis tools:** Evaluation of mapped hardware structure and resource use.
- **Static analysis and linting:** Detection of coding issues, width mismatches, and suspicious constructs.
- **Formal verification tools:** Potential verification of selected functional properties and access-control behavior.

The exact tools used for the individual examples, as well as their simulation, synthesis, and verification results, should be documented only when confirmed from the project files and execution reports.

## Scope and Limitations

- Folder names identify the intended subject areas but do not establish the exact algorithms, coding styles, or implementation quality.
- The expansion and specific meaning of **ITA Algorithm** cannot be determined reliably from the folder name alone.
- The zeroization mechanism's completeness depends on the design and the locations in which sensitive information may be stored.
- APB firewall guarantees depend on the access policy and the transaction attributes actually checked.
- SHA-256 correctness requires conformance to the algorithm's complete specification, including padding and round processing.
- Finite-field arithmetic depends on the field polynomial, representation, and reduction rules.
- Montgomery arithmetic requires the appropriate modulus and representation constraints.
- A branch-free conditional swap alone does not prove constant-time operation or side-channel resistance.
- Karatsuba's hardware benefits depend on operand size, recursion strategy, synthesis, and implementation constraints.
- Hardware watermarking effectiveness depends on the insertion and detection approach and the threat model.
- No area, timing, power, security, or verification-coverage claims should be made without supporting measurements or evidence.

## Key Takeaway

**Phase 12 — Hardware Security & Cryptographic RTL** explores the intersection of digital design, cryptographic computation, and hardware protection.

From zeroizable key storage and APB access control to SHA-256, finite-field multiplication, Montgomery arithmetic, and Karatsuba multiplication, this phase builds a foundation for understanding how security-sensitive algorithms and arithmetic architectures can be translated into RTL.

The central engineering objective is to combine **mathematical correctness, synthesizable implementation, rigorous verification, and security-aware design practices**.