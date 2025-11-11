`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module general_adder
(
    input logic [31:0] a, 
    input logic [31:0] b, 
    output logic [31:0] out
);

logic a_sign;
logic b_sign;
logic [7:0] a_exponent;
logic [7:0] b_exponent;
logic [7:0] diff_exponent;
logic [48:0] a_mantissa;
logic [48:0] b_mantissa;   

logic o_sign;
logic [7:0] o_exponent;
logic [48:0] o_mantissa;

logic subnormal;

logic [7:0] shift_amt;

assign out[31] = o_sign;
assign out[30:23] = o_exponent;
assign out[22:0] = o_mantissa[46:24];

always_comb 
begin

    a_sign = a[31];

    if(a[30:23] == '0) begin
        a_exponent = 8'b00000001;
        a_mantissa = {2'b0, a[22:0], 24'b0};
    end else begin
        a_exponent = a[30:23];
        a_mantissa = {2'b1, a[22:0], 24'b0};
    end

    b_sign = b[31];

    if(b[30:23] == '0) begin
        b_exponent = 8'b00000001;
        b_mantissa = {2'b0, b[22:0], 24'b0};
    end else begin
        b_exponent = b[30:23];
        b_mantissa = {2'b1, b[22:0], 24'b0};
    end

    subnormal = '0;
    if (a_exponent == b_exponent) begin // Equal exponents
        o_exponent = a_exponent;
        if (a[30:23] == '0)
            subnormal = '1;
        if (a_sign == b_sign) begin // Equal signs = add
            o_mantissa = a_mantissa + b_mantissa;
            //Signify to shift
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
            if (a[30:23] == '0)
                subnormal = '1;
            diff_exponent = a_exponent - b_exponent;
            o_sign = a_sign;
            if (a_sign == b_sign) begin
                o_mantissa = a_mantissa + (b_mantissa >> (diff_exponent));
            end else begin
                o_mantissa = a_mantissa - (b_mantissa >> (diff_exponent));
            end
        end else begin // B is bigger
            o_exponent = b_exponent;
            if (b[30:23] == '0)
                subnormal = '1;
            o_sign = b_sign;
            diff_exponent = b_exponent - a_exponent;
            if (a_sign == b_sign) begin
                o_mantissa = b_mantissa + (a_mantissa >> (diff_exponent));
            end else begin
                o_mantissa = b_mantissa - (a_mantissa >> (diff_exponent));
            end
        end
    end

    shift_amt = '0;
    if(o_mantissa[48] == 1) begin
        o_exponent = o_exponent + 1'b1;
        o_mantissa = o_mantissa >> 1'b1;
        if (o_exponent == 8'd255)
            o_mantissa = '0;
        subnormal = '0;
    end else if (o_mantissa[47] == 1) begin
        subnormal = '0;
    end else if (o_mantissa[47] == 0) begin
        if (o_mantissa[46:24] == 23'b000000) begin
            o_sign = '0;
            o_exponent = '0;
        end else if (o_mantissa[46:24] == 23'b000001) begin
            shift_amt =  8'd23;
        end else if (o_mantissa[46:25] == 22'b000001) begin
            shift_amt =  8'd22;
        end else if (o_mantissa[46:26] == 21'b000001) begin
            shift_amt =  8'd21;
        end else if (o_mantissa[46:27] == 20'b000001) begin
            shift_amt =  8'd20;
        end else if (o_mantissa[46:28] == 19'b000001) begin
            shift_amt =  8'd19;
        end else if (o_mantissa[46:29] == 18'b000001) begin
            shift_amt =  8'd18;
        end else if (o_mantissa[46:30] == 17'b000001) begin
            shift_amt =  8'd17;
        end else if (o_mantissa[46:31] == 16'b000001) begin
            shift_amt =  8'd16;
        end else if (o_mantissa[46:32] == 15'b000001) begin
            shift_amt =  8'd15;
        end else if (o_mantissa[46:33] == 14'b000001) begin
            shift_amt =  8'd14;
        end else if (o_mantissa[46:34] == 13'b000001) begin
            shift_amt =  8'd13;
        end else if (o_mantissa[46:35] == 12'b000001) begin
            shift_amt =  8'd12;
        end else if (o_mantissa[46:36] == 11'b000001) begin
            shift_amt =  8'd11;
        end else if (o_mantissa[46:37] == 10'b000001) begin
            shift_amt =  8'd10;
        end else if (o_mantissa[46:38] == 9'b000001) begin
            shift_amt =  8'd9;
        end else if (o_mantissa[46:39] == 8'b000001) begin
            shift_amt =  8'd8;
        end else if (o_mantissa[46:40] == 7'b000001) begin
            shift_amt =  8'd7;
        end else if (o_mantissa[46:41] == 6'b000001) begin
            shift_amt =  8'd6;
        end else if (o_mantissa[46:42] == 5'b00001) begin
            shift_amt =  8'd5;
        end else if (o_mantissa[46:43] == 4'b0001) begin
            shift_amt =  8'd4;
        end else if (o_mantissa[46:44] == 3'b001) begin
            shift_amt =  8'd3;
        end else if (o_mantissa[46:45] == 2'b01) begin
            shift_amt =  8'd2;
        end else if (o_mantissa[46:46] == 1'b1) begin
            shift_amt =  8'd1;
        end
    end

    if (subnormal)
        o_exponent = o_exponent - 8'b1;
    
    if (shift_amt < o_exponent) begin
        o_mantissa = o_mantissa << shift_amt;
        o_exponent = o_exponent - shift_amt;
    end else begin
        if (subnormal)
            o_mantissa = o_mantissa << o_exponent;
        else
            o_mantissa = o_mantissa << (o_exponent-8'b1);
        o_exponent = '0;
    end


    if (o_mantissa[23] == 1'b1 && o_mantissa[22:0] == '0) begin
        if (o_mantissa[24] != 1'b0)
            o_mantissa = o_mantissa + {24'b1, 24'b0};
    end else if (o_mantissa[23] == 1'b1) begin
        o_mantissa = o_mantissa + {24'b1, 24'b0};
    end

end
endmodule 