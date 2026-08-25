module palindrome_number_tb;
  reg [7:0] num;
  wire is_palindrome;
  
  palindrome_number dut (
    .num(num),
    .is_palindrome(is_palindrome)
  );
  
  initial begin
    $monitor("t=%0t\t num=%0d (%b)\t is_palindrome=%b", $time, num, num, is_palindrome);

    // Test Case 1: Palindrome number
    num = 8'b01011010;  // 90 -> reversed 01011010 -> palindrome
    #10;
    
    // Test Case 2: Non-palindrome number
    num = 8'b11001010;  // 202 -> reversed 01010011 -> not palindrome
    #10;
    
    // Test Case 3: Single-digit number
    num = 8'b00001000;  // 8 -> reversed 00010000 -> not palindrome
    #10;
    
    // Test Case 4: Palindrome number with odd number of digits
    num = 8'b11100111;  // 231 -> reversed 11100111 -> palindrome
    #10;

    // Test Case 5: All zeros (edge case)
    num = 8'b00000000;  // 0 -> reversed 00000000 -> palindrome
    #10;

    // Test Case 6: All ones (edge case)
    num = 8'b11111111;  // 255 -> reversed 11111111 -> palindrome
    #10;

    // Test Case 7: Single bit set at MSB (asymmetric)
    num = 8'b10000000;  // 128 -> reversed 00000001 -> not palindrome
    #10;

    // Test Case 8: Single bit set at LSB (asymmetric)
    num = 8'b00000001;  // 1 -> reversed 10000000 -> not palindrome
    #10;

    // Test Case 9: Symmetric pattern (mirrored halves)
    num = 8'b10011001;  // 153 -> reversed 10011001 -> palindrome
    #10;

    // Test Case 10: Near-palindrome (off by one bit)
    num = 8'b10011000;  // 152 -> reversed 00011001 -> not palindrome
    #10;

    // Test Case 11: Alternating bits
    num = 8'b10101010;  // 170 -> reversed 01010101 -> not palindrome
    #10;

    // Test Case 12: Mid-value palindrome
    num = 8'b01100110;  // 102 -> reversed 01100110 -> palindrome
    #10;

    $finish;
  end
  
endmodule