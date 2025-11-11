//////////////////////////////////////////////////////////
// Copyright Ethan Weinstock, Garrett Botkin, Jingsong Guo
// Controller for storing outputs from VEGETA engine
// and writing back into the main memory
//////////////////////////////////////////////////////////
`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module output_control 
#(
    parameter M,
    parameter ALPHA,
    parameter ADD_DATAWIDTH,
    parameter N,
    localparam M_SCALED = M/ALPHA,
    localparam DATA_WIDTH = ADD_DATAWIDTH,
    localparam LANE_COUNT = M_SCALED * ALPHA,
    localparam DATA_DEPTH = N  
)
(
    input logic clk,
    input logic rst_n, // needs to be asserted for every new matrix output
    input logic output_start,

    input logic [ALPHA*ADD_DATAWIDTH-1:0] acc_out [0: M_SCALED-1],
    
    // BRAM interface
    output logic [31:0] output_address,
    output logic [31:0] output_data,
    output logic output_L2_enable, // L2 control
    output logic [3:0] output_L2_wenable, // L2 control

    output logic L2_load_done

);

    localparam OUTPUT_CYCLES = DATA_DEPTH + M_SCALED-1;
    localparam L2_OUTPUT_ADDRESS = 32'h8000_0000;

    logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] mem_address [0 : LANE_COUNT-1]; // address used to write to L1
    logic [`vegeta_clog2(DATA_DEPTH) - 1: 0] n_mem_address [0 : LANE_COUNT-1];
    logic [DATA_WIDTH-1:0] mem_data [0 : LANE_COUNT-1]; // data to write to L1
    logic [DATA_WIDTH-1:0] n_mem_data [0 : LANE_COUNT-1];

    logic [`vegeta_clog2(DATA_DEPTH + M_SCALED - 1) : 0] output_cycle_counter;  // used for counting cycles and locating where to start reading outputs
    logic [`vegeta_clog2(DATA_DEPTH + M_SCALED - 1) : 0] n_output_cycle_counter;
    logic write_en [0: LANE_COUNT-1];
    logic n_write_en [0: LANE_COUNT-1];
    logic mem_en;
    logic n_mem_en;
    logic n_mem_en_2;
    logic mem_en_2;
    logic mem_en_ctrl;

    // L1 read
    logic [`vegeta_clog2(DATA_DEPTH): 0] L1_read_mem_address;
    logic [`vegeta_clog2(DATA_DEPTH): 0] n_L1_read_mem_address;  
    logic [DATA_WIDTH-1:0] L1_read_mem_data [0 : LANE_COUNT-1];
    logic [`vegeta_clog2(LANE_COUNT): 0] L1_read_lane_index; 
    logic [`vegeta_clog2(LANE_COUNT): 0] n_L1_read_lane_index;

    // Output to L2
    logic n_output_L2_enable;
    logic [3:0] n_output_L2_wenable;
    logic [31:0] n_output_address;
    logic [31:0] n_output_data;

    logic L2_load_done_next;
    

    typedef enum logic [2:0] {
        RESET,
        IDLE,
        L1_STORE,
        START_L2_STORE,
        START_L2_STORE_2,
        L2_STORE,
        STATEX = 'x
    } state_type;

    state_type state, next_state;

    L1_buffer_independent_write #(
        .DATA_WIDTH(DATA_WIDTH),
        .LANE_COUNT(LANE_COUNT),
        .DATA_DEPTH(DATA_DEPTH)
    ) L1 (
        .clk(clk),
        .enable(mem_en_ctrl),
        .write(write_en),
        .data_in(mem_data),
        .write_index(mem_address),
        .read_index(L1_read_mem_address[0 +: (`vegeta_clog2(DATA_DEPTH))]),
        .data_out(L1_read_mem_data)
    );


    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            state <= RESET;
            mem_address <= '{default: '0};
            mem_data <= '{default: '0};
            write_en <= '{default: '0};
            mem_en <= '0;
            mem_en_2 <= '0;
            output_cycle_counter <= '0;

            L1_read_mem_address <= '0;
            L1_read_lane_index <= '0;

            output_address <= '0;
            output_data <= '0;
            output_L2_enable <= '0;
            output_L2_wenable <= '0;

            L2_load_done <= '0;

        end
        else begin
            state <= next_state;
            mem_address <= n_mem_address;
            mem_data <= n_mem_data;
            write_en <= n_write_en;
            mem_en <= n_mem_en;
            mem_en_2 <= n_mem_en_2;
            output_cycle_counter <= n_output_cycle_counter;

            L1_read_mem_address <= n_L1_read_mem_address;
            L1_read_lane_index <= n_L1_read_lane_index;

            output_address <= n_output_address;
            output_data <= n_output_data;
            output_L2_enable <= n_output_L2_enable;
            output_L2_wenable <= n_output_L2_wenable;

            L2_load_done <= L2_load_done_next;
        end
    end 

    always_comb begin
        next_state = STATEX;
        L2_load_done_next = '0;
        case (state)

            RESET:begin
                next_state = IDLE;
            end

            IDLE:begin
                if (output_start) 
                    next_state = L1_STORE;
                else
                    next_state = IDLE;
            end

            L1_STORE:begin
                if (output_cycle_counter == (`vegeta_clog2(DATA_DEPTH + M_SCALED - 1)+1)'(OUTPUT_CYCLES))
                    next_state = START_L2_STORE;
                else
                    next_state = L1_STORE;
            end
            START_L2_STORE:
            begin
                next_state = START_L2_STORE_2;
            end
            START_L2_STORE_2:
            begin
                next_state = L2_STORE;
            end
            L2_STORE:begin
                if (L1_read_mem_address == (`vegeta_clog2(DATA_DEPTH+1))'(DATA_DEPTH) && L1_read_lane_index == 0) begin
                    next_state = IDLE;
                    L2_load_done_next = '1;
                end else
                    next_state = L2_STORE;
            end
        endcase
    end

    // output to L1 logic
    always_comb begin
        integer m_scaled, alpha, pe_index;

        n_mem_address = '{default: '0};
        n_mem_data = '{default: '0};
        n_output_cycle_counter = '0;
        n_write_en = '{default: '0};
        n_mem_en = 1'b0;

        case (state)
            L1_STORE: begin
                if (output_cycle_counter == (`vegeta_clog2(DATA_DEPTH + M_SCALED - 1)+1)'(OUTPUT_CYCLES)) begin
                    n_mem_address = '{default: '0};
                    n_mem_data = '{default: '0};
                    n_output_cycle_counter = '0;
                    n_write_en = '{default: '0};
                    n_mem_en = '1;
                end else begin

                    for (m_scaled = 0; m_scaled < M_SCALED; m_scaled++) begin
                        for (alpha = 0; alpha < ALPHA; alpha++) begin
                            n_mem_data[ALPHA*m_scaled + alpha] = acc_out [m_scaled][alpha*ADD_DATAWIDTH +: ADD_DATAWIDTH];
                        end
                    end

                    
                    for (pe_index = 0; pe_index < M_SCALED; pe_index++) begin
                        for (alpha = 0; alpha < ALPHA; alpha++) begin

                            // don't write to memory if in the staggered locations 
                            if (output_cycle_counter < (`vegeta_clog2(DATA_DEPTH + M_SCALED - 1)+1)'(pe_index)) begin
                                n_mem_address[ALPHA*pe_index + alpha] = '0;
                                n_write_en[ALPHA*pe_index + alpha] = 1'b0;
                            end else if (output_cycle_counter - pe_index >= DATA_DEPTH) begin  // easier to write it this way
                                n_mem_address[ALPHA*pe_index + alpha] = '0;
                                n_write_en[ALPHA*pe_index + alpha] = 1'b0;
                            end else begin
                                n_mem_address[ALPHA*pe_index + alpha] = (`vegeta_clog2(DATA_DEPTH))'(output_cycle_counter - pe_index);
                                n_write_en[ALPHA*pe_index + alpha] = 1'b1;
                            end
                        end
                    end
                    
                    n_mem_en = 1'b1;
                    n_output_cycle_counter = output_cycle_counter + 1'b1;
                end
            end
        endcase
    end

    // L1 to L2 logic
    always_comb begin
        
        // L1 read
        n_L1_read_mem_address = '0;  
        n_L1_read_lane_index = '0;

        // Output to L2
        n_output_L2_enable = '0;
        n_output_L2_wenable = '0;
        n_output_address = L2_OUTPUT_ADDRESS;
        n_output_data = '0;
        n_mem_en_2 = 1'b0;

        if (state == START_L2_STORE_2) begin
            n_output_L2_enable = 1'b1;
            n_output_L2_wenable = 4'b1111;
            // n_L1_read_mem_address = L1_read_mem_address + 1;
            n_L1_read_lane_index = (`vegeta_clog2(LANE_COUNT)+1)'(L1_read_lane_index + 1);
            n_mem_en_2 = 1'b1;
            n_output_data = L1_read_mem_data[L1_read_lane_index]; // assume data width matches
        end
        else if (state == L2_STORE) begin
            n_mem_en_2 = 1'b1;
            if (L1_read_mem_address == (`vegeta_clog2(DATA_DEPTH+1))'(DATA_DEPTH) && L1_read_lane_index == 0)
                n_output_L2_enable = 1'b0;
            else
                n_output_L2_enable = 1'b1;
            n_output_L2_wenable = 4'b1111;
      
            if (L1_read_lane_index == (`vegeta_clog2(LANE_COUNT)+1)'(LANE_COUNT-1)) begin
                n_L1_read_lane_index = '0;
                n_output_address = L2_OUTPUT_ADDRESS + (L1_read_lane_index * N + L1_read_mem_address - 1) * (DATA_WIDTH / 8);
            end else begin
                n_L1_read_lane_index = (`vegeta_clog2(LANE_COUNT)+1)'(L1_read_lane_index + 1);
                n_output_address = L2_OUTPUT_ADDRESS + (L1_read_lane_index * N + L1_read_mem_address) * (DATA_WIDTH / 8);
            end
            if (L1_read_lane_index == (`vegeta_clog2(LANE_COUNT)+1)'(LANE_COUNT-2)) begin  // leave out one more cycle for L1 data to be read
                n_L1_read_mem_address = (`vegeta_clog2(DATA_DEPTH)+1)'(L1_read_mem_address + 1);
            end
            else begin
                n_L1_read_mem_address = L1_read_mem_address;
            end
                

            n_output_data = L1_read_mem_data[L1_read_lane_index]; // assume data width matches

        end 
    end

    assign mem_en_ctrl = mem_en || mem_en_2;  //(state == L1_STORE && output_cycle_counter == OUTPUT_CYCLES) || (state == L2_STORE); // L1 data readout available by L2_STORE

endmodule