this demonstrates a **weighted constraint using the `dist` operator** in SystemVerilog.

### 1. Your constraint

```systemverilog id="u8v6zi"
constraint c1 {
  var1 dist {5 := 3, 2 := 6, 7 := 3};
};
```

This tells the randomization solver to assign **different weights** to the possible values:

| `var1` | Weight |
| -----: | -----: |
|      5 |      3 |
|      2 |      6 |
|      7 |      3 |

Total weight:

```text id="c9d6d4"
3 + 6 + 3 = 12
```

Therefore, the relative distribution is approximately:

* `var1 = 5` → **3/12 = 25%**
* `var1 = 2` → **6/12 = 50%**
* `var1 = 7` → **3/12 = 25%**

So `2` is given **twice the weight** of `5` or `7`.

---

### 2. Important point about `:=`

You used:

```systemverilog
5 := 3
```

`:=` assigns the specified weight to **that value**.

For your example:

```text id="2d3j8n"
5 → weight 3
2 → weight 6
7 → weight 3
```

The solver uses these as **relative weights**, not guaranteed exact percentages.

So with only 10 iterations, you might see:

```text id="r8j4xp"
var1=2
var1=7
var1=2
var1=5
var1=2
var1=2
var1=5
var1=7
var1=2
var1=5
```

You should **not expect exactly 5 occurrences of `2`, 2.5 occurrences of `5`, etc.** in only 10 samples.

With many more randomizations, the observed distribution should tend toward the specified proportions.

---

### 3. Why weighted constraints are useful

In verification, completely uniform randomization may not represent the scenarios you care about equally.

For example:

```systemverilog
constraint c1 {
  opcode dist {
    4'b0000 := 5,
    4'b0001 := 2,
    4'b0010 := 1
  };
}
```

You can make one operation occur more frequently while still allowing other operations to appear.

This is useful for creating **biased constrained-random stimulus**.

---

### 4. `:=` vs `:/`

There are two important forms:

#### `:=` — weight applies to each value

```systemverilog
var1 dist {
  [1:3] := 6
};
```

Each value gets weight `6`:

```text
1 → 6
2 → 6
3 → 6
```

#### `:/` — weight is distributed across the range

```systemverilog
var1 dist {
  [1:3] :/ 6
};
```

The total weight of the range is `6`, so each value effectively gets:

```text
1 → 2
2 → 2
3 → 2
```

This distinction is commonly asked in SystemVerilog interviews.

### Interview answer

> **The `dist` constraint provides weighted randomization. The weights control the relative probability of values being selected, allowing verification environments to generate biased constrained-random stimulus instead of uniformly distributed stimulus.**

Your current progression is:

```text
rand
  ↓
constraints
  ↓
pre_randomize / post_randomize
  ↓
inline constraints
  ↓
weighted constraints (`dist`)
```

Next logical topic is **`inside` constraint**, which is commonly used to restrict a variable to a set or range of legal values.
