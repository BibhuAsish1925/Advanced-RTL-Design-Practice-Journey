module key_reg_zeroize #(
  parameter int W = 128
)(
  input  logic         clk,
  input  logic         rst_n,        // Active-low reset
  input  logic         load,         // Load key when 1
  input  logic [W-1:0] key_in,
  input  logic         tamper,       // Asynchronous tamper signal
  input  logic         soft_zeroize, // Synchronous firmware wipe request
  output logic [W-1:0] key_out,
  output logic         parity_ok
);

  // Tamper is asynchronous; soft_zeroize is synchronous.
  wire async_zeroize = tamper;

  // Key storage
  always_ff @(posedge clk or negedge rst_n or posedge async_zeroize) begin
    if (!rst_n)
      key_out <= '0;
    else if (async_zeroize)
      key_out <= '0;
    else if (soft_zeroize)
      key_out <= '0;
    else if (load)
      key_out <= key_in;
  end

  // ---------------------------------------------------------
  // Parity integrity check
  // XOR reduction of every 8-bit lane.
  // parity_ok = 1 when the total number of 1s is even.
  // ---------------------------------------------------------

  generate
    if (W % 8 == 0) begin : gen_byte_parity

      logic [W/8-1:0] lane_parity;

      for (genvar i = 0; i < W/8; i++) begin : gen_lane
        assign lane_parity[i] = ^key_out[i*8 +: 8];
      end

      assign parity_ok = ~(^lane_parity);

    end
    else begin : gen_no_byte_parity
      assign parity_ok = 1'b0;
    end
  endgenerate

endmodule