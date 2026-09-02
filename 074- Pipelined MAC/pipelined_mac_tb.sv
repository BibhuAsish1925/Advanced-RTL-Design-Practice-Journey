module pipelined_mac_tb;
    parameter int DATA_WIDTH = 8;
    parameter int ACC_WIDTH  = 32;
    logic                  clk;
    logic                  rst;
    logic                  en;
    logic [DATA_WIDTH-1:0] a;
    logic [DATA_WIDTH-1:0] b;
    logic [ACC_WIDTH-1:0] acc;
    logic [ACC_WIDTH-1:0] expected_acc;
    logic [2*DATA_WIDTH-1:0] expected_product;
    // DUT
    pipelined_mac #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .a   (a),
        .b   (b),
        .acc (acc)
    );
    // Clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    // Apply one pipelined MAC input
    task automatic apply_mac(
        input logic [DATA_WIDTH-1:0] a_in,
        input logic [DATA_WIDTH-1:0] b_in
    );
        logic [2*DATA_WIDTH-1:0] product;
        begin
            product = a_in * b_in;
            @(negedge clk);
            a  = a_in;
            b  = b_in;
            en = 1'b1;
            @(posedge clk);
            #1;
            // Accumulator receives the PREVIOUS
            // cycle's product.
            expected_acc = expected_acc + expected_product;
            if (acc !== expected_acc) begin
                $error(
                    "FAIL: A=%0d B=%0d | Expected ACC=%0d | Actual ACC=%0d",
                    a_in,
                    b_in,
                    expected_acc,
                    acc
                );
            end
            else begin
                $display(
                    "PASS: A=%0d B=%0d | Product=%0d | ACC=%0d",
                    a_in,
                    b_in,
                    product,
                    acc
                );
            end
            // Save current product for next cycle
            expected_product = product;
        end
    endtask
    initial begin
        rst = 1'b1;
        en  = 1'b0;
        a = '0;
        b = '0;
        expected_acc     = '0;
        expected_product = '0;
        // Reset
        @(posedge clk);
        #1;
        rst = 1'b0;
        // MAC operations
        apply_mac(8'd5,  8'd3);
        apply_mac(8'd10, 8'd2);
        apply_mac(8'd7,  8'd4);
        apply_mac(8'd12, 8'd5);
        apply_mac(8'd20, 8'd10);
        // Flush final product from pipeline
        @(negedge clk);
        a  = '0;
        b  = '0;
        en = 1'b1;
        @(posedge clk);
        #1;
        expected_acc = expected_acc + expected_product;
        if (acc !== expected_acc)
            $error(
                "FAIL: Pipeline flush | Expected=%0d | Actual=%0d",
                expected_acc,
                acc
            );
        else
            $display(
                "PASS: Pipeline flush | ACC=%0d",
                acc
            );
        // Disable MAC
        @(negedge clk);
        a  = 8'd100;
        b  = 8'd100;
        en = 1'b0;
        @(posedge clk);
        #1;
        if (acc !== expected_acc)
            $error("FAIL: ACC changed while enable was LOW");
        else
            $display(
                "PASS: Enable test | ACC remained %0d",
                acc
            );
        $display("--------------------------------------------");
        $display("PIPELINED MAC TEST COMPLETED");
        $display("Expected ACC = %0d", expected_acc);
        $display("Actual ACC   = %0d", acc);
        $display("--------------------------------------------");
        $finish;
    end
endmodule