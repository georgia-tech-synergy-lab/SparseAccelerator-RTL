module systolic_data_setup 
import vTPU_pkg::*;
#(
    parameter MATRIX_WIDTH = 14
) 
(
    input logic clk,
    input logic reset,
    input logic enable,
    input BYTE_TYPE data_input [0 : MATRIX_WIDTH - 1],
    output BYTE_TYPE systolic_output [0 : MATRIX_WIDTH]
);

BYTE_TYPE buffer_reg_cs[1:MATRIX_WIDTH-1][1:MATRIX_WIDTH-1] = '{'{default: '0}};
BYTE_TYPE buffer_reg_ns[1:MATRIX_WIDTH-1][1:MATRIX_WIDTH-1];

BYTE_TYPE data_input_v [1 : MATRIX_WIDTH - 1];
BYTE_TYPE buffer_reg_ns_v [1 : MATRIX_WIDTH - 1][1 : MATRIX_WIDTH - 1];

BYTE_TYPE systolic_output_v [ 1 : MATRIX_WIDTH - 1];

// SHIFT_REG
always_comb begin
    data_input_v = data_input[1 : MATRIX_WIDTH - 1];

    for(integer i = 1; i <= MATRIX_WIDTH - 1; i=i+1) begin
        for(integer j = 1; j<= MATRIX_WIDTH - 1; j=j + 1) begin
            if(i == 1) begin
                buffer_reg_ns_v[i][j] = data_input_v[j];
            end
            else begin
                buffer_reg_ns_v[i][j] = buffer_reg_cs[i-1][j];
            end
        end
    end
    buffer_reg_ns = buffer_reg_ns_v;
end

// Diagonalization process
always_comb begin
    for(integer i = 0; i <= MATRIX_WIDTH - 1; i=i + 1) begin
        systolic_output_v[i] = buffer_reg_cs[i][i];
    end

    systolic_output [0] = data_input[0];
    systolic_output [1 : MATRIX_WIDTH - 1] = systolic_output_v;
end

// SEQ_LOGIC
always_ff @(posedge clk) begin
    if(rst == 1) begin
        buffer_reg_cs <= '{'{default: '0}};
    end

    else begin
        if(enable == 1) begin
            buffer_reg_cs <= buffer_reg_ns;
        end
    end
end
 
endmodule