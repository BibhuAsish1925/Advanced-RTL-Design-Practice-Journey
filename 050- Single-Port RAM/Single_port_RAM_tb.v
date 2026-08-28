module Single_port_RAM_tb;
parameter addr_width = 7;
parameter data_width = 8;
parameter depth = 128;

reg [data_width-1:0] data;
reg [addr_width-1:0] address;
reg we, clk;
wire [data_width-1:0] q;

Single_port_RAM dut(data, address, we, clk, q);

initial begin
    clk=1'b1;
    forever #5 clk=~clk;
end

initial begin
    data= 8'hf0;
    address= 7'd0;      
    we= 1'b1;        //write data
    #10;
    
    data= 8'he1;
    address= 7'd1;      
    #10;
    
    data= 8'hd2;
    address= 7'd2;      
    #10;
    data= 8'hz; 
     //read operation
    address= 7'd0;      
    we= 1'b0;       
    #10;
    
    address= 7'd2;     
    #10;
    
    address= 7'd1;
    #10;
end

initial begin
$monitor("write enable: %b  address: %b  data: %b  output: %b", we, address, data, q);
#60 $finish;
end
endmodule