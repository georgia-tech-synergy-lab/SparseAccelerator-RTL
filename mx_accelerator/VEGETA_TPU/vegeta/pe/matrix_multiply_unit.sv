module matrix_multiply_unit
import vTPU_pkg::*;
#(
    parameter MATRIX_WIDTH = 14
) 
(
    input logic clk,
    input logic rst,
    input logic enable,
    input BYTE_TYPE weight_data [0 : MATRIX_WIDTH - 1],
    input logic weight_signed,
    input BYTE_TYPE systolic_data [0 : MATRIX_WIDTH - 1],
    input logic systolic_signed,

    input logic activate_weight,
    input logic load_weight,
    input BYTE_TYPE weight_address,

    output WORD_TYPE result_data [0 : MATRIX_WIDTH - 1]
);

WORD_TYPE interim_result [0 : MATRIX_WIDTH - 1][0 : MATRIX_WIDTH - 1] = '{'{default: '0}};
logic load_weight_map[0 : MATRIX_WIDTH-1];

logic activate_control_cs [0 : MATRIX_WIDTH-1-1] = '{defult: '0};
logic activate_control_ns[0 : MATRIX_WIDTH-1-1];

logic activate_map[0 : MATRIX_WIDTH-1];

EXTENDED_BYTE_TYPE extended_weight_data [0:MATRIX_WIDTH-1];
EXTENDED_BYTE_TYPE extended_systolic_data [0: MATRIX_WIDTH-1];

logic sign_control_cs [0: 2+MATRIX_WIDTH-1] = '{default:'0};
logic sign_control_ns [0 : 2+MATRIX_WIDTH-1];

assign activate_control_ns[1 : MATRIX_WIDTH-1-1] = activate_control_cs[0:MATRIX_WIDTH-2-1];
assign activate_control_ns[0] = activate_weight;

assign sign_control_ns[1:2+MATRIX_WIDTH-1] = sign_control_cs[0:2+MATRIX_WIDTH-2];
assign sign_control_ns[0] = systolic_signed;

assign activate_map = {activate_control_ns[0], activate_control_cs};

always_comb begin
    logic load_weight_v;
    BYTE_TYPE weight_address_v;
    logic load_weight_map_v [0:MATRIX_WIDTH-1];

    load_weight_v = load_weight;
    weight_address_v = weight_address;

    load_weight_map_v = '{default: '0};

    if(load_weight_v == 1) begin
        load_weight_map_v[weight_address_v] = 1;
    end    
    load_weight_map = load_weight_map_v;

end

always_comb begin
    for(integer i = 0; i<MATRIX_WIDTH; i=i+1) begin
        if(weight_signed == 1) begin
            extended_weight_data[i] = {weight_data[i][BYTE_WIDTH-1], weight_data[i]};
        end

        else begin
            extended_weight_data[i] = {1'b0, weight_data[i]};
        end

        if(sign_control_ns[i] == 1) begin
            extended_systolic_data[i] = {systolic_data[i][BYTE_WIDTH-1], systolic_data[i]};
        end

        else begin
            extended_systolic_data[i] = {0, systolic_data[i]};
        end
    end
end

genvar i, j;

generate
    for(i = 0; i<MATRIX_WIDTH; i=i + 1) begin
        for(j = 0; j<MATRIX_WIDTH; j=j+1) begin

            //UPPER left element
            if(i==0 && j == 0) begin
                macc macc_io #(.LAST_SUM_WIDTH(0), .PARTIAL_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH))
                (
                    .clk(clk),
                    .rst(rst),
                    .enable(enable),
                    .weight_input(extended_weight_data[j]),
                    .preload_weight(load_weight_map[i]),
                    .load_weight(activate_map[i]),
                    .input(extended_systolic_data[i]),
                    .last_sum(0),
                    .partial_sum(interim_result[i][j][2*EXTENDED_BYTE_WIDTH-1 : 0])
                );
            end

            if(i == 0 && j > 0) begin
                macc macc_i1 #(.LAST_SUM_WIDTH(0), .PARTIAL_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH))
                (
                    .clk(clk),
                    .rst(rst),
                    .enable(enable),
                    .weight_input(extended_weight_data[j]),
                    .preload_weight(load_weight_map[i]),
                    .load_weight(activate_map[i]),
                    .input(extended_systolic_data[i]),
                    .last_sum(0),
                    .partial_sum(interim_result[i][j][2*EXTENDED_BYTE_WIDTH-1 : 0])
                );

            end

            if(i > 0 && i <= 2*(BYTE_WIDTH-1) && j == 0) begin
                macc macc_i2 #(.LAST_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH+i-1), .PARTIAL_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH+i))
                (
                    .clk(clk),
                    .rst(rst),
                    .enable(enable),
                    .weight_input(extended_weight_data[j]),
                    .preload_weight(load_weight_map[i]),
                    .load_weight(activate_map[i]),
                    .input(extended_systolic_data[i]),
                    .last_sum(interim_result[i-1][j][2*EXTENDED_BYTE_WIDTH+i-2 : 0]),
                    .partial_sum(interim_result[i][j][2*EXTENDED_BYTE_WIDTH + i-1 : 0])
                );
            end

            if(i > 0 && i <= 2*(BYTE_WIDTH-1) && j > 0) begin
                macc macc_i3 #(.LAST_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH+i-1), .PARTIAL_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH+i))
                (
                    .clk(clk),
                    .rst(rst),
                    .enable(enable),
                    .weight_input(extended_weight_data[j]),
                    .preload_weight(load_weight_map[i]),
                    .load_weight(activate_map[i]),
                    .input(extended_systolic_data[i]),
                    .last_sum(interim_result[i-1][j][2*EXTENDED_BYTE_WIDTH+i-2 : 0]),
                    .partial_sum(interim_result[i][j][2*EXTENDED_BYTE_WIDTH + i-1 : 0])
                );
            end

            if(i > 2*(BYTE_WIDTH) && j == 0) begin
                macc macc_i4 #(.LAST_SUM_WIDTH(4*BYTE_WIDTH), .PARTIAL_SUM_WIDTH(4*BYTE_WIDTH))
                (
                    .clk(clk),
                    .rst(rst),
                    .enable(enable),
                    .weight_input(extended_weight_data[j]),
                    .preload_weight(load_weight_map[i]),
                    .load_weight(activate_map[i]),
                    .input(extended_systolic_data[i]),
                    .last_sum(interim_result[i-1][j]),
                    .partial_sum(interim_result[i][j])
                );
            end

            if(i > 2*(BYTE_WIDTH) && j > 0) begin
                macc macc_i5 #(.LAST_SUM_WIDTH(4*BYTE_WIDTH), .PARTIAL_SUM_WIDTH(4*BYTE_WIDTH))
                (
                    .clk(clk),
                    .rst(rst),
                    .enable(enable),
                    .weight_input(extended_weight_data[j]),
                    .preload_weight(load_weight_map[i]),
                    .load_weight(activate_map[i]),
                    .input(extended_systolic_data[i]),
                    .last_sum(interim_result[i-1][j]),
                    .partial_sum(interim_result[i][j])
                );
            end
        end
    end
endgenerate


always_comb begin
    logic [2*EXTENDED_BYTE_WIDTH+MATRIX_WIDTH-2 : 0] result_data_v;
    logic [4*BYTE_WIDTH-1 : 2*EXTENDED_BYTE_WIDTH -1] extend_v;

    for(integer i=MATRIX_WIDTH-1; i>= 0; i=i-1) begin
        result_data_v = interim_result[MATRIX_WIDTH-1][i][2*EXTENDED_BYTE_WIDTH+MATRIX_WIDTH-2 : 0];
        if(sign_control_cs[2+MATRIX_WIDTH-1] == 1) begin
            extend_v = '{default: interim_result[MATRIX_WIDTH-1][i][2*EXTENDED_BYTE_WIDTH+MATRIX_WIDTH-2]};
        end

        else begin
            extend_v = '{default: '0};
        end

        result_data[i] = {extend_v, result_data_v};
    end
end

always_ff @(posedge clk) begin
    if (rst == 1) begin
        activate_control_cs <= '{default: '0};
        sign_control_cs <= '{default: '0};
    end

    else begin
        activate_control_cs <= activate_control_ns;
        sign_control_cs <= sign_control_ns;
    end
end
    
endmodule