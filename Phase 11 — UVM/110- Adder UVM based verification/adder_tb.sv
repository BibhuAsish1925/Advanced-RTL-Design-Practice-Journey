
////////////////////////////////////////////////////////////
// UVM PACKAGE
////////////////////////////////////////////////////////////

`include "uvm_macros.svh"
import uvm_pkg::*;


////////////////////////////////////////////////////////////
// TRANSACTION
////////////////////////////////////////////////////////////

class transaction extends uvm_sequence_item;

    rand bit [3:0] a;
    rand bit [3:0] b;

    bit [4:0] y;

    function new(input string path = "transaction");
        super.new(path);
    endfunction

    `uvm_object_utils_begin(transaction)
        `uvm_field_int(a, UVM_DEFAULT)
        `uvm_field_int(b, UVM_DEFAULT)
        `uvm_field_int(y, UVM_DEFAULT)
    `uvm_object_utils_end

endclass


////////////////////////////////////////////////////////////
// GENERATOR / SEQUENCE
////////////////////////////////////////////////////////////

class generator extends uvm_sequence #(transaction);

    `uvm_object_utils(generator)

    transaction t;

    function new(input string path = "generator");
        super.new(path);
    endfunction

    virtual task body();

        repeat (10) begin

            t = transaction::type_id::create("t");

            start_item(t);

            assert(t.randomize())
                else `uvm_fatal("GEN", "Transaction randomization failed");

            `uvm_info(
                "GEN",
                $sformatf(
                    "Data sent to Driver: a = %0d, b = %0d",
                    t.a, t.b
                ),
                UVM_NONE
            );

            finish_item(t);

        end

    endtask

endclass


////////////////////////////////////////////////////////////
// DRIVER
////////////////////////////////////////////////////////////

class driver extends uvm_driver #(transaction);

    `uvm_component_utils(driver)

    transaction tc;

    virtual add_if aif;

    function new(
        input string path = "driver",
        uvm_component parent = null
    );
        super.new(path, parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual add_if)::get(
                this,
                "",
                "aif",
                aif
            ))
        begin
            `uvm_fatal(
                "DRV",
                "Unable to access virtual interface from uvm_config_db"
            );
        end

    endfunction


    virtual task run_phase(uvm_phase phase);

        forever begin

            seq_item_port.get_next_item(tc);

            aif.a <= tc.a;
            aif.b <= tc.b;

            `uvm_info(
                "DRV",
                $sformatf(
                    "Trigger DUT: a = %0d, b = %0d",
                    tc.a, tc.b
                ),
                UVM_NONE
            );

            // Allow DUT and monitor to process the transaction
            #10;

            seq_item_port.item_done();

        end

    endtask

endclass


////////////////////////////////////////////////////////////
// MONITOR
////////////////////////////////////////////////////////////

class monitor extends uvm_monitor;

    `uvm_component_utils(monitor)

    uvm_analysis_port #(transaction) send;

    transaction t;

    virtual add_if aif;


    function new(
        input string path = "monitor",
        uvm_component parent = null
    );

        super.new(path, parent);

        send = new("send", this);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual add_if)::get(
                this,
                "",
                "aif",
                aif
            ))
        begin
            `uvm_fatal(
                "MON",
                "Unable to access virtual interface from uvm_config_db"
            );
        end

    endfunction


    virtual task run_phase(uvm_phase phase);

        forever begin

            #10;

            t = transaction::type_id::create("t");

            t.a = aif.a;
            t.b = aif.b;
            t.y = aif.y;

            `uvm_info(
                "MON",
                $sformatf(
                    "Data sent to Scoreboard: a = %0d, b = %0d, y = %0d",
                    t.a, t.b, t.y
                ),
                UVM_NONE
            );

            send.write(t);

        end

    endtask

endclass


////////////////////////////////////////////////////////////
// SCOREBOARD
////////////////////////////////////////////////////////////

class scoreboard extends uvm_scoreboard;

    `uvm_component_utils(scoreboard)

    uvm_analysis_imp #(transaction, scoreboard) recv;

    transaction tr;


    function new(
        input string path = "scoreboard",
        uvm_component parent = null
    );

        super.new(path, parent);

        recv = new("recv", this);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

    endfunction


    virtual function void write(input transaction t);

        tr = t;

        `uvm_info(
            "SCO",
            $sformatf(
                "Data received from Monitor: a = %0d, b = %0d, y = %0d",
                tr.a, tr.b, tr.y
            ),
            UVM_NONE
        );


        if (tr.y == (tr.a + tr.b)) begin

            `uvm_info(
                "SCO",
                "TEST PASSED",
                UVM_NONE
            );

        end
        else begin

            `uvm_error(
                "SCO",
                $sformatf(
                    "TEST FAILED: Expected = %0d, Actual = %0d",
                    tr.a + tr.b,
                    tr.y
                )
            );

        end

    endfunction

endclass


////////////////////////////////////////////////////////////
// AGENT
////////////////////////////////////////////////////////////

class agent extends uvm_agent;

    `uvm_component_utils(agent)

    monitor m;
    driver d;

    uvm_sequencer #(transaction) seqr;


    function new(
        input string inst = "AGENT",
        uvm_component parent = null
    );

        super.new(inst, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        m = monitor::type_id::create("m", this);

        d = driver::type_id::create("d", this);

        seqr = uvm_sequencer #(transaction)::type_id::create(
            "seqr",
            this
        );

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        d.seq_item_port.connect(seqr.seq_item_export);

    endfunction

endclass


////////////////////////////////////////////////////////////
// ENVIRONMENT
////////////////////////////////////////////////////////////

class env extends uvm_env;

    `uvm_component_utils(env)

    scoreboard s;
    agent a;


    function new(
        input string inst = "ENV",
        uvm_component parent = null
    );

        super.new(inst, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        s = scoreboard::type_id::create("s", this);

        a = agent::type_id::create("a", this);

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        a.m.send.connect(s.recv);

    endfunction

endclass


////////////////////////////////////////////////////////////
// TEST
////////////////////////////////////////////////////////////

class test extends uvm_test;

    `uvm_component_utils(test)

    generator gen;
    env e;


    function new(
        input string inst = "TEST",
        uvm_component parent = null
    );

        super.new(inst, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        gen = generator::type_id::create("gen");

        e = env::type_id::create("e", this);

    endfunction


    virtual task run_phase(uvm_phase phase);

        phase.raise_objection(this);

        `uvm_info(
            "TEST",
            "UVM test started",
            UVM_LOW
        );

        // Start sequence on agent sequencer
        gen.start(e.a.seqr);

        // Give monitor/scoreboard time to process final transaction
        #10;

        `uvm_info(
            "TEST",
            "UVM test completed",
            UVM_LOW
        );

        phase.drop_objection(this);

    endtask

endclass


////////////////////////////////////////////////////////////
// TOP-LEVEL TESTBENCH
////////////////////////////////////////////////////////////

module adder_tb;

    add_if aif();


    // DUT
    adder dut (
        .a(aif.a),
        .b(aif.b),
        .y(aif.y)
    );


    ////////////////////////////////////////////////////////
    // VCD DUMP
    ////////////////////////////////////////////////////////

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, adder_tb);

    end


    ////////////////////////////////////////////////////////
    // UVM START
    ////////////////////////////////////////////////////////

    initial begin

        uvm_config_db #(virtual add_if)::set(
            null,
            "uvm_test_top.e.a*",
            "aif",
            aif
        );

        run_test("test");

    end

endmodule