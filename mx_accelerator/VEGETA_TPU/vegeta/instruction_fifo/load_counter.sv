module load_counter
import vTPU_pkg::*;
#(
    parameter COUNTER_WIDTH = 32,
    parameter MATRIX_WIDTH = 14
) 
(
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [COUNTER_WIDTH-1 : 0] start_val,
    input logic load,
    output logic [COUNTER_WIDTH-1 : 0] count_val
);

logic [COUNTER_WIDTH-1 : 0] counter_input_cs = '0;
logic [COUNTER_WIDTH-1 : 0] counter_input_ns;

logic [COUNTER_WIDTH-1 : 0] input_pipe_cs = '0;
logic [COUNTER_WIDTH-1 : 0] input_pipe_ns 

logic [COUNTER_WIDTH-1 : 0] counter_cs = '0;
logic [COUNTER_WIDTH-1 : 0] counter_ns;

logic load_cs = 0;
logic load_ns;

assign load_ns = load;
/*
_ _ _ _
*/
assign input_pipe_ns = (load == 1) ? start_val : (COUNTER_WIDTH'd1);

assign counter_input_ns = input_pipe_cs;
assign counter_ns = counter_cs + counter_input_cs;
assign count_val = counter_cs;
    
always_ff @(posedge clk) begin
    if(rst == 1) begin
        counter_input_cs <= 0;
        input_pipe_cs <= 0;
        load_cs <= 0;
    end
    else begin
        if(enable == 1) begin
            counter_input_cs <= counter_input_ns;
            input_pipe_cs <= input_pipe_ns;
            load_cs <= load_ns;
        end
    end

    if(load_cs == 1) begin
        counter_cs <= 0;
    end

    else begin
        if(enable == 1) begin
            counter_cs <= counter_ns;
        end
    end
end
endmodule