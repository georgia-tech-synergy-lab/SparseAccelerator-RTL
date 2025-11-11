//////////////////////////////////////////////////////////
// Copyright Ethan Weinstock, Garrett Botkin, Jingsong Guo
// Top level test bench of VEGETA top level deisgn
// Includes models of L2 memory
//////////////////////////////////////////////////////////

`timescale 1ns/1ps

`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module vegeta_top_tb ();

    // matrix dimensions: 
    // weight M by K
    // activation K by N
    localparam M = 16; 
    localparam K = 16;
    localparam N = 16;
    localparam ALPHA = 1;
    // Horizontal reduction

    localparam BETA = 1; // Vertical reduction
    localparam ADD_DATAWIDTH = 32;
    localparam MUL_DATAWIDTH = 16;
    localparam K_SCALED = K/BETA;
    localparam M_SCALED = M/ALPHA;
    localparam BLOCK_SIZE = 4; // BLOCK_SIZE from the SPARSITY_DEGREE:BLOCK_SIZE definition (used to identify how many input activations are needed)
    localparam META_DATA_SIZE = `vegeta_clog2(BLOCK_SIZE);
    

    // Testbench Params
    localparam DEBUG   = 0;
    localparam VERBOSE = 0;

    localparam NUM_TRIALS = 1;

    localparam ENABLE_DENSE_TESTS     = 1;
    localparam ENABLE_2X4SPARSE_TESTS = 0;
    localparam ENABLE_1X4SPARSE_TESTS = 0;

    localparam RANDOM_TESTS = 0;

    // Testbench Signals
    logic clk;
    logic rst_n;

    logic start_multiplication;
    logic [31:0] sparsity_degree;

    // activation BRAM interface
    logic [31:0] activation_address;
    logic [31:0] activation_data;
    logic        activation_enable;

    // weight BRAM interface
    logic [31:0] weight_address;
    logic [31:0] weight_data;
    logic        weight_enable;

    // metadata BRAM interface
    logic [31:0] metadata_address;
    logic [31:0] metadata_data;
    logic        metadata_enable;

    // accumulation BRAM interface
    logic [31:0] accumulation_address;
    logic [31:0] accumulation_data;
    logic        accumulation_enable;

    // output BRAM interface
    logic [31:0] output_address;
    logic [31:0] output_data;
    logic output_enable;
    logic [3:0] output_write;

    logic compute_done;

    // DUT
    vegeta_top #(
        .M(M),
        .K(K),
        .N(N),
        .ALPHA(ALPHA)
    ) my_vegeta_top (
        .clk(clk),
        .rst_n(rst_n),
        .start_multiplication(start_multiplication),
        .sparsity_degree(sparsity_degree),

        .activation_address(activation_address),
        .activation_data(activation_data),
        .activation_enable(activation_enable),

        .weight_address(weight_address),
        .weight_data(weight_data),
        .weight_enable(weight_enable),

        .metadata_address(metadata_address),
        .metadata_data(metadata_data),
        .metadata_enable(metadata_enable),

        .accumulation_address(accumulation_address),
        .accumulation_data(accumulation_data),
        .accumulation_enable(accumulation_enable),

        .output_address(output_address),
        .output_data(output_data),
        .output_enable(output_enable),
        .output_write(output_write),

        .compute_done(compute_done)
    );

    // BRAM Memory
    logic [31:0] weight_bram [0:K*M*MUL_DATAWIDTH/32-1];
    logic [31:0] metadata_bram [0:K*M*META_DATA_SIZE/32-1];
    logic [31:0] activation_bram [0:BLOCK_SIZE*K*N*MUL_DATAWIDTH/32-1];
    logic [31:0] accumulation_bram [0:M*N*ADD_DATAWIDTH/32-1];
    logic [31:0] output_bram [0:M*N*ADD_DATAWIDTH/32-1];

    // Read from Weight Ram
    always_ff @(posedge clk) begin
        if (weight_enable) begin
            weight_data <= weight_bram[weight_address[2 +: `vegeta_clog2(K*M*MUL_DATAWIDTH/32)+1]];
        end else begin
            weight_data <= 'x;
        end
    end

    // Read from Metadata Ram
    always_ff @(posedge clk) begin
        if (metadata_enable) begin
            metadata_data <= metadata_bram[metadata_address[2 +: `vegeta_clog2(K*M*META_DATA_SIZE/32)+1]];
        end else begin
            metadata_data <= 'x;
        end
    end

    // Read from Activation Ram
    always_ff @(posedge clk) begin
        if (activation_enable) begin
            activation_data <= activation_bram[activation_address[2 +: `vegeta_clog2(K*BLOCK_SIZE*N*MUL_DATAWIDTH/32)+1]];
        end else begin
            activation_data <= 'x;
        end
    end

    // Read from Accumulation Ram
    always_ff @(posedge clk) begin
        if (accumulation_enable) begin
            accumulation_data <= accumulation_bram[accumulation_address[2 +: `vegeta_clog2(M*N*ADD_DATAWIDTH/32)+1]];
        end else begin
            accumulation_data <= 'x;
        end
    end

    integer cycle_count;

    always @(posedge clk) begin
        if (compute_done) begin
            // Stop counting once compute_done is high
            cycle_count = cycle_count; // Keep the value unchanged
        end 
        else if (weight_enable) begin
            if (cycle_count == 32'hx || cycle_count == 0)  
                cycle_count = 1; // Initialize to 1 when weight_enable is first asserted
            else
                cycle_count = cycle_count + 1; // Increment on every clock cycle
        end 
        else begin
            cycle_count = 0; // Reset when weight_enable is de-asserted
        end
    end

    // Write to Output Ram
    always_ff @(posedge clk) begin
        $display(cycle_count);
        if (output_enable && output_write == '1)
            output_bram[output_address[2 +: `vegeta_clog2(M*N*ADD_DATAWIDTH/32)+1]] <= output_data;
    end
    
    // Clock Block
    initial begin
        clk = 1'b0;
        forever begin
            #50 clk = ~clk;
        end
    end

    // genvar i,j, alpha, beta;
    // generate;
    //     initial begin
    //         for(i=0; i < K_SCALED; i = i + 1) begin : vertical
    //             for(j = 0; j< 1; j = j + 1) begin : horizontal
    //                 for (alpha = 0; alpha < 1; alpha = alpha + 1) begin : alpha
    //                     for (beta = 0; beta < BETA; beta = beta + 1) begin : beta
    //                         always_comb begin
    //                             $display($bitstoshortreal({my_vegeta_top.my_vegeta_compute_top.vertical[0].horizontal[0].genblk1.vegeta_pe_inst_0_0.pu_gen[0].vegeta_pu_i.mac_gen[0].vegeta_mac_i.weight_buffer_out[15:0], 16'b0});
    //                     end
    //                 end
    //             end
    //         end
    //     end
    // endgenerate;

    integer failures;
    // Simulation
    initial begin
        // $vcdpluson;   
        // $vcdplusmemon;
        failures = 0;
        rst_n = '0;
        #200 rst_n = '1;

        // Dense Tests
        if (ENABLE_DENSE_TESTS) begin
            $display("Dense Tests \n");
            repeat (NUM_TRIALS) begin
                sparsity_degree = 4;
                gen_ram(RANDOM_TESTS);
                start_multiplication = '0;

                #500 start_multiplication = '1;
                #100 start_multiplication = '0;

                @(posedge compute_done)
                validate_output();
            end
        end

        // Sparse Tests (2:4)
        if (ENABLE_2X4SPARSE_TESTS) begin
            $display("2x4 Sparse Tests \n");
            repeat (NUM_TRIALS) begin
                sparsity_degree = 2;
                gen_ram(RANDOM_TESTS);
                
                start_multiplication = '0;

                #500 start_multiplication = '1;
                #100 start_multiplication = '0;

                @(posedge compute_done)

                validate_output();
            end
        end

        // Sparse Tests (1:4)
        if (ENABLE_1X4SPARSE_TESTS) begin
            $display("1x4 Sparse Tests \n");
            repeat (NUM_TRIALS) begin
                sparsity_degree = 1;
                gen_ram(RANDOM_TESTS);
                
                start_multiplication = '0;

                #500 start_multiplication = '1;
                #100 start_multiplication = '0;

                @(posedge compute_done)

                validate_output();
            end
        end

        if (failures == 0) begin
            $display("PASSED");
        end else begin
            $display("FAILED");
        end

        #10000 $finish;
    end

    // Initilize Ram
    function gen_ram();
        input bit randomize_ram;

        integer i, j;
        shortreal num;
        logic [31:0] field_1, field_0, temp_value;

        begin

            if (randomize_ram) begin
                    
                // Random Ram Values
                temp_value = '1;
                for (i = 0 ; i < K*M*MUL_DATAWIDTH/32; i++) begin
                    while (temp_value[30:23] == 8'b11111111 || temp_value[14:7] == 8'b11111111)
                        temp_value = $urandom();
                    temp_value[30:23] = 8'b10000000;
                    temp_value[14:7] = 8'b10000000;
                    weight_bram[i] = temp_value;
                    temp_value = '1;
                end

                temp_value = '1;
                for (i = 0 ; i < K*N*BLOCK_SIZE*MUL_DATAWIDTH/32; i++) begin
                    while (temp_value[30:23] == 8'b11111111 || temp_value[14:7] == 8'b11111111)
                        temp_value = $urandom();
                    temp_value[30:23] = 8'b10000000;
                    temp_value[14:7] = 8'b10000000;
                    activation_bram[i] = temp_value;
                    temp_value = '1;
                end

                temp_value = '1;
                for (i = 0; i < M*N*ADD_DATAWIDTH/32; i++) begin
                    while (temp_value[30:23] == 8'b11111111 || temp_value[14:7] == 8'b11111111)
                        temp_value = $urandom();     
                    temp_value[30:23] = 8'b10000000;
                    temp_value[14:7] = 8'b10000000;
                    accumulation_bram[i] = temp_value;
                    temp_value = '1;
                end

                for (i = 0; i <  K*M*META_DATA_SIZE/32; i++)
                    if (sparsity_degree == 4) begin
                        metadata_bram[i] = '0;
                    end else if (sparsity_degree == 2) begin
                        for (j = 0; 64'(j) < $floor(32/META_DATA_SIZE); j += 2) begin
                            temp_value = $urandom();  
                            metadata_bram[i][j*META_DATA_SIZE +: META_DATA_SIZE] = temp_value[1:0];
                            metadata_bram[i][(j+1)*META_DATA_SIZE +: META_DATA_SIZE] = temp_value[3:2];
                            while (metadata_bram[i][j*META_DATA_SIZE +: META_DATA_SIZE] == metadata_bram[i][(j+1)*META_DATA_SIZE +: META_DATA_SIZE]) begin
                                temp_value = $urandom();  
                                metadata_bram[i][j*META_DATA_SIZE +: META_DATA_SIZE] = temp_value[1:0];
                                metadata_bram[i][(j+1)*META_DATA_SIZE +: META_DATA_SIZE] = temp_value[3:2];
                            end
                        end
                    end else if (sparsity_degree == 1) begin
                        metadata_bram[i] = $urandom();
                    end

            end else begin

                // Set Ram Values
                num = 0;
                for (i = 0 ; i < K*M*MUL_DATAWIDTH/32; i++) begin
                    field_0 = $shortrealtobits(num);
                    field_1 = $shortrealtobits(num + 1);
                    weight_bram[i]     = {field_1[31:16], field_0[31:16]};
                    num += 2;
                end
                num = 0;
                for (i = 0 ; i < K*N*BLOCK_SIZE*MUL_DATAWIDTH/32; i++) begin
                    field_0 = $shortrealtobits(num);
                    field_1 = $shortrealtobits(num + 1);
                    activation_bram[i] = {field_1[31:16], field_0[31:16]};
                    num += 2;
                end

                num = 0;
                for (i = 0; i < M*N*ADD_DATAWIDTH/32; i++) begin
                    field_0 = $shortrealtobits(num);
                    accumulation_bram[i] = field_0;
                    num += 1;
                end

                for (i = 0; i < K*M*META_DATA_SIZE/32; i++) begin
                    metadata_bram[i] = {4{8'b11100100}};
                end

            end

        end

    endfunction : gen_ram

    // Creation of Golden Matrix to compare output of VEGETA to. 
    function validate_output;

        integer i, j, x, y, k, failed;
        logic [1:0] metadata;


        shortreal   weight_matrix        [0:M-1][0:K-1];
        shortreal   sparse_weight_matrix [0:M-1][0:K*BLOCK_SIZE-1];
        logic [1:0] metadata_matrix      [0:M-1][0:K-1];
        shortreal   activation_matrix    [0:K*BLOCK_SIZE-1][0:N-1];
        shortreal   accumulation_matrix  [0:M-1][0:N-1];

        shortreal output_matrix [0:M-1][0:N-1];

        shortreal mult_output;

        shortreal lane_0, lane_1;

        begin
            // Create Matrixes

            weight_matrix = '{default:'0};
            sparse_weight_matrix = '{default:'0};
            metadata_matrix = '{default:'0};
            activation_matrix = '{default:'0};
            accumulation_matrix = '{default:'0};

            output_matrix = '{default:'0};

            for (i = 0; i < K*M; i++) begin
                metadata_matrix[i/K][i % K] = metadata_bram[i/(32/META_DATA_SIZE)][(i%(32/META_DATA_SIZE))*META_DATA_SIZE +: META_DATA_SIZE];
            end

            for (i = 0 ; i < K*M*MUL_DATAWIDTH/32*2; i+=2) begin
                weight_matrix[i/K][i%K]   = $bitstoshortreal({weight_bram[i/2][0  +: 16], 16'b0});
                weight_matrix[i/K][i%K+1] = $bitstoshortreal({weight_bram[i/2][16 +: 16], 16'b0});
            end

            j = 0;
            for (y = 0 ; y < M; y++) begin
                if (sparsity_degree == 4) begin
                    for (x = 0 ; x < K; x++) begin
                        sparse_weight_matrix[y][x] = weight_matrix[y][x];
                    end
                end else if (sparsity_degree == 2) begin
                    for (x = 0 ; x < K; x+=2) begin
                        metadata = metadata_matrix[y][x];
                        sparse_weight_matrix[y][x*2+metadata] = weight_matrix[y][x];
                        metadata = metadata_matrix[y][x+1];
                        sparse_weight_matrix[y][x*2+metadata] = weight_matrix[y][x+1];
                    end
                end else if( sparsity_degree == 1) begin
                    for (x = 0 ; x < K; x++) begin
                        metadata = metadata_matrix[y][x];
                        sparse_weight_matrix[y][x*4+metadata] = weight_matrix[y][x];
                    end
                end

            end

            for (i = 0 ; i < BLOCK_SIZE*K*N*MUL_DATAWIDTH/32*2; i+=2) begin
                activation_matrix[i/N][i%N]   = $bitstoshortreal({activation_bram[i/2][0  +: 16], 16'b0});
                activation_matrix[i/N][i%N+1] = $bitstoshortreal({activation_bram[i/2][16 +: 16], 16'b0});
            end

            for (i = 0 ; i < M*N*ADD_DATAWIDTH/32; i++) begin
                accumulation_matrix[i/N][i%N] = $bitstoshortreal(accumulation_bram[i]);
            end

            if (VERBOSE) begin
                $display("Weight: \n", sparse_weight_matrix, "\n");
                $display("Metadata: \n", metadata_matrix, "\n");

                $display("Activation: \n", activation_matrix, "\n");
                $display("Accumulation: \n", accumulation_matrix, "\n");
            end

            // Loop 1
            for (int i = 0; i < M; i++) begin
                // Loop 2
                for (int j = 0; j < N; j++) begin
                    // Loop 3
                    lane_0 = accumulation_matrix[i][j];
                    lane_1 = 0;
                    for (int k = 0; k < K*BLOCK_SIZE/sparsity_degree; k+=2) begin
                        // Multiply and Store
                        lane_0 += sparse_weight_matrix[i][k] * activation_matrix[k][j];
                        lane_1 += sparse_weight_matrix[i][k+1] * activation_matrix[k+1][j];
                    end

                    // Accumulate and Store
                    output_matrix[i][j] = lane_0 + lane_1;

                end
            end

            if (VERBOSE) begin
                $display("Output: \n", output_matrix, "\n");
            end

            // Loop 1
            failed = 0;
            for (int i = 0; i < M; i++) begin
                // Loop 2
                for (int j = 0; j < N; j++) begin
                    if ($shortrealtobits(output_matrix[i][j]) != (output_bram[i*N+j])) begin
                        $display("\nError Mismatched Values Found at: %d %d", i, j);
                        $display( "Output Matrix: ", output_matrix[i][j]);
                        $display( "Output BRAM:   ", $bitstoshortreal(output_bram[i*N+j]));
                        $displayh("Output Matrix: ", $shortrealtobits(output_matrix[i][j]));
                        $displayh("Output BRAM:   ", (output_bram[i*N+j]));
                        failed = 1;             
                    end
                end
            end

            if (failed == 0) begin
                if (DEBUG) begin
                    $display("PASSED");
            end
            end else begin
                failures++;
                if (DEBUG) begin
                    $display("FAILED");
                end
            end

            $display("\n\n");

        end

    endfunction : validate_output

endmodule