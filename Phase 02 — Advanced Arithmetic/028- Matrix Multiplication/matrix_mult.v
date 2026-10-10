module matrix_mult #(
  parameter N = 3,
  parameter W = 8
)(
  input      [N*N*W-1:0]   A_flat,
  input      [N*N*W-1:0]   B_flat,
  output reg [N*N*2*W-1:0] C_flat
);
  integer i, j, k;
  reg [2*W-1:0] sum;

  always @(*) begin
    for (i = 0; i < N; i = i + 1)
      for (j = 0; j < N; j = j + 1) begin
        sum = 0;
        for (k = 0; k < N; k = k + 1)
          sum = sum + A_flat[(i*N+k)*W +: W] * B_flat[(k*N+j)*W +: W];
        C_flat[(i*N+j)*2*W +: 2*W] = sum;
      end
  end
endmodule