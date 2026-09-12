module fir_filter_tb;

    parameter int DATA_WIDTH   = 8;
    parameter int COEFF_WIDTH  = 8;
    parameter int TAPS         = 4;
    parameter int OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + $clog2(TAPS);

    logic clk;
    logic rst;
    logic en;

    logic signed [DATA_WIDTH-1:0] data_in;
    logic signed [COEFF_WIDTH-1:0] coeff [TAPS];
    logic signed [OUTPUT_WIDTH-1:0] data_out;

    // Reference delay line: holds the TAPS-1 most recent PREVIOUS
    // samples (does not include the current sample being applied)
    logic signed [DATA_WIDTH-1:0] reference_delay [TAPS-1];

    integer expected_result;
    integer i;
    integer j;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------
    fir_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .TAPS(TAPS),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .en       (en),
        .data_in  (data_in),
        .coeff    (coeff),
        .data_out (data_out)
    );

    // --------------------------------------------------
    // Clock
    // --------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------
    // Reference Model
    // coeff[0] pairs with the new sample; coeff[k] for k>=1
    // pairs with reference_delay[k-1] (the sample from k
    // cycles ago) -- matching the DUT's own convention.
    // --------------------------------------------------
    task automatic calculate_expected(
        input logic signed [DATA_WIDTH-1:0] new_sample
    );
        integer temp_sum;
        begin
            temp_sum = new_sample * coeff[0];
            for (j = 1; j < TAPS; j = j + 1)
                temp_sum = temp_sum + (reference_delay[j-1] * coeff[j]);
            expected_result = temp_sum;
        end
    endtask

    // --------------------------------------------------
    // Apply Sample
    // --------------------------------------------------
    task automatic apply_sample(
        input logic signed [DATA_WIDTH-1:0] sample
    );
        begin
            @(negedge clk);
            data_in = sample;
            calculate_expected(sample);

            @(posedge clk);
            #1;

            if (data_out !== expected_result) begin
                $error(
                    "FAIL: Input=%0d | Expected=%0d | Actual=%0d",
                    sample, expected_result, data_out
                );
            end
            else begin
                $display(
                    "PASS: Input=%0d | Expected=%0d | Output=%0d",
                    sample, expected_result, data_out
                );
            end

            // Update reference delay line (descending order so
            // blocking writes don't clobber values still needed
            // from lower indices this same pass)
            for (j = TAPS-2; j > 0; j = j - 1)
                reference_delay[j] = reference_delay[j-1];
            reference_delay[0] = sample;
        end
    endtask

    // --------------------------------------------------
    // Main Test
    // --------------------------------------------------
    initial begin
        rst = 1'b1;
        en  = 1'b0;
        data_in = '0;

        // h = [1, 2, 3, 4]
        coeff[0] = 8'sd1;
        coeff[1] = 8'sd2;
        coeff[2] = 8'sd3;
        coeff[3] = 8'sd4;

        for (i = 0; i < TAPS-1; i = i + 1)
            reference_delay[i] = '0;

        expected_result = 0;

        // Reset
        @(posedge clk);
        #1;
        rst = 1'b0;
        en  = 1'b1;

        // Ramping samples
        apply_sample(8'sd1);
        apply_sample(8'sd2);
        apply_sample(8'sd3);
        apply_sample(8'sd4);
        apply_sample(8'sd5);
        apply_sample(8'sd6);
        apply_sample(8'sd7);
        apply_sample(8'sd8);

        // Negative-value tests
        apply_sample(-8'sd1);
        apply_sample(-8'sd2);
        apply_sample(8'sd5);

        // Disable test
        @(negedge clk);
        data_in = 8'sd100;
        en = 1'b0;
        @(posedge clk);
        #1;
        if (data_out !== expected_result)
            $error("FAIL: Output changed while enable was LOW");
        else
            $display("PASS: Enable test | Output remained %0d", data_out);

        // Reset mid-stream and confirm clean recovery
        @(negedge clk);
        rst = 1'b1;
        @(posedge clk);
        #1;
        if (data_out !== 0)
            $error("FAIL: data_out not cleared after reset, got %0d", data_out);
        else
            $display("PASS: Reset test | data_out cleared to 0");
        rst = 1'b0;
        en  = 1'b1;
        for (i = 0; i < TAPS-1; i = i + 1)
            reference_delay[i] = '0;

        apply_sample(8'sd3);

        $display("----------------------------------------");
        $display("FIR FILTER TEST COMPLETED");
        $display("----------------------------------------");

        $finish;
    end

endmodule