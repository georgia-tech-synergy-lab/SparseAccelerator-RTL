// Take data from outside world and load into corresponding registers
// Should handle normal registers and metadata separately based on the instruction
// This module will handle control logic for reg_load, drain all of which will involve register writes
// We should be able to load register and drain to a register simultaneously, add that functionality as long as they are to different registers
// Cannot do point above, only one write port available

// TODO: Complete drain stage control
module register_write_controller
import vTPU_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic instruction_ready_reg_load,
    input logic instruction_ready_drain,

    // Instruction Identifier
    input logic [3:0] opcode_function,
    input logic [$clog2(NUM_REGS) - 1 : 0] buffer_address,
    input logic [15 : 0] memory_address,

    // Input Data Bus from outside world
    input logic [7 : 0] input_data,
    input logic input_data_req,
    output logic input_data_ack,

    // Outputs to VEGETA reg
    output logic write_req,
    output logic [1:0] write_mode,
    output logic [$clog2(NUM_REGS) - 1 : 0] write_address,
    output logic [7 : 0] write_data, // Assuming 8-bit bus

    // Inputs from VEGETA Reg
    input logic write_busy,
    input logic write_done,

    // Outputs to META reg
    output logic write_req_meta,
    output logic [1:0] write_mode_meta,
    output logic [$clog2(NUM_REGS) - 1 : 0] write_address_meta,
    output logic [7 : 0] write_data_meta, // Assuming 8-bit bus

    // Inputs from META Reg
    input logic write_busy_meta,
    input logic write_done,

    // TODO: Signals from accumulator below compute unit


    output wire logic reg_load_stage_ready,
    output logic drain_ready

);

// This signal should also depend on drain_ready dependent signals because we cannot write simultaenously
assign reg_load_stage_ready = write_busy || write_busy_meta;
logic instruction_ready_reg_load_intm;
logic [3:0] opcode_function_intm,
logic [$clog2(NUM_REGS) - 1 : 0] buffer_address_intm,
logic [15 : 0] memory_address_intm,

initial begin
    write_req <= 0;
    write_req_meta <= 0;
    write_mode <= 0;
    write_mode_meta <= 0;
    write_address <= 0;
    write_address_meta <= 0;
    write_data <= 0;
    write_data_meta <= 0;
    // reg_load_stage_ready <= 0;
    drain_ready <= 0;
    input_data_ack <= 0;
    instruction_ready_reg_load_intm <= 0;
end

always_ff @(posedge clk) begin
    if(rst_n == 0) begin
        // reg_load_stage_ready <= 0;
        drain_ready <= 0;
        instruction_ready_reg_load_intm <= 0;
    end

    else begin
        if(instruction_ready_reg_load == 1 && write_done == 0) begin
            instruction_ready_reg_load_intm <= 1;
            opcode_function_intm <= opcode_function;
            buffer_address_intm <= buffer_address;
            memory_address_intm <= memory_address;
        end

        else if(write_done == 1)
            instruction_ready_reg_load_intm <= 0;

        if (instruction_ready_drain == 1) begin
            
        end

    end
    
end

// Used for transfer
always_ff @(posedge clk) begin
    if(rst_n == 1'b0) begin
        write_req <= 0;
        write_req_meta <= 0;
        write_mode <= 0;
        write_mode_meta <= 0;
        write_address <= 0;
        write_address_meta <= 0;
        write_data <= 0;
        write_data_meta <= 0;
        input_data_ack <= 0;
    end

    else begin
        if(instruction_ready_reg_load_intm == 1 && write_done == 0) begin
            
            if(opcode_function_intm == 0 && input_data_req == 1) begin // Writing to metadata register
                write_req_meta <= 1;
                write_mode_meta <= memory_address_intm;
                write_address_meta <= buffer_address_intm;
                write_data_meta <= input_data;
                input_data_ack <= 1;
            end

            else begin
                write_req_meta <= 0;
            end

            if(opcode_function_intm == 1 && input_data_req == 1) begin
                write_req <= 1;
                write_mode <= memory_address_intm;
                write_address <= buffer_address_intm;
                write_data <= input_data;
                input_data_ack <= 1;
            end

            else begin
                write_req <= 1;
            end
        end

        else begin
            write_req_meta <= 0;
            write_req <= 0;
            input_data_ack <= 0;
        end
    end
end

    
endmodule