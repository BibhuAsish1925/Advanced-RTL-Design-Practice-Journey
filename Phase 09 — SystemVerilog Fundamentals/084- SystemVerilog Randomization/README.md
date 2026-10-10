We can now switch from **Verilog RTL practice → SystemVerilog-based verification environment**.

Your example is a good starting point because it introduces **classes, randomization, and constraints**, which are fundamental to SystemVerilog verification.

### 1. What your code is doing

```systemverilog
class test;

  rand bit [3:0] a;
  rand bit [3:0] b;

  constraint c1 {
    a > 2 && a < 10;
    b > 3 && b < 11;
  }

endclass
```

* `class test` → creates a SystemVerilog class.
* `rand` → tells the simulator that `a` and `b` should be randomized.
* `bit [3:0]` → 4-bit unsigned variables, range `0–15`.
* `constraint c1` → restricts the legal random values.

Therefore:

* `a`: **3–9**
* `b`: **4–10**

Then:

```systemverilog
t = new();
```

creates an object of the class.

And:

```systemverilog
t.randomize();
```

asks the SystemVerilog constraint solver to generate values satisfying `c1`.

### 2. Your testbench

```systemverilog
repeat(10) begin
  t.randomize();
  $display("a=%d b=%d", t.a, t.b);
end
```

This generates **10 different legal combinations**.

For example:

```text
a= 5 b= 9
a= 3 b= 6
a= 8 b=10
a= 4 b= 5
...
```

The exact sequence is not guaranteed because randomization is controlled by the simulator's random seed.

---

### 3. One important improvement

You should **check whether randomization succeeded**:

```systemverilog
if (!t.randomize())
  $error("Randomization failed");
```

So a better version is:

```systemverilog
class test;

  rand bit [3:0] a;
  rand bit [3:0] b;

  constraint c1 {
    a > 2 && a < 10;
    b > 3 && b < 11;
  }

endclass

module tb;

  test t;

  initial begin
    t = new();

    repeat (10) begin
      if (!t.randomize())
        $error("Randomization failed");

      $display("a=%0d b=%0d", t.a, t.b);
    end
  end

endmodule
```

I changed `%d` to `%0d` so the output is cleaner.

---

## How we'll build the SV verification environment

Since you're moving toward **RTL/DV**, I suggest we learn SystemVerilog in this progression:

```text
SystemVerilog Basics
        ↓
Classes & Objects
        ↓
Randomization
        ↓
Constraints
        ↓
Tasks & Functions
        ↓
Interfaces
        ↓
Modports
        ↓
Clocking Blocks
        ↓
Mailbox
        ↓
Events
        ↓
Generator
        ↓
Driver
        ↓
Monitor
        ↓
Reference Model
        ↓
Scoreboard
        ↓
Functional Coverage
        ↓
Assertions (SVA)
        ↓
Complete SV Verification Environment
        ↓
UVM Concepts
```

And importantly, we won't just study syntax. We'll gradually turn these concepts into an **industry-style non-UVM verification environment** around an RTL DUT.

### Our first stage

For now, focus on:

**Classes → Objects → `new()` → `rand` → `randomize()` → constraints → `pre_randomize()` / `post_randomize()` → constraint control.**

Your current example is therefore **Lesson 1: constrained randomization**.

Next, we can take this exact example and introduce **`inside`, `dist`, implication constraints, conditional constraints, and inline constraints** before moving into the actual verification components.
