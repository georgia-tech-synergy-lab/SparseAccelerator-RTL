module instruction_fifo
import vTPU_pack::*;
#(
    parameter FIFO_DEPTH = 32
) 
(
    input logic clk,
    input logic rst,

    input WORD_TYPE lower_word,
    input WORD_TYPE middle_word,
    input HALFWORD_TYPE upper_word,
    input logic write_en [0 : 2],

    output INSTRUCTION_TYPE out,
    input logic next_en,

    output logic empty,
    output logic full
);

logic empty_vector [0:2];
logic full_vector [0:2];

WORD_TYPE lower_output;
WORD_TYPE middle_output;
HALFWORD_TYPE upper_output;

assign empty = empty_vector[0] || empty_vector[1] || empty_vector[2];
assign full = full_vector[0] || full_vector[1] || full_vector[2];

assign out = {upper_output, middle_output, lower_output};

fifo fifo_0 #(.FIFO_WIDTH(4*BYTE_WIDTH), .FIFO_DEPTH(FIFO_DEPTH))
(
    .clk(clk),
    .rst(rst),
    .in(lower_word),
    .write_en(write_en[0]),
    .out(lower_output),
    .next_en(next_en),
    .empty(empty_vector[0]),
    .full(full_vector[0])
);

fifo fifo_1 #(.FIFO_WIDTH(4*BYTE_WIDTH), .FIFO_DEPTH(FIFO_DEPTH))
(
    .clk(clk),
    .rst(rst),
    .in(middle_word),
    .write_en(write_en[1]),
    .out(middle_output),
    .next_en(next_en),
    .empty(empty_vector[1]),
    .full(full_vector[1])
);

fifo fifo_2 #(.FIFO_WIDTH(2*BYTE_WIDTH), .FIFO_DEPTH(FIFO_DEPTH))
(
    .clk(clk),
    .rst(rst),
    .in(upper_word),
    .write_en(write_en[2]),
    .out(upper_output),
    .next_en(next_en),
    .empty(empty_vector[2]),
    .full(full_vector[2])
);
endmodule