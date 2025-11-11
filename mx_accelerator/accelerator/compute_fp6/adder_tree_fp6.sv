//`include "vTPU_pkg_fp6.sv"
module adder_tree_fp6 
// import vTPU_pkg_fp6::*;
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

        
            fp6_adder adder_stage (
              .A(data[stage-1][adder*2]),
              .B(data[stage-1][adder*2+1]),
              .O(data[stage][adder])
            ); 
          end
        end // always

      end // for
endgenerate

assign odata = data[STAGES_NUM][0];
  
endmodule