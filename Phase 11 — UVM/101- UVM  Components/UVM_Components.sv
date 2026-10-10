`include "uvm_macros.svh"
import uvm_pkg::*;

////////////////////////////////////////////////////////////
// DRIVER
////////////////////////////////////////////////////////////

class my_driver extends uvm_driver #(uvm_sequence_item);

  `uvm_component_utils(my_driver)

  function new(string name = "my_driver",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info("DRIVER",
              "Driver build_phase executed",
              UVM_MEDIUM);
  endfunction

  task run_phase(uvm_phase phase);

    `uvm_info("DRIVER",
              "Driver run_phase started",
              UVM_MEDIUM);

    forever begin
      #10;

      `uvm_info("DRIVER",
                "Driver is running",
                UVM_HIGH);
    end

  endtask

endclass


////////////////////////////////////////////////////////////
// MONITOR
////////////////////////////////////////////////////////////

class my_monitor extends uvm_monitor;

  `uvm_component_utils(my_monitor)

  function new(string name = "my_monitor",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info("MONITOR",
              "Monitor build_phase executed",
              UVM_MEDIUM);
  endfunction

  task run_phase(uvm_phase phase);

    `uvm_info("MONITOR",
              "Monitor run_phase started",
              UVM_MEDIUM);

    forever begin
      #10;

      `uvm_info("MONITOR",
                "Monitor is running",
                UVM_HIGH);
    end

  endtask

endclass


////////////////////////////////////////////////////////////
// ENVIRONMENT
////////////////////////////////////////////////////////////

class my_env extends uvm_env;

  `uvm_component_utils(my_env)

  my_driver  drv_h;
  my_monitor mon_h;

  function new(string name = "my_env",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    `uvm_info("ENV",
              "Creating driver and monitor",
              UVM_MEDIUM);

    drv_h = my_driver::type_id::create("drv_h", this);
    mon_h = my_monitor::type_id::create("mon_h", this);

  endfunction


  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    `uvm_info("ENV",
              "connect_phase executed",
              UVM_MEDIUM);

  endfunction

endclass


////////////////////////////////////////////////////////////
// TEST
////////////////////////////////////////////////////////////

class my_test extends uvm_test;

  `uvm_component_utils(my_test)

  my_env env_h;

  function new(string name = "my_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    env_h = my_env::type_id::create("env_h", this);

  endfunction


  task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    `uvm_info("TEST",
              "UVM test started",
              UVM_LOW);

    #100;

    `uvm_info("TEST",
              "UVM test completed",
              UVM_LOW);

    phase.drop_objection(this);

  endtask

endclass


////////////////////////////////////////////////////////////
// TOP MODULE
////////////////////////////////////////////////////////////

module uvm_components_tb;

  initial begin

    // Set verbosity level
    uvm_top.set_report_verbosity_level(UVM_HIGH);

    run_test("my_test");

  end

endmodule