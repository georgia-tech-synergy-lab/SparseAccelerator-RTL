 module mult_normalizer
(
    input logic [8:0] in_e, 
    input logic [15:0] in_m, 
    output logic [7:0] out_e, 
    output wire logic [6:0] out_m
);

logic [15:0] tmp;

//always_comb 
//begin // Can replace with case statements
//    if (in_e[8] == 1) begin
//        out_e = 8'd255;
//        tmp = 16'b0;
//    end
//    //if (in_e[14:8] == 1) begin
//    //    out_e = 8'd255;
//    //    tmp = 16'b0;
//    //end
//    
//    if (in_m[15:9] == 7'b0000001) begin
//        out_e = in_e - 6;
//        tmp = in_m <<  6;
//    end
//    if (in_m[15:10] == 6'b000001) begin
//        out_e = in_e - 5;
//        tmp = in_m << 5;
//    end else if (in_m[15:11] == 5'b00001) begin
//        out_e = in_e - 4;
//        tmp = in_m << 4;
//    end else if (in_m[15:12] == 4'b0001) begin
//        out_e = in_e - 3;
//        tmp = in_m << 3;
//    end else if (in_m[15:13] == 3'b001) begin
//        out_e = in_e - 2;
//        tmp = in_m << 2;
//    end else if (in_m[15:14] == 2'b01) begin
//        out_e = in_e - 1;
//        tmp = in_m << 1;
//    end else if (in_m[15] == 1'b1) begin
//        out_e = in_e;
//        tmp = in_m;
//    end else begin
//        out_e = in_e;
//        tmp = in_m;
//    end
//end

always_comb 
begin // Can replace with case statements
    if (in_e[8] == 1) begin
        out_e = 8'd255;
        tmp = 16'b0;
    end
  
    else if (in_m[14:0]== 15'b000000000000001) begin
        out_e = in_e - 14;
        tmp = in_m <<  14;
    end else if (in_m[14:1] == 14'b00000000000001) begin
        out_e = in_e - 13;
        tmp = in_m <<  13;
    end else if (in_m[14:2] == 13'b0000000000001) begin
        out_e = in_e - 12;
        tmp = in_m <<  12;
    end else if (in_m[14:3] == 12'b000000000001) begin
        out_e = in_e - 11;
        tmp = in_m <<  11;
    end else if (in_m[14:4] == 11'b00000000001) begin
        out_e = in_e - 10;
        tmp = in_m <<  10;
    end else if (in_m[14:5] == 10'b0000000001) begin
        out_e = in_e - 9;
        tmp = in_m <<  9;
    end else if (in_m[14:6] == 9'b000000001) begin
        out_e = in_e - 8;
        tmp = in_m <<  8;
    end else if (in_m[14:7] == 8'b00000001) begin
        out_e = in_e - 7;
        tmp = in_m <<  7;
    end 
    else if (in_m[14:8] == 7'b0000001) begin
        out_e = in_e - 6;
        tmp = in_m <<  6;
    end else if (in_m[14:9] == 6'b000001) begin
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
    end else if (in_m[14] == 1'b1) begin
        out_e = in_e;
        $display("in_e = %x, out_e = %x",in_e,out_e);
        tmp = in_m;
    end else begin
        out_e = in_e;
        tmp = in_m;
    end
    
    
    
    //$display("in_m = %x, tmp = %x",in_m,tmp);
    //$display("in_e = %x, out_e = %x",in_e,out_e);
end


 

assign out_m = tmp[13:7];
endmodule