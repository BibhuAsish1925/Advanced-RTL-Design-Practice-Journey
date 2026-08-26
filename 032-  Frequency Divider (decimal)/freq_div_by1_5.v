module mod_3_counter
       (input clk,reset, output reg [1:0] counter);
        
        always@(posedge clk)
        begin
            if(reset)
            counter <= 0;
            else
                if(counter == 2)
                counter <= 0;
                else
                counter <= counter + 1;
         end        
endmodule

module D_flipflop(
    input clk, reset, d,
    output reg Q
    );
    
    always@(posedge clk)
          begin
            if({reset})
                Q<= 1'b0;
            else 
                Q <= d;
            end
endmodule

module freq_div_by3(
    input clk, reset,
    output clk_by3
    );
    wire[1:0] q;
    wire temp; 
    
    mod_3_counter M3C(clk, reset, q);
    
    D_flipflop D(~clk, reset, q[1], temp);
    
    or(clk_by3, q[1], temp);
    
endmodule

module dual_edge_trig_ff(
    input clk, reset, d,
    output q
    );
    reg q1, q2;
    
    assign q = clk ? q1 : q2;
    
    always@ (posedge clk)
        begin
            if(reset) q1<= 1'b0;
            else q1 <= d;
        end
    
    always@ (negedge clk)
        begin
            if(reset) q2<= 1'b0;
            else q2 <= d; 
        end
endmodule

module freq_div_by1_5(
    input clk, reset,
    output new_clk
    );
    wire t1, t2;
    
    freq_div_by3 FD3(clk, reset, t1);
    
    dual_edge_trig_ff DETF(clk, reset, t1, t2);
    
    xor(new_clk, t1, t2);
endmodule