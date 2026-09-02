module pwm_tb;
    parameter int COUNTER_WIDTH = 8;
    logic clk;
    logic rst;
    logic [COUNTER_WIDTH-1:0] duty_cycle;
    logic pwm_out;
    pwm #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .duty_cycle (duty_cycle),
        .pwm_out    (pwm_out)
    );
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    task automatic test_duty_cycle(
        input logic [COUNTER_WIDTH-1:0] duty
    );
        integer high_count;
        integer total_count;
        begin
            duty_cycle = duty;
            high_count = 0;
            total_count = 0;
            // Allow counter to start from zero
            @(negedge clk);
            // Measure one complete PWM period
            repeat (256) begin
                @(posedge clk);
                #1; // let counter/pwm_out fully settle before sampling
                if (pwm_out)
                    high_count++;
                total_count++;
            end
            $display(
                "Duty Setting = %0d | HIGH Cycles = %0d | Total = %0d",
                duty,
                high_count,
                total_count
            );
        end
    endtask
    initial begin
        rst = 1'b1;
        duty_cycle = 8'd0;
        repeat (2)
            @(posedge clk);
        rst = 1'b0;
        // 25%
        test_duty_cycle(8'd64);
        // 50%
        test_duty_cycle(8'd128);
        // 75%
        test_duty_cycle(8'd192);
        $display("--------------------------------");
        $display("PWM TEST COMPLETED");
        $display("--------------------------------");
        $finish;
    end
endmodule