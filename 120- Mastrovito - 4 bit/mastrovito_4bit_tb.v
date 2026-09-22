`timescale 1ns / 1ps

module mastrovito_4bit_tb;

  reg  [3:0] A;
  reg  [3:0] B;
  wire [3:0] P;

  integer errors;
  integer i;
  integer j;

  // ----------------------------------------------------------
  // DUT
  // ----------------------------------------------------------

  mastrovito_4bit dut (
    .A(A),
    .B(B),
    .P(P)
  );

  // ----------------------------------------------------------
  // Independent reference GF(2^4) multiplier
  //
  // Polynomial:
  // P(x) = x^4 + x + 1
  //
  // This uses a bit-serial shift/reduce algorithm,
  // structurally different from the Mastrovito equations.
  // ----------------------------------------------------------

  function [3:0] ref_mult;
    input [3:0] ai;
    input [3:0] bi;

    reg [3:0] aa;
    reg [3:0] bb;
    reg [3:0] product;
    reg       high_bit;

    integer k;

    begin

      aa      = ai;
      bb      = bi;
      product = 4'b0000;

      for (k = 0; k < 4; k = k + 1) begin

        // GF addition = XOR
        if (bb[0])
          product = product ^ aa;

        // Shift and modular reduction
        high_bit = aa[3];

        aa = aa << 1;

        if (high_bit)
          aa = aa ^ 4'b0011;

        bb = bb >> 1;

      end

      ref_mult = product;

    end
  endfunction

  // ----------------------------------------------------------
  // Generic test task
  // ----------------------------------------------------------

  task check_case;

    input [3:0] test_A;
    input [3:0] test_B;

    reg [3:0] expected;

    begin

      A = test_A;
      B = test_B;

      #1;

      expected = ref_mult(test_A, test_B);

      if (P !== expected) begin

        $display(
          "FAIL: A=%h B=%h | DUT=%h | EXPECTED=%h",
          test_A,
          test_B,
          P,
          expected
        );

        errors = errors + 1;

      end
      else begin

        $display(
          "PASS: A=%h B=%h | P=%h",
          test_A,
          test_B,
          P
        );

      end

    end

  endtask

  // ----------------------------------------------------------
  // TEST 1: Zero multiplication
  //
  // A * 0 = 0
  // 0 * B = 0
  // ----------------------------------------------------------

  task test_zero;

    begin

      $display("\n========================================");
      $display("TEST 1: ZERO MULTIPLICATION");
      $display("========================================");

      for (i = 0; i < 16; i = i + 1) begin

        check_case(4'h0, i[3:0]);
        check_case(i[3:0], 4'h0);

      end

    end

  endtask

  // ----------------------------------------------------------
  // TEST 2: Multiplicative identity
  //
  // A * 1 = A
  // 1 * A = A
  // ----------------------------------------------------------

  task test_identity;

    begin

      $display("\n========================================");
      $display("TEST 2: MULTIPLICATIVE IDENTITY");
      $display("========================================");

      for (i = 0; i < 16; i = i + 1) begin

        check_case(i[3:0], 4'h1);
        check_case(4'h1, i[3:0]);

      end

    end

  endtask

  // ----------------------------------------------------------
  // TEST 3: Directed test vectors
  // ----------------------------------------------------------

  task test_directed;

    begin

      $display("\n========================================");
      $display("TEST 3: DIRECTED TEST VECTORS");
      $display("========================================");

      check_case(4'h2, 4'h2);
      check_case(4'h2, 4'h3);
      check_case(4'h3, 4'h4);
      check_case(4'h5, 4'h7);
      check_case(4'h6, 4'h9);
      check_case(4'h8, 4'hB);
      check_case(4'hA, 4'hC);
      check_case(4'hC, 4'hD);
      check_case(4'hE, 4'hF);
      check_case(4'hF, 4'hF);

    end

  endtask

  // ----------------------------------------------------------
  // TEST 4: Commutative property
  //
  // A * B = B * A
  // ----------------------------------------------------------

  task test_commutative;

    reg [3:0] result1;
    reg [3:0] result2;

    begin

      $display("\n========================================");
      $display("TEST 4: COMMUTATIVE PROPERTY");
      $display("========================================");

      for (i = 0; i < 16; i = i + 1) begin

        for (j = 0; j < 16; j = j + 1) begin

          A = i[3:0];
          B = j[3:0];

          #1;

          result1 = P;

          A = j[3:0];
          B = i[3:0];

          #1;

          result2 = P;

          if (result1 !== result2) begin

            $display(
              "FAIL: A=%h B=%h | A*B=%h | B*A=%h",
              i[3:0],
              j[3:0],
              result1,
              result2
            );

            errors = errors + 1;

          end

        end

      end

      if (errors == 0)
        $display("PASS: Commutative property verified");

    end

  endtask

  // ----------------------------------------------------------
  // TEST 5: Exhaustive verification
  //
  // 16 x 16 = 256 combinations
  // ----------------------------------------------------------

  task test_exhaustive;

    begin

      $display("\n========================================");
      $display("TEST 5: EXHAUSTIVE 256-CASE TEST");
      $display("========================================");

      for (i = 0; i < 16; i = i + 1) begin

        for (j = 0; j < 16; j = j + 1) begin

          A = i[3:0];
          B = j[3:0];

          #1;

          if (P !== ref_mult(A, B)) begin

            $display(
              "FAIL: A=%h B=%h | DUT=%h | REF=%h",
              A,
              B,
              P,
              ref_mult(A, B)
            );

            errors = errors + 1;

          end

        end

      end

      if (errors == 0)
        $display("PASS: All 256 combinations verified");

    end

  endtask

  // ----------------------------------------------------------
  // TEST 6: Random verification
  // ----------------------------------------------------------

  task test_random;

    reg [3:0] random_A;
    reg [3:0] random_B;
    reg [3:0] expected;

    begin

      $display("\n========================================");
      $display("TEST 6: RANDOM TESTING");
      $display("========================================");

      for (i = 0; i < 100; i = i + 1) begin

        random_A = $random;
        random_B = $random;

        A = random_A;
        B = random_B;

        #1;

        expected = ref_mult(random_A, random_B);

        if (P !== expected) begin

          $display(
            "FAIL RANDOM[%0d]: A=%h B=%h | DUT=%h | REF=%h",
            i,
            random_A,
            random_B,
            P,
            expected
          );

          errors = errors + 1;

        end

      end

      if (errors == 0)
        $display("PASS: 100 random cases verified");

    end

  endtask

  // ----------------------------------------------------------
  // MAIN TEST
  // ----------------------------------------------------------

  initial begin

    errors = 0;

    A = 4'h0;
    B = 4'h0;

    $display("\n");
    $display("================================================");
    $display("       MASTROVITO GF(2^4) MULTIPLIER TB");
    $display("       Polynomial: x^4 + x + 1");
    $display("================================================");

    // Basic functional tests
    test_zero;
    test_identity;
    test_directed;

    // Algebraic property
    test_commutative;

    // Complete input-space verification
    test_exhaustive;

    // Additional random verification
    test_random;

    // --------------------------------------------------------
    // FINAL RESULT
    // --------------------------------------------------------

    $display("\n================================================");

    if (errors == 0)
      $display("FINAL RESULT: PASS");
    else
      $display("FINAL RESULT: FAIL - %0d error(s)", errors);

    $display("================================================\n");

    $finish;

  end

endmodule