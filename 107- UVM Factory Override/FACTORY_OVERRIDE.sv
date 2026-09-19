// Code your testbench here
// or browse Examples

`include "uvm_macros.svh"
import uvm_pkg::*;
 
 
class first_fo extends uvm_object; 
  
  rand bit [3:0] data;
  
  function new(string path = "first_fo");
    super.new(path);
  endfunction 
  
  `uvm_object_utils_begin(first_fo)
  `uvm_field_int(data, UVM_DEFAULT);
  `uvm_object_utils_end
  
endclass
/////////////////////////////////////
class first_mod_fo extends first_fo;
  rand bit ack;
  
  function new(string path = "first_mod_fo");
    super.new(path);
  endfunction 
  
  `uvm_object_utils_begin(first_mod_fo)
  `uvm_field_int(ack, UVM_DEFAULT);
  `uvm_object_utils_end
  
  
endclass
 
 
 
////////////////////////////////////////////
 
class comp_fo extends uvm_component;
  `uvm_component_utils(comp_fo)
  
  first_fo f;
  
  function new(string path = "second", uvm_component parent = null);
    super.new(path, parent);
    f = first_fo::type_id::create("f");
    f.randomize();
    f.print();
  endfunction 
  
  
endclass
 
 
/////////////////////////////////////////////
 
module tb6;
 
  comp_fo c;
  
  initial begin
    uvm_factory::get().set_type_override_by_type(first_fo::get_type(), first_mod_fo::get_type());
    c = comp_fo::type_id::create("comp", null); 
  end
 
endmodule