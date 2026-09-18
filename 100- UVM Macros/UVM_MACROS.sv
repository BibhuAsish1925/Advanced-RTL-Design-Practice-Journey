`include "uvm_macros.svh"
import uvm_pkg::*;

////////////////////////////////////////////////////////////
// UVM TEST
////////////////////////////////////////////////////////////

class my_test extends uvm_test;

  `uvm_component_utils(my_test)

  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    `uvm_info("TEST", "UVM_LOW message", UVM_LOW);
    `uvm_info("TEST", "UVM_MEDIUM message", UVM_MEDIUM);
    `uvm_info("TEST", "UVM_HIGH message", UVM_HIGH);
    `uvm_info("TEST", "UVM_FULL message", UVM_FULL);

    phase.drop_objection(this);

  endtask

endclass


////////////////////////////////////////////////////////////
// TOP MODULE
////////////////////////////////////////////////////////////

module uvm_reporting_tb;

  initial begin

    // Set global UVM verbosity
    uvm_top.set_report_verbosity_level(UVM_HIGH);

    run_test("my_test");

  end

endmodule