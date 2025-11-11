 module mult_normalizer_fp6
(
    input logic [2:0] in_e, 
    input logic [7:0] in_m, 
    output logic [1:0] out_e, 
    output wire logic [2:0] out_m
);

logic [7:0] tmp;



always_comb 
begin // Can replace with case statements
    if (in_e[2] == 1) begin  //exponent overflow
        out_e = 2'b11;
        tmp = 6'b111111;          
   
    end else if (in_m[6:3] == 4'b0001 ) begin
        if (in_e>=3) begin
            out_e = in_e - 3;
            tmp = in_m << 3;
        end else begin
            out_e = 2'b00;
            tmp = in_m << in_e;
        end

        //out_e = in_e - 3;
        //tmp = in_m << 3;
    end else if (in_m[6:4] == 3'b001) begin
        if (in_e>=2) begin
            out_e = in_e - 2;
            tmp = in_m << 2;
        end else begin
            out_e = 2'b00;
            tmp = in_m << in_e;
        end
        //out_e = in_e - 2;
        //tmp = in_m << 2;
        //$display("shift by 2");
    end else if (in_m[6:5] == 2'b01) begin
        if (in_e>=1) begin
            out_e = in_e - 1;
            tmp = in_m << 1;
        end else begin
            out_e = 2'b00;
            tmp = {1'b0,in_m};
        end
        //out_e = in_e - 1;
        //tmp = in_m << 1;
        //$display("shift by 1");
    end else if (in_m[6] == 1'b1) begin
        out_e = in_e;
        //$display("no shift");
        //$display("in_e = %x, out_e = %x",in_e,out_e);
        tmp = in_m;
    end else begin
        out_e = in_e;
        tmp = in_m;
    end   
    
    
   //$display("in_m = %x, tmp = %x",in_m,tmp);
   //$display("tmp[5:3] = %x",tmp[5:3]);
   //$display("in_e = %x, out_e = %x",in_e,out_e);
end




assign out_m = tmp[5:3];
 
endmodule