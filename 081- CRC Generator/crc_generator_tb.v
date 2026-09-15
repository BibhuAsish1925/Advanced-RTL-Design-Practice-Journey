`timescale 1ns/1ps

module crc_generator_tb;

  // Instantiate the generic engine as CRC-32/ISO-HDLC (same standard
  // used for Ethernet/ZIP/PNG) to cross-check it against the same
  // golden reference used for crc32_stream earlier.
  reg clk, rst_n;
  reg valid_i;
  reg [7:0] data_i;
  reg last_i;
  wire valid_o;
  wire [31:0] crc_o;

  crc_generator #(
    .WIDTH(32),
    .POLY(32'hEDB88320),
    .INIT_VAL(32'hFFFFFFFF),
    .XOR_OUT(32'hFFFFFFFF)
  ) dut_crc32 (
    .clk(clk), .rst_n(rst_n),
    .valid_i(valid_i), .data_i(data_i), .last_i(last_i),
    .valid_o(valid_o), .crc_o(crc_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  reg [7:0] message [0:8];
  integer i;

  initial begin
    $monitor("t=%0t\t valid_i=%b data_i=%h last_i=%b | valid_o=%b crc_o=%h",
              $time, valid_i, data_i, last_i, valid_o, crc_o);

    message[0]="1"; message[1]="2"; message[2]="3";
    message[3]="4"; message[4]="5"; message[5]="6";
    message[6]="7"; message[7]="8"; message[8]="9";

    rst_n = 0; valid_i = 0; last_i = 0; data_i = 0;
    #12; rst_n = 1;

    for (i = 0; i <= 8; i = i + 1) begin
      @(negedge clk);
      data_i  = message[i];
      valid_i = 1'b1;
      last_i  = (i == 8);
      @(posedge clk);
    end
    @(negedge clk);
    valid_i = 0;
    last_i  = 0;

    wait (valid_o == 1'b1);
    #1;

    if (crc_o !== 32'hCBF43926)
      $display("FAIL: generic-CRC-32(\"123456789\") = %h, expected CBF43926", crc_o);
    else
      $display("PASS: generic-CRC-32(\"123456789\") = %h matches golden reference", crc_o);

    #20;
    $finish;
  end

endmodule