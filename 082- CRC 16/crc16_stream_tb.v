`timescale 1ns/1ps

module crc16_stream_tb;

  reg clk, rst_n;
  reg valid_i;
  reg [7:0] data_i;
  reg last_i;
  wire valid_o;
  wire [15:0] crc_o;

  crc16_stream dut (
    .clk(clk), .rst_n(rst_n),
    .valid_i(valid_i), .data_i(data_i), .last_i(last_i),
    .valid_o(valid_o), .crc_o(crc_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Standard CRC-16/MODBUS check message: ASCII "123456789"
  // Universally known correct result: 0x4B37
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

    if (crc_o !== 16'h4B37)
      $display("FAIL: CRC16/MODBUS(\"123456789\") = %h, expected 4B37", crc_o);
    else
      $display("PASS: CRC16/MODBUS(\"123456789\") = %h matches golden reference", crc_o);

    #20;
    $finish;
  end

endmodule