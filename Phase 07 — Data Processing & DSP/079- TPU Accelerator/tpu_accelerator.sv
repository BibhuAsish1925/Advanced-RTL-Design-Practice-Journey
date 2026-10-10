`timescale 1ns/1ps
module tpu_accelerator #(
    parameter int DATA_WIDTH = 8,
    parameter int MATRIX_SIZE = 2,
    parameter int ACC_WIDTH = 2 * DATA_WIDTH + $clog2(MATRIX_SIZE)
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input logic signed [DATA_WIDTH-1:0]
        matrix_a [MATRIX_SIZE][MATRIX_SIZE],
    input logic signed [DATA_WIDTH-1:0]
        matrix_b [MATRIX_SIZE][MATRIX_SIZE],
    output logic signed [ACC_WIDTH-1:0]
        matrix_c [MATRIX_SIZE][MATRIX_SIZE],
    output logic busy,
    output logic done
);
    integer i;
    integer j;
    integer k;
    logic signed [ACC_WIDTH-1:0] accumulator;
    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        COMPLETE
    } state_t;
    state_t state;
    integer row;
    integer col;
    integer index;
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            row   <= 0;
            col   <= 0;
            index <= 0;
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    matrix_c[i][j] <= '0;
                end
            end
        end
        else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        row   <= 0;
                        col   <= 0;
                        index <= 0;
                        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                                matrix_c[i][j] <= '0;
                            end
                        end
                        state <= COMPUTE;
                    end
                end
                COMPUTE: begin
                    busy <= 1'b1;
                    matrix_c[row][col] <=
                        matrix_c[row][col] +
                        (matrix_a[row][index] *
                         matrix_b[index][col]);
                    if (index == MATRIX_SIZE-1) begin
                        index <= 0;
                        if (col == MATRIX_SIZE-1) begin
                            col <= 0;
                            if (row == MATRIX_SIZE-1) begin
                                state <= COMPLETE;
                            end
                            else begin
                                row <= row + 1;
                            end
                        end
                        else begin
                            col <= col + 1;
                        end
                    end
                    else begin
                        index <= index + 1;
                    end
                end
                COMPLETE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule