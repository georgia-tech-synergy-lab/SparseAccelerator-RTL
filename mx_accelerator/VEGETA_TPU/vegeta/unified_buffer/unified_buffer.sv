/**

TODO: Check port reg and wire whatever is required and also overall flow

*/
module unified_buffer 
import vTPU_pkg::*;
#(
    parameter integer MATRIX_WIDTH = 14,
    parameter integer TILE_WIDTH = 4096 // buffer depth
) (
    input logic clk,
    input logic rst,
    input logic enable,

    input BUFFER_ADDRESS_TYPE master_address,
    input logic master_en,
    input logic master_write_en[0:MATRIX_WIDTH-1],
    input BYTE_TYPE master_write_port[0:MATRIX_WIDTH-1],
    output BYTE_TYPE master_read_port[0:MATRIX_WIDTH-1],

    // Port0
    input BUFFER_ADDRESS_TYPE address0,
    input logic en0,
    output BYTE_TYPE read_port0 [0 : MATRIX_WIDTH - 1],

    // Port1
    input BUFFER_ADDRESS_TYPE address1,
    input logic en1,
    input logic write_en1,
    input BYTE_TYPE write_port1[0 : MATRIX_WIDTH -1]
);

BYTE_TYPE read_port0_reg0_cs [0 : MATRIX_WIDTH - 1] = '{default: '0}; // need to initialize this
BYTE_TYPE read_port0_reg0_ns [0 : MATRIX_WIDTH - 1];
BYTE_TYPE read_port0_reg1_cs [0 : MATRIX_WIDTH - 1] = '{default: '0}; // need to intialize this
wire BYTE_TYPE read_port0_reg1_ns [0 : MATRIX_WIDTH - 1];

BYTE_TYPE master_read_port_reg0_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
BYTE_TYPE master_read_port_reg0_ns [0 : MATRIX_WIDTH - 1];
BYTE_TYPE master_read_port_reg1_cs [0 : MATRIX_WIDTH - 1] = '{default: '0};
wire BYTE_TYPE master_read_port_reg1_ns [0 : MATRIX_WIDTH - 1];

wire logic [MATRIX_WIDTH*BYTE_WIDTH -1  : 0] write_port1_bits;
logic [MATRIX_WIDTH*BYTE_WIDTH -1  : 0] read_port0_bits;

wire logic [MATRIX_WIDTH*BYTE_WIDTH -1  : 0] master_write_port_bits;
logic [MATRIX_WIDTH*BYTE_WIDTH -1  : 0] master_read_port_bits;

BUFFER_ADDRESS_TYPE address0_override;
BUFFER_ADDRESS_TYPE address1_override;

logic en0_override;
logic en1_override;

// infer as blockRAM
(* ram_style = "block" *) 
RAM_TYPE ram [0 : TILE_WIDTH - 1];


// initialize
initial begin
//    read_port0_reg0_cs = '{default: '0};
//    read_port0_reg1_cs = '{default: '0};
//    master_read_port_reg0_cs = '{default: '0};
//    master_read_port_reg1_cs = '{default: '0};

    // synthesis translate_off
    // Random values for testing purposes
    ram[0] = ByteArrayToBits #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: byte_array_to_bits('{'h7F, 'h7E, 'h7D, 'h7C, 'h7B, 'h7A, 'h79, 'h78, 'h77, 'h76, 'h75, 'h74, 'h73, 'h72});
    ram[1] = ByteArrayToBits #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: byte_array_to_bits('{'h71, 'h70, 'h6F, 'h6E, 'h6D, 'h6C, 'h6B, 'h6A, 'h69, 'h68, 'h67, 'h66, 'h65, 'h64});

    for(integer i = 2; i < TILE_WIDTH; i++) begin
        ram[i] = 0;
    end
    // synthesis translate_on
end

assign write_port1_bits = ByteArrayToBits #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: byte_array_to_bits(write_port1);
assign master_write_port_bits = ByteArrayToBits #(.ARRAY_LENGTH(MATRIX_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) :: byte_array_to_bits(master_write_port);
assign read_port0_reg1_ns = read_port0_reg0_cs;
assign read_port0 = read_port0_reg1_cs;


assign master_read_port_reg1_ns = master_read_port_reg0_cs;
assign master_read_port = master_read_port_reg1_cs;

always_comb begin

    for(integer i =0; i< MATRIX_WIDTH; i= i + 1) begin
    
        master_read_port_reg0_ns[i] = master_read_port_bits[i*BYTE_WIDTH +: BYTE_WIDTH];
        read_port0_reg0_ns[i] = read_port0_bits[i*BYTE_WIDTH +: BYTE_WIDTH];
    end

end

// Process begins now
always_comb begin
    if(master_en == 1) begin
        en0_override = master_en;
        en1_override = master_en;
        address0_override = master_address;
        address1_override = master_address;
    end

    else begin
        $display("Assigning addresses\n");
        en0_override = en0;
        en1_override = en1;
        address0_override = address0;
        address1_override = address1;
    end
end

always_ff @(posedge clk) begin: PORT_0
    if(en0_override == 1) begin
        //synthesis translate_off
        if (int'($unsigned(address0_override)) < TILE_WIDTH ) begin
        //synthesis translate_on
         for (integer i = 0; i < MATRIX_WIDTH; i = i + 1) begin
          if (master_write_en[i] == 1'b1) begin
            ram[address0_override][i*BYTE_WIDTH +: BYTE_WIDTH] <= master_write_port_bits[i*BYTE_WIDTH +: BYTE_WIDTH];
          end
        end
        read_port0_bits <= ram[address0_override];
        //synthesis translate_off
        end
        //synthesis translate_on
    end
end: PORT_0

always_ff @(posedge clk) begin
if (en1_override == 1'b1) begin
    //synthesis translate_off
    if (int'($unsigned(address1_override)) < TILE_WIDTH ) begin
    //synthesis translate_on
    if (write_en1 == 1'b1) begin
        $display("Writing %d %d \n", address1_override, address1);
        ram[address1_override] <= write_port1_bits;
    end
    master_read_port_bits <= ram[address1_override];
    end
//synthesis translate_off
end
// synthesis translate_on
end

always_ff @(posedge clk) begin
if (rst == 1'b1) begin
    read_port0_reg0_cs <= '{default: '0};
    read_port0_reg1_cs <= '{default: '0};
    master_read_port_reg0_cs <= '{default: '0};
    master_read_port_reg1_cs <= '{default: '0};
end 
else begin
    if (enable == 1'b1) begin
    $display("Out of Reset\n");
    read_port0_reg0_cs <= read_port0_reg0_ns;
    read_port0_reg1_cs <= read_port0_reg1_ns;
    master_read_port_reg0_cs <= master_read_port_reg0_ns;
    master_read_port_reg1_cs <= master_read_port_reg1_ns;
    end
end
end
  
endmodule