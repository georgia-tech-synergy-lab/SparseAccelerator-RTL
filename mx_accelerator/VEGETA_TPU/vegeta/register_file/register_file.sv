module register_file
import vTPU_pkg::*;
#(
    parameter MATRIX_WIDTH = 14,
    parameter REGISTER_DEPTH =  512
)
(
  input logic clk,
  input logic rst,
  input logic enable,
  input ACCUMULATOR_ADDRESS_TYPE write_address,
  input logic write_enable,
  input logic accumulate,
  input ACCUMULATOR_ADDRESS_TYPE read_address,
  input WORD_TYPE write_port [0 : MATRIX_WIDTH - 1],
  output WORD_TYPE read_port [0 : MATRIX_WIDTH - 1]
);

(* ram_style = "block" *)
ACCUMULATOR_TYPE accumulators [0 : REGISTER_DEPTH - 1];
(* ram_style = "block" *)
ACCUMULATOR_TYPE accumulators_copy [0 : REGISTER_DEPTH - 1];

// Memory port signals
wire logic acc_write_en;
wire ACCUMULATOR_ADDRESS_TYPE acc_write_address;
wire ACCUMULATOR_ADDRESS_TYPE acc_read_address;
wire ACCUMULATOR_ADDRESS_TYPE acc_accu_address;
WORD_TYPE acc_write_port [0 : MATRIX_WIDTH - 1];
WORD_TYPE acc_read_port [0 : MATRIX_WIDTH - 1];
WORD_TYPE acc_accumulate_port [0 : MATRIX_WIDTH - 1];

// DSP signals
WORD_TYPE dsp_add_port0_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE dsp_add_port0_ns [0 : MATRIX_WIDTH - 1];
WORD_TYPE dsp_add_port1_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE dsp_add_port1_ns [0 : MATRIX_WIDTH - 1];
WORD_TYPE dsp_result_port_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE dsp_result_port_ns [0 : MATRIX_WIDTH - 1];
WORD_TYPE dsp_pipe0_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE dsp_pipe0_ns [0 : MATRIX_WIDTH - 1];
WORD_TYPE dsp_pipe1_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE dsp_pipe1_ns [0 : MATRIX_WIDTH - 1];

// Pipeline registers
WORD_TYPE accumulate_port_pipe0_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE accumulate_port_pipe0_ns [0 : MATRIX_WIDTH - 1];
WORD_TYPE accumulate_port_pipe1_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE accumulate_port_pipe1_ns [0 : MATRIX_WIDTH - 1];

logic accumulate_pipe_cs [0 : 2] = '0;
logic accumulate_pipe_ns [0 : 2];

WORD_TYPE write_port_pipe0_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE write_port_pipe0_ns [0 : MATRIX_WIDTH - 1];
WORD_TYPE write_port_pipe1_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE write_port_pipe1_ns [0 : MATRIX_WIDTH - 1];
WORD_TYPE write_port_pipe2_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
WORD_TYPE write_port_pipe2_ns [0 : MATRIX_WIDTH - 1];

logic write_enable_pipe_cs [0 : 5] = '0;
logic write_enable_pipe_ns [0 : 5];

ACCUMULATOR_ADDRESS_TYPE write_address_pipe0_cs = '0;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe0_ns;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe1_cs = '0;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe1_ns;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe2_cs = '0;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe2_ns;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe3_cs = '0;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe3_ns;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe4_cs = '0;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe4_ns;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe5_cs = '0;
ACCUMULATOR_ADDRESS_TYPE write_address_pipe5_ns;

ACCUMULATOR_ADDRESS_TYPE read_address_pipe0_cs = '0;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe0_ns;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe1_cs = '0;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe1_ns;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe2_cs = '0;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe2_ns;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe3_cs = '0;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe3_ns;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe4_cs = '0;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe4_ns;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe5_cs = '0;
ACCUMULATOR_ADDRESS_TYPE read_address_pipe5_ns;


assign write_port_pipe0_ns = write_port;
assign write_port_pipe1_ns = write_port_pipe0_cs;
assign write_port_pipe2_ns = write_port_pipe1_cs;

assign dsp_add_port0_ns = write_port_pipe2_cs;
assign acc_write_port = dsp_result_port_cs;

assign accumulate_port_pipe0_ns = acc_accumulate_port;
assign accumulate_port_pipe1_ns = accumulate_port_pipe0_cs;

assign accumulate_pipe_ns[1 : 2] = accumulate_pipe_cs[0 : 1];
assign accumulate_pipe_ns[0] = accumulate;

assign acc_accu_address = write_address;
assign write_address_pipe0_ns = write_address;
assign write_address_pipe1_ns = write_address_pipe0_cs;
assign write_address_pipe2_ns = write_address_pipe1_cs;
assign write_address_pipe3_ns = write_address_pipe2_cs;
assign write_address_pipe4_ns = write_address_pipe3_cs;
assign write_address_pipe5_ns = write_address_pipe4_cs;
assign acc_write_address = write_address_pipe5_cs;

assign write_enable_pipe_ns[1 : 5] = write_enable_pipe_cs[0:4];
assign write_enable_pipe_ns[0] = write_enable;
assign acc_write_en = write_enable_pipe_cs[5];

assign read_address_pipe0_ns = read_address;
assign read_address_pipe1_ns = read_address_pipe0_cs;
assign read_address_pipe2_ns = read_address_pipe1_cs;
assign read_address_pipe3_ns = read_address_pipe2_cs;
assign read_address_pipe4_ns = read_address_pipe3_cs;
assign read_address_pipe5_ns = read_address_pipe4_cs;
assign acc_read_address = read_address_pipe5_cs;

assign read_port = acc_read_port;

assign dsp_pipe0_ns = dsp_add_port0_cs;
assign dsp_pipe1_ns = dsp_add_port1_cs;

always_comb begin
    for(integer i = 0; i< MATRIX_WIDTH; i=i + 1) begin
        dsp_result_port_ns[i] = dsp_pipe0_cs[i] + dsip_pipe1_cs[i];
    end
end

always_comb begin
    if(accumulate_pipe_cs[2] == 1) begin
        dsp_add_port1_ns = accumulate_port_pipe1_cs;
    end
    else begin
        dsp_add_port1_ns = '{default: '0};
    end
end

always_ff @(posedge clk) begin
    if(enable == 1) begin
        // synthesis translate_off
        if(acc_write_address < register_depth) begin
        // synthesis translate_on
            if(acc_write_en == 1) begin
                accumulators[acc_write_address] <= WordArrayToBits#(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: word_array_to_bits(acc_write_port);
                accumulators_copy[acc_write_address] <= WordArrayToBits#(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: word_array_to_bits(acc_write_port);
            end
        // synthesis translate_off
        end
        // synthesis translate_on
    end  
end

always_ff @(posedge clk) begin
    if(enable == 1) begin
        // synthesis translate_off
        if(acc_read_address < register_depth) begin
        // synthesis translate_on
        for(integer i = 0; i < MATRIX_WIDTH; i= i + 1) begin
            acc_read_port[i] <= accumulators[acc_read_address][i*4*BYTE_WIDTH +: 4*BYTE_WIDTH];
            acc_accumulate_port[i] <= accumulators_copy[acc_read_address][i*4*BYTE_WIDTH +: 4*BYTE_WIDTH];
        end
        // synthesis translate_off
        end
        // synthesis translate_on
    end  
end

always_ff @(posedge clk) begin
    if(rst == 1) begin
        dsp_add_port0_cs <= '{default: '0};
        dsp_add_port1_cs <= '{default: '0};
        dsp_result_port_cs <= '{default: '0};
        dsp_pipe0_cs <= '{default: '0};
        dsp_pipe1_cs <= '{default: '0};
        accumulate_port_pipe0_cs <= '{default: '0};
        accumulate_port_pipe1_cs <= '{default: '0};
        accumulate_pipe_cs <= '{default: '0};
        write_port_pipe0_cs <= '{default: '0};
        write_port_pipe1_cs <= '{default: '0};
        write_port_pipe2_cs <= '{default: '0};
        write_enable_pipe_cs <= '{default: '0};
        write_address_pipe0_cs <= '{default: '0};
        write_address_pipe1_cs <= '{default: '0};
        write_address_pipe2_cs <= '{default: '0};
        write_address_pipe3_cs <= '{default: '0};
        write_address_pipe4_cs <= '{default: '0};
        write_address_pipe5_cs <= '{default: '0};
        read_address_pipe0_cs <= '{default: '0};
        read_address_pipe1_cs <= '{default: '0};
        read_address_pipe2_cs <= '{default: '0};
        read_address_pipe3_cs <= '{default: '0};
        read_address_pipe4_cs <= '{default: '0};
        read_address_pipe5_cs <= '{default: '0};
    end

    else begin
        if(enable == 1) begin
            dsp_add_port0_cs <= dsp_add_port0_ns;
            dsp_add_port1_cs <= dsp_add_port1_ns;
            dsp_result_port_cs <= dsp_result_port_ns;
            dsp_pipe0_cs <= dsp_pipe0_ns;
            dsp_pipe1_cs <= dsp_pipe1_ns;

            accumulate_port_pipe0_cs <= accumulate_port_pipe0_ns;
            accumulate_port_pipe1_cs <= accumulate_port_pipe1_ns;

            accumulate_pipe_cs <= accumulate_pipe_ns;

            write_port_pipe0_cs <= write_port_pipe0_ns;
            write_port_pipe1_cs <= write_port_pipe1_ns;
            write_port_pipe2_cs <= write_port_pipe2_ns;

            write_enable_pipe_cs <= write_enable_pipe_ns;

            write_address_pipe0_cs <= write_address_pipe0_ns;
            write_address_pipe1_cs <= write_address_pipe1_ns;
            write_address_pipe2_cs <= write_address_pipe2_ns;
            write_address_pipe3_cs <= write_address_pipe3_ns;
            write_address_pipe4_cs <= write_address_pipe4_ns;
            write_address_pipe5_cs <= write_address_pipe5_ns;

            read_address_pipe0_cs <= read_address_pipe0_ns;
            read_address_pipe1_cs <= read_address_pipe1_ns;
            read_address_pipe2_cs <= read_address_pipe2_ns;
            read_address_pipe3_cs <= read_address_pipe3_ns;
            read_address_pipe4_cs <= read_address_pipe4_ns;
            read_address_pipe5_cs <= read_address_pipe5_ns; 
        end
    end  
end
endmodule