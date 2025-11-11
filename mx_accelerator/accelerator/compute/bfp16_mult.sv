`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////
// BFP16 Multiplier 

// https://github.com/danshanley/FPU/blob/master/fpu.v
// with slight modifications to turn FP32 to BFP16
// for area approximation

// Format: 1-bit signed, 8-bit exponents, 7-bit fractions

// NOTE: MORE VERIFICATION NEEDED
/////////////////////////////////////////////////////////////

module bfp16_mult
(
    input logic [15:0] A, B, 
    output wire logic [15:0] O // To overload default net in SV
);

    wire logic a_sign;
    wire logic b_sign;

    wire logic [7:0] a_exponent;
    wire logic [7:0] a_mantissa;

    wire logic [7:0] b_exponent;
    wire logic [7:0] b_mantissa;

    logic o_sign;
    logic [7:0]  o_exponent;
    logic [8:0]  o_mantissa;

    wire logic [15:0] multiplier_out;

    assign a_sign = A[15]; // Sign bit in MSB
    assign a_exponent[7:0] = A[14:7]; // 8-bit exponent in bfloat16
    assign a_mantissa[7:0] = {1'b1, A[6:0]}; // Adding one for the 1.xxxxxx in the mantissa (7-bit mantissa +1-bit)

    assign b_sign = B[15];
    assign b_exponent[7:0] = B[14:7];
    assign b_mantissa[7:0] = {1'b1, B[6:0]};

    general_multiplier M1 
    (
    .a(A),
    .b(B),
    .out(multiplier_out));

    always_comb 
    begin: mult_corner_case // If else causes long combinational chains, can consider using case statements
        //a or b is NaN return NaN
        if ((a_exponent == 255 && a_mantissa != 0) || 
            (b_exponent == 255 && b_mantissa != 0)) 
        begin
            o_sign = a_sign;
            o_exponent = 255;
            o_mantissa = a_mantissa | b_mantissa;
        end
        //a or b is 0 return 0
        else if ((a_exponent == 0) && (a_mantissa == 0) || 
                 (b_exponent == 0) && (b_mantissa == 0)) 
        begin
            o_sign = a_sign ^ b_sign;
            o_exponent = 0;
            o_mantissa = 0;
        //a or b is inf return inf
        end 
        else if ((a_exponent == 255) || (b_exponent == 255)) 
        begin
            o_sign = a_sign;
            o_exponent = 255;
            o_mantissa = 0;
        end
        // Why is this condition needed ?
        else if (A == 'd0 && B == 'd0) 
        begin
            o_sign = 0;
            o_exponent = 0;
            o_mantissa = 0;
        end 
        else 
        begin // Passed all corner cases
            o_sign = multiplier_out[15];
            o_exponent = multiplier_out[14:7];
            o_mantissa = multiplier_out[6:0]; 
        end 
        
    end: mult_corner_case

    assign O ={o_sign, o_exponent, o_mantissa[6:0]};

endmodule
