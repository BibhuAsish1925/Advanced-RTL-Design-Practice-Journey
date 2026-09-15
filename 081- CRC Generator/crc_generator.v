module crc_generator #(
  parameter WIDTH      = 32,
  parameter [WIDTH-1:0] POLY      = 32'hEDB88320, // reflected polynomial
  parameter [WIDTH-1:0] INIT_VAL  = {WIDTH{1'b1}},
  parameter [WIDTH-1:0] XOR_OUT   = {WIDTH{1'b1}}  // final XOR mask (0 for none)
)(
  input  wire clk, input wire rst_n,
  input  wire valid_i,
  input  wire [7:0] data_i,  // byte stream
  input  wire last_i,        // pulse with last byte
  output reg  valid_o,
  output reg  [WIDTH-1:0] crc_o
);
  reg [WIDTH-1:0] crc;
  reg [WIDTH-1:0] c;
  reg [7:0] d;
  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin crc<=INIT_VAL; valid_o<=1'b0; crc_o<={WIDTH{1'b0}}; end
    else begin
      valid_o <= 1'b0;
      if (valid_i) begin
        c = crc; d = data_i;
        for (i=0;i<8;i=i+1) begin
          if ((c[0] ^ d[0])==1'b1) c = (c >> 1) ^ POLY;
          else                     c = (c >> 1);
          d = d >> 1;
        end
        crc <= c;
        if (last_i) begin
          crc_o   <= c ^ XOR_OUT; // final XOR
          valid_o <= 1'b1;
          crc     <= INIT_VAL;    // auto-reseed
        end
      end
    end
  end
endmodule