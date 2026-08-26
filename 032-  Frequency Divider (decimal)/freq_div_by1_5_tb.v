module freq_div_by1_5_tb;
reg clk, reset;
wire new_clk;

freq_div_by1_5 dut(clk, reset, new_clk);

initial begin
clk= 1'b0;
forever #10 clk= ~clk;
end
initial begin
reset= 1'b1;
#20
reset= 1'b0;
#200 $finish;
end
endmodule