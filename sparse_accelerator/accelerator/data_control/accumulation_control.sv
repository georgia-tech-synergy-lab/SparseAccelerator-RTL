`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module accumulation_control 
#(
    parameter K,
    parameter M,
    parameter ALPHA,
    parameter BETA,
    parameter ADD_DATAWIDTH,
    parameter N,
    localparam M_SCALED = M/ALPHA,
    localparam DATA_WIDTH = ALPHA*BETA*ADD_DATAWIDTH,
    localparam LANE_COUNT = M_SCALED,
    localparam DATA_DEPTH = N
)
(
    input logic clk,
    input logic rst_n,
    input logic begin_load,
    output logic accumulation_L1_loaded,

    // accumulation BRAM interface
	output logic [31:0] accumulation_address,
    input logic [31:0] accumulation_data,
    output logic accumulation_enable,

    input logic load_array_from_L1,
    output logic accumulation_transferring_in,
    output logic [DATA_WIDTH-1:0] accumulation_in [0 : LANE_COUNT-1],
    output logic accumulations_loaded
);

    // L1 buffer

    logic L1_enable, L1_enable_next;
    logic L1_write, L1_write_next;
    logic [DATA_WIDTH - 1 : 0] L1_data_in      [0 : LANE_COUNT-1];
    logic [DATA_WIDTH - 1 : 0] L1_data_in_next [0 : LANE_COUNT-1];
    logic [`vegeta_clog2(DATA_DEPTH) : 0] L1_write_index, L1_write_index_next;
    logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] L1_read_index      [0 : LANE_COUNT-1];
    logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] L1_read_index_next [0 : LANE_COUNT-1];
    logic L1_read_enable [0 : LANE_COUNT - 1];
    logic L1_read_enable_next [0 : LANE_COUNT - 1];


    L1_buffer_independent_read #(
        .DATA_WIDTH(DATA_WIDTH),
        .LANE_COUNT(LANE_COUNT),
        .DATA_DEPTH(DATA_DEPTH)
    ) accumulation_bram (
        .clk(clk),
        .enable(L1_enable),
        .write(L1_write),
        .data_in(L1_data_in),
        .write_index(L1_write_index[0 +: (`vegeta_clog2(DATA_DEPTH))]),
        .read_index(L1_read_index),
        .read_enable(L1_read_enable),
        .data_out(accumulation_in)
    );

    localparam L2_ACCUMULATION_ADDRESS = 32'h7000_0000;

    logic accumulation_transferring_in_next;
    logic L1_loaded_next;
    logic accumulations_loaded_next;

    logic [`vegeta_clog2(ALPHA) - 1 :0] alpha_index, alpha_index_next;
    logic [`vegeta_clog2(M_SCALED) -1 : 0] y_index, y_index_next;

    logic [31:0] accumulation_address_next;

    typedef enum logic [2:0] {
        RESET,
        IDLE,
        START_LOAD,
        ACCUMULATION_LOAD,
        ACCUMULATION_READY,
        COMPUTE_1,
        COMPUTE_2,
        DONE,
        STATEX = 'x
    } state_type;

    state_type state, next_state;

    always_ff @( posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            accumulation_enable <= '0;
            accumulation_transferring_in <= '0;
            state <= RESET;
            accumulation_address <= '0;
            alpha_index <= '0;
            y_index <= '0;

            L1_enable <= '0;
            L1_write <= '0;
            L1_data_in <= '{default: '0};
            L1_write_index <= '0;
            L1_read_index <= '{default: '0};
            L1_read_enable <= '{default: '0};

            accumulation_L1_loaded <= '0;
            accumulations_loaded <= '0;
        end else begin
            accumulation_enable <= '1;
            accumulation_transferring_in <= accumulation_transferring_in_next;
            state <= next_state;
            accumulation_address <= accumulation_address_next;
            alpha_index <= alpha_index_next;
            y_index <= y_index_next;

            L1_enable <= L1_enable_next;
            L1_write <= L1_write_next;
            L1_data_in <= L1_data_in_next;
            L1_write_index <= L1_write_index_next;
            L1_read_index <= L1_read_index_next;
            L1_read_enable <= L1_read_enable_next;

            accumulation_L1_loaded <= L1_loaded_next;
            accumulations_loaded <= accumulations_loaded_next;
        end
    end


generate;
    if (LANE_COUNT > 1) begin
        always_comb begin 
            next_state = STATEX;
            accumulation_transferring_in_next = '0;
            L1_loaded_next = '0;
            accumulations_loaded_next = '0;
            case (state)
                RESET:
                begin
                    next_state = IDLE;
                end
                IDLE:
                begin
                    if (begin_load == 1)
                        next_state = START_LOAD;
                    else
                        next_state = IDLE;
                end
                START_LOAD:
                    next_state = ACCUMULATION_LOAD;
                ACCUMULATION_LOAD:
                begin
                    if ((y_index == (`vegeta_clog2(M_SCALED))'(M_SCALED - 1)) && (accumulation_address == (L2_ACCUMULATION_ADDRESS + ADD_DATAWIDTH / 8 * N))) begin
                        L1_loaded_next = '1;
                        next_state = ACCUMULATION_READY;
                    end else begin
                        next_state = ACCUMULATION_LOAD;
                    end
                end
                ACCUMULATION_READY:
                begin
                    if (load_array_from_L1)
                        next_state = COMPUTE_1;
                    else
                        next_state = ACCUMULATION_READY;
                end
                COMPUTE_1:
                begin
                    accumulation_transferring_in_next = '1;
                    // second to last cycle before finished the first lane, switch
                    if (L1_read_index[0] == (`vegeta_clog2(DATA_DEPTH))'(DATA_DEPTH-2))
                        next_state = COMPUTE_2;
                    else
                        next_state = COMPUTE_1;
                end
                COMPUTE_2:
                begin
                    accumulation_transferring_in_next = '1;
                    // if we are only reading from the last lane we are done
                    if (~L1_read_enable[LANE_COUNT -2] && L1_read_enable[LANE_COUNT-1])
                        next_state = DONE;
                    else
                        next_state = COMPUTE_2;
                end
                DONE:
                    begin
                        accumulations_loaded_next = '1;
                        next_state = IDLE;
                    end
            endcase
        end
    end else begin 
        always_comb begin 
            next_state = STATEX;
            accumulation_transferring_in_next = '0;
            L1_loaded_next = '0;
            accumulations_loaded_next = '0;
            case (state)
                RESET:
                begin
                    next_state = IDLE;
                end
                IDLE:
                begin
                    if (begin_load == 1)
                        next_state = START_LOAD;
                    else
                        next_state = IDLE;
                end
                START_LOAD:
                    next_state = ACCUMULATION_LOAD;
                ACCUMULATION_LOAD:
                begin
                    if ((y_index == (`vegeta_clog2(M_SCALED))'(M_SCALED - 1)) && (alpha_index == (`vegeta_clog2(ALPHA))'(ALPHA-1)) && (accumulation_address == (L2_ACCUMULATION_ADDRESS + ADD_DATAWIDTH / 8 * N))) begin
                        L1_loaded_next = '1;
                        next_state = ACCUMULATION_READY;
                    end else begin
                        next_state = ACCUMULATION_LOAD;
                    end
                end
                ACCUMULATION_READY:
                begin
                    if (load_array_from_L1)
                        next_state = COMPUTE_1;
                    else
                        next_state = ACCUMULATION_READY;
                end
                COMPUTE_1:
                begin
                    accumulation_transferring_in_next = '1;
                    // second to last cycle before finished the only lane, switch
                    if (L1_read_index[0] == (`vegeta_clog2(DATA_DEPTH))'(DATA_DEPTH-2))
                        next_state = COMPUTE_2;
                    else
                        next_state = COMPUTE_1;
                end
                COMPUTE_2:
                begin
                    accumulation_transferring_in_next = '1;
                    // last cycle for the only lane
                    next_state = DONE;
                end
                DONE:
                    begin
                        accumulations_loaded_next = '1;
                        next_state = IDLE;
                    end
            endcase
        end
    end
endgenerate


    always_comb begin
        L1_data_in_next = L1_data_in;
        if (state == ACCUMULATION_LOAD) begin
            L1_data_in_next[y_index][alpha_index* BETA*ADD_DATAWIDTH +: BETA * ADD_DATAWIDTH] = '0;
            L1_data_in_next[y_index][alpha_index* BETA*ADD_DATAWIDTH +: ADD_DATAWIDTH] = accumulation_data;
        end
    end

    integer i;

    always_comb begin
        accumulation_address_next = L2_ACCUMULATION_ADDRESS;
        y_index_next = '0;
        alpha_index_next = '0;

        L1_enable_next = '0;
        L1_write_next = '0;
        L1_write_index_next = '0;
        L1_read_index_next = '{default: '0};
        L1_read_enable_next = '{default: '0};
        case (state)
            START_LOAD:
                accumulation_address_next = accumulation_address + ADD_DATAWIDTH / 8 * N;
            ACCUMULATION_LOAD:
            begin
                // if we are at the end of the column jump back
                if (accumulation_address >= L2_ACCUMULATION_ADDRESS + ADD_DATAWIDTH / 8 * N * (M-1))
                    accumulation_address_next = accumulation_address + 4 - ADD_DATAWIDTH / 8 * N * (M-1);
                else
                    accumulation_address_next = accumulation_address + ADD_DATAWIDTH / 8 * N;
                

                /*
                if 4:4 need to load twice
                if 2:4 need to load four times
                if 1:4 need to load eight times

                */
                if (alpha_index == (`vegeta_clog2(ALPHA))'(ALPHA-1)) begin
                    alpha_index_next = '0;
                    if (y_index == (`vegeta_clog2(M_SCALED))'(M_SCALED - 1)) begin
                        y_index_next = '0;

                        L1_enable_next = '1;
                        L1_write_next = '1;
                    end else begin
                        y_index_next = (`vegeta_clog2(M_SCALED))'(y_index + 1);
                    end
                end else begin
                    y_index_next = y_index;
                    alpha_index_next = (`vegeta_clog2(ALPHA))'(alpha_index + 1);
                end

                if (L1_write)
                    L1_write_index_next = (`vegeta_clog2(DATA_DEPTH+1))'(L1_write_index + 1); 
                else
                    L1_write_index_next = L1_write_index;
            end
            ACCUMULATION_READY:
            begin
                L1_enable_next = '1;
                L1_read_enable_next[0] = '1;
            end
            COMPUTE_1:
            begin
                L1_enable_next = '1;
                L1_read_enable_next[0] = '1;
                L1_read_index_next[0] = (`vegeta_clog2(DATA_DEPTH))'(L1_read_index[0] + 1);
                // shift register
                for (i = 1; i < LANE_COUNT; i++) begin
                    L1_read_enable_next[i] = L1_read_enable[i-1];
                    L1_read_index_next[i] = L1_read_index[i-1];
                end
            end
            COMPUTE_2:
            begin
                L1_enable_next = '1;
                // set to 0
                L1_read_enable_next[0] = '0;
                L1_read_index_next[0] = '0;
                // finish shifting out the rest of the accumulations
                // shift register
                for (i = 1; i < LANE_COUNT; i++) begin
                    L1_read_enable_next[i] = L1_read_enable[i-1];
                    L1_read_index_next[i] = L1_read_index[i-1];
                end
            end
            
        endcase
    end

endmodule