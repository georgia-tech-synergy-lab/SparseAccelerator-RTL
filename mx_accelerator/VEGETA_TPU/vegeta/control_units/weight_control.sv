module weight_control 
import vTPU_pkg::*;
#(
    parameter MATRIX_WIDTH = 14
) 
(
    input logic clk,
    input logic rst,
    input logic enable,

    input WEIGHT_INSTRUCTION_TYPE instruction,
    input logic instruction_en,

    output logic weight_read_en,
    output WEIGHT_ADDRESS_TYPE weight_buffer_address,

    output logic load_weight,
    output BYTE_TYPE weight_address,

    output logic weight_signed,

    output logic busy,
    output logic resource_busy
);

logic weight_read_en_cs        = '0;
logic weight_read_en_ns;
    
logic load_weight_cs [0 : 2] = '0;
logic load_weight_ns [0 : 2];
    
logic weight_signed_cs         = '0;
logic weight_signed_ns;
    
logic signed_pipe_cs           [0 : 2] = '0;
logic signed_pipe_ns           [0 : 2];
    
logic signed_load;
logic signed_reset;

localparam WEIGHT_COUNTER_WIDTH = $clog2(MATRIX_WIDTH-1);

logic [WEIGHT_COUNTER_WIDTH-1:0] weight_address_cs  = '0;
logic [WEIGHT_COUNTER_WIDTH-1:0] weight_address_ns;

logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe0_cs  = '0;
logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe0_ns;

logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe1_cs  = '0;
logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe1_ns;

logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe2_cs  = '0;
logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe2_ns;

logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe3_cs  = '0;
logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe3_ns;

logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe4_cs  = '0;
logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe4_ns;

logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe5_cs  = '0;
logic [WEIGHT_COUNTER_WIDTH-1:0] weight_pipe5_ns;

WEIGHT_ADDRESS_TYPE buffer_pipe_cs = '0;
WEIGHT_ADDRESS_TYPE buffer_pipe_ns;
    
logic read_pipe0_cs            = '0;
logic read_pipe0_ns;
    
logic read_pipe1_cs            = '0;
logic read_pipe1_ns;
    
logic read_pipe2_cs            = '0;
logic read_pipe2_ns;
        
logic running_cs = '0;
logic running_ns;
    
logic running_pipe_cs [0:2] = '0;
logic running_pipe_ns [0:2];
    
// LENGTH_COUNTER signals
logic length_reset;
logic length_load;
logic length_event;
    
// ADDRESS_COUNTER signals
logic address_load;

counter length_counter_i
(
    .clk(clk),
    .rst(length_reset),
    .enable(enable),
    .end_val(instruction.calc_length),
    .load(length_load),
    .count_event(length_event)
);

load_counter address_counter_i
(
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .start_val(instruction.weight_address),
    .load(address_load),
    .count_val(buffer_pipe_ns)
);

assign read_pipe0_ns   = weight_read_en_cs;
assign read_pipe1_ns   = read_pipe0_cs;
assign read_pipe2_ns   = read_pipe1_cs;
assign weight_read_en  = (weight_read_en_cs == 1'b0) ? 1'b0 : read_pipe2_cs;

// Weight buffer read takes 3 clock cycles
assign load_weight_ns[0]       = (weight_read_en_cs == 1'b0) ? 1'b0 : read_pipe2_cs;
assign load_weight_ns[1:2]     = load_weight_cs[0:1];
assign load_weight             = load_weight_cs[2];

assign weight_signed_ns    = instruction.op_code[0];
assign signed_pipe_ns[0]   = weight_signed_cs;
assign signed_pipe_ns[1]   = signed_pipe_cs[0];
assign signed_pipe_ns[2]   = signed_pipe_cs[1];
assign weight_signed       = (load_weight_cs[2] == 1'b0) ? 1'b0 : signed_pipe_cs[2];

assign weight_pipe0_ns = weight_address_cs;
assign weight_pipe1_ns = weight_pipe0_cs;
assign weight_pipe2_ns = weight_pipe1_cs;
assign weight_pipe3_ns = weight_pipe2_cs;
assign weight_pipe4_ns = weight_pipe3_cs;
assign weight_pipe5_ns = weight_pipe4_cs;

// Possible error
assign weight_address[WEIGHT_COUNTER_WIDTH-1:0] = weight_pipe5_cs;
assign weight_address[BYTE_WIDTH-1:WEIGHT_COUNTER_WIDTH] = 0;

assign weight_buffer_address = buffer_pipe_cs;

assign busy = running_cs;
assign running_pipe_ns[0] = running_cs;
assign running_pipe_ns[1:2] = running_pipe_cs[0:1];

always_comb begin
    logic resource_busy_v;
    for(integer i =0; i<=2; i=i + 1) begin
        resource_busy_v = resource_busy_v || running_pipe_cs[i];
    end

    resource_busy = resource_busy_v;
end

always_comb begin
    if(weight_address_cs == MATRIX_WIDTH - 1) begin
        weight_address_ns = 0;
    end

    else begin
        weight_address_ns = weight_address_cs + 1;
    end
end

always_comb begin
    logic instruction_en_v;
    logic running_cs_v;
    logic length_event_v;

    logic running_ns_v;
    logic address_load_v;
    BYTE_TYPE weight_address_ns_v;
    logic weight_read_en_ns_v;
    logic length_load_v;
    logic length_reset_v;
    logic signed_load_v;
    logic signed_reset_v;

    instruction_en_v = instruction_en;
    running_cs_v = running_cs;
    length_event_v = length_event;

    // synthesis translate_off
    if(instruction_en_v == 1 && running_cs_v == 1) begin
        $display("New instruction should not be fed while processing\n");
    end
    // synthesis tranlate_on

    if(running_cs_v == 0) begin
        if(instruction_en_v == 1) begin
            running_ns_v        = 1'b1;
            address_load_v      = 1'b1;
            weight_read_en_ns_v = 1'b1;
            length_load_v       = 1'b1;
            length_reset_v      = 1'b1;
            signed_load_v       = 1'b1;
            signed_reset_v      = 1'b0;
        end

        else begin
            running_ns_v        = 1'b0;
            address_load_v      = 1'b0;
            weight_read_en_ns_v = 1'b0;
            length_load_v       = 1'b0;
            length_reset_v      = 1'b0;
            signed_load_v       = 1'b0;
            signed_reset_v      = 1'b0; 
        end
    end

    else begin
        if (length_event_v == 1) begin
            running_ns_v        = 1'b0;
            address_load_v      = 1'b0;
            weight_read_en_ns_v = 1'b0;
            length_load_v       = 1'b0;
            length_reset_v      = 1'b0;
            signed_load_v       = 1'b0;
            signed_reset_v      = 1'b1;
        end

        else begin
            running_ns_v        = 1'b1;
            address_load_v      = 1'b0;
            weight_read_en_ns_v = 1'b1;
            length_load_v       = 1'b0;
            length_reset_v      = 1'b0;
            signed_load_v       = 1'b0;
            signed_reset_v      = 1'b0;
        end
    end

    running_ns = running_ns_v;
    address_load = address_load_v;
    weight_read_en_ns = weight_read_en_ns_v;
    length_load = length_load_v;
    length_reset = length_reset_v;
    signed_load = signed_load_v;
    signed_reset = signed_reset_v;
end

always_ff @(posedge clk) begin
    if(rst == 1) begin
        weight_read_en_cs <= 0;
        load_weight_cs <= '0;
        running_cs <= 0;
        running_pipe_cs <= '0;
        weight_pipe0_cs <= '0;
        weight_pipe1_cs <= '0;
        weight_pipe2_cs <= '0;
        weight_pipe3_cs <= '0;
        weight_pipe4_cs <= '0;
        weight_pipe5_cs <= '0;
        buffer_pipe_cs <= '0;
        signed_pipe_cs <= '0;
    end

    else begin
        if(enable == 1) begin
            weight_read_en_cs   <= weight_read_en_ns;
            load_weight_cs      <= load_weight_ns;
            running_cs          <= running_ns;
            running_pipe_cs     <= running_pipe_ns;
            weight_pipe0_cs     <= weight_pipe0_ns;
            weight_pipe1_cs     <= weight_pipe1_ns;
            weight_pipe2_cs     <= weight_pipe2_ns;
            weight_pipe3_cs     <= weight_pipe3_ns;
            weight_pipe4_cs     <= weight_pipe4_ns;
            weight_pipe5_cs     <= weight_pipe5_ns;
            buffer_pipe_cs      <= buffer_pipe_ns;
            signed_pipe_cs      <= signed_pipe_ns;
        end
    end

    if(length_reset == 1) begin
        weight_address_cs <= '0;
    end

    else begin
        if(enable == 1) begin
            weight_address_cs <= weight_address_ns;
        end
    end

    if(signed_reset == 1) begin
        weight_signed_cs <= 0;
        read_pipe0_cs <= 0;
        read_pipe1_cs <= 0;
        read_pipe2_cs <= 0;
    end

    else begin
        if(signed_load == 1) begin
            weight_signed_cs <= weight_signed_ns;
        end

        if(enable == 1) begin 
            read_pipe0_cs <= read_pipe0_ns;
            read_pipe1_cs <= read_pipe1_ns;
            read_pipe2_cs <= read_pipe2_ns;
        end
    end
end
    
endmodule