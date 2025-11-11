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
module systolic_movement_pattern_generator 
#(parameter int X=4, Y=3)
(
    input logic clk,
    input logic start,
    input logic rst_n,
    output logic done,
    output logic pattern [0 : Y-1]
);
    localparam INIT_PATTERN = {1, Y'{0}};

    integer column_sum [0 : Y - 1];
    integer count;
    logic [Y-1:0] pattern_out;

    always_ff @(posedge clk) begin
        if (rst_n == 0) begin
            // Reset the pattern when rst_n is asserted
            pattern_out <= INIT_PATTERN;
            column_sum[0] <= 1;

        end 
        
        else begin
            if (start_intm == 1 || start_intm == 1) begin
                start_intm <= 1;
                if(column_sum[0] <= X) begin
                    pattern_out <= {1'b1, (pattern_out >> 1 )[Y-2 : 0]};
                    column_sum[0] <= column_sum[0] + 1;
                end

                else if(pattern_out > 0 && column_sum[0] == X + 1) begin
                    pattern_out <= {1'b0, (pattern_out >> 1 )[Y-2 : 0]};
                    if((pattern_out >> 1) == 0)
                        done <= 1;
                end

                else if(pattern_out == 0) begin
                    done <= 0;
                    start_intm <= 0;
                    pattern_out <= INIT_PATTERN;
                    column_sum[0] <= 1;

                end
            end
        end
    end
endmodule
