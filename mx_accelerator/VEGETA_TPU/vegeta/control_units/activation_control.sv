module activation_control #(
    parameter MATRIX_WIDTH = 14
) 
(
    input logic clk,
    input logic rst,

    input INSTRUCTION_TYPE instruction,
    input logic instruction_en,

    output ACCUMULATOR_ADDRESS_TYPE acc_to_act_addr,
    output ACTIVATION_BIT_TYPE activation_function,
    output logic signed_not_unsigned,

    output BUFFER_ADDRESS_TYPE act_to_buf_addr,
    output logic buf_write_en,
    
    output logic busy,
    output logic resource_busy
);

ACCUMULATOR_ADDRESS_TYPE acc_to_act_addr_cs = '{default: '0};
ACCUMULATOR_ADDRESS_TYPE acc_to_act_addr_ns;

BUFFER_ADDRESS_TYPE act_to_buf_addr_cs = '{default: '0};
BUFFER_ADDRESS_TYPE act_to_buf_addr_ns;

ACTIVATION_BIT_TYPE activation_function_cs = '0;
ACTIVATION_BIT_TYPE activation_function_ns;

logic signed_not_unsigned_cs = 0;
logic signed_not_unsigned_ns;

logic buf_write_en_cs = 0;
logic buf_write_en_ns;

logic running_cs = 0;
logic running_ns;

logic running_pipe_cs [0 : 3+MATRIX_WIDTH+2+7+3-1] = '{default: '0};
logic running_pipe_ns [0: 3+MATRIX_WIDTH+2+7+3-1];

logic act_load;
logic act_reset;

logic buf_write_en_delay_cs [0 : 2] = '{default: '0};
logic buf_write_en_delay_ns [0 : 2];

logic signed_delay_cs [0 : 2] = '{default: '0};
logic signed_delay_ns [0 : 2];

ACTIVATION_BIT_TYPE activation_pipe0_cs = '{default: '0};
ACTIVATION_BIT_TYPE activation_pipe0_ns;

ACTIVATION_BIT_TYPE activation_pipe1_cs = '{default: '0};
ACTIVATION_BIT_TYPE activation_pipe1_ns;

ACTIVATION_BIT_TYPE activation_pipe2_cs = '{default: '0};
ACTIVATION_BIT_TYPE activation_pipe2_ns;

logic length_reset;
LENGTH_TYPE length_end_val;
logic length_load;
logic length_event;

// ADDRESS_COUNTER signals
logic address_load;

ACCUMULATOR_ADDRESS_TYPE acc_address_delay_cs [0 : 3+MATRIX_WIDTH+2-1] = '{default: '0};
ACCUMULATOR_ADDRESS_TYPE acc_address_delay_ns [0 : 3+MATRIX_WIDTH+2-1];

ACTIVATION_BIT_TYPE activation_delay_cs [0 : 3+MATRIX_WIDTH+2+7-1] = '{default: '0};
ACTIVATION_BIT_TYPE activation_delay_ns [0 : 3+MATRIX_WIDTH+2+7-1];

logic s_not_u_delay_cs [0 : 3+MATRIX_WIDTH+2+7-1] = '{default: '0};
logic s_not_u_delay_ns [0 : 3+MATRIX_WIDTH+2+7-1];

BUFFER_ADDRESS_TYPE act_to_buf_delay_cs [0 : 3+MATRIX_WIDTH+2+7+3-1] = '{default: '0};
BUFFER_ADDRESS_TYPE act_to_buf_delay_ns [0 : 3+MATRIX_WIDTH+2+7+3-1];

logic write_en_delay_cs [0 : 3+MATRIX_WIDTH+2+7+3-1] = '{default: '0};
logic write_en_delay_ns [0 : 3+MATRIX_WIDTH+2+7+3-1];

assign acc_address_delay_ns[1:(3+MATRIX_WIDTH+2-1)] = acc_address_delay_cs[0:(3+MATRIX_WIDTH+2-2)];
assign activation_delay_ns[1:(3+MATRIX_WIDTH+2+7-1)] = activation_delay_cs[0:(3+MATRIX_WIDTH+2+7-2)];
assign s_not_u_delay_ns[1:(3+MATRIX_WIDTH+2+7-1)] = s_not_u_delay_cs[0:(3+MATRIX_WIDTH+2+7-2)];
assign act_to_buf_delay_ns[1:(3+MATRIX_WIDTH+2+7+3-1)] = act_to_buf_delay_cs[0:(3+MATRIX_WIDTH+2+7+3-2)];
assign write_en_delay_ns[1:(3+MATRIX_WIDTH+2+7+3-1)] = write_en_delay_cs[0:(3+MATRIX_WIDTH+2+7+3-2)];

assign acc_to_act_addr = acc_address_delay_cs[3+MATRIX_WIDTH+2-1];
assign activation_function = activation_delay_cs[3+MATRIX_WIDTH+2+7-1];
assign signed_not_unsigned = s_not_u_delay_cs[3+MATRIX_WIDTH+2+7-1];
assign act_to_buf_addr = act_to_buf_delay_cs[3+MATRIX_WIDTH+2+7+3-1];
assign buf_write_en = write_en_delay_cs[3+MATRIX_WIDTH+2+7+3-1];

counter length_counter_i
#(.COUNTER_WIDTH(LENGTH_WIDTH))
(
    .clk(clk),
    .rst(length_reset),
    .enable(enable),
    .end_val(instruction.calc_length),
    .load(length_load),
    .count_event(length_event)
);

load_counter address_counter0_i
#(.COUNTER_WIDTH(ACCUMULATOR_ADDRESS_WIDTH),
  .MATRIX_WIDTH(MATRIX_WIDTH))
(
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .start_val(instruction.acc_address),
    .load(address_load),
    .count_val(acc_to_act_addr_ns)
);

load_counter address_counter1_i
#(.COUNTER_WIDTH(ACCUMULATOR_ADDRESS_WIDTH))
(
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .start_val(instruction.buffer_address),
    .load(address_load),
    .count_val(act_to_buf_addr_ns)
);

assign signed_not_unsigned_ns = instruction.op_code[4];
assign activation_function_ns = instruction.op_code[3:0];

assign activation_delay_ns[0] = (activation_function_cs == 4'b0000) ? 4'b0000 : activation_pipe2_cs;
assign s_not_u_delay_ns[0] = (signed_not_unsigned_cs == 1'b0) ? 1'b0 : signed_delay_cs[2];
assign write_en_delay_ns[0] = (buf_write_en_cs == 1'b0) ? 1'b0 : buf_write_en_delay_cs[2];

assign busy = running_cs;
assign running_pipe_ns[0] = running_cs;
assign running_pipe_ns[1:(3+MATRIX_WIDTH+2+7+3-1)] = running_pipe_cs[0:(3+MATRIX_WIDTH+2+7+2-1)];

assign acc_address_delay_ns[0] = acc_to_act_addr_cs;
assign act_to_buf_delay_ns[0] = act_to_buf_addr_cs;

assign buf_write_en_delay_ns[0] = buf_write_en_cs;
assign signed_delay_ns[0] = signed_not_unsigned_cs;
assign activation_pipe0_ns = activation_function_cs;
assign buf_write_en_delay_ns[1:2] = buf_write_en_delay_cs[0:1];
assign signed_delay_ns[1:2] = signed_delay_cs[0:1];
assign activation_pipe1_ns = activation_pipe0_cs;
assign activation_pipe2_ns = activation_pipe1_cs;

always_comb begin
    logic resource_busy_v;
     resource_busy_v = running_cs;

     for(integer i =0; i<=MATRIX_WIDTH+2+7+3-1; i=i+1) begin
        resource_busy_v = resource_busy_v || running_pipe_cs[i];
     end

     resource_busy = resource_busy_v;
end

always_comb begin
    INSTRUCTION_TYPE instruction_v;
    logic instruction_en_v;
    logic running_cs_v;
    logic length_event_v;

    logic running_ns_v;
    logic address_load_v;
    logic buf_write_en_delay_ns_v;
    logic length_load_v;
    logic length_reset_v;
    logic act_load_v;
    logic act_reset_v;

    instruction_v = instruction;
    instruction_en_v = instruction_en;
    running_cs_v = running_cs;
    length_event_v = length_event;

    if (running_cs_v == 1'b0) begin
        if (instruction_en_v == 1'b1) begin
            running_ns_v = 1'b1;
            address_load_v = 1'b1;
            buf_write_en_ns_v = 1'b1;
            length_load_v = 1'b1;
            length_reset_v = 1'b1;
            act_load_v = 1'b1;
            act_reset_v = 1'b0;
        end else begin
            running_ns_v = 1'b0;
            address_load_v = 1'b0;
            buf_write_en_ns_v = 1'b0;
            length_load_v = 1'b0;
            length_reset_v = 1'b0;
            act_load_v = 1'b0;
            act_reset_v = 1'b0;
        end
    end else begin
        if (length_event_v == 1'b1) begin
            running_ns_v = 1'b0;
            address_load_v = 1'b0;
            buf_write_en_ns_v = 1'b0;
            length_load_v = 1'b0;
            length_reset_v = 1'b0;
            act_load_v = 1'b0;
            act_reset_v = 1'b1;
        end else begin
            running_ns_v = 1'b1;
            address_load_v = 1'b0;
            buf_write_en_ns_v = 1'b1;
            length_load_v = 1'b0;
            length_reset_v = 1'b0;
            act_load_v = 1'b0;
            act_reset_v = 1'b0;
        end
    end

    running_ns = running_ns_v;
    address_load = address_load_v;
    buf_write_en_ns = buf_write_en_ns_v;
    length_load = length_load_v;
    length_reset = length_reset_v;
    act_load = act_load_v;
    act_reset = act_reset_v;
end

always_ff @(posedge clk) begin
    if (rst == 1) begin
        buf_write_en_cs <= 1'b0;
        running_cs <= 1'b0;
        running_pipe_cs <= '{default: '0};
        acc_to_act_addr_cs <= '{default: '0};
        act_to_buf_addr_cs <= '{default: '0};
        buf_write_en_delay_cs <= '{default: '0};
        signed_delay_cs <= '{default: '0};
        activation_pipe0_cs <= '{default: '0};
        activation_pipe1_cs <= '{default: '0};
        activation_pipe2_cs <= '{default: '0};
        
        // delay register
        acc_address_delay_cs <= '{default: '0};
        activation_delay_cs <= '{default: '0};
        s_not_u_delay_cs <= '{default: '0};
        act_to_buf_delay_cs <= '{default: '0};
        write_en_delay_cs <= '{default: '0};
    end else begin
        if (enable == 1) begin
            buf_write_en_cs <= buf_write_en_ns;
            running_cs <= running_ns;
            running_pipe_cs <= running_pipe_ns;
            acc_to_act_addr_cs <= acc_to_act_addr_ns;
            act_to_buf_addr_cs <= act_to_buf_addr_ns;
            buf_write_en_delay_cs <= buf_write_en_delay_ns;
            signed_delay_cs <= signed_delay_ns;
            activation_pipe0_cs <= activation_pipe0_ns;
            activation_pipe1_cs <= activation_pipe1_ns;
            activation_pipe2_cs <= activation_pipe2_ns;
            
            // delay register
            acc_address_delay_cs <= acc_address_delay_ns;
            activation_delay_cs <= activation_delay_ns;
            s_not_u_delay_cs <= s_not_u_delay_ns;
            act_to_buf_delay_cs <= act_to_buf_delay_ns;
            write_en_delay_cs <= write_en_delay_ns;
        end
    end
    
    if (act_reset) begin
        activation_function_cs <= '{default: '0};
        signed_not_unsigned_cs <= '0;
    end else begin
        if (act_load) begin
            activation_function_cs <= activation_function_ns;
            signed_not_unsigned_cs <= signed_not_unsigned_ns;
        end
    end
end

endmodule