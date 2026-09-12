`timescale 1ns/1ps
module fixed_point_dsp #(
    parameter int DATA_WIDTH     = 8,
    parameter int FRACTION_BITS  = 4,
    parameter int OUTPUT_WIDTH   = 2 * DATA_WIDTH
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         en,
    input  logic [1:0]                   opcode,
    input  logic signed [DATA_WIDTH-1:0] a,
    input  logic signed [DATA_WIDTH-1:0] b,
    output logic signed [OUTPUT_WIDTH-1:0] result
);
    localparam int MAC_WIDTH = OUTPUT_WIDTH;
    logic signed [OUTPUT_WIDTH-1:0] a_ext;
    logic signed [OUTPUT_WIDTH-1:0] b_ext;
    logic signed [OUTPUT_WIDTH-1:0] mult_result;
    logic signed [OUTPUT_WIDTH-1:0] next_result;
    always_comb begin
        // Sign extend inputs
        a_ext = {{(OUTPUT_WIDTH-DATA_WIDTH){a[DATA_WIDTH-1]}}, a};
        b_ext = {{(OUTPUT_WIDTH-DATA_WIDTH){b[DATA_WIDTH-1]}}, b};
        // Fixed-point multiplication
        mult_result = a * b;
        next_result = '0;
        case (opcode)
            // -----------------------------------------
            // ADD
            // -----------------------------------------
            2'b00: begin
                next_result = a_ext + b_ext;
            end
            // -----------------------------------------
            // SUBTRACT
            // -----------------------------------------
            2'b01: begin
                next_result = a_ext - b_ext;
            end
            // -----------------------------------------
            // MULTIPLY
            // -----------------------------------------
            2'b10: begin
                // Restore fixed-point scaling
                next_result =
                    mult_result >>> FRACTION_BITS;
            end
            // -----------------------------------------
            // MAC
            // -----------------------------------------
            2'b11: begin
                next_result =
                    result +
                    (mult_result >>> FRACTION_BITS);
            end
            default: begin
                next_result = '0;
            end
        endcase
    end
    // -------------------------------------------------
    // Output Register
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            result <= '0;
        end
        else if (en) begin
            
            result <= next_result;
        end
    end
endmodule