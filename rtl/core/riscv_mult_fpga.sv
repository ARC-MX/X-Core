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

module riscv_mult_fpga
(
  input  logic        clk,
  input  logic        rst_n,

  input  logic        enable_i,
  input  logic [ 2:0] operator_i,

  // integer and short multiplier
  input  logic        short_subword_i,
  input  logic [ 1:0] short_signed_i,

  input  logic [31:0] op_a_i,
  input  logic [31:0] op_b_i,
  input  logic [31:0] op_c_i,

  input  logic [ 4:0] imm_i,


  // dot multiplier
  input  logic [ 1:0] dot_signed_i,
  input  logic [31:0] dot_op_a_i,
  input  logic [31:0] dot_op_b_i,
  input  logic [31:0] dot_op_c_i,

  output logic [31:0] result_o,

  output logic        multicycle_o,
  output logic        ready_o,
  input  logic        ex_ready_i
);

parameter DONE=3'h2; //multipler pipeline

enum logic [1:0] {IDLE, WAIT, FINSH} CS, NS;

logic [63:0] result_ss,result_uu,result_su;
logic [2:0]  cnt;
logic  mult_ss_en,mult_su_en,mult_uu_en = 1'b0;
/*
assign result_ss = $signed({{32{op_a_i[31]}}, op_a_i}) * $signed({{32{op_b_i[31]}}, op_b_i};
assign result_su = $signed({{32{op_a_i[31]}}, op_a_i}) * {32'b0, op_b_i};
assign result_uu = {32'b0, op_a_i} * {32'b0, op_b_i};

always_comb begin
  if(operator_i == MUL_MAC32) begin
      result_o = result_ss[31:0];     
  end else if( (operator_i == MUL_H) && (short_signed_i == 2'b11)) begin
      result_o = result_ss[63:32];
  end else if( (operator_i == MUL_H) && (short_signed_i == 2'b01)) begin
      result_o = result_su[63:32];
  end else if( (operator_i == MUL_H) && (short_signed_i == 2'b00)) begin
      result_o = result_uu[63:32];
  end else
      result_o = result_ss[31:0];  
 end
*/

always_comb begin
  mult_ss_en = 1'b0;
  mult_su_en = 1'b0;
  mult_uu_en = 1'b0;
  result_o = result_ss[31:0]; 
  if( (operator_i == MUL_H) && (short_signed_i == 2'b11)) begin
      mult_ss_en = 1'b1;
      result_o = result_ss[63:32];
  end else if( (operator_i == MUL_H) && (short_signed_i == 2'b01)) begin
      mult_su_en = 1'b1;
      result_o = result_su[63:32];
  end else if( (operator_i == MUL_H) && (short_signed_i == 2'b00)) begin
      mult_uu_en = 1'b1;
      result_o = result_uu[63:32];
  end else if(operator_i == MUL_MAC32) begin
      mult_ss_en = 1'b1;
      result_o = result_ss[31:0]; 
  end
 end

mult_gen_ss mult_gen_ss (
  .CLK(clk),         // input wire CLK
  .A  (op_a_i),      // input wire [31 : 0] A
  .B  (op_b_i),      // input wire [31 : 0] B
  .CE (mult_ss_en&enable_i),  // input wire CE
  .P  (result_ss)    // output wire [63 : 0] P
);

mult_gen_su mult_gen_su (
  .CLK(clk),         // input wire CLK
  .A  (op_a_i),      // input wire [31 : 0] A
  .B  (op_b_i),      // input wire [31 : 0] B
  .CE (mult_su_en&enable_i),  // input wire CE
  .P  (result_su)    // output wire [63 : 0] P
);

mult_gen_uu mult_gen_uu (
  .CLK(clk),         // input wire CLK
  .A  (op_a_i),      // input wire [31 : 0] A
  .B  (op_b_i),      // input wire [31 : 0] B
  .CE (mult_uu_en&enable_i),  // input wire CE
  .P  (result_uu)    // output wire [63 : 0] P
);

always_comb begin
  case (CS)
      IDLE: begin
        if(enable_i) begin
          ready_o   =  1'b0;
          NS        =  WAIT;
        end else begin
		  ready_o = 1'b1;
		  NS        =  IDLE;
		end
      end
      WAIT: begin
        if(cnt >= DONE) begin
          ready_o   =  1'b1;
          NS        =  FINSH;
        end else begin
		  ready_o   =  1'b0;
		  NS       =  WAIT;
		end
      end
      FINSH: begin
        if(ex_ready_i) begin
		  ready_o   =  1'b1;
          NS        =  IDLE;
        end else begin
		  ready_o   =  1'b1;
          NS        =  FINSH;
        end
		end
      default: begin 
				NS  =  IDLE;
				ready_o = 1'b1;
			end
  endcase // mulh_CS
end 

always_ff @(posedge clk or negedge rst_n) begin 
  if(~rst_n) begin
     CS  <=  IDLE;
  end else 
     CS  <=  NS;
end


always_ff @(posedge clk or negedge rst_n) begin  
  if(~rst_n) begin
     cnt    <= 0;
  end else if(cnt >= DONE) begin
     cnt    <= 0;
  end else if(~ready_o) begin
     cnt    <= cnt+1'b1;
  end
end

assign multicycle_o = 0;

endmodule
