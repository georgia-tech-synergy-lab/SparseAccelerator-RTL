//////////////////////////////////////////////////////////
// Copyright Ethan Weinstock, Garrett Botkin, Jingsong Guo
// Top level VEGETA controller handling orchestration 
// between activation, accumulation, weight, metadata, 
// compute, and output control
//////////////////////////////////////////////////////////
`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module vegeta_control
#(
    parameter K_SCALED,
    parameter M_SCALED,
    parameter N
)
(
    input logic clk,
    input logic rst_n,
    // global control signal
    input logic start_multiplication,
    output logic begin_load,

    // status signals
    input logic weight_array_loaded,
    input logic activation_L1_loaded,
    input logic accumulation_L1_loaded,
    input logic output_L2_loaded,

    // compute control
    output logic start_compute,
    output logic mode,
    output logic output_valid,

    // statistics
    output logic compute_done
);

    logic begin_load_next;
    logic start_compute_next;
    logic output_valid_next;
    logic mode_next;
    logic compute_done_next;

    logic [`vegeta_clog2(N+M_SCALED) :0] output_counter, output_counter_next;
    logic [`vegeta_clog2(K_SCALED + 2) : 0 ] flow_counter, flow_counter_next;

    logic [2:0] ready_counter, ready_counter_next;


    typedef enum logic [3:0] {
        RESET,
        IDLE,
        WEIGHT_LOAD,
        SYNC_1,
        COMPUTE_FLOW,
        COMPUTE_O,
        WRITE_OUT,
        STATEX = 'x
    } state_type;

    state_type state, state_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= RESET;
            begin_load <= '0;
            start_compute <= '0;
            output_valid <= '0;
            compute_done <= '0;
            mode <= '0;
            output_counter <= '0;
            flow_counter <= '0;
            ready_counter <= '0;
        end else begin 
            state <= state_next;
            begin_load <= begin_load_next;
            start_compute <= start_compute_next;
            output_valid <= output_valid_next;
            compute_done <= compute_done_next;
            mode <= mode_next;
            output_counter <= output_counter_next;
            flow_counter <= flow_counter_next;
            ready_counter <= ready_counter_next;
        end
    end

    always_comb begin
        state_next = STATEX;
        begin_load_next = '0;
        start_compute_next = '0;
        output_valid_next = '0;
        compute_done_next = '0;
        mode_next = '0;
        output_counter_next = output_counter;
        flow_counter_next = flow_counter;
        ready_counter_next = '0;

        case(state)
            RESET: begin
                state_next = IDLE;
            end
            IDLE: begin
                compute_done_next = compute_done;
                if (start_multiplication == 1) begin
                    state_next = WEIGHT_LOAD;
                    begin_load_next = '1;
                end else
                    state_next = IDLE;
            end
            WEIGHT_LOAD: begin
                flow_counter_next = '0;
                output_counter_next = '0;

                ready_counter_next = ready_counter;
                if (weight_array_loaded)
                    ready_counter_next[0] = '1;
                if (activation_L1_loaded)
                    ready_counter_next[1] = '1;
                if (accumulation_L1_loaded)
                    ready_counter_next[2] = '1;
                if (&ready_counter) begin
                    state_next = SYNC_1;
                    start_compute_next = '1;
                end else begin
                    state_next = WEIGHT_LOAD;
                end
            end
            SYNC_1:
                state_next = COMPUTE_FLOW;
            COMPUTE_FLOW: begin
                mode_next = '1;

                // just inputs
                flow_counter_next = flow_counter + (`vegeta_clog2(K_SCALED+2)+1)'(1);
                
                if ((flow_counter < (`vegeta_clog2(K_SCALED+2)+1)'(K_SCALED))) begin
                    state_next = COMPUTE_FLOW;
                end else begin
                    output_valid_next = '1;
                    state_next = COMPUTE_O;
                end
            end
            COMPUTE_O: begin

                // just outputs
                output_counter_next = output_counter + `vegeta_clog2(N+M_SCALED)'(1);

                if (output_counter < (`vegeta_clog2(N+M_SCALED)+1)'(N+M_SCALED)) begin
                    state_next = COMPUTE_O;
                    mode_next = '1;
                end else begin
                    state_next = WRITE_OUT;
                end
            end
            WRITE_OUT: begin
                if (output_L2_loaded) begin
                    state_next = IDLE;
                    compute_done_next = '1;
                end else begin
                    state_next = WRITE_OUT;
                end
            end
        endcase
    end
endmodule