module pipelined_mac #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,
    input  logic [DATA_WIDTH-1:0] a,
    input  logic [DATA_WIDTH-1:0] b,
    output logic [ACC_WIDTH-1:0] acc
);
    logic [2*DATA_WIDTH-1:0] product_reg;
    // Stage 1: Multiplication
    always_ff @(posedge clk) begin
        if (rst)
            product_reg <= '0;
        else if (en)
            product_reg <= a * b;
    end
    // Stage 2: Accumulation
    always_ff @(posedge clk) begin
        if (rst)
            acc <= '0;
        else if (en)
            acc <= acc + product_reg;
    end
endmodule