`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;


// ============================================================
// APB CONFIGURATION
// Unique class name
// ============================================================

class apb_config extends uvm_object;

    `uvm_object_utils(apb_config)

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "apb_config");
        super.new(name);
    endfunction

endclass


// ============================================================
// OPERATION MODE
// ============================================================

typedef enum bit [1:0] {
    APB_READ  = 0,
    APB_WRITE = 1,
    APB_RESET = 2
} apb_oper_mode;


// ============================================================
// APB TRANSACTION
// ============================================================

class apb_transaction extends uvm_sequence_item;

    // --------------------------------------------------------
    // Inputs / stimulus
    // --------------------------------------------------------

    rand logic [31:0] PADDR;
    rand logic [31:0] PWDATA;

    apb_oper_mode OP;

    logic PWRITE;

    // --------------------------------------------------------
    // DUT outputs
    // --------------------------------------------------------

    logic        PREADY;
    logic        PSLVERR;
    logic [31:0] PRDATA;


    // --------------------------------------------------------
    // Address constraints
    // --------------------------------------------------------

    constraint valid_addr_c {
        PADDR inside {[0:31]};
    }

    constraint invalid_addr_c {
        PADDR > 31;
    }


    // --------------------------------------------------------
    // UVM factory registration
    // --------------------------------------------------------

    `uvm_object_utils_begin(apb_transaction)

        `uvm_field_int(PWRITE, UVM_ALL_ON)
        `uvm_field_int(PWDATA, UVM_ALL_ON)
        `uvm_field_int(PADDR,  UVM_ALL_ON)

        `uvm_field_int(PREADY,  UVM_ALL_ON)
        `uvm_field_int(PSLVERR, UVM_ALL_ON)
        `uvm_field_int(PRDATA,  UVM_ALL_ON)

        `uvm_field_enum(
            apb_oper_mode,
            OP,
            UVM_DEFAULT
        )

    `uvm_object_utils_end


    function new(string name = "apb_transaction");
        super.new(name);
    endfunction

endclass


// ============================================================
// WRITE SEQUENCE
// ============================================================

class apb_write_seq extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_write_seq)

    apb_transaction tr;


    function new(string name = "apb_write_seq");
        super.new(name);
    endfunction


    virtual task body();

        repeat (15) begin

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(1);
            tr.invalid_addr_c.constraint_mode(0);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "WRITE_SEQ",
                    "Transaction randomization failed"
                )
            end

            tr.OP     = APB_WRITE;
            tr.PWRITE = 1'b1;

            finish_item(tr);

        end

    endtask

endclass


// ============================================================
// READ SEQUENCE
// ============================================================

class apb_read_seq extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_read_seq)

    apb_transaction tr;


    function new(string name = "apb_read_seq");
        super.new(name);
    endfunction


    virtual task body();

        repeat (15) begin

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(1);
            tr.invalid_addr_c.constraint_mode(0);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "READ_SEQ",
                    "Transaction randomization failed"
                )
            end

            tr.OP     = APB_READ;
            tr.PWRITE = 1'b0;

            finish_item(tr);

        end

    endtask

endclass


// ============================================================
// WRITE THEN READ SEQUENCE
// ============================================================

class apb_write_read_seq extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_write_read_seq)

    apb_transaction tr;


    function new(string name = "apb_write_read_seq");
        super.new(name);
    endfunction


    virtual task body();

        repeat (15) begin

            // ------------------------------------------------
            // WRITE
            // ------------------------------------------------

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(1);
            tr.invalid_addr_c.constraint_mode(0);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "WR_RD_SEQ",
                    "Write randomization failed"
                )
            end

            tr.OP     = APB_WRITE;
            tr.PWRITE = 1'b1;

            finish_item(tr);


            // ------------------------------------------------
            // READ
            // ------------------------------------------------

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(1);
            tr.invalid_addr_c.constraint_mode(0);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "WR_RD_SEQ",
                    "Read randomization failed"
                )
            end

            tr.OP     = APB_READ;
            tr.PWRITE = 1'b0;

            finish_item(tr);

        end

    endtask

endclass


// ============================================================
// BULK WRITE THEN BULK READ
// ============================================================

class apb_writeb_readb_seq extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_writeb_readb_seq)

    apb_transaction tr;


    function new(string name = "apb_writeb_readb_seq");
        super.new(name);
    endfunction


    virtual task body();

        // ----------------------------------------------------
        // 15 WRITE operations
        // ----------------------------------------------------

        repeat (15) begin

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(1);
            tr.invalid_addr_c.constraint_mode(0);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "BULK_SEQ",
                    "Write randomization failed"
                )
            end

            tr.OP     = APB_WRITE;
            tr.PWRITE = 1'b1;

            finish_item(tr);

        end


        // ----------------------------------------------------
        // 15 READ operations
        // ----------------------------------------------------

        repeat (15) begin

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(1);
            tr.invalid_addr_c.constraint_mode(0);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "BULK_SEQ",
                    "Read randomization failed"
                )
            end

            tr.OP     = APB_READ;
            tr.PWRITE = 1'b0;

            finish_item(tr);

        end

    endtask

endclass


// ============================================================
// INVALID WRITE SEQUENCE
// ============================================================

class apb_write_err_seq extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_write_err_seq)

    apb_transaction tr;


    function new(string name = "apb_write_err_seq");
        super.new(name);
    endfunction


    virtual task body();

        repeat (15) begin

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(0);
            tr.invalid_addr_c.constraint_mode(1);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "WR_ERR_SEQ",
                    "Invalid write randomization failed"
                )
            end

            tr.OP     = APB_WRITE;
            tr.PWRITE = 1'b1;

            finish_item(tr);

        end

    endtask

endclass


// ============================================================
// INVALID READ SEQUENCE
// ============================================================

class apb_read_err_seq extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_read_err_seq)

    apb_transaction tr;


    function new(string name = "apb_read_err_seq");
        super.new(name);
    endfunction


    virtual task body();

        repeat (15) begin

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(0);
            tr.invalid_addr_c.constraint_mode(1);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "RD_ERR_SEQ",
                    "Invalid read randomization failed"
                )
            end

            tr.OP     = APB_READ;
            tr.PWRITE = 1'b0;

            finish_item(tr);

        end

    endtask

endclass


// ============================================================
// RESET SEQUENCE
// ============================================================

class apb_reset_seq extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_reset_seq)

    apb_transaction tr;


    function new(string name = "apb_reset_seq");
        super.new(name);
    endfunction


    virtual task body();

        repeat (5) begin

            tr = apb_transaction::type_id::create("tr");

            tr.valid_addr_c.constraint_mode(1);
            tr.invalid_addr_c.constraint_mode(0);

            start_item(tr);

            if (!tr.randomize()) begin
                `uvm_fatal(
                    "RESET_SEQ",
                    "Reset transaction randomization failed"
                )
            end

            tr.OP     = APB_RESET;
            tr.PWRITE = 1'b0;

            finish_item(tr);

        end

    endtask

endclass


// ============================================================
// DRIVER
// ============================================================

class apb_driver extends uvm_driver #(apb_transaction);

    `uvm_component_utils(apb_driver)

    virtual apb_if vif;

    apb_transaction tr;


    function new(
        string name = "apb_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // --------------------------------------------------------
    // Build phase
    // --------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual apb_if)::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "DRV",
                "Unable to access APB virtual interface"
            )

        end

    endfunction


    // --------------------------------------------------------
    // Reset
    // --------------------------------------------------------

    task reset_dut();

        repeat (5) begin

            vif.presetn <= 1'b0;
            vif.paddr   <= 32'h0;
            vif.pwdata  <= 32'h0;
            vif.pwrite  <= 1'b0;
            vif.psel    <= 1'b0;
            vif.penable <= 1'b0;

            `uvm_info(
                "DRV",
                "System Reset Active",
                UVM_MEDIUM
            )

            @(posedge vif.pclk);

        end

        vif.presetn <= 1'b1;

    endtask


    // --------------------------------------------------------
    // Drive one transaction
    // --------------------------------------------------------

    task drive_transaction(apb_transaction tr);

        // ====================================================
        // RESET
        // ====================================================

        if (tr.OP == APB_RESET) begin

            vif.presetn <= 1'b0;
            vif.paddr   <= 32'h0;
            vif.pwdata  <= 32'h0;
            vif.pwrite  <= 1'b0;
            vif.psel    <= 1'b0;
            vif.penable <= 1'b0;

            @(posedge vif.pclk);

            vif.presetn <= 1'b1;

        end


        // ====================================================
        // WRITE
        // ====================================================

        else if (tr.OP == APB_WRITE) begin

            vif.presetn <= 1'b1;
            vif.psel    <= 1'b1;
            vif.pwrite  <= 1'b1;
            vif.paddr   <= tr.PADDR;
            vif.pwdata  <= tr.PWDATA;
            vif.penable <= 1'b0;

            // Setup phase
            @(posedge vif.pclk);

            // Access phase
            vif.penable <= 1'b1;

            @(posedge vif.pclk);

            // Wait until DUT completes transfer
            @(negedge vif.pready);

            tr.PREADY  = vif.pready;
            tr.PSLVERR = vif.pslverr;

            `uvm_info(
                "DRV",
                $sformatf(
                    "WRITE: addr=%0d data=%0d slverr=%0d",
                    tr.PADDR,
                    tr.PWDATA,
                    tr.PSLVERR
                ),
                UVM_NONE
            )

            vif.penable <= 1'b0;

        end


        // ====================================================
        // READ
        // ====================================================

        else if (tr.OP == APB_READ) begin

            vif.presetn <= 1'b1;
            vif.psel    <= 1'b1;
            vif.pwrite  <= 1'b0;
            vif.paddr   <= tr.PADDR;
            vif.pwdata  <= 32'h0;
            vif.penable <= 1'b0;

            // Setup phase
            @(posedge vif.pclk);

            // Access phase
            vif.penable <= 1'b1;

            @(posedge vif.pclk);

            // Wait until DUT completes transfer
            @(negedge vif.pready);

            tr.PREADY  = vif.pready;
            tr.PRDATA  = vif.prdata;
            tr.PSLVERR = vif.pslverr;

            `uvm_info(
                "DRV",
                $sformatf(
                    "READ: addr=%0d data=%0d slverr=%0d",
                    tr.PADDR,
                    tr.PRDATA,
                    tr.PSLVERR
                ),
                UVM_NONE
            )

            vif.penable <= 1'b0;

        end

    endtask


    // --------------------------------------------------------
    // Run phase
    // --------------------------------------------------------

    virtual task run_phase(uvm_phase phase);

        reset_dut();

        forever begin

            seq_item_port.get_next_item(tr);

            drive_transaction(tr);

            seq_item_port.item_done();

        end

    endtask

endclass


// ============================================================
// MONITOR
// ============================================================

class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;

    uvm_analysis_port #(apb_transaction) send;


    function new(
        string name = "apb_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        send = new("send", this);

    endfunction


    // --------------------------------------------------------
    // Build phase
    // --------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual apb_if)::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "MON",
                "Unable to access APB virtual interface"
            )

        end

    endfunction


    // --------------------------------------------------------
    // Monitor
    // --------------------------------------------------------

    virtual task run_phase(uvm_phase phase);

        forever begin

            @(posedge vif.pclk);


            // =================================================
            // RESET
            // =================================================

            if (!vif.presetn) begin

                apb_transaction reset_tr;

                reset_tr =
                    apb_transaction::type_id::create(
                        "reset_tr"
                    );

                reset_tr.OP = APB_RESET;

                `uvm_info(
                    "MON",
                    "SYSTEM RESET DETECTED",
                    UVM_NONE
                )

                send.write(reset_tr);

            end


            // =================================================
            // WRITE
            // =================================================

            else if (vif.presetn &&
                     vif.psel &&
                     vif.pwrite &&
                     vif.penable) begin

                apb_transaction wr_tr;

                wr_tr =
                    apb_transaction::type_id::create(
                        "wr_tr"
                    );

                wr_tr.OP     = APB_WRITE;
                wr_tr.PWRITE = 1'b1;
                wr_tr.PADDR  = vif.paddr;
                wr_tr.PWDATA = vif.pwdata;

                // Wait for transfer completion
                @(negedge vif.pready);

                wr_tr.PREADY  = vif.pready;
                wr_tr.PSLVERR = vif.pslverr;

                `uvm_info(
                    "MON",
                    $sformatf(
                        "WRITE: addr=%0d data=%0d slverr=%0d",
                        wr_tr.PADDR,
                        wr_tr.PWDATA,
                        wr_tr.PSLVERR
                    ),
                    UVM_NONE
                )

                send.write(wr_tr);

            end


            // =================================================
            // READ
            // =================================================

            else if (vif.presetn &&
                     vif.psel &&
                     !vif.pwrite &&
                     vif.penable) begin

                apb_transaction rd_tr;

                rd_tr =
                    apb_transaction::type_id::create(
                        "rd_tr"
                    );

                rd_tr.OP     = APB_READ;
                rd_tr.PWRITE = 1'b0;
                rd_tr.PADDR  = vif.paddr;

                // Wait for transfer completion
                @(negedge vif.pready);

                rd_tr.PREADY  = vif.pready;
                rd_tr.PRDATA  = vif.prdata;
                rd_tr.PSLVERR = vif.pslverr;

                `uvm_info(
                    "MON",
                    $sformatf(
                        "READ: addr=%0d data=%0d slverr=%0d",
                        rd_tr.PADDR,
                        rd_tr.PRDATA,
                        rd_tr.PSLVERR
                    ),
                    UVM_NONE
                )

                send.write(rd_tr);

            end

        end

    endtask

endclass


// ============================================================
// SCOREBOARD
// ============================================================

class apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(
        apb_transaction,
        apb_scoreboard
    ) recv;


    // Reference memory
    bit [31:0] reference_mem [32];


    function new(
        string name = "apb_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

        recv = new("recv", this);

    endfunction


    // --------------------------------------------------------
    // Build
    // --------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        for (int i = 0; i < 32; i++)
            reference_mem[i] = 32'h0;

    endfunction


    // --------------------------------------------------------
    // Analysis write
    // --------------------------------------------------------

    virtual function void write(apb_transaction tr);


        // =====================================================
        // RESET
        // =====================================================

        if (tr.OP == APB_RESET) begin

            for (int i = 0; i < 32; i++)
                reference_mem[i] = 32'h0;

            `uvm_info(
                "SCO",
                "REFERENCE MEMORY RESET",
                UVM_NONE
            )

        end


        // =====================================================
        // WRITE
        // =====================================================

        else if (tr.OP == APB_WRITE) begin

            if (tr.PSLVERR) begin

                `uvm_info(
                    "SCO",
                    $sformatf(
                        "SLV ERROR during WRITE: addr=%0d",
                        tr.PADDR
                    ),
                    UVM_NONE
                )

            end

            else begin

                reference_mem[tr.PADDR] = tr.PWDATA;

                `uvm_info(
                    "SCO",
                    $sformatf(
                        "WRITE: addr=%0d data=%0d",
                        tr.PADDR,
                        tr.PWDATA
                    ),
                    UVM_NONE
                )

            end

        end


        // =====================================================
        // READ
        // =====================================================

        else if (tr.OP == APB_READ) begin

            if (tr.PSLVERR) begin

                `uvm_info(
                    "SCO",
                    $sformatf(
                        "SLV ERROR during READ: addr=%0d",
                        tr.PADDR
                    ),
                    UVM_NONE
                )

            end

            else begin

                if (reference_mem[tr.PADDR] == tr.PRDATA) begin

                    `uvm_info(
                        "SCO",
                        $sformatf(
                            "DATA MATCHED: addr=%0d expected=%0d actual=%0d",
                            tr.PADDR,
                            reference_mem[tr.PADDR],
                            tr.PRDATA
                        ),
                        UVM_NONE
                    )

                end

                else begin

                    `uvm_error(
                        "SCO",
                        $sformatf(
                            "DATA MISMATCH: addr=%0d expected=%0d actual=%0d",
                            tr.PADDR,
                            reference_mem[tr.PADDR],
                            tr.PRDATA
                        )
                    )

                end

            end

        end


        $display(
            "------------------------------------------------------------"
        );

    endfunction

endclass


// ============================================================
// AGENT
// ============================================================

class apb_agent extends uvm_agent;

    `uvm_component_utils(apb_agent)

    apb_config cfg;

    apb_driver drv;
    apb_monitor mon;

    uvm_sequencer #(apb_transaction) seqr;


    function new(
        string name = "apb_agent",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // --------------------------------------------------------
    // Build phase
    // --------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        cfg = apb_config::type_id::create("cfg");

        mon = apb_monitor::type_id::create(
            "mon",
            this
        );


        if (cfg.is_active == UVM_ACTIVE) begin

            drv = apb_driver::type_id::create(
                "drv",
                this
            );

            seqr =
                uvm_sequencer #(
                    apb_transaction
                )::type_id::create(
                    "seqr",
                    this
                );

        end

    endfunction


    // --------------------------------------------------------
    // Connect phase
    // --------------------------------------------------------

    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        if (cfg.is_active == UVM_ACTIVE) begin

            drv.seq_item_port.connect(
                seqr.seq_item_export
            );

        end

    endfunction

endclass


// ============================================================
// ENVIRONMENT
// ============================================================

class apb_env extends uvm_env;

    `uvm_component_utils(apb_env)

    apb_agent      agent;
    apb_scoreboard scoreboard;


    function new(
        string name = "apb_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // --------------------------------------------------------
    // Build phase
    // --------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agent =
            apb_agent::type_id::create(
                "agent",
                this
            );

        scoreboard =
            apb_scoreboard::type_id::create(
                "scoreboard",
                this
            );

    endfunction


    // --------------------------------------------------------
    // Connect phase
    // --------------------------------------------------------

    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        agent.mon.send.connect(
            scoreboard.recv
        );

    endfunction

endclass


// ============================================================
// TEST
// ============================================================

class apb_test extends uvm_test;

    `uvm_component_utils(apb_test)

    apb_env env;

    apb_write_read_seq  wr_rd_seq;
    apb_writeb_readb_seq bulk_seq;
    apb_write_seq       write_seq;
    apb_read_seq        read_seq;
    apb_write_err_seq   write_err_seq;
    apb_read_err_seq    read_err_seq;
    apb_reset_seq       reset_seq;


    function new(
        string name = "apb_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // --------------------------------------------------------
    // Build phase
    // --------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env =
            apb_env::type_id::create(
                "env",
                this
            );

        wr_rd_seq =
            apb_write_read_seq::type_id::create(
                "wr_rd_seq"
            );

        bulk_seq =
            apb_writeb_readb_seq::type_id::create(
                "bulk_seq"
            );

        write_seq =
            apb_write_seq::type_id::create(
                "write_seq"
            );

        read_seq =
            apb_read_seq::type_id::create(
                "read_seq"
            );

        write_err_seq =
            apb_write_err_seq::type_id::create(
                "write_err_seq"
            );

        read_err_seq =
            apb_read_err_seq::type_id::create(
                "read_err_seq"
            );

        reset_seq =
            apb_reset_seq::type_id::create(
                "reset_seq"
            );

    endfunction


    // --------------------------------------------------------
    // Run phase
    // --------------------------------------------------------

    virtual task run_phase(uvm_phase phase);

        phase.raise_objection(this);


        // ----------------------------------------------------
        // Default test
        // Bulk write followed by bulk read
        // ----------------------------------------------------

        bulk_seq.start(
            env.agent.seqr
        );


        // Allow final DUT transaction to settle
        #100;


        phase.drop_objection(this);

    endtask

endclass


// ============================================================
// TESTBENCH TOP
// ============================================================

module apb_ram_tb;

    apb_if vif();


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    apb_ram dut (

        .presetn (vif.presetn),
        .pclk    (vif.pclk),

        .psel    (vif.psel),
        .penable (vif.penable),
        .pwrite  (vif.pwrite),

        .paddr   (vif.paddr),
        .pwdata  (vif.pwdata),

        .prdata  (vif.prdata),
        .pready  (vif.pready),
        .pslverr (vif.pslverr)

    );


    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        vif.pclk = 1'b0;
    end

    always #10 vif.pclk = ~vif.pclk;


    // --------------------------------------------------------
    // UVM configuration
    // --------------------------------------------------------

    initial begin

        uvm_config_db #(
            virtual apb_if
        )::set(
            null,
            "*",
            "vif",
            vif
        );

        run_test("apb_test");

    end


    // --------------------------------------------------------
    // Waveform
    // --------------------------------------------------------

    initial begin

        $dumpfile("apb_ram_uvm.vcd");
        $dumpvars(0, apb_ram_tb);

    end

endmodule