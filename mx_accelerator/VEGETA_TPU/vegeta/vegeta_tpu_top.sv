module vegeta_tpu_top
import vTPU_pack::*;
#(
    parameter MATRIX_WIDTH  = 14,
    parameter WEIGHT_BUFFER_DEPTH = 32768,
    parameter UNIFIED_BUFFER_DEPTH  = 4096
) (
    input logic clk,
    input logic rst,
    input logic enable,

    output WORD_TYPE runtime_count,
    input WORD_TYPE lower_instruction_word,
    input WORD_TYPE middle_instruction_word,
    input HALFWORD_TYPE upper_instruction_word,
    input logic instruction_write_en [0 : 2],

    output logic instruction_empty,
    output logic instruction_full,

    input BYTE_TYPE weight_write_port [0:MATRIX_WIDTH-1],
    input WEIGHT_ADDRESS_TYPE weight_address,
    input logic weight_enable,
    input logic weight_write_enable [0:MATRIX_WIDTH-1],

    input BYTE_TYPE buffer_write_port [0:MATRIX_WIDTH-1],
    output BYTE_TYPE buffer_read_port [0:MATRIX_WIDTH-1],
    input BUFFER_ADDRESS_TYPE buffer_address,
    input logic buffer_enable,
    input logic buffer_write_enable [0:MATRIX_WIDTH-1],

    output logic synchronize
);

INSTRUCTION_TYPE instruction;
logic empty;
logic full;

logic instruction_enable;
logic busy;
logic synchronize_in;

runtime_counter runtime_counter_i (
    .clk(clk),
    .rst(reset),
    .instruction_en(instruction_enable),
    .synchronize(synchronize_in),
    .counter_val(runtime_count)
);

instruction_fifo instruction_fifo_i (
    .clk(clk),
    .rst(reset),
    .lower_word(lower_instruction_word),
    .middle_word(middle_instruction_word),
    .upper_word(upper_instruction_word),
    .write_en(instruction_write_en),
    .output(instruction),
    .next_en(instruction_enable),
    .empty(empty),
    .full(full)
);

assign instruction_empty = empty;
assign instruction_full = full;

tpu_core #(
    .MATRIX_WIDTH(MATRIX_WIDTH),
    .WEIGHT_BUFFER_DEPTH(WEIGHT_BUFFER_DEPTH),
    .UNIFIED_BUFFER_DEPTH(UNIFIED_BUFFER_DEPTH)
) tpu_core_i (
    .clk(clk),
    .rst(reset),
    .enable(enable),
    .weight_write_port(weight_write_port),
    .weight_address(weight_address),
    .weight_enable(weight_enable),
    .weight_write_enable(weight_write_enable),
    .buffer_write_port(buffer_write_port),
    .buffer_read_port(buffer_read_port),
    .buffer_address(buffer_address),
    .buffer_enable(buffer_enable),
    .buffer_write_enable(buffer_write_enable),
    .instruction_port(instruction),
    .instruction_enable(instruction_enable),
    .busy(busy),
    .synchronize(synchronize_in)
);

assign synchronize = synchronize_in;


endmodule