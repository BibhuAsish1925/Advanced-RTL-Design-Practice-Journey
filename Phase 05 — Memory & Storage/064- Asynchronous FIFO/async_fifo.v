module async_fifo #( parameter WIDTH = 8, DEPTH = 16 )
 (
   // Write domain
   input                  wr_clk,
   input                  wr_rst_n,
   input                  wr_en,
   input      [WIDTH-1:0] wr_data,
   output                 full,

   // Read domain
   input                  rd_clk,
   input                  rd_rst_n,
   input                  rd_en,
   output reg [WIDTH-1:0] rd_data,
   output                 empty
 );

   localparam ADDR_WIDTH = $clog2(DEPTH);
   localparam PTR_WIDTH  = ADDR_WIDTH + 1; // extra MSB disambiguates full vs empty

   reg [WIDTH-1:0] mem [0:DEPTH-1];

   // ---------------- Write domain ----------------
   reg  [PTR_WIDTH-1:0] wr_bin, wr_gray;
   wire [PTR_WIDTH-1:0] wr_bin_next  = wr_bin + (wr_en && !full);
   wire [PTR_WIDTH-1:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;

   reg  [PTR_WIDTH-1:0] rd_gray_sync1, rd_gray_sync2; // read ptr synced into wr_clk domain
   reg                   full_reg;

   always @(posedge wr_clk or negedge wr_rst_n) begin
      if (!wr_rst_n) begin
         wr_bin        <= 0;
         wr_gray       <= 0;
         rd_gray_sync1 <= 0;
         rd_gray_sync2 <= 0;
         full_reg      <= 1'b0;
      end else begin
         wr_bin  <= wr_bin_next;
         wr_gray <= wr_gray_next;

         // 2-flop synchronizer for the read pointer's gray code
         rd_gray_sync1 <= rd_gray;
         rd_gray_sync2 <= rd_gray_sync1;

         if (wr_en && !full)
            mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;

         full_reg <= (wr_gray_next == {~rd_gray_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
                                         rd_gray_sync2[PTR_WIDTH-3:0]});
      end
   end
   assign full = full_reg;

   // ---------------- Read domain ----------------
   reg  [PTR_WIDTH-1:0] rd_bin, rd_gray;
   wire [PTR_WIDTH-1:0] rd_bin_next  = rd_bin + (rd_en && !empty);
   wire [PTR_WIDTH-1:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

   reg  [PTR_WIDTH-1:0] wr_gray_sync1, wr_gray_sync2; // write ptr synced into rd_clk domain
   reg                   empty_reg;

   always @(posedge rd_clk or negedge rd_rst_n) begin
      if (!rd_rst_n) begin
         rd_bin        <= 0;
         rd_gray       <= 0;
         wr_gray_sync1 <= 0;
         wr_gray_sync2 <= 0;
         empty_reg     <= 1'b1;
         rd_data       <= 0;
      end else begin
         rd_bin  <= rd_bin_next;
         rd_gray <= rd_gray_next;

         // 2-flop synchronizer for the write pointer's gray code
         wr_gray_sync1 <= wr_gray;
         wr_gray_sync2 <= wr_gray_sync1;

         if (rd_en && !empty)
            rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];

         empty_reg <= (rd_gray_next == wr_gray_sync2);
      end
   end
   assign empty = empty_reg;

endmodule