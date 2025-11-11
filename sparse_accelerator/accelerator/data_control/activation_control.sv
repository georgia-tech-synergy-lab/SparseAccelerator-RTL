/*
======================= START OF LICENSE NOTICE =======================
    Copyright (C) 2025 Akshat Ramachandran (GT), Souvik Kundu (Intel), Tushar Krishna (GT). All Rights Reserved

    NO WARRANTY. THE PRODUCT IS PROVIDED BY DEVELOPER "AS IS" AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DEVELOPER BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
    GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
    IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
    OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE PRODUCT, EVEN
    IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
======================== END OF LICENSE NOTICE ========================
    Primary Author: Akshat Ramachandran (GT)

*/
`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module activation_control 
#(
    parameter K, 
    parameter N,
    parameter ALPHA,
    parameter BETA,
    parameter MUL_DATAWIDTH,
    parameter BLOCK_SIZE,
    localparam K_SCALED = K/BETA,
    localparam DATA_WIDTH = MUL_DATAWIDTH*BLOCK_SIZE*BETA,
    localparam LANE_COUNT = K_SCALED,
    localparam DATA_DEPTH = N
)
(
    input logic clk,
    input logic rst_n,
    input logic [`vegeta_clog2(BLOCK_SIZE):0] m_by_n,
    input logic begin_load,
    output logic activation_L1_loaded,

    // weight BRAM interface
	output logic [31:0] activation_address,
    input logic [31:0] activation_data,
    output logic activation_enable,

    input logic load_array_from_L1,
    output logic activation_transferring_in,
    output logic [DATA_WIDTH-1:0] activation_in [0 : LANE_COUNT-1],
    output logic activations_loaded
);

    // L1 buffer

    logic L1_enable, L1_enable_next;
    logic L1_write, L1_write_next;
    logic [DATA_WIDTH - 1 : 0] L1_data_in      [0 : LANE_COUNT-1];
    logic [DATA_WIDTH - 1 : 0] L1_data_in_next [0 : LANE_COUNT-1];
    logic [DATA_WIDTH - 1 : 0] act_1 [0 : LANE_COUNT-1];
    logic [DATA_WIDTH - 1 : 0] act_1_next [0 : LANE_COUNT-1];
    logic [DATA_WIDTH - 1 : 0] act_2 [0 : LANE_COUNT-1];
    logic [DATA_WIDTH - 1 : 0] act_2_next [0 : LANE_COUNT-1];
    logic [`vegeta_clog2(DATA_DEPTH) : 0] L1_write_index, L1_write_index_next;
    logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] L1_read_index      [0 : LANE_COUNT-1];
    logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] L1_read_index_next [0 : LANE_COUNT-1];
    logic L1_read_enable [0 : LANE_COUNT - 1];
    logic L1_read_enable_next [0 : LANE_COUNT - 1];


    L1_buffer_independent_read #(
        .DATA_WIDTH(DATA_WIDTH),
        .LANE_COUNT(LANE_COUNT),
        .DATA_DEPTH(DATA_DEPTH)
    ) weight_bram (
        .clk(clk),
        .enable(L1_enable),
        .write(L1_write),
        .data_in(L1_data_in),
        .write_index(L1_write_index[0 +: (`vegeta_clog2(DATA_DEPTH))]),
        .read_index(L1_read_index),
        .read_enable(L1_read_enable),
        .data_out(activation_in)
    );

    localparam L2_ACTIVATION_ADDRESS = 32'h6000_0000;

    logic activation_transferring_in_next;
    logic L1_loaded_next;
    logic activations_loaded_next;

    // input logic [MUL_DATAWIDTH*BLOCK_SIZE*BETA-1:0] act_in [0 : K_SCALED-1],

    logic [`vegeta_clog2(K_SCALED) - 1 :0] x_index, x_index_next;
    logic [`vegeta_clog2(BLOCK_SIZE*BETA) -1 : 0] m_index, m_index_next;

    logic [31:0] activation_address_next;

    typedef enum logic [3:0] {
        RESET,
        IDLE,
        START_LOAD,
        ACTIVATION_LOAD,
        ACTIVATION_STORE,
        ACTIVATION_READY,
        COMPUTE_1,
        COMPUTE_2,
        DONE,
        STATEX = 'x
    } state_type;

    state_type state, next_state;

    always_ff @( posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            activation_enable <= '0;
            activation_transferring_in <= '0;
            state <= RESET;
            activation_address <= '0;
            x_index <= '0;
            m_index <= '0;

            L1_enable <= '0;
            L1_write <= '0;
            L1_data_in <= '{default: '0};
            act_1 <= '{default: '0};
            act_2 <= '{default: '0};
            L1_write_index <= '0;
            L1_read_index <= '{default: '0};
            L1_read_enable <= '{default: '0};

            activation_L1_loaded <= '0;
            activations_loaded <= '0;
        end else begin
            activation_enable <= '1;
            activation_transferring_in <= activation_transferring_in_next;
            state <= next_state;
            activation_address <= activation_address_next;
            x_index <= x_index_next;
            m_index <= m_index_next;

            L1_enable <= L1_enable_next;
            L1_write <= L1_write_next;
            L1_data_in <= L1_data_in_next;
            act_1 <= act_1_next;
            act_2 <= act_2_next;
            L1_write_index <= L1_write_index_next;
            L1_read_index <= L1_read_index_next;
            L1_read_enable <= L1_read_enable_next;

            activation_L1_loaded <= L1_loaded_next;
            activations_loaded <= activations_loaded_next;
        end
    end

    always_comb begin 
        next_state = STATEX;
        activation_transferring_in_next = '0;
        L1_loaded_next = '0;
        activations_loaded_next = '0;
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
            begin
                next_state = ACTIVATION_LOAD;
            end
            ACTIVATION_LOAD:
            begin
                if (m_index == (`vegeta_clog2(BLOCK_SIZE*BETA))'(2*m_by_n-1) && x_index == (`vegeta_clog2(K_SCALED))'(K_SCALED - 1)) begin
                    next_state = ACTIVATION_STORE;
                end else
                    next_state = ACTIVATION_LOAD;
            end
            ACTIVATION_STORE:
            begin
                if (activation_address == (L2_ACTIVATION_ADDRESS + N * MUL_DATAWIDTH /8)) begin
                    L1_loaded_next = '1;
                    next_state = ACTIVATION_READY;
                end else begin
                    next_state = ACTIVATION_LOAD;
                end
            end
            ACTIVATION_READY:
            begin
                if (load_array_from_L1)
                    next_state = COMPUTE_1;
                else
                    next_state = ACTIVATION_READY;
            end
            COMPUTE_1:
            begin
                activation_transferring_in_next = '1;
                // second to last cycle before finished the first lane, switch
                if (L1_read_index[0] == (`vegeta_clog2(DATA_DEPTH))'(DATA_DEPTH-2))
                    next_state = COMPUTE_2;
                else
                    next_state = COMPUTE_1;
            end
            COMPUTE_2:
            begin
                activation_transferring_in_next = '1;
                // if we are only reading from the last lane we are done
                if (~L1_read_enable[LANE_COUNT -2] && L1_read_enable[LANE_COUNT-1])
                    next_state = DONE;
                else
                    next_state = COMPUTE_2;
            end
            DONE:
                begin
                    activations_loaded_next = '1;
                    next_state = IDLE;
                end
        endcase
    end

    always_comb begin
        // assume BETA = 2, BLOCK_SIZE=4
        act_1_next = act_1;
        act_2_next = act_2;
        if (state == ACTIVATION_LOAD) begin
            case (m_by_n)
                // Dense 4:4
                (`vegeta_clog2(BLOCK_SIZE)+1)'(1):
                    begin
                        act_1_next[x_index][m_index*BLOCK_SIZE*MUL_DATAWIDTH +: BLOCK_SIZE*MUL_DATAWIDTH ] = '0;
                        act_1_next[x_index][m_index*BLOCK_SIZE*MUL_DATAWIDTH +: MUL_DATAWIDTH ]   = activation_data[0 +: MUL_DATAWIDTH];
                        act_2_next[x_index][m_index*BLOCK_SIZE*MUL_DATAWIDTH +: BLOCK_SIZE*MUL_DATAWIDTH ] = '0;
                        act_2_next[x_index][m_index*BLOCK_SIZE*MUL_DATAWIDTH +: MUL_DATAWIDTH ]   = activation_data[MUL_DATAWIDTH +: MUL_DATAWIDTH];
                    end
                // Sparse 2:4
                (`vegeta_clog2(BLOCK_SIZE)+1)'(2):
                    begin
                        act_1_next[x_index][(m_index  )*MUL_DATAWIDTH +: MUL_DATAWIDTH ] = activation_data[0 +: MUL_DATAWIDTH];
                        act_1_next[x_index][(m_index+BLOCK_SIZE)*MUL_DATAWIDTH +: MUL_DATAWIDTH ] = activation_data[0 +: MUL_DATAWIDTH];
                        act_2_next[x_index][(m_index  )*MUL_DATAWIDTH +: MUL_DATAWIDTH ] = activation_data[MUL_DATAWIDTH +: MUL_DATAWIDTH];
                        act_2_next[x_index][(m_index+BLOCK_SIZE)*MUL_DATAWIDTH +: MUL_DATAWIDTH ] = activation_data[MUL_DATAWIDTH +: MUL_DATAWIDTH];
                    end
                // Sparse 1:4
                (`vegeta_clog2(BLOCK_SIZE)+1)'(4):
                    begin
                        act_1_next[x_index][(m_index  )*MUL_DATAWIDTH +:  MUL_DATAWIDTH ] = activation_data[0             +: MUL_DATAWIDTH];
                        act_2_next[x_index][(m_index  )*MUL_DATAWIDTH +:  MUL_DATAWIDTH ] = activation_data[MUL_DATAWIDTH +: MUL_DATAWIDTH];
                    end
            endcase
        end
    end

    integer i;

    always_comb begin
        activation_address_next = L2_ACTIVATION_ADDRESS;
        x_index_next = '0;
        m_index_next = '0;

        L1_enable_next = '0;
        L1_write_next = '0;
        L1_write_index_next = '0;
        L1_read_index_next = '{default: '0};
        L1_read_enable_next = '{default: '0};
        L1_data_in_next = '{default: 'x};
        case (state)
            START_LOAD:
            begin
                activation_address_next = activation_address + MUL_DATAWIDTH / 8 * N;
                
                x_index_next = x_index;
                m_index_next = m_index;
                L1_enable_next = L1_enable;
                L1_write_next = L1_write;
                L1_write_index_next = L1_write_index;
                L1_read_index_next = L1_read_index;
                L1_read_enable_next = L1_read_enable;
                L1_data_in_next = L1_data_in;
            end
            ACTIVATION_LOAD:
            begin
                // if we are at the end of the column jump back
                if (m_index == (`vegeta_clog2(BLOCK_SIZE*BETA))'(2*m_by_n-1) && x_index == (`vegeta_clog2(K_SCALED))'(K_SCALED - 1))
                    activation_address_next = activation_address;
                else if (activation_address >= L2_ACTIVATION_ADDRESS + MUL_DATAWIDTH / 8 * N * (m_by_n * K-1))
                    activation_address_next = activation_address + 4 - MUL_DATAWIDTH / 8 * N * (m_by_n * K-1);
                else
                    activation_address_next = activation_address + MUL_DATAWIDTH / 8 * N;
                

                /*
                if 4:4 need to load twice
                if 2:4 need to load four times
                if 1:4 need to load eight times

                */
                if (m_index == (`vegeta_clog2(BLOCK_SIZE*BETA))'(2*m_by_n-1)) begin
                    m_index_next = '0;
                    if (x_index == (`vegeta_clog2(K_SCALED))'(K_SCALED - 1)) begin
                        x_index_next = '0;

                        L1_enable_next = '1;
                        L1_write_next = '1;
                        L1_write_index_next = L1_write_index;
                        L1_data_in_next = act_1_next;
                    end else begin
                        x_index_next = (`vegeta_clog2(K_SCALED))'(x_index + 1);
                        L1_write_index_next = L1_write_index;
                    end
                end else begin
                    x_index_next = x_index;
                    m_index_next = (`vegeta_clog2(BLOCK_SIZE*BETA))'(m_index + 1);
                    L1_write_index_next = L1_write_index;
                end

                if (L1_write)
                    L1_write_index_next = (`vegeta_clog2(DATA_DEPTH+1))'(L1_write_index + 1); 
            end
            ACTIVATION_STORE:
            begin
                activation_address_next = activation_address + MUL_DATAWIDTH / 8 * N;
                m_index_next = m_index;
                x_index_next = x_index;
                L1_enable_next = '1;
                L1_write_next = '1;
                L1_write_index_next = (`vegeta_clog2(DATA_DEPTH+1))'(L1_write_index + 1); 
                L1_data_in_next = act_2;
            end
            ACTIVATION_READY:
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
                // finish shifting out the rest of the activations
                // shift register
                for (i = 1; i < LANE_COUNT; i++) begin
                    L1_read_enable_next[i] = L1_read_enable[i-1];
                    L1_read_index_next[i] = L1_read_index[i-1];
                end
            end
            
        endcase
    end
endmodule;