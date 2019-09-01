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
//`include "./include/apu_macros.sv"

//import apu_core_package::*;
import riscv_defines::*;

module riscv_ex_stage_fpga
(
  input  logic        clk,
  input  logic        rst_n,

  // ALU signals from ID stage
  input  logic [ALU_OP_WIDTH-1:0] alu_operator_i,
  input  logic [31:0] alu_operand_a_i,
  input  logic [31:0] alu_operand_b_i,
  input  logic [31:0] alu_operand_c_i,
  input  logic        alu_en_i,

  input  logic [ 1:0] imm_vec_ext_i,


  // Multiplier signals
  input  logic [ 2:0] mult_operator_i,
  input  logic [31:0] mult_operand_a_i,
  input  logic [31:0] mult_operand_b_i,
  input  logic [31:0] mult_operand_c_i,
  input  logic        mult_en_i,

  input  logic [ 1:0] mult_signed_mode_i,
  input  logic [ 4:0] mult_imm_i,

  output logic        mult_multicycle_o,

  // input from ID stage
  input  logic        branch_in_ex_i,
  input  logic [5:0]  regfile_alu_waddr_i,
  input  logic        regfile_alu_we_i,

  // directly passed through to WB stage, not used in EX
  input  logic        regfile_we_i,
  input  logic [5:0]  regfile_waddr_i,

  // CSR access
  input  logic        csr_access_i,
  input  logic [31:0] csr_rdata_i,

  ///////////////through to MEM stage, add by BertChen, 2018.6.2
  input  logic         data_we_ex_i,         // write enable                      -> from id stage
  input  logic [1:0]   data_type_ex_i,       // Data type word, halfword, byte    -> from id stage
  input  logic [31:0]  data_wdata_ex_i,      // data to write to memory           -> from id stage
  input  logic [1:0]   data_reg_offset_ex_i, // offset inside register for stores -> from id stage
  input  logic         data_sign_ext_ex_i,   // sign extension                    -> from id stage
  input  logic         data_req_ex_i,        // data request                      -> from id stage
  //////////////

  // Output of EX stage pipeline
  output logic [31:0] regfile_alu_wdata_mem_o,
  output logic        regfile_alu_we_mem_o, 
  output logic [5:0]  regfile_alu_waddr_mem_o,
     
  output logic [5:0]  regfile_waddr_mem_o,
  output logic        regfile_we_mem_o,

  output logic [31:0] data_addr_mem_o,
  output logic        data_we_mem_o,         // write enable                      -> to LSU
  output logic [1:0]  data_type_mem_o,       // Data type word, halfword, byte    -> to LSU
  output logic [31:0] data_wdata_mem_o,      // data to write to memory           -> to LSU
  output logic [1:0]  data_reg_offset_mem_o, // offset inside register for stores -> to LSU
  output logic        data_sign_ext_mem_o,   // sign extension                    -> to LSU
  output logic        data_req_mem_o,        // data request                      -> to LSU

  // Forwarding ports : to ID stage
  output logic  [5:0] regfile_alu_waddr_fw_o,
  output logic        regfile_alu_we_fw_o,
  output logic [31:0] regfile_alu_wdata_fw_o,    // forward to RF and ID/EX pipe, ALU & MUL

  // To IF: Jump and branch target and decision
  output logic [31:0] jump_target_o,
  output logic        branch_decision_o,

  // Stall Control

  output logic        ex_ready_o,   // EX stage ready for new data
  output logic        ex_valid_o,   // EX stage gets new data
  input  logic        mem_ready_i,  // MEM stage ready for new data
  input  logic        wb_ready_i,
  input  logic        lsu_successive_stall_i,
  input  logic        load_wfw_stall_i
);

  logic [31:0]    alu_result;
  logic [31:0]    div_result;
  logic [31:0]    mult_result;
  logic           alu_cmp_result;

  logic           alu_ready;
  logic           mult_ready;
  logic           div_ready; 

  logic           div_en;

  assign div_en = (alu_operator_i == ALU_DIV) || (alu_operator_i == ALU_REM) || (alu_operator_i == ALU_DIVU) || (alu_operator_i == ALU_REMU);

  riscv_alu_basic alu_basic
  (
    .clk                 ( clk             ),
    .rst_n               ( rst_n           ),

    .operator_i          ( alu_operator_i  ),
    .operand_a_i         ( alu_operand_a_i ),
    .operand_b_i         ( alu_operand_b_i ),
    .operand_c_i         ( alu_operand_c_i ),

    .vector_mode_i       ( VEC_MODE32  ),
    .bmask_a_i           ( '0       ),
    .bmask_b_i           ( '0       ),
    .imm_vec_ext_i       ( imm_vec_ext_i   ),

    .result_o            ( alu_result      ),
    .comparison_result_o ( alu_cmp_result  ),

    .ready_o             ( alu_ready       ),
    .ex_ready_i          ( ex_ready_o      )
  );


riscv_div_fpga div_fpga 
(
    .clk                 ( clk             ),
    .rst_n               ( rst_n           ),

    .div_en              ( div_en&alu_en_i ),
    .operator_i          ( alu_operator_i  ),
    .operand_a_i         ( alu_operand_a_i ),
    .operand_b_i         ( alu_operand_b_i ),

    .result_o            ( div_result      ),

    .ready_o             ( div_ready       ),
    .ex_ready_i          ( ex_ready_o      )
);

riscv_mult_fpga mult_fpga
(
    .clk             ( clk                  ),
    .rst_n           ( rst_n                ),

    .enable_i        ( mult_en_i            ),
    .operator_i      ( mult_operator_i      ),

    .short_subword_i ( '0                   ),
    .short_signed_i  ( mult_signed_mode_i   ),

    .op_a_i          ( mult_operand_a_i     ),
    .op_b_i          ( mult_operand_b_i     ),
    .op_c_i          ( mult_operand_c_i     ),
    .imm_i           ( mult_imm_i           ),

    .dot_op_a_i      ( '0                   ),
    .dot_op_b_i      ( '0                   ),
    .dot_op_c_i      ( '0                   ),
    .dot_signed_i    ( '0                   ),

    .result_o        ( mult_result          ),

    .multicycle_o    ( mult_multicycle_o    ),
    .ready_o         ( mult_ready           ),
    .ex_ready_i      ( ex_ready_o           )
  );

  ///////////////////////////////////////
    // EX/MEM Pipeline Register           //
    ///////////////////////////////////////
    always_ff @(posedge clk, negedge rst_n)
    begin : EX_MEM_Pipeline_Register
      if (~rst_n)
      begin
        regfile_waddr_mem_o  <= '0;
        regfile_we_mem_o     <= 1'b0;
        data_req_mem_o       <= 1'b0;
        data_we_mem_o        <= 1'b0;
        data_type_mem_o      <= '0;
        data_wdata_mem_o     <= '0;
        data_reg_offset_mem_o<= '0;
        data_sign_ext_mem_o  <= '0;
        data_addr_mem_o       <= '0;
        regfile_alu_we_mem_o <= 1'b0; 
        regfile_alu_waddr_mem_o <= '0;
        regfile_alu_wdata_mem_o <= '0;
      end
      else begin
        if (ex_valid_o) 
        begin
          //for lsu access       
          if(wb_ready_i | ((~lsu_successive_stall_i)&data_req_ex_i)) begin    
            data_req_mem_o       <=   data_req_ex_i;          // data request
            data_we_mem_o        <=   data_we_ex_i;         // write enable                      
            data_type_mem_o      <=   data_type_ex_i;       // Data type word, halfword, byte    
            data_wdata_mem_o     <=   data_wdata_ex_i;      // data to write to memory           
            data_reg_offset_mem_o<=   data_reg_offset_ex_i; // offset inside register for stores 
            data_sign_ext_mem_o  <=   data_sign_ext_ex_i;   // sign extension                                                  
            data_addr_mem_o      <=   alu_result;
  
            regfile_waddr_mem_o  <=   regfile_waddr_i;
            regfile_we_mem_o     <=   regfile_we_i;
          end
          //for result wb
          regfile_alu_we_mem_o      <= regfile_alu_we_i ;
          regfile_alu_waddr_mem_o   <= regfile_alu_waddr_i;
          if (alu_en_i&~div_en)
           regfile_alu_wdata_mem_o  <= alu_result;
          if (alu_en_i&div_en)
            regfile_alu_wdata_mem_o <= div_result;
          if (mult_en_i)
            regfile_alu_wdata_mem_o <= mult_result;
          if (csr_access_i)
            regfile_alu_wdata_mem_o <= csr_rdata_i;
          /////////////////////////////////////////////////
        end else  begin
          if (mem_ready_i) begin
            // we are ready for a new instruction, but there is none available,
            // so we just flush the current one out of the pipe
            regfile_alu_we_mem_o <= 1'b0;
          end
          if(wb_ready_i) begin
            regfile_we_mem_o     <= 1'b0;
            data_req_mem_o       <= 1'b0;
          end
        end
      end
    end
  
    ///////////////////////////////////////////////////////////
    //ALU ForWard
    always_comb
    begin
      regfile_alu_wdata_fw_o = '0;
      regfile_alu_waddr_fw_o = '0;
      regfile_alu_we_fw_o    = '0;
  
      regfile_alu_we_fw_o      = regfile_alu_we_i ;
      regfile_alu_waddr_fw_o   = regfile_alu_waddr_i;
      if (alu_en_i&~div_en)
        regfile_alu_wdata_fw_o = alu_result;
      if (alu_en_i&div_en)
        regfile_alu_wdata_fw_o = div_result;
      if (mult_en_i)
        regfile_alu_wdata_fw_o = mult_result;
      if (csr_access_i)
        regfile_alu_wdata_fw_o = csr_rdata_i;
  
    end
  
    // branch handling
    assign branch_decision_o = alu_cmp_result;
    assign jump_target_o     = alu_operand_c_i;
    //////////////////////////////////////////////////////////
  
    // As valid always goes to the right and ready to the left, and we are able
    // to finish branches without going to the WB stage, ex_valid does not
    // depend on ex_ready.
    // successive lsu happen, but lsu is not ready, it need to stall ex stage.
    assign ex_ready_o =  (( alu_ready & mult_ready&div_ready
                         & mem_ready_i ) | (branch_in_ex_i) ) & ~load_wfw_stall_i &~(lsu_successive_stall_i&~wb_ready_i);
    assign ex_valid_o = ( alu_en_i | mult_en_i | csr_access_i )
                         & (alu_ready & mult_ready &div_ready& mem_ready_i) & ~load_wfw_stall_i &~(lsu_successive_stall_i&~wb_ready_i) ;
  
  endmodule
