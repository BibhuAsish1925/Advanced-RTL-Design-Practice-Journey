`timescale 1ns / 1ps

////////////////////////////////////////////////////////////
// DUT : 4-BIT REGISTERED ADDER
////////////////////////////////////////////////////////////

module seq_adder (
    input        clk,
    input        rst,
    input  [3:0]  a,
    input  [3:0]  b,
    output reg [4:0] y
);

    always @(posedge clk) begin
        if (rst)
            y <= 5'b00000;
        else
            y <= a + b;
    end

endmodule


////////////////////////////////////////////////////////////
// INTERFACE
////////////////////////////////////////////////////////////

interface seq_add_if();

    logic       clk;
    logic       rst;
    logic [3:0] a;
    logic [3:0] b;
    logic [4:0] y;

endinterface