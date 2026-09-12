`timescale 1ns/1ps
module fir_filter #(
    parameter int DATA_WIDTH   = 8,
    parameter int COEFF_WIDTH  = 8,
    parameter int TAPS         = 4,
    parameter int OUTPUT_WIDTH =
        DATA_WIDTH + COEFF_WIDTH + $clog2(TAPS)
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         en,
    input  logic signed [DATA_WIDTH-1:0] data_in,
    input  logic signed [COEFF_WIDTH-1:0] coeff [TAPS],
    output logic signed [OUTPUT_WIDTH-1:0] data_out
);
    logic signed [DATA_WIDTH-1:0] delay_line [TAPS-1];
    logic signed [DATA_WIDTH+COEFF_WIDTH-1:0] products [TAPS];
    logic signed [OUTPUT_WIDTH-1:0] sum;
    integer i;
    // --------------------------------------------------
    // FIR Multiply-Accumulate
    // coeff[0] pairs with the CURRENT sample (data_in);
    // coeff[k] for k>=1 pairs with delay_line[k-1] (the
    // sample from k cycles ago).
    // --------------------------------------------------
    always_comb begin
        products[0] = data_in * coeff[0];
        sum = products[0];
        for (i = 1; i < TAPS; i = i + 1) begin
            products[i] = delay_line[i-1] * coeff[i];
            sum = sum + products[i];
        end
    end
    // --------------------------------------------------
    // Input Delay Line
    // --------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS-1; i = i + 1)
                delay_line[i] <= '0;
            data_out <= '0;
        end
        else if (en) begin
            // Shift previous samples
            for (i = TAPS-2; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            // Newest sample
            delay_line[0] <= data_in;
            // Register filtered result
            data_out <= sum;
        end
    end
endmodule