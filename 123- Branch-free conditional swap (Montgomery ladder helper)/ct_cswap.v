`timescale 1ns / 1ps

// ================================================================
// Constant-Time Conditional Swap
//
// sel = 0:
//     a_out = a_in
//     b_out = b_in
//
// sel = 1:
//     a_out = b_in
//     b_out = a_in
//
// Branch-free XOR-mask implementation.
// ================================================================

module ct_cswap #(
    parameter W = 256
)(
    input  wire         sel,
    input  wire [W-1:0] a_in,
    input  wire [W-1:0] b_in,
    output wire [W-1:0] a_out,
    output wire [W-1:0] b_out
);

    wire [W-1:0] mask;
    wire [W-1:0] swap_mask;

    // All zeros when sel=0
    // All ones  when sel=1
    assign mask = {W{sel}};

    // Generate swap difference
    assign swap_mask = (a_in ^ b_in) & mask;

    // Conditional swap
    assign a_out = a_in ^ swap_mask;
    assign b_out = b_in ^ swap_mask;

endmodule