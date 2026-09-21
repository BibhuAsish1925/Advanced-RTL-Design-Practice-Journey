`timescale 1ns / 1ps

// ================================================================
// SHA-256 single-block compression core
//
// Scope: computes SHA-256 over exactly ONE 512-bit (64-byte) block.
// The caller is responsible for message padding (append 0x80, zero
// pad, then the 64-bit big-endian bit-length) to build a full 64-byte
// block, exactly as the SHA-256 spec requires. Multi-block chaining
// (for messages longer than 55 bytes) is not implemented here - this
// covers the core compression function itself, the building block a
// larger multi-block core would call once per 512-bit chunk.
// ================================================================
module sha256_core (
    input  wire         clk,
    input  wire         reset,
    input  wire [7:0]   data_in,     // one message-block byte per cycle
    input  wire         data_valid,  // pulse with each valid data_in byte
    output reg  [255:0] hash_out,
    output reg           hash_valid
);

    // ---- Round constants K[0..63] (fractional parts of cube roots of
    // the first 64 primes) ----
    reg [31:0] K [0:63];
    initial begin
        K[0]=32'h428a2f98; K[1]=32'h71374491; K[2]=32'hb5c0fbcf; K[3]=32'he9b5dba5;
        K[4]=32'h3956c25b; K[5]=32'h59f111f1; K[6]=32'h923f82a4; K[7]=32'hab1c5ed5;
        K[8]=32'hd807aa98; K[9]=32'h12835b01; K[10]=32'h243185be; K[11]=32'h550c7dc3;
        K[12]=32'h72be5d74; K[13]=32'h80deb1fe; K[14]=32'h9bdc06a7; K[15]=32'hc19bf174;
        K[16]=32'he49b69c1; K[17]=32'hefbe4786; K[18]=32'h0fc19dc6; K[19]=32'h240ca1cc;
        K[20]=32'h2de92c6f; K[21]=32'h4a7484aa; K[22]=32'h5cb0a9dc; K[23]=32'h76f988da;
        K[24]=32'h983e5152; K[25]=32'ha831c66d; K[26]=32'hb00327c8; K[27]=32'hbf597fc7;
        K[28]=32'hc6e00bf3; K[29]=32'hd5a79147; K[30]=32'h06ca6351; K[31]=32'h14292967;
        K[32]=32'h27b70a85; K[33]=32'h2e1b2138; K[34]=32'h4d2c6dfc; K[35]=32'h53380d13;
        K[36]=32'h650a7354; K[37]=32'h766a0abb; K[38]=32'h81c2c92e; K[39]=32'h92722c85;
        K[40]=32'ha2bfe8a1; K[41]=32'ha81a664b; K[42]=32'hc24b8b70; K[43]=32'hc76c51a3;
        K[44]=32'hd192e819; K[45]=32'hd6990624; K[46]=32'hf40e3585; K[47]=32'h106aa070;
        K[48]=32'h19a4c116; K[49]=32'h1e376c08; K[50]=32'h2748774c; K[51]=32'h34b0bcb5;
        K[52]=32'h391c0cb3; K[53]=32'h4ed8aa4a; K[54]=32'h5b9cca4f; K[55]=32'h682e6ff3;
        K[56]=32'h748f82ee; K[57]=32'h78a5636f; K[58]=32'h84c87814; K[59]=32'h8cc70208;
        K[60]=32'h90befffa; K[61]=32'ha4506ceb; K[62]=32'hbef9a3f7; K[63]=32'hc67178f2;
    end

    localparam [255:0] H_INIT =
        256'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19;

    // Working registers a..h (32 bits each)
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] Hcur [0:7]; // running hash state for this block

    // Message schedule W[0..63]
    reg [31:0] W [0:63];
    reg [5:0]  byte_cnt;   // 0..63, counts bytes shifted into the block
    reg [5:0]  round;      // 0..63, compression round counter

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_EXPAND = 3'd2;
    localparam S_ROUND  = 3'd3;
    localparam S_FINAL  = 3'd4;

    reg [2:0] state;
    integer i;

    function [31:0] rotr;
        input [31:0] x;
        input [4:0]  n;
        begin
            rotr = (x >> n) | (x << (32 - n));
        end
    endfunction

    wire [31:0] s0_exp = rotr(W[byte_cnt-15], 7) ^ rotr(W[byte_cnt-15], 18) ^ (W[byte_cnt-15] >> 3);
    wire [31:0] s1_exp = rotr(W[byte_cnt-2], 17) ^ rotr(W[byte_cnt-2], 19) ^ (W[byte_cnt-2] >> 10);

    wire [31:0] S1   = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
    wire [31:0] chv  = (e & f) ^ (~e & g);
    wire [31:0] temp1 = h + S1 + chv + K[round] + W[round];
    wire [31:0] S0   = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
    wire [31:0] majv = (a & b) ^ (a & c) ^ (b & c);
    wire [31:0] temp2 = S0 + majv;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= S_IDLE;
            hash_valid <= 1'b0;
            hash_out   <= 256'h0;
            byte_cnt   <= 6'd0;
            {Hcur[0],Hcur[1],Hcur[2],Hcur[3],Hcur[4],Hcur[5],Hcur[6],Hcur[7]} <= H_INIT;
        end else begin
            hash_valid <= 1'b0;
            case (state)
                S_IDLE: begin
                    byte_cnt <= 6'd0;
                    if (data_valid) begin
                        // First byte of the block: pack big-endian into W[0]'s top byte
                        W[0][31:24] <= data_in;
                        byte_cnt    <= 6'd1;
                        state       <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    if (data_valid) begin
                        // byte_cnt (1..63) selects word index and byte lane,
                        // big-endian packing (MSB byte first within each word)
                        case (byte_cnt[1:0])
                            2'd0: W[byte_cnt[5:2]][31:24] <= data_in;
                            2'd1: W[byte_cnt[5:2]][23:16] <= data_in;
                            2'd2: W[byte_cnt[5:2]][15:8]  <= data_in;
                            2'd3: W[byte_cnt[5:2]][7:0]   <= data_in;
                        endcase
                        if (byte_cnt == 6'd63) begin
                            state <= S_EXPAND;
                            byte_cnt <= 6'd16;
                        end else begin
                            byte_cnt <= byte_cnt + 1'b1;
                        end
                    end
                end

                S_EXPAND: begin
                    // Expand W[16..63] one word per cycle
                    W[byte_cnt] <= W[byte_cnt-16] + s0_exp + W[byte_cnt-7] + s1_exp;
                    if (byte_cnt == 6'd63) begin
                        state <= S_ROUND;
                        round <= 6'd0;
                        a <= Hcur[0]; b <= Hcur[1]; c <= Hcur[2]; d <= Hcur[3];
                        e <= Hcur[4]; f <= Hcur[5]; g <= Hcur[6]; h <= Hcur[7];
                    end else begin
                        byte_cnt <= byte_cnt + 1'b1;
                    end
                end

                S_ROUND: begin
                    // One compression round per cycle, 64 rounds total
                    h <= g; g <= f; f <= e; e <= d + temp1;
                    d <= c; c <= b; b <= a; a <= temp1 + temp2;
                    if (round == 6'd63) begin
                        state <= S_FINAL;
                    end else begin
                        round <= round + 1'b1;
                    end
                end

                S_FINAL: begin
                    Hcur[0] <= Hcur[0] + a; Hcur[1] <= Hcur[1] + b;
                    Hcur[2] <= Hcur[2] + c; Hcur[3] <= Hcur[3] + d;
                    Hcur[4] <= Hcur[4] + e; Hcur[5] <= Hcur[5] + f;
                    Hcur[6] <= Hcur[6] + g; Hcur[7] <= Hcur[7] + h;
                    hash_out <= {Hcur[0]+a, Hcur[1]+b, Hcur[2]+c, Hcur[3]+d,
                                 Hcur[4]+e, Hcur[5]+f, Hcur[6]+g, Hcur[7]+h};
                    hash_valid <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule