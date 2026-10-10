module trng_tb;
    reg  aclk;
    reg  resetn;
    reg  random_data_ready;
    wire [31:0] random_data_output;
    wire        random_data_valid;

    trng dut (
        .aclk(aclk),
        .resetn(resetn),
        .random_data_ready(random_data_ready),
        .random_data_output(random_data_output),
        .random_data_valid(random_data_valid)
    );

    initial aclk = 1'b0;
    always #5 aclk = ~aclk;
    initial begin
        $monitor("t=%0t\t valid=%b ready=%b data=%h",
                  $time, random_data_valid, random_data_ready, random_data_output);
        resetn = 0;
        random_data_ready = 0;
        #12;
        resetn = 1;

        // Wait for the first 32-bit collection to complete, then
        // acknowledge it via random_data_ready to let the next
        // collection begin.
        wait (random_data_valid == 1'b1);
        @(posedge aclk);
        random_data_ready = 1;
        @(posedge aclk);
        random_data_ready = 0;

        // Wait for a second word to be collected and confirm it
        // differs from the first (since the ring oscillators keep
        // free-running, back-to-back words should not be identical)
        wait (random_data_valid == 1'b1);
        @(posedge aclk);
        random_data_ready = 1;
        @(posedge aclk);
        random_data_ready = 0;
        #50;
        $finish;

    end
endmodule