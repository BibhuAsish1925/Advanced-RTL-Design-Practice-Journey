//============================================================
// FIFO INTERFACE
//============================================================

interface fifo_if;

  logic       clock;
  logic       rst;

  logic       rd;
  logic       wr;

  logic [7:0] data_in;
  logic [7:0] data_out;

  logic       full;
  logic       empty;

endinterface



//============================================================
// TRANSACTION
//============================================================

class transaction;

  rand bit       wr;
  rand bit       rd;
  rand bit [7:0] data_in;

  bit [7:0] data_out;

  bit full;
  bit empty;


  // Keep randomization simple
  constraint valid_control {
    wr inside {0,1};
    rd inside {0,1};
  }


  function transaction copy();

    copy = new();

    copy.wr       = this.wr;
    copy.rd       = this.rd;
    copy.data_in  = this.data_in;

    copy.data_out = this.data_out;

    copy.full     = this.full;
    copy.empty    = this.empty;

  endfunction


  function void display(input string tag);

    $display(
      "[%0s] WR=%0b RD=%0b DATA_IN=%0h DATA_OUT=%0h FULL=%0b EMPTY=%0b",
      tag,
      wr,
      rd,
      data_in,
      data_out,
      full,
      empty
    );

  endfunction

endclass



//============================================================
// GENERATOR
//============================================================

class generator;

  transaction tr;

  mailbox #(transaction) mbx;

  event sconext;
  event done;

  int count;


  function new(mailbox #(transaction) mbx);

    this.mbx = mbx;

    tr = new();

  endfunction


  task run();

    repeat(count) begin

      assert(tr.randomize())
        else $error("[GEN] : RANDOMIZATION FAILED");


      mbx.put(tr.copy());

      tr.display("GEN");


      // Wait for scoreboard
      @(sconext);

    end


    ->done;

  endtask

endclass



//============================================================
// DRIVER
//============================================================

class driver;

  transaction tr;

  mailbox #(transaction) mbx;

  virtual fifo_if vif;


  function new(mailbox #(transaction) mbx);

    this.mbx = mbx;

  endfunction


  //==========================================================
  // RESET
  //==========================================================

  task reset();

    vif.rst     <= 1'b1;

    vif.wr      <= 1'b0;
    vif.rd      <= 1'b0;
    vif.data_in <= 8'h00;


    repeat(2)
      @(posedge vif.clock);


    vif.rst <= 1'b0;


    @(posedge vif.clock);


    $display("[DRV] : RESET DONE");

  endtask



  //==========================================================
  // DRIVE TRANSACTION
  //==========================================================

  task run();

    forever begin

      mbx.get(tr);


      // Drive before next rising edge
      @(negedge vif.clock);


      vif.wr      <= tr.wr;
      vif.rd      <= tr.rd;
      vif.data_in <= tr.data_in;


      tr.display("DRV");

    end

  endtask

endclass



//============================================================
// MONITOR
//============================================================

class monitor;

  transaction tr;

  mailbox #(transaction) mbx;

  virtual fifo_if vif;


  function new(mailbox #(transaction) mbx);

    this.mbx = mbx;

  endfunction


  task run();

    forever begin

      @(posedge vif.clock);

      // Allow DUT non-blocking assignments to update
      #1;


      tr = new();


      tr.wr       = vif.wr;
      tr.rd       = vif.rd;

      tr.data_in  = vif.data_in;
      tr.data_out = vif.data_out;

      tr.full     = vif.full;
      tr.empty    = vif.empty;


      mbx.put(tr);


      tr.display("MON");

    end

  endtask

endclass



//============================================================
// SCOREBOARD
//============================================================

class scoreboard;

  transaction tr;

  mailbox #(transaction) mbx;

  event sconext;


  // Reference model
  bit [7:0] reference_queue[$];


  function new(mailbox #(transaction) mbx);

    this.mbx = mbx;

  endfunction



  task run();

    forever begin

      mbx.get(tr);


      //------------------------------------------------------
      // WRITE CHECK
      //------------------------------------------------------

      if (tr.wr && !tr.full) begin

        reference_queue.push_back(tr.data_in);

        $display(
          "[SCO] WRITE ACCEPTED : DATA = %0h",
          tr.data_in
        );

      end


      //------------------------------------------------------
      // READ CHECK
      //------------------------------------------------------

      if (tr.rd && !tr.empty) begin

        if (reference_queue.size() > 0) begin

          if (tr.data_out == reference_queue[0]) begin

            $display(
              "[SCO] READ MATCHED : EXPECTED = %0h ACTUAL = %0h",
              reference_queue[0],
              tr.data_out
            );

          end

          else begin

            $display(
              "[SCO] READ MISMATCHED : EXPECTED = %0h ACTUAL = %0h",
              reference_queue[0],
              tr.data_out
            );

          end


          reference_queue.pop_front();

        end

      end


      //------------------------------------------------------
      // EMPTY FLAG CHECK
      //------------------------------------------------------

      if (reference_queue.size() == 0) begin

        if (!tr.empty)
          $display("[SCO] ERROR : EMPTY FLAG INCORRECT");

      end


      //------------------------------------------------------
      // FULL FLAG CHECK
      //------------------------------------------------------

      if (reference_queue.size() == 32) begin

        if (!tr.full)
          $display("[SCO] ERROR : FULL FLAG INCORRECT");

      end


      ->sconext;

    end

  endtask

endclass



//============================================================
// ENVIRONMENT
//============================================================

class environment;

  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  sco;


  mailbox #(transaction) gdmbx;
  mailbox #(transaction) msmbx;


  event next;


  virtual fifo_if vif;


  function new(virtual fifo_if vif);

    this.vif = vif;


    //--------------------------------------------------------
    // Mailboxes
    //--------------------------------------------------------

    gdmbx = new();

    msmbx = new();


    //--------------------------------------------------------
    // Components
    //--------------------------------------------------------

    gen = new(gdmbx);

    drv = new(gdmbx);

    mon = new(msmbx);

    sco = new(msmbx);


    //--------------------------------------------------------
    // Virtual Interface Connections
    //--------------------------------------------------------

    drv.vif = this.vif;

    mon.vif = this.vif;


    //--------------------------------------------------------
    // Synchronization
    //--------------------------------------------------------

    gen.sconext = next;

    sco.sconext = next;

  endfunction



  task pre_test();

    drv.reset();

  endtask



  task test();

    fork

      gen.run();

      drv.run();

      mon.run();

      sco.run();

    join_none

  endtask



  task post_test();

    wait(gen.done.triggered);


    #20;


    $display("");
    $display("==============================================");
    $display("        FIFO SIMULATION COMPLETED");
    $display("==============================================");
    $display("");


    $finish();

  endtask



  task run();

    pre_test();

    test();

    post_test();

  endtask

endclass



//============================================================
// TOP TESTBENCH
//============================================================

module fifo_tb;


  //==========================================================
  // Interface
  //==========================================================

  fifo_if vif();



  //==========================================================
  // DUT
  //==========================================================

  fifo dut (

    .clock    (vif.clock),
    .rd       (vif.rd),
    .wr       (vif.wr),
    .full     (vif.full),
    .empty    (vif.empty),
    .data_in  (vif.data_in),
    .data_out (vif.data_out),
    .rst      (vif.rst)

  );



  //==========================================================
  // Environment
  //==========================================================

  environment env;



  //==========================================================
  // CLOCK
  //==========================================================

  initial begin

    vif.clock = 1'b0;

  end


  always #5 vif.clock = ~vif.clock;



  //==========================================================
  // TEST
  //==========================================================

  initial begin

    env = new(vif);


    // Number of transactions
    env.gen.count = 50;


    env.run();

  end



  //==========================================================
  // VCD WAVEFORM
  //==========================================================

  initial begin

    $dumpfile("fifo_waveform.vcd");

    // IMPORTANT:
    // Top module is fifo_tb
    $dumpvars(0, fifo_tb);

  end


endmodule