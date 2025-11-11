//general adder logic whenever the inputs change
module general_adder
(
    input logic [31:0] a, 
    input logic [15:0] b, 
    output wire logic [31:0] out
);

// wire logic [31:0] out;

logic a_sign;
logic b_sign;
logic [7:0] a_exponent;
logic [7:0] b_exponent;
logic [23:0] a_mantissa;
logic [23:0] b_mantissa;   

logic o_sign;
logic [7:0] o_exponent;
logic [24:0] o_mantissa; 


logic [7:0] i_e;
logic [23:0] i_m;
wire logic [7:0] o_e;
wire logic [24:0] o_m;


addition_normalizer norm1(
    .in_e(i_e),
    .in_m(i_m),
    .out_e(o_e),
    .out_m(o_m)
);

assign out[31] = o_sign;
assign out[30:23] = o_exponent;
assign out[22:0] = o_mantissa[22:0];

always_comb 
begin

    a_sign = a[31];

    if(a[30:23] == 0) begin
        a_exponent = 8'b00000001;
        a_mantissa = {1'b0, a[22:0]};
    end else begin
        a_exponent = a[30:23];
        a_mantissa = {1'b1, a[22:0]};
    end

    b_sign = b[15];

    if(b[14:7] == 0) begin
        b_exponent = 8'b00000001;
        b_mantissa = {1'b0, b[6:0],16'b0};
    end else begin
        b_exponent = b[14:7];
        b_mantissa = {1'b1, b[6:0],16'b0};
    end

    if (a_exponent == b_exponent) begin // Equal exponents
        o_exponent = a_exponent;
        if (a_sign == b_sign) begin // Equal signs = add
            o_mantissa = a_mantissa + b_mantissa;
            //Signify to shift
            o_mantissa[24] = 1;
            o_sign = a_sign;
        end else begin // Opposite signs = subtract
            if(a_mantissa > b_mantissa) begin
                o_mantissa = a_mantissa - b_mantissa;
                o_sign = a_sign;
            end else begin
                o_mantissa = b_mantissa - a_mantissa;
                o_sign = b_sign;
            end
        end
    end else begin //Unequal exponents
        if (a_exponent > b_exponent) begin // A is bigger
            o_exponent = a_exponent;
            o_sign = a_sign;
            if (a_sign == b_sign) begin
                o_mantissa = a_mantissa + (b_mantissa >> (a_exponent - b_exponent));
            end else begin
                o_mantissa = a_mantissa - (b_mantissa >> (a_exponent - b_exponent));
            end
        end else if (a_exponent < b_exponent) begin // B is bigger
            o_exponent = b_exponent;
            o_sign = b_sign;
            if (a_sign == b_sign) begin
                o_mantissa = b_mantissa + (a_mantissa >> (b_exponent - a_exponent));
            end else begin
                o_mantissa = b_mantissa - (a_mantissa >> (b_exponent - a_exponent));
            end
        end
    end

    if(o_mantissa[24] == 1) begin
        o_exponent = o_exponent + 1;
        o_mantissa = o_mantissa >> 1;
    end else if( (o_exponent != 0)) begin
        i_e = o_exponent;
        i_m = o_mantissa;
        o_exponent = o_e;
        o_mantissa = o_m;
    end
end
endmodule 