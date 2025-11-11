/*
Responsibility of the module sending the activation input to organize appropriately based on sparsity patter.
This block only simply distributes and broadcasts.
*/
`include "vTPU_pkg.sv"

module vegeta_pe
// import vTPU_pkg::*;
(
    input logic clk,
    input logic rst_n,

    input logic [ALPHA*BETA*ADD_DATAWIDTH-1 : 0] acc_in,
    input logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in,
    input [MUL_DATAWIDTH*M*BETA-1:0] act_in, // Because 128-bit is needed for N:4 can be modified and accordingly for higher bits

    input logic [1:0] mode,
    input logic [1 : 0] gemm_mode, // dense, or 2:4, 1:4 etc
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen

    output logic [MUL_DATAWIDTH*M*BETA-1:0] act_out, // For transferring data to right
    output logic [ALPHA*BETA*ADD_DATAWIDTH-1:0] acc_out,
    output logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out,
    output weight_transferring_out
);

// Transfer on rising edge of clock
always_ff@(posedge clk) begin
    if (mode == 2'b10)
        act_out <= act_in;
end

genvar i;
generate;
    for(i = 0; i<ALPHA; i=i+1) begin
        vegeta_pu vegeta_pu_i(
            .clk(clk),
            .rst_n(rst_n),
            .acc_in(acc_in[i*BETA*ADD_DATAWIDTH +: BETA*ADD_DATAWIDTH]),
            .weight_in(weight_in[i*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) +: BETA*(MUL_DATAWIDTH+META_DATA_SIZE)]),
            .act_in(act_in),
            .mode(mode),
            .gemm_mode(gemm_mode),
            .weight_transferring_in(weight_transferring_in),
            .i_wb(i_wb),
            .acc_out(acc_out[i*BETA*ADD_DATAWIDTH +: BETA*ADD_DATAWIDTH]),
            .weight_out(weight_out[i*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) +: BETA*(MUL_DATAWIDTH+META_DATA_SIZE)]),
            .weight_transferring_out(weight_transferring_out)
        );
    end
endgenerate 
endmodule