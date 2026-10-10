class parent;
 bit [3:0] length;
 bit [4:0] breadth;
 bit [31:0] peri;

 function void Peri();
  peri = 2*(length+breadth);
   $display("perimeter=%0d",peri);
 endfunction

endclass

class child extends parent;
 bit [31:0]area;
 
 function void rectangle();
  area = length*breadth;
   $display("area=%0d", area);
  super.Peri();
 endfunction

endclass

module tb6;
  child c;

  initial begin
   c = new();
   c.length=10;
   c.breadth=20;
   c.rectangle();
  end
endmodule