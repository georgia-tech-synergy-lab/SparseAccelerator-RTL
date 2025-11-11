//////////////////////////////////////////////////////////
// Copyright Ethan Weinstock, Garrett Botkin, Jingsong Guo
// Variable With 2D ram structure
// Single index read
// Independent index write
//////////////////////////////////////////////////////////

`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module L1_buffer_independent_write
#(
    parameter DATA_WIDTH,
    parameter LANE_COUNT,
    parameter DATA_DEPTH
) 
(
    input logic clk,

    input logic enable,
    input logic write [0 : LANE_COUNT-1],
    input logic [DATA_WIDTH-1:0] data_in [0 : LANE_COUNT-1],
    input logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] write_index [0 : LANE_COUNT-1],
    input logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] read_index,

    output logic [DATA_WIDTH-1:0] data_out [0 : LANE_COUNT-1]
);

    logic [DATA_WIDTH-1:0] bram [0: DATA_DEPTH - 1][0 : LANE_COUNT-1];

    logic any_write;

    integer i;
    always_comb begin
        any_write = '0;
        for (i = 0; i < LANE_COUNT; i++)
            any_write = any_write | write[i];
    end

    always_ff @( posedge clk) begin
        if (enable && ~any_write)
            data_out <= bram[read_index];
    end

    genvar lane;
    generate
        for (lane = 0; lane < LANE_COUNT; lane++) begin
            always_ff @( posedge clk) begin
                if (enable && write[lane]) begin
                    bram[write_index[lane]][lane] <= data_in[lane];
                end
            end
        end
    endgenerate

endmodule