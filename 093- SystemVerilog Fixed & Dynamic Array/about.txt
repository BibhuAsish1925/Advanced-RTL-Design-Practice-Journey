 this is the next important SystemVerilog topic: **arrays**, specifically **dynamic arrays vs fixed-size arrays**.

# 1. Dynamic Array

Your declaration:

```systemverilog
int a[];
```

creates a **dynamic array**. Its size is determined during runtime.

Initially:

```systemverilog
a.size()
```

returns `0` because no storage has been allocated yet.

### Allocation

```systemverilog
a = new[4];
```

allocates four elements:

```text
a[0] a[1] a[2] a[3]
```

Then:

```systemverilog
a = {1,2,3,4};
```

assigns the values:

```text
a[0] = 1
a[1] = 2
a[2] = 3
a[3] = 4
```

---

## 2. Resizing while preserving data

This is the important part:

```systemverilog
a = new[6](a);
```

The syntax:

```text
new[new_size](old_array)
```

creates a new dynamic array of size `6` and copies the existing elements from the old array.

So:

```text
Before:

1  2  3  4


After new[6](a):

1  2  3  4  0  0
```

The first four elements are retained, while the newly allocated elements get their default value (`0` for `int`).

If instead you simply did:

```systemverilog
a = new[6];
```

the old array contents would **not** be retained.

---

## 3. `delete()`

```systemverilog
a.delete();
```

deallocates the dynamic array.

After that:

```systemverilog
a.size()
```

returns:

```text
0
```

So the dynamic-array lifecycle is:

```text
int a[]
    ↓
new[4]
    ↓
{1,2,3,4}
    ↓
new[6](a)
    ↓
delete()
```

### Key dynamic-array methods

| Operation       | Syntax          |
| --------------- | --------------- |
| Allocate        | `a = new[4]`    |
| Get size        | `a.size()`      |
| Resize + retain | `a = new[6](a)` |
| Delete          | `a.delete()`    |

---

# 4. Fixed-size array

Your second example:

```systemverilog
int a[4];
```

is a **fixed-size array**.

Its size is determined at compile time:

```text
a[0] a[1] a[2] a[3]
```

You cannot resize it using `new[]`.

You initialize it with:

```systemverilog
a = '{1,2,3,4};
```

Notice the difference from your dynamic array:

```systemverilog
a = {1,2,3,4};    // dynamic array assignment
```

versus:

```systemverilog
a = '{1,2,3,4};   // array literal
```

For fixed/unpacked arrays, the **`'{...}` assignment pattern** is the appropriate syntax.

---

# 5. Two-dimensional fixed array

You have:

```systemverilog
int b[4][2];
```

This represents:

```text
4 rows × 2 columns
```

So:

```text
       col0  col1
row0    1     0
row1    2     0
row2    3     0
row3    4     0
```

Your initialization:

```systemverilog
b = '{'{1,0},'{2,0},'{3,0},'{4,0}};
```

creates exactly that matrix.

Access:

```systemverilog
b[i][j]
```

where:

* `i` = row
* `j` = column

---

# 6. Dynamic vs Fixed array

| Feature     | Fixed array        | Dynamic array      |
| ----------- | ------------------ | ------------------ |
| Declaration | `int a[4]`         | `int a[]`          |
| Size        | Compile time       | Runtime            |
| Resize      | ❌                  | ✓                  |
| `size()`    | Not normally used  | ✓                  |
| `delete()`  | ❌                  | ✓                  |
| `new[]`     | ❌                  | ✓                  |
| Useful for  | Known-size storage | Variable-size data |

---

## Verification relevance

Dynamic arrays become very useful when a transaction contains a **variable-length payload**:

```systemverilog
class packet;
  rand bit [7:0] data[];

  function void create_packet(int size);
    data = new[size];
  endfunction
endclass
```

For example:

```text
Packet 1 → 4 bytes
Packet 2 → 16 bytes
Packet 3 → 64 bytes
```

You don't need to declare a maximum fixed array unnecessarily.

This is especially relevant when we later build your **transaction → generator → driver → monitor → scoreboard** environment.
