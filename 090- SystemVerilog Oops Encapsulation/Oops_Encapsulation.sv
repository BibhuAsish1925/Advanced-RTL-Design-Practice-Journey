class parent;
 bit [3:0] a=2; //by default it is public
 bit [3:0] b=3;

// local bit [3:0] a=2;
// local bit [3:0] b=3;

//   protected bit [3:0] a=2;
//   protected bit [3:0] b=3;


 function void print();
  $display("a=%d b=%d", a,b);
 endfunction
endclass

class child extends parent;

  bit [3:0] c;

  function void add();
    c = a + b;       // Allowed: protected members inherited by child
    $display("c=%0d", c);
  endfunction

  // Access protected members through a public method
  function bit [3:0] get_a();
    return a;
  endfunction

  function bit [3:0] get_b();
    return b;
  endfunction

endclass


module tb7;

  child c;
  bit [3:0] d;

  initial begin
    c = new();

    c.print();
    c.add();

    // Cannot directly access c.a or c.b from here.
    // Use public methods instead.
    d = c.get_a() + c.get_b();

    $display("d=%0d", d);
  end

endmodule