//general adder logic whenever the inputs change
module general_adder_fp6
(
    input logic [5:0] a, 
    input logic [5:0] b, 
    output wire logic [5:0] out
);

// wire logic [31:0] out;

logic a_sign;
logic b_sign;
logic [1:0] a_exponent;
logic [1:0] b_exponent;
logic [3:0] a_mantissa;
logic [3:0] b_mantissa;   

logic o_sign;
logic [1:0] o_exponent;
logic [4:0] o_mantissa; 


logic [1:0] i_e;
logic [3:0] i_m;
wire logic [1:0] o_e;
wire logic [4:0] o_m;


addition_normalizer_fp6 norm1(
    .in_e(i_e),
    .in_m(i_m),
    .out_e(o_e),
    .out_m(o_m)
);

assign out[5] = o_sign;
assign out[4:3] = o_exponent;
assign out[2:0] = o_mantissa[2:0];

always_comb 
begin

    a_sign = a[5];

    if(a[4:3] == 0) begin
        a_exponent = 2'b01;
        a_mantissa = {1'b0, a[2:0]};
    end else begin
        a_exponent = a[4:3];
        a_mantissa = {1'b1, a[2:0]};
    end

    b_sign = b[5];

    if(b[4:3] == 0) begin
        b_exponent = 2'b01;
        b_mantissa = {1'b0, b[2:0]};
    end else begin
        b_exponent = b[4:3];
        b_mantissa = {1'b1, b[2:0]};
    end

    if (a_exponent == b_exponent) begin // Equal exponents
        if (a[4:3]==2'b00 && b[4:3]==0) begin
            o_exponent = 2'b00;
        end else begin
            o_exponent = a_exponent;
        end
        
        
        if (a_sign == b_sign) begin // Equal signs = add
            o_mantissa = a_mantissa + b_mantissa;
            //Signify to shift
            //o_mantissa[4] = 1;
            o_sign = a_sign;
        end else begin // Opposite signs = subtract
            if(a_mantissa > b_mantissa) begin
                o_mantissa = a_mantissa - b_mantissa;
                o_sign = a_sign;
            end else begin
                o_mantissa = b_mantissa - a_mantissa;
                o_sign = b_sign;
            end
            //$display("a_mantissa = %h, b_mantissa = %h, o_mantissa = %h", a_mantissa, b_mantissa, o_mantissa);
            //$display("o_exponent_inside = %h", o_exponent);
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
                // $display("a_mantissa = %h, b_mantissa = %h, o_mantissa = %h", a_mantissa, b_mantissa, o_mantissa);
            end else begin
                o_mantissa = b_mantissa - (a_mantissa >> (b_exponent - a_exponent));
                // $display("a_mantissa after shift = %h", a_mantissa >> (b_exponent - a_exponent));
                // $display("a_mantissa = %h, b_mantissa = %h, o_mantissa = %h", a_mantissa, b_mantissa, o_mantissa);
            end
        end
    end

    if(o_mantissa[4] == 1) begin
        o_exponent = o_exponent + 1;
        // $display("o_exponent_inside_overflow = %h", o_exponent);
        o_mantissa = o_mantissa >> 1;
    end else if( (o_exponent != 0)) begin
        i_e = o_exponent;
        i_m = o_mantissa;
        //$display("i_e = %h, i_m = %h", i_e, i_m);
        o_exponent = o_e;
        o_mantissa = o_m;
    end
end
endmodule 