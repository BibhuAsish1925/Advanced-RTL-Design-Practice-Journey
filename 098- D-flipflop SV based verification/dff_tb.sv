//============================================================
// DFF CLASS-BASED SYSTEMVERILOG TESTBENCH
//============================================================


//============================================================
// Transaction
//============================================================

class transaction;

  rand bit din;
  bit dout;

  function transaction copy();
    copy = new();
    copy.din  = this.din;
    copy.dout = this.dout;
  endfunction

  function void display(input string tag);
    $display("[%0s] : DIN = %0b | DOUT = %0b",
             tag, din, dout);
  endfunction

endclass


//============================================================
// Generator
//============================================================

class generator;

  transaction tr;

  mailbox #(transaction) mbx;
  mailbox #(transaction) mbxref;

  event sconext;
  event done;

  int count;

  function new(
    mailbox #(transaction) mbx,
    mailbox #(transaction) mbxref
  );

    this.mbx    = mbx;
    this.mbxref = mbxref;

    tr = new();

  endfunction


  task run();

    repeat(count) begin

      assert(tr.randomize())
        else $error("[GEN] : RANDOMIZATION FAILED");

      // Send transaction to driver
      mbx.put(tr.copy());

      // Send expected transaction to scoreboard
      mbxref.put(tr.copy());

      tr.display("GEN");

      // Wait for scoreboard
      @(sconext);

    end

    ->done;

  endtask

endclass


//============================================================
// Driver
//============================================================

class driver;

  transaction tr;

  mailbox #(transaction) mbx;

  virtual dff_if vif;


  function new(mailbox #(transaction) mbx);

    this.mbx = mbx;

  endfunction


  //==========================================================
  // Reset
  //==========================================================

  task reset();

    vif.rst <= 1'b1;
    vif.din <= 1'b0;

    repeat(2)
      @(posedge vif.clk);

    vif.rst <= 1'b0;

    @(posedge vif.clk);

    $display("[DRV] : RESET DONE");

  endtask


  //==========================================================
  // Drive input
  //==========================================================

  task run();

    forever begin

      mbx.get(tr);

      // Drive data before the next rising edge
      @(negedge vif.clk);

      vif.din <= tr.din;

      tr.display("DRV");

    end

  endtask

endclass


//============================================================
// Monitor
//============================================================

class monitor;

  transaction tr;

  mailbox #(transaction) mbx;

  virtual dff_if vif;


  function new(mailbox #(transaction) mbx);

    this.mbx = mbx;

  endfunction


  task run();

    forever begin

      // Wait for DFF clock edge
      @(posedge vif.clk);

      // Allow non-blocking assignment in DUT to update
      #1;

      tr = new();

      tr.dout = vif.dout;

      mbx.put(tr);

      tr.display("MON");

    end

  endtask

endclass


//============================================================
// Scoreboard
//============================================================

class scoreboard;

  transaction tr;
  transaction trref;

  mailbox #(transaction) mbx;
  mailbox #(transaction) mbxref;

  event sconext;


  function new(
    mailbox #(transaction) mbx,
    mailbox #(transaction) mbxref
  );

    this.mbx    = mbx;
    this.mbxref = mbxref;

  endfunction


  task run();

    forever begin

      // Get actual output
      mbx.get(tr);

      // Get expected input
      mbxref.get(trref);

      tr.display("SCO");
      trref.display("REF");


      if (tr.dout == trref.din) begin

        $display("[SCO] : DATA MATCHED");

      end
      else begin

        $display("[SCO] : DATA MISMATCHED");

      end


      // Tell generator to continue
      ->sconext;

    end

  endtask

endclass


//============================================================
// Environment
//============================================================

class environment;

  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  sco;


  // Generator -> Driver
  mailbox #(transaction) gdmbx;

  // Monitor -> Scoreboard
  mailbox #(transaction) msmbx;

  // Generator -> Scoreboard
  mailbox #(transaction) mbxref;


  event next;

  virtual dff_if vif;


  function new(virtual dff_if vif);

    this.vif = vif;


    // Create mailboxes
    gdmbx = new();
    msmbx = new();
    mbxref = new();


    // Create components
    gen = new(gdmbx, mbxref);
    drv = new(gdmbx);
    mon = new(msmbx);
    sco = new(msmbx, mbxref);


    // Connect virtual interface
    drv.vif = this.vif;
    mon.vif = this.vif;


    // Synchronization
    gen.sconext = next;
    sco.sconext = next;

  endfunction


  //==========================================================
  // Pre-test
  //==========================================================

  task pre_test();

    drv.reset();

  endtask


  //==========================================================
  // Test
  //==========================================================

  task test();

    fork

      gen.run();
      drv.run();
      mon.run();
      sco.run();

    join_none

  endtask


  //==========================================================
  // Post-test
  //==========================================================

  task post_test();

    wait(gen.done.triggered);

    #20;

    $display("");
    $display("==========================================");
    $display("       DFF SIMULATION COMPLETED");
    $display("==========================================");
    $display("");

    $finish();

  endtask


  //==========================================================
  // Run
  //==========================================================

  task run();

    pre_test();

    test();

    post_test();

  endtask

endclass


//============================================================
// TOP TESTBENCH
//============================================================

module dff_tb;

  //==========================================================
  // Interface
  //==========================================================

  dff_if vif();


  //==========================================================
  // DUT
  //==========================================================

  dff dut(vif);


  //==========================================================
  // Environment
  //==========================================================

  environment env;


  //==========================================================
  // Clock Generation
  //==========================================================

  initial begin

    vif.clk = 1'b0;

  end


  always #5 vif.clk = ~vif.clk;


  //==========================================================
  // Test
  //==========================================================

  initial begin

    env = new(vif);

    // Number of random transactions
    env.gen.count = 20;

    env.run();

  end


  //==========================================================
  // VCD Waveform Generation
  //==========================================================

  initial begin

    $dumpfile("dff_waveform.vcd");

    // IMPORTANT:
    // Top module is dff_tb, NOT tb
    $dumpvars(0, dff_tb);

  end


endmodule