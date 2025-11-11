//////////////////////////////////////////////////////////
// Copyright Ethan Weinstock, Garrett Botkin, Jingsong Guo
// Variable With 2D ram structure
// Single index read and write
//////////////////////////////////////////////////////////

`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module L1_buffer
#(
    parameter DATA_WIDTH,
    parameter LANE_COUNT,
    parameter DATA_DEPTH
) 
(
    input logic clk,

    input logic enable,
    input logic write,
    input logic [DATA_WIDTH-1:0] data_in [0 : LANE_COUNT-1],
    input logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] index,

    output logic [DATA_WIDTH-1:0] data_out [0 : LANE_COUNT-1]
);

    logic [DATA_WIDTH-1:0] bram [0: DATA_DEPTH - 1][0 : LANE_COUNT-1];

    always_ff @( posedge clk) begin
        if (enable) begin
            if (write)
                bram[index] <= data_in;
            else
                data_out <= bram[index];
        end
    end

endmodule