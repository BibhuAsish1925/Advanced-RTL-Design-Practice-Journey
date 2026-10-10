module clk_glitch_monitor_tb;

  localparam MIN_PERIOD    = 10;
  localparam MAX_PERIOD    = 100;
  localparam CW            = 16;
  localparam REF_PERIOD    = 10; // ns per clk_ref cycle

  reg  clk_ref;
  reg  rst_n;
  reg  clk_mon;
  wire fault;

  clk_glitch_monitor #(
    .MIN_PERIOD (MIN_PERIOD),
    .MAX_PERIOD (MAX_PERIOD),
    .CW         (CW)
  ) dut (
    .clk_ref (clk_ref),
    .rst_n   (rst_n),
    .clk_mon (clk_mon),
    .fault   (fault)
  );

  // Clean reference clock (delay-first, no race at time 0)
  initial clk_ref = 1'b0;
  always #(REF_PERIOD/2) clk_ref = ~clk_ref;

  initial begin
    $monitor("t=%0t\t clk_mon=%b fault=%b", $time, clk_mon, fault);

    rst_n   = 1'b0;
    clk_mon = 1'b0;
    #(REF_PERIOD*2);
    rst_n = 1'b1;

    // Test 1: healthy clk_mon, edges every 30 ref cycles
    // (well within [MIN_PERIOD=10, MAX_PERIOD=100]) - fault should stay 0
    repeat (6) begin
      #(REF_PERIOD*30);
      clk_mon = ~clk_mon;
    end

    // Test 2: too-fast edges, every 3 ref cycles (< MIN_PERIOD=10)
    // - should trigger fault=1
    repeat (6) begin
      #(REF_PERIOD*3);
      clk_mon = ~clk_mon;
    end

    // Reset to clear the sticky fault before next test
    #(REF_PERIOD*5);
    rst_n = 1'b0;
    #(REF_PERIOD*2);
    rst_n = 1'b1;

    // Test 3: stall - hold clk_mon constant for longer than
    // MAX_PERIOD=100 ref cycles with no edge at all
    #(REF_PERIOD*150);

    // Reset once more to confirm fault clears
    rst_n = 1'b0;
    #(REF_PERIOD*2);
    rst_n = 1'b1;
    #(REF_PERIOD*5);

    $finish;
  end

endmodule