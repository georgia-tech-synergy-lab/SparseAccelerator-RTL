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
module fifo 
import vTPU_pack:: *;
#(
    parameter FIFO_WIDTH = 8,
    parameter FIFO_DEPTH = 32
) 
(
    input logic clk,
    input logic rst,
    input logic [FIFO_WIDTH-1 : 0] in,
    input logic write_en,

    output logic [FIFO_WIDTH-1 : 0] out,
    input logic next_en,

    output logic empty,
    output logic full
);

logic [FIFO_WIDTH - 1 : 0] fifo_data [0 : FIFO_DEPTH - 1] = '{default: '0};
integer SIZE = 0;

assign out = fifo_data[0];

always_ff @(posedge clk) begin
    logic [FIFO_WIDTH-1 : 0] in_v;
    logic write_en_v;
    logic next_en_v;
    logic [FIFO_WIDTH-1 : 0] fifo_data_v [0 : FIFO_DEPTH - 1];
    integer size_v;

    logic empty_v = 1;
    logic full_v = 0;

    input_v = input;
    write_en_v = write_en;
    next_en_v = next_en;
    fifo_data_v = fifo_data;
    size_v = size;

    if(rst == 1) begin
        size_v = 0;
        fifo_data_v = '{default: '0};
        empty_v = 1;
        full_v = 0;
    end

    else begin
        if(next_en_v == 1) begin
            for(integer i =1 ;i<FIFO_DEPTH; i=i + 1) begin
                fifo_data_v[i-1] = fifo_data;
            end

            size_v = size_v - 1;
            full_v = 0;
        end

        if(write_en_v == 1) begin
            fifo_data_v[size_v] = input_v;
            size_v = size_v + 1;
            empty_v = 0;
        end

        case (size_v)
            FIFO_DEPTH: begin
                empty_v = 0;
                full_v = 1;
            end

            0: begin
                empty_v = 1;
                full_v = 0;
            end
            default: begin
                empty_v = empty_v;
                full_v = full_v;
            end
        endcase
    end

    fifo_data = fifo_data_v;
    size = size_v;
    empty = empty_v;
    full = full_v;
end

localparam ADDRESS_WIDTH = $clog2(FIFO_DEPTH);
logic [ADDRESS_WIDTH-1:0] write_ptr_cs = '0;
logic [ADDRESS_WIDTH-1:0] write_ptr_ns;
logic [ADDRESS_WIDTH-1:0] read_ptr_cs = '0;
logic [ADDRESS_WIDTH-1:0] read_ptr_ns;
logic looped_cs = '0;
logic looped_ns;
logic empty_cs = '1;
logic empty_ns;
logic full_cs = '0;
logic full_ns;


dist_ram ram_i #(.DATA_WIDTH(FIFO_WIDTH), .DATA_DEPTH(FIFO_DEPTH), .ADDRESS_WIDTH(ADDRESS_WIDTH))
(
    .clk(clk),
    .in_addr(write_ptr_cs),
    .in(in),
    .write_en(write_en),
    .out_addr(read_ptr_cs),
    .out(out)
);

assign empty = empty_cs;
assign full = full_cs;


always_comb begin
    logic [ADDRESS_WIDTH-1:0] write_ptr_v;
    logic [ADDRESS_WIDTH-1:0] read_ptr_v;
    logic looped_v;
    logic empty_v;
    logic full_v;
    logic write_en_v;
    logic next_en_v;

    write_ptr_v = write_ptr_cs;
    read_ptr_v  = read_ptr_cs;
    looped_v    = looped_cs;
    empty_v     = empty_cs;
    full_v      = full_cs;
    write_en_v  = write_en;
    next_en_v   = next_en;

    if(next_en_v == 1 && (write_ptr_v != read_ptr_v || looped_v == 1)) begin
        if(read_ptr_v == FIFO_DEPTH - 1) begin
            read_ptr_v = 0;
            looped_v = 0;
        end

        else begin
            read_ptr_v = read_ptr_v + 1;
        end
    end

    if(write_en_v == 1 && (write_ptr_v != read_ptr_v || looped_v == 0)) begin
        if(write_ptr_v == FIFO_DEPTH - 1) begin
            write_ptr_v = 0;
            looped_v = 1;
        end

        else begin
            write_ptr_v = write_ptr_v + 1;
        end
    end

if (write_ptr_v == read_ptr_v) begin
    if looped_v == 1 begin
        empty_v = empty_v;
        full_v  = 1;
    end
    else begin
        empty_v = 1;
        full_v  = full_v;
    end;
end

else begin
    empty_v = 0;
    full_v  = 0;
end


write_ptr_ns    = write_ptr_v;
read_ptr_ns     = read_ptr_v;
looped_ns       = looped_v;
empty_ns        = empty_v;
full_ns         = full_v;
end

always_ff @(posedge clk) begin
    if(rst == 1) begin
        write_ptr_cs <= '0;
        read_ptr_cs  <= '0;
        looped_cs    <= 1'b0;
        empty_cs     <= 1'b1;
        full_cs      <= 1'b0;
    end

    else begin
        write_ptr_cs <= write_ptr_ns;
        read_ptr_cs  <= read_ptr_ns;
        looped_cs    <= looped_ns;
        empty_cs     <= empty_ns;
        full_cs      <= full_ns;
    end

end
    
endmodule