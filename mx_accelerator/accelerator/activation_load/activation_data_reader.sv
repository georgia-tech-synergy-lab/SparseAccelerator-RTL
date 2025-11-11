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


module activation_data_reader
import vTPU_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic instruction_ready_compute_act,

    input logic [3:0] opcode_function,
    input logic [$clog2(NUM_REGS) - 1 : 0] buffer_address,
    input logic [15 : 0] memory_address,

    // ACC FIFOS
    output logic [MUL_DATAWIDTH*M*BETA-1 : 0] act_fifo_data [0: X_SCALED-1],
    output logic act_fifo_valid [0:X_SCALED-1],

    // This will be probided by a master controller
    input logic [1:0] mode, // To identify if we are in only weight load stage or compute stage with possible overlapped weight load
    input logic [1 : 0] gemm_mode, // dense, or 2:4, 1:4 etc

    // Inputs from vegeta_compute top


    // Outputs to vegeta_compute top
    output logic [MUL_DATAWIDTH*M*BETA-1:0] act_in [0 : X_SCALED-1],

    // Inputs from vegeta_reg
    input logic [7:0] read_data,
    input logic row_last, // To identify last element of a row
    input logic reg_last, // To identify last element of the register (When reg_last and row_last are one means data transfer is complete)

    // Outputs to vegeta_reg
    output logic read_req,
    output logic [1 : 0] read_mode,
    output logic [$clog2(NUM_REGS)-1 : 0] read_address,

);

logic instruction_ready_compute_act_intm;
logic [3:0] opcode_function_intm;
logic [$clog2(NUM_REGS) - 1 : 0] buffer_address_intm;
logic [15 : 0] memory_address_intm;

always_ff @(posedge clk) begin
    if(rst_n == 1'b0) begin
        weight_in <= '0;
        acc_in [0 : Y_SCALED-1] <= 0;
        weight_transferring_in <= 0;
        i_wb <= 0; // buffer select into which next load will happen
        read_req <= 0;
        read_req_meta <= 0;
        read_mode <= 0;
        read_mode_meta <= 0;
        read_address <= 0;
        read_address_meta <= 0;
    end

    else begin

        if(instruction_ready_compute_act == 1) begin
            instruction_ready_compute_act_intm <= 1;
            opcode_function_intm <= opcode_function;
            buffer_address_intm <= buffer_address;
            memory_address_intm <= memory_address;

        end
    end
end

//////////////////////////////////////////////////////////////////////////////////////////
// Pipeline logic to serially get weights from the register,
// Stage 1: Get ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) element and send to next stage
// Stage 2: Get Y_SCALED-1 number of elements from stage above
// Stage 3: Send this data to the compute unit

logic stage_0_1;
// Stage 0 block
always_ff @(posedge clk) begin
    if(instruction_ready_compute_act_intm == 1 && reg_last == 0) begin
        read_req <= 1;
        read_mode <= memory_address_intm;
        read_address <= buffer_address_intm;
        stage_0_1 <= 1;
    end

    else begin
        stage_0_1 <= 0;
    end

end

logic [MUL_DATAWIDTH*M*BETA - 1 : 0] stage1_data;
logic [MUL_DATAWIDTH - 1 : 0] stage1_intm;
localparam STAGE1A_COUNTER = 2;
localparam STAGE1B_COUNTER = M*BETA;
integer stage1a_count;
logic stage1_ready;
integer stage1b_count;
logic stage1a_ready, stage1b_ready;
// Stage 1A block
always_ff @(posedge clk) begin
    if(stage_0_1 == 1) begin
        if(stage1a_count < STAGE1A_COUNTER) begin
            stage1_intm[stage1a_count*(MUL_DATAWIDTH/2) +: MUL_DATAWIDTH/2] <= read_data;
            stage1a_count <= stage1a_count + 1;
            stage1a_ready <= 0;
        end

        else begin
            stage1a_ready <= 1;
            stage1a_count <= 0;
        end
        end
end

// Stage 1B block
always_ff @(posedge clk) begin
    if(stage1a_ready == 1) begin
        if(stage1b_count < STAGE1B_COUNTER) begin
            stage1_data[stage1b_count*(MUL_DATAWIDTH) +: (MUL_DATAWIDTH)] <= stage1_intm;
            stage1b_count = stage1b_count + 1;
        end

        else begin
            stage1b_count <= 0;
            stage1b_ready <= 1;
        end
    end

    else begin
        stage1b_ready <= 0;
    end
end

// Stage 2 Block
localparam STAGE2_COUNTER = X_SCALED;
logic [MUL_DATAWIDTH*M*BETA - 1 : 0] stage2_data [0 : X_SCALED - 1];
integer stage2_count;
logic stage2_ready;
always_ff @(posedge clk) begin
    if(stage1b_ready == 1) begin
        if(stage2_count < STAGE2_COUNTER_ACC) begin
            stage2_data[stage2_count] <= stage1_data;
            stage2_count = stage2_count + 1;
        end

        else begin
            stage2_count <= 0;
            stage2_ready <= 1;
        end
    end

    else begin
        stage2_ready <= 0;
    end
end

// Stage 3 Block
always_ff @(posedge clk) begin
    if(stage2_ready == 1) begin
        act_fifo_data <= stage2_data;
        act_fifo_valid <= X_SCALED'{1};
    end

    else begin
        act_fifo_valid <= X_SCALED'{0};
    end
end
//////////////////////////////////////////////////////////////////////////////////////////




    
endmodule