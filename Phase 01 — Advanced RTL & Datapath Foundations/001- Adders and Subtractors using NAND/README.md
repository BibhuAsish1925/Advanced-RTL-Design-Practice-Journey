## 1. Circuit Overview & Applications

Topic: Half Adder, Half Subtractor, Full Adder, and Full Subtractor Using NAND Gates

These four modules implement basic arithmetic circuits using only NAND gates. NAND is a universal gate, meaning these circuits can be constructed without directly using AND, OR, or XOR gates.

- `ha_nand` — Half adder
- `hs_nand` — Half subtractor
- `fa_nand` — Full adder
- `fs_nand` — Full subtractor

Applications include arithmetic logic units (ALUs), digital arithmetic circuits, and fundamental combinational logic design.

## 2. Circuit Working & RTL Implementation

### Half Adder — `ha_nand`

Inputs: `a`, `b`; outputs: `sout`, `cout`.

- Sum: \\(S=A\oplus B\\)
- Carry: \\(C=A\cdot B\\)

The first three NAND gates generate intermediate signals used to implement XOR. The remaining gates produce the sum and carry outputs.

### Half Subtractor — `hs_nand`

Inputs: `a`, `b`; outputs: `sout`, `cout`.

- Difference: \\(D=A\oplus B\\)
- Borrow: \\(B\_{\text{out}}=\overline{A}\cdot B\\)

The XOR network generates the difference, while the final NAND gate combination generates the borrow output.

### Full Adder — `fa_nand`

Inputs: `a`, `b`, `cin`; outputs: `sout`, `cout`.

- Sum: \\(S=A\oplus B\oplus C\_{\text{in}}\\)
- Carry: \\(C\_{\text{out}}=AB+C\_{\text{in}}(A\oplus B)\\)

The circuit first computes the XOR of `a` and `b`, then combines that intermediate result with `cin` to generate the sum and carry.

### Full Subtractor — `fs_nand`

Inputs: `a`, `b`, `bin`; outputs: `sout`, `cout`.

- Difference: \\(D=A\oplus B\oplus B\_{\text{in}}\\)
- Borrow: \\(B\_{\text{out}}=\overline{A}B+\overline{(A\oplus B)}B\_{\text{in}}\\)

The circuit calculates the difference using NAND-based XOR logic and generates the borrow output through the final NAND gate combination.

Important RTL observation: The full adder and full subtractor use the same intermediate NAND network, but their final carry/borrow connections differ.

## 3. Verification & Testbench

All four modules are combinational circuits, so their outputs depend directly on the current inputs. A testbench should exhaustively test every input combination.

| Circuit         | Input combinations | Expected outputs      |
| --------------- | ------------------ | --------------------- |
| Half adder      | 4                  | Sum and carry         |
| Half subtractor | 4                  | Difference and borrow |
| Full adder      | 8                  | Sum and carry         |
| Full subtractor | 8                  | Difference and borrow |

For verification, compare each output against its corresponding arithmetic truth table. No clock is required.

## 4. Advantages & Limitations

Advantages

- Demonstrates NAND as a universal logic gate.
- Builds arithmetic functions from gate-level primitives.
- Helps develop understanding of XOR, carry, and borrow generation.

Limitations

- Multiple gate stages can introduce propagation delay.
- Gate-level implementations may be less readable than behavioral RTL.
- The supplied modules do not include testbenches or timing analysis.

## 5. Interview Takeaways

- A half adder adds two bits; a full adder adds two bits plus carry-in.
- A half subtractor subtracts two bits; a full subtractor includes borrow-in.
- NAND is a universal gate and can implement XOR, AND, and NOT functions.
- Carry and borrow are distinct outputs with different Boolean expressions.
- Gate-level RTL describes how a circuit is constructed, rather than only specifying its arithmetic behavior.

Status: Reviewed — NAND-Based Adders and Subtractors.