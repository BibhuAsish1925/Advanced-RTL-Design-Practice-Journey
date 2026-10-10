`timescale 1ns/1ps

module clock_gating_tb;

  localparam CLK_PERIOD = 10;

  reg  clk;
  reg  enable;
  wire gated_clk;

  clock_gating dut (
    .clk       (clk),
    .enable    (enable),
    .gated_clk (gated_clk)
  );

  // Clean clock generation (delay-first, no race at time 0)
  initial clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  initial begin
    $monitor("t=%0t\t clk=%b enable=%b gated_clk=%b", $time, clk, enable, gated_clk);

    // Start disabled
    enable = 1'b0;
    #(CLK_PERIOD*3);

    // Enable normally while clk is low - clean, expected behavior
    @(negedge clk);
    enable = 1'b1;
    #(CLK_PERIOD*3);

    // GLITCH DEMONSTRATION:
    // Toggle enable while clk is HIGH - since there's no latch here,
    // gated_clk will immediately react mid-cycle, producing an
    // unwanted short pulse/edge instead of waiting for the next
    // clean low phase (unlike clock_gating_glitch_free)
    @(posedge clk);
    #1;
    enable = 1'b0;
    #1;
    enable = 1'b1;
    #(CLK_PERIOD*3);

    // Disable cleanly while clk is low
    @(negedge clk);
    enable = 1'b0;
    #(CLK_PERIOD*3);

    $finish;
  end

endmodule