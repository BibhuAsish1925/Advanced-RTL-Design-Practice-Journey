`timescale 1ns / 1ps

module hamming_encoder_tb;
    reg [3:0]data;
    wire [6:0] ham_data_encoder;
    integer i;
    integer errors;

    // Verified expected codeword for every possible 4-bit input
    reg [6:0] expected [0:15];

    hamming_encoder dut(data, ham_data_encoder);

    initial begin
        expected[0]  = 7'b0000000;
        expected[1]  = 7'b0000111;
        expected[2]  = 7'b0011001;
        expected[3]  = 7'b0011110;
        expected[4]  = 7'b0101010;
        expected[5]  = 7'b0101101;
        expected[6]  = 7'b0110011;
        expected[7]  = 7'b0110100;
        expected[8]  = 7'b1001011;
        expected[9]  = 7'b1001100;
        expected[10] = 7'b1010010;
        expected[11] = 7'b1010101;
        expected[12] = 7'b1100001;
        expected[13] = 7'b1100110;
        expected[14] = 7'b1111000;
        expected[15] = 7'b1111111;

        errors = 0;

        for (i = 0; i < 16; i = i + 1) begin
            data = i[3:0];
            #2;
            if (ham_data_encoder !== expected[i]) begin
                $display("FAIL: data=%b expected=%b got=%b", data, expected[i], ham_data_encoder);
                errors = errors + 1;
            end
            else begin
                $display("PASS: data=%b -> codeword=%b", data, ham_data_encoder);
            end
        end

        $display("----------------------------------------");
        if (errors == 0)
            $display("ALL 16 ENCODER TEST CASES PASSED");
        else
            $display("%0d ENCODER TEST CASE(S) FAILED", errors);
        $display("----------------------------------------");

        #10 $stop;
    end
endmodule