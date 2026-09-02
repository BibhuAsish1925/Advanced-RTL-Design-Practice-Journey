module digital_convolution_tb;

    parameter int DATA_WIDTH = 8;
    parameter int COEFF_WIDTH = 8;
    parameter int TAPS = 4;
    parameter int OUTPUT_WIDTH =
        DATA_WIDTH + COEFF_WIDTH + $clog2(TAPS);

    logic signed [DATA_WIDTH-1:0] data_in [TAPS];

    logic signed [COEFF_WIDTH-1:0] coeff [TAPS];

    logic signed [OUTPUT_WIDTH-1:0] result;

    logic signed [OUTPUT_WIDTH-1:0] expected_result;

    integer i;

    // DUT
    digital_convolution #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .TAPS(TAPS),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) dut (
        .data_in(data_in),
        .coeff(coeff),
        .result(result)
    );

    // --------------------------------------------------
    // Reference Model
    // --------------------------------------------------

    task automatic calculate_expected;

        logic signed [DATA_WIDTH+COEFF_WIDTH-1:0] product;
        logic signed [OUTPUT_WIDTH-1:0] temp_sum;

        begin

            temp_sum = '0;

            for (int j = 0; j < TAPS; j++) begin

                product = data_in[j] * coeff[j];

                temp_sum = temp_sum + product;

            end

            expected_result = temp_sum;

        end

    endtask


    // --------------------------------------------------
    // Test Procedure
    // --------------------------------------------------

    task automatic run_test;

        begin

            #1;

            calculate_expected;

            if (result !== expected_result) begin

                $error(
                    "FAIL: Expected=%0d Actual=%0d",
                    expected_result,
                    result
                );

            end
            else begin

                $display(
                    "PASS: Expected=%0d Actual=%0d",
                    expected_result,
                    result
                );

            end

        end

    endtask


    initial begin

        // ------------------------------------------------
        // Test 1
        // ------------------------------------------------

        data_in[0] = 8'd1;
        data_in[1] = 8'd2;
        data_in[2] = 8'd3;
        data_in[3] = 8'd4;

        coeff[0] = 8'd1;
        coeff[1] = 8'd1;
        coeff[2] = 8'd1;
        coeff[3] = 8'd1;

        run_test;


        // ------------------------------------------------
        // Test 2
        // ------------------------------------------------

        data_in[0] = 8'd2;
        data_in[1] = 8'd4;
        data_in[2] = 8'd6;
        data_in[3] = 8'd8;

        coeff[0] = 8'd1;
        coeff[1] = 8'd2;
        coeff[2] = 8'd3;
        coeff[3] = 8'd4;

        run_test;


        // ------------------------------------------------
        // Test 3
        // ------------------------------------------------

        data_in[0] = 8'd10;
        data_in[1] = 8'd20;
        data_in[2] = 8'd30;
        data_in[3] = 8'd40;

        coeff[0] = 8'd4;
        coeff[1] = 8'd3;
        coeff[2] = 8'd2;
        coeff[3] = 8'd1;

        run_test;


        // ------------------------------------------------
        // Test 4: Zero coefficients
        // ------------------------------------------------

        data_in[0] = 8'd50;
        data_in[1] = 8'd60;
        data_in[2] = 8'd70;
        data_in[3] = 8'd80;

        coeff[0] = 8'd0;
        coeff[1] = 8'd0;
        coeff[2] = 8'd0;
        coeff[3] = 8'd0;

        run_test;


        // ------------------------------------------------
        // Test 5: Negative Values
        // ------------------------------------------------

        data_in[0] = -8'sd2;
        data_in[1] =  8'sd3;
        data_in[2] = -8'sd4;
        data_in[3] =  8'sd5;

        coeff[0] =  8'sd2;
        coeff[1] = -8'sd1;
        coeff[2] =  8'sd3;
        coeff[3] = -8'sd2;

        run_test;


        $display("----------------------------------------");
        $display("DIGITAL CONVOLUTION TEST COMPLETED");
        $display("----------------------------------------");

        $finish;

    end

endmodule