module factorial_tb;
reg [3:0] n;
wire [31:0] result;
integer x;
factorial dut(n, result);

initial for(x=0; x<11; x=x+1) #10 n=x;

initial begin 
$monitor("\t\t factorial of %d is %0d", n, result);
#120 $finish;
end
endmodule