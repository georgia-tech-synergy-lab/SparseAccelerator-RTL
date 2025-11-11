/*
Responsibility of the module sending the activation input to organize appropriately based on sparsity patter.
This block only simply distributes and broadcasts.
*/

`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module vegeta_pe
#(
    parameter ALPHA,
    parameter BETA,
    parameter ADD_DATAWIDTH,
    parameter MUL_DATAWIDTH,
    parameter META_DATA_SIZE,
    parameter BLOCK_SIZE
)
(
    input logic clk,
    input logic rst_n,

    input logic [ALPHA*BETA*ADD_DATAWIDTH-1 : 0] acc_in,
    input logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in,
    input logic [MUL_DATAWIDTH*BLOCK_SIZE*BETA-1:0] act_in, // Because 128-bit is needed for N:4 can be modified and accordingly for higher bits

    input logic mode,
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen

    output logic [MUL_DATAWIDTH*BLOCK_SIZE*BETA-1:0] act_out, // For transferring data to right
    output logic [ALPHA*BETA*ADD_DATAWIDTH-1:0] acc_out,
    output logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out
);

// Transfer on rising edge of clock
always_ff@(posedge clk or negedge rst_n) begin
    if (~rst_n)
        act_out <= '0;
    else if (mode == 1'b1)
        act_out <= act_in;
end

genvar i;
generate;
    for(i = 0; i<ALPHA; i=i+1) begin : pu_gen
        vegeta_pu #(
            .BETA(BETA),
            .ADD_DATAWIDTH(ADD_DATAWIDTH),
            .MUL_DATAWIDTH(MUL_DATAWIDTH),
            .META_DATA_SIZE(META_DATA_SIZE),
            .BLOCK_SIZE(BLOCK_SIZE)  
        ) vegeta_pu_i(
            .clk(clk),
            .rst_n(rst_n),
            .acc_in(acc_in[i*BETA*ADD_DATAWIDTH +: BETA*ADD_DATAWIDTH]),
            .weight_in(weight_in[i*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) +: BETA*(MUL_DATAWIDTH+META_DATA_SIZE)]),
            .act_in(act_in),
            .mode(mode),
            .weight_transferring_in(weight_transferring_in),
            .i_wb(i_wb),
            // acc out goes to specific column portion
            .acc_out(acc_out[i*BETA*ADD_DATAWIDTH +: BETA*ADD_DATAWIDTH]),
            .weight_out(weight_out[i*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) +: BETA*(MUL_DATAWIDTH+META_DATA_SIZE)])
        );
    end : pu_gen
endgenerate 

endmodule