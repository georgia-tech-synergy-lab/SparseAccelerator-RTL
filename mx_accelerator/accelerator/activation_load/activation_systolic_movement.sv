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
module act_systolic_movement
import vTPU_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic start_compute,

    // There will be Y_SCALED number of FIFOs to extract data from
    input logic [MUL_DATAWIDTH*M*BETA-1 : 0] fifo_data [0: X_SCALED-1],
    input logic fifo_empty [0 : X_SCALED - 1],
    output logic fifo_valid [0:X_SCALED-1],

    output logic [MUL_DATAWIDTH*M*BETA-1 : 0] acc_in [0 : X_SCALED-1]
);

logic start_compute_intm;
integer systolic_count;
always_ff @(posedge clk) begin
    if(rst_n == 0) begin
        fifo_valid <= '0;
        systolic_count <= 0;
    end

    else begin
        if(start_compute == 1) begin
            start_compute_intm <= 1;
        end
        if(start_compute_intm == 1 && fifo_empty[X_SCALED - 1] == 0) begin
            for(integer i = 0; i <= systolic_count; i = i + 1) begin
                acc_in[i] <= fifo_empty[i] == 0 ? fifo_data[i] : 0;
                fifo_valid[i] <= fifo_empty[i] == 0 ? 1 : 0;
            end

            for(integer j = systolic_count + 1; j < X_SCALED; j = j + 1) begin
                acc_in[j] <= 0;
                fifo_valid[i] <= 0;
            end

            systolic_count <= systolic_count + 1;
        end

        else begin
            start_compute_intm <= 0;
            systolic_count <= 0;
        end
    end   
end
endmodule