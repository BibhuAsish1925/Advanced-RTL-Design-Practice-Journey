module apb_firewall #(
  parameter logic [31:0] ALLOW_BASE = 32'h4000_0000,
  parameter logic [31:0] ALLOW_END  = 32'h4000_FFFF
)(
  input  logic        PCLK,
  input  logic        PRESETn,
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic        PWRITE,
  input  logic [31:0] PADDR,
  input  logic [31:0] PWDATA,

  output logic [31:0] PRDATA,
  output logic        PREADY,
  output logic        PSLVERR,

  // Downstream interface
  output logic        M_PSEL,
  output logic        M_PENABLE,
  output logic        M_PWRITE,
  output logic [31:0] M_PADDR,
  output logic [31:0] M_PWDATA,

  input  logic [31:0] M_PRDATA,
  input logic        M_PREADY,
  input logic        M_PSLVERR
);

  // ---------------------------------------------------------
  // Address permission check
  // ---------------------------------------------------------

  logic addr_allowed;

  assign addr_allowed =
      (PADDR >= ALLOW_BASE) &&
      (PADDR <= ALLOW_END);

  // ---------------------------------------------------------
  // Downstream APB signals
  // ---------------------------------------------------------

  assign M_PSEL    = PSEL && addr_allowed;
  assign M_PENABLE = PENABLE && addr_allowed;
  assign M_PWRITE  = PWRITE;
  assign M_PADDR   = PADDR;
  assign M_PWDATA  = PWDATA;

  // ---------------------------------------------------------
  // Response generation
  // ---------------------------------------------------------

  // Allowed transaction:
  //   Pass response from protected slave.
  //
  // Blocked transaction:
  //   Return immediately with error.
  // ---------------------------------------------------------

  assign PREADY  = addr_allowed ? M_PREADY : 1'b1;

  assign PRDATA  = addr_allowed ? M_PRDATA : 32'hDEAD_DEAD;

  assign PSLVERR = PRESETn &&
                   PSEL &&
                   PENABLE &&
                   !addr_allowed;

endmodule