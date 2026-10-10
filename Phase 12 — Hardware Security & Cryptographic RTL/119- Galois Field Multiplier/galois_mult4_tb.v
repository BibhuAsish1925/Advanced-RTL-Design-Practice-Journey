`timescale 1ns / 1ps

module galois_mult4_tb;

  reg  [3:0] a;
  reg  [3:0] b;
  wire [3:0] product;

  integer errors;
  integer i;
  integer j;

  // ----------------------------------------------------------
  // DUT
  // ----------------------------------------------------------

  galois_mult4 dut (
    .a       (a),
    .b       (b),
    .product (product)
  );

  // ----------------------------------------------------------
  // Reference GF(2^4) multiplier
  //
  // Irreducible polynomial:
  // P(x) = x^4 + x + 1 = 10011
  // ----------------------------------------------------------

  function [3:0] ref_mult;
    input [3:0] ai;
    input [3:0] bi;

    reg [3:0] aa;
    reg [3:0] bb;
    reg [3:0] p;
    reg       high_bit;
    integer   k;

    begin
      aa = ai;
      bb = bi;
      p  = 4'b0000;

      for (k = 0; k < 4; k = k + 1) begin

        if (bb[0])
          p = p ^ aa;

        high_bit = aa[3];

        aa = aa << 1;

        if (high_bit)
          aa = aa ^ 4'b0011;

        bb = bb >> 1;

      end

      ref_mult = p;

    end
  endfunction

  // ----------------------------------------------------------
  // Test task
  // ----------------------------------------------------------

  task check_case;
    input [3:0] test_a;
    input [3:0] test_b;
    reg   [3:0] expected;

    begin

      a = test_a;
      b = test_b;

      #1;

      expected = ref_mult(test_a, test_b);

      if (product !== expected) begin

        $display(
          "FAIL: a=%h b=%h | DUT=%h | EXPECTED=%h",
          test_a,
          test_b,
          product,
          expected
        );

        errors = errors + 1;

      end
      else begin

        $display(
          "PASS: a=%h b=%h | product=%h",
          test_a,
          test_b,
          product
        );

      end

    end
  endtask

  // ----------------------------------------------------------
  // Test 1: Zero multiplication
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
  // Test 2: Multiplication by identity
  //
  // In GF(2^4):
  // a * 1 = a
  // 1 * a = a
  // ----------------------------------------------------------

  task test_identity;
    begin

      $display("\n========================================");
      $display("TEST 2: IDENTITY ELEMENT");
      $display("========================================");

      for (i = 0; i < 16; i = i + 1) begin

        check_case(i[3:0], 4'h1);
        check_case(4'h1, i[3:0]);

      end

    end
  endtask

  // ----------------------------------------------------------
  // Test 3: Directed multiplication cases
  // ----------------------------------------------------------

  task test_directed;
    begin

      $display("\n========================================");
      $display("TEST 3: DIRECTED TEST CASES");
      $display("========================================");

      check_case(4'h2, 4'h2);
      check_case(4'h3, 4'h4);
      check_case(4'h5, 4'h7);
      check_case(4'h6, 4'h9);
      check_case(4'hA, 4'hB);
      check_case(4'hC, 4'hD);
      check_case(4'hF, 4'hF);

    end
  endtask

  // ----------------------------------------------------------
  // Test 4: Commutative property
  //
  // a * b = b * a
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

          a = i[3:0];
          b = j[3:0];

          #1;

          result1 = product;

          a = j[3:0];
          b = i[3:0];

          #1;

          result2 = product;

          if (result1 !== result2) begin

            $display(
              "FAIL: Commutativity a=%h b=%h | a*b=%h | b*a=%h",
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
  // Test 5: Exhaustive verification
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

          a = i[3:0];
          b = j[3:0];

          #1;

          if (product !== ref_mult(a, b)) begin

            $display(
              "FAIL: a=%h b=%h | DUT=%h | REF=%h",
              a,
              b,
              product,
              ref_mult(a, b)
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
  // Test 6: Random testing
  // ----------------------------------------------------------

  task test_random;
    reg [3:0] random_a;
    reg [3:0] random_b;
    reg [3:0] expected;

    begin

      $display("\n========================================");
      $display("TEST 6: RANDOM TESTING");
      $display("========================================");

      for (i = 0; i < 100; i = i + 1) begin

        random_a = $random;
        random_b = $random;

        a = random_a;
        b = random_b;

        #1;

        expected = ref_mult(random_a, random_b);

        if (product !== expected) begin

          $display(
            "FAIL RANDOM[%0d]: a=%h b=%h | DUT=%h | REF=%h",
            i,
            random_a,
            random_b,
            product,
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
  // Main test sequence
  // ----------------------------------------------------------

  initial begin

    errors = 0;
    a = 4'h0;
    b = 4'h0;

    $display("\n");
    $display("================================================");
    $display("     GF(2^4) GALOIS MULTIPLIER TESTBENCH");
    $display("     Polynomial: x^4 + x + 1");
    $display("================================================");

    // Directed tests
    test_zero;
    test_identity;
    test_directed;

    // Mathematical property
    test_commutative;

    // Complete functional verification
    test_exhaustive;

    // Additional random verification
    test_random;

    // --------------------------------------------------------
    // Final result
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