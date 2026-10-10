module sync_fifo_tb;

    parameter WIDTH = 8;
    parameter DEPTH = 16;

    reg clk, rst, wr_en, rd_en;
    reg [WIDTH-1:0] wr_data;
    wire [WIDTH-1:0] rd_data;
    wire empty, full;

    sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst(rst),
        .wr_en(wr_en), .rd_en(rd_en),
        .wr_data(wr_data), .rd_data(rd_data),
        .empty(empty), .full(full)
    );

    always #5 clk = ~clk;

    integer i;

    initial begin
        $monitor("t=%0t\t wr=%b rd=%b wdata=%h rdata=%h num_items=%0d full=%b empty=%b",
                  $time, wr_en, rd_en, wr_data, rd_data, dut.num_items, full, empty);

        clk = 0; rst = 1; wr_en = 0; rd_en = 0; wr_data = 0;
        #12; rst = 0;

        // Fill the FIFO completely
        wr_en = 1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            wr_data = i;
            @(posedge clk);
        end
        wr_en = 0;
        @(posedge clk);

        // Simultaneous read+write test: num_items must stay stable
        wr_en = 1; rd_en = 1; wr_data = 8'hAA;
        repeat (4) @(posedge clk);
        wr_en = 0; rd_en = 0;
        @(posedge clk);

        // Drain the rest
        rd_en = 1;
        repeat (DEPTH) @(posedge clk);
        rd_en = 0;

        #20;
        $finish;
    end

endmodule