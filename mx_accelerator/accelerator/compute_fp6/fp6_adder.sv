module fp6_adder
(
    input logic [5:0] A, 
    input logic [5:0] B, 
    output logic [5:0] O
);

wire logic a_sign;
wire logic b_sign;

wire logic [1:0] a_exponent;
wire logic [3:0] a_mantissa; // plus one bit

wire logic [1:0] b_exponent; 
wire logic [3:0] b_mantissa; // plus one bit 

logic o_sign;
logic [1:0] o_exponent;
logic [3:0] o_mantissa;  // plus two bits

wire logic [5:0] adder_out;


assign a_sign = A[5];
assign a_exponent[1:0] = A[4:3];
assign a_mantissa[3:0] = {1'b1, A[2:0]};

assign a_sign = A[5];
assign a_exponent[1:0] = A[4:3];
assign a_mantissa[3:0] = {1'b1, A[2:0]};


general_adder_fp6 gAdder (
    .a(A),
    .b(B),
    .out(adder_out)
);

//covers corner cases and uses general adder logic
always_comb
begin
    //a is NaN or b is zero return a
    if ( (b_exponent == 0) && (b_mantissa == 0)) begin
        o_sign = a_sign;
        o_exponent = a_exponent;
        o_mantissa = a_mantissa;
        O = {o_sign, o_exponent, o_mantissa[2:0]};
        //b is NaN or a is zero return b
    end else if ( (a_exponent == 0) && (a_mantissa == 0)) begin
        o_sign = b_sign;
        o_exponent = b_exponent;
        o_mantissa = b_mantissa;
        O = {o_sign, o_exponent, o_mantissa[2:0]};
        //a and b is inf return inf
    //end else if ((a_exponent == 255) || (b_exponent == 255)) begin
    //    o_sign = a_sign ^ b_sign;
    //    o_exponent = 255;
    //    o_mantissa = 0;
    //    O = {o_sign, o_exponent, o_mantissa[22:0]};
    end else begin // Passed all corner cases
        //adder_a_in = A;
        //adder_b_in = B;
        o_sign = adder_out[5];
        o_exponent = adder_out[4:3];
        o_mantissa = adder_out[2:0];
        O = {o_sign, o_exponent, o_mantissa[2:0]};
        //$display("A = %h, B = %h, adder_out = %h", A, B, adder_out);
    end
end  

endmodule