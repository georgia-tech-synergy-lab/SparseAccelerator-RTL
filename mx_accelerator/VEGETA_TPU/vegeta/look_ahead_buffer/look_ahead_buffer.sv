module look_ahead_buffer 
import vTPU_pkg::*;
(
    input logic clk,
    input logic rst,

    input logic instruction_busy,

    input INSTRUCTION_TYPE instruction_input,
    input logic instruction_write,

    output INSTRUCTION_TYPE  instruction_output,
    output logic instruction_read
);

INSTRUCTION_TYPE input_reg_cs = '0;
INSTRUCTION_TYPE input_reg_ns;

logic input_write_cs = 0;
logic input_write_ns;

INSTRUCTION_TYPE pipe_reg_cs = '0;
INSTRUCTION_TYPE pipe_reg_ns;

logic pipe_write_cs = 0;
logic ppe_write_ns;

INSTRUCTION_TYPE output_reg_cs = '0;
INSTRUCTION_TYPE output_reg_ns;

logic output_write_cs =0;
logic output_write_ns;

assign input_reg_ns = instruction_input;
assign instruction_output = (instruction_busy == 0) ? output_reg_cs : '0;
assign input_write_ns = instruction_write;
assign instruction_read = (instruction_busy == 0) ? output_write_cs : '0;

always_comb begin
    if (pipe_write_cs) begin
        if (pipe_reg_cs.op_code[OP_CODE_WIDTH-1:3] == 5'b00001) begin
            if (input_write_cs) begin
                pipe_reg_ns     = input_reg_cs;
                output_reg_ns   = pipe_reg_cs;
                pipe_write_ns   = input_write_cs;
                output_write_ns = pipe_write_cs;
            end else begin
                pipe_reg_ns     = pipe_reg_cs;
                output_reg_ns   = init_instruction;
                pipe_write_ns   = pipe_write_cs;
                output_write_ns = 1'b0;
            end
        end else begin
            pipe_reg_ns     = input_reg_cs;
            output_reg_ns   = pipe_reg_cs;
            pipe_write_ns   = input_write_cs;
            output_write_ns = pipe_write_cs;
        end
    end else begin
        pipe_reg_ns     = input_reg_cs;
        output_reg_ns   = pipe_reg_cs;
        pipe_write_ns   = input_write_cs;
        output_write_ns = pipe_write_cs;
    end
end

always_ff @(posedge clk) begin
    if (rst == 1) begin
        input_reg_cs    <= '0;
        pipe_reg_cs     <= '0;
        output_reg_cs   <= '0;
        
        input_write_cs  <= 1'b0;
        pipe_write_cs   <= 1'b0;
        output_write_cs <= 1'b0;
    end else begin
        if (enable && instruction_busy == 1'b0) begin
            input_reg_cs    <= input_reg_ns;
            pipe_reg_cs     <= pipe_reg_ns;
            output_reg_cs   <= output_reg_ns;
            
            input_write_cs  <= input_write_ns;
            pipe_write_cs   <= pipe_write_ns;
            output_write_cs <= output_write_ns;
        end
    end
end
    
endmodule