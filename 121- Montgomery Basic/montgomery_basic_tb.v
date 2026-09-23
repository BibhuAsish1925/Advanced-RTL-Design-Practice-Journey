`timescale 1ns / 1ps

module montgomery_basic_tb;

    reg  [7:0] A;
    reg  [7:0] B;
    reg  [7:0] N;
    wire [7:0] C;

    integer errors;
    integer i;

    montgomery_basic dut (
        .A(A),
        .B(B),
        .N(N),
        .C(C)
    );

    // ------------------------------------------------------------
    // Reference model
    // ------------------------------------------------------------
    function [7:0] reference_mod_mult;
        input [7:0] a;
        input [7:0] b;
        input [7:0] n;

        reg [15:0] temp;

        begin
            temp = a * b;

            if (n != 0)
                reference_mod_mult = temp % n;
            else
                reference_mod_mult = 8'h00;
        end
    endfunction

    // ------------------------------------------------------------
    // Test task
    // ------------------------------------------------------------
    task check_case;
        input [7:0] a;
        input [7:0] b;
        input [7:0] n;

        reg [7:0] expected;

        begin
            A = a;
            B = b;
            N = n;

            #1;

            expected = reference_mod_mult(a, b, n);

            if (C !== expected) begin
                $display("FAIL: A=%h B=%h N=%h | C=%h Expected=%h",
                         A, B, N, C, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS: A=%h B=%h N=%h | C=%h",
                         A, B, N, C);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------
    initial begin

        errors = 0;

        $display("==============================================");
        $display(" Basic Modular Multiplier Test");
        $display("==============================================");

        // Zero cases
        check_case(8'h00, 8'h25, 8'h17);
        check_case(8'h25, 8'h00, 8'h17);

        // Identity cases
        check_case(8'h01, 8'h25, 8'h17);
        check_case(8'h25, 8'h01, 8'h17);

        // Directed cases
        check_case(8'h05, 8'h07, 8'h13);
        check_case(8'h0A, 8'h0B, 8'h17);
        check_case(8'h12, 8'h0F, 8'h1D);
        check_case(8'h25, 8'h13, 8'h1F);
        check_case(8'h55, 8'h33, 8'h7F);
        check_case(8'hAA, 8'h55, 8'hF1);
        check_case(8'hFF, 8'hFF, 8'hFD);

        // Boundary-style modulus tests
        check_case(8'hFE, 8'h02, 8'hFF);
        check_case(8'hFF, 8'h01, 8'hFF);
        check_case(8'h80, 8'h80, 8'h7F);

        // Modulus = 1
        check_case(8'h55, 8'hAA, 8'h01);

        // N = 0 protection
        check_case(8'h55, 8'hAA, 8'h00);

        // Random tests
        $display("----------------------------------------------");
        $display("Random Tests");
        $display("----------------------------------------------");

        for (i = 0; i < 100; i = i + 1) begin
            A = $random;
            B = $random;
            N = ($random % 255) + 1;

            #1;

            if (C !== reference_mod_mult(A, B, N)) begin
                $display("FAIL: Random A=%h B=%h N=%h C=%h Expected=%h",
                         A, B, N, C,
                         reference_mod_mult(A, B, N));
                errors = errors + 1;
            end
        end

        // Final result
        $display("==============================================");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $display("==============================================");

        $finish;
    end

endmodule