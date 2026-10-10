`timescale 1ns / 1ps

// ================================================================
// Basic Montgomery Ladder - Conceptual RTL
//
// Computes:
//
//     Y = X^E mod N
//
// The ladder processes the exponent from MSB to LSB.
// Each bit performs:
//     - one multiplication
//     - one squaring
//
// This maintains a constant operation pattern.
// ================================================================

module montgomery_ladder_basic #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] X,
    input  [WIDTH-1:0] E,
    input  [WIDTH-1:0] N,
    output [WIDTH-1:0] Y
);

    integer i;

    reg [WIDTH-1:0] R0;
    reg [WIDTH-1:0] R1;
    reg [WIDTH-1:0] base;
    reg [WIDTH-1:0] exp;

    reg [2*WIDTH-1:0] mult_temp;

    always @(*) begin

        base = X;
        exp  = E;

        R0 = {{(WIDTH-1){1'b0}}, 1'b1};
        R1 = base;

        if (N == 0) begin
            R0 = 0;
            R1 = 0;
        end
        else begin

            // Process exponent from MSB to LSB
            for (i = WIDTH-1; i >= 0; i = i - 1) begin

                if (exp[i] == 1'b0) begin

                    // R1 = R0 * R1 mod N
                    mult_temp = R0 * R1;
                    R1 = mult_temp % N;

                    // R0 = R0 * R0 mod N
                    mult_temp = R0 * R0;
                    R0 = mult_temp % N;

                end
                else begin

                    // R0 = R0 * R1 mod N
                    mult_temp = R0 * R1;
                    R0 = mult_temp % N;

                    // R1 = R1 * R1 mod N
                    mult_temp = R1 * R1;
                    R1 = mult_temp % N;

                end
            end
        end
    end

    assign Y = R0;

endmodule