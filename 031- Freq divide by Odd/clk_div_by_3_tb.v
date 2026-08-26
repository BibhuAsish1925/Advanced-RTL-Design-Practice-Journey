module clk_div_by_3_tb;

    reg clk;
    wire clk_out;

    clk_div_by_3 dut(
        .clk(clk),
        .clk_out(clk_out)
    );


	initial begin
		clk = 0;
	end
	
	always begin
		#20;
		clk = ~clk;
	end
      
endmodule