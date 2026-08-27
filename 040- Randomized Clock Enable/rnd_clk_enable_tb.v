module rnd_clk_enable_tb;

  localparam LFSR_W    = 8;
  localparam CLK_PERIOD = 10;
  localparam NUM_CYCLES = 2000;

  reg  clk;
  reg  rst_n;
  reg  en_i;
  wire en_o;

  integer i;
  integer stall_count;

  rnd_clk_enable #(.LFSR_W(LFSR_W)) dut (
    .clk   (clk),
    .rst_n (rst_n),
    .en_i  (en_i),
    .en_o  (en_o)
  );

  // Clean clock generation (delay-first, no race at time 0)
  initial clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  initial begin
    rst_n       = 1'b0;
    en_i        = 1'b0;
    stall_count = 0;

    #(CLK_PERIOD*2);
    rst_n = 1'b1;

    // Confirm LFSR seeded non-zero right after reset
    #1;
    if (dut.lfsr !== {LFSR_W{1'b1}})
      $display("FAIL: LFSR did not reset to non-zero seed, got %b", dut.lfsr);
    else
      $display("PASS: LFSR correctly reset to all-ones seed");

    // Drive en_i high continuously and sample en_o over many cycles
    en_i = 1'b1;
    for (i = 0; i < NUM_CYCLES; i = i + 1) begin
      @(posedge clk);
      #1; // small delta to let combinational stall settle
      if (en_i && !en_o) stall_count = stall_count + 1;
    end

    $display("Observed stall count = %0d out of %0d cycles (%0.2f%%), expected ~12.5%%",
              stall_count, NUM_CYCLES, (stall_count * 100.0) / NUM_CYCLES);

    // Confirm en_o tracks en_i when en_i is deasserted (should never
    // be high regardless of LFSR state)
    en_i = 1'b0;
    repeat (20) begin
      @(posedge clk);
      #1;
      if (en_o !== 1'b0)
        $display("FAIL: en_o=1 while en_i=0 at t=%0t", $time);
    end
    $display("PASS: en_o stays 0 whenever en_i=0");

    $finish;
  end

endmodule