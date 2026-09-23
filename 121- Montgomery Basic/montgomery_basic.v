`timescale 1ns / 1ps

// ================================================================
// Basic Montgomery Multiplier - Conceptual RTL
//
// Computes:
//     C = (A * B) mod N
//
// NOTE:
// This is a conceptual modular multiplier.
// It does NOT implement the complete Montgomery REDC algorithm.
// A true Montgomery multiplier would compute:
//     C = (A * B * R^-1) mod N
// where R = 2^WIDTH.
// ================================================================

module montgomery_basic #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] A,
    input  [WIDTH-1:0] B,
    input  [WIDTH-1:0] N,
    output [WIDTH-1:0] C
);

    reg [2*WIDTH-1:0] mult;
    reg [2*WIDTH-1:0] mod_temp;

    always @(*) begin
        mult = A * B;

        if (N != 0)
            mod_temp = mult % N;
        else
            mod_temp = 0;
    end

    assign C = mod_temp[WIDTH-1:0];

endmodule