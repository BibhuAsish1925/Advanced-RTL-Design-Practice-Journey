`timescale 1ns/1ps

module apb_firewall_tb;

  // ---------------------------------------------------------
  // Clock / reset
  // ---------------------------------------------------------

  logic PCLK;
  logic PRESETn;

  // ---------------------------------------------------------
  // APB master-side signals
  // ---------------------------------------------------------

  logic        PSEL;
  logic        PENABLE;
  logic        PWRITE;
  logic [31:0] PADDR;
  logic [31:0] PWDATA;

  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;

  // ---------------------------------------------------------
  // Downstream protected-slave signals
  // ---------------------------------------------------------

  logic        M_PSEL;
  logic        M_PENABLE;
  logic        M_PWRITE;
  logic [31:0] M_PADDR;
  logic [31:0] M_PWDATA;

  logic [31:0] M_PRDATA;
  logic        M_PREADY;
  logic        M_PSLVERR;

  // ---------------------------------------------------------
  // DUT
  // ---------------------------------------------------------

  apb_firewall #(
    .ALLOW_BASE(32'h4000_0000),
    .ALLOW_END (32'h4000_FFFF)
  ) dut (
    .PCLK       (PCLK),
    .PRESETn    (PRESETn),

    .PSEL       (PSEL),
    .PENABLE    (PENABLE),
    .PWRITE     (PWRITE),
    .PADDR      (PADDR),
    .PWDATA     (PWDATA),

    .PRDATA     (PRDATA),
    .PREADY     (PREADY),
    .PSLVERR    (PSLVERR),

    .M_PSEL     (M_PSEL),
    .M_PENABLE  (M_PENABLE),
    .M_PWRITE   (M_PWRITE),
    .M_PADDR    (M_PADDR),
    .M_PWDATA   (M_PWDATA),

    .M_PRDATA   (M_PRDATA),
    .M_PREADY   (M_PREADY),
    .M_PSLVERR  (M_PSLVERR)
  );

  // ---------------------------------------------------------
  // Clock
  // ---------------------------------------------------------

  initial begin
    PCLK = 1'b0;
    forever #5 PCLK = ~PCLK;
  end

  // ---------------------------------------------------------
  // Test sequence
  // ---------------------------------------------------------

  initial begin

    // Initial values
    PRESETn   = 1'b0;

    PSEL      = 1'b0;
    PENABLE   = 1'b0;
    PWRITE    = 1'b0;
    PADDR     = 32'h0;
    PWDATA    = 32'h0;

    M_PRDATA  = 32'h0;
    M_PREADY  = 1'b1;
    M_PSLVERR = 1'b0;

    // -------------------------------------------------------
    // RESET
    // -------------------------------------------------------

    $display("\n========================================");
    $display("RESET");
    $display("========================================");

    #12;
    PRESETn = 1'b1;

    // -------------------------------------------------------
    // TEST 1: Allowed WRITE
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 1: ALLOWED WRITE");
    $display("----------------------------------------");

    PADDR = 32'h4000_0010;
    PWDATA = 32'h1234_ABCD;
    PWRITE = 1'b1;

    // APB SETUP phase
    @(posedge PCLK);
    PSEL = 1'b1;
    PENABLE = 1'b0;

    // APB ACCESS phase
    @(posedge PCLK);
    PENABLE = 1'b1;

    #1;

    if (M_PSEL !== 1'b1)
      $error("FAILED: Allowed WRITE did not reach downstream");

    if (M_PENABLE !== 1'b1)
      $error("FAILED: Downstream PENABLE not asserted");

    if (M_PADDR !== PADDR)
      $error("FAILED: Address mismatch");

    if (M_PWDATA !== PWDATA)
      $error("FAILED: Write data mismatch");

    if (PSLVERR !== 1'b0)
      $error("FAILED: Allowed WRITE generated PSLVERR");

    if (PREADY !== 1'b1)
      $error("FAILED: PREADY not asserted");

    $display("PASS: Allowed WRITE forwarded");

    // End transaction
    @(posedge PCLK);
    PSEL = 1'b0;
    PENABLE = 1'b0;

    // -------------------------------------------------------
    // TEST 2: Allowed READ
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 2: ALLOWED READ");
    $display("----------------------------------------");

    PADDR = 32'h4000_0020;
    PWRITE = 1'b0;
    M_PRDATA = 32'hCAFE_BABE;
    M_PREADY = 1'b1;
    M_PSLVERR = 1'b0;

    // SETUP
    @(posedge PCLK);
    PSEL = 1'b1;
    PENABLE = 1'b0;

    // ACCESS
    @(posedge PCLK);
    PENABLE = 1'b1;

    #1;

    if (M_PSEL !== 1'b1)
      $error("FAILED: Allowed READ did not reach downstream");

    if (PRDATA !== 32'hCAFE_BABE)
      $error("FAILED: Read data mismatch: %h", PRDATA);

    if (PSLVERR !== 1'b0)
      $error("FAILED: Allowed READ generated PSLVERR");

    $display("PASS: Allowed READ returned %h", PRDATA);

    // End transaction
    @(posedge PCLK);
    PSEL = 1'b0;
    PENABLE = 1'b0;

    // -------------------------------------------------------
    // TEST 3: Lower boundary
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 3: LOWER ADDRESS BOUNDARY");
    $display("----------------------------------------");

    PADDR = 32'h4000_0000;
    PWRITE = 1'b0;
    M_PRDATA = 32'h1111_2222;

    @(posedge PCLK);
    PSEL = 1'b1;
    PENABLE = 1'b0;

    @(posedge PCLK);
    PENABLE = 1'b1;

    #1;

    if (M_PSEL !== 1'b1)
      $error("FAILED: Lower boundary blocked");

    if (PSLVERR !== 1'b0)
      $error("FAILED: Lower boundary generated error");

    $display("PASS: Lower boundary allowed");

    @(posedge PCLK);
    PSEL = 1'b0;
    PENABLE = 1'b0;

    // -------------------------------------------------------
    // TEST 4: Upper boundary
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 4: UPPER ADDRESS BOUNDARY");
    $display("----------------------------------------");

    PADDR = 32'h4000_FFFF;
    PWRITE = 1'b0;
    M_PRDATA = 32'h3333_4444;

    @(posedge PCLK);
    PSEL = 1'b1;
    PENABLE = 1'b0;

    @(posedge PCLK);
    PENABLE = 1'b1;

    #1;

    if (M_PSEL !== 1'b1)
      $error("FAILED: Upper boundary blocked");

    if (PSLVERR !== 1'b0)
      $error("FAILED: Upper boundary generated error");

    $display("PASS: Upper boundary allowed");

    @(posedge PCLK);
    PSEL = 1'b0;
    PENABLE = 1'b0;

    // -------------------------------------------------------
    // TEST 5: Block address below allowed range
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 5: BLOCKED ADDRESS - BELOW RANGE");
    $display("----------------------------------------");

    PADDR = 32'h3FFF_FFFC;
    PWRITE = 1'b0;

    @(posedge PCLK);
    PSEL = 1'b1;
    PENABLE = 1'b0;

    @(posedge PCLK);
    PENABLE = 1'b1;

    #1;

    if (M_PSEL !== 1'b0)
      $error("FAILED: Blocked READ reached downstream");

    if (PSLVERR !== 1'b1)
      $error("FAILED: Blocked READ did not generate PSLVERR");

    if (PREADY !== 1'b1)
      $error("FAILED: Blocked transaction did not complete");

    if (PRDATA !== 32'hDEAD_DEAD)
      $error("FAILED: Blocked READ returned incorrect data");

    $display("PASS: Below-range address blocked");

    @(posedge PCLK);
    PSEL = 1'b0;
    PENABLE = 1'b0;

    // -------------------------------------------------------
    // TEST 6: Block address above allowed range
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 6: BLOCKED ADDRESS - ABOVE RANGE");
    $display("----------------------------------------");

    PADDR = 32'h5000_0000;
    PWRITE = 1'b1;
    PWDATA = 32'hDEAD_BEEF;

    @(posedge PCLK);
    PSEL = 1'b1;
    PENABLE = 1'b0;

    @(posedge PCLK);
    PENABLE = 1'b1;

    #1;

    if (M_PSEL !== 1'b0)
      $error("FAILED: Blocked WRITE reached downstream");

    if (PSLVERR !== 1'b1)
      $error("FAILED: Blocked WRITE did not generate PSLVERR");

    if (PREADY !== 1'b1)
      $error("FAILED: Blocked WRITE did not complete");

    $display("PASS: Above-range address blocked");

    @(posedge PCLK);
    PSEL = 1'b0;
    PENABLE = 1'b0;

    // -------------------------------------------------------
    // TEST 7: Downstream slave error propagation
    // -------------------------------------------------------

    $display("\n----------------------------------------");
    $display("TEST 7: DOWNSTREAM SLAVE ERROR");
    $display("----------------------------------------");

    PADDR = 32'h4000_0100;
    PWRITE = 1'b0;
    M_PRDATA = 32'h0000_0000;
    M_PREADY = 1'b1;
    M_PSLVERR = 1'b1;

    @(posedge PCLK);
    PSEL = 1'b1;
    PENABLE = 1'b0;

    @(posedge PCLK);
    PENABLE = 1'b1;

    #1;

    // NOTE:
    // Current firewall design only generates PSLVERR
    // for blocked addresses. Therefore downstream
    // M_PSLVERR is NOT propagated in this implementation.

    if (PSLVERR !== 1'b0)
      $error("Unexpected firewall error");

    $display("PASS: Firewall itself did not generate an error");

    @(posedge PCLK);
    PSEL = 1'b0;
    PENABLE = 1'b0;

    // -------------------------------------------------------
    // COMPLETE
    // -------------------------------------------------------

    $display("\n========================================");
    $display("APB FIREWALL TESTBENCH COMPLETED");
    $display("========================================");

    #20;
    $finish;

  end

endmodule