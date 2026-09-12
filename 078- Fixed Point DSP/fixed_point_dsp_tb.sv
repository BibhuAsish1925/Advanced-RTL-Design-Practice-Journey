`timescale 1ns/1ps

module fixed_point_dsp_tb;

    parameter int DATA_WIDTH    = 8;
    parameter int FRACTION_BITS = 4;
    parameter int OUTPUT_WIDTH  = 2 * DATA_WIDTH;

    logic clk;
    logic rst;
    logic en;

    logic [1:0] opcode;

    logic signed [DATA_WIDTH-1:0] a;
    logic signed [DATA_WIDTH-1:0] b;

    logic signed [OUTPUT_WIDTH-1:0] result;

    integer reference_accumulator;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    fixed_point_dsp #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRACTION_BITS(FRACTION_BITS),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .en     (en),
        .opcode (opcode),
        .a      (a),
        .b      (b),
        .result (result)
    );

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------
    // Convert real -> fixed-point, truncate toward zero.
    // Fine for ADD/SUBTRACT: results are exact, no rescaling.
    // -------------------------------------------------
    function automatic integer real_to_fixed(input real value);
        real scaled;
        begin
            scaled = value * (2.0 ** FRACTION_BITS);
            real_to_fixed = $rtoi(scaled);
        end
    endfunction

    // -------------------------------------------------
    // Convert real -> fixed-point, floor toward -inf.
    // Matches the DUT's arithmetic-right-shift rescaling
    // behavior; used for MULTIPLY/MAC.
    // -------------------------------------------------
    function automatic integer real_to_fixed_floor(input real value);
        real scaled;
        begin
            scaled = value * (2.0 ** FRACTION_BITS);
            real_to_fixed_floor = $rtoi($floor(scaled));
        end
    endfunction

    // -------------------------------------------------
    // Convert fixed-point -> real (for display only)
    // -------------------------------------------------
    function automatic real fixed_to_real(input integer value);
        begin
            fixed_to_real = value / (2.0 ** FRACTION_BITS);
        end
    endfunction

    // -------------------------------------------------
    // Apply Test
    // -------------------------------------------------
    task automatic test_operation(
        input logic [1:0] op,
        input real input_a,
        input real input_b
    );
        integer fixed_a;
        integer fixed_b;
        integer expected;
        integer actual;
        integer product_fixed;
        begin
            fixed_a = real_to_fixed(input_a);
            fixed_b = real_to_fixed(input_b);

            a = fixed_a;
            b = fixed_b;
            opcode = op;

            case (op)
                2'b00: expected = real_to_fixed(input_a + input_b);
                2'b01: expected = real_to_fixed(input_a - input_b);
                2'b10: expected = real_to_fixed_floor(input_a * input_b);
                2'b11: begin
                    product_fixed = real_to_fixed_floor(input_a * input_b);
                    expected = reference_accumulator + product_fixed;
                    reference_accumulator = expected;
                end
                default: expected = 0;
            endcase

            @(posedge clk);
            #1;

            actual = result;

            if (actual !== expected) begin
                $error(
                    "FAIL: A=%0f B=%0f OP=%b Expected=%0d Actual=%0d",
                    input_a, input_b, op, expected, actual
                );
            end
            else begin
                $display(
                    "PASS: A=%0f B=%0f OP=%b Result=%0f",
                    input_a, input_b, op, fixed_to_real(actual)
                );
            end
        end
    endtask

    // -------------------------------------------------
    // Main Test
    // -------------------------------------------------
    initial begin
        rst    = 1'b1;
        en     = 1'b0;
        opcode = 2'b00;
        a = '0;
        b = '0;
        reference_accumulator = 0;

        // Reset
        @(posedge clk);
        #1;
        rst = 1'b0;
        en  = 1'b1;

        // Addition
        test_operation(2'b00, 2.5, 1.25);

        // Subtraction
        test_operation(2'b01, 5.5, 2.25);

        // Multiplication
        test_operation(2'b10, 2.5, 1.5);

        // Negative numbers
        test_operation(2'b00, -2.5, 1.25);
        test_operation(2'b01, -3.5, -1.25);
        test_operation(2'b10, -2.0, 1.5);

        // Negative fractional multiply -- specifically exercises the
        // floor-vs-truncate rounding edge case
        test_operation(2'b10, -0.5, 0.3125);

        // ---------------------------------------------
        // MAC test
        // ---------------------------------------------
        rst = 1'b1;
        @(posedge clk);
        #1;
        rst = 1'b0;
        reference_accumulator = 0;

        // 1.5 x 2.0 = 3.0
        test_operation(2'b11, 1.5, 2.0);
        // 0.5 x 4.0 = 2.0 -> accumulated = 5.0
        test_operation(2'b11, 0.5, 4.0);
        // -1.0 x 1.5 = -1.5 -> accumulated = 3.5
        test_operation(2'b11, -1.0, 1.5);

        // ---------------------------------------------
        // Disable test
        // ---------------------------------------------
        @(negedge clk);
        opcode = 2'b00;
        a = real_to_fixed(9.0);
        b = real_to_fixed(1.0);
        en = 1'b0;
        @(posedge clk);
        #1;
        if (result !== reference_accumulator)
            $error("FAIL: result changed while enable was LOW, got %0d", result);
        else
            $display("PASS: Enable test | result held at %0d", result);

        $display("-----------------------------------------");
        $display("FIXED-POINT DSP TEST COMPLETED");
        $display("-----------------------------------------");

        $finish;
    end

endmodule