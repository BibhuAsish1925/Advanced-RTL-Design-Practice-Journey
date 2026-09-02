module sine_wave_generator_tb;
    parameter int PHASE_WIDTH = 8;
    parameter int OUTPUT_WIDTH = 8;
    logic clk;
    logic rst;
    logic [PHASE_WIDTH-1:0] phase_step;
    logic signed [OUTPUT_WIDTH-1:0] sine_out;
    sine_wave_generator #(
        .PHASE_WIDTH(PHASE_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .phase_step (phase_step),
        .sine_out   (sine_out)
    );
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    initial begin
        rst = 1'b1;
        // Phase increment
        phase_step = 8'd16;
        repeat (2)
            @(posedge clk);
        rst = 1'b0;
        $display("--------------------------------");
        $display("SINE WAVE GENERATOR");
        $display("--------------------------------");
        $display("Time\tPhase\tSine");
        repeat (64) begin
            @(posedge clk);
            #1; // let non-blocking updates commit before sampling
            $display(
                "%0t\t%0d\t%0d",
                $time,
                dut.phase_acc,
                sine_out
            );
        end
        $display("--------------------------------");
        $display("SINE WAVE TEST COMPLETED");
        $display("--------------------------------");
        $finish;
    end
endmodule