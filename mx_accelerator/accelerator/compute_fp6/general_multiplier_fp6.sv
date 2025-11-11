module general_multiplier_fp6
(
    input logic       [5:0] a, 
    input logic       [5:0] b,
    output wire logic [5:0] out
);

logic       a_sign;
logic [1:0] a_exponent;
logic [3:0] a_mantissa;

logic       b_sign;
logic [1:0] b_exponent;
logic [3:0] b_mantissa;

logic       o_sign;
logic [2:0] o_exponent;
logic [3:0] o_mantissa;

logic [7:0] product;

assign out = {o_sign, o_exponent[1:0], o_mantissa[2:0]};

logic      [2:0]  i_e;
logic      [7:0]  i_m;
wire logic [1:0]  o_e;
wire logic [2:0]  o_m;



mult_normalizer_fp6 norm1
(
    .in_e(i_e),
    .in_m(i_m),
    .out_e(o_e),
    .out_m(o_m)
);

// 7 + 7 = 14,,,,,, _ 1_ . 0_ 0_ 0_ 0_ 0_ 0_ _ _ _ _ _ _ _ _

always_comb
begin
    a_sign = a[5];
    a_mantissa = a[2:0];
    if(a[4:3] == 0) begin // Subnormal Numbers
        a_exponent = 2'b01;
        a_mantissa = {1'b0, a[2:0]};
    end else begin // Normal numbers
        a_exponent = a[4:3];
        a_mantissa = {1'b1, a[2:0]};
    end
end


always_comb
begin
    b_sign     = b[5];
    b_mantissa = b[2:0];
    if(b[4:3] == 0) begin // Subnormal Numbers
        b_exponent = 2'b01;
        b_mantissa = {1'b0, b[2:0]};
    end else begin // Normal numbers
        b_exponent = b[4:3];
        b_mantissa = {1'b1, b[2:0]};        
    end
end

always_comb
begin
    o_sign = a_sign ^ b_sign; //xor of signs
    if (a[4:3] ==0 | b[4:3] == 0) begin
        o_exponent = 0;
    end else begin        
        o_exponent = a_exponent + b_exponent - 2'd1; // Subtracting 1 to account for the 1.xxxxxx format
    end
    //o_exponent = (a_exponent + b_exponent) - 2'd1;
    product = a_mantissa * b_mantissa;
    //$display("a_mantissa = %h, b_mantissa = %h", a_mantissa, b_mantissa);
    //$display("b_exponent = %h", b_exponent);
    //$display("product = %h", product);
    //$display ("o_exponent = %h", o_exponent);
    ////$display("a = %h, b = %h", a, b);
    //$display("\n");

    // Normalization
    if(product[7] == 1 ) begin // fix // We have overflown so we need to adjust for it. So right shift once to bring significand back to 1.xxxx format and adjust the exponent accordingly.
        o_exponent = o_exponent + 1; // Counteracting with 2^1
        //$display("o_exponent inside overflow = %h", o_exponent);
        product = product >> 1; // Doing 2^-1
    end


    i_e = o_exponent;
    i_m = product;
    o_exponent = o_e;
    product[5:3] = o_m;
    //$display("i_e = %h, i_m = %h, o_m=%h, o_e =%h", i_e, i_m, o_m, o_e);
    //$display("\n");

    //if((o_exponent != 0)) begin
    //    i_e = o_exponent;
    //    i_m = product;
    //    o_exponent = o_e;
    //    product[5:3] = o_m;
    //    //$display("i_e = %h, i_m = %h, o_m=%h, o_e =%h", i_e, i_m, o_m, o_e);
    //    //$display("\n");
    //end
    //else begin
    //    i_e = 0;
    //    //i_m = 0;
    //    //o_exponent = 0;
    //    //product[5:3] = 0;
    //end

    if (o_m ==0) begin
        o_mantissa = 1;
    end else begin
        o_mantissa = product[5:3]; // See figure above for understanding
    end
    //$display("o_mantissa = %h", o_mantissa);
//
    //$display("\n");
end

endmodule