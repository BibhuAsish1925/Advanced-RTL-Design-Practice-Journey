`timescale 1ns/1ps

module Dual_port_RAM_DualCLK_tb;

  logic        clk_wr;
  logic        clk_rd;
  logic        rst_n;
  logic        wr_en;
  logic [7:0]  wr_addr;
  logic [31:0] data_in;
  logic        rd_en;
  logic [7:0]  rd_addr;
  logic [31:0] data_out;

  integer i;

  Dual_port_RAM_DualCLK dut (
    .clk_wr  (clk_wr),
    .clk_rd  (clk_rd),
    .rst_n   (rst_n),
    .wr_en   (wr_en),
    .wr_addr (wr_addr),
    .data_in (data_in),
    .rd_en   (rd_en),
    .rd_addr (rd_addr),
    .data_out(data_out)
  );

  // Two independent, differently-timed clocks (genuinely asynchronous)
  initial clk_wr = 1'b0;
  always #5 clk_wr = ~clk_wr;   // 10ns period

  initial clk_rd = 1'b0;
  always #3.5 clk_rd = ~clk_rd; // 7ns period

  initial begin
    $monitor("t=%0t\t wr_en=%b wr_addr=%0d data_in=%h | rd_en=%b rd_addr=%0d data_out=%h",
              $time, wr_en, wr_addr, data_in, rd_en, rd_addr, data_out);

    // Reset
    rst_n   = 1'b0;
    wr_en   = 1'b0;
    rd_en   = 1'b0;
    wr_addr = 8'h00;
    rd_addr = 8'h00;
    data_in = 32'h0;
    #20;
    rst_n = 1'b1;
    #10;

    // Write phase: write known values into a handful of addresses
    wr_en = 1'b1;
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge clk_wr);
      wr_addr = i[7:0];
      data_in = 32'hA000_0000 + i;
    end
    @(posedge clk_wr);
    wr_en = 1'b0;

    // Let the write side settle across clock domains before reading
    #50;

    // Read phase: read back the same addresses from the read clock domain
    rd_en = 1'b1;
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge clk_rd);
      rd_addr = i[7:0];
    end
    @(posedge clk_rd);
    rd_en = 1'b0;

    #20;
    $finish;
  end

endmodule