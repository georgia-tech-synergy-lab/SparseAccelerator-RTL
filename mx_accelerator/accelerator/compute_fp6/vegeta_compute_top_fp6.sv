/*
Make X Scaled by Y Scaled systolic array made up of multiple PEs
*/
`include "vTPU_pkg_fp6.sv"
module vegeta_compute_top_fp6
// import vTPU_pkg_fp6::*;
(
    input logic clk,
    input logic rst_n,

    // Y_SCALED number of acc_in i.e, top row
    // input logic [ALPHA*BETA*ADD_DATAWIDTH-1 : 0] acc_in [0 : Y_SCALED],
    input logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in [0 : Y_SCALED-1],

    //X_SCALED number of rows means that many activations as input, i.e, left most column
    input logic [MUL_DATAWIDTH*M*BETA-1:0] act_in [0 : X_SCALED-1],
    input logic [ADD_DATAWIDTH*ALPHA-1 : 0] acc_in [0 : Y_SCALED-1],
    input logic [1:0] mode,
    input logic [1 : 0] gemm_mode, // dense, or 2:4, 1:4 etc
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen

    input logic [7:0] input_scale,
    input logic [7:0] weight_scale,
    
    input logic [7:0] input_acc_scale [0:X_SCALED-1],

    output logic [7:0] output_acc_scale [0:X_SCALED-1],

    // Output will be the partial sums at the bottom after going through the adder tree
    output logic [ALPHA*ADD_DATAWIDTH-1:0] acc_out [0 : Y_SCALED-1]
);

wire logic [MUL_DATAWIDTH*M*BETA-1:0] act_out_intm [0 : X_SCALED-1][0:Y_SCALED-1];
wire logic [ALPHA*BETA*ADD_DATAWIDTH-1:0] acc_out_intm [0 : X_SCALED-1][0:Y_SCALED-1];
wire logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out_intm [0 : X_SCALED-1][0:Y_SCALED-1];
wire logic weight_transferring_out_intm [0 : X_SCALED-1][0:Y_SCALED-1];

logic [7:0] input_acc_scale_intm [0 : X_SCALED - 1][0 : Y_SCALED - 1];

genvar i,j;
generate;
    for(i=0; i < X_SCALED; i = i + 1) begin
        for(j = 0; j< Y_SCALED; j = j + 1) begin
            if(i == 0  && j == 0) begin
                vegeta_pe_fp6 vegeta_pe_inst_0_0(
                    .clk(clk),
                    .rst_n(rst_n),
                    .acc_in(acc_in[i]),
                    .weight_in(weight_in[j]),
                    .act_in(act_in[i]),
                    .mode(mode),
                    .gemm_mode(gemm_mode),
                    .weight_transferring_in(weight_transferring_in),
                    .i_wb(i_wb),
                    .act_out(act_out_intm[i][j]),
                    .acc_out(acc_out_intm[i][j]),
                    .weight_out(weight_out_intm[i][j]),
                    .weight_transferring_out(weight_transferring_out_intm[i][j]),

                    .input_scale(input_scale),
                    .weight_scale(weight_scale),
                    .input_acc_scale(input_acc_scale[i]),
                    .output_acc_scale(input_acc_scale_intm[i][j])
  
                );
            end

            else if (i == 0 && j > 0) begin
                vegeta_pe_fp6 vegeta_pe_inst_0_j(
                    .clk(clk),
                    .rst_n(rst_n),
                    .acc_in(acc_in[j]),
                    .weight_in(weight_in[j]),
                    .act_in(act_out_intm[i][j-1]),
                    .mode(mode),
                    .gemm_mode(gemm_mode),
                    .weight_transferring_in(weight_transferring_in),
                    .i_wb(i_wb),
                    .act_out(act_out_intm[i][j]),
                    .acc_out(acc_out_intm[i][j]),
                    .weight_out(weight_out_intm[i][j]),
                    .weight_transferring_out(weight_transferring_out_intm[i][j]),

                    .input_scale(input_scale),
                    .weight_scale(weight_scale),
                    .input_acc_scale(input_acc_scale[j]),
                    .output_acc_scale(input_acc_scale_intm[i][j])

                );
            end

            else if (j == 0 && i > 0) begin
                vegeta_pe_fp6 vegeta_pe_inst_i_0(
                    .clk(clk),
                    .rst_n(rst_n),
                    .acc_in(acc_out_intm[i-1][j]),
                    .weight_in(weight_out_intm[i-1][j]),
                    .act_in(act_in[i]),
                    .mode(mode),
                    .gemm_mode(gemm_mode),
                    .weight_transferring_in(weight_transferring_out_intm[i-1][j]),
                    .i_wb(i_wb),
                    .act_out(act_out_intm[i][j]),
                    .acc_out(acc_out_intm[i][j]),
                    .weight_out(weight_out_intm[i][j]),
                
                    .weight_transferring_out(weight_transferring_out_intm[i][j]),

                    .input_scale(input_scale),
                    .weight_scale(weight_scale),
                    .input_acc_scale(input_acc_scale_intm[i-1][j]),
                    .output_acc_scale(input_acc_scale_intm[i][j])


                );
            end

            else begin
                 vegeta_pe_fp6 vegeta_pe_inst_i_j(
                    .clk(clk),
                    .rst_n(rst_n),
                    .acc_in(acc_out_intm[i-1][j]),
                    .weight_in(weight_out_intm[i-1][j]),
                    .act_in(act_out_intm[i][j-1]),
                    .mode(mode),
                    .gemm_mode(gemm_mode),
                    .weight_transferring_in(weight_transferring_out_intm[i-1][j]),
                    .i_wb(i_wb),
                    .act_out(act_out_intm[i][j]),
                    .acc_out(acc_out_intm[i][j]),
                    .weight_out(weight_out_intm[i][j]),
                    .weight_transferring_out(weight_transferring_out_intm[i][j]),

                    
                    .input_scale(input_scale),
                    .weight_scale(weight_scale),
                    .input_acc_scale(input_acc_scale_intm[i-1][j]),
                    .output_acc_scale(input_acc_scale_intm[i][j])
                );
            end
        end
    end
endgenerate

// This is fully combinational, the control unit just has to orchestrate timing of the PEs above
genvar k;
genvar l;
generate;
    for(k=0; k < Y_SCALED; k = k + 1) begin
        for(l=0; l < ALPHA; l = l+1) begin
            adder_tree_fp6 adder_tree_X_SCALED_k(
                .clk(clk),
                .rst_n(rst_n),
                .idata(acc_out_intm[X_SCALED-1][k][l*BETA*ADD_DATAWIDTH +: BETA*ADD_DATAWIDTH]),
                .odata(acc_out[k][l*ADD_DATAWIDTH +: ADD_DATAWIDTH])
            );
        end 
    end
endgenerate
endmodule