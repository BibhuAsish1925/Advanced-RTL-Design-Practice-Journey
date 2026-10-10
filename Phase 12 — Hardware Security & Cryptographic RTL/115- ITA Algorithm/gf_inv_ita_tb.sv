`timescale 1ns/1ps

module gf_inv_ita_tb;

  logic [7:0] a;
  logic [7:0] inv;

  // --------------------------------------------------------------
  // DUT
  // --------------------------------------------------------------

  gf_inv_ita dut (
    .a   (a),
    .inv (inv)
  );

  // --------------------------------------------------------------
  // Test task
  // --------------------------------------------------------------

  task automatic check_inverse(
    input [7:0] test_a,
    input [7:0] expected_inv
  );

    begin

      a = test_a;

      #10;

      if (inv !== expected_inv) begin
        $error(
          "FAIL: a = %02h, expected inv = %02h, got = %02h",
          test_a,
          expected_inv,
          inv
        );
      end
      else begin
        $display(
          "PASS: a = %02h -> inv = %02h",
          test_a,
          inv
        );
      end

    end

  endtask


  // --------------------------------------------------------------
  // Test sequence
  // --------------------------------------------------------------

  initial begin

    $display("\n========================================");
    $display("GF(2^8) ITA INVERSE TEST");
    $display("========================================");

    // ------------------------------------------------------------
    // Zero case
    // AES convention: Inv(00) = 00
    // ------------------------------------------------------------

    check_inverse(
      8'h00,
      8'h00
    );

    // ------------------------------------------------------------
    // Known AES GF(2^8) inverses
    // ------------------------------------------------------------

    check_inverse(
      8'h01,
      8'h01
    );

    check_inverse(
      8'h02,
      8'h8D
    );

    check_inverse(
      8'h03,
      8'hF6
    );

    check_inverse(
      8'h53,
      8'hCA
    );

    check_inverse(
      8'hCA,
      8'h53
    );

    check_inverse(
      8'hFF,
      8'h1C
    );

    // ------------------------------------------------------------
    // Additional values
    // ------------------------------------------------------------

    check_inverse(
      8'h10,
      8'hE1
    );

    check_inverse(
      8'h20,
      8'hA0
    );

    // ------------------------------------------------------------
    // Finish
    // ------------------------------------------------------------

    $display("\n========================================");
    $display("GF(2^8) ITA TEST COMPLETED");
    $display("========================================");

    $finish;

  end

endmodule