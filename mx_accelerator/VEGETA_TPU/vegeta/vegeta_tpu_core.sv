module vegeta_tpu_core 
import vTPU_pack::*;
#(
    parameter MATRIX_WIDTH = 14,
    parameter WEIGHT_BUFFER_DEPTH = 32768,
    parameter UNIFIED_BUFFER_DEPTH = 4096
) (
    input logic clk,
    input logic rst,
    input logic enable,

    input BYTE_TYPE weight_write_port [0 : MATRIX_WIDTH - 1],
    input WEIGHT_ADDRESS_TYPE weight_address,
    input logic weight_enable,
    input logic weight_write_enable [0 : MATRIX_WIDTH - 1],

    input BYTE_TYPE buffer_write_port [0 : MATRIX_WIDTH - 1],
    output BYTE_TYPE buffer_read_port [0 : MATRIX_WIDTH - 1],
    input BUFFER_ADDRESS_TYPE buffer_address,
    input logic buffer_enable,
    input logic buffer_write_enable [0 : MATRIX_WIDTH - 1]

    input INSTRUCTION_TYPE instruction_port,
    input logic instruction_enable,

    output logic busy,
    output logic synchronize
);

logic BUFFER_ADDRESS_TYPE buffer_address0;
logic buffer_en0;
BYTE_TYPE buffer_read_port0 [0 : MATRIX_WIDTH - 1];

BUFFER_ADDRESS_TYPE buffer_address1;
logic buffer_write_en1;
BYTE_TYPE buffer_write_port1 [0 : MATRIX_WIDTH - 1];

WEIGHT_ADDRESS_TYPE weight_address0;
logic weight_en0;
BYTE_TYPE weight_read_port0 [0 : MATRIX_WIDTH - 1];

BYTE_TYPE sds_systolic_output [0 : MATRIX_WIDTH - 1];

logic mmu_weight_signed;
logic mmu_systolic_signed;

logic mmu_activate_weight;
logic mmu_load_weight;
BYTE_TYPE mmu_weight_address;

WORD_TYPE mmu_result_data [0 : MATRIX_WIDTH - 1];

ACCUMULATOR_ADDRESS_TYPE reg_write_address;
logic reg_write_en;
logic reg_accumulate;
ACCUMULATOR_ADDRESS_TYPE reg_read_adrress;
WORD_TYPE reg_read_port [0 : MATRIX_WIDTH - 1];

ACTIVATION_BIT_TYPE activation_function;
logic activation_signed;

WEIGHT_INSTRUCTION_TYPE weight_instruction;
logic weight_instruction_en;
logic weight_read_en;
logic weight_resource_busy;

INSTRUCTION_TYPE mmu_instruction;
logic mmu_instruction_en;
logic buf_read_en;
logic mmu_sds_en;
logic mmu_resource_busy;

INSTRUCTION_TYPE activation_instruction;
logic activation_instruction_en;
logic activation_resource_busy;

logic instruction_busy;
INSTRUCTION_TYPE instruction_output;
logic instruction_read;

logic control_busy;
logic weight_busy;
logic matrix_busy;
logic activation_busy;

weight_buffer #(
    .MATRIX_WIDTH(MATRIX_WIDTH),
    .TILE_WIDTH(WEIGHT_BUFFER_DEPTH)
) weight_buffer_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .address0(weight_address0),
    .en0(weight_en0),
    .write_en0(1'b0),
    .write_port0('{default: '0}),
    .read_port0(weight_read_port0),
    .address1(weight_address),
    .en1(weight_enable),
    .write_en1(weight_write_enable),
    .write_port1(weight_write_port),
    .read_port1()
);

unified_buffer #(
    .MATRIX_WIDTH(MATRIX_WIDTH),
    .TILE_WIDTH(UNIFIED_BUFFER_DEPTH)
) unified_buffer_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .master_address(buffer_address),
    .master_en(buffer_enable),
    .master_write_en(buffer_write_enable),
    .master_write_port(buffer_write_port),
    .master_read_port(buffer_read_port),
    .address0(buffer_address0),
    .en0(buffer_en0),
    .read_port0(buffer_read_port0),
    .address1(buffer_address1),
    .en1(buffer_write_en1),
    .write_en1(buffer_write_en1),
    .write_port1(buffer_write_port1)
);

systolic_data_setup #(.MATRIX_WIDTH(MATRIX_WIDTH)) 
systolic_data_setup_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .data_input(buffer_read_port0),
    .systolic_output(sds_systolic_output)
);

matrix_multiply_unit #(.MATRIX_WIDTH(MATRIX_WIDTH)) 
matrix_multiply_unit_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .weight_data(weight_read_port0),
    .weight_signed(mmu_weight_signed),
    .systolic_data(sds_systolic_output),
    .systolic_signed(mmu_systolic_signed),
    .activate_weight(mmu_activate_weight),
    .load_weight(mmu_load_weight),
    .weight_address(mmu_weight_address),
    .result_data(mmu_result_data)
);

register_file #(
    .MATRIX_WIDTH(MATRIX_WIDTH),
    .REGISTER_DEPTH(512)
) register_file_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .write_address(reg_write_address),
    .write_port(mmu_result_data),
    .write_enable(reg_write_en),
    .accumulate(reg_accumulate),
    .read_address(reg_read_address),
    .read_port(reg_read_port)
);

activation #(.MATRIX_WIDTH(MATRIX_WIDTH)) activation_i 
(
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .activation_function(activation_function),
    .signed_not_unsigned(activation_signed),
    .activation_input(reg_read_port),
    .activation_output(buffer_write_port1)
);

weight_control #(.MATRIX_WIDTH(MATRIX_WIDTH))
weight_control_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .instruction(weight_instruction),
    .instruction_en(weight_instruction_en),
    .weight_read_en(weight_en0),
    .weight_buffer_address(weight_address0),
    .load_weight(mmu_load_weight),
    .weight_address(mmu_weight_address),
    .weight_signed(mmu_weight_signed),
    .busy(weight_busy),
    .resource_busy(weight_resource_busy)
);

matrix_multiply_control #(.MATRIX_WIDTH(MATRIX_WIDTH))
matrix_multiply_control_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .instruction(mmu_instruction),
    .instruction_en(mmu_instruction_en),
    .buf_to_sds_addr(buffer_address0),
    .buf_read_en(buffer_en0),
    .mmu_sds_en(mmu_sds_en),
    .mmu_signed(mmu_systolic_signed),
    .activate_weight(mmu_activate_weight),
    .acc_addr(reg_write_address),
    .accumulate(reg_accumulate),
    .acc_enable(reg_write_en),
    .busy(matrix_busy),
    .resource_busy(mmu_resource_busy)
);

activation_control #(.MATRIX_WIDTH(MATRIX_WIDTH)) 
activation_control_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .instruction(activation_instruction),
    .instruction_en(activation_instruction_en),
    .acc_to_act_addr(reg_read_address),
    .activation_function(activation_function),
    .signed_not_unsigned(activation_signed),
    .act_to_buf_addr(buffer_address1),
    .buf_write_en(buffer_write_en1),
    .busy(activation_busy),
    .resource_busy(activation_resource_busy)
);

look_ahead_buffer look_ahead_buffer_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .instruction_busy(instruction_busy),
    .instruction_input(instruction_port),
    .instruction_write(instruction_enable),
    .instruction_output(instruction_output),
    .instruction_read(instruction_read)
);

control_coordinator control_coordinator_i (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .instruction(instruction_output),
    .instruction_en(instruction_read),
    .busy(instruction_busy),
    .weight_busy(weight_busy),
    .weight_resource_busy(weight_resource_busy),
    .weight_instruction(weight_instruction),
    .weight_instruction_en(weight_instruction_en),
    .matrix_busy(matrix_busy),
    .matrix_resource_busy(mmu_resource_busy),
    .matrix_instruction(mmu_instruction),
    .matrix_instruction_en(mmu_instruction_en),
    .activation_busy(activation_busy),
    .activation_resource_busy(activation_resource_busy),
    .activation_instruction(activation_instruction),
    .activation_instruction_en(activation_instruction_en),
    .synchronize(synchronize)
);

assign busy = instruction_busy;

endmodule