module tpu_accelerator_tb;
    parameter int DATA_WIDTH  = 8;
    parameter int MATRIX_SIZE = 2;
    parameter int ACC_WIDTH   = 2 * DATA_WIDTH + $clog2(MATRIX_SIZE);

    logic clk;
    logic rst;
    logic start;

    logic signed [DATA_WIDTH-1:0] matrix_a [MATRIX_SIZE][MATRIX_SIZE];
    logic signed [DATA_WIDTH-1:0] matrix_b [MATRIX_SIZE][MATRIX_SIZE];
    logic signed [ACC_WIDTH-1:0]  matrix_c [MATRIX_SIZE][MATRIX_SIZE];

    logic busy;
    logic done;

    integer expected [MATRIX_SIZE][MATRIX_SIZE];

    integer i, j, k;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    tpu_accelerator #(
        .DATA_WIDTH(DATA_WIDTH),
        .MATRIX_SIZE(MATRIX_SIZE),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .matrix_a (matrix_a),
        .matrix_b (matrix_b),
        .matrix_c (matrix_c),
        .busy     (busy),
        .done     (done)
    );

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------
    // Reference model: compute expected = A x B
    // -------------------------------------------------
    task automatic compute_expected;
        begin
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    expected[i][j] = 0;
                    for (k = 0; k < MATRIX_SIZE; k = k + 1)
                        expected[i][j] = expected[i][j] +
                            (matrix_a[i][k] * matrix_b[k][j]);
                end
            end
        end
    endtask

    // -------------------------------------------------
    // Run one full multiply and check the result, including
    // busy/done timing behavior
    // -------------------------------------------------
    task automatic run_multiply(input string label);
        begin
            compute_expected;

            // busy must be low and done must not already be
            // asserted before we start
            if (busy !== 1'b0)
                $error("FAIL [%s]: busy was already high before start", label);

            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            // busy should assert shortly after start and stay
            // high throughout the computation
            if (busy !== 1'b1)
                $error("FAIL [%s]: busy did not assert after start", label);

            wait (done);
            #1;

            if (busy !== 1'b0)
                $error("FAIL [%s]: busy still high when done asserted", label);

            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    if (matrix_c[i][j] !== expected[i][j]) begin
                        $error(
                            "FAIL [%s]: C[%0d][%0d] Expected=%0d Actual=%0d",
                            label, i, j, expected[i][j], matrix_c[i][j]
                        );
                    end
                    else begin
                        $display(
                            "PASS [%s]: C[%0d][%0d] = %0d",
                            label, i, j, matrix_c[i][j]
                        );
                    end
                end
            end

            // done should only pulse for one cycle
            @(posedge clk);
            #1;
            if (done !== 1'b0)
                $error("FAIL [%s]: done did not deassert after one cycle", label);
        end
    endtask

    // -------------------------------------------------
    // Main Test
    // -------------------------------------------------
    initial begin
        rst   = 1'b1;
        start = 1'b0;

        repeat (2) @(posedge clk);
        rst = 1'b0;

        // ---------------------------------------------
        // Test 1: A=[[1,2],[3,4]], B=[[5,6],[7,8]]
        // Expected C=[[19,22],[43,50]]
        // ---------------------------------------------
        matrix_a[0][0]=1;  matrix_a[0][1]=2;
        matrix_a[1][0]=3;  matrix_a[1][1]=4;
        matrix_b[0][0]=5;  matrix_b[0][1]=6;
        matrix_b[1][0]=7;  matrix_b[1][1]=8;
        run_multiply("Test1");

        // ---------------------------------------------
        // Test 2: identity matrix -- result should equal A
        // ---------------------------------------------
        matrix_a[0][0]=9;  matrix_a[0][1]=-3;
        matrix_a[1][0]=4;  matrix_a[1][1]=7;
        matrix_b[0][0]=1;  matrix_b[0][1]=0;
        matrix_b[1][0]=0;  matrix_b[1][1]=1;
        run_multiply("Test2-Identity");

        // ---------------------------------------------
        // Test 3: negative values
        // ---------------------------------------------
        matrix_a[0][0]=-2; matrix_a[0][1]=5;
        matrix_a[1][0]=3;  matrix_a[1][1]=-4;
        matrix_b[0][0]=-1; matrix_b[0][1]=2;
        matrix_b[1][0]=6;  matrix_b[1][1]=-3;
        run_multiply("Test3-Negative");

        // ---------------------------------------------
        // Test 4: zero matrix
        // ---------------------------------------------
        matrix_a[0][0]=0;  matrix_a[0][1]=0;
        matrix_a[1][0]=0;  matrix_a[1][1]=0;
        matrix_b[0][0]=5;  matrix_b[0][1]=9;
        matrix_b[1][0]=2;  matrix_b[1][1]=1;
        run_multiply("Test4-Zero");

        // ---------------------------------------------
        // Test 5: reset mid-operation, confirm clean recovery
        // ---------------------------------------------
        matrix_a[0][0]=1;  matrix_a[0][1]=1;
        matrix_a[1][0]=1;  matrix_a[1][1]=1;
        matrix_b[0][0]=2;  matrix_b[0][1]=2;
        matrix_b[1][0]=2;  matrix_b[1][1]=2;

        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        @(posedge clk); // let it get partway into COMPUTE
        rst = 1'b1;
        @(posedge clk);
        #1;
        if (busy !== 1'b0 || done !== 1'b0)
            $error("FAIL: busy/done not cleared after mid-op reset");
        else
            $display("PASS: Mid-operation reset correctly cleared busy/done");
        rst = 1'b0;

        // Re-run the same matrices after reset to confirm the
        // accelerator recovers and produces a correct result
        run_multiply("Test6-AfterReset");

        $display("--------------------------------------");
        $display("TPU ACCELERATOR TEST COMPLETED");
        $display("--------------------------------------");
        $finish;
    end

endmodule