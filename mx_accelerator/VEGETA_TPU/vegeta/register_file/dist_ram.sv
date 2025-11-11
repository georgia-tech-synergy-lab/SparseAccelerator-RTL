module dist_ram 
import vTPU_pack::*;
#(
    parameter DATA_WIDTH = 8,
    parameter DATA_DEPTH = 32,
    parameter ADDRESS_WIDTH = 5
) 
(
    input logic clk,
    input logic [ADDRESS_WIDTH-1 : 0] in_addr,
    input logic [DATA_WIDTH - 1 : 0] in,
    input logic write_en,
    input logic [ADDRESS_WIDTH-1 :0] out_addr,
    output logic [DATA_WIDTH-1 : 0] out
);

logic [DATA_WIDTH - 1 : 0] ram [0 : DATA_DEPTH - 1];

assign out = ram[out_addr];

always_ff @(posedge clk) begin
    if(write_en == 1) begin
        ram[in_addr] <= in;
    end
end
    
endmodule