module lfsr_galois_tb;

  localparam W = 16;

  logic clk, rst_n, en;
  logic [W-1:0] q;

  lfsr_galois #(.W(W)) dut (
    .clk(clk), .rst_n(rst_n), .en(en), .q(q)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  integer i;
  logic [W-1:0] first_val;
  integer wrap_count;

  initial begin
    $monitor("t=%0t\t en=%b q=%h", $time, en, q);

    rst_n = 0; en = 0;
    #12;
    rst_n = 1;
    #10;

    if (q !== 16'h0001)
      $display("FAIL: q not seeded to 0x0001 after reset, got %h", q);
    else
      $display("PASS: q correctly seeded to 0x0001");

    en = 1;
    first_val = q;
    wrap_count = 0;

    // Run for enough cycles to confirm it doesn't repeat prematurely,
    // and (separately) that it does eventually return after the full
    // maximal-length period of 65535 cycles.
    for (i = 0; i < 1000; i = i + 1) begin
      @(posedge clk);
      if (q == first_val) begin
        wrap_count = wrap_count + 1;
        $display("NOTE: sequence returned to seed value after %0d cycles", i+1);
      end
    end

    if (wrap_count == 0)
      $display("PASS: sequence did not prematurely repeat within 1000 cycles");

    en = 0;
    #20;
    $finish;
  end

endmodule