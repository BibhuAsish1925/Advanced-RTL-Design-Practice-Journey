module clock_gating_glitch_free_tb;

  localparam CLK_PERIOD = 10;

  reg  clk;
  reg  enable;
  wire gated_clk;

  clock_gating_glitch_free dut (
    .clk       (clk),
    .enable    (enable),
    .gated_clk (gated_clk)
  );

  // Clean clock generation (delay-first, no race at time 0)
  initial clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  initial begin
    $monitor("t=%0t\t clk=%b enable=%b gated_clk=%b", $time, clk, enable, gated_clk);

    // Start disabled - gated_clk should stay low throughout
    enable = 1'b0;
    #(CLK_PERIOD*3);

    // Enable while clk is LOW - should be captured cleanly,
    // gated_clk should start following clk from the next high phase
    @(negedge clk);
    enable = 1'b1;
    #(CLK_PERIOD*3);

    // Try to change enable while clk is HIGH - this should NOT
    // affect gated_clk mid-cycle (glitch-free check); the latch
    // should hold until clk goes low again
    @(posedge clk);
    #1;
    enable = 1'b0;
    #(CLK_PERIOD*3);

    // Re-enable, again while clk is low, and hold to confirm
    // clean resumption of gating
    @(negedge clk);
    enable = 1'b1;
    #(CLK_PERIOD*4);

    $finish;
  end

endmodule