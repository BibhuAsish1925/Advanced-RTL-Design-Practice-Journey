module pwm #(
    parameter int COUNTER_WIDTH = 8
)(
    input  logic                     clk,
    input  logic                     rst,
    input  logic [COUNTER_WIDTH-1:0] duty_cycle,
    output logic                     pwm_out
);
    logic [COUNTER_WIDTH-1:0] counter;
    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= '0;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end
    always_comb begin
        if (rst)
            pwm_out = 1'b0;
        else
            pwm_out = (counter < duty_cycle);
    end
endmodule