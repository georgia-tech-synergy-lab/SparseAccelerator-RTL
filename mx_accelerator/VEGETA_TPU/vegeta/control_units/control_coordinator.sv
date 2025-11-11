module control_coordinator 
import vTPU_pkg::*;
#(


) (
    input logic clk,
    input logic rst,
    input logic enable,

    input INSTRUCTION_TYPE instruction,
    input logic instruction_en,

    output logic busy,

    input logic weight_busy,
    input logic weight_resource_busy,
    output WEIGHT_INSTRUCTION_TYPE weight_instruction,
    output logic weight_instruction_en,

    input logic matrix_busy,
    input logic matrix_resource_busy,
    output INSTRUCTION_TYPE matrix_instruction,
    output logic matrix_instruction_en,

    input logic activation_busy,
    input logic activation_resource_busy,
    output INSTRUCTION_TYPE activation_instruction,
    output logic activation_instruction_en,

    output logic synchronize
);
    logic en_flag_cs [0 : 3] = '{default : '0};
    logic en_flag_ns [0 : 3];

    INSTRUCTION_TYPE instruction_cs = '0;
    INSTRUCTION_TYPE instruction_ns;

    logic instruction_en_cs = 0;
    logic instruction_en_ns;

    logic instruction_running;

    assign instruction_ns = instruction;
    assign instruction_en_ns = instruction_en;
    assign busy = instruction_running;

    always_comb begin
        INSTRUCTION_TYPE instruction_v;
        logic en_flags_ns_v [0 : 3];
        logic set_synchronize_v;

        instruction_v = instruction;

        if(instruction_v.op_code == 'hFF)
            en_flags_ns_v = 4'b0001;
        
        else if (instruction_v.op_code[7] == 1) begin
            en_flags_ns_v = 4'b0010    
        end

        else if (instruction_v.op_code[5] == 1) begin
            en_flags_ns_v = 4'b0100    
        end

        else if (instruction_v.op_code[3] == 1) begin
            en_flags_ns_v = 4'b1000;    
        end

        else
            en_flags_ns_v = 4'b0000;

        en_flag_ns = en_flags_ns_v;
    end

    always_comb begin
        INSTRUCTION_TYPE instruction_v;
        logic instruction_en_v;
        logic en_flags_v [0 : 3];
        logic weights_busy_v;
        logic matrix_busy_v;
        logic activation_busy_v;
        logic weight_resource_busy_v;
        logic matrix_resource_busy_v;
        logic activation_resource_busy_v;

        logic weight_instruction_en_v;
        logic matrix_instruction_en_v;
        logic activation_instruction_en_v;
        logic instruction_running_v;
        logic synchronize_v;

        instruction_v = instruction;
        instruction_en_v = instruction_en_cs;
        en_flags_v = en_flags_cs;
        weight_busy_v = weight_busy;
        matrix_busy_v = matrix_busy;
        activation_busy_v = activation_busy;
        weight_resource_busy_v = weight_resource_busy;
        matrix_resource_busy_v = matrix_resource_busy;
        activation_resource_busy_v = activation_resource_busy;

        if(instruction_en_v == 1) begin
            if(en_flags_v[3] == 1) begin
                if (weight_resource_busy_v == 1 || matrix_resource_busy_v == 1 || activation_resource_busy_v == 1) begin
                    instruction_running_v = 1;
                    weight_instruction_en_v = 0;
                    matrix_instruction_en_v = 0;
                    activation_instruction_en_v = 0;
                    synchronize_v = 0;
                end
            else begin
                    instruction_running_v = 0;
                    weight_instruction_en_v = 0;
                    matrix_instruction_en_v = 0;
                    activation_instruction_en_v = 0;
                    synchronize_v = 1;
            end
        end

        else begin
            if((weight_busy_v == 1 && en_flags_v[0] == 1)
                || (matrix_busy_v == 1 && (en_flags_v[1] == 1 || en_flags_v[2] == 1))
                || (activation_busy_v == 1 && en_flags_v[2] == 1)) begin
                    instruction_running_v = 1;
                    weight_instruction_en_v = 0;
                    matrix_instruction_en_v = 0;
                    activation_instruction_en_v = 0;
                    synchronize_v = 0;

                end
            else begin
                    instruction_running_v = 0;
                    weight_instruction_en_v = en_flags_v[0];
                    matrix_instruction_en_v = en_flags_v[1];
                    activation_instruction_en_v = en_flags_v[2];
                    synchronize_v = 0;
            end

        end

        end

        else begin
            instruction_running_v = 0;
            weight_instruction_en_v = 0;
            matrix_instruction_en_v = 0;
            activation_instruction_en_v = 0;
            synchronize_v = 0;
        end

        instruction_running = instruction_running_v;
        weight_instruction_en = weight_instruction_en_v;
        matrix_instruction_en = matrix_instruction_en_v;
        activation_instruction_en = activation_instruction_en_v;
        synchronize = synchronize_v;

    end

    assign weight_instruction = to_weight_instruction(instruction_cs);
    assign matrix_instruction = instruction_cs;
    activation_instruction = instruction_cs



always_ff@(posedge clk) begin
    if(rst == 1) begin
        en_flag_cs <= '{default: '0};
        instruction_cs <= '0;
        instruction_en_cs = 0;
    end

    else begin
        if(instruction_running == 0 && enable == 1) begin
            en_flag_cs <= en_flag_ns;
            instruction_cs <= instruction_ns;
            instruction_en_cs <= instruction_en_ns;
        end
    end
end
endmodule