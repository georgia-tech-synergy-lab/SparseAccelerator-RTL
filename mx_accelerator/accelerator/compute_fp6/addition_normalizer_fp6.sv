module addition_normalizer_fp6
(
    input  logic [1:0] in_e, // This is 7 bit because we do not have to worry about overflow during FP32 addition
    input  logic [3:0] in_m, 
    output logic [1:0] out_e, 
    output logic [4:0] out_m
);

always_comb 
begin
    
    if (in_m[3:0] == 4'b0001) begin
        if (in_e >= 3) begin
            out_e = in_e - 3;
            out_m = in_m << 3;
        end else begin
            out_e = 2'b00;
            //out_m = in_m << (3 - in_e);
            out_m = in_m << in_e;
        end
    end else if (in_m[3:1] == 3'b001) begin
        if(in_e>=2) begin
            out_e = in_e - 2;
            out_m = in_m << 2;
        end else begin
            out_e = 2'b00;
            out_m = in_m << in_e;
            //out_m = in_m << (2 - in_e);
        end
        out_e = in_e - 2;
        out_m = in_m << 2;
    end else if (in_m[3:2] == 2'b01) begin
        if (in_e == 2'b00) begin
            out_e = 2'b00;
            out_m = {1'b0, in_m};
        end else begin
            out_e = in_e - 1;
            out_m = in_m << 1;  
        end      
    end else if (in_m[3] == 1'b1) begin
        out_e = in_e;
        out_m = in_m;
    //end else begin
    //    out_e = in_e + 1;
    //    out_m = in_m >> 1;
    end
end
endmodule