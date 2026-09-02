module sine_wave_generator #(
    parameter int PHASE_WIDTH = 8,
    parameter int OUTPUT_WIDTH = 8
)(
    input  logic                     clk,
    input  logic                     rst,
    input  logic [PHASE_WIDTH-1:0]   phase_step,
    output logic signed [OUTPUT_WIDTH-1:0] sine_out
);
    logic [PHASE_WIDTH-1:0] phase_acc;
    logic signed [OUTPUT_WIDTH-1:0] sine_lut [0:15];
    logic [3:0] lut_address;
    integer i;
    // ------------------------------------------------
    // Sine Lookup Table
    // ------------------------------------------------
    initial begin
        sine_lut[0]  = 8'sd0;
        sine_lut[1]  = 8'sd49;
        sine_lut[2]  = 8'sd90;
        sine_lut[3]  = 8'sd117;
        sine_lut[4]  = 8'sd127;
        sine_lut[5]  = 8'sd117;
        sine_lut[6]  = 8'sd90;
        sine_lut[7]  = 8'sd49;
        sine_lut[8]  = 8'sd0;
        sine_lut[9]  = -8'sd49;
        sine_lut[10] = -8'sd90;
        sine_lut[11] = -8'sd117;
        sine_lut[12] = -8'sd127;
        sine_lut[13] = -8'sd117;
        sine_lut[14] = -8'sd90;
        sine_lut[15] = -8'sd49;
    end
    // ------------------------------------------------
    // Phase Accumulator
    // ------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            phase_acc <= '0;
        else
            phase_acc <= phase_acc + phase_step;
    end
    // ------------------------------------------------
    // LUT Address
    // ------------------------------------------------
    assign lut_address = phase_acc[PHASE_WIDTH-1 -: 4];
    // ------------------------------------------------
    // Sine Output
    // ------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            sine_out <= '0;
        else
            sine_out <= sine_lut[lut_address];
    end
endmodule