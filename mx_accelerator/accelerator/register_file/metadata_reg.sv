/*
Identical to Tile registers, except bit widths
*/

module metadata_reg
import vTPU_pack::*;
(
    input clk,
    input rst_n,
    input write_req,
    input read_req,
    input [1 : 0] write_mode, // To identify to treat the operation as treg, ureg, or vreg
    input [1 : 0] read_mode,
    input [$clog2(NUM_REGS) - 1 : 0] write_address,
    input [1 : 0] write_data, // Assuming 8-bit bus
    input [$clog2(NUM_REGS)-1 : 0] read_address,

    output logic write_busy,
    output logic write_done,
    output logic [1:0] read_data,
    output logic row_last, // To identify last element of a row
    output logic reg_last, // To identify last element of the register (When reg_last and row_last are one means data transfer is complete)
);

// infer as blockRAM
(* ram_style = "block" *)
logic [1 : 0] reg_ram [0 : NUM_REG_ROWS * NUM_META_REG_COLUMNS - 1][0 : NUM_REGS-1];

logic [$clog2(NUM_REG_ROWS) : 0] reg_write_row_counter, reg_read_row_counter;
logic [$clog2(NUM_META_REG_COLUMNS) : 0] reg_write_column_counter, reg_read_column_counter;
logic [$clog2(NUM_REGS) - 1 : 0] write_address_intm, read_address_intm;
logic [2 : 0] burst_read_counter, burst_write_counter;

initial begin
    write_busy  <=  0;
    read_data   <= '0;
    row_last    <=  0;
    reg_last    <=  0;
    write_done <= 0;
    reg_write_row_counter <= 0;
    reg_read_row_counter <= 0;
    reg_write_column_counter <= 0;
    reg_read_column_counter <= 0;
    burst_read_counter <= 0;
    burst_write_counter <= 0;
end

always_comb begin
    write_address_intm = write_address;
    read_address_intm = read_address;
end

always_ff@(posedge clk) begin
    if(rst_n == 1'b0) begin
        // Abort current operations
        write_busy <= 1'b0;
        read_data <= '0;
        row_last <= 0;
        reg_last = '0;
        reg_write_row_counter <= 0;
        reg_read_row_counter <= 0;
        reg_write_column_counter <= 0;
        reg_read_column_counter <= 0;
        write_done <= 0;
        burst_read_counter <= 0;
        burst_write_counter <= 0;
    end

    else begin
        // Write Request, then start accepting data
        if(write_req == 1'b1 && write_done == 0) begin
            write_busy <= 1'b1;
            reg_ram[write_address_intm + burst_write_counter][reg_write_row_counter*64 + reg_write_column_counter] <= write_data;
            reg_write_column_counter <= treg_write_column_counter + 1;

            if((reg_write_column_counter + 1) > TREG_COLUMN_WIDTH/8) begin
                reg_write_column_counter <= 0;
                reg_write_row_counter <= reg_write_row_counter + 1;

                if(reg_write_row_counter + 1 > 16) begin

                    case (write_mode)
                        // treg
                        0: 
                            write_done <= 1;
                        // ureg
                        1:
                            burst_write_counter <= burst_write_counter + 1;
                            if(burst_write_counter + 1  == 2) begin
                                write_done <= 1;
                            end

                        // vreg    
                        2:
                            burst_write_counter <= burst_write_counter + 1;
                            if(burst_write_counter + 1  == 4) begin
                                write_done <= 1;
                            end

                    endcase

                    reg_write_row_counter <= 0;
                    reg_write_column_counter <= 0;
                end
            end
        end

        else begin
            write_busy <= 1'b0;
            write_done <= 0;
            burst_write_counter <= 0;
        end

        if(read_req == 1'b1 && reg_last == 0) begin
            row_last <= 0;
            read_data <= reg_ram[read_address_intm + burst_read_counter][reg_read_row_counter*64 + reg_read_column_counter];
            reg_read_column_counter <= reg_read_column_counter + 1;

            if((reg_read_column_counter + 1) > TREG_COLUMN_WIDTH/8) begin
                row_last <= 1;
                reg_read_column_counter <= 0;
                reg_read_row_counter <= reg_read_row_counter + 1;

                if(reg_read_row_counter + 1 > 16) begin

                    case (read_mode)
                        // treg
                        0: 
                            reg_last <= 1;
                        // ureg
                        1: 
                            burst_read_counter <= burst_read_counter + 1;
                            if(burst_read_counter + 1  == 2) begin
                                reg_last <= 1;
                            end

                        // vreg    
                        2: 
                            burst_read_counter <= burst_read_counter + 1;
                            if(burst_read_counter + 1  == 4) begin
                                reg_last <= 1;
                            end

                    endcase

                    reg_read_row_counter <= 0;
                    reg_read_column_counter <= 0;
                end
            end
        end

        else begin
            row_last <= 0;
            reg_last <= 0;
            burst_read_counter <= 0;
        end  
    end
end
endmodule