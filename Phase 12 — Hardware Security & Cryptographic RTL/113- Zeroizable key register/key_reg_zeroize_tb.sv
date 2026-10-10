`timescale 1ns/1ps

module key_reg_zeroize_tb;

  parameter int W = 128;

  logic         clk;
  logic         rst_n;
  logic         load;
  logic [W-1:0] key_in;
  logic         tamper;
  logic         soft_zeroize;

  logic [W-1:0] key_out;
  logic         parity_ok;

  // ---------------------------------------------------------
  // DUT
  // ---------------------------------------------------------

  key_reg_zeroize #(
    .W(W)
  ) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .load         (load),
    .key_in       (key_in),
    .tamper       (tamper),
    .soft_zeroize (soft_zeroize),
    .key_out      (key_out),
    .parity_ok    (parity_ok)
  );

  // ---------------------------------------------------------
  // Clock: 10 ns period
  // ---------------------------------------------------------

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // ---------------------------------------------------------
  // Test sequence
  // ---------------------------------------------------------

  initial begin

    // Initial values
    rst_n        = 1'b0;
    load         = 1'b0;
    key_in       = '0;
    tamper       = 1'b0;
    soft_zeroize = 1'b0;

    // -------------------------------------------------------
    // TEST 1: Reset
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 1: RESET");
    $display("----------------------------------------");

    #12;

    if (key_out !== '0)
      $error("RESET FAILED: key_out is not zero");
    else
      $display("PASS: Key cleared by reset");

    rst_n = 1'b1;

    // -------------------------------------------------------
    // TEST 2: Load key
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 2: LOAD KEY");
    $display("----------------------------------------");

    key_in = 128'h0123_4567_89AB_CDEF_1122_3344_5566_7788;
    load   = 1'b1;

    @(posedge clk);
    #1;

    load = 1'b0;

    if (key_out !== key_in)
      $error("LOAD FAILED: key_out = %h", key_out);
    else
      $display("PASS: Key loaded = %h", key_out);

    // -------------------------------------------------------
    // TEST 3: Key retention
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 3: KEY RETENTION");
    $display("----------------------------------------");

    @(posedge clk);
    #1;

    if (key_out !== 128'h0123_4567_89AB_CDEF_1122_3344_5566_7788)
      $error("RETENTION FAILED");
    else
      $display("PASS: Key retained");

    // -------------------------------------------------------
    // TEST 4: Software zeroize
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 4: SOFTWARE ZEROIZE");
    $display("----------------------------------------");

    soft_zeroize = 1'b1;

    @(posedge clk);
    #1;

    soft_zeroize = 1'b0;

    if (key_out !== '0)
      $error("SOFT ZEROIZE FAILED: key_out = %h", key_out);
    else
      $display("PASS: Software zeroize cleared key");

    // -------------------------------------------------------
    // TEST 5: Reload key
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 5: RELOAD KEY");
    $display("----------------------------------------");

    key_in = 128'hA5A5_A5A5_5A5A_5A5A_DEAD_BEEF_CAFE_1234;
    load   = 1'b1;

    @(posedge clk);
    #1;

    load = 1'b0;

    if (key_out !== key_in)
      $error("RELOAD FAILED");
    else
      $display("PASS: New key loaded = %h", key_out);

    // -------------------------------------------------------
    // TEST 6: Asynchronous tamper zeroize
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 6: ASYNCHRONOUS TAMPER");
    $display("----------------------------------------");

    #2;

    tamper = 1'b1;

    // No clock edge is required here.
    #1;

    if (key_out !== '0)
      $error("TAMPER ZEROIZE FAILED: key_out = %h", key_out);
    else
      $display("PASS: Tamper asynchronously cleared key");

    tamper = 1'b0;

    // -------------------------------------------------------
    // TEST 7: Reload after tamper
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 7: RELOAD AFTER TAMPER");
    $display("----------------------------------------");

    key_in = 128'hFFFF_0000_FFFF_0000_AAAA_5555_1234_5678;
    load   = 1'b1;

    @(posedge clk);
    #1;

    load = 1'b0;

    if (key_out !== key_in)
      $error("RELOAD AFTER TAMPER FAILED");
    else
      $display("PASS: Key successfully reloaded");

    // -------------------------------------------------------
    // TEST 8: Final reset
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 8: FINAL RESET");
    $display("----------------------------------------");

    rst_n = 1'b0;

    #2;

    if (key_out !== '0)
      $error("FINAL RESET FAILED");
    else
      $display("PASS: Final reset cleared key");

    rst_n = 1'b1;

    // -------------------------------------------------------
    // Finish
    // -------------------------------------------------------

    $display("\n========================================");
    $display("ALL TESTS COMPLETED");
    $display("========================================");

    #10;
    $finish;

  end

endmodule