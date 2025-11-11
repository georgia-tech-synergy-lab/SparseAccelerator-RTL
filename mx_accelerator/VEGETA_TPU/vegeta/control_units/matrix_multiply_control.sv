module matrix_multiply_control 
import vTPU_pkg::*;
#(
    parameter MATRIX_WIDTH = 14
) 
(
    input logic clk,
    input logic enable,

    input INSTRUCTION_TYPE instruction,
    input logic instruction_en,

    output BUFFER_ADDRESS_TYPE buf_to_sds_addr,
    output logic buf_read_en,

    output logic mmu_sds_en,
    output logic mmu_signed,
    output logic activate_weight,

    output ACCUMULATOR_ADDRESS_TYPE acc_address,
    output logic accumulate,
    output logic acc_enable,

    output logic busy,
    output logic resource_busy 
);

logic buf_read_en_cs = 1'b0;
logic buf_read_en_ns;

logic mmu_sds_en_cs = 1'b0;
logic mmu_sds_en_ns;

logic mmu_sds_en_delay_cs [0 : 2] = '{default: '0};
logic mmu_sds_en_delay_ns [0 : 2];

logic mmu_signed_cs = '0;
logic mmu_signed_ns;

logic signed_pipe_cs [0 : 2] = '{default: '0};
logic signed_pipe_ns  [0 : 2];

localparam WEIGHT_COUNTER_WIDTH = $clog2(MATRIX_WIDTH-1);
logic [WEIGHT_COUNTER_WIDTH-1 : 0] weight_counter_cs = '0;
logic [WEIGHT_COUNTER_WIDTH-1 : 0] weight_counter_ns = '0;

logic weight_pipe_cs [0 : 2] = '{default: '0};
logic weight_pipe_ns;

logic activate_weight_delay_cs [0 :2] = '{default: '0};
logic activate_weight_delay_ns [0 : 2];

logic acc_enable_cs = 0;
logic acc_enable_ns;

logic running_cs = '0;
logic running_ns;

logic running_pipe_cs [0 : MATRIX_WIDTH+2+3-1] = '{default: '0};
logic running_pipe_ns [0 : MATRIX_WIDTH+2+3-1];

logic accumulate_cs = '0;
logic accumulate_ns;
    
BUFFER_ADDRESS_TYPE buf_addr_pipe_cs = '{default: '0};
BUFFER_ADDRESS_TYPE buf_addr_pipe_ns;

ACCUMULATOR_ADDRESS_TYPE acc_addr_pipe_cs = '{default: '0};
ACCUMULATOR_ADDRESS_TYPE acc_addr_pipe_ns;

logic buf_read_pipe_cs [0 : 2] = '{default: '0};
logic buf_read_pipe_ns [0 : 2];

logic mmu_sds_en_pipe_cs [0 : 2] = '{default: '0};
logic mmu_sds_en_pipe_ns [0 : 2];

logic acc_en_pipe_cs [0 : 2] = '{default: '0};
logic acc_en_pipe_ns [0 : 2];

logic accumulate_pipe_cs [0 : 2] = '{default: '0};
logic accumulate_pipe_ns [0 : 2];

logic acc_load;
logic acc_reset;

ACCUMULATOR_ADDRESS_TYPE acc_addr_delay_cs [0 : MATRIX_WIDTH-1 + 2 + 3] = '{default: '0};
ACCUMULATOR_ADDRESS_TYPE acc_addr_delay_ns [0 : MATRIX_WIDTH-1 + 2 + 3];

logic  accumulate_delay_cs [0 : MATRIX_WIDTH-1 + 2 + 3] = '{default: '0};
logic  accumulate_delay_ns [0 : MATRIX_WIDTH-1 + 2 + 3];

logic acc_en_delay_cs [0 : MATRIX_WIDTH-1 + 2 + 3] = '{default: '0};
logic acc_en_delay_ns [0 : MATRIX_WIDTH-1 + 2 + 3];

// LENGTH_COUNTER signals
logic length_reset;
LENGTH_TYPE length_end_val;
logic length_load;
logic length_event;

// ADDRESS_COUNTER signals
logic address_load;

// WEIGHT_COUNTER reset
logic weight_reset;

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
    .count_val(acc_addr_pipe_ns)
);

load_counter address_counter1_i
#(.COUNTER_WIDTH(ACCUMULATOR_ADDRESS_WIDTH))
(
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .start_val(instruction.buffer_address),
    .load(address_load),
    .count_val(buf_addr_pipe_ns)
);

assign accumulate_ns = instruction.op_code[1];
    
assign buf_to_sds_addr = buf_addr_pipe_cs;
assign acc_addr_delay_ns[0] = acc_addr_pipe_cs;
    
assign acc_addr = acc_addr_delay_cs[MATRIX_WIDTH-1 + 2 + 3];
  
assign buf_read_pipe_ns[1:2] = buf_read_pipe_cs[0:1];
assign mmu_sds_en_pipe_ns[1:2] = mmu_sds_en_pipe_cs[0:1];
assign acc_en_pipe_ns[1:2] = acc_en_pipe_cs[0:1];
assign accumulate_pipe_ns[1:2] = accumulate_pipe_cs[0:1];
assign signed_pipe_ns[1:2] = signed_pipe_cs[0:1];
assign weight_pipe_ns[1:2] = weight_pipe_cs[0:1];
    
assign buf_read_pipe_ns[0] = buf_read_en_cs;
assign mmu_sds_en_pipe_ns[0] = mmu_sds_en_cs ;
assign acc_en_pipe_ns[0] = acc_enable_cs;
assign accumulate_pipe_ns[0] = accumulate_cs;
assign signed_pipe_ns[0] = mmu_signed_cs;
assign weight_pipe_ns[0] = (weight_counter_cs == '0) ? 1 : 0;
    
assign mmu_signed_ns = instruction.op_code[0];
    
assign buf_read_en = (buf_read_en_cs == 1'b0) ? 1'b0 : buf_read_pipe_cs[2];
assign mmu_sds_delay_ns[0] = (mmu_sds_en_cs == 1'b0) ? 1'b0 : mmu_sds_en_pipe_cs[2];
assign acc_en_delay_ns[0] = (acc_enable_cs == 1'b0) ? 1'b0 : acc_en_pipe_cs[2];
assign accumulate_delay_ns[0] = (accumulate_cs == 1'b0) ? 1'b0 : accumulate_pipe_cs[2];
    
assign mmu_signed = (mmu_sds_delay_cs[2] == 1'b0) ? signed_pipe_cs[2] : 1'b0;
    
assign activate_weight_delay_ns[0] = weight_pipe_cs[2];
assign activate_weight_delay_ns[1:2] = activate_weight_delay_cs[0:1];
assign activate_weight = (mmu_sds_delay_cs[2] == 1'b0) ? 0 : activate_weight_delay_cs[2];
    
assign acc_enable = acc_en_delay_cs[MATRIX_WIDTH-1 + 2 + 3];
assign accumulate = accumulate_delay_cs[MATRIX_WIDTH-1 + 2 + 3];
assign mmu_sds_en = mmu_sds_delay_cs[2];
    
assign busy = running_cs;
assign running_pipe_ns[0] = running_cs;
assign running_pipe_ns[1:MATRIX_WIDTH+2+3-1] = running_pipe_cs[0:MATRIX_WIDTH+2+2-1];

assign acc_addr_delay_ns[1:MATRIX_WIDTH-1 + 2 + 3] = acc_addr_delay_cs[0:MATRIX_WIDTH-1 + 2 +2];
assign accumulate_delay_ns[1:MATRIX_WIDTH-1 + 2 + 3] = accumulate_delay_cs[0:MATRIX_WIDTH-1 + 2 + 2];
assign acc_en_delay_ns[1:MATRIX_WIDTH-1 + 2 + 3] = acc_en_delay_cs[0:MATRIX_WIDTH-1 + 2 + 2];
assign mmu_sds_delay_ns[1:2] = mmu_sds_delay_cs[0:1];

always_comb begin
    logic resource_busy_v;
     resource_busy_v = running_cs;

     for(integer i =0; i<=MATRIX_WIDTH+2+3-1; i=i+1) begin
        resource_busy_v = resource_busy_v || running_pipe_cs[i];
     end

     resource_busy = resource_busy_v;
end

always_comb begin
    if(weight_counter_cs == MATRIX_WIDTH-1) begin
        weight_counter_ns = '0;
    end

    else begin
        weight_counter_ns = weight_counter_cs + 1;
    end
end

always_comb begin
    INSTRUCTION_TYPE instruction_v;
    logic instruction_en_v;
    logic running_cs_v;
    logic length_event_v;

    logic running_ns_v;
    logic address_load_v;
    logic buf_read_en_ns_v;
    logic mmu_sds_en_ns_v;
    logic acc_enable_ns_v;
    logic length_load_v;
    logic length_reset_v;
    logic acc_load_v;
    logic acc_reset_v;
    logic weight_reset_v;

    instruction_v  = instruction;
    instruction_en_v = instruction_en;
    running_cs_v = running_cs;
    length_event_v = length_event;

    if(running_cs_v == 0) begin
        if(instruction_en_v == 1) begin
            running_ns_v = 1'b1;
            address_load_v = 1'b1;
            buf_read_en_ns_v = 1'b1;
            mmu_sds_en_ns_v = 1'b1;
            acc_enable_ns_v = 1'b1;
            length_load_v = 1'b1;
            length_reset_v = 1'b1;
            acc_load_v = 1'b1;
            acc_reset_v = 1'b0;
            weight_reset_v = 1'b1;
        end

        else begin
            running_ns_v = 1'b0;
            address_load_v = 1'b0;
            buf_read_en_ns_v = 1'b0;
            mmu_sds_en_ns_v = 1'b0;
            acc_enable_ns_v = 1'b0;
            length_load_v = 1'b0;
            length_reset_v = 1'b0;
            acc_load_v = 1'b0;
            acc_reset_v = 1'b0;
            weight_reset_v = 1'b0;
        end
    end

    else begin
        if(length_event_v == 1) begin
            running_ns_v = 1'b0;
            address_load_v = 1'b0;
            buf_read_en_ns_v = 1'b0;
            mmu_sds_en_ns_v = 1'b0;
            acc_enable_ns_v = 1'b0;
            length_load_v = 1'b0;
            length_reset_v = 1'b0;
            acc_load_v = 1'b0;
            acc_reset_v = 1'b1;
            weight_reset_v = 1'b0;
        end

        else begin
            running_ns_v = 1'b1;
            address_load_v = 1'b0;
            buf_read_en_ns_v = 1'b1;
            mmu_sds_en_ns_v = 1'b1;
            acc_enable_ns_v = 1'b1;
            length_load_v = 1'b0;
            length_reset_v = 1'b0;
            acc_load_v = 1'b0;
            acc_reset_v = 1'b0;
            weight_reset_v = 1'b0;
        end
    end

    running_ns = running_ns_v;
    address_load = address_load_v;
    buf_read_en_ns = buf_read_en_ns_v;
    mmu_sds_en_ns = mmu_sds_en_ns_v;
    acc_enable_ns = acc_enable_ns_v;
    length_load = length_load_v;
    length_reset = length_reset_v;
    acc_load = acc_load_v;
    acc_reset = acc_reset_v;
    weight_reset = weight_reset_v;
end

always_ff @(posedge clk) begin
    if (rst == 1) begin
        buf_read_en_cs <= 1'b0;
        mmu_sds_en_cs <= 1'b0;
        acc_enable_cs <= 1'b0;
        running_cs <= 1'b0;
        running_pipe_cs <= '0;
        buf_addr_pipe_cs <= '0;
        acc_addr_pipe_cs <= '0;
        acc_addr_delay_cs = '0;
        accumulate_delay_cs = '0;
        acc_en_delay_cs = '0;
        mmu_sds_delay_cs = '0;
        signed_pipe_cs = '0;
        weight_pipe_cs = '0;
        activate_weight_delay_cs = '0;
    end 
    else begin
        if (enable == 1) begin
            buf_read_en_cs <= buf_read_en_ns;
            mmu_sds_en_cs <= mmu_sds_en_ns;
            acc_enable_cs <= acc_enable_ns;
            running_cs <= running_ns;
            running_pipe_cs <= running_pipe_ns;
            buf_addr_pipe_cs <= buf_addr_pipe_ns;
            acc_addr_pipe_cs <= acc_addr_pipe_ns;
            acc_addr_delay_cs = acc_addr_delay_ns;
            accumulate_delay_cs = accumulate_delay_ns;
            acc_en_delay_cs = acc_en_delay_ns;
            mmu_sds_delay_cs = mmu_sds_delay_ns;
            signed_pipe_cs = signed_pipe_ns;
            weight_pipe_cs = weight_pipe_ns;
            activate_weight_delay_cs = activate_weight_delay_ns;
        end
    end

    if (acc_reset == 1) begin
        accumulate_cs <= 1'b0;
        buf_read_pipe_cs <= '0;
        mmu_sds_en_pipe_cs <= '0;
        acc_en_pipe_cs <= '0;
        accumulate_pipe_cs <= '0;
        mmu_signed_cs <= 1'b0;
    end 
    else begin
        if (acc_load) begin
            accumulate_cs <= accumulate_ns;
            mmu_signed_cs <= mmu_signed_ns;
        end

        if (enable) begin
            buf_read_pipe_cs <= buf_read_pipe_ns;
            mmu_sds_en_pipe_cs <= mmu_sds_en_pipe_ns;
            acc_en_pipe_cs <= acc_en_pipe_ns;
            accumulate_pipe_cs <= accumulate_pipe_ns;
        end
    end

    if (weight_reset) begin
        weight_counter_cs <= '0;
    end else begin
        if (enable) begin
            weight_counter_cs <= weight_counter_ns;
        end
    end
end
    
endmodule