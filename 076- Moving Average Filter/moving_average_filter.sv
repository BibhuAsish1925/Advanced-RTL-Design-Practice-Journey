`timescale 1ns/1ps
module moving_average_filter #(
    parameter int DATA_WIDTH = 8,
    parameter int WINDOW_SIZE = 4,
    parameter int SUM_WIDTH = DATA_WIDTH + $clog2(WINDOW_SIZE)
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   en,
    input  logic [DATA_WIDTH-1:0]  data_in,
    output logic [DATA_WIDTH-1:0]  data_out
);
    logic [DATA_WIDTH-1:0] sample_buffer [WINDOW_SIZE];
    logic [SUM_WIDTH-1:0] sum;
    logic [DATA_WIDTH-1:0] oldest_sample;
    integer i;
    assign oldest_sample = sample_buffer[WINDOW_SIZE-1];
    always_ff @(posedge clk) begin
        if (rst) begin
            sum      <= '0;
            data_out <= '0;
            for (i = 0; i < WINDOW_SIZE; i = i + 1)
                sample_buffer[i] <= '0;
        end
        else if (en) begin
            // Update running sum
            sum <= sum + data_in - oldest_sample;
            // Shift samples
            for (i = WINDOW_SIZE-1; i > 0; i = i - 1)
                sample_buffer[i] <= sample_buffer[i-1];
            sample_buffer[0] <= data_in;
            // Average
            data_out <= (sum + data_in - oldest_sample)
                        / WINDOW_SIZE;
        end
    end
endmodule