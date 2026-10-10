class parent;

  virtual function void print();
    $display("We are inside the parent class");
  endfunction

endclass


class child extends parent;

  function void print();
    $display("We are inside the child class");
  endfunction

endclass


module tb8;

  parent p;
  child  c;

  initial begin

    // Create parent and child objects
    p = new();
    c = new();

    // Parent handle points to child object
    p = c;

    // Runtime polymorphism:
    // Child's print() is called
    p.print();

    // Direct child handle also calls child's print()
    c.print();

    // The following is illegal:
    // c = p;
    // A parent handle cannot directly be assigned to a child handle.

  end

endmodule