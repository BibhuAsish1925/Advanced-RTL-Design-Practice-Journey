`timescale 1ns / 1ps

module ct_cswap_tb;

    parameter W = 256;

    reg         sel;
    reg  [W-1:0] a_in;
    reg  [W-1:0] b_in;

    wire [W-1:0] a_out;
    wire [W-1:0] b_out;

    integer errors;

    // ============================================================
    // DUT
    // ============================================================

    ct_cswap #(
        .W(W)
    ) dut (
        .sel   (sel),
        .a_in  (a_in),
        .b_in  (b_in),
        .a_out (a_out),
        .b_out (b_out)
    );

    // ============================================================
    // Check task
    // ============================================================

    task check_case;
        input         test_sel;
        input [W-1:0] test_a;
        input [W-1:0] test_b;

        reg [W-1:0] expected_a;
        reg [W-1:0] expected_b;

        begin

            sel  = test_sel;
            a_in = test_a;
            b_in = test_b;

            #10;

            if (test_sel == 1'b0) begin
                expected_a = test_a;
                expected_b = test_b;
            end
            else begin
                expected_a = test_b;
                expected_b = test_a;
            end

            if ((a_out !== expected_a) ||
                (b_out !== expected_b)) begin

                $display("------------------------------------------------");
                $display("FAIL");
                $display("SEL      = %b", test_sel);
                $display("A_IN     = %h", test_a);
                $display("B_IN     = %h", test_b);
                $display("A_OUT    = %h", a_out);
                $display("B_OUT    = %h", b_out);
                $display("EXPECTED A= %h", expected_a);
                $display("EXPECTED B= %h", expected_b);
                $display("------------------------------------------------");

                errors = errors + 1;

            end
            else begin

                $display("PASS | SEL=%b | A_IN=%h | B_IN=%h | A_OUT=%h | B_OUT=%h",
                         test_sel, test_a, test_b, a_out, b_out);

            end

        end
    endtask

    // ============================================================
    // Test sequence
    // ============================================================

    initial begin

        errors = 0;

        // Initial values
        sel  = 1'b0;
        a_in = {W{1'b0}};
        b_in = {W{1'b0}};

        #10;

        $display("");
        $display("================================================");
        $display(" Constant-Time Conditional Swap Test");
        $display(" Width = %0d bits", W);
        $display("================================================");
        $display("");

        // --------------------------------------------------------
        // Test 1: sel = 0
        // No swap
        // --------------------------------------------------------

        check_case(
            1'b0,
            256'h1111111111111111_2222222222222222_3333333333333333_4444444444444444,
            256'hAAAAAAAAAAAAAAAA_BBBBBBBBBBBBBBBB_CCCCCCCCCCCCCCCC_DDDDDDDDDDDDDDDD
        );

        // --------------------------------------------------------
        // Test 2: sel = 1
        // Swap
        // --------------------------------------------------------

        check_case(
            1'b1,
            256'h1111111111111111_2222222222222222_3333333333333333_4444444444444444,
            256'hAAAAAAAAAAAAAAAA_BBBBBBBBBBBBBBBB_CCCCCCCCCCCCCCCC_DDDDDDDDDDDDDDDD
        );

        // --------------------------------------------------------
        // Test 3: zero / all ones
        // --------------------------------------------------------

        check_case(
            1'b0,
            256'h0000000000000000_0000000000000000_0000000000000000_0000000000000000,
            256'hFFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF
        );

        check_case(
            1'b1,
            256'h0000000000000000_0000000000000000_0000000000000000_0000000000000000,
            256'hFFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF
        );

        // --------------------------------------------------------
        // Test 4: Equal inputs
        // --------------------------------------------------------

        check_case(
            1'b0,
            256'h123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0,
            256'h123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0
        );

        check_case(
            1'b1,
            256'h123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0,
            256'h123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0
        );

        // --------------------------------------------------------
        // Test 5: Alternating patterns
        // --------------------------------------------------------

        check_case(
            1'b0,
            256'hAAAAAAAAAAAAAAAA_AAAAAAAAAAAAAAAA_AAAAAAAAAAAAAAAA_AAAAAAAAAAAAAAAA,
            256'h5555555555555555_5555555555555555_5555555555555555_5555555555555555
        );

        check_case(
            1'b1,
            256'hAAAAAAAAAAAAAAAA_AAAAAAAAAAAAAAAA_AAAAAAAAAAAAAAAA_AAAAAAAAAAAAAAAA,
            256'h5555555555555555_5555555555555555_5555555555555555_5555555555555555
        );

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        #10;

        $display("");
        $display("================================================");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $display("================================================");
        $display("");

        // Keep simulation alive briefly so waveform is visible
        #20;

        $finish;

    end

endmodule