// The instruction ready will be high for only one clock cycle, need to change this
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
module instruction_fifo
(
    input logic clk,
    input logic rst_n,
    input logic [INSTRUCTION_WIDTH - 1 : 0] instruction,
    input logic instruction_valid,

    // feedback from units
    input logic reg_load_stage_ready,
    input logic weight_load_ready,
    input logic compute_ready,
    input logic drain_ready,
    input logic store_ready,

    // From register, giving information on which buffer address is currently being serviced
    input logic [$clog2(NUM_REGS) - 1 : 0] current_buffer_loading,

    output logic instruction_ready_reg_load,
    output logic instruction_ready_weight_load,
    output logic instruction_ready_compute,
    output logic instruction_ready_drain,
    output logic instruction_ready_store,

    output logic [3:0] opcode_function,
    output logic [$clog2(NUM_REGS) - 1 : 0] buffer_address,
    output logic [15 : 0] memory_address
);

wire logic fifo_empty, fifo_full;
wire logic [INSTRUCTION_WIDTH-1 : 0] instruction_out;
logic read_instruction;

logic [7 : 0] current_opcode, prev_opcode;
logic stall;

initial begin
    read_instruction <= 0;
    prev_opcode <= 0;
    buffer_address <= 0;
    memory_address <= 0;
end


fifo fifo_0 #(.FIFO_WIDTH(INSTRUCTION_WIDTH), .FIFO_DEPTH(8))
(
    .clk(clk),
    .rst(rst_n),
    .in(instruction),
    .write_en(instruction_valid),
    .out(instruction_out),
    .next_en(read_instruction),
    .empty(fifo_empty),
    .full(fifo_full)
);

// Stage 1: Read Instruction
always_ff @(posedge clk) begin
    if(rst_n == 0) begin
        read_instruction <= 0;
        execute_instruction <= 0;
        buffer_address <= 0;
        memory_address <= 0;
    end

    if(stall == 0 &&  fifo_empty == 0) begin
        read_instruction <= 1;
    end

    else begin
        read_instruction <= 0;
    end
end

// Stage 2: Decode Instruction
always_ff @(posedge clk) begin
    if(rst_n == 0) begin
        stall <= 0;
        instruction_ready_reg_load <= 0;
        instruction_ready_weight_load <= 0;
        instruction_ready_compute <= 0;
        instruction_ready_drain <= 0;
        instruction_ready_store <= 0;
        opcode_function <= 0;
        buffer_address <= 0;
        memory_address <= 0;
    end

    case (instruction_out[7:0])
        1: begin
            instruction_ready_weight_load <= 0;
            instruction_ready_compute <= 0;
            instruction_ready_drain <= 0;
            instruction_ready_store <= 0;

            if(reg_load_stage_ready == 1) begin
                instruction_ready_reg_load <= 1;
                opcode_function <= instruction_out[8 +: 4];
                buffer_address <= instruction_out[12 +: 4];
                memory_address <= instruction_out[16 +: 16];
                stall <= 0;
            end

            else
                instruction_ready_reg_load <= 0;
                stall <= 1;
        end

        2: begin
            instruction_ready_reg_load <= 0;
            instruction_ready_compute <= 0;
            instruction_ready_drain <= 0;
            instruction_ready_store <= 0;
            // We can load weights into SA if the current buffer that is being loaded into reg 
            // is not the same as the one we want to load into SA
            if(weight_load_ready == 1 && current_buffer_loading != instruction_out[12 +: 4];) begin
                instruction_ready_weight_load <= 1;
                opcode_function <= instruction_out[8 +: 4];
                buffer_address <= instruction_out[12 +: 4];
                memory_address <= instruction_out[16 +: 16];
                stall <= 0;
            end

            else
                instruction_ready_weight_load <= 0;
                stall <= 1;
        end

        4: begin
            instruction_ready_reg_load <= 0;
            instruction_ready_weight <= 0;
            instruction_ready_drain <= 0;
            instruction_ready_store <= 0;

            if(compute_ready == 1) begin
                instruction_ready_compute <= 1;
                opcode_function <= instruction_out[8 +: 4];
                buffer_address <= instruction_out[12 +: 4];
                memory_address <= instruction_out[16 +: 16];
                stall <= 0;
            end

            else
                instruction_ready_compute <= 0;
                stall <= 1;
        end

        8: begin
            instruction_ready_reg_load <= 0;
            instruction_ready_weight <= 0;
            instruction_ready_compute <= 0;
            instruction_ready_store <= 0;

            if(drain_ready == 1) begin
                instruction_ready_drain <= 1;
                opcode_function <= instruction_out[8 +: 4];
                buffer_address <= instruction_out[12 +: 4];
                memory_address <= instruction_out[16 +: 16];
                stall <= 0;
            end

            else
                instruction_ready_drain <= 0;
                stall <= 1;
        end

        16: begin
            instruction_ready_reg_load <= 0;
            instruction_ready_weight <= 0;
            instruction_ready_compute <= 0;
            instruction_ready_drain <= 0;
            
            if(store_ready == 1) begin
                instruction_ready_store <= 1;
                opcode_function <= instruction_out[8 +: 4];
                buffer_address <= instruction_out[12 +: 4];
                memory_address <= instruction_out[16 +: 16];
                stall <= 0;
            end

            else
                instruction_ready_store <= 0;
                stall <= 1;
        end
    endcase
end



    
endmodule