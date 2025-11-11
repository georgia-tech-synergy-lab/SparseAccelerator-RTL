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
package vTPU_pkg;

    localparam ADD_DATAWIDTH = 16;
    localparam MUL_DATAWIDTH = 16;
    localparam META_DATA_SIZE = 2;
    localparam BITWIDTH = 8;
    localparam NUM_REG_ROWS = 16; // 16 rows
    localparam NUM_REG_COLUMNS = 64; // 64 bytes in each column, assuming 8-bit per-location granularity
    localparam NUM_REGS = 8;

    // META DATA Registers
    localparam NUM_META_REG_COLUMNS = 32;

    // Compute
    localparam BETA = 1; // Vertical reduction
    localparam ALPHA = 1; // Horizontal reduction
    localparam M = 1; // M from the N:M definition (used to identify how many input activations are needed)
    localparam N = 1;

    // Systolic Array Parameters
    localparam X = 3; // row
    localparam Y = 3; // column

    // After reduction operations
    localparam X_SCALED = X/BETA;
    localparam Y_SCALED = Y/ALPHA;




    // localparam BYTE_WIDTH = 8;
    // localparam EXTENDED_BYTE_WIDTH = BYTE_WIDTH + 1;
    // localparam BUFFER_ADDRESS_WIDTH = 24;
    // localparam ACCUMULATOR_ADDRESS_WIDTH = 16;
    // localparam MATRIX_WIDTH = 14;
    // localparam WEIGHT_ADDRESS_WIDTH = BUFFER_ADDRESS_WIDTH + ACCUMULATOR_ADDRESS_WIDTH;
    // localparam OP_CODE_WIDTH = 8;
    // localparam LENGTH_WIDTH = 32;
    // localparam INSTRUCTION_WIDTH = WEIGHT_ADDRESS_WIDTH + LENGTH_WIDTH + OP_CODE_WIDTH;

    // typedef logic[BYTE_WIDTH - 1: 0] BYTE_TYPE;
    // typedef logic[EXTENDED_BYTE_WIDTH - 1: 0] EXTENDED_BYTE_TYPE;
    // typedef logic[2*EXTENDED_BYTE_WIDTH - 1 : 0] MUL_HALFWORD_TYPE;
    // typedef logic[2*BYTE_WIDTH - 1 : 0] HALFWORD_TYPE;
    // typedef logic[4*BYTE_WIDTH - 1 : 0] WORD_TYPE;

    // typedef logic[BUFFER_ADDRESS_WIDTH - 1 : 0] BUFFER_ADDRESS_TYPE;
    // typedef logic[MATRIX_WIDTH*BYTE_WIDTH - 1 : 0] RAM_TYPE;
    // typedef logic[WEIGHT_ADDRESS_WIDTH-1 : 0] WEIGHT_ADDRESS_TYPE;
    // typedef logic [ACCUMULATOR_ADDRESS_WIDTH - 1 : 0] ACCUMULATOR_ADDRESS_TYPE;

    // typedef logic [4*BYTE_WIDTH*MATRIX_WIDTH-1] ACCUMULATOR_TYPE;
    // typedef logic [OP_CODE_WIDTH - 1 : 0] OP_CODE_TYPE;
    // typedef logic [LENGTH_WIDTH - 1 : 0] LENGTH_TYPE;
    // typedef logic [3 : 0] ACTIVATION_BIT_TYPE;

    // typedef logic [20 : 0] SIGMOID_ARRAY_TYPE;
    // typedef logic [3*BYTE_WIDTH-1  : 0] RELU_ARRAY_TYPE;

    // typedef enum  {NO_ACTIVATION, RELU, RELU6, CRELU, ELU, SELU, SOFTPLUS, SOFTSIGN, DROPOUT, SIGMOID, TANH} ACTIVATION_TYPE;
    
    // typedef struct packed {
    //     OP_CODE_TYPE op_code;
    //     LENGTH_TYPE calc_length;
    //     ACCUMULATOR_ADDRESS_TYPE acc_address;
    //     BUFFER_ADDRESS_TYPE buffer_address;
    // } INSTRUCTION_TYPE;

    // typedef struct packed {
    //     OP_CODE_TYPE op_code;
    //     LENGTH_TYPE calc_length;
    //     WEIGHT_ADDRESS_TYPE weight_address;
    // } WEIGHT_INSTRUCTION_TYPE;

    // virtual class ByteArrayToBits 
    // #(parameter ARRAY_LENGTH = MATRIX_WIDTH,
    // parameter BYTE_WIDTH = BYTE_WIDTH);
    //     static function logic [(ARRAY_LENGTH * BYTE_WIDTH)-1:0] byte_array_to_bits
    //     (input [BYTE_WIDTH - 1 : 0] byte_array [0 : ARRAY_LENGTH - 1]);
    //     logic [ ARRAY_LENGTH * BYTE_WIDTH - 1 : 0] bit_vector;
    //     integer i;
    //     for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
    //         bit_vector[i*BYTE_WIDTH +: BYTE_WIDTH] = byte_array[i];
    //     end

    //     return bit_vector;
    //     endfunction
    // endclass

    // virtual class WordArrayToBits 
    // #(parameter ARRAY_LENGTH = MATRIX_WIDTH,
    // parameter BYTE_WIDTH = BYTE_WIDTH);
    //     static function logic [(ARRAY_LENGTH * 4*BYTE_WIDTH)-1:0] word_array_to_bits
    //     (input WORD_TYPE word_array [0 : ARRAY_LENGTH - 1]);
    //     logic [(ARRAY_LENGTH * 4*BYTE_WIDTH)-1:0] bit_vector;
    //     integer i;
    //     for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
    //         bit_vector[i*4*BYTE_WIDTH +: 4*BYTE_WIDTH] = word_array[i];
    //     end
    //     return bit_vector;
    //     endfunction
    // endclass

    // automatic function WEIGHT_INSTRUCTION_TYPE to_weight_instruction
    // (input INSTRUCTION_TYPE instruction);
    // WEIGHT_INSTRUCTION_TYPE weight_instruction;
    // weight_instruction.op_code = instruction.op_code;
    // weight_instruction.calc_length = instruction.calc_length;
    // weight_instruction.weight_address = instruction.buffer_address & instruction.acc_address;

    // return weight_instruction;

    // endfunction

    // // typedef BYTE_TYPE byte_array_func_return [$];
    // // virtual class BitsToByteArray 
    // // #(parameter ARRAY_LENGTH = MATRIX_WIDTH,
    // // parameter BYTE_WIDTH = BYTE_WIDTH);
    // //     static function byte_array_func_return bits_to_byte_array
    // //     (input [ARRAY_LENGTH * BYTE_WIDTH - 1 : 0] bit_vector);
    // //     BYTE_TYPE byte_array [0 : ARRAY_LENGTH - 1]
    // //     integer i;
    // //     for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
    // //         byte_array[i] = bit_vector[i*BYTE_WIDTH +: BYTE_WIDTH];
    // //     end
    // //     return byte_array;
    // //     endfunction
    // // endclass


endpackage: vTPU_pkg

import vTPU_pkg::*;