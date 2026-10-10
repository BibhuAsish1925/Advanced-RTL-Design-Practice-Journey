//============================================================
// 32 x 8 SYNCHRONOUS FIFO
//============================================================

module fifo #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH      = 32
)(
  input  logic                  clock,
  input  logic                  rst,

  input  logic                  rd,
  input  logic                  wr,

  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out,

  output logic                  full,
  output logic                  empty
);

  localparam ADDR_WIDTH = $clog2(DEPTH);

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  logic [ADDR_WIDTH-1:0] wr_ptr;
  logic [ADDR_WIDTH-1:0] rd_ptr;

  logic [$clog2(DEPTH+1)-1:0] count;

  integer i;


  //==========================================================
  // FIFO Logic
  //==========================================================

  always_ff @(posedge clock) begin

    if (rst) begin

      wr_ptr   <= '0;
      rd_ptr   <= '0;
      count    <= '0;
      data_out <= '0;

      for (i = 0; i < DEPTH; i = i + 1)
        mem[i] <= '0;

    end

    else begin

      // WRITE
      if (wr && !full) begin

        mem[wr_ptr] <= data_in;
        wr_ptr      <= wr_ptr + 1'b1;

      end


      // READ
      if (rd && !empty) begin

        data_out <= mem[rd_ptr];
        rd_ptr   <= rd_ptr + 1'b1;

      end


      // COUNT UPDATE
      case ({wr && !full, rd && !empty})

        2'b10:
          count <= count + 1'b1;

        2'b01:
          count <= count - 1'b1;

        default:
          count <= count;

      endcase

    end

  end


  //==========================================================
  // Status Flags
  //==========================================================

  assign empty = (count == 0);

  assign full  = (count == DEPTH);

endmodule