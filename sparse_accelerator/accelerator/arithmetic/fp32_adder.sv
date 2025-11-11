`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module fp32_adder
(
    input logic [31:0] A, 
    input logic [31:0] B, 
    output logic [31:0] O
);

logic a_sign;
logic b_sign;

logic [7:0] a_exponent;
logic [23:0] a_mantissa; // plus one bit

logic [7:0] b_exponent; 
logic [23:0] b_mantissa; // plus one bit 

logic o_sign;
logic [7:0] o_exponent;
logic [22:0] o_mantissa;  // plus two bits

logic [31:0] adder_out;


assign a_sign = A[31];
assign a_exponent[7:0] = A[30:23];
assign a_mantissa[23:0] = {1'b1, A[22:0]};

assign b_sign = B[31];
assign b_exponent[7:0] = B[30:23];
assign b_mantissa[23:0] = {1'b1, B[22:0]};

general_adder gAdder (
    .a(A),
    .b(B),
    .out(adder_out)
);

//covers corner cases and uses general adder logic
always_comb
begin
    //a is NaN or b is zero return a
    if ((a_exponent == 8'd255 && a_mantissa[22:0] != '0) || (B[30:0] == '0)) begin
        o_sign = a_sign;
        o_exponent = a_exponent;
        o_mantissa = a_mantissa[22:0];
    //b is NaN or a is zero return b
    end else if ((b_exponent == 8'd255 && b_mantissa[22:0] != '0) || (A[30:0] == '0)) begin
        o_sign = b_sign;
        o_exponent = b_exponent;
        o_mantissa = b_mantissa[22:0];
    //a and b is inf return inf
    end else if ((a_exponent == 255) || (b_exponent == 255)) begin
        // +inf + -inf = NaN
        if (a_sign == b_sign) begin
            o_sign = a_sign;
            o_mantissa = '0;
        end else begin
            o_sign = 1'b0;
            o_mantissa = '1;   
        end
        o_exponent = 8'd255;
    end else begin // Passed all corner cases
        o_sign = adder_out[31];
        o_exponent = adder_out[30:23];
        o_mantissa = adder_out[22:0];
    end
    O = {o_sign, o_exponent, o_mantissa[22:0]};
end  



endmodule