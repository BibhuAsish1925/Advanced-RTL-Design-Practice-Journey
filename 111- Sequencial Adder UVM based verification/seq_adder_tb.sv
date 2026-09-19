// ============================================================
// UVM Package
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;


// ============================================================
// Transaction
// Unique name: adder_transaction
// ============================================================

class adder_transaction extends uvm_sequence_item;

    rand bit [3:0] a;
    rand bit [3:0] b;
         bit [4:0] y;

    function new(string name = "adder_transaction");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(adder_transaction)
        `uvm_field_int(a, UVM_DEFAULT)
        `uvm_field_int(b, UVM_DEFAULT)
        `uvm_field_int(y, UVM_DEFAULT)
    `uvm_object_utils_end

endclass


// ============================================================
// Generator / Sequence
// Unique name: adder_generator
// ============================================================

class adder_generator extends uvm_sequence #(adder_transaction);

    `uvm_object_utils(adder_generator)

    adder_transaction trans;

    function new(string name = "adder_generator");
        super.new(name);
    endfunction

    virtual task body();

        repeat(10) begin

            trans = adder_transaction::type_id::create("trans");

            start_item(trans);

            if (!trans.randomize())
                `uvm_error("GEN",
                    "Transaction randomization failed")

            `uvm_info("GEN",
                $sformatf(
                    "Sending to Driver: a = %0d, b = %0d",
                    trans.a,
                    trans.b
                ),
                UVM_NONE
            )

            finish_item(trans);

        end

    endtask

endclass


// ============================================================
// Driver
// Unique name: adder_driver
// ============================================================

class adder_driver extends uvm_driver #(adder_transaction);

    `uvm_component_utils(adder_driver)

    virtual seq_add_if aif;

    adder_transaction trans;

    function new(
        string name = "adder_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual seq_add_if)::get(
                this,
                "",
                "aif",
                aif
            ))

            `uvm_fatal(
                "DRV",
                "Unable to access virtual interface"
            )

    endfunction


    virtual task run_phase(uvm_phase phase);

        forever begin

            seq_item_port.get_next_item(trans);

            // Drive right after a clock edge, so inputs are stable
            // well before the NEXT edge that will actually latch them
            @(posedge aif.clk);
            aif.a <= trans.a;
            aif.b <= trans.b;

            `uvm_info(
                "DRV",
                $sformatf(
                    "Driving DUT: a = %0d, b = %0d",
                    trans.a,
                    trans.b
                ),
                UVM_NONE
            )

            seq_item_port.item_done();

        end

    endtask

endclass


// ============================================================
// Monitor
// Unique name: adder_monitor
// ============================================================

class adder_monitor extends uvm_monitor;

    `uvm_component_utils(adder_monitor)

    virtual seq_add_if aif;

    uvm_analysis_port #(adder_transaction) send;

    // Declare transaction as a class member
    adder_transaction trans;

    // Pipeline registers: y observed at a clock edge corresponds to
    // the a/b that were present BEFORE that same edge (one-cycle
    // registered latency), not the a/b sampled at the same instant.
    bit [3:0] prev_a, prev_b;
    bit       have_prev;


    function new(
        string name = "adder_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        send = new("send", this);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual seq_add_if)::get(
                this,
                "",
                "aif",
                aif
            ))

            `uvm_fatal(
                "MON",
                "Unable to access virtual interface"
            )

    endfunction


    virtual task run_phase(uvm_phase phase);

        have_prev = 0;

        forever begin

            @(posedge aif.clk);
            #1; // let the DUT's non-blocking update to y settle

            if (have_prev) begin
                trans = adder_transaction::type_id::create("trans");
                trans.a = prev_a;
                trans.b = prev_b;
                trans.y = aif.y;

                `uvm_info(
                    "MON",
                    $sformatf(
                        "Monitor: a = %0d, b = %0d, y = %0d",
                        trans.a,
                        trans.b,
                        trans.y
                    ),
                    UVM_NONE
                )

                send.write(trans);
            end

            prev_a    = aif.a;
            prev_b    = aif.b;
            have_prev = 1;

        end

    endtask

endclass


// ============================================================
// Scoreboard
// Unique name: adder_scoreboard
// ============================================================

class adder_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(adder_scoreboard)

    uvm_analysis_imp #(adder_transaction, adder_scoreboard) recv;

    function new(
        string name = "adder_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

        recv = new("recv", this);

    endfunction


    virtual function void write(adder_transaction trans);

        `uvm_info(
            "SCO",
            $sformatf(
                "Received: a = %0d, b = %0d, y = %0d",
                trans.a,
                trans.b,
                trans.y
            ),
            UVM_NONE
        )


        if (trans.y == (trans.a + trans.b)) begin

            `uvm_info(
                "SCO",
                "TEST PASSED",
                UVM_NONE
            )

        end

        else begin

            `uvm_error(
                "SCO",
                $sformatf(
                    "TEST FAILED: Expected = %0d, Actual = %0d",
                    trans.a + trans.b,
                    trans.y
                )
            )

        end

    endfunction

endclass


// ============================================================
// Agent
// Unique name: adder_agent
// ============================================================

class adder_agent extends uvm_agent;

    `uvm_component_utils(adder_agent)

    adder_monitor mon;
    adder_driver  drv;

    uvm_sequencer #(adder_transaction) seqr;


    function new(
        string name = "adder_agent",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        mon = adder_monitor::type_id::create(
            "mon",
            this
        );

        drv = adder_driver::type_id::create(
            "drv",
            this
        );

        seqr = uvm_sequencer #(adder_transaction)::type_id::create(
            "seqr",
            this
        );

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        drv.seq_item_port.connect(
            seqr.seq_item_export
        );

    endfunction

endclass


// ============================================================
// Environment
// Unique name: adder_env
// ============================================================

class adder_env extends uvm_env;

    `uvm_component_utils(adder_env)

    adder_agent      agt;
    adder_scoreboard sb;


    function new(
        string name = "adder_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agt = adder_agent::type_id::create(
            "agt",
            this
        );

        sb = adder_scoreboard::type_id::create(
            "sb",
            this
        );

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        agt.mon.send.connect(
            sb.recv
        );

    endfunction

endclass


// ============================================================
// Test
// Unique name: adder_test
// ============================================================

class adder_test extends uvm_test;

    `uvm_component_utils(adder_test)

    adder_generator gen;
    adder_env       env;


    function new(
        string name = "adder_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        gen = adder_generator::type_id::create(
            "gen"
        );

        env = adder_env::type_id::create(
            "env",
            this
        );

    endfunction


    virtual task run_phase(uvm_phase phase);

        phase.raise_objection(this);

        gen.start(
            env.agt.seqr
        );

        #20;

        phase.drop_objection(this);

    endtask

endclass


// ============================================================
// UVM Testbench Top
// ============================================================

module seq_adder_tb;

    seq_add_if aif();

    // DUT
    seq_adder dut (
        .clk(aif.clk),
        .rst(aif.rst),
        .a(aif.a),
        .b(aif.b),
        .y(aif.y)
    );

    // Clock generation
    initial aif.clk = 1'b0;
    always #5 aif.clk = ~aif.clk;

    // Reset sequencing
    initial begin
        aif.rst = 1'b1;
        repeat (2) @(posedge aif.clk);
        aif.rst = 1'b0;
    end


    initial begin

        uvm_config_db #(virtual seq_add_if)::set(
            null,
            "uvm_test_top.env.agt*",
            "aif",
            aif
        );

        run_test("adder_test");

    end


    // Optional waveform dump
    initial begin

        $dumpfile("adder_uvm.vcd");
        $dumpvars(0, seq_adder_tb);

    end

endmodule