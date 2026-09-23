`timescale 1ns / 1ps

module karatsuba_mul_tb;

    // ------------------------------------------------------------
    // 32-bit DUT
    // ------------------------------------------------------------

    reg  [31:0] a32;
    reg  [31:0] b32;
    wire [63:0] p32;

    karatsuba_mul #(
        .WIDTH(32),
        .BASE(8)
    ) dut32 (
        .a(a32),
        .b(b32),
        .p(p32)
    );

    // ------------------------------------------------------------
    // 16-bit DUT
    // ------------------------------------------------------------

    reg  [15:0] a16;
    reg  [15:0] b16;
    wire [31:0] p16;

    karatsuba_mul #(
        .WIDTH(16),
        .BASE(8)
    ) dut16 (
        .a(a16),
        .b(b16),
        .p(p16)
    );

    integer errors;
    integer i;

    // ------------------------------------------------------------
    // 16-bit test
    // ------------------------------------------------------------

    task check16;
        input [15:0] test_a;
        input [15:0] test_b;

        reg [31:0] expected;

        begin

            a16 = test_a;
            b16 = test_b;

            #1;

            expected = test_a * test_b;

            if (p16 !== expected) begin

                $display("FAIL 16-bit: A=%h B=%h P=%h EXP=%h",
                         a16, b16, p16, expected);

                errors = errors + 1;

            end

        end
    endtask

    // ------------------------------------------------------------
    // 32-bit test
    // ------------------------------------------------------------

    task check32;
        input [31:0] test_a;
        input [31:0] test_b;

        reg [63:0] expected;

        begin

            a32 = test_a;
            b32 = test_b;

            #1;

            expected = test_a * test_b;

            if (p32 !== expected) begin

                $display("FAIL 32-bit: A=%h B=%h P=%h EXP=%h",
                         a32, b32, p32, expected);

                errors = errors + 1;

            end

        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------

    initial begin

        errors = 0;

        $display("==============================================");
        $display(" Recursive Karatsuba Multiplier Test");
        $display("==============================================");

        // ========================================================
        // 16-bit tests
        // ========================================================

        $display("----------------------------------------------");
        $display("16-bit Tests");
        $display("----------------------------------------------");

        check16(16'h0000, 16'h0000);
        check16(16'h0000, 16'hFFFF);
        check16(16'h0001, 16'hFFFF);

        check16(16'h0002, 16'h0003);
        check16(16'h00FF, 16'h00FF);
        check16(16'h1234, 16'h5678);
        check16(16'hABCD, 16'h1357);

        check16(16'hFFFF, 16'hFFFF);
        check16(16'h8000, 16'h8000);

        // ========================================================
        // 32-bit tests
        // ========================================================

        $display("----------------------------------------------");
        $display("32-bit Tests");
        $display("----------------------------------------------");

        check32(32'h00000000, 32'h00000000);
        check32(32'h00000000, 32'hFFFFFFFF);

        check32(32'h00000001, 32'hFFFFFFFF);
        check32(32'h00000002, 32'h00000003);

        check32(32'h0000FFFF, 32'h0000FFFF);
        check32(32'h00010001, 32'h00010001);

        check32(32'h12345678, 32'h00000002);
        check32(32'h12345678, 32'h9ABCDEF0);

        check32(32'hABCDEF01, 32'h13572468);
        check32(32'hFFFFFFFF, 32'hFFFFFFFF);

        check32(32'h80000000, 32'h80000000);

        // ========================================================
        // Random 16-bit tests
        // ========================================================

        $display("----------------------------------------------");
        $display("Random 16-bit Tests");
        $display("----------------------------------------------");

        for (i = 0; i < 100; i = i + 1) begin

            a16 = $random;
            b16 = $random;

            #1;

            if (p16 !== (a16 * b16)) begin

                $display("FAIL Random16: A=%h B=%h P=%h EXP=%h",
                         a16, b16, p16, (a16 * b16));

                errors = errors + 1;

            end

        end

        // ========================================================
        // Random 32-bit tests
        // ========================================================

        $display("----------------------------------------------");
        $display("Random 32-bit Tests");
        $display("----------------------------------------------");

        for (i = 0; i < 100; i = i + 1) begin

            a32 = {$random, $random};
            b32 = {$random, $random};

            #1;

            if (p32 !== (a32 * b32)) begin

                $display("FAIL Random32: A=%h B=%h P=%h EXP=%h",
                         a32, b32, p32, (a32 * b32));

                errors = errors + 1;

            end

        end

        // ========================================================
        // Final result
        // ========================================================

        $display("==============================================");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $display("==============================================");

        $finish;

    end

endmodule