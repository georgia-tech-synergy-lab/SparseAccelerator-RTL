`include "vTPU_pkg_fp6.sv"
module vegeta_pu_fp6
// import vTPU_pkg_fp6::*;
(
    input logic clk,
    input logic rst_n,
    
    input logic [BETA*ADD_DATAWIDTH-1 : 0] acc_in,
    input logic [BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in,
    input [BETA*MUL_DATAWIDTH*M-1:0] act_in,

    input logic [1:0] mode,
    input logic [1 : 0] gemm_mode, // dense, or 2:4, 1:4 etc
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen

    input logic [7:0] input_scale,
    input logic [7:0] weight_scale,
    input  [7:0] input_acc_scale,
    output [7:0] output_acc_scale,

    output logic [BETA*ADD_DATAWIDTH-1:0] acc_out,
    output logic [BETA*(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out,
    output weight_transferring_out
);

// always_ff@(posedge clk) begin
//     if (mode == 2'b10)
//         output_acc_scale <= input_acc_scale;
// end

genvar i;
generate;
    for(i=0; i< BETA; i=i+1) begin
        vegeta_mac_fp6 vegeta_mac_i(
            .clk(clk),
            .rst_n(rst_n),
            .acc_in(acc_in[i*ADD_DATAWIDTH +: ADD_DATAWIDTH]),
            .weight_in(weight_in[i*(MUL_DATAWIDTH+META_DATA_SIZE) +: (MUL_DATAWIDTH+META_DATA_SIZE)]),
            .act_in(act_in[i*MUL_DATAWIDTH*M +: MUL_DATAWIDTH*M]),
            .mode(mode),
            .gemm_mode(gemm_mode),
            .weight_transferring_in(weight_transferring_in),
            .i_wb(i_wb),
            .input_scale(input_scale),
            .weight_scale(weight_scale),
            .input_acc_scale(input_acc_scale),
            .output_acc_scale(output_acc_scale),
            .acc_out(acc_out[i*ADD_DATAWIDTH +: ADD_DATAWIDTH]),
            .weight_out(weight_out[i*(MUL_DATAWIDTH+META_DATA_SIZE) +: (MUL_DATAWIDTH+META_DATA_SIZE)]),
            .weight_transferring_out(weight_transferring_out)

        );

    end
endgenerate
    
endmodule