module drain_reader
import vTPU_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic start_compute,

    output logic fifo_non_empty,

    input logic [ALPHA*ADD_DATAWIDTH-1:0] acc_out [0 : Y_SCALED-1],
    output logic [7:0] output_data
    input logic data_req,
    output logic data_valid,
    output logic transfer_complete
);

logic start_counter, stop_counter;
integer count;
always_ff @(posedge clk) begin
    if(rst_n ==0) begin
        count <= 0;
    end

    else begin
        if(start_counter == 1) begin
            count <= count + 1;
        end

        else if(start_counter ==0) begin
            count <= 0;
        end
    end
    
end

logic [ADD_DATAWIDTH*ALPHA-1 : 0] acc_data_out [0 : Y_SCALED - 1];
logic acc_write_valid [0 : Y_SCALED - 1];
logic acc_read_valid [0 : Y_SCALED - 1];
logic fifo_empty [0 : Y_SCALED - 1];
logic fifo_full [0 : Y_SCALED - 1];

assign fifo_non_empty = ~fifo_empty[0];
genvar i;
generate;

    for(i = 0; i < Y_SCALED; i = i + 1) begin

        fifo fifo_inst #(.FIFO_WIDTH(ALPHA*ADD_DATAWIDTH), .FIFO_DEPTH(Y_SCALED))
        (
            .clk(clk),
            .rst(rst_n),
            .in(acc_out[i]),
            .write_en(acc_write_valid[i]),
            .out(acc_data_out[i]),
            .next_en(read_valid[i]),
            .empty(fifo_empty[i]),
            .full(fifo_full[i])
        );
    end
endgenerate

logic start, done;
logic fifo_valid_pattern [0 : Y_SCALED - 1];
systolic_movement_pattern_generator #(
        .X(X_PARAM),
        .Y(Y_PARAM)
    ) pattern_generator_inst (
        .clk(clk),
        .start(start),
        .rst_n(rst_n),
        .done(done),
        .pattern(fifo_valid_pattern)
    );

logic start_compute_intm;
always_ff @(posedge clk) begin
    if(rst_n == 0) begin


    end

    else begin
        if(start_compute == 1) begin
            start_compute_intm <= start_compute;
        end

        if(start_compute_intm == 1) begin
             start_counter <= 1;

             if(count == X_SCALED) begin
                start_counter <= 0;
                data_load_start <= 1;
                start_compute_intm <= 0;
             end
        end

        else begin
            data_load_start <= 0;
        end
    end
end

always_ff @(posedge clk) begin
    if(data_load_start == 1) begin
        start_loading <= 1;
        start <= 1;
        fifo_valid <= fifo_valid_pattern;
    end

    else begin
        fifo_valid <= 0;
        start_loading <= 0;
        start <= 0;
    end

    if(start_loading == 1) begin
        start <= 0;
        fifo_valid <= fifo_valid_pattern;
        if(done == 1) begin
            start_loading <= 0;
        end
    end
end


integer drain_count;
integer column_count [0 : Y_SCALED - 1];
logic [ALPHA*ADD_DATAWIDTH-1:0] stage0_data;
logic [7:0] stage1_data;
logic stage0_ready, stage1_ready;
logic last_transfer;
// Stage 0
always_ff @(posedge clk) begin
    if(~fifo_empty[drain_count] && data_req == 1 
        && column_count[drain_count] <= X_SCALED && last_transfer == 0) begin

        if(stage1_ready == 1) begin
            stage0_data <= acc_data_out[drain_count];
            stage0_ready <= 1;
            for(integer i = 0; i < Y_SCALED; i = i +1) begin
                if(i == drain_count)
                    read_valid[drain_count] <= 1;
                else
                    read_valid[drain_count] <= 0;
            end
            drain_count <= (drain_count + 1) % Y_SCALED;
            column_count[drain_count] <= column_count[drain_count] + 1;
            if(drain_count == Y_SCALED - 1 && column_count[drain_count] + 1 == X_SCALED)
                last_transfer <= 1;
            
            else
                last_transfer <= 0;
        end

        else begin
            read_valid <= '0;
            stage0_ready <= 0;
            last_transfer <= 0;
        end
    end

    else begin
        if(data_req == 1) begin
            drain_count <= (drain_count + 1) % Y_SCALED;
            if(column_count[Y_SCALED] >  X_SCALED)
                last_transfer <= 1;
        end

        else begin
            drain_count <= 0;
            stage0_ready <= 0;
            last_transfer <= 0;
        end
    end
end

// Stage 1
integer last_datum;
logic stop_data;
always_ff @(posedge clk) begin
    if(last_datum < ALPHA*2)
        stage1_ready <= 1;
    else
        stage1_ready <= 0;

    if(stage0_ready == 1 && transfer_complete == 0) begin
        stage1_ready <= 0;
        output_data <= stage0_data[last_datum +: 8];
        last_datum <= last_datum + 1;
        data_valid <= 1;
        if(last_transfer == 1 && last_datum + 1 == ALPHA*2 - 1)
            transfer_complete <= 1;
    end

    else begin
        transfer_complete <= 0;
        last_datum <= 0;
        stage1_ready <= 1;
    end
end
    
endmodule