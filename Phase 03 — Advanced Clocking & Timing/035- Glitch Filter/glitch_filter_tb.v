module glitch_filter_tb;

  localparam STABLE_CYCLES = 4;
  localparam CLK_PERIOD    = 10;

  reg  clk;
  reg  rst_n;
  reg  in_n;
  wire out_n;

  glitch_filter #(.STABLE_CYCLES(STABLE_CYCLES)) dut (
    .clk   (clk),
    .rst_n (rst_n),
    .in_n  (in_n),
    .out_n (out_n)
  );

  // Clean clock generation (delay-first, no race with initial block)
  initial clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  initial begin
    $monitor("t=%0t\t clk=%b rst_n=%b in_n=%b out_n=%b", $time, clk, rst_n, in_n, out_n);

    // Reset
    rst_n = 1'b0;
    in_n  = 1'b1;   // idle (not asserted)
    #(CLK_PERIOD*2);
    rst_n = 1'b1;

    // Test 1: short glitch (1 cycle low) - should be FILTERED, out_n stays 1
    #(CLK_PERIOD*3);
    in_n = 1'b0;
    #(CLK_PERIOD*1);
    in_n = 1'b1;

    // Hold idle for a few cycles so filter settles before next test
    #(CLK_PERIOD*6);

    // Test 2: genuine assertion, held for 6 cycles (>= STABLE_CYCLES)
    // out_n should transition to 0 after STABLE_CYCLES clocks
    in_n = 1'b0;
    #(CLK_PERIOD*6);

    // Test 3: release back to idle, held long enough to commit
    in_n = 1'b1;
    #(CLK_PERIOD*6);

    // Test 4: another short glitch while idle - should be FILTERED again
    in_n = 1'b0;
    #(CLK_PERIOD*2);
    in_n = 1'b1;
    #(CLK_PERIOD*6);

    $finish;
  end

endmodule