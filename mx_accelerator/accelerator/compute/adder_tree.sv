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
`include "vTPU_pkg.sv"
// `include "bfp32_adder.sv"
module adder_tree 
// import vTPU_pkg::*;
#(
  parameter STAGES_NUM = $clog2(BETA),
  parameter INPUTS_NUM_INT = 2 ** STAGES_NUM
)(
  input clk,
  input rst_n,
  input logic [BETA-1:0][ADD_DATAWIDTH-1:0] idata,
  output logic [ADD_DATAWIDTH-1:0] odata
);

logic [STAGES_NUM:0][INPUTS_NUM_INT-1:0][ADD_DATAWIDTH-1:0] data;

// generating tree
genvar stage, adder;
generate
  for( stage = 0; stage <= STAGES_NUM; stage++ ) begin: stage_gen

    localparam ST_OUT_NUM = INPUTS_NUM_INT >> stage;

    if( stage == '0 ) begin
      // stege 0 is just module inputs
      for( adder = 0; adder < ST_OUT_NUM; adder++ ) begin: inputs_gen

        always_comb begin
          if( adder < BETA ) begin
            data[stage][adder] <= idata[adder];
          end else begin
            data[stage][adder] <= '0;
          end
        end // always_comb

      end // for
    end else begin
      // all other stages hold adders outputs
      for( adder = 0; adder < ST_OUT_NUM; adder++ ) begin: adder_gen
          bfp32_adder adder_stage (
            .A(data[stage-1][adder*2]),
            .B(data[stage-1][adder*2+1]),
            .O(data[stage][adder])
          ); 
      end // for
    end // if stage
  end // for
endgenerate

assign odata = data[STAGES_NUM][0];
  
endmodule