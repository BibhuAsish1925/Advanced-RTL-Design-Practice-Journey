`timescale 1ns / 1ps

module xtime_basic_tb;

  reg  [7:0] a;
  wire [7:0] result;

  xtime_basic dut (
    .a(a),
    .result(result)
  );

  task check(input [7:0] in_val, input [7:0] expected, input [127:0] label);
    begin
      a = in_val;
      #1;
      if (result !== expected)
        $display("FAIL [%0s]: xtime(%h) = %h, expected %h", label, in_val, result, expected);
      else
        $display("PASS [%0s]: xtime(%h) = %h", label, in_val, result);
    end
  endtask

  initial begin
    $monitor("t=%0t\t a=%h result=%h", $time, a, result);

    // FIPS-197 (AES spec) section 4.2.1 worked example
    check(8'h57, 8'hAE, "spec example 1: xtime(57)=AE");
    check(8'hAE, 8'h47, "spec example 2: xtime(AE)=47");

    // Edge cases, cross-checked against an independent GF(2^8) multiplier
    check(8'h00, 8'h00, "zero input");
    check(8'h01, 8'h02, "no MSB, simple shift");
    check(8'h80, 8'h1B, "MSB set, pure reduction (shift gives 0)");
    check(8'hFF, 8'hE5, "all ones");

    #10;
    $finish;
  end

endmodule