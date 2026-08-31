module async_fifo_tb;

    parameter WIDTH = 8;
    parameter DEPTH = 16;

    reg  wr_clk, wr_rst_n, wr_en;
    reg  [WIDTH-1:0] wr_data;
    wire full;

    reg  rd_clk, rd_rst_n, rd_en;
    wire [WIDTH-1:0] rd_data;
    wire empty;

    async_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n), .wr_en(wr_en),
        .wr_data(wr_data), .full(full),
        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n), .rd_en(rd_en),
        .rd_data(rd_data), .empty(empty)
    );

    // Two independent, genuinely asynchronous clocks
    initial wr_clk = 1'b0;
    always #5 wr_clk = ~wr_clk;   // 10ns period

    initial rd_clk = 1'b0;
    always #7 rd_clk = ~rd_clk;   // 14ns period

    integer i;

    initial begin
        $monitor("t=%0t\t wr_en=%b wdata=%h full=%b | rd_en=%b rdata=%h empty=%b",
                  $time, wr_en, wr_data, full, rd_en, rd_data, empty);

        wr_rst_n = 0; wr_en = 0; wr_data = 0;
        rd_rst_n = 0; rd_en = 0;
        #20;
        wr_rst_n = 1;
        rd_rst_n = 1;
        #10;

        // Fill phase: write DEPTH items back-to-back on wr_clk
        wr_en = 1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            wr_data = i;
            @(posedge wr_clk);
        end
        wr_en = 0;

        // Let the write pointer propagate across the CDC synchronizer
        #50;

        // Drain phase: read DEPTH items back on the independent rd_clk
        rd_en = 1;
        repeat (DEPTH) @(posedge rd_clk);
        rd_en = 0;

        #40;
        $finish;
    end

endmodule