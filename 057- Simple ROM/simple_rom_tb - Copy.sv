module simple_rom_tb;

  logic        clk;
  logic        rst_n;
  logic        rd_en;
  logic [7:0]  rd_addr;
  logic [31:0] data_out;

  integer i;

  simple_rom dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .rd_en   (rd_en),
    .rd_addr (rd_addr),
    .data_out(data_out)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    $monitor("t=%0t\t rst_n=%b rd_en=%b rd_addr=%0d data_out=%h",
              $time, rst_n, rd_en, rd_addr, data_out);

    // Reset
    rst_n = 1'b0;
    rd_en = 1'b0;
    rd_addr = 8'h00;
    #12;

    // Confirm data_out is cleanly 0 right after reset
    if (data_out !== 32'h0)
      $display("FAIL: data_out not reset, got %h", data_out);
    else
      $display("PASS: data_out correctly reset to 0");

    rst_n = 1'b1;

    // Read back a handful of addresses and verify against the known
    // initialization pattern (0x1000_0000 + addr)
    rd_en = 1'b1;
    for (i = 0; i < 8; i = i + 1) begin
      rd_addr = i[7:0];
      @(posedge clk);
      #1;
      if (data_out !== (32'h1000_0000 + i))
        $display("FAIL: addr=%0d expected=%h got=%h", i, 32'h1000_0000+i, data_out);
      else
        $display("PASS: addr=%0d data_out=%h", i, data_out);
    end

    // Also check the top address
    rd_addr = 8'd255;
    @(posedge clk);
    #1;
    if (data_out !== (32'h1000_0000 + 255))
      $display("FAIL: addr=255 expected=%h got=%h", 32'h1000_0000+255, data_out);
    else
      $display("PASS: addr=255 data_out=%h", data_out);

    rd_en = 1'b0;
    #20;
    $finish;
  end

endmodule