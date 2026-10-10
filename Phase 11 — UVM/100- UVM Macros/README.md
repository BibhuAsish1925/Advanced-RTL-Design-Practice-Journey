## 1. Circuit Overview & Applications

This example demonstrates UVM Reporting and Verbosity Control in SystemVerilog UVM.

It shows how the `uvm_info` macro generates informational messages at different verbosity levels and how the global UVM verbosity setting controls which messages are displayed.

Applications:

- Debugging UVM testbenches
- Controlling simulation log output
- Filtering messages during verification
- Managing debug information in large UVM environments

## 2. Circuit Working & RTL Implementation

The `my_test` class extends `uvm_test` and implements the `run_phase`.

It uses:

```
phase.raise_objection(this);
```

to keep the UVM run phase active while the test executes, and:

```
phase.drop_objection(this);
```

to allow the phase to finish.

Four informational messages are generated:

```
`uvm_info("TEST", "UVM_LOW message", UVM_LOW);
`uvm_info("TEST", "UVM_MEDIUM message", UVM_MEDIUM);
`uvm_info("TEST", "UVM_HIGH message", UVM_HIGH);
`uvm_info("TEST", "UVM_FULL message", UVM_FULL);
```

The top module sets the global verbosity:

```
uvm_top.set_report_verbosity_level(UVM_HIGH);
```

With `UVM_HIGH` selected, messages at `UVM_LOW`, `UVM_MEDIUM`, and `UVM_HIGH` are displayed, while the `UVM_FULL` message is filtered out.

### UVM verbosity levels

| Level        | Value | Behavior at `UVM_HIGH` setting |
| ------------ | ----- | ------------------------------ |
| `UVM_NONE`   | 0     | Displayed                      |
| `UVM_LOW`    | 100   | Displayed                      |
| `UVM_MEDIUM` | 200   | Displayed                      |
| `UVM_HIGH`   | 300   | Displayed                      |
| `UVM_FULL`   | 400   | Filtered                       |
| `UVM_DEBUG`  | 500   | Filtered                       |

Higher verbosity settings permit more detailed messages.

## 3. Verification & Testbench

The `uvm_reporting_tb` top module:

1. Sets the global verbosity level to `UVM_HIGH`.
2. Starts the test using `run_test("my_test")`.
3. Allows the test to generate messages at four verbosity levels.
4. Demonstrates how verbosity filtering affects simulation output.

This is a UVM framework demonstration, not a DUT functional verification test. It does not require a hardware design or scoreboard.

## 4. Advantages & Limitations

Advantages

- Simple demonstration of UVM reporting macros
- Controls the amount of simulation log output
- Helps distinguish routine messages from detailed debugging information
- Uses standard UVM test and phase mechanisms

Limitations

- No DUT or functional checking
- No error or warning reporting examples
- Demonstrates only global verbosity control, not component-specific settings

## 5. Interview Takeaways

- What does `uvm_info` do? Generates an informational report message with an ID, message text, and verbosity level.
- What does `UVM_HIGH` mean? Messages with verbosity at or below the configured threshold are eligible for display.
- What happens to `UVM_FULL` here? It is filtered because its verbosity exceeds `UVM_HIGH`.
- Why use objections? They control when a UVM phase can finish.
- What does `run_test("my_test")` do? Starts the UVM test through the UVM factory mechanism.

### Repository classification

Status: DONE — UVM Reporting & Verbosity Control

This example complements your existing UVM components, hierarchy, factory, and verification-environment exercises by covering an essential UVM debugging and log-management feature.