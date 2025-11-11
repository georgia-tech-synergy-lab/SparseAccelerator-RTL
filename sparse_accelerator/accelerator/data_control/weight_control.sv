//////////////////////////////////////////////////////////
// Copyright Ethan Weinstock, Garrett Botkin, Jingsong Guo
// Controller for reading in weight & metadata matrix data
// and formatting it for input into the VEGETA engine
//////////////////////////////////////////////////////////
`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module weight_control 
#(
    parameter K,
    parameter M,
    parameter ALPHA,
    parameter BETA,
    parameter MUL_DATAWIDTH,
    parameter META_DATA_SIZE,
    parameter BLOCK_SIZE,
    localparam K_SCALED = K/BETA,
    localparam M_SCALED = M/ALPHA
)
(
    input logic clk,
    input logic rst_n,
    input logic begin_load,
    input logic [`vegeta_clog2(BLOCK_SIZE):0] m_by_n,
    output logic L1_loaded,

    // weight BRAM interface
	output logic [31:0] weight_address,
    input logic [31:0] weight_data,
    output logic weight_enable,

	output logic [31:0] metadata_address,
    input logic  [31:0] metadata_data_in,
    output logic metadata_enable,

    input logic load_array_from_L1,
    output logic weight_transferring_in,
    output logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in [0 : M_SCALED-1],
    output logic weight_array_loaded
);


    // L1 buffer

    logic L1_enable, L1_enable_next;
    logic L1_write, L1_write_next;
    logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] L1_data_in [0 : M_SCALED-1];
    logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] L1_data_in_next [0 : M_SCALED-1];
    logic [`vegeta_clog2(K_SCALED) : 0] L1_index, L1_index_next;
    // logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] L1_data_out [0 : M_SCALED-1];


    L1_buffer #(
        .DATA_WIDTH(ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE)),
        .LANE_COUNT(M_SCALED),
        .DATA_DEPTH(K_SCALED)
    ) weight_bram (
        .clk(clk),
        .enable(L1_enable),
        .write(L1_write),
        .data_in(L1_data_in),
        .index(L1_index[0 +: (`vegeta_clog2(K_SCALED))]),
        .data_out(weight_in)
    );

    // state

    typedef enum logic [2:0] {
        RESET,
        IDLE,
        START_LOAD,
        WEIGHT_LOAD,
        WEIGHT_READY,
        ARRAY_LOAD,
        DONE,
        STATEX = 'x
    } state_type;

    state_type state, next_state;


    // L1 load
    localparam L2_WEIGHT_ADDR = 32'h4000_0000;
    localparam L2_METADATA_ADDRESS = 32'h5000_0000;

    logic [31:0] weight_address_next, metadata_address_next;

    logic [`vegeta_clog2(M_SCALED) - 1 :0] y_index, y_index_next;
    // logic [`vegeta_clog2(ALPHA*BETA) - 1: 0] alpha_beta_index, alpha_beta_index_next;
    logic [`vegeta_clog2(32/META_DATA_SIZE) - 1: 0] metadata_index, metadata_index_next, metadata_index_prev;
    // logic [`vegeta_clog2(32/MUL_DATAWIDTH) -1 : 0] weight_index, weight_index_next;
    // logic [`vegeta_clog2(BETA) -1 : 0 ] beta_index, beta_index_next;
    logic [`vegeta_clog2(ALPHA) -1 : 0 ] alpha_index, alpha_index_next;

    logic weight_transferring_in_next;
    logic L1_loaded_next;
    logic weight_array_loaded_next;

    logic [31:0] metadata_data;

    // dense metadata = 0
    assign metadata_data = (m_by_n == (`vegeta_clog2(BLOCK_SIZE)+1)'(1)) ? 32'b0 : metadata_data_in;

    always_ff @( posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            L1_enable <= '0;
            L1_write <= '0;
            L1_data_in <= '{default: '0}; // Unpacked Array Has to Be Reset Specially :)
            L1_index <= '0;

            weight_enable <= '0;
            metadata_enable <= '0;
            weight_transferring_in <= '0;
            state <= RESET;

            weight_address <= '0;
            metadata_address <= '0;
            y_index <= '0;
            metadata_index <= '0;
            metadata_index_prev <= '0;
            alpha_index <= '0;

            L1_loaded <= '0;
            weight_array_loaded <= '0;
        end else begin
            L1_enable <= L1_enable_next;
            L1_write <= L1_write_next;
            L1_data_in <= L1_data_in_next;
            L1_index <= L1_index_next;

            weight_enable <= '1;
            // if dense disable metadata
            metadata_enable <= (m_by_n == (`vegeta_clog2(BLOCK_SIZE)+1)'(1)) ? 1'b0 : 1'b1;
            weight_transferring_in <= weight_transferring_in_next;
            state <= next_state;

            weight_address <= weight_address_next;
            metadata_address <= metadata_address_next;
            y_index <= y_index_next;
            metadata_index <= metadata_index_next;
            metadata_index_prev <= metadata_index;
            alpha_index <= alpha_index_next;

            L1_loaded <= L1_loaded_next;
            weight_array_loaded <= weight_array_loaded_next;
        end
    end
    
    always_comb begin 
        next_state = STATEX;
        weight_transferring_in_next = '0;
        L1_loaded_next = '0;
        weight_array_loaded_next = '0;
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
                next_state = WEIGHT_LOAD;
            WEIGHT_LOAD:
                begin
                    if (alpha_index == '0 && y_index == '0 && (weight_address == (L2_WEIGHT_ADDR + K * M * MUL_DATAWIDTH / 8 - 4 - K * MUL_DATAWIDTH / 8))) begin
                        next_state = WEIGHT_READY;
                        L1_loaded_next = '1;
                    end else
                        next_state = WEIGHT_LOAD;
                end
            WEIGHT_READY:
                begin
                    if (load_array_from_L1) begin
                        next_state = ARRAY_LOAD;
                    end else begin
                        next_state = WEIGHT_READY;
                    end
                end
            ARRAY_LOAD:
                begin
                    weight_transferring_in_next = '1;
                    if (L1_index == 0) begin
                        next_state = DONE;
                    end else begin
                        next_state = ARRAY_LOAD;
                    end
                end
            DONE:
                begin
                    weight_array_loaded_next = '1;
                    next_state = IDLE;
                end
        endcase
    end

    always_comb begin
        L1_data_in_next = L1_data_in;
        if (state == WEIGHT_LOAD) begin
            L1_data_in_next[y_index][alpha_index*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) +: 2*(MUL_DATAWIDTH+META_DATA_SIZE)] = 
                {metadata_data[META_DATA_SIZE * (BETA*metadata_index_prev+1) +: META_DATA_SIZE],
                 weight_data  [MUL_DATAWIDTH                                 +: MUL_DATAWIDTH],
                 metadata_data[META_DATA_SIZE * (BETA*metadata_index_prev)   +: META_DATA_SIZE],
                 weight_data  [0                                             +: MUL_DATAWIDTH]};
        end
    end

generate;
    if (K < 16) begin
        always_comb begin
            weight_address_next = L2_WEIGHT_ADDR + K * M * MUL_DATAWIDTH / 8 - 4;

            metadata_address_next = L2_METADATA_ADDRESS + K * M * META_DATA_SIZE / 8 - 4;
            metadata_index_next = $floor(32/(2*META_DATA_SIZE)) - 1;

            alpha_index_next =  (`vegeta_clog2(ALPHA))'(ALPHA - 1);
            y_index_next = (`vegeta_clog2(M_SCALED))'(M_SCALED - 1);

            L1_enable_next = '0;
            L1_write_next = '0;
            L1_index_next = (`vegeta_clog2(K_SCALED)+1)'(K_SCALED);
            case (state)
                START_LOAD:
                begin
                    weight_address_next = weight_address - K * MUL_DATAWIDTH / 8;
                    metadata_index_next = metadata_index - (`vegeta_clog2(32/META_DATA_SIZE))'(K/2) ;
                end
                WEIGHT_LOAD:
                    begin
                        if (weight_address < L2_WEIGHT_ADDR + K * MUL_DATAWIDTH / 8 ) begin
                            weight_address_next = weight_address -4 + K * (M - 1) * MUL_DATAWIDTH / 8;
                        end else begin
                            // get two words per address
                            weight_address_next = weight_address - K * MUL_DATAWIDTH / 8;
                        end

                        if (metadata_index < K/2) begin
                            if (metadata_address == L2_METADATA_ADDRESS) begin
                                metadata_index_next = metadata_index + (`vegeta_clog2(32/META_DATA_SIZE))'(7-K/2) ;
                                metadata_address_next = L2_METADATA_ADDRESS + K * M * META_DATA_SIZE / 8 - 4;
                            end else begin
                                metadata_index_next = metadata_index + (`vegeta_clog2(32/META_DATA_SIZE))'(8-K/2) ;
                                metadata_address_next = metadata_address - 4;
                            end
                        end else begin
                            metadata_address_next = metadata_address;
                            metadata_index_next = metadata_index - (`vegeta_clog2(32/META_DATA_SIZE))'(K/2) ;
                        end

                        if (alpha_index == 0) begin
                            alpha_index_next = (`vegeta_clog2(ALPHA))'(ALPHA - 1);
                            if (y_index == 0) begin
                                y_index_next = (`vegeta_clog2(M_SCALED))'(M_SCALED - 1);

                                L1_index_next = L1_index - (`vegeta_clog2(K_SCALED)+1)'(1);
                                L1_enable_next = '1;
                                L1_write_next = '1;
                            end else begin
                                y_index_next = y_index - (`vegeta_clog2(M_SCALED))'(1);

                                L1_index_next = L1_index;
                            end
                        end else begin
                            alpha_index_next = alpha_index - (`vegeta_clog2(ALPHA))'(1);
                            y_index_next = y_index;

                            L1_index_next = L1_index;
                        end
                    end
                WEIGHT_READY:
                    begin
                        L1_enable_next = '1;
                        L1_index_next = (`vegeta_clog2(K_SCALED)+1)'(K_SCALED-1);
                    end
                ARRAY_LOAD:
                    begin
                        L1_enable_next = '1;
                        L1_index_next = L1_index - (`vegeta_clog2(K_SCALED)+1)'(1);
                    end
            endcase
        end
    end else begin
        always_comb begin
            weight_address_next = L2_WEIGHT_ADDR + K * M * MUL_DATAWIDTH / 8 - 4;

            metadata_address_next = L2_METADATA_ADDRESS + K * M * META_DATA_SIZE / 8 - 4;
            metadata_index_next = $floor(32/(2*META_DATA_SIZE)) - 1;

            alpha_index_next =  (`vegeta_clog2(ALPHA))'(ALPHA - 1);
            y_index_next = (`vegeta_clog2(M_SCALED))'(M_SCALED - 1);

            L1_enable_next = '0;
            L1_write_next = '0;
            L1_index_next = (`vegeta_clog2(K_SCALED)+1)'(K_SCALED);
            case (state)
                START_LOAD:
                    begin
                        weight_address_next = weight_address - K * MUL_DATAWIDTH / 8;
                        metadata_address_next = metadata_address - K*META_DATA_SIZE/8;
                    end
                WEIGHT_LOAD:
                    begin
                        if (weight_address < L2_WEIGHT_ADDR + K * MUL_DATAWIDTH / 8 ) begin
                            weight_address_next = weight_address -4 + K * (M - 1) * MUL_DATAWIDTH / 8;
                        end else begin
                            // get two words per address
                            weight_address_next = weight_address - K * MUL_DATAWIDTH / 8;
                        end

                        if (metadata_address < (L2_METADATA_ADDRESS + K * META_DATA_SIZE/8)) begin
                            if (metadata_index == 0) begin
                                metadata_address_next = metadata_address + K * (M-1) * META_DATA_SIZE / 8 - 4;
                                metadata_index_next = $floor(32/(2*META_DATA_SIZE)) - 1;
                            end else begin
                                metadata_address_next = metadata_address + K * (M-1) * META_DATA_SIZE / 8;
                                metadata_index_next = metadata_index - (`vegeta_clog2(32/META_DATA_SIZE))'(1) ;
                            end
                        end else begin
                            metadata_address_next = metadata_address - K*META_DATA_SIZE/8;
                            metadata_index_next = metadata_index;
                        end

                        if (alpha_index == 0) begin
                            alpha_index_next = (`vegeta_clog2(ALPHA))'(ALPHA - 1);
                            if (y_index == 0) begin
                                y_index_next = (`vegeta_clog2(M_SCALED))'(M_SCALED - 1);

                                L1_index_next = L1_index - (`vegeta_clog2(K_SCALED)+1)'(1);
                                L1_enable_next = '1;
                                L1_write_next = '1;
                            end else begin
                                y_index_next = y_index - (`vegeta_clog2(M_SCALED))'(1);

                                L1_index_next = L1_index;
                            end
                        end else begin
                            alpha_index_next = alpha_index - (`vegeta_clog2(ALPHA))'(1);
                            y_index_next = y_index;

                            L1_index_next = L1_index;
                        end
                    end
                WEIGHT_READY:
                    begin
                        L1_enable_next = '1;
                        L1_index_next = (`vegeta_clog2(K_SCALED)+1)'(K_SCALED-1);
                    end
                ARRAY_LOAD:
                    begin
                        L1_enable_next = '1;
                        L1_index_next = L1_index - (`vegeta_clog2(K_SCALED)+1)'(1);
                    end
            endcase
        end
    end
endgenerate;

endmodule;