`include "vTPU_pkg_fp6.sv"
module vegeta_mac_fp6
// import vTPU_pkg_fp6::*;
(
    input logic clk,
    input logic rst_n,
    input logic [ADD_DATAWIDTH-1 : 0] acc_in,
    input logic [MUL_DATAWIDTH+META_DATA_SIZE - 1 : 0] weight_in,
    input [MUL_DATAWIDTH*M-1:0] act_in,  // Activation data
    // Input Ctrl signal
    input logic [1:0] mode,
    input logic [1 : 0] gemm_mode, // dense, or 2:4, 1:4 etc
    input logic weight_transferring_in,
    input logic i_wb, // buffer select into which next load will happen

    //scaling factor
    input logic [7:0] input_scale,             //exponent only
    input logic [7:0] weight_scale,
    input logic [7:0] input_acc_scale,
    output logic [7:0] output_acc_scale,

    // Output data signals
    output logic [ADD_DATAWIDTH-1:0] acc_out,
    output logic [(MUL_DATAWIDTH+META_DATA_SIZE)-1:0] weight_out,
    output weight_transferring_out
);

    // Internal ports
    logic  [(MUL_DATAWIDTH+META_DATA_SIZE)-1:0]  weight_buffer [0:1];           // weight double buffer
    logic  [MUL_DATAWIDTH-1:0]                   weight_buffer_out;             // read weights from buffer
    logic  [META_DATA_SIZE-1:0]                  meta_buffer_out;             // read metadata from buffer
    logic [MUL_DATAWIDTH-1:0]                    activation;
    wire logic [MUL_DATAWIDTH-1:0]               mult_out; // Outputs after calculation in this PE
    logic  [ADD_DATAWIDTH-1:0]                   acc_adder_in;
    wire logic [ADD_DATAWIDTH-1:0]               acc_adder_out;
    logic                                        weight_transferring_out_driver;
    logic [7:0]                                  scale_acc_out;
    logic [7:0]                                  output_acc_scale_temp;

// For support for different quantization, change these units below
fp6_mult mult (
    .A(activation),
    .B(weight_buffer_out),
    .O(mult_out)
);

fp6_adder adder (
    .A(acc_adder_in),
    .B(mult_out),
    .O(acc_adder_out)
); 

always_ff @(posedge clk) begin
    if(rst_n == 1'b0) begin
        weight_buffer[0] <= 0;
        weight_buffer[1] <= 0;
        weight_out <= 0;
        acc_out <= 0;
        weight_transferring_out_driver <= 0;              
    end

    else begin
        // Weight load stage
        if(mode == 2'b00 && weight_transferring_in == 1) begin
            weight_buffer[i_wb] <= weight_in;
            weight_out <= weight_in;
            // weight_transferring_out <= weight_transferring_in;     
        end

        else if (mode == 2'b10) begin // Compute stage
            acc_out <= acc_adder_out;
            
            // Continue load of next set of weights into the buffers for double buffering
            if(weight_transferring_in == 1) begin
                weight_buffer[~i_wb] <= weight_in;
                weight_out <= weight_in;
                // weight_transferring_out <= weight_transferring_in;
            end
        end
    end
end

always_comb begin
    if(rst_n == 1'b0) begin
        weight_buffer_out = 0;
        meta_buffer_out = 0;
    end

    else begin
        if(mode == 2'b10) begin // Do GEMM
            
            weight_buffer_out = weight_buffer[i_wb][MUL_DATAWIDTH - 1 : 0];		
            meta_buffer_out =   weight_buffer[i_wb][MUL_DATAWIDTH+META_DATA_SIZE - 1:MUL_DATAWIDTH];
            acc_adder_in = acc_in;

            // Select correct activation based on metadata
            if(gemm_mode == 0) // Dense
                activation = act_in[MUL_DATAWIDTH-1 : 0];
            
            else begin
                activation = act_in[MUL_DATAWIDTH*meta_buffer_out +: MUL_DATAWIDTH];
            end    
        end
    end
end

// Output scaling
always_comb begin
    if(rst_n == 1'b0) begin
        scale_acc_out = 0;
    end

    else begin
        if(mode == 2'b10) begin
            scale_acc_out = input_scale+weight_scale;
            if(scale_acc_out > 7'd127) begin
                output_acc_scale_temp = 7'd127;
            end else if (scale_acc_out < input_acc_scale) begin
                output_acc_scale_temp = input_acc_scale;
            end else begin
                output_acc_scale_temp = scale_acc_out;
            end

        end
    end
end

assign output_acc_scale = output_acc_scale_temp;

endmodule