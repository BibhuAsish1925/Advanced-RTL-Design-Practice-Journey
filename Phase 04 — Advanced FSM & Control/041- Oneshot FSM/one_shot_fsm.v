module one_shot_fsm (
  input clk, reset,
  output reg [3:0] state,
  output reg out1, out2
);

// Define states as one hot encoding
parameter [3:0] IDLE = 4'b0001;
parameter [3:0] STATE1 = 4'b0010;
parameter [3:0] STATE2 = 4'b0100;
parameter [3:0] STATE3 = 4'b1000;

// Sequential state register
always @(posedge clk, posedge reset) begin
  if (reset)
    state <= IDLE;
  else
    case(state)
      IDLE:    state <= STATE1;
      STATE1:  state <= STATE2;
      STATE2:  state <= STATE3;
      STATE3:  state <= IDLE;
      default: state <= IDLE;
    endcase
end

// Combinational Moore output decode - aligned with CURRENT state
always @(*) begin
  case(state)
    IDLE:    begin out1 = 1'b0; out2 = 1'b0; end
    STATE1:  begin out1 = 1'b1; out2 = 1'b0; end
    STATE2:  begin out1 = 1'b0; out2 = 1'b1; end
    STATE3:  begin out1 = 1'b1; out2 = 1'b1; end
    default: begin out1 = 1'b0; out2 = 1'b0; end
  endcase
end

endmodule




/*

            +-----+      1      +-------+
            |     |------------>|STATE1 |
            | IDLE|      0      |       |
            |     |<------------|       |
            +-----+             +-------+
              |                   | 1
              | 0                 |
              |                   |
            +-----+      1      +-------+
            |     |------------>|STATE2 |
            |     |      0      |       |
            |     |<------------|       |
            +-----+             +-------+
              |                   | 1
              | 0                 |
              |                   |
            +-----+      1      +-------+
            |     |------------>|STATE3 |
            |     |      0      |       |
            |     |<------------|       |
            +-----+             +-------+
              |                   | 1
              | 0                 |
              |                   |
            +-----+      1      +-----+
            |     |------------>|IDLE |
            |     |      0      |     |
            |     |<------------|     |
            +-----+             +-----+
*/