module min_pw_qual_tb;

  localparam MIN_PW_ASSERT   = 2;
  localparam MIN_PW_DEASSERT = 2;
  localparam CLK_PERIOD      = 10;

  reg  clk;
  reg  rst_n;
  reg  sig_i;
  wire sig_o;

  min_pw_qual #(
    .MIN_PW_ASSERT   (MIN_PW_ASSERT),
    .MIN_PW_DEASSERT (MIN_PW_DEASSERT)
  ) dut (
    .clk   (clk),
    .rst_n (rst_n),
    .sig_i (sig_i),
    .sig_o (sig_o)
  );

  // Clean clock generation (delay-first, no race at time 0)
  initial clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  initial begin
    $monitor("t=%0t\t sig_i=%b sig_o=%b", $time, sig_i, sig_o);

    // Reset
    rst_n = 1'b0;
    sig_i = 1'b0;
    #(CLK_PERIOD*2);
    rst_n = 1'b1;

    // Test 1: short high glitch (1 cycle) - shorter than MIN_PW_ASSERT,
    // sig_o should NOT assert
    #(CLK_PERIOD*2);
    sig_i = 1'b1;
    #(CLK_PERIOD*1);
    sig_i = 1'b0;
    #(CLK_PERIOD*4);

    // Test 2: sustained high (5 cycles) - should assert sig_o
    // after MIN_PW_ASSERT cycles
    sig_i = 1'b1;
    #(CLK_PERIOD*5);

    // Test 3: short low glitch (1 cycle) while asserted - shorter than
    // MIN_PW_DEASSERT, sig_o should stay high
    sig_i = 1'b0;
    #(CLK_PERIOD*1);
    sig_i = 1'b1;
    #(CLK_PERIOD*4);

    // Test 4: sustained low (5 cycles) - should deassert sig_o
    // after MIN_PW_DEASSERT cycles
    sig_i = 1'b0;
    #(CLK_PERIOD*5);

    $finish;
  end

endmodule