// ================================================================
// GF(2^8) Inverse using Itoh-Tsujii style exponentiation
//
// AES irreducible polynomial:
// x^8 + x^4 + x^3 + x + 1
// Polynomial representation: 8'h1B
//
// For non-zero a:
//     a^(-1) = a^(2^8 - 2) = a^254
//
// Note:
//     GF(2^8) uses characteristic-2 arithmetic.
//     Addition  = XOR
//     Multiplication = carry-less multiplication + reduction
// ================================================================

module gf_inv_ita (
  input  logic [7:0] a,
  output logic [7:0] inv
);

  // --------------------------------------------------------------
  // GF(2^8) multiplication
  // --------------------------------------------------------------

  function automatic [7:0] gf_mult;
    input [7:0] x;
    input [7:0] y;

    reg [7:0] product;
    reg [7:0] temp;
    integer i;

    begin
      product = 8'h00;
      temp    = x;

      for (i = 0; i < 8; i = i + 1) begin

        // Addition in GF(2^8) = XOR
        if (y[i])
          product = product ^ temp;

        // Multiply temp by x
        // Reduce using AES polynomial x^8+x^4+x^3+x+1
        if (temp[7])
          temp = (temp << 1) ^ 8'h1B;
        else
          temp = temp << 1;

      end

      gf_mult = product;
    end
  endfunction


  // --------------------------------------------------------------
  // GF(2^8) squaring
  // --------------------------------------------------------------

  function automatic [7:0] gf_square;
    input [7:0] x;

    begin
      gf_square = gf_mult(x, x);
    end
  endfunction


  // --------------------------------------------------------------
  // ITA-style exponentiation chain
  //
  // a^2
  // a^4
  // a^8
  // a^16
  // a^32
  // a^64
  // a^128
  //
  // Then:
  //
  // 254 = 128 + 64 + 32 + 16 + 8 + 4 + 2
  //
  // Therefore:
  //
  // a^254 =
  // a^128 * a^64 * a^32 * a^16 *
  // a^8   * a^4  * a^2
  // --------------------------------------------------------------

  logic [7:0] a2;
  logic [7:0] a4;
  logic [7:0] a8;
  logic [7:0] a16;
  logic [7:0] a32;
  logic [7:0] a64;
  logic [7:0] a128;

  logic [7:0] m1;
  logic [7:0] m2;
  logic [7:0] m3;
  logic [7:0] m4;
  logic [7:0] m5;
  logic [7:0] m6;

  // Squaring chain
  assign a2   = gf_square(a);
  assign a4   = gf_square(a2);
  assign a8   = gf_square(a4);
  assign a16  = gf_square(a8);
  assign a32  = gf_square(a16);
  assign a64  = gf_square(a32);
  assign a128 = gf_square(a64);

  // Multiplication chain
  assign m1 = gf_mult(a128, a64);
  assign m2 = gf_mult(m1, a32);
  assign m3 = gf_mult(m2, a16);
  assign m4 = gf_mult(m3, a8);
  assign m5 = gf_mult(m4, a4);
  assign m6 = gf_mult(m5, a2);

  // a^254 = a^(-1) for a != 0
  assign inv = (a == 8'h00) ? 8'h00 : m6;

endmodule