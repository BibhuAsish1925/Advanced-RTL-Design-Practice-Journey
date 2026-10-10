module fixed_array;
  int a[4];
  int b[4][2];    //int b[row][coloumn];

  initial begin
   a='{1,2,3,4};
    b='{'{1,0},'{2,0},'{3,0},'{4,0}};

  for(int i=0; i<4; i++)begin
    $display("a[%0d]=%0d", i, a[i]);
  end

  for(int i=0; i<4; i++)begin
    for(int j=0; j<2; j++)begin
   $display("b[%0d][%0d]=%0d",i,j, b[i][j]);
   end
  end  
  end

endmodule