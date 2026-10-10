module data_whitener_tb;
  localparam W = 32;
  localparam LFSR_W = 16;
  reg clk, rst_n, valid_i;
  reg [W-1:0] d_i;
  wire valid_o;
  wire [W-1:0] d_o;
  data_whitener #(.W(W), .LFSR_W(LFSR_W)) dut (
    .clk(clk), .rst_n(rst_n),
    .valid_i(valid_i), .d_i(d_i),
    .valid_o(valid_o), .d_o(d_o)
  );
  initial clk = 1'b0;
  always #5 clk = ~clk;
  integer i;
  initial begin
    $monitor("t=%0t\t valid_i=%b d_i=%h valid_o=%b d_o=%h", $time, valid_i, d_i, valid_o, d_o);
    rst_n = 0; valid_i = 0; d_i = 0;
    #12; rst_n = 1;
    // Whiten the SAME repeating word several times in a row.
    // With the old bug (XOR with a single replicated bit), every
    // output would just be d_i or ~d_i -- still a highly repetitive,
    // structured pattern. With the fix, each output should differ
    // in a genuinely bit-varied way as the LFSR advances.
    valid_i = 1;
    for (i = 0; i < 8; i = i + 1) begin
      d_i = 32'hAAAAAAAA; // repeating pattern, worst case for whitening
      @(posedge clk);
    end
    valid_i = 0;
    #20;
    $finish;
  end
endmodule