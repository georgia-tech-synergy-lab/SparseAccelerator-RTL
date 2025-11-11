//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////
// FP6 Multiplier 

// https://github.com/danshanley/FPU/blob/master/fpu.v
// with slight modifications to turn FP32 to BFP16
// for area approximation

// Format: 1-bit signed, 8-bit exponents, 7-bit fractions

// NOTE: MORE VERIFICATION NEEDED
/////////////////////////////////////////////////////////////

module fp6_mult
(
    input logic [5:0] A, B, 
    output wire logic [5:0] O // To overload default net in SV
);

    wire logic a_sign;
    wire logic b_sign;

    wire logic [1:0] a_exponent;
    wire logic [3:0] a_mantissa;

    wire logic [1:0] b_exponent;
    wire logic [3:0] b_mantissa;

        
    logic o_sign;
    logic [1:0]  o_exponent;
    logic [3:0]  o_mantissa;

    wire logic [5:0] multiplier_out;

    assign a_sign = A[5]; // Sign bit in MSB
    assign a_exponent[1:0] = A[4:3]; // 2-bit exponent in FP6
    assign a_mantissa[3:0] = {1'b1, A[2:0]}; // Adding one for the 1.xxxxxx in the mantissa (7-bit mantissa +1-bit)

    assign b_sign = B[5];
    assign b_exponent[1:0] = B[4:3];
    assign b_mantissa[3:0] = {1'b1, B[2:0]};

    general_multiplier_fp6 M1 
    (
    .a(A),
    .b(B),
    .out(multiplier_out));

    always_comb 
    begin: mult_corner_case // If else causes long combinational chains, can consider using case statements
        ////a or b is NaN return NaN
        //if ((a_exponent == 255 && a_mantissa != 0) || 
        //    (b_exponent == 255 && b_mantissa != 0)) 
        //begin
        //    o_sign = a_sign;
        //    o_exponent = 255;
        //    o_mantissa = a_mantissa | b_mantissa;
        //end
        //a or b is 0 return 0
        if ((a_exponent == 0) && (a_mantissa == 0) || 
                 (b_exponent == 0) && (b_mantissa == 0)) 
        begin
            o_sign = a_sign ^ b_sign;
            o_exponent = 0;
            o_mantissa = 0;
        //a or b is inf return inf
        end 
        //else if ((a_exponent == 255) || (b_exponent == 255)) 
        //begin
        //    o_sign = a_sign;
        //    o_exponent = 255;
        //    o_mantissa = 0;
        //end
        // Why is this condition needed ?
        else if (A == 'd0 && B == 'd0) 
        begin
            o_sign = 0;
            o_exponent = 0;
            o_mantissa = 0;
        end 
        else 
        begin // Passed all corner cases
            o_sign = multiplier_out[5];
            o_exponent = multiplier_out[4:3];
            o_mantissa = multiplier_out[2:0]; 
        end 
        
    end: mult_corner_case

    assign O ={o_sign, o_exponent, o_mantissa[2:0]};

endmodule