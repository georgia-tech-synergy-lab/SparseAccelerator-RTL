`timescale 1ns/1ps

    // Signals
module TB_UNIFIED_BUFFER;
import vTPU_pkg::*;

    // Parameters
    localparam integer MATRIX_WIDTH = 14;
    localparam integer TILE_WIDTH = 10;

    // Signals
    logic clk = 0;
    logic rst = 0;
    logic enable = 1;
    BUFFER_ADDRESS_TYPE master_address = 0;
    logic master_en = 0;
    logic master_write_en[0 : MATRIX_WIDTH - 1] = '{default : '0};
    BYTE_TYPE master_write_port [0 : MATRIX_WIDTH - 1] = '{default : '0};
    BYTE_TYPE master_read_port [0 : MATRIX_WIDTH - 1];
    BUFFER_ADDRESS_TYPE address0 = 0;
    logic en0 = 0;
    BYTE_TYPE write_port0 [0 : MATRIX_WIDTH - 1] = '{default : '0};
    BYTE_TYPE read_port0 [0 : MATRIX_WIDTH - 1];
    BUFFER_ADDRESS_TYPE address1 = 0;
    logic en1 = 0;
    logic write_en1 = 0;
    BYTE_TYPE write_port1 [0 : MATRIX_WIDTH - 1];
    BYTE_TYPE read_port1 [0 : MATRIX_WIDTH - 1];

    // Instantiate DUT
    unified_buffer #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .TILE_WIDTH(TILE_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .master_address(address0),
        .master_en(master_en),
        .master_write_en(master_write_en),
        .master_write_port(master_write_port),
        .master_read_port(master_read_port),
        .address0(address0),
        .en0(en0),
        .read_port0(read_port0),
        .address1(address1),
        .en1(en1),
        .write_en1(write_en1),
        .write_port1(write_port1)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        // Reset
        rst = 1;
        #10;
        rst = 0;

        // Test write and read through port0
        for (integer i = 0; i < TILE_WIDTH; i = i + 1) begin
            address0 = i;
            address1 = i;
            en1 = 1;
            en0 = 1;
            write_en1 = 1;
            for (integer j = 0; j < MATRIX_WIDTH; j = j + 1) begin
                $display("Writing in TB\n");
                write_port1[j] = i*j;
            end
            
             for (integer j = 0; j < MATRIX_WIDTH; j = j + 1) begin
                $display("Writing value = %d\n", write_port1[j]);
            end
            #10;
            en1 = 1;
            en0 = 1;
            write_en1 = 0;
            #10;
            #10;
            #10;
            for (integer j = 0; j < MATRIX_WIDTH; j = j + 1) begin
                if (read_port0[j] != i*j) begin
                    $display("%d Error reading memory through port0!", read_port0[j]);
                    $stop;
                end
            end
        end

        $display("Test was successful!");
        $finish;
    end

endmodule