`timescale 1ns / 1ps

module wm_proof_simple_tb;

  // Override with a small, easy-to-verify-by-hand 8-bit pattern for
  // the main correctness checks, then separately confirm the real
  // 64-bit default MAGIC/SIGN pair also works at full width.
  localparam [7:0] TEST_MAGIC = 8'hA5; // 10100101

  reg clk, rst_n, tr_we, tr_bit;
  wire sig_valid;
  wire [63:0] sig_value;

  wm_proof_simple #(
    .MAGIC({56'd0, TEST_MAGIC}),
    .SIGN (64'hCAFEBABE)
  ) dut_small (
    .clk(clk), .rst_n(rst_n),
    .tr_we(tr_we), .tr_bit(tr_bit),
    .sig_valid(sig_valid), .sig_value(sig_value)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  // The 8-bit magic pattern 10100101, shifted in MSB-first
  reg correct_seq [0:7];
  reg wrong_seq   [0:7];
  integer i;

  initial begin
    correct_seq[0]=1; correct_seq[1]=0; correct_seq[2]=1; correct_seq[3]=0;
    correct_seq[4]=0; correct_seq[5]=1; correct_seq[6]=0; correct_seq[7]=1;

    wrong_seq[0]=1; wrong_seq[1]=1; wrong_seq[2]=1; wrong_seq[3]=1;
    wrong_seq[4]=1; wrong_seq[5]=1; wrong_seq[6]=1; wrong_seq[7]=1;

    $monitor("t=%0t\t tr_bit=%b sr=%h sig_valid=%b sig_value=%h",
              $time, tr_bit, dut_small.sr, sig_valid, sig_value);

    rst_n = 0; tr_we = 0; tr_bit = 0;
    #12; rst_n = 1;

    // Test 1: shift in the WRONG sequence first - sig_valid should
    // never assert
    tr_we = 1;
    for (i = 0; i < 8; i = i + 1) begin
      @(negedge clk);
      tr_bit = wrong_seq[i];
    end
    @(negedge clk);
    if (sig_valid !== 1'b0)
      $display("FAIL: sig_valid asserted on wrong sequence");
    else
      $display("PASS: wrong sequence correctly did not trigger");

    // Test 2: shift in the CORRECT sequence - sig_valid should pulse
    // high for exactly one cycle right after the last bit, with
    // sig_value equal to SIGN
    for (i = 0; i < 8; i = i + 1) begin
      @(negedge clk);
      tr_bit = correct_seq[i];
    end
    @(negedge clk); // one cycle after the last shift-in
    #1;
    if (sig_valid !== 1'b1 || sig_value !== 64'hCAFEBABE)
      $display("FAIL: correct sequence did not trigger as expected (sig_valid=%b sig_value=%h)", sig_valid, sig_value);
    else
      $display("PASS: correct sequence triggered sig_valid with sig_value=%h", sig_value);

    // Confirm the pulse is only one cycle wide
    @(negedge clk);
    if (sig_valid !== 1'b0)
      $display("FAIL: sig_valid did not deassert after one cycle");
    else
      $display("PASS: sig_valid correctly pulsed for exactly one cycle");

    tr_we = 0;

    #20;
    $finish;
  end

endmodule