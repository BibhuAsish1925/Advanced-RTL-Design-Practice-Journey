module carry_look_ahead_gen_tb;

    reg  [3:0] a;
    reg  [3:0] b;
    reg        cin;

    wire [3:0] sum;
    wire       carry;

    reg  [4:0] expected;

    // DUT
    carry_look_ahead_gen dut (
        .a    (a),
        .b    (b),
        .cin  (cin),
        .sum  (sum),
        .carry(carry)
    );

    initial begin

        // Test 1
        a = 4'b1000;
        b = 4'b0011;
        cin = 1'b0;
        #10;
        check_result;

        // Test 2
        a = 4'b0001;
        b = 4'b1010;
        cin = 1'b1;
        #10;
        check_result;

        // Test 3
        a = 4'b0110;
        b = 4'b0110;
        cin = 1'b0;
        #10;
        check_result;

        // Test 4
        a = 4'b0111;
        b = 4'b1110;
        cin = 1'b0;
        #10;
        check_result;

        // Test 5
        a = 4'b1001;
        b = 4'b0110;
        cin = 1'b1;
        #10;
        check_result;

        // Test 6
        a = 4'b1001;
        b = 4'b0100;
        cin = 1'b0;
        #10;
        check_result;

        // Test 7
        a = 4'b1111;
        b = 4'b1110;
        cin = 1'b1;
        #10;
        check_result;

        $finish;
    end

    // Task to verify DUT output
    task check_result;
        begin
            expected = a + b + cin;

            if ({carry, sum} == expected)
                $display("PASS: a=%b b=%b cin=%b | sum=%b carry=%b",
                         a, b, cin, sum, carry);
            else
                $display("FAIL: a=%b b=%b cin=%b | Expected=%b | Got=%b",
                         a, b, cin, expected, {carry, sum});
        end
    endtask

endmodule