`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module vegeta_pu
#(
    parameter BETA,
    parameter ADD_DATAWIDTH,
    parameter MUL_DATAWIDTH,
    parameter META_DATA_SIZE,
    parameter BLOCK_SIZE
)
(
    input logic clk,
    input logic rst_n,
    
    input logic [BETA*ADD_DATAWIDTH-1 : 0] acc_in,
    input logic [BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in,
    input logic [BETA*MUL_DATAWIDTH*BLOCK_SIZE-1:0] act_in,

    input logic mode,
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen

    output logic [BETA*ADD_DATAWIDTH-1:0] acc_out,
    output logic [BETA*(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out
);

genvar i;
generate;
    for(i=0; i< BETA; i=i+1) begin : mac_gen
        vegeta_mac #(
            .ADD_DATAWIDTH(ADD_DATAWIDTH),
            .MUL_DATAWIDTH(MUL_DATAWIDTH),
            .META_DATA_SIZE(META_DATA_SIZE),
            .BLOCK_SIZE(BLOCK_SIZE)
        ) vegeta_mac_i(
            .clk(clk),
            .rst_n(rst_n),
            .acc_in(acc_in[i*ADD_DATAWIDTH +: ADD_DATAWIDTH]),
            .weight_in(weight_in[i*(MUL_DATAWIDTH+META_DATA_SIZE) +: (MUL_DATAWIDTH+META_DATA_SIZE)]),
            .act_in(act_in[i*MUL_DATAWIDTH*BLOCK_SIZE +: MUL_DATAWIDTH*BLOCK_SIZE]),
            .mode(mode),
            .weight_transferring_in(weight_transferring_in),
            .i_wb(i_wb),
            .acc_out(acc_out[i*ADD_DATAWIDTH +: ADD_DATAWIDTH]),
            .weight_out(weight_out[i*(MUL_DATAWIDTH+META_DATA_SIZE) +: (MUL_DATAWIDTH+META_DATA_SIZE)])
        );
    end
endgenerate

endmodule