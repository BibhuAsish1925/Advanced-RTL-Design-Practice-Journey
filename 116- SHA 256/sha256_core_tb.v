`timescale 1ns / 1ps

module sha256_core_tb;

    reg clk, reset, data_valid;
    reg [7:0] data_in;
    wire [255:0] hash_out;
    wire hash_valid;

    sha256_core dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_valid(data_valid),
        .hash_out(hash_out),
        .hash_valid(hash_valid)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Pre-padded 64-byte block for SHA-256("abc"), Python-verified:
    // 61626380 00000000 ... 00000000 00000018
    // Expected result: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
    reg [7:0] block [0:63];
    integer i;

    initial begin
        block[0]=8'h61; block[1]=8'h62; block[2]=8'h63; block[3]=8'h80;
        for (i = 4; i < 62; i = i + 1) block[i] = 8'h00;
        block[62]=8'h00; block[63]=8'h18;

        $monitor("t=%0t\t state=%0d hash_valid=%b hash_out=%h", $time, dut.state, hash_valid, hash_out);

        reset = 1; data_valid = 0; data_in = 0;
        #12; reset = 0;

        // Feed the 64-byte pre-padded block in, one byte per clock
        for (i = 0; i < 64; i = i + 1) begin
            @(negedge clk);
            data_in    = block[i];
            data_valid = 1'b1;
        end
        @(negedge clk);
        data_valid = 0;

        wait (hash_valid == 1'b1);
        #1;

        if (hash_out !== 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad)
            $display("FAIL: hash_out = %h, expected ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", hash_out);
        else
            $display("PASS: SHA-256(\"abc\") correctly computed as %h", hash_out);

        #20;
        $finish;
    end

endmodule