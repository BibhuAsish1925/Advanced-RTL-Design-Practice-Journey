module prng_tb;

// Inputs
reg clk;
reg rst_n;

// Outputs
wire [7:0] prbs;

// Instantiate DUT
prng dut (
    .clk(clk),
    .rst_n(rst_n),
    .prbs(prbs)
);

// Reset
initial begin
    $monitor("t=%0t\t rst_n=%b prbs=%b", $time, rst_n, prbs);
    clk = 1'b0;
    rst_n = 1'b0;
    #10;
    rst_n = 1'b1;
    #300;
    $finish;
end

// Clock generator
always #5 clk = ~clk;

endmodule