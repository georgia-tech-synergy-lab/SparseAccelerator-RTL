module WEIGHT_BUFFER 
#(parameter MATRIX_WIDTH = 14, TILE_WIDTH = 32768) 
(
    input logic clk,
    input logic rst,
    input logic enable,
    
    // Port0
    input weight_address_type address0,
    input logic en0,
    input logic write_en0,
    input BYTE_TYPE write_port0 [0 : MATRIX_WIDTH - 1],
    output wire BYTE_TYPE read_port0 [0 : MATRIX_WIDTH - 1],

    // Port1
    input weight_address_type address1,
    input logic en1,
    input logic write_en1 [0 : MATRIX_WIDTH - 1],
    input BYTE_TYPE write_port1 [0 : MATRIX_WIDTH - 1],
    output wire BYTE_TYPE read_port1 [0 : MATRIX_WIDTH - 1]
);

BYTE_TYPE read_port0_reg0_cs [0 : MATRIX_WIDTH - 1]; // need to initialize this
wire BYTE_TYPE read_port0_reg0_ns [0 : MATRIX_WIDTH - 1];
BYTE_TYPE read_port0_reg1_cs [0 : MATRIX_WIDTH - 1]; // need to intialize this
wire BYTE_TYPE read_port0_reg1_ns [0 : MATRIX_WIDTH - 1];

BYTE_TYPE read_port1_reg0_cs [0 : MATRIX_WIDTH - 1]; // need to initialize this
wire BYTE_TYPE read_port1_reg0_ns [0 : MATRIX_WIDTH - 1];
BYTE_TYPE read_port1_reg1_cs [0 : MATRIX_WIDTH - 1]; // need to intialize this
wire BYTE_TYPE read_port1_reg1_ns [0 : MATRIX_WIDTH - 1];

logic [MATRIX_WIDTH*BYTE_WIDTH -1  : 0] write_port0_bits;
logic [MATRIX_WIDTH*BYTE_WIDTH -1  : 0] write_port1_bits;
logic [MATRIX_WIDTH*BYTE_WIDTH -1  : 0] read_port0_bits;
logic [MATRIX_WIDTH*BYTE_WIDTH -1  : 0] read_port1_bits;

// infer as blockRAM
(* ram_style = "block" *) 
RAM_TYPE ram [0 : TILE_WIDTH - 1];

initial begin
    read_port0_reg0_cs = 0;
    read_port0_reg1_cs = 0;
    master_read_port_reg0_cs = 0;
    master_read_port_reg1_cs = 0;

    // synthesis translate_off
    // Random values for testing purposes
    ram[0] = ByteArrayToBits #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: byte_array_to_bits('{'h80, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00});
    ram[1] = ByteArrayToBits #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: byte_array_to_bits('{'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00});

    for(integer i = 2; i < TILE_WIDTH; i++) begin
        ram[i] = 0;
    end
    // synthesis translate_on
end

assign write_port0_bits = ByteArrayToBits #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: byte_array_to_bits(write_port0);
assign write_port1_bits = ByteArrayToBits #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: byte_array_to_bits(write_port1);

assign read_port0_reg0_ns = BitsToByteArray #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: bits_to_byte_array(read_port0_bits);
assign read_port1_reg0_ns = BitsToByteArray #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: bits_to_byte_array(read_port1_bits);

assign read_port0_reg1_ns = read_port0_reg0_cs;
assign read_port1_reg1_ns = read_port1_reg0_cs;
assign read_port0 = read_port0_reg1_cs;
assign read_port1 = read_port1_reg1_cs;

always_ff @(posedge clk) begin: PORT_0
    if(en0 == 1) begin
        //synthesis translate_off
        if (int'($unsigned(address0)) < TILE_WIDTH ) begin
        //synthesis translate_on
            if(write_en0 == 1) begin
                ram[address0] <= write_port0_bits;
            end
        read_port0_bits <= ram[address0];
        //synthesis translate_off
        end
        //synthesis translate_on
    end
end: PORT_0

always_ff @(posedge clk) begin: PORT_1
    if(en1 == 1) begin
        //synthesis translate_off
        if (int'($unsigned(address1)) < TILE_WIDTH ) begin
        //synthesis translate_on
            for(integer i = 0; i<MATRIX_WIDTH; i= i + 1) begin
                if(write_en1[i] == 1) begin
                    ram[address1][i*BYTE_WIDTH +: BYTE_WIDTH] <= write_port1_bits[i*BYTE_WIDTH +: BYTE_WIDTH];
            end
        read_port1_bits <= ram[address1];
        //synthesis translate_off
        end
        //synthesis translate_on
    end
end: PORT_1

always_ff @(posedge clk) begin: SEQ_LOGIC
if (rst == 1'b1) begin
    read_port0_reg0_cs <= '{default: '0};
    read_port0_reg1_cs <= '{default: '0};
    read_port1_reg0_cs <= '{default: '0};
    read_port1_reg1_cs <= '{default: '0};
end 
else begin
    if (enable == 1'b1) begin
    read_port0_reg0_cs <= read_port0_reg0_ns;
    read_port0_reg1_cs <= read_port0_reg1_ns;
    read_port1_reg0_cs <= read_port1_reg0_ns;
    read_port1_reg1_cs <= read_port1_reg1_ns;
    end
end
end: SEQ_LOGIC










endmodule