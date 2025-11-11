/*
Make K Scaled by M Scaled systolic array made up of multiple PEs
*/

// instantiates all the PEs an adder trees

`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module vegeta_compute_top
#(
    parameter K_SCALED,
    parameter M_SCALED,
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

    // M_SCALED number of acc_in i.e, top row
    // input logic [ALPHA*BETA*ADD_DATAWIDTH-1 : 0] acc_in [0 : M_SCALED],
    input logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in [0 : M_SCALED-1],

    //K_SCALED number of rows means that many activations as input, i.e, left most column
    input logic [MUL_DATAWIDTH*BLOCK_SIZE*BETA-1:0] act_in [0 : K_SCALED-1],
    input logic [ALPHA*BETA*ADD_DATAWIDTH-1 : 0] acc_in [0 : M_SCALED-1],
    input logic mode,
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen

    // Output will be the partial sums at the bottom after going through the adder tree
    output logic [ALPHA*ADD_DATAWIDTH-1:0] acc_out [0 : M_SCALED-1]
);

logic [MUL_DATAWIDTH*BLOCK_SIZE*BETA-1:0] act_out_intm [0 : K_SCALED-1][0:M_SCALED-1];
logic [ALPHA*BETA*ADD_DATAWIDTH-1:0] acc_out_intm [0 : K_SCALED-1][0:M_SCALED-1];
logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out_intm [0 : K_SCALED-1][0:M_SCALED-1];

genvar i,j;
generate;
    for(i=0; i < K_SCALED; i = i + 1) begin : vertical
        for(j = 0; j< M_SCALED; j = j + 1) begin : horizontal
            if(i == 0  && j == 0) begin
                vegeta_pe #(
                    .ALPHA(ALPHA),
                    .BETA(BETA),
                    .ADD_DATAWIDTH(ADD_DATAWIDTH),
                    .MUL_DATAWIDTH(MUL_DATAWIDTH),
                    .META_DATA_SIZE(META_DATA_SIZE),
                    .BLOCK_SIZE(BLOCK_SIZE)  
                ) vegeta_pe_inst_0_0(
                    .clk(clk),
                    .rst_n(rst_n),
                    .acc_in(acc_in[i]),
                    .weight_in(weight_in[j]),
                    .act_in(act_in[i]),
                    .mode(mode),
                    .weight_transferring_in(weight_transferring_in),
                    .i_wb(i_wb),
                    .act_out(act_out_intm[i][j]),
                    .acc_out(acc_out_intm[i][j]),
                    .weight_out(weight_out_intm[i][j])
                );
            end

            else if (i == 0 && j > 0) begin
                vegeta_pe #(
                    .ALPHA(ALPHA),
                    .BETA(BETA),
                    .ADD_DATAWIDTH(ADD_DATAWIDTH),
                    .MUL_DATAWIDTH(MUL_DATAWIDTH),
                    .META_DATA_SIZE(META_DATA_SIZE),
                    .BLOCK_SIZE(BLOCK_SIZE)  
                ) vegeta_pe_inst_0_j(
                    .clk(clk),
                    .rst_n(rst_n),
                    .acc_in(acc_in[j]),
                    .weight_in(weight_in[j]),
                    .act_in(act_out_intm[i][j-1]),
                    .mode(mode),
                    .weight_transferring_in(weight_transferring_in),
                    .i_wb(i_wb),
                    .act_out(act_out_intm[i][j]),
                    .acc_out(acc_out_intm[i][j]),
                    .weight_out(weight_out_intm[i][j])
                );
            end

            else if (j == 0 && i > 0) begin
                vegeta_pe #(
                    .ALPHA(ALPHA),
                    .BETA(BETA),
                    .ADD_DATAWIDTH(ADD_DATAWIDTH),
                    .MUL_DATAWIDTH(MUL_DATAWIDTH),
                    .META_DATA_SIZE(META_DATA_SIZE),
                    .BLOCK_SIZE(BLOCK_SIZE)  
                ) vegeta_pe_inst_i_0(
                    .clk(clk),
                    .rst_n(rst_n),
                    .acc_in(acc_out_intm[i-1][j]),
                    .weight_in(weight_out_intm[i-1][j]),
                    .act_in(act_in[i]),
                    .mode(mode),
                    .weight_transferring_in(weight_transferring_in),
                    .i_wb(i_wb),
                    .act_out(act_out_intm[i][j]),
                    .acc_out(acc_out_intm[i][j]),
                    .weight_out(weight_out_intm[i][j])
                );
            end

            else begin
                vegeta_pe #(
                    .ALPHA(ALPHA),
                    .BETA(BETA),
                    .ADD_DATAWIDTH(ADD_DATAWIDTH),
                    .MUL_DATAWIDTH(MUL_DATAWIDTH),
                    .META_DATA_SIZE(META_DATA_SIZE),
                    .BLOCK_SIZE(BLOCK_SIZE)  
                ) vegeta_pe_inst_i_j(
                    .clk(clk),
                    .rst_n(rst_n),
                    .acc_in(acc_out_intm[i-1][j]),
                    .weight_in(weight_out_intm[i-1][j]),
                    .act_in(act_out_intm[i][j-1]),
                    .mode(mode),
                    .weight_transferring_in(weight_transferring_in),
                    .i_wb(i_wb),
                    .act_out(act_out_intm[i][j]),
                    .acc_out(acc_out_intm[i][j]),
                    .weight_out(weight_out_intm[i][j])
                );
            end
        end
    end
endgenerate

// This is fully combinational, the control unit just has to orchestrate timing of the PEs above
genvar k;
genvar l;
generate;
    for(k=0; k < M_SCALED; k = k + 1) begin
        for(l=0; l < ALPHA; l = l+1) begin
            adder_tree #(
                .BETA(BETA),
                .ADD_DATAWIDTH(ADD_DATAWIDTH)
            ) adder_tree_X_SCALED_k(
                .clk(clk),
                .rst_n(rst_n),
                .idata(acc_out_intm[K_SCALED-1][k][l*BETA*ADD_DATAWIDTH +: BETA*ADD_DATAWIDTH]),
                .odata(acc_out[k][l*ADD_DATAWIDTH +: ADD_DATAWIDTH])
            );
        end 
    end
endgenerate
endmodule