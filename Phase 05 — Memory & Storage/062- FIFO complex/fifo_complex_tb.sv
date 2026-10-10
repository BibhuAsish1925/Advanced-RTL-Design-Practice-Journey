`timescale 1ns/1ps

module fifo_complex_tb;

  localparam DATA_WIDTH = 8;
  localparam DEPTH      = 8;

  logic clk, rst_n;
  logic wr_en, rd_en;
  logic [DATA_WIDTH-1:0] data_in, data_out;
  logic full, empty, almost_full, almost_empty;

  fifo_complex #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .rd_en(rd_en),
    .data_in(data_in), .data_out(data_out),
    .full(full), .empty(empty),
    .almost_full(almost_full), .almost_empty(almost_empty)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  integer i;

  initial begin
    $monitor("t=%0t\t wr=%b rd=%b din=%h dout=%h count=%0d full=%b afull=%b empty=%b aempty=%b",
              $time, wr_en, rd_en, data_in, data_out, dut.count, full, almost_full, empty, almost_empty);

    rst_n = 0; wr_en = 0; rd_en = 0; data_in = 0;
    #12; rst_n = 1;

    // Fill the FIFO completely, watch almost_full and full assert correctly
    wr_en = 1;
    for (i = 0; i < DEPTH; i = i + 1) begin
      data_in = i;
      @(posedge clk);
    end
    wr_en = 0;
    @(posedge clk);

    // Simultaneous read+write test: count must stay stable (not drift down)
    wr_en = 1; rd_en = 1; data_in = 8'hAA;
    repeat (4) @(posedge clk);
    wr_en = 0; rd_en = 0;
    @(posedge clk);

    // Drain the rest, watch almost_empty and empty assert correctly
    rd_en = 1;
    repeat (DEPTH) @(posedge clk);
    rd_en = 0;

    #20;
    $finish;
  end

endmodule