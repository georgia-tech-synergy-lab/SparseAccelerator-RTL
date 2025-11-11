// BETA > 1 requires adder tree at the end
// gives final sum

`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module adder_tree 
#(
  parameter BETA,
  parameter ADD_DATAWIDTH
)(
  input logic clk,
  input logic rst_n,
  input logic [BETA-1:0][ADD_DATAWIDTH-1:0] idata,
  
  output logic [ADD_DATAWIDTH-1:0] odata
);

localparam STAGES_NUM = `vegeta_clog2(BETA);
localparam INPUTS_NUM_INT = 2 ** STAGES_NUM;

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
            data[stage][adder] = idata[adder];
          end else begin
            data[stage][adder] = '0;
          end
        end // always_comb

      end // for
    end else begin
      // all other stages hold adders outputs
      for( adder = 0; adder < ST_OUT_NUM; adder++ ) begin: adder_gen
        fp32_adder adder_stage (
          .A(data[stage-1][adder*2]),
          .B(data[stage-1][adder*2+1]),
          .O(data[stage][adder])
        ); 
      end // for
    end // if stage
  end // for
endgenerate

always_ff @( posedge clk or negedge rst_n) begin
  if (~rst_n)
    odata <= '0;
  else
    odata <= data[STAGES_NUM][0];
end
  
endmodule