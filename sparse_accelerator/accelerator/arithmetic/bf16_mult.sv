`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module bfp16_mult
(
    input logic [15:0] A,
    input logic [15:0] B, 
    output logic [31:0] O
);

    logic a_sign;
    logic b_sign;

    logic [7:0] a_exponent;
    logic [6:0] a_mantissa;

    logic [7:0] b_exponent;
    logic [6:0] b_mantissa;

    logic o_sign;
    logic [7:0]  o_exponent;
    logic [22:0]  o_mantissa;

    logic [31:0] multiplier_out;

    assign a_sign = A[15]; // Sign bit in MSB
    assign a_exponent = A[14:7]; // 8-bit exponent in bfloat16
    assign a_mantissa = A[6:0];

    assign b_sign = B[15];
    assign b_exponent = B[14:7];
    assign b_mantissa = B[6:0];

    general_multiplier M1(
        .a(A),
        .b(B),
        .out(multiplier_out)
    );

    always_comb 
    begin: mult_corner_case // If else causes long combinational chains, can consider using case statements
        //a or b is NaN return NaN
        // assume NaN * inf = NaN
        if ((a_exponent == 8'd255 && a_mantissa != 0) || 
            (b_exponent == 8'd255 && b_mantissa != 0)) 
        begin
            o_sign = '0;
            o_exponent = 8'd255;
            o_mantissa = 23'd8388607;
        end
        // inf * 0 is nan
        else if ((a_exponent == 8'd255 && b_exponent == 0 && b_mantissa == 0) ||
                 (b_exponent == 8'd255 && a_exponent == 0 && a_mantissa == 0) )
        begin
            o_sign = '0;
            o_exponent = 8'd255;
            o_mantissa = 23'd8388607;
        end
        // 0 * 0 is 0
        else if ((a_exponent == 0 && a_mantissa == 0) || 
                 (b_exponent == 0 && b_mantissa == 0)) 
        begin
            o_sign = a_sign ^ b_sign;
            o_exponent = '0;
            o_mantissa = '0;
        //a or b is inf return inf
        end 
        else if ((a_exponent == 8'd255) || (b_exponent == 8'd255)) 
        begin
            o_sign = a_sign ^ b_sign;
            o_exponent = 8'd255;
            o_mantissa = '0;
        end
        else 
        begin 
            o_sign = multiplier_out[31];
            o_exponent = multiplier_out[30:23];
            o_mantissa = multiplier_out[22:0]; 
        end 
        
    end: mult_corner_case

    assign O ={o_sign, o_exponent, o_mantissa};

endmodule