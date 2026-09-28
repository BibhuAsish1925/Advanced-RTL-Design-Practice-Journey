# 9-BIT ARMSTRONG NUMBER DETECTOR

## 1. CIRCUIT OVERVIEW & APPLICATIONS

This design is a **9-bit combinational Armstrong-number detector**. It checks whether the input number is equal to the sum of the cubes of its decimal digits.

For a 3-digit number:

$$
N = d_2d_1d_0
$$

the Armstrong condition is:

$$
N = d_2^3+d_1^3+d_0^3
$$

For example:

$$
153 = 1^3+5^3+3^3
$$

$$
153 = 1+125+27 = 153
$$

Therefore, `153` is detected as an Armstrong number.

The 9-bit input can represent values from **0 to 511**.

### Applications

* Mathematical/computational hardware
* Algorithm-to-RTL demonstrations
* Decimal digit extraction and arithmetic
* Hardware learning exercises involving functions, division, and modulo operations

---

# 2. CIRCUIT WORKING & RTL IMPLEMENTATION

The main operation is:

```text
                 ┌─────────────────────┐
number ─────────>│  Armstrong Checker  │
                 │                     │
                 │ Extract decimal     │
                 │ digits using % 10   │
                 │        ↓            │
                 │ Cube each digit     │
                 │        ↓            │
                 │ Accumulate cubes    │
                 │        ↓            │
                 │ Compare with number │
                 └──────────┬──────────┘
                            │
                            ▼
                       is_armstrong
```

The function:

```verilog
function check_armstrong;
```

contains the actual Armstrong-number algorithm.

### Initialization

```verilog
result = 9'd0;
temp_num = num;
```

`result` accumulates the sum of digit cubes, while `temp_num` is used to extract the digits without modifying the original input.

---

### Extracting each decimal digit

```verilog
remainder = temp_num % 10;
```

The modulo operation extracts the least-significant decimal digit.

For example:

```text
153 % 10 = 3
15  % 10 = 5
1   % 10 = 1
```

Then:

```verilog
result = result + (remainder * remainder * remainder);
```

adds the cube of that digit.

For `153`:

```text
3³ = 27
5³ = 125
1³ = 1

result = 27 + 125 + 1
       = 153
```

---

### Removing the processed digit

```verilog
temp_num = temp_num / 10;
```

Integer division removes the least-significant decimal digit.

Therefore:

```text
153 → 15 → 1 → 0
```

and the loop terminates.

---

### Final comparison

```verilog
if (result == num)
    check_armstrong = ARMSTRONG;
else
    check_armstrong = Not_ARMSTRONG;
```

Thus:

```text
result == original number → is_armstrong = 1
result != original number → is_armstrong = 0
```

The main `always` block then assigns the function result:

```verilog
is_armstrong = check_armstrong(number);
```

and prints the classification using `$display`.

---

# 3. VERIFICATION & TESTBENCH

The testbench applies six values:

| Number | Expected result |
| -----: | --------------- |
|    153 | Armstrong       |
|    300 | Not Armstrong   |
|    370 | Armstrong       |
|    190 | Not Armstrong   |
|    407 | Armstrong       |
|    420 | Not Armstrong   |

The testbench changes the input every 10 ns:

```verilog
number=9'd153;
#10;
number=9'd300;
#10;
...
```

The DUT itself prints the result through:

```verilog
$display("\t\t %d is a armstrong number", number);
```

or:

```verilog
$display("\t\t %d is not an armstrong number", number);
```

So the expected classifications are:

```text
153 → Armstrong
300 → Not Armstrong
370 → Armstrong
190 → Not Armstrong
407 → Armstrong
420 → Not Armstrong
```

The simulation terminates after 60 ns:

```verilog
initial #60 $finish;
```

### Verification limitation

The current TB is **not self-checking**. It relies on the `$display` statements inside the DUT.

A stronger verification approach would keep the DUT free of `$display` statements and let the testbench compare:

```text
actual is_armstrong
        vs.
expected result
```

and generate explicit `PASS/FAIL` messages.

---

# 4. ADVANTAGES & LIMITATIONS

### Advantages

* Simple algorithm.
* Function encapsulates the Armstrong calculation.
* Combinational operation with no clock or reset.
* Reusable `check_armstrong` function.
* Easy to simulate and understand.
* Demonstrates decimal digit extraction using `%` and `/`.

### Limitations

The major hardware concern is the use of:

```verilog
%
/
```

with decimal arithmetic.

Although the algorithm is simple in software, division and modulo operations can synthesize into relatively expensive hardware.

Also, the `while` loop creates a variable number of iterations depending on the input.

For a practical ASIC/FPGA implementation, an **iterative clocked architecture** could reduce combinational area by processing one decimal digit per cycle.

Another point is that the design is specifically checking the **sum of cubes of decimal digits**. It is therefore appropriate for the 3-digit Armstrong definition used by this code; it is not a generalized arbitrary-digit Armstrong implementation.

---

# 5. INTERVIEW TAKEAWAYS

**Core concept:** Extract each decimal digit, cube it, accumulate the cubes, and compare the result with the original number.

**Algorithm:**

```text
temp_num = number
result = 0

while temp_num != 0:
    digit = temp_num % 10
    result = result + digit³
    temp_num = temp_num / 10

if result == number:
    Armstrong
else:
    Not Armstrong
```

**Key RTL concepts demonstrated:**

* Combinational `always`
* Verilog function
* `while` loop
* `%` modulo operator
* `/` division operator
* Temporary registers
* Accumulation
* Function return value

**One-line interview explanation:**

> “This RTL implements a combinational Armstrong-number detector by repeatedly extracting decimal digits, adding their cubes, and comparing the accumulated result with the original 9-bit input.”
