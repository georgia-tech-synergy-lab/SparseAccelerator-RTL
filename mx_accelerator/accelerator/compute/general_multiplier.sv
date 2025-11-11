module general_multiplier
(
    input logic [15:0] a, 
    input logic [15:0] b,
    output wire logic [15:0] out
);

logic a_sign;
logic [7:0] a_exponent;
logic [7:0] a_mantissa;

logic b_sign;
logic [7:0] b_exponent;
logic [7:0] b_mantissa;

logic o_sign;
logic [8:0] o_exponent;
logic [8:0] o_mantissa;

logic [15:0] product;

assign out = {o_sign, o_exponent[7:0], o_mantissa[6:0]};

logic  [8:0] i_e;
logic  [15:0] i_m;
wire logic [7:0] o_e;
wire logic [6:0] o_m;

mult_normalizer norm1
(
    .in_e(i_e),
    .in_m(i_m),
    .out_e(o_e),
    .out_m(o_m)
);

// 7 + 7 = 14,,,,,, _ 1_ . 0_ 0_ 0_ 0_ 0_ 0_ _ _ _ _ _ _ _ _

always_comb
begin
    a_sign = a[15];
    if(a[14:7] == 0) begin // Subnormal Numbers
        a_exponent = 8'b00000001;
        a_mantissa = {1'b0, a[6:0]};
    end else begin // Normal numbers
        a_exponent = a[14:7];
        a_mantissa = {1'b1, a[6:0]};
    end
end


always_comb
begin
    b_sign = b[15];
    if(b[14:7] == 0) begin
        b_exponent = 8'b00000001;
        b_mantissa = {1'b0, b[6:0]};
    end else begin
        b_exponent = b[14:7];
        b_mantissa = {1'b1, b[6:0]};
    end
end

always_comb
begin
    o_sign = a_sign ^ b_sign; //xor of signs
    o_exponent = (a_exponent + b_exponent) - 8'd127;
    product = a_mantissa * b_mantissa;

    // Normalization
    if(product[15] == 1 ) begin // fix // We have overflown so we need to adjust for it. So right shift once to bring significand back to 1.xxxx format and adjust the exponent accordingly.
        o_exponent = o_exponent + 1; // Counteracting with 2^1
        product = product >> 1; // Doing 2^-1
    end

    if((o_exponent != 0)) begin
        i_e = o_exponent;
        i_m = product;
        o_exponent = o_e;
        product[14:8] = o_m;
    end
    else begin
        i_e = 9'b0;
        i_m = 16'b0;
        o_exponent = 0;
        product[14:8] = 0;
    end

    o_mantissa = product[14:8]; // See figure above for understanding
end

endmodule