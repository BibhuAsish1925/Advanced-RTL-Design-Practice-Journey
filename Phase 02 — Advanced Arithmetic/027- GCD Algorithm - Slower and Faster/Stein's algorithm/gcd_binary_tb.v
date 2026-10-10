module gcd_binary_tb;
    parameter WIDTH = 32;
    reg clk;
    reg rst_n;
    reg start;
    reg [WIDTH-1:0] A, B;
    wire busy;
    wire done;
    wire [WIDTH-1:0] gcd;

    gcd_binary #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .A(A),
        .B(B),
        .busy(busy),
        .done(done),
        .gcd(gcd)
    );

    always #5 clk = ~clk;

    task run_test(input [WIDTH-1:0] a_val, input [WIDTH-1:0] b_val, input [WIDTH-1:0] expected);
        begin
            @(negedge clk);
            A = a_val;
            B = b_val;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait (done);
            if (gcd === expected)
                $display("PASS: gcd(%0d,%0d) = %0d", a_val, b_val, gcd);
            else
                $display("FAIL: gcd(%0d,%0d) = %0d (expected %0d)", a_val, b_val, gcd, expected);
            @(negedge clk);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        A = 0;
        B = 0;
        #12 rst_n = 1;

        run_test(48, 18, 6);
        run_test(0, 5, 5);
        run_test(7, 0, 7);
        run_test(1, 1, 1);
        run_test(17, 13, 1);
        run_test(1000, 500, 500);
        run_test(0, 0, 0);

        #20 $finish;
    end
endmodule