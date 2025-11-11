`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module general_multiplier
(
    input logic [15:0] a, 
    input logic [15:0] b,
    output logic [31:0] out
);

logic a_sign;
logic [7:0] a_exponent;
logic [7:0] a_mantissa;

logic b_sign;
logic [7:0] b_exponent;
logic [7:0] b_mantissa;

logic o_sign;
logic [9:0] o_exponent;
logic [22:0] o_mantissa;

logic [39:0] product;


logic [7:0] exp_diff;

assign out = {o_sign, o_exponent[7:0], o_mantissa};

// 7 + 7 = 14,,,,,, _ 1_ . 0_ 0_ 0_ 0_ 0_ 0_ _ _ _ _ _ _ _ _

always_comb
begin
    a_sign = a[15];
    if(a[14:7] == 0) begin // Subnormal Numbers
        a_exponent = 8'b1;
        a_mantissa = {1'b0, a[6:0]};
    end else begin // Normal numbers
        a_exponent = a[14:7];
        a_mantissa = {1'b1, a[6:0]};
    end

    b_sign = b[15];
    if(b[14:7] == 0) begin
        b_exponent = 8'b1;
        b_mantissa = {1'b0, b[6:0]};
    end else begin
        b_exponent = b[14:7];
        b_mantissa = {1'b1, b[6:0]};
    end

    o_sign = a_sign ^ b_sign; //xor of signs
    o_exponent = {2'b0, a_exponent} + {2'b0, b_exponent} - 8'd127;
    exp_diff= 8'd128 - (a_exponent + b_exponent); // extra factor of 1 to shift past implicit mantissa bit
    product = {{8'b0, a_mantissa} * {8'b0, b_mantissa}, {24{1'b0}}};

    // Normalization
    if(product[39] == 1 ) begin // fix // We have overflown so we need to adjust for it. So right shift once to bring significand back to 1.xxxx format and adjust the exponent accordingly.
        o_exponent = o_exponent + 1'b1; // Counteracting with 2^1
        exp_diff = exp_diff - 1'b1;
        product = product >> 1'b1; // Doing 2^-1
    end
    // if leading 0 need to renormalize
    else if (product[38] == 0) begin 
        if (product[37:31] == 7'b000001) begin
            exp_diff = exp_diff + 8'd7;
            o_exponent = o_exponent - 10'd7;
            product = product << 7;
        end else if (product[37:32] == 6'b000001) begin
            exp_diff = exp_diff + 8'd6;
            o_exponent = o_exponent - 10'd6;
            product = product << 6;
        end else if (product[37:33] == 5'b00001) begin
            exp_diff = exp_diff + 8'd5;
            o_exponent = o_exponent - 10'd5;
            product = product << 5;
        end else if (product[37:34] == 4'b0001) begin
            exp_diff = exp_diff + 8'd4;
            o_exponent = o_exponent - 10'd4;
            product = product << 4;
        end else if (product[37:35] == 3'b001) begin
            exp_diff = exp_diff + 8'd3;
            o_exponent = o_exponent - 10'd3;
            product = product << 3;
        end else if (product[37:36] == 2'b01) begin
            exp_diff = exp_diff + 8'd2;
            o_exponent = o_exponent - 10'd2;
            product = product << 2;
        end else if (product[37:37] == 1'b1) begin
            exp_diff = exp_diff + 8'd1;
            o_exponent = o_exponent - 10'd1;
            product = product << 1;
        end
    end

    if (o_exponent[9:8] == 2'b11) begin
        // underflow
        // check for subnormalization
        o_exponent = 10'd0;
        if (exp_diff > 8'd24)
            product = '0;
        else
            product = product >> exp_diff;
    end else if (o_exponent[9:8] == 2'b01) begin
        // overflow
        o_exponent = 10'd255;
        product = '0;
    end else if (o_exponent[7:0] == 8'd255) begin
        product = '0;
    end else if (o_exponent == 10'b0 && product[38] == 1) begin
        // we naturally ended with a subnormal number
        product = product >> 1;
    end

    if (product[14] == 1'b1 && product[13:0] == '0) begin
        if (product[15] != 1'b0)
            product = product + {24'b1, 15'b0};
    end else if (product[14] == 1'b1) begin
        product = product + {24'b1, 15'b0};
    end

    o_mantissa = {product[37:15]}; // See figure above for understanding
end

endmodule