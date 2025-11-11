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
module vegeta_mac

(
    input logic clk,
    input logic rst_n,
    input logic [ADD_DATAWIDTH-1 : 0] acc_in,
    input logic [MUL_DATAWIDTH+META_DATA_SIZE - 1 : 0] weight_in,
    input [MUL_DATAWIDTH*M-1:0] act_in,  // Activation data
    // Input Ctrl signal
    input logic [1:0] mode,
    input logic [1 : 0] gemm_mode, // dense, or 2:4, 1:4 etc
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen
    // Output data signals
    output logic [ADD_DATAWIDTH-1:0] acc_out,
    output logic [(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out,
    output weight_transferring_out
);

    // Internal ports
    logic  [(MUL_DATAWIDTH+META_DATA_SIZE)-1:0]  weight_buffer [0:1];           // weight double buffer
    logic  [MUL_DATAWIDTH-1:0]                   weight_buffer_out;             // read weights from buffer
    logic  [META_DATA_SIZE-1:0]                  meta_buffer_out;             // read metadata from buffer
    logic [MUL_DATAWIDTH-1:0]                    activation; //used to be wire_logic, not sure why
    wire logic [2*MUL_DATAWIDTH-1:0]             mult_out; // Outputs after calculation in this PE
    logic  [ADD_DATAWIDTH-1:0]                   acc_adder_in;
    wire logic [ADD_DATAWIDTH-1:0]               acc_adder_out;
    logic                                        weight_transferring_out_driver;

// For support for different quantization, change these units below
bfp16_mult mult (
    .A(activation),
    .B(weight_buffer_out),
    .O(mult_out)
);

bfp32_adder adder (
    .A(acc_adder_in),
    .B(mult_out),
    .O(acc_adder_out)
); 

always_ff @(posedge clk) begin
    if(rst_n == 1'b0) begin
        weight_buffer[0] <= 0;
        weight_buffer[1] <= 0;
        weight_out <= 0;
        acc_out <= 0;
        weight_transferring_out_driver <= 0;              
    end else begin
        //change to hopefully avoid multiple drivers
        weight_transferring_out_driver <= weight_transferring_in; 
        // Weight load stage
        if(mode == 2'b00 && weight_transferring_in == 1) begin
            weight_buffer[i_wb] <= weight_in;
            weight_out <= weight_in;
            //weight_transferring_out <= weight_transferring_in;     
        end else if (mode == 2'b10) begin // Compute stage 
            acc_out <= acc_adder_out;
            // Continue load of next set of weights into the buffers for double buffering
            if(weight_transferring_in == 1) begin
                weight_buffer[~i_wb] <= weight_in;
                weight_out <= weight_in;
                //weight_transferring_out <= weight_transferring_in;
            end
        end
    end
end

always_comb begin
    if(rst_n == 1'b0) begin
        weight_buffer_out = 0;
        meta_buffer_out = 0;
    end

    else begin
        if(mode == 2'b10) begin // Do GEMM
            weight_buffer_out = weight_buffer[i_wb][MUL_DATAWIDTH - 1 : 0];		
            meta_buffer_out =   weight_buffer[i_wb][MUL_DATAWIDTH+META_DATA_SIZE - 1:MUL_DATAWIDTH];
            acc_adder_in = acc_in;

            // Select correct activation based on metadata
            if(gemm_mode == 0) // Dense
                activation = act_in[MUL_DATAWIDTH-1 : 0];
            
            else begin
                activation = act_in[MUL_DATAWIDTH*meta_buffer_out +: MUL_DATAWIDTH];
            end    
        end
    end
end

assign weight_transferring_out = weight_transferring_out_driver;

endmodule