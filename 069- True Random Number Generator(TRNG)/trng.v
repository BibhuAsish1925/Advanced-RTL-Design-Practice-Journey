module trng (
    input  wire        aclk,
    input  wire        resetn,
    input  wire        random_data_ready,
    output reg  [31:0] random_data_output,
    output reg         random_data_valid
);

    (* dont_touch = "true" *) wire [4:0] ring_bits5; // ring oscillator signals (5-stage)
    (* dont_touch = "true" *) wire [2:0] ring_bits3; // ring oscillator signals (3-stage)

    wire random_bit5;
    wire random_bit3;

    reg [31:0] random_data_reg;
    reg [5:0]  bit_count;

    // Ring oscillator 5 stages
    // Explicit delays are required here: without them, this combinational
    // feedback loop has no propagation delay in simulation and will hang
    // the simulator in an infinite zero-time loop instead of oscillating.
    assign #1 ring_bits5[0] = ~ring_bits5[4];
    assign #1 ring_bits5[1] = ~ring_bits5[0];
    assign #1 ring_bits5[2] = ~ring_bits5[1];
    assign #1 ring_bits5[3] = ~ring_bits5[2];
    assign #1 ring_bits5[4] = ~ring_bits5[3];

    assign random_bit5 = ring_bits5[4];

    // Ring oscillator 3 stages
    assign #1 ring_bits3[0] = ~ring_bits3[2];
    assign #1 ring_bits3[1] = ~ring_bits3[0];
    assign #1 ring_bits3[2] = ~ring_bits3[1];

    assign random_bit3 = ring_bits3[2];

    // SIMULATION-ONLY: kick-start each ring so it doesn't stay stuck at X
    // forever. The forced seed must be held long enough for it to
    // propagate all the way around BOTH rings (5ns for the 5-stage ring,
    // 3ns for the 3-stage ring) before release, otherwise the far end of
    // the ring is still X at release time and immediately re-injects X
    // back into the loop the instant control is handed back. On real
    // silicon this isn't needed: thermal/electrical noise naturally
    // perturbs the loop into oscillation. This block is NOT synthesizable
    // and must be excluded from any synthesis run.
    // synthesis translate_off
    initial begin
        force ring_bits5[0] = 1'b0;
        force ring_bits3[0] = 1'b0;
        #10; // safely longer than either ring's full propagation lap
        release ring_bits5[0];
        release ring_bits3[0];
    end
    // synthesis translate_on

    // Random number generation logic (placeholder for actual TRNG logic)
    always @(posedge aclk) begin
      if (!resetn) begin
        random_data_reg <= 32'h0;
        bit_count <= 6'd0;
        random_data_valid <= 1'b0;
      end else begin
        if (bit_count == 6'd32) begin
          random_data_valid <= 1'b1; // Indicate that random data is ready after 32 bits
          random_data_output <= random_data_reg; // Output the generated random data
          bit_count <= (random_data_ready)? 6'd0: bit_count; // Reset bit count
        end
        else begin
          random_data_reg <= {random_data_reg[30:0], random_bit3^random_bit5}; // Shift in new random bit
          bit_count <= bit_count + 6'd1;
          random_data_valid <= 1'b0; // Data not ready until 32 bits are collected
        end 
      end
    end

endmodule