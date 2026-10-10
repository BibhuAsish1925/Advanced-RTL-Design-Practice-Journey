module digital_convolution #(
    parameter int DATA_WIDTH = 8,
    parameter int COEFF_WIDTH = 8,
    parameter int TAPS = 4,
    parameter int OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + $clog2(TAPS)
)(
    input  logic signed [DATA_WIDTH-1:0]  data_in [TAPS],
    input  logic signed [COEFF_WIDTH-1:0] coeff [TAPS],
    output logic signed [OUTPUT_WIDTH-1:0] result
);
    integer i;
    logic signed [DATA_WIDTH+COEFF_WIDTH-1:0] products [TAPS];
    logic signed [OUTPUT_WIDTH-1:0] sum;
    always_comb begin
        sum = '0;
        for (i = 0; i < TAPS; i = i + 1) begin
            products[i] = data_in[i] * coeff[i];
            sum = sum + products[i];
        end
        result = sum;
    end
endmodule