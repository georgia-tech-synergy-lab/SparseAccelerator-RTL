`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module vegeta_mac
#(
    parameter ADD_DATAWIDTH,
    parameter MUL_DATAWIDTH,
    parameter META_DATA_SIZE,
    parameter BLOCK_SIZE
)
(
    input logic clk,
    input logic rst_n,
    input logic [ADD_DATAWIDTH-1 : 0] acc_in,
    // weight stationary design
    input logic [MUL_DATAWIDTH+META_DATA_SIZE - 1 : 0] weight_in,
    input logic [MUL_DATAWIDTH*BLOCK_SIZE-1:0] act_in,  // Activation data
    // Input Ctrl signal
    // mode controls whether PE is in weight_load or compute
    input logic mode,
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen
    // Output data signals
    output logic [ADD_DATAWIDTH-1:0] acc_out,
    output logic [(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out
);

    // Internal ports
    logic  [(MUL_DATAWIDTH+META_DATA_SIZE)-1:0]  weight_buffer [0:1];           // weight double buffer
    logic  [MUL_DATAWIDTH-1:0]                   weight_buffer_out;             // read weights from buffer
    logic  [META_DATA_SIZE-1:0]                  meta_buffer_out;             // read metadata from buffer
    logic  [MUL_DATAWIDTH-1:0]                   activation;
    logic  [ADD_DATAWIDTH-1:0]                   mult_out; // Outputs after calculation in this PE
    logic  [ADD_DATAWIDTH-1:0]                   acc_adder_in;
    logic  [ADD_DATAWIDTH-1:0]                   acc_adder_out;

// For support for different quantization, change these units below
bfp16_mult mult (
    .A(activation),
    .B(weight_buffer_out),
    .O(mult_out)
);

fp32_adder adder (
    .A(acc_adder_in),
    .B(mult_out),
    .O(acc_adder_out)
); 

always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        weight_buffer[0] <= '0;
        weight_buffer[1] <= '0;
        weight_out <= '0;
        acc_out <= '0;
    end

    else begin
        // Weight load stage
        if(weight_transferring_in == 1'b1) begin
            weight_out <= weight_in;
        end

        if(mode == 1'b0 && weight_transferring_in == 1'b1) begin
            weight_buffer[i_wb] <= weight_in;
        end

        else if (mode == 1'b1) begin // Compute stage
            acc_out <= acc_adder_out;
            // keep loading weights while computation is happening
            // Continue load of next set of weights into the buffers for double buffering
            if(weight_transferring_in == 1'b1) begin
                weight_buffer[~i_wb] <= weight_in;
            end
        end
    end
end

assign weight_buffer_out = weight_buffer[i_wb][MUL_DATAWIDTH - 1 : 0];		
assign meta_buffer_out =   weight_buffer[i_wb][MUL_DATAWIDTH+META_DATA_SIZE - 1:MUL_DATAWIDTH];

assign activation = act_in[MUL_DATAWIDTH*meta_buffer_out +: MUL_DATAWIDTH];
assign acc_adder_in = acc_in;

// always_comb begin
//     if(rst_n == 1'b0) begin
//         weight_buffer_out = '0;
//         meta_buffer_out = '0;
//     end

//     else begin
//         if(mode == 1'b1) begin // Do GEMM
//             weight_buffer_out = weight_buffer[i_wb][MUL_DATAWIDTH - 1 : 0];		
//             meta_buffer_out =   weight_buffer[i_wb][MUL_DATAWIDTH+META_DATA_SIZE - 1:MUL_DATAWIDTH];
//             acc_adder_in = acc_in;

//             // Select correct activation based on metadata
//             if(gemm_mode == 1'b0) // Dense
//                 // don't check metadata
//                 activation = act_in[MUL_DATAWIDTH-1 : 0];
            
//             else begin
//                 // if sparse check metadata
//                 activation = act_in[MUL_DATAWIDTH*meta_buffer_out +: MUL_DATAWIDTH];
//             end    
//         end
//     end
// end

endmodule