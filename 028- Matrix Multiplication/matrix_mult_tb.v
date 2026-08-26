`timescale 1ns/1ps
module matrix_mult_tb;
  parameter N = 3;
  parameter W = 8;
  reg  [N*N*W-1:0]   A_flat;
  reg  [N*N*W-1:0]   B_flat;
  wire [N*N*2*W-1:0] C_flat;
  integer i, j;

  matrix_mult #(.N(N), .W(W)) dut (
    .A_flat(A_flat),
    .B_flat(B_flat),
    .C_flat(C_flat)
  );

  initial begin
    // A = [[1,2,3],[4,5,6],[7,8,9]]
    A_flat[(0*N+0)*W +: W] = 1; A_flat[(0*N+1)*W +: W] = 2; A_flat[(0*N+2)*W +: W] = 3;
    A_flat[(1*N+0)*W +: W] = 4; A_flat[(1*N+1)*W +: W] = 5; A_flat[(1*N+2)*W +: W] = 6;
    A_flat[(2*N+0)*W +: W] = 7; A_flat[(2*N+1)*W +: W] = 8; A_flat[(2*N+2)*W +: W] = 9;

    // B = [[9,8,7],[6,5,4],[3,2,1]]
    B_flat[(0*N+0)*W +: W] = 9; B_flat[(0*N+1)*W +: W] = 8; B_flat[(0*N+2)*W +: W] = 7;
    B_flat[(1*N+0)*W +: W] = 6; B_flat[(1*N+1)*W +: W] = 5; B_flat[(1*N+2)*W +: W] = 4;
    B_flat[(2*N+0)*W +: W] = 3; B_flat[(2*N+1)*W +: W] = 2; B_flat[(2*N+2)*W +: W] = 1;

    #10;
    
    $display("Matrix A:");
    for (i = 0; i < N; i = i + 1) begin
      for (j = 0; j < N; j = j + 1)
        $write("%0d ", A_flat[(i*N+j)*W +: W]);
      $display("");
    end

    $display("Matrix B:");
    for (i = 0; i < N; i = i + 1) begin
      for (j = 0; j < N; j = j + 1)
        $write("%0d ", B_flat[(i*N+j)*W +: W]);
      $display("");
    end

    $display("Result matrix C:");
    for (i = 0; i < N; i = i + 1) begin
      for (j = 0; j < N; j = j + 1)
        $write("%0d ", C_flat[(i*N+j)*2*W +: 2*W]);
      $display("");
    end

    if (C_flat[(0*N+0)*2*W +: 2*W]===30 && C_flat[(0*N+1)*2*W +: 2*W]===24 && C_flat[(0*N+2)*2*W +: 2*W]===18 &&
        C_flat[(1*N+0)*2*W +: 2*W]===84 && C_flat[(1*N+1)*2*W +: 2*W]===69 && C_flat[(1*N+2)*2*W +: 2*W]===54 &&
        C_flat[(2*N+0)*2*W +: 2*W]===138 && C_flat[(2*N+1)*2*W +: 2*W]===114 && C_flat[(2*N+2)*2*W +: 2*W]===90)
      $display("PASS: matrix multiplication correct");
    else
      $display("FAIL: matrix multiplication incorrect");

    $finish;
  end
endmodule