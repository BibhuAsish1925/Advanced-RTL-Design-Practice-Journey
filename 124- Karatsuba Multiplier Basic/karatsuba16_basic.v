`timescale 1ns / 1ps

// ================================================================
// 16x16 -> 32-bit Karatsuba Multiplier
//
// a = a1*2^8 + a0
// b = b1*2^8 + b0
//
// z0 = a0*b0
// z2 = a1*b1
// z1 = (a0+a1)*(b0+b1) - z0 - z2
//
// P = (z2 << 16) + (z1 << 8) + z0
//
// Unsigned, combinational implementation.
// ================================================================

module karatsuba16_basic (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] p
);

    // ------------------------------------------------------------
    // Split operands
    // ------------------------------------------------------------

    wire [7:0] a0;
    wire [7:0] a1;
    wire [7:0] b0;
    wire [7:0] b1;

    assign a0 = a[7:0];
    assign a1 = a[15:8];

    assign b0 = b[7:0];
    assign b1 = b[15:8];

    // ------------------------------------------------------------
    // Three 8x8 multiplications
    // ------------------------------------------------------------

    wire [15:0] z0;
    wire [15:0] z2;

    assign z0 = a0 * b0;
    assign z2 = a1 * b1;

    // ------------------------------------------------------------
    // Middle product
    // ------------------------------------------------------------

    wire [8:0] sa;
    wire [8:0] sb;

    wire [17:0] middle;

    assign sa = {1'b0, a0} + {1'b0, a1};
    assign sb = {1'b0, b0} + {1'b0, b1};

    assign middle = sa * sb;

    // ------------------------------------------------------------
    // z1 = middle - z0 - z2
    // ------------------------------------------------------------

    wire [17:0] z0_ext;
    wire [17:0] z2_ext;
    wire [17:0] z1;

    assign z0_ext = {2'b00, z0};
    assign z2_ext = {2'b00, z2};

    assign z1 = middle - z0_ext - z2_ext;

    // ------------------------------------------------------------
    // Result assembly
    // ------------------------------------------------------------

    wire [31:0] part_z2;
    wire [31:0] part_z1;
    wire [31:0] part_z0;

    assign part_z2 = {z2, 16'h0000};
    assign part_z1 = {6'b000000, z1, 8'h00};
    assign part_z0 = {16'h0000, z0};

    assign p = part_z2 + part_z1 + part_z0;

endmodule