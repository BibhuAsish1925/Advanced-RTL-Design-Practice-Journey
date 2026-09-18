`include "uvm_macros.svh"
import uvm_pkg::*;

class first extends uvm_object;
	rand bit[3:0] data;

	function new(string path = "first");
		super.new(path);
	endfunction

	`uvm_object_utils_begin(first)
	`uvm_field_int(data, UVM_DEFAULT);
	`uvm_object_utils_end
endclass

module tb4;

	initial begin
	first f1, s1;
	f1 = new("first");
	s1 = new("second");
	f1.randomize();
	s1.copy(f1);
	f1.print();
	s1.print();
	end

	initial begin 
	first f2, s2;
	f2 = new("first");
	f2.randomize();
	$cast(s2, f2.clone());
	f2.print();
	s2.print();
	end
endmodule