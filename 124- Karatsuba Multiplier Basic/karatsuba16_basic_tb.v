`timescale 1ns / 1ps

module karatsuba16_basic_tb;

    reg  [15:0] a;
    reg  [15:0] b;
    wire [31:0] p;

    integer errors;
    integer i;

    karatsuba16_basic dut (
        .a(a),
        .b(b),
        .p(p)
    );

    // ------------------------------------------------------------
    // Test task
    // ------------------------------------------------------------

    task check_case;
        input [15:0] test_a;
        input [15:0] test_b;

        reg [31:0] expected;

        begin

            a = test_a;
            b = test_b;

            #1;

            expected = test_a * test_b;

            if (p !== expected) begin

                $display("FAIL: A=%h B=%h | P=%h Expected=%h",
                         a, b, p, expected);

                errors = errors + 1;

            end
            else begin

                $display("PASS: A=%h B=%h | P=%h",
                         a, b, p);

            end

        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------

    initial begin

        errors = 0;

        $display("==============================================");
        $display(" 16x16 Karatsuba Multiplier Test");
        $display("==============================================");

        // Zero tests
        check_case(16'h0000, 16'h0000);
        check_case(16'h0000, 16'hFFFF);
        check_case(16'hFFFF, 16'h0000);

        // Identity tests
        check_case(16'h0001, 16'h0001);
        check_case(16'h1234, 16'h0001);
        check_case(16'hFFFF, 16'h0001);

        // Directed tests
        check_case(16'h0002, 16'h0003);
        check_case(16'h0005, 16'h0007);
        check_case(16'h0010, 16'h0010);
        check_case(16'h00FF, 16'h00FF);

        // Cross-half tests
        check_case(16'h0101, 16'h0101);
        check_case(16'h00FF, 16'hFF00);
        check_case(16'h1234, 16'h5678);
        check_case(16'hABCD, 16'h1357);

        // Maximum values
        check_case(16'hFFFF, 16'hFFFF);
        check_case(16'hFFFF, 16'h0002);
        check_case(16'h8000, 16'h8000);

        // Random tests
        $display("----------------------------------------------");
        $display("Random Tests");
        $display("----------------------------------------------");

        for (i = 0; i < 200; i = i + 1) begin

            a = $random;
            b = $random;

            #1;

            if (p !== (a * b)) begin

                $display("FAIL: Random A=%h B=%h | P=%h Expected=%h",
                         a, b, p, (a * b));

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