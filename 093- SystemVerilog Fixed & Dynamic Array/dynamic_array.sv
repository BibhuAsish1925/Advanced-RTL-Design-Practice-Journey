module dynamic_array;
  int a[];
  initial begin
   $display("size of array is %d", a.size());
   a = new[4];
   $display("size of array is %d", a.size());
   a = {1,2,3,4};
     for(int i=0; i<4; i++)begin
     $display("a[%0d]=%0d", i, a[i]);
    end

      a = new[6](a);  //for retaining the previous array values put a in brackets beside the array
    $display("size of array is %d", a.size());
    //a = {9,8,7,6,5,4,3,2,1,11};
      for(int i=0; i<6; i++)begin
    $display("a[%0d]=%0d", i, a[i]);
    end
    a.delete();
      $display("size of array is %0d", a.size());
    end
endmodule