class test;

 rand bit[3:0] var1;
 rand bit[3:0] var2;

// select either pre or post at a time and comment other 

/*function void pre_randomize();
 var1.rand_mode(0);
 var1=12; var2=14;
 $display("Inside pre randomize");
endfunction*/

function void post_randomize();
 var1=12; var2=10;
 $display("Inside post randomize"); 
endfunction

endclass

module tb1;
 test t;

 initial begin
  t=new();
  t.randomize();
   $display("var1=%0d var2=%0d", t.var1, t.var2);
 end
endmodule