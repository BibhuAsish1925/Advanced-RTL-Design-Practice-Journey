module Single_port_RAM
    #(parameter addr_width = 7,
      parameter data_width = 8,
      parameter depth = 128)
     
     (input [data_width-1:0] data,  
      input [addr_width-1:0] address,  
      input we,clk,                 
      output [data_width-1:0] q);

reg [data_width-1:0] ram [depth-1:0];

reg [addr_width-1:0] addr_reg;

always @(posedge clk)
    begin
        if(we)
           ram[address] <=data; 
        else
           addr_reg <=address;
    end
    
assign q= ram[addr_reg];

endmodule