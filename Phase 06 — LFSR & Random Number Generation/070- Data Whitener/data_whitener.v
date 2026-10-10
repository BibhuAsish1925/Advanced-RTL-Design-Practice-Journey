module data_whitener #(
  parameter integer W=32, LFSR_W=16
)(
  input wire clk, rst_n,
  input wire valid_i,
  input wire [W-1:0] d_i,
  output reg valid_o,
  output reg [W-1:0] d_o
);
  reg [LFSR_W-1:0] lfsr;

  // NOTE: these taps are specifically chosen (and verified) for LFSR_W=16.
  // They are NOT automatically valid for any other LFSR_W value.
  wire fb = lfsr[LFSR_W-1] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

  initial begin
    if (LFSR_W != 16)
      $display("WARNING: data_whitener taps are only verified for LFSR_W=16, got LFSR_W=%0d", LFSR_W);
  end

  // Intermediate wire so the replicated PN pattern can be safely
  // truncated with a normal part-select (indexing a replication
  // expression directly is not legal in strict Verilog-2001).
  wire [(((W/LFSR_W)+1)*LFSR_W)-1:0] lfsr_rep = {(W/LFSR_W)+1{lfsr}};

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lfsr <= {LFSR_W{1'b1}};
      valid_o <= 1'b0;
      d_o <= {W{1'b0}};
    end else begin
      valid_o <= valid_i;
      if (valid_i) begin
        d_o <= d_i ^ lfsr_rep[W-1:0]; // whiten with replicated PN bits, not a single bit
        lfsr <= {lfsr[LFSR_W-2:0], fb};
      end
    end
  end
endmodule