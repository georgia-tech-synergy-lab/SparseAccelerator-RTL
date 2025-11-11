module compute_control
import vTPU_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic instruction_ready_compute,
    
    input logic [3:0] opcode_function,
    input logic [$clog2(NUM_REGS) - 1 : 0] buffer_address,
    input logic [15 : 0] memory_address,

    output logic instruction_ready_compute_acc,
    output logic instruction_ready_compute_act,

    output logic start_compute,

    output logic [3:0] opcode_function_out,
    output logic [$clog2(NUM_REGS) - 1 : 0] buffer_address_out,
    output logic [15 : 0] memory_address_out
);


logic start_counter, stop_counter;
integer count;
always_ff @(posedge clk) begin
    if(rst_n ==0) begin
        count <= 0;
    end


    else begin
        if(start == 1 && stop == 0) begin
            count <= count + 1;
        end

        else if(start ==0 && stop == 1) begin
            count <= 0;
        end
    end
    
end
always_ff @(posedge clk) begin
    if(rst_n == 0) begin



    end

    if(instruction_ready_compute == 1) begin
        instruction_ready_compute_acc <= 1;
        instruction_ready_compute_act <= 1;
        opcode_function_out <= opcode_function;
        buffer_address_out <= buffer_address;
        memory_address_out <= memory_address;
        start <= 1;
    end

    else begin
        start <= 0;
        instruction_ready_compute_acc <= 0;
        instruction_ready_compute_act <= 0;
    end
end


always_ff @(posedge clk) begin
    if(count == 100) begin
        stop <= 1;
        start_compute <= 1;
    end

    else begin
        stop <= 0;
        start_compute <= 0;
    end
    
end


endmodule