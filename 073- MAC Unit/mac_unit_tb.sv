module mac_unit_tb;
    parameter int DATA_WIDTH = 8;
    parameter int ACC_WIDTH  = 32;
    logic                  clk;
    logic                  rst;
    logic                  en;
    logic [DATA_WIDTH-1:0] a;
    logic [DATA_WIDTH-1:0] b;
    logic [ACC_WIDTH-1:0]  acc;
    logic [ACC_WIDTH-1:0] expected_acc;
    // DUT
    mac_unit #(
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
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    // Apply one MAC operation
    task automatic apply_mac(
        input logic [DATA_WIDTH-1:0] a_in,
        input logic [DATA_WIDTH-1:0] b_in
    );
        logic [2*DATA_WIDTH-1:0] product_temp;
        begin
            product_temp = a_in * b_in;
            expected_acc = expected_acc + product_temp;
            @(negedge clk);
            a  = a_in;
            b  = b_in;
            en = 1'b1;
            @(posedge clk);
            #1;
            if (acc !== expected_acc) begin
                $error(
                    "FAIL: A=%0d B=%0d | Expected=%0d | Actual=%0d",
                    a_in, b_in, expected_acc, acc
                );
            end
            else begin
                $display(
                    "PASS: A=%0d B=%0d | Product=%0d | ACC=%0d",
                    a_in, b_in, product_temp, acc
                );
            end
        end
    endtask
    initial begin
        // Initial values
        rst = 1'b1;
        en  = 1'b0;
        a   = '0;
        b   = '0;
        expected_acc = '0;
        // Reset
        @(posedge clk);
        #1;
        rst = 1'b0;
        // MAC operations
        apply_mac(8'd5,  8'd3);    // 15
        apply_mac(8'd10, 8'd2);    // +20 = 35
        apply_mac(8'd7,  8'd4);    // +28 = 63
        apply_mac(8'd12, 8'd5);    // +60 = 123
        apply_mac(8'd20, 8'd10);   // +200 = 323
        // Test enable = 0
        @(negedge clk);
        a  = 8'd100;
        b  = 8'd100;
        en = 1'b0;
        @(posedge clk);
        #1;
        if (acc !== expected_acc)
            $error("FAIL: Accumulator changed while enable was LOW");
        else
            $display("PASS: Enable test | ACC remained %0d", acc);
        // Final result
        $display("----------------------------------------");
        $display("MAC TEST COMPLETED");
        $display("Expected ACC = %0d", expected_acc);
        $display("Actual ACC   = %0d", acc);
        $display("----------------------------------------");
        $finish;
    end
endmodule