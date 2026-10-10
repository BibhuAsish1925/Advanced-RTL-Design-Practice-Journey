`timescale 1ns / 1ps

module hamming_decoder(
    input [6:0] ham_data_encoder,
    output [3:0] data,
    output [2:0] error_position,
    output is_error
    ); 
    
    wire c1, c2, c3;
    wire [6:0] corrected;
    
    assign c1= ham_data_encoder[0]^ham_data_encoder[2]^ham_data_encoder[4]^ham_data_encoder[6]; // C1= 1 xor 3 xor 5 xor 7
     
    assign c2= ham_data_encoder[1]^ham_data_encoder[2]^ham_data_encoder[5]^ham_data_encoder[6]; // C2= 2 xor 3 xor 6 xor 7
    
    assign c3= ham_data_encoder[3]^ham_data_encoder[4]^ham_data_encoder[5]^ham_data_encoder[6]; // C3= 4 xor 5 xor 6 xor 7
    
    assign error_position= {c3,c2,c1};//position of error, 

    assign is_error = c3 |c2 | c1;//or (any '1'=>is_error=1)

    // Flip the single erroneous bit (identified by error_position,
    // 1-indexed) before extracting data, so single-bit errors are
    // actually CORRECTED, not just detected.
    assign corrected = ham_data_encoder ^ (is_error ? (7'b1 << (error_position - 1)) : 7'b0);

    assign data[0]= corrected[2];
    assign data[1]= corrected[4];
    assign data[2]= corrected[5];
    assign data[3]= corrected[6];
  
endmodule