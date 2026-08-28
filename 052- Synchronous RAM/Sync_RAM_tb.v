module Sync_RAM_tb;
    reg clk, rst, cs, oe, we;
    reg [7:0] address, data_in;
    wire [7:0] data_out;

    Sync_RAM uut(
        .clk     (clk),
        .rst_n   (rst),
        .cs      (cs),
        .oe      (oe),
        .we      (we),
        .address (address),
        .data_in (data_in),
        .data_out(data_out)
        );

    initial 
    begin
	        clk=0;
	        rst=0;
	        cs=1;
	        oe=0;
	        we=0;
	        address=0;
	        data_in=0;
	    #10 rst=1;
	        we=1;

	        repeat (10) 
		        begin
		    		#10 address=address+1;
		                data_in=address;
		        end

	    #10 we=0;
	        oe=1;
	        address=0;

	        repeat (10) 
		        begin
		            #10 address=address+1;
		        end
    end

    	initial repeat(500) #5 clk=~clk;

    	initial begin
    	    $monitor("t=%0t\t rst_n=%b cs=%b oe=%b we=%b address=%0d data_in=%0d data_out=%0d",
    	              $time, rst, cs, oe, we, address, data_in, data_out);
    	    #250 $finish;
    	end

endmodule