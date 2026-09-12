module moving_average_filter_tb;
    parameter int DATA_WIDTH  = 8;
    parameter int WINDOW_SIZE = 4;
    parameter int SUM_WIDTH   = DATA_WIDTH + $clog2(WINDOW_SIZE);

    logic clk;
    logic rst;
    logic en;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;

    // Reference model state (independent full re-sum each cycle,
    // not mirroring the DUT's running-sum optimization)
    logic [DATA_WIDTH-1:0] reference_buffer [WINDOW_SIZE];
    integer reference_sum;
    integer expected_average;
    integer i;
    integer j;

    // DUT
    moving_average_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .WINDOW_SIZE(WINDOW_SIZE),
        .SUM_WIDTH(SUM_WIDTH)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .en       (en),
        .data_in  (data_in),
        .data_out (data_out)
    );

    // Clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------
    // Apply one input sample and check output
    // --------------------------------------------------
    task automatic apply_sample(
        input logic [DATA_WIDTH-1:0] sample
    );
        begin
            @(negedge clk);
            data_in = sample;

            // Shift into the reference model (descending order so
            // blocking assignment doesn't clobber values it still
            // needs to read from lower indices this same pass)
            for (j = WINDOW_SIZE-1; j > 0; j = j - 1)
                reference_buffer[j] = reference_buffer[j-1];
            reference_buffer[0] = sample;

            reference_sum = 0;
            for (j = 0; j < WINDOW_SIZE; j = j + 1)
                reference_sum = reference_sum + reference_buffer[j];

            expected_average = reference_sum / WINDOW_SIZE;

            @(posedge clk);
            #1; // let the DUT's non-blocking updates settle before sampling

            if (data_out !== expected_average) begin
                $error(
                    "FAIL: Input=%0d | Expected=%0d | Actual=%0d",
                    sample, expected_average, data_out
                );
            end
            else begin
                $display(
                    "PASS: Input=%0d | Average=%0d",
                    sample, data_out
                );
            end
        end
    endtask

    initial begin
        rst = 1'b1;
        en  = 1'b0;
        data_in = '0;
        reference_sum    = 0;
        expected_average = 0;
        for (i = 0; i < WINDOW_SIZE; i = i + 1)
            reference_buffer[i] = '0;

        // Reset
        @(posedge clk);
        #1;
        rst = 1'b0;
        en  = 1'b1;

        // ------------------------------------------------
        // Ramping input sequence
        // ------------------------------------------------
        apply_sample(8'd10);
        apply_sample(8'd20);
        apply_sample(8'd30);
        apply_sample(8'd40);
        apply_sample(8'd50);
        apply_sample(8'd60);
        apply_sample(8'd70);
        apply_sample(8'd80);

        // ------------------------------------------------
        // Constant input (average should converge to the
        // constant value once the window fully fills with it)
        // ------------------------------------------------
        apply_sample(8'd100);
        apply_sample(8'd100);
        apply_sample(8'd100);
        apply_sample(8'd100);

        // ------------------------------------------------
        // Disable filter: output must hold steady even though
        // a new input value is applied
        // ------------------------------------------------
        @(negedge clk);
        data_in = 8'd200;
        en      = 1'b0;
        @(posedge clk);
        #1;
        if (data_out !== expected_average)
            $error("FAIL: Output changed while enable was LOW");
        else
            $display("PASS: Enable test | Output remained %0d", data_out);

        // ------------------------------------------------
        // Re-enable and confirm it resumes correctly with
        // the previously-held window state (200 was never
        // actually shifted in since en was low)
        // ------------------------------------------------
        en = 1'b1;
        apply_sample(8'd90);

        // ------------------------------------------------
        // Reset mid-stream and confirm output/window clears
        // ------------------------------------------------
        @(negedge clk);
        rst = 1'b1;
        @(posedge clk);
        #1;
        if (data_out !== 0)
            $error("FAIL: data_out not cleared after reset, got %0d", data_out);
        else
            $display("PASS: Reset test | data_out cleared to 0");
        rst = 1'b0;
        for (i = 0; i < WINDOW_SIZE; i = i + 1)
            reference_buffer[i] = '0;
        reference_sum = 0;
        expected_average = 0;

        apply_sample(8'd5);

        $display("----------------------------------------");
        $display("MOVING AVERAGE FILTER TEST COMPLETED");
        $display("----------------------------------------");
        $finish;
    end
endmodule