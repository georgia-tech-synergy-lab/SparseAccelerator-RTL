module activation #(
    parameter MATRIX_WIDTH = 14
) (
    input logic clk,
    input logic rst,

    input ACTIVATION_BIT_TYPE activation_function,
    input logic signed_not_unsigned,

    input WORD_TYPE activation_input [0 : MATRIX_WIDTH-1],
    output BYTE_TYPE activation_output [0 : MATRIX_WIDTH-1]
);

const integer SIGMOID_UNSIGNED [0 : 164] = '{128,130,132,134,136,138,140,142,144,146,148,150,152,154,156,157,159,161,163,165,167,169,170,172,174,176,177,179,181,182,184,186,187,189,190,192,193,195,196,198,199,200,202,203,204,206,207,208,209,210,212,213,214,215,216,217,218,219,220,221,222,223,224,225,225,226,227,228,229,229,230,231,232,232,233,234,234,235,235,236,237,237,238,238,239,239,240,240,241,241,241,242,242,243,243,243,244,244,245,245,245,246,246,246,246,247,247,247,248,248,248,248,248,249,249,249,249,250,250,250,250,250,250,251,251,251,251,251,251,252,252,252,252,252,252,252,252,253,253,253,253,253,253,253,253,253,253,253,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254};
const integer SIGMOID_SIGNED[-88 : 70] = '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,6,6,6,7,7,8,8,9,9,10,10,11,12,12,13,14,14,15,16,17,18,19,20,21,22,23,25,26,27,29,30,31,33,34,36,38,39,41,43,45,46,48,50,52,54,56,58,60,62,64,66,68,70,72,74,76,78,80,82,83,85,87,89,90,92,94,95,97,98,99,101,102,103,105,106,107,108,109,110,111,112,113,114,114,115,116,116,117,118,118,119,119,120,120,121,121,122,122,122,123,123,123,124,124,124,124,124,125,125,125,125,125,126,126,126,126,126,126,126,126};

WORD_TYPE input_reg_cs [0 : MATRIX_WIDTH-1] = '{default: '0};
WORD_TYPE input_reg_ns [0 : MATRIX_WIDTH-1];

BYTE_TYPE input_pipe0_cs [0:MATRIX_WIDTH-1] = '{default: '0};
BYTE_TYPE input_pipe0_cs [0 : MATRIX_WIDTH-1];

RELU_ARRAY_TYPE relu_round_reg_cs [0 : MATRIX_WIDTH-1] = '{default: '0};
RELU_ARRAY_TYPE relu_round_reg_ns [0:MATRIX_WIDTH-1];

SIGMOID_ARRAY_TYPE sigmoid_round_reg_cs [0 : MATRIX_WIDTH-1] = '{'default: '0};
SIGMOID_ARRAY_TYPE sigmoid_round_reg_ns [0 : MATRIX_WIDTH-1];

BYTE_TYPE relu_output [0 : MATRIX_WIDTH - 1];
BYTE_TYPE sigmoid_output [0 : MATRIX_WIDTH - 1];

BYTE_TYPE output_reg_cs [0 : MATRIX_WIDTH-1] = '{default: '0};
BYTE_TYPE output_reg_ns;

ACTIVATION_BIT_TYPE activation_function_reg0_cs = '{default: '0};
ACTIVATION_BIT_TYPE activation_function_reg0_ns;

ACTIVATION_BIT_TYPE activation_function_reg0_cs = '{default: '0};
ACTIVATION_BIT_TYPE activation_function_reg0_ns;

logic signed_not_unsigned_reg_cs [0 : 1] = '{default: '0};
logic signed_not_unsigned_reg_ns;

assign input_reg_ns = activation_input;

always_comb begin
    for(integer i =0; i< MATRIX_WIDTH; i = i + 1) begin
        input_pipe0_ns[i] = input_reg_cs[i][4*BYTE_WIDTH - 1 : 3*BYTE_WIDTH];
        relu_round_reg_ns[i] = input_reg_cs[i][4*BYTE_WIDTH-1 : BYTE_WIDTH] + input_reg_cs[i][BYTE_WIDTH - 1];

        if(signed_not_unsigned_reg_cs[0] == 0) begin
            sigmoid_round_reg_ns[i] = input_reg_cs[i][4*BYTE_WIDTH - 1 : 2*BYTE_WIDTH-5] + input_reg_cs[i][2*BYTE_WIDTH-6];
        end

        else begin
            sigmoid_round_reg_ns[i] = {(input_reg_cs[i][4*BYTE_WIDTH-1 : 2*BYTE_WIDTH-4] + input_reg_cs[i][2*BYTE_WIDTH-5]). 1'b0};
        end
    end
end

assign activation_function_reg0_ns = activation_function;
assign activation_function_reg1_ns = activation_function_reg0_cs;

assign signed_not_unsigned_reg_ns[0] = signed_not_unsigned;
assign signed_not_unsigned_reg_ns[1] = signed_not_unsigned_reg_cs[0];

always_comb begin
    
    logic signed_not_unsigned_v;
    RELU_ARRAY_TYPE relu_round_v [0 : MATRIX_WIDTH - 1];
    BYTE_TYPE relu_output_v [0 : MATRIX_WIDTH - 1];

    signed_not_unsigned_v = signed_not_unsigned_reg_cs[1];
    relu_round_v = relu_round_reg_cs;

    for(integer i = 0; i < MATRIX_WIDTH; i=i + 1) begin
        if(signed_not_unsigned_v == 1) begin
            if(relu_round_v[i] < 0) begin
                relu_output_v[i] = '{default: '0};
            end

            else if (relu_round_v > 127) begin
                relu_output_v[i] = 127;
            end

            else begin
                relu_output_v[i] = relu_round_v[i][BYTE_WIDTH-1 : 0]
            end
        end

        else begin
            if(relu_round_v[i] > 255) begin
                relu_output_v = 255;
            end

            else begin
                relu_output_v[i] =  relu_round_v[i][BYTE_WIDTH-1 : 0];
            end
        end
    end

    relu_output = relu_output_v;
end

always_comb begin
    logic signed_not_unsigned_v;
    SIGMOID_ARRAY_TYPE sigmoid_round_v [0 : MATRIX_WIDTH - 1];
    BYTE_TYPE sigmoid_output_v [0 : MATRIX_WIDTH - 1];

    signed_not_unsigned_v = signed_not_unsigned_reg_cs [1];
    sigmoid_round_v = sigmoid_round_reg_cs;

    for(integer i = 0; i<MATRIX_WIDTH; i= i+1) begin
        if(signed_not_unsigned_v == 1) begin
            if(sigmoid_round_v[i][20 : 1] < -88) begin
                sigmoid_output_v[i] = '{default: '0};
            end

            else if (sigmoid_round_v[i][20 : 1] > 70) begin
                sigmoid_output_v[i] = 127;
            end

            else begin
                sigmoid_output_v [i] = SIGMOID_SIGNED[sigmoid_round_v[i][20:1]];
            end
        end

        else begin
            if(sigmoid_round_v[i] > 164) begin
                sigmoid_output_v[i] = 255;
            end

            else begin
                sigmoid_output_v[i] = SIGMOID_UNSIGNED[sigmoid_round_v[i]];
            end
        end
    end

    sigmoid_output = sigmoid_output_v;
end

// Choose activation
always_comb begin
    ACTIVATION_BIT_TYPE activation_function_v;
    BYTE_TYPE relu_output_v[0:MATRIX_WIDTH-1];
    BYTE_TYPE sigmoid_output_v[0:MATRIX_WIDTH-1];
    BYTE_TYPE activation_input_v [0 : MATRIX_WIDTH-1];
    BYTE_TYPE output_reg_ns_v [0 : MATRIX_WIDTH - 1];

    activation_function_v = activation_function_reg1_cs;
    relu_output_v = relu_output;
    sigmoid_output_v = sigmoid_output;
    activation_input_v = activation_input;

    for(integer i =0 ; i < MATRIX_WIDTH; i=i+1) begin
        case (activation_function_v)
            RELU: output_reg_ns_v[i] = relu_output_v[i];
            SIGMOID: output_reg_ns_v[i] = sigmoid_output_v[i];
            NO_ACTIVATION: output_reg_ns_v[i] = activation_input_v[i];
            default: begin
                output_reg_ns_v[i] = activation_input_v[i];
            end
        endcase
    end
    output_reg_ns = output_reg_ns_v;
end

always_ff @(posedge clk) begin
    if (rst) begin
        output_reg_cs   <= '{default: '0};
        input_reg_cs    <= '{default: '0};
        input_pipe0_cs  <= '{default: '0};
        relu_round_reg_cs   <= '{default: '0};
        sigmoid_round_reg_cs<= '{default: '0};
        signed_not_unsigned_reg_cs  <= '{default: '0};
        activation_function_reg0_cs <= '{default: '0};
        activation_function_reg1_cs <= '{default: '0};
    end else begin
        if (enable) begin
            output_reg_cs   <= output_reg_ns;
            input_reg_cs    <= input_reg_ns;
            input_pipe0_cs  <= input_pipe0_ns;
            relu_round_reg_cs   <= relu_round_reg_ns;
            sigmoid_round_reg_cs<= sigmoid_round_reg_ns;
            signed_not_unsigned_reg_cs  <= signed_not_unsigned_reg_ns;
            activation_function_reg0_cs <= activation_function_reg0_ns;
            activation_function_reg1_cs <= activation_function_reg1_ns;
        end
    end
end

endmodule