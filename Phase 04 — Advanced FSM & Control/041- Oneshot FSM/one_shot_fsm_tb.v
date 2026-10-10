module one_shot_fsm_tb;

        reg clk, reset;
        wire [3:0] state;
        wire out1, out2;

        one_shot_fsm dut (
          .clk(clk), .reset(reset),
          .state(state), .out1(out1), .out2(out2)
        );

        initial begin
          $monitor("t=%0t\t state=%b out1=%b out2=%b", $time, state, out1, out2);
          clk = 0;
          reset = 1;
          #10 reset = 0;
          #100 $finish;
        end

        always #5 clk = ~clk;

endmodule