module fifo_complex #(
  parameter DATA_WIDTH = 32,
  parameter DEPTH = 16,
  parameter ADDR_WIDTH = $clog2(DEPTH)
)(
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  wr_en,
  input  logic                  rd_en,
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out,
  output logic                  full,
  output logic                  empty,
  output logic                  almost_full,
  output logic                  almost_empty
);

  localparam AF_THRESHOLD = DEPTH - 2;
  localparam AE_THRESHOLD = 1;

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
  logic [ADDR_WIDTH:0]   count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0; rd_ptr <= 0; count <= 0;
    end else begin
      full  <= (count == DEPTH);
      empty <= (count == 0);
      almost_full  <= (count >= AF_THRESHOLD);
      almost_empty <= (count <= AE_THRESHOLD);

      // Gate on the ACTUAL current count, not the registered flags above,
      // so there's no 1-cycle-stale window that lets an invalid op through
      if (wr_en && (count != DEPTH) && rd_en && (count != 0)) begin
        mem[wr_ptr] <= data_in;
        wr_ptr <= wr_ptr + 1;
        data_out <= mem[rd_ptr];
        rd_ptr <= rd_ptr + 1;
      end else if (wr_en && (count != DEPTH)) begin
        mem[wr_ptr] <= data_in;
        wr_ptr <= wr_ptr + 1;
        count <= count + 1;
      end else if (rd_en && (count != 0)) begin
        data_out <= mem[rd_ptr];
        rd_ptr <= rd_ptr + 1;
        count <= count - 1;
      end
    end
  end

endmodule