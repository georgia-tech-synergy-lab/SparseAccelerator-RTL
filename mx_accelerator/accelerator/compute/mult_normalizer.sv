module mult_normalizer
(
    input logic [8:0] in_e, 
    input logic [15:0] in_m, 
    output logic [7:0] out_e, 
    output wire logic [6:0] out_m
);

logic [15:0] tmp;

always_comb 
begin // Can replace with case statements
    if (in_e[8] == 1) begin
        out_e = 8'd255;
        tmp = 16'b0;
    end
    else if (in_m[14:9] == 6'b000001) begin
        out_e = in_e - 5;
        tmp = in_m << 5;
    end else if (in_m[14:10] == 5'b00001) begin
        out_e = in_e - 4;
        tmp = in_m << 4;
    end else if (in_m[14:11] == 4'b0001) begin
        out_e = in_e - 3;
        tmp = in_m << 3;
    end else if (in_m[14:12] == 3'b001) begin
        out_e = in_e - 2;
        tmp = in_m << 2;
    end else if (in_m[14:13] == 2'b01) begin
        out_e = in_e - 1;
        tmp = in_m << 1;
    end else begin
        out_e = in_e;
        tmp = in_m;
    end
end

assign out_m = tmp[14:8];
endmodule