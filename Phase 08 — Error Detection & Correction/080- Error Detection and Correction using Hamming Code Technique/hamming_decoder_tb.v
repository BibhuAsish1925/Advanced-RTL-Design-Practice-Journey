module hamming_decoder_tb;
    reg [6:0] ham_data_encoder;
    wire [2:0]error_position;
    wire is_error; 
    wire [3:0]data;
    integer errors;

    hamming_decoder dut(ham_data_encoder,data,error_position,is_error);

    task automatic check_case(
        input [6:0] codeword,
        input       expect_error,
        input [2:0] expect_pos,
        input [3:0] expect_data,
        input [127:0] label
    );
        begin
            ham_data_encoder = codeword;
            #2;
            if (is_error !== expect_error || data !== expect_data ||
                (expect_error && error_position !== expect_pos)) begin
                $display("FAIL [%0s]: codeword=%b is_error=%b pos=%0d data=%b (expected is_error=%b pos=%0d data=%b)",
                          label, codeword, is_error, error_position, data,
                          expect_error, expect_pos, expect_data);
                errors = errors + 1;
            end
            else begin
                $display("PASS [%0s]: codeword=%b -> is_error=%b pos=%0d data=%b",
                          label, codeword, is_error, error_position, data);
            end
        end
    endtask

    initial begin
        errors = 0;

        // Base valid codeword for data=0110, plus a single-bit error
        // injected at EVERY one of the 7 possible bit positions,
        // confirming both detection (error_position) and correction
        // (data still recovers to the original 0110) at every position.
        check_case(7'b0110011, 1'b0, 3'd0, 4'b0110, "no_error");
        check_case(7'b0110010, 1'b1, 3'd1, 4'b0110, "error_pos1");
        check_case(7'b0110001, 1'b1, 3'd2, 4'b0110, "error_pos2");
        check_case(7'b0110111, 1'b1, 3'd3, 4'b0110, "error_pos3");
        check_case(7'b0111011, 1'b1, 3'd4, 4'b0110, "error_pos4");
        check_case(7'b0100011, 1'b1, 3'd5, 4'b0110, "error_pos5");
        check_case(7'b0010011, 1'b1, 3'd6, 4'b0110, "error_pos6");
        check_case(7'b1110011, 1'b1, 3'd7, 4'b0110, "error_pos7");

        $display("----------------------------------------");
        if (errors == 0)
            $display("ALL 8 DECODER TEST CASES PASSED");
        else
            $display("%0d DECODER TEST CASE(S) FAILED", errors);
        $display("----------------------------------------");

        #10 $finish;
    end
endmodule