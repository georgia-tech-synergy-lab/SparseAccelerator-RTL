module macc 
import vTPU_pkg::*;
#(
    parameter LAST_SUM_WIDTH = 0,
    parameter PARTIAL_SUM_WIDTH = 2*EXTENDED_BYTE_TYPE
) 
(
    input logic clk,
    input logic reset,
    input logic enable,
    input EXTENDED_BYTE_TYPE weight_input,
    input logic preload_weight,
    input logic load_weight,
    input EXTENDED_BYTE_TYPE in,
    input logic [LAST_SUM_WIDTH-1 : 0] last_sum,
    output logic [PARTIAL_SUM_WIDTH - 1 : 0] partial_sum
);

EXTENDED_BYTE_TYPE preweight_cs = '0;
EXTENDED_BYTE_TYPE preweight_ns;

EXTENDED_BYTE_TYPE weight_cs = '0;
EXTENDED_BYTE_TYPE weight_ns;

EXTENDED_BYTE_TYPE input_cs = '0;
EXTENDED_BYTE_TYPE input_ns;

MUL_HALFWORD_TYPE pipeline_cs = '0;
MUL_HALFWORD_TYPE pipeline_ns;

logic [PARTIAL_SUM_WIDTH-1 : 0] partial_sum_cs;
logic [PARTIAL_SUM_WIDTH-1 : 0] partial_sum_ns;

assign input_ns = input;
assign preweight_ns = weight_input;
assign weight_ns = preweight_cs;

always_comb begin
    EXTENDED_BYTE_TYPE input_v;
    EXTENDED_BYTE_TYPE weight_v;
    MUL_HALFWORD_TYPE pipeline_cs_v;
    MUL_HALFWORD_TYPE pipeline_ns_v;
    logic [LAST_SUM_WIDTH-1 : 0] last_sum_v;
    logic [PARTIAL_SUM_WIDTH-1 : 0] partial_sum_v;

    input_v = input_cs;
    weight_v = weight_cs;
    pipeline_cs_v = pipeline_cs;
    last_sum_v = last_sum;

    pipeline_ns_v = signed'(input_v) * signed'(weight_v);

    if(LAST_SUM_WIDTH > 0 && LAST_SUM_WIDTH < PARTIAL_SUM_WIDTH)
        partial_sum_v = {pipeline_cs_v[2*EXTENDED_BYTE_WIDTH - 1], pipeline_cs_v} + {last_sum_v[LAST_SUM_WIDTH-1], last_sum_v};
    else if(LAST_SUM_WIDTH > 0 && LAST_SUM_WIDTH == PARTIAL_SUM_WIDTH)
        partial_sum_v = pipeline_cs_v + last_sum_v;
    else
        partial_sum_v = pipeline_cs_v;

    pipeline_ns = pipeline_ns_v;
    partial_sum_ns = partial_sum_v;
end

assign partial_sum = partial_sum_cs;

always_ff @(posedge clk) begin
    if (reset == 1) begin
        preweight_cs    <= '0;
        weight_cs       <= '0;
        input_cs        <= '0;
        pipeline_cs     <= '0;
        partial_sum_cs  <= '0;
    end 
    else begin
        if (preload_weight == 1) begin
            preweight_cs <= preweight_ns;
        end
        
        if (load_weight == 1) begin
            weight_cs = weight_ns;
        end
        
        if (enable == 1) begin
            input_cs        = input_ns;
            pipeline_cs     = pipeline_ns;
            partial_sum_cs  = partial_sum_ns;
        end
    end
end

endmodule