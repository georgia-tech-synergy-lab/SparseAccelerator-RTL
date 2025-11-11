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
module weight_acc_reader
import vTPU_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic instruction_ready_weight_load,
    input logic instruction_ready_compute_acc,

    input logic [3:0] opcode_function,
    input logic [$clog2(NUM_REGS) - 1 : 0] buffer_address,
    input logic [15 : 0] memory_address,

    // ACC FIFOS
    output logic [ALPHA*ADD_DATAWIDTH-1 : 0] acc_fifo_data [0: Y_SCALED-1],
    output logic acc_fifo_valid [0:Y_SCALED-1],

    // This will be probided by a master controller
    input logic [1:0] mode, // To identify if we are in only weight load stage or compute stage with possible overlapped weight load
    input logic [1 : 0] gemm_mode, // dense, or 2:4, 1:4 etc

    // Inputs from vegeta_compute top


    // Outputs to vegeta_compute top
    output logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in [0 : Y_SCALED-1],
    output logic [ADD_DATAWIDTH*ALPHA-1 : 0] acc_in [0 : Y_SCALED-1],
    output logic weight_transferring_in,
    output logic i_wb, // buffer select into which next load will happen
    output logic [1:0] mode_out, // To identify if we are in only weight load stage or compute stage with possible overlapped weight load
    output logic [1 : 0] gemm_mode_out, // dense, or 2:4, 1:4 etc

    // Inputs from vegeta_reg
    input logic [7:0] read_data,
    input logic row_last, // To identify last element of a row
    input logic reg_last, // To identify last element of the register (When reg_last and row_last are one means data transfer is complete)

    // Outputs to vegeta_reg
    output logic read_req,
    output logic [1 : 0] read_mode,
    output logic [$clog2(NUM_REGS)-1 : 0] read_address,

    // Inputs from meta reg
    input logic [7:0] read_data_meta,
    input logic row_last_meta, // To identify last element of a row
    input logic reg_last_meta, // To identify last element of the register (When reg_last and row_last are one means data transfer is complete)

    // Outputs to meta reg
    output logic read_req_meta,
    output logic [1 : 0] read_mode_meta,
    output logic [$clog2(NUM_REGS)-1 : 0] read_address_meta,


    output logic weight_load_ready,  
);

logic instruction_ready_weight_load_intm;
logic instruction_ready_compute_acc_intm;
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
        // Buffer the data from instruction fifo module
        if(instruction_ready_weight_load == 1) begin
            instruction_ready_weight_load_intm <= 1;
            opcode_function_intm <= opcode_function;
            buffer_address_intm <= buffer_address;
            memory_address_intm <= memory_address;
        end

        if(instruction_ready_compute_acc == 1) begin
            instruction_ready_compute_acc_intm <= 1;
            opcode_function_intm <= opcode_function;
            buffer_address_intm <= buffer_address;
            memory_address_intm <= memory_address;

        end
    end
end

// Need a fifo for meta registers because it is faster than the treg load

fifo fifo_meta_data #(.FIFO_WIDTH(2), .FIFO_DEPTH(16))
(
    .clk(clk),
    .rst(rst_n),
    .in(read_data_meta),
    .write_en(meta_data_valid),
    .out(read_data_meta_fifo),
    .next_en(read_data_from_fifo),
    .empty(fifo_empty),
    .full(fifo_full)
);

// TODO:  Follow similar logic for accumulator data, just put the data into Y_SCALED number of FIFOs

// Get accumulator data and load into the Fifos to make systolic movement

logic stage0_1_acc;
// Stage 0 block
always_ff @(posedge clk) begin
    if(instruction_ready_compute_acc_intm == 1 && reg_last == 0) begin
        read_req <= 1;
        read_mode <= memory_address_intm;
        read_address <= buffer_address_intm;
        stage_0_1_acc <= 1;
    end

    else begin
        stage_0_1_acc <= 0;
    end

end

logic [ADD_DATAWIDTH*ALPHA - 1 : 0] stage1_data_acc;
logic [ADD_DATAWIDTH - 1 : 0] stage1_intm_acc;
localparam STAGE1A_COUNTER_ACC = 2;
localparam STAGE1B_COUNTER_ACC = ALPHA;
integer stage1a_count_acc;
logic stage1_ready_acc;
integer stage1b_count_acc;
logic stage1a_ready;
logic stage1a_ready_acc;

// Stage 1A block
always_ff @(posedge clk) begin

    if(stage_0_1_acc == 1) begin
        if(stage1a_count_acc < STAGE1A_COUNTER_ACC) begin
            stage1_intm_acc[stage1a_count_acc*(ADD_DATAWIDTH/2) +: ADD_DATAWIDTH/2] <= read_data;
            stage1a_count_acc <= stage1a_count_acc + 1;
            stage1a_ready_acc <= 0;
        end

        else begin
            stage1a_ready_acc <= 1;
            stage1a_count_acc <= 0;
        end
        end
end

logic stage1b_ready, stage1b_ready_acc;
// Stage 1B block
always_ff @(posedge clk) begin
    if(stage1a_ready_acc == 1) begin
        if(stage1b_count_acc < STAGE1B_COUNTER_ACC) begin
            stage1_data_acc[stage1b_coun_acc*(ADD_DATAWIDTH) +: (ADD_DATAWIDTH)] <= stage1_intm_acc;
            stage1b_count_acc = stage1b_count_acc + 1;
        end

        else begin
            stage1b_count_acc <= 0;
            stage1b_ready_acc <= 1;
        end
    end

    else begin
        stage1b_ready_acc <= 0;
    end
end

// Stage 2 Block
logic stage2_ready, stage2_ready_acc;
localparam STAGE2_COUNTER_ACC = Y_SCALED;
logic [ALPHA*ADD_DATAWIDTH-1 : 0] stage2_data_acc [0 : Y_SCALED - 1];
integer stage2_count_acc;
always_ff @(posedge clk) begin
    if(stage1b_ready_acc == 1) begin
        if(stage2_count_acc < STAGE2_COUNTER_ACC) begin
            stage2_data_acc[stage2_count_acc] <= stage1_data_acc;
            stage2_count_acc = stage2_count_acc + 1;
        end

        else begin
            stage2_count_acc <= 0;
            stage2_ready_acc <= 1;
        end
    end

    else begin
        stage2_ready_acc <= 0;
    end
end

// Stage 3 Block
always_ff @(posedge clk) begin
    if(stage2_ready_acc == 1) begin
        acc_fifo_data <= stage2_data_acc;
        acc_fifo_valid <= Y_SCALED'{1};
    end

    else begin
        acc_fifo_valid <= Y_SCALED'{0};
    end
end


///////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////
// Pipeline logic to serially get weights from the register,
// Stage 1: Get ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) element and send to next stage
// Stage 2: Get Y_SCALED-1 number of elements from stage above
// Stage 3: Send this data to the compute unit

logic stage_0_1;
// Stage 0 block
always_ff @(posedge clk) begin
    if(instruction_ready_weight_load_intm == 1 && reg_last == 0) begin
        read_req <= 1;
        read_mode <= memory_address_intm;
        read_address <= buffer_address_intm;
        stage_0_1 <= 1;
    end

    else begin
        stage_0_1 <= 0;
    end

    // Independently begin loading metadata in the fifos bottleneck is treg
    if(instruction_ready_weight_load_intm == 1 && reg_last_meta == 0) begin
        read_req_meta <= 1;
        read_mode_meta <= memory_address_intm;
        read_address_meta <= buffer_address_intm;
    end

    else begin
        read_req_meta <= 0;
    end
end

logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] stage1_data;
logic [MUL_DATAWIDTH - 1 : 0] stage1_intm;
localparam STAGE1A_COUNTER = 2;
localparam STAGE1B_COUNTER = ALPHA*BETA;
integer stage1a_count;
logic stage1_ready;
integer stage1b_count;

// Stage 1A block
always_ff @(posedge clk) begin

    // Continue loading meta data in fifos, will take data from fifo when required treg is ready
    if(reg_last_meta == 0)
        meta_data_valid <= 1;
    else begin
        meta_data_valid <= 0;
    end


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
            stage1_data[stage1b_count*(MUL_DATAWIDTH + META_DATA_SIZE) +: (MUL_DATAWIDTH + META_DATA_SIZE)] <= {stage1_intm, read_data_meta_fifo};
            read_data_from_fifo <= 1;
            stage1b_count = stage1b_count + 1;
        end

        else begin
            read_data_from_fifo <= 0;
            stage1b_count <= 0;
            stage1b_ready <= 1;
        end
    end

    else begin
        read_data_from_fifo <= 0;
        stage1b_ready <= 0;
    end
end

// Stage 2 Block
localparam STAGE2_COUNTER = Y_SCALED;
logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] stage2_data [0 : Y_SCALED - 1];
integer stage2_count;
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
        weight_in <= stage2_data;
        weight_transferring_in <= 1;
    end

    else begin
        weight_transferring_in <= 0;
    end
end
//////////////////////////////////////////////////////////////////////////////////////////




    
endmodule