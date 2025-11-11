`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module vegeta_top
#(
    // matrix dimensions: 
    // weight M by K
    // activation K by N
    parameter M = 4, // column
    parameter K = 4, // row
    parameter N = 4,

    parameter ALPHA = 2 // Horizontal reduction
)
(
    input logic clk,
    input logic rst_n,
    input logic start_multiplication,

    input logic [31:0] sparsity_degree,

    // activation BRAM interface
    output logic [31:0] activation_address,
    input logic [31:0] activation_data,
    output logic activation_enable,

    // weight BRAM interface
	output logic [31:0] weight_address,
    input logic [31:0] weight_data,
    output logic weight_enable,

    // metadata BRAM interface
	output logic [31:0] metadata_address,
    input logic  [31:0] metadata_data,
    output logic metadata_enable,

    // accumulation BRAM interface
    output logic [31:0] accumulation_address,
    input logic [31:0] accumulation_data,
    output logic accumulation_enable,

    // output BRAM interface
    output logic [31:0] output_address,
    output logic [31:0] output_data,
    output logic output_enable,
    output logic [3:0] output_write,

    output logic compute_done
);

localparam BETA = 2; // Vertical reduction
localparam ADD_DATAWIDTH = 32;
localparam MUL_DATAWIDTH = 16;
localparam K_SCALED = K/BETA;
localparam M_SCALED = M/ALPHA;
localparam BLOCK_SIZE = 4; // BLOCK_SIZE from the N:BLOCK_SIZE definition (used to identify how many input activations are needed)
localparam META_DATA_SIZE = `vegeta_clog2(BLOCK_SIZE);


// vegeta compute top signals
logic [ALPHA*BETA*(MUL_DATAWIDTH+META_DATA_SIZE) - 1 : 0] weight_in [0 : M_SCALED-1];
logic [MUL_DATAWIDTH*BLOCK_SIZE*BETA-1:0] activation_in [0 : K_SCALED-1];
logic [ALPHA*BETA*ADD_DATAWIDTH-1 : 0] acc_in [0 : M_SCALED-1];
logic mode;
logic weight_transferring_in;
logic i_wb; // buffer select into which next load will happen
logic [ALPHA*ADD_DATAWIDTH-1:0] acc_out [0 : M_SCALED-1];

// top level control signals
logic begin_load;
logic start_compute;
logic output_valid;

// weight control
logic weight_L1_loaded;
logic weight_array_loaded;

// activation control
logic [`vegeta_clog2(BLOCK_SIZE):0] m_by_n;
logic activation_transferring_in;
logic activation_L1_loaded;
logic activation_start;
logic activations_loaded;

// accumulation control
logic accumulation_transferring_in;
logic accumulation_L1_loaded;
logic accumulations_loaded;

// output control
logic output_L2_loaded;



always_comb begin 
    case(sparsity_degree)
        1: begin
            m_by_n = (`vegeta_clog2(BLOCK_SIZE)+1)'(4);
        end
        2: begin
            m_by_n = (`vegeta_clog2(BLOCK_SIZE)+1)'(2);
        end
        4: begin
            // dense is BLOCK_SIZE/N is 1
            m_by_n = (`vegeta_clog2(BLOCK_SIZE)+1)'(1);
        end
        default: begin
            m_by_n = (`vegeta_clog2(BLOCK_SIZE)+1)'(1);
        end
    endcase
end

assign i_wb = '0;

vegeta_control #(
    .K_SCALED(K_SCALED),
    .M_SCALED(M_SCALED),
    .N(N)
) my_vegeta_control (
    .clk(clk),
    .rst_n(rst_n),
    // global control signal
    .start_multiplication(start_multiplication),
    .begin_load(begin_load),

    // status signals
    .weight_array_loaded(weight_array_loaded),
    .activation_L1_loaded(activation_L1_loaded),
    .accumulation_L1_loaded(accumulation_L1_loaded),
    .output_L2_loaded(output_L2_loaded),

    // compute control
    .start_compute(start_compute),
    .mode(mode),
    .output_valid(output_valid),

    // statistics
    .compute_done(compute_done)
);

activation_control #(
    .K(K),
    .N(N),
    .ALPHA(ALPHA),
    .BETA(BETA),
    .MUL_DATAWIDTH(MUL_DATAWIDTH),
    .BLOCK_SIZE(BLOCK_SIZE)
) my_activation_control (
    .clk(clk),
    .rst_n(rst_n),
    // L1 load control signals
    .m_by_n(m_by_n),
    .begin_load(begin_load),
    .activation_L1_loaded(activation_L1_loaded),
    // memory signals
	.activation_address(activation_address),
    .activation_data(activation_data),
    .activation_enable(activation_enable),
    // start array load from L1
    .load_array_from_L1(start_compute),
    .activation_transferring_in(activation_transferring_in),
    .activation_in(activation_in),
    .activations_loaded(activations_loaded)
);

weight_control #(
    .K(K),
    .M(M),
    .ALPHA(ALPHA),
    .BETA(BETA),
    .MUL_DATAWIDTH(MUL_DATAWIDTH),
    .META_DATA_SIZE(META_DATA_SIZE),
    .BLOCK_SIZE(BLOCK_SIZE)  
) my_weight_control (
    .clk(clk),
    .rst_n(rst_n),
    // L1 load control signals
    .begin_load(begin_load),
    .m_by_n(m_by_n),
    .L1_loaded(weight_L1_loaded),
    // memory signals
	.weight_address(weight_address),
    .weight_data(weight_data),
    .weight_enable(weight_enable),
	.metadata_address(metadata_address),
    .metadata_data_in(metadata_data),
    .metadata_enable(metadata_enable),
    // start array load from L1
    .load_array_from_L1(weight_L1_loaded),
    .weight_transferring_in(weight_transferring_in),
    .weight_in(weight_in),
    .weight_array_loaded(weight_array_loaded)
);

accumulation_control #(
    .K(K),
    .M(M),
    .ALPHA(ALPHA),
    .BETA(BETA),
    .ADD_DATAWIDTH(ADD_DATAWIDTH),
    .N(N)
) my_accumulation_control(
    .clk(clk),
    .rst_n(rst_n),
    .begin_load(begin_load),
    .accumulation_L1_loaded(accumulation_L1_loaded),

    // accumulation BRAM interface
	.accumulation_address(accumulation_address),
    .accumulation_data(accumulation_data),
    .accumulation_enable(accumulation_enable),

    .load_array_from_L1(start_compute),
    .accumulation_transferring_in(accumulation_transferring_in),
    .accumulation_in(acc_in),
    .accumulations_loaded(accumulations_loaded)
);

output_control #(
    .M(M),
    .ALPHA(ALPHA),
    .ADD_DATAWIDTH(ADD_DATAWIDTH),
    .N(N)
) my_output_control (
    .clk(clk),
    .rst_n(rst_n), 
    .output_start(output_valid),
    .acc_out(acc_out),
    
    // BRAM interface
    .output_address(output_address),
    .output_data(output_data),
    .output_L2_enable(output_enable),
    .output_L2_wenable(output_write),

    .L2_load_done(output_L2_loaded)
);

vegeta_compute_top #(
    .K_SCALED(K_SCALED),
    .M_SCALED(M_SCALED),
    .ALPHA(ALPHA),
    .BETA(BETA),
    .ADD_DATAWIDTH(ADD_DATAWIDTH),
    .MUL_DATAWIDTH(MUL_DATAWIDTH),
    .META_DATA_SIZE(META_DATA_SIZE),
    .BLOCK_SIZE(BLOCK_SIZE)  
) my_vegeta_compute_top
(
    .clk(clk),
    .rst_n(rst_n),
    .weight_in (weight_in),
    .act_in(activation_in),
    .acc_in(acc_in),
    .mode(mode),
    .weight_transferring_in(weight_transferring_in),
    .i_wb(i_wb),
    .acc_out(acc_out)
);

endmodule