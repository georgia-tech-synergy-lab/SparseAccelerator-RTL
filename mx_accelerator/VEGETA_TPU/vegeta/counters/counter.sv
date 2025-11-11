module counter #(
    parameter COUNTER_WIDTH = 32
) (
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [COUNTER_WIDTH - 1 : 0] end_val,
    input logic load,

    output logic [COUNTER_WIDTH-1 : 0] count_val,

    output logic count_event
);

logic [COUNTER_WIDTH - 1 : 0]counter = '0;
logic [COUNTER_WIDTH - 1 : 0] end_reg = '0;
logic event_cs = 0;
logic event_ns;

logic event_pipe_cs = 0;
logic event_pipe_ns;

assign count_val = counter;
assign count_event = event_pipe_cs;
assign event_pipe_ns = event_cs;

always_comb begin
    if(counter == end_reg) begin
        event_ns = 1;
    end

    else begin
        event_ns = 0;
    end
end

always_ff @(posedge clk) begin
    if(reset == 1) begin
        counter <= '0;
        event_cs <= 0;
        event_pipe_cs <= 0;
    end

    else begin
        if(enable == 1) begin
            counter <= counter + 1;
            event_cs <= event_ns;
            event_pipe_cs <= event_pipe_ns;
        end
    end

    if(load == 1) begin
        end_reg <= end_val; 
    end
end

endmodule