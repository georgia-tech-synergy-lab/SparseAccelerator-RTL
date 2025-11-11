/*
======================= START OF LICENSE NOTICE =======================
    Copyright (C) 2025 Akshat Ramachandran (GT), Souvik Kundu (Intel), Tushar Krishna (GT). All Rights Reserved

    NO WARRANTY. THE PRODUCT IS PROVIDED BY DEVELOPER "AS IS" AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DEVELOPER BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
    GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
    IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
    OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE PRODUCT, EVEN
    IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
======================== END OF LICENSE NOTICE ========================
    Primary Author: Akshat Ramachandran (GT)

*/
`include "vTPU_pkg.sv"
module vegeta_pu
// import vTPU_pkg::*;
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

    output logic [BETA*ADD_DATAWIDTH-1:0] acc_out,
    output logic [BETA*(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out,
    output weight_transferring_out
);


genvar i;
generate;
    for(i=0; i< BETA; i=i+1) begin
        vegeta_mac vegeta_mac_i(
            .clk(clk),
            .rst_n(rst_n),
            .acc_in(acc_in[i*ADD_DATAWIDTH +: ADD_DATAWIDTH]),
            .weight_in(weight_in[i*(MUL_DATAWIDTH+META_DATA_SIZE) +: (MUL_DATAWIDTH+META_DATA_SIZE)]),
            .act_in(act_in[i*MUL_DATAWIDTH*M +: MUL_DATAWIDTH*M]),
            .mode(mode),
            .gemm_mode(gemm_mode),
            .weight_transferring_in(weight_transferring_in),
            .i_wb(i_wb),
            .acc_out(acc_out[i*ADD_DATAWIDTH +: ADD_DATAWIDTH]),
            .weight_out(weight_out[i*(MUL_DATAWIDTH+META_DATA_SIZE) +: (MUL_DATAWIDTH+META_DATA_SIZE)]),
            .weight_transferring_out(weight_transferring_out)

        );

    end
endgenerate
    
endmodule