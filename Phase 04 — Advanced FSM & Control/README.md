# Phase 04 — Advanced FSM & Control

## Overview

This phase focuses on Finite State Machines (FSMs) and control-oriented digital design using Verilog HDL. It explores how sequential logic can represent system states, evaluate input conditions, generate outputs, and control transitions between operating states.

The implementations cover one-shot FSMs, sequence generation, and sequence detectors using Mealy and Moore state-machine architectures. They also explore overlapping and non-overlapping sequence detection, providing practical exposure to state transitions, output-generation strategies, and sequential pattern recognition.

These concepts are fundamental to digital controllers, protocol logic, event-driven systems, and control units in larger RTL designs.

## Topics Covered

| No. | Topic | Description |
|---:|---|---|
| 041 | One-Shot FSM | Implements a finite state machine that responds to a triggering condition with a controlled, typically single-event output response. |
| 042 | FSM Sequence Generator | Uses state transitions to generate a predefined sequence of output values or control signals. |
| 043 | FSM Mealy Overlapping | Implements a Mealy sequence detector that permits a previously detected sequence to share bits with the next occurrence. |
| 044 | FSM Mealy Non-Overlapping | Implements a Mealy sequence detector that returns to an appropriate starting state after detection to prevent sequence overlap. |
| 045 | FSM Moore Overlapping | Implements a Moore sequence detector that allows overlapping occurrences of the target sequence, with outputs determined by the current state. |
| 046 | FSM Moore Non-Overlapping | Implements a Moore sequence detector that prevents overlapping detections, with outputs determined by the current state. |
| 047 | Two Sequence Detector Using FSM | Uses finite state machine logic to detect two target sequences according to the implemented transition and output conditions. |

## Technical Areas Explored

### 1. Finite State Machine Fundamentals

A Finite State Machine models sequential behavior using a finite set of states, input-dependent transition rules, and defined outputs.

Key concepts include:
- State representation and encoding.
- Current-state and next-state logic.
- State-transition conditions.
- Reset and initial-state behavior.
- Sequential output generation.
- Default transitions and handling unexpected states.

FSMs provide a structured way to implement control logic whose behavior depends on both current inputs and previous operating conditions.

### 2. Mealy and Moore Architectures

Mealy and Moore machines differ in how their outputs are generated.

Key concepts include:
- Mealy outputs depending on the current state and inputs.
- Moore outputs depending on the current state.
- Output timing relative to state transitions.
- State assignment and transition design.
- Trade-offs between state count and output behavior.

Understanding these architectures helps in selecting an appropriate FSM structure for a particular control or detection requirement.

### 3. Overlapping and Non-Overlapping Sequence Detection

Sequence detectors identify predefined patterns in a stream of input bits. Their transition logic must account for partial matches and the possibility of subsequent matches.

Key concepts include:
- Target-pattern recognition.
- Partial-match tracking.
- State transitions after successful detection.
- Overlapping sequence occurrences.
- Non-overlapping detection behavior.
- Correct output timing when a pattern is recognized.

An overlapping detector can reuse bits from one detected occurrence when searching for the next occurrence. A non-overlapping detector follows a transition strategy that prevents such reuse.

The exact transition behavior depends on the target pattern and the state-machine implementation.

### 4. Sequence Generation and Event Control

The one-shot FSM and sequence generator explore how state machines produce controlled responses and predefined output patterns.

Key concepts include:
- Trigger detection.
- State-dependent output generation.
- Controlled event responses.
- Sequence progression.
- Completion and return-to-idle behavior.
- Reset and retrigger handling.

These concepts are useful when implementing controllers that respond to events, execute ordered operations, or generate predetermined control sequences.

### 5. Multiple Sequence Detection

The two-sequence detector extends basic pattern recognition by supporting more than one target sequence.

Key concepts include:
- Multiple pattern-recognition paths.
- Shared and distinct transition states.
- Input-dependent state transitions.
- Detection-output conditions.
- Handling simultaneous or competing partial matches where relevant.

This topic introduces the additional design considerations involved in extending a single-pattern detector to recognize multiple patterns.

## Design and Verification Methodology

The FSM implementations can be studied using the following workflow:

1. **Define the behavior:** Identify the required states, inputs, outputs, reset conditions, and detection or completion criteria.
2. **Develop the state diagram:** Represent the possible states and transitions, including conditions for each transition.
3. **Write the RTL:** Implement current-state storage, next-state logic, and output-generation logic.
4. **Simulate input sequences:** Apply directed input patterns that exercise expected transitions and output behavior.
5. **Verify detection behavior:** Check successful matches, partial matches, overlapping occurrences, and non-overlapping operation as applicable.
6. **Test boundary conditions:** Examine reset during operation, repeated triggers, consecutive patterns, and unexpected input sequences.
7. **Inspect waveforms:** Track the current state, input, output, and detection timing across clock cycles.
8. **Evaluate implementation quality:** Where applicable, consider state count, logic complexity, output timing, and synthesis results.

For sequence detectors, verification should include both successful target patterns and near-matches that differ by one or more bits.

## Applications

The concepts covered in this phase are relevant to:

- **Digital controllers:** State-based control of system operations.
- **Protocol controllers:** Tracking protocol states and generating control signals.
- **Pattern recognition:** Detecting predefined serial input sequences.
- **Event-driven systems:** Triggering controlled responses to input events.
- **Processor control units:** Coordinating operations through state transitions.
- **Communication interfaces:** Recognizing command and control patterns.
- **Embedded digital systems:** Implementing deterministic control behavior.

## Learning Objectives

By completing this phase, the learner should be able to:

- Explain the structure and operation of a finite state machine.
- Develop state-transition logic using Verilog HDL.
- Distinguish Mealy and Moore state-machine architectures.
- Implement sequence generators and event-response controllers.
- Design overlapping and non-overlapping sequence detectors.
- Understand state transitions for multiple target sequences.
- Verify output timing relative to state transitions and input changes.
- Create testbenches for normal operation, partial matches, and boundary conditions.
- Analyze FSM behavior through simulation waveforms.
- Recognize the trade-offs between state-machine structure, logic complexity, and output latency.

## Tools and Technologies

- **Hardware Description Language:** Verilog HDL
- **Simulation:** Compatible Verilog simulators
- **Debugging:** Waveform analysis and state-transition inspection
- **Verification:** Directed input sequences and expected-output checking
- **Design analysis:** State diagrams, transition tables, and RTL inspection

Specific tools, verification coverage, and synthesis results should be documented for individual implementations when available.

## Scope and Limitations

This phase focuses on FSM-based control logic and sequence recognition. The descriptions of each circuit are based on their folder names; the exact target sequences, state encodings, output protocols, and implementation details depend on the corresponding RTL files.

Important considerations include:

- **Reset behavior:** State machines require a clearly defined reset and recovery strategy.
- **Output timing:** Mealy and Moore outputs can differ in when they respond to input changes and state transitions.
- **Sequence overlap:** Incorrect transition logic can cause missed detections or unintended repeated detections.
- **Retrigger behavior:** One-shot controllers must define whether and when a new trigger is accepted.
- **Multiple patterns:** Detecting several sequences can increase state-transition complexity.
- **Verification coverage:** Testing only a successful sequence is insufficient to establish correct behavior for partial matches and boundary cases.
- **Synthesis quality:** State encoding and logic structure can affect area and timing, depending on the implementation and target technology.

Functional simulation establishes behavior for the tested scenarios; synthesis and physical timing analysis are separate steps when implementation performance must be evaluated.

## Key Takeaway

Phase 04 develops the skills required to design sequential control logic using finite state machines. Through one-shot controllers, sequence generators, Mealy and Moore architectures, and overlapping and non-overlapping sequence detectors, it establishes a foundation for implementing reliable controllers and pattern-recognition logic in larger digital systems.