`timescale 1ns / 1ps

module montgomery_ladder_basic_tb;

    reg  [7:0] X;
    reg  [7:0] E;
    reg  [7:0] N;
    wire [7:0] Y;

    integer errors;
    integer i;

    montgomery_ladder_basic dut (
        .X(X),
        .E(E),
        .N(N),
        .Y(Y)
    );

    // ------------------------------------------------------------
    // Reference modular exponentiation
    // ------------------------------------------------------------
    function [7:0] reference_power;
        input [7:0] base;
        input [7:0] exponent;
        input [7:0] modulus;

        reg [15:0] result;
        reg [15:0] base_temp;
        integer j;

        begin

            if (modulus == 0) begin
                reference_power = 8'h00;
            end
            else begin

                result    = 16'd1;
                base_temp = base % modulus;

                // Simple binary exponentiation
                for (j = 0; j < 8; j = j + 1) begin

                    if (exponent[j])
                        result = (result * base_temp) % modulus;

                    base_temp = (base_temp * base_temp) % modulus;

                end

                reference_power = result[7:0];

            end
        end
    endfunction

    // ------------------------------------------------------------
    // Test task
    // ------------------------------------------------------------
    task check_case;
        input [7:0] x;
        input [7:0] e;
        input [7:0] n;

        reg [7:0] expected;

        begin

            X = x;
            E = e;
            N = n;

            #1;

            expected = reference_power(x, e, n);

            if (Y !== expected) begin

                $display("FAIL: X=%h E=%h N=%h | Y=%h Expected=%h",
                         X, E, N, Y, expected);

                errors = errors + 1;

            end
            else begin

                $display("PASS: X=%h E=%h N=%h | Y=%h",
                         X, E, N, Y);

            end

        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------
    initial begin

        errors = 0;

        $display("==============================================");
        $display(" Montgomery Ladder Test");
        $display("==============================================");

        // --------------------------------------------------------
        // Basic exponent cases
        // --------------------------------------------------------

        // X^0 = 1 mod N
        check_case(8'h05, 8'h00, 8'h13);
        check_case(8'h25, 8'h00, 8'h1F);

        // X^1 = X mod N
        check_case(8'h05, 8'h01, 8'h13);
        check_case(8'h0A, 8'h01, 8'h17);

        // --------------------------------------------------------
        // Directed tests
        // --------------------------------------------------------

        check_case(8'h02, 8'h03, 8'h13);
        check_case(8'h02, 8'h08, 8'h17);
        check_case(8'h03, 8'h05, 8'h1F);
        check_case(8'h05, 8'h0A, 8'h17);
        check_case(8'h07, 8'h0F, 8'h19);
        check_case(8'h0B, 8'h10, 8'h1D);
        check_case(8'h12, 8'h13, 8'h25);
        check_case(8'h25, 8'h07, 8'h2F);

        // --------------------------------------------------------
        // Larger values
        // --------------------------------------------------------

        check_case(8'h55, 8'h33, 8'h7F);
        check_case(8'hAA, 8'h55, 8'hF1);
        check_case(8'hFE, 8'h20, 8'hFD);
        check_case(8'hFF, 8'hFF, 8'hFD);

        // --------------------------------------------------------
        // X = 0
        // --------------------------------------------------------

        check_case(8'h00, 8'h01, 8'h17);
        check_case(8'h00, 8'h08, 8'h17);
        check_case(8'h00, 8'hFF, 8'h1F);

        // --------------------------------------------------------
        // X = 1
        // --------------------------------------------------------

        check_case(8'h01, 8'h10, 8'h17);
        check_case(8'h01, 8'hFF, 8'h7F);

        // --------------------------------------------------------
        // Modulus = 1
        // --------------------------------------------------------

        check_case(8'h55, 8'hAA, 8'h01);
        check_case(8'hFF, 8'hFF, 8'h01);

        // --------------------------------------------------------
        // N = 0 protection
        // --------------------------------------------------------

        check_case(8'h55, 8'hAA, 8'h00);

        // --------------------------------------------------------
        // Random tests
        // --------------------------------------------------------

        $display("----------------------------------------------");
        $display("Random Tests");
        $display("----------------------------------------------");

        for (i = 0; i < 100; i = i + 1) begin

            X = $random;
            E = $random;
            N = ($random % 255) + 1;

            #1;

            if (Y !== reference_power(X, E, N)) begin

                $display("FAIL: Random X=%h E=%h N=%h | Y=%h Expected=%h",
                         X, E, N, Y,
                         reference_power(X, E, N));

                errors = errors + 1;

            end

        end

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("==============================================");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $display("==============================================");

        $finish;

    end

endmodule