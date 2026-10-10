module prime_number_detector_tb;
  reg [31:0] number;
  wire is_prime;

  prime_number_detector dut(.number(number), .is_prime(is_prime));

  initial begin
    // Test case 1: Prime number (13)
    number = 13;
    #10;
    
    // Test case 2: Non-prime number (20)
    number = 20;
    #10;

    // Test case 3: prime number (11)
    number = 11;
    #10;

    // Test case 4: non-prime number (18)
    number = 18;
    #10;

    // Add more test cases here

    $finish;
  end

  always @(number) begin
    $display("Number %d is %s", number, (is_prime) ? "prime" : "not prime");
  end
endmodule