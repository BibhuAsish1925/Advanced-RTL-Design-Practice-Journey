`timescale 1ns / 1ps

// ================================================================
// Recursive Karatsuba Multiplier
//
// WIDTH : operand width
// BASE  : leaf multiplier width
//
// For WIDTH <= BASE:
//     Uses built-in multiplication.
//
// Otherwise:
//
//     a = a1*2^LOW + a0
//     b = b1*2^LOW + b0
//
//     z0 = a0*b0
//     z2 = a1*b1
//     z1 = (a0+a1)*(b0+b1) - z0 - z2
//
//     P = (z2 << 2*LOW) + (z1 << LOW) + z0
//
// Supports unsigned operands.
// ================================================================

module karatsuba_mul #(
    parameter integer WIDTH = 32,
    parameter integer BASE  = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [(2*WIDTH)-1:0] p
);

    // Lower half and upper half widths
    localparam integer LOW  = WIDTH / 2;
    localparam integer HIGH = WIDTH - LOW;

    generate

        // --------------------------------------------------------
        // Leaf multiplier
        // --------------------------------------------------------

        if (WIDTH <= BASE) begin : G_LEAF

            assign p = a * b;

        end

        // --------------------------------------------------------
        // Recursive Karatsuba stage
        // --------------------------------------------------------

        else begin : G_RECURSIVE

            // ----------------------------------------------------
            // Operand split
            // ----------------------------------------------------

            wire [LOW-1:0]  a0;
            wire [HIGH-1:0] a1;

            wire [LOW-1:0]  b0;
            wire [HIGH-1:0] b1;

            assign a0 = a[LOW-1:0];
            assign a1 = a[WIDTH-1:LOW];

            assign b0 = b[LOW-1:0];
            assign b1 = b[WIDTH-1:LOW];

            // ----------------------------------------------------
            // z0 = a0 * b0
            // ----------------------------------------------------

            wire [(2*LOW)-1:0] z0;

            karatsuba_mul #(
                .WIDTH(LOW),
                .BASE(BASE)
            ) U_Z0 (
                .a(a0),
                .b(b0),
                .p(z0)
            );

            // ----------------------------------------------------
            // z2 = a1 * b1
            // ----------------------------------------------------

            wire [(2*HIGH)-1:0] z2;

            karatsuba_mul #(
                .WIDTH(HIGH),
                .BASE(BASE)
            ) U_Z2 (
                .a(a1),
                .b(b1),
                .p(z2)
            );

            // ----------------------------------------------------
            // sa = a0 + a1
            // sb = b0 + b1
            //
            // HIGH >= LOW
            // ----------------------------------------------------

            wire [HIGH:0] sa;
            wire [HIGH:0] sb;

            assign sa =
                {{(HIGH+1-LOW){1'b0}}, a0} +
                {1'b0, a1};

            assign sb =
                {{(HIGH+1-LOW){1'b0}}, b0} +
                {1'b0, b1};

            // ----------------------------------------------------
            // Middle product
            // ----------------------------------------------------

            localparam integer SUM_WIDTH = HIGH + 1;
            localparam integer M_WIDTH   = 2 * SUM_WIDTH;

            wire [M_WIDTH-1:0] middle;

            karatsuba_mul #(
                .WIDTH(SUM_WIDTH),
                .BASE(BASE)
            ) U_MIDDLE (
                .a(sa),
                .b(sb),
                .p(middle)
            );

            // ----------------------------------------------------
            // z1 = middle - z0 - z2
            // ----------------------------------------------------

            wire [M_WIDTH-1:0] z0_ext;
            wire [M_WIDTH-1:0] z2_ext;
            wire [M_WIDTH-1:0] z1;

            assign z0_ext = {{(M_WIDTH-2*LOW){1'b0}}, z0};
            assign z2_ext = {{(M_WIDTH-2*HIGH){1'b0}}, z2};

            assign z1 = middle - z0_ext - z2_ext;

            // ----------------------------------------------------
            // Result assembly
            //
            // P = (z2 << 2*LOW)
            //   + (z1 << LOW)
            //   + z0
            // ----------------------------------------------------

            wire [(2*WIDTH)-1:0] part_z2;
            wire [(2*WIDTH)-1:0] part_z1;
            wire [(2*WIDTH)-1:0] part_z0;

            assign part_z2 =
                {z2, {2*LOW{1'b0}}};

            assign part_z1 =
                {{(2*WIDTH-M_WIDTH-LOW){1'b0}},
                 z1,
                 {LOW{1'b0}}};

            assign part_z0 =
                {{(2*WIDTH-2*LOW){1'b0}},
                 z0};

            assign p = part_z2 + part_z1 + part_z0;

        end

    endgenerate

endmodule