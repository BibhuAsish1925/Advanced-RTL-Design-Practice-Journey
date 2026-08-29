module Rom_Using_Case_tb;
    reg [2:0]addr;
    reg r_en;
    reg chip_en;
    wire [7:0]data_F1;
    wire [7:0]data_F2;
    wire [7:0]data_F3;
    wire [7:0]data_F4;

    Rom_Using_Case uut0(.address(addr),
                        .read_en(r_en),
                        .ce(chip_en),
                        .data_F1(data_F1),
                        .data_F2(data_F2),
                        .data_F3(data_F3),
                        .data_F4(data_F4)                     
                            );                  
    initial
    begin
            $monitor("t=%0t\t chip_en=%b r_en=%b addr=%b | F1=%0d F2=%0d F3=%0d F4=%0d",
                      $time, chip_en, r_en, addr, data_F1, data_F2, data_F3, data_F4);
            r_en=0;
            addr=3'bx;
            chip_en=0;
        #20;
            r_en=1;
            addr=3'b000;
            chip_en=1;
        #20;
            addr=3'b001;
        #20;
            addr=3'b010;
        #20;
            addr=3'b011;
        #20;
            addr=3'b100;
        #20;
            addr=3'b101;
        #20;
            addr=3'b110;
        #20;
            addr=3'b111;
            $finish;
    end

endmodule