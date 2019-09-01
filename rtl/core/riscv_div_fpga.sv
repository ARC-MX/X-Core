/*
Copyright 2019 PerfXLab (Beijing) Technology Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/    
import riscv_defines::*;

module riscv_div_fpga
(
  input  logic                     clk,
  input  logic                     rst_n,

  input  logic                     div_en,
  input  logic [ALU_OP_WIDTH-1:0]  operator_i,
  input  logic [31:0]              operand_a_i,
  input  logic [31:0]              operand_b_i,

  output logic [31:0]              result_o,

  output logic                     ready_o,
  input  logic                     ex_ready_i
);

logic div_ss_en,div_uu_en;
logic div_ss_ready,div_uu_ready;
logic [63:0] div_ss_result,div_uu_result;
logic div_ss_dout_tvalid;
logic div_uu_dout_tvalid;

always_comb begin
  div_ss_en = 1'b0;
  div_uu_en = 1'b0;
  if( (operator_i == ALU_DIV) || (operator_i == ALU_REM)) begin
      div_ss_en = 1'b1;
  end else if( (operator_i == ALU_DIVU) || (operator_i == ALU_REMU)) begin
      div_uu_en = 1'b1;
  end 
end

div_gen_ss div_gen_ss (
  .aclk                 (clk),                      // input wire aclk
  .aclken               (1'b1),                // input wire aclken
  .aresetn              ((div_ss_en&~div_ss_dout_tvalid) | ~ex_ready_i),                    // input wire aresetn

  .s_axis_divisor_tvalid(div_ss_en),//&div_ss_divisor_tready),                // input wire s_axis_divisor_tvalid
 // .s_axis_divisor_tready(div_ss_divisor_tready),    // output wire s_axis_divisor_tready
  .s_axis_divisor_tdata (operand_a_i),              // input wire [31 : 0] s_axis_divisor_tdata

  .s_axis_dividend_tvalid(div_ss_en),//&div_ss_dividend_tready),      // input wire s_axis_dividend_tvalid
 // .s_axis_dividend_tready(div_ss_dividend_tready),  // output wire s_axis_dividend_tready
  .s_axis_dividend_tdata (operand_b_i),    // input wire [31 : 0] s_axis_dividend_tdata

  .m_axis_dout_tvalid(div_ss_dout_tvalid),          // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata (div_ss_result)                // output wire [63 : 0] m_axis_dout_tdata
);

div_gen_uu div_gen_uu (
  .aclk                 (clk),                                  // input wire aclk
  .aclken               (1'b1),                            // input wire aclken
  .aresetn              ((div_uu_en&~div_uu_dout_tvalid) | ~ex_ready_i),                                // input wire aresetn

  .s_axis_divisor_tvalid(div_uu_en),//&div_uu_divisor_tready),                // input wire s_axis_divisor_tvalid
 // .s_axis_divisor_tready(div_uu_divisor_tready),    // output wire s_axis_divisor_tready
  .s_axis_divisor_tdata (operand_a_i),              // input wire [31 : 0] s_axis_divisor_tdata

  .s_axis_dividend_tvalid(div_uu_en),//&div_uu_dividend_tready),               // input wire s_axis_dividend_tvalid
 // .s_axis_dividend_tready(div_uu_dividend_tready),  // output wire s_axis_dividend_tready
  .s_axis_dividend_tdata (operand_b_i),             // input wire [31 : 0] s_axis_dividend_tdata

  .m_axis_dout_tvalid(div_uu_dout_tvalid),          // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata (div_uu_result)                // output wire [63 : 0] m_axis_dout_tdata
);

always_comb begin
  result_o = div_ss_result[63:32];
  if(operator_i == ALU_DIV) begin
    result_o = div_ss_result[63:32];
  end else if(operator_i == ALU_DIVU) begin
    result_o = div_uu_result[63:32];
  end else if(operator_i == ALU_REM) begin
    result_o = div_ss_result[31:0];
  end else if(operator_i == ALU_REMU) begin
    result_o = div_uu_result[31:0];
  end
end

assign div_ss_ready =  div_ss_dout_tvalid & div_ss_en ;//& div_ss_divisor_tready & div_ss_dividend_tready;
assign div_uu_ready =  div_uu_dout_tvalid & div_uu_en ;//& div_uu_divisor_tready & div_uu_en & div_uu_dividend_tready;
assign ready_o = div_en ? (div_ss_ready||div_uu_ready):1'b1;

endmodule