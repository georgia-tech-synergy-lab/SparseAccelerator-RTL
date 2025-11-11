//////////////////////////////////////////////////////////
// Copyright Ethan Weinstock, Garrett Botkin, Jingsong Guo
// Variable With 2D ram structure
// Independent index read
// Single index write
//////////////////////////////////////////////////////////

`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module L1_buffer_independent_read
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
    input logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] write_index,
    input logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] read_index [0 : LANE_COUNT-1],
    input logic read_enable [0 : LANE_COUNT-1],

    output logic [DATA_WIDTH-1:0] data_out [0 : LANE_COUNT-1]
);

    logic [DATA_WIDTH-1:0] bram [0: DATA_DEPTH - 1][0 : LANE_COUNT-1];

    always_ff @( posedge clk) begin
        if (enable && write)
            bram[write_index] <= data_in;
    end

    genvar lane;
    generate
        for (lane = 0; lane < LANE_COUNT; lane++) begin
            always_ff @( posedge clk) begin
                if (enable && ~write) begin
                    if (read_enable[lane])
                        data_out[lane] <= bram[read_index[lane]][lane];
                    else
                        data_out[lane] <= '0;
                end
            end
        end
    endgenerate

endmodule