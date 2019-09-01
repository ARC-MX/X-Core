// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License�?); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS�? BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Renzo Andri - andrire@student.ethz.ch                      //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Instruction Decode Stage                                   //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Decode stage of the core. It decodes the instructions      //
//                 and hosts the register file.                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////
// Based on PULP RISCV Core by perfxlab
// RSIC V top module 
// 2018/5/26
/////////////////////////////////////////////////

import riscv_defines::*;
import riscv_package::*;

// Source/Destination register instruction index
`define REG_S1 19:15
`define REG_S2 24:20
`define REG_S4 31:27
`define REG_D  11:07

module riscv_id_stage
#(
  parameter RISCV_SECURE       =  1
)
(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        test_en_i,

    input  logic        fetch_enable_i,
    output logic        ctrl_busy_o,
    output logic        core_ctrl_firstfetch_o,
    output logic        is_decoding_o,

    // Interface to IF stage
    input  logic              instr_valid_i,
    input  logic       [31:0] instr_rdata_i,      // comes from pipeline of IF stage
    output logic              instr_req_o,


    // Jumps and branches
    output logic        branch_in_ex_o,
    input  logic        branch_decision_i,
    output logic [31:0] jump_target_o,
	output logic 		jump_out,
    // IF and ID stage signals
    output logic        clear_instr_valid_o,
    output logic        pc_set_o,
    output logic [2:0]  pc_mux_o,
    output logic [1:0]  exc_pc_mux_o,
    output logic [1:0]  trap_addr_mux_o,          //Change the bit width from 1 bit to 2 bit by **, 2018.5.10

    input  logic [31:0] pc_if_i,
    input  logic [31:0] pc_id_i,

    // Stalls
    output logic        halt_if_o,      // controller requests a halt of the IF stage
    output logic        load_wfw_stall_o,
    output logic        lsu_successive_stall_o,

    output logic        id_ready_o,     // ID stage is ready for the next instruction
    input  logic        ex_ready_i,     // EX stage is ready for the next instruction
    input  logic        wb_ready_i,     // WB stage is ready for the next instruction

    output logic        id_valid_o,     // ID stage is done
    input  logic        ex_valid_i,     // EX stage is done
    input  logic        mem_valid_i,
    input  logic        lsu_ready_mem_i,

    // Pipeline ID/EX
    output logic [31:0] pc_ex_o,

    output logic [31:0] alu_operand_a_ex_o,
    output logic [31:0] alu_operand_b_ex_o,
    output logic [31:0] alu_operand_c_ex_o,
    output logic [ 1:0] imm_vec_ext_ex_o,
    output logic [5:0]  regfile_waddr_ex_o,
    output logic        regfile_we_ex_o,

    output logic [5:0]  regfile_alu_waddr_ex_o,
    output logic        regfile_alu_we_ex_o,

    // ALU
    output logic        alu_en_ex_o,
    output logic [ALU_OP_WIDTH-1:0] alu_operator_ex_o,


    // MUL
    output logic [ 2:0] mult_operator_ex_o,
    output logic [31:0] mult_operand_a_ex_o,
    output logic [31:0] mult_operand_b_ex_o,
    output logic [31:0] mult_operand_c_ex_o,
    output logic        mult_en_ex_o,
    output logic [ 1:0] mult_signed_mode_ex_o,
    output logic [ 4:0] mult_imm_ex_o,

    // CSR ID/EX
    output logic        csr_access_ex_o,
    output logic [1:0]  csr_op_ex_o,
    input  PrivLvl_t    current_priv_lvl_i,
    output logic        csr_irq_sec_o,
    output logic [5:0]  csr_cause_o,
    output logic        csr_save_if_o,
    output logic        csr_save_id_o,
    output logic        csr_restore_mret_id_o,
    output logic        csr_restore_uret_id_o,
    output logic        csr_restore_sret_id_o,           //add by **, 2018.5.10
    output logic        csr_restore_dret_id_o,
    output logic        csr_save_cause_o,
    output logic [31:0] csr_tval_o,                      //add by **, 2018.5.17

    output logic        debug_pc_id_o,  
    output logic        debug_pc_if_o,       
    output logic        debug_irq_cause_en_o,     
    output logic        debug_ebk_cause_en_o,
    output logic        debug_halt_cause_en_o,

    output logic        debug_step_cause_en_o,


    // Interface to load store unit
    output logic        data_req_ex_o,
    output logic        data_we_ex_o,
    output logic [1:0]  data_type_ex_o,
    output logic        data_sign_ext_ex_o,
    output logic [1:0]  data_reg_offset_ex_o,
    //output logic        data_load_event_ex_o,

    output logic        data_misaligned_ex_o,

    input  logic        data_misaligned_i,

    input  logic        data_req_mem_i,

    // Interrupt signals
    input  logic        irq_i,
    input  logic        irq_sec_i,
    input  logic [4:0]  irq_id_i,
    input  logic        m_irq_enable_i,
    input  logic        s_irq_enable_i,
    input  logic        u_irq_enable_i,
    input  logic [31:0] mip_i,
    input  logic [31:0] mie_i,
    input  logic [31:0] csr_mideleg_i,
    output logic        irq_ack_o,
    output logic [4:0]  irq_id_o,
    output logic [5:0]  exc_cause_o,
    output logic        irq_req_happen_o, 
    output logic [31:0] irq_req_event_o,  

    input  logic        lsu_load_err_i,
    input  logic        lsu_store_err_i,

      // from mmu exc, add by **, 2018.5.17
    input  exception_t   mmu_data_exception_i  ,
    input  exception_t   mmu_fetch_exception_i , 

    // Debug Unit Signals
    input  logic [DBG_SETS_W-1:0] dbg_settings_i,
    input  logic        dbg_req_i,
    output logic        dbg_ack_o,
    input  logic        dbg_stall_i,
    output logic        dbg_trap_o,

    input  logic        dbg_reg_rreq_i,
    input  logic [ 5:0] dbg_reg_raddr_i,
    output logic [31:0] dbg_reg_rdata_o,

    input  logic        dbg_reg_wreq_i,
    input  logic [ 5:0] dbg_reg_waddr_i,
    input  logic [31:0] dbg_reg_wdata_i,

    input  logic        dbg_jump_req_i,
    //Debug Unit
    input  logic        debug_mode_i,
    input  logic        debug_ebreakm_i,
    input  logic        debug_ebreaku_i,
    input  logic        debug_ebreaks_i,
    input  logic        debug_halt_new_i,
    input  logic        debug_step_i,
	output logic		cause_clr_o,
    // Forward Signals
    input  logic [5:0]  regfile_waddr_mem_i,
    input  logic        regfile_we_mem_i,

    input  logic [5:0]  regfile_waddr_wb_i,
    input  logic        regfile_we_wb_i,
    input  logic [31:0] regfile_wdata_wb_i, // From wb_stage: selects data from data memory, ex_stage result and sp rdata

    input  logic [5:0]  regfile_alu_waddr_fw_i, //From ex_stage
    input  logic        regfile_alu_we_fw_i,
    input  logic [31:0] regfile_alu_wdata_fw_i,

    input  logic [5:0]  regfile_alu_waddr_mem_i,
    input  logic        regfile_alu_we_mem_i,
    input  logic [31:0] regfile_alu_wdata_mem_i,

    input  logic [5:0]  regfile_alu_waddr_wb_i,
    input  logic        regfile_alu_we_wb_i,   
    input  logic [31:0] regfile_alu_wdata_wb_i,

    // from ALU
    input  logic        mult_multicycle_i,    // when we need multiple cycles in the multiplier and use op c as storage

    // Performance Counters
    output logic        perf_jump_o,          // we are executing a jump instruction
    output logic        perf_jr_stall_o,      // jump-register-hazard
    output logic        perf_ld_stall_o      // load-use-hazard
);

  logic [31:0] instr;

  // Decoder/Controller ID stage internal signals
  logic        deassert_we;

  logic        illegal_insn_dec;
  logic        ebrk_insn;
  logic        mret_insn_dec;
  logic        uret_insn_dec;
  logic        sret_insn_dec;  // add by **, 2018.5.10
  logic        dret_insn_dec;  
  logic        ecall_insn_dec;
  logic        pipe_flush_dec;

  logic        rega_used_dec;
  logic        regb_used_dec;
  logic        regc_used_dec;

  logic        branch_taken_ex;
  logic [1:0]  jump_in_id;
  logic [1:0]  jump_in_dec;

  logic        misaligned_stall;
  logic        jr_stall;
  logic        load_stall;

  logic        instr_multicycle;

  logic        halt_id;
  logic        irq_debug;


  // Immediate decoding and sign extension
  logic [31:0] imm_i_type;
  logic [31:0] imm_iz_type;
  logic [31:0] imm_s_type;
  logic [31:0] imm_sb_type;
  logic [31:0] imm_u_type;
  logic [31:0] imm_uj_type;
  logic [31:0] imm_z_type;
  logic [31:0] imm_s2_type;
  logic [31:0] imm_bi_type;
  logic [31:0] imm_s3_type;
  logic [31:0] imm_vs_type;
  logic [31:0] imm_vu_type;

  logic [31:0] imm_a;       // contains the immediate for operand b
  logic [31:0] imm_b;       // contains the immediate for operand b

  logic [31:0] jump_target;       // calculated jump target (-> EX -> IF)

  // Signals running between controller and exception controller
  logic       irq_req_ctrl, irq_sec_ctrl;
  logic [4:0] irq_id_ctrl;
  logic       irq_enable_ctrl;
  logic       exc_ack, exc_kill;// handshake

  // Register file interface
  logic [5:0]  regfile_addr_ra_id;
  logic [5:0]  regfile_addr_rb_id;
  logic [5:0]  regfile_addr_rc_id;

  logic [5:0]  regfile_waddr_id;
  logic [5:0]  regfile_alu_waddr_id;
  logic        regfile_alu_we_id;

  logic [31:0] regfile_data_ra_id;
  logic [31:0] regfile_data_rb_id;
  logic [31:0] regfile_data_rc_id;

  // ALU Control
  logic        alu_en;
  logic [ALU_OP_WIDTH-1:0] alu_operator;
  logic [2:0]  alu_op_a_mux_sel;
  logic [2:0]  alu_op_b_mux_sel;
  logic [1:0]  alu_op_c_mux_sel;
  logic [1:0]  regc_mux;

  logic [0:0]  imm_a_mux_sel;
  logic [3:0]  imm_b_mux_sel;
  logic [1:0]  jump_target_mux_sel;

  // Multiplier Control
  logic [2:0]  mult_operator;    // multiplication operation selection
  logic        mult_en;          // multiplication is used instead of ALU
  logic        mult_int_en;      // use integer multiplier
  logic [1:0]  mult_signed_mode; // Signed mode multiplication at the output of the controller, and before the pipe registers

  // Register Write Control
  logic        regfile_we_id;
  //logic        regfile_alu_waddr_mux_sel;

  // Data Memory Control
  logic        data_we_id;
  logic [1:0]  data_type_id;
  logic        data_sign_ext_id;
  logic [1:0]  data_reg_offset_id;
  logic        data_req_id;

  // CSR control
  logic        csr_access;
  logic [1:0]  csr_op;
  logic        csr_status;

 // logic        prepost_useincr;

  // Forwarding
  logic [2:0]  operand_a_fw_mux_sel;
  logic [2:0]  operand_b_fw_mux_sel;
  logic [2:0]  operand_c_fw_mux_sel;
  logic [31:0] operand_a_fw_id;
  logic [31:0] operand_b_fw_id;
  logic [31:0] operand_c_fw_id;

  logic [31:0] operand_b, operand_b_vec;

  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;
  logic [31:0] alu_operand_c;

  // Immediates for ID
  logic [0:0]  mult_imm_mux;
  logic [ 1:0] imm_vec_ext_id;
  logic [ 4:0] mult_imm_id;

  // Forwarding detection signals
  logic        reg_d_ex_is_reg_a_id;
  logic        reg_d_ex_is_reg_b_id;
  logic        reg_d_ex_is_reg_c_id;
  logic        reg_d_mem_is_reg_a_id;
  logic        reg_d_mem_is_reg_b_id;
  logic        reg_d_mem_is_reg_c_id;
  logic        reg_d_wb_is_reg_a_id;
  logic        reg_d_wb_is_reg_b_id;
  logic        reg_d_wb_is_reg_c_id;
  logic        reg_d_alu_is_reg_a_id;
  logic        reg_d_alu_is_reg_b_id;
  logic        reg_d_alu_is_reg_c_id;
  logic        reg_d_alu_mem_is_reg_a_id;
  logic        reg_d_alu_mem_is_reg_b_id;
  logic        reg_d_alu_mem_is_reg_c_id;
  logic        reg_d_alu_wb_is_reg_a_id;
  logic        reg_d_alu_wb_is_reg_b_id;
  logic        reg_d_alu_wb_is_reg_c_id;

  assign instr = instr_rdata_i;

  // immediate extraction and sign extension
  assign imm_i_type  = { {20 {instr[31]}}, instr[31:20] };
  assign imm_iz_type = {            20'b0, instr[31:20] };
  assign imm_s_type  = { {20 {instr[31]}}, instr[31:25], instr[11:7] };
  assign imm_sb_type = { {19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
  assign imm_u_type  = { instr[31:12], 12'b0 };
  assign imm_uj_type = { {12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 };

  // immediate for CSR manipulatin (zero extended)
  assign imm_z_type  = { 27'b0, instr[`REG_S1] };

  assign imm_s2_type = { 27'b0, instr[24:20] };
  assign imm_bi_type = { {27{instr[24]}}, instr[24:20] };
  assign imm_s3_type = { 27'b0, instr[29:25] };
  assign imm_vs_type = { {26 {instr[24]}}, instr[24:20], instr[25] };
  assign imm_vu_type = { 26'b0, instr[24:20], instr[25] };

  //---------------------------------------------------------------------------
  // source register selection 
  //---------------------------------------------------------------------------
  assign regfile_addr_ra_id = {1'b0, instr[`REG_S1]};
  assign regfile_addr_rb_id = {1'b0, instr[`REG_S2]};

  // register C mux
  always_comb
  begin
    unique case (regc_mux)
      REGC_ZERO:  regfile_addr_rc_id = '0;
      REGC_RD:    regfile_addr_rc_id = {1'b0, instr[`REG_D]}; 
      REGC_S1:    regfile_addr_rc_id = {1'b0, instr[`REG_S1]};
      default:    regfile_addr_rc_id = '0;
    endcase
  end

  //---------------------------------------------------------------------------
  // destination registers 
  //---------------------------------------------------------------------------
  assign regfile_waddr_id = {1'b0, instr[`REG_D]}; 

  // Second Register Write Address Selection
  assign regfile_alu_waddr_id  = regfile_waddr_id;
  // Forwarding control signals
  assign reg_d_ex_is_reg_a_id     = regfile_we_ex_o & (regfile_waddr_ex_o      == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_ex_is_reg_b_id     = regfile_we_ex_o & (regfile_waddr_ex_o      == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_ex_is_reg_c_id     = regfile_we_ex_o & (regfile_waddr_ex_o      == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_wb_is_reg_a_id     = regfile_we_wb_i & (regfile_waddr_wb_i      == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_wb_is_reg_b_id     = regfile_we_wb_i & (regfile_waddr_wb_i      == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_wb_is_reg_c_id     = regfile_we_wb_i & (regfile_waddr_wb_i      == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_mem_is_reg_a_id    = regfile_we_mem_i& (regfile_waddr_mem_i     == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_mem_is_reg_b_id    = regfile_we_mem_i& (regfile_waddr_mem_i     == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_mem_is_reg_c_id    = regfile_we_mem_i& (regfile_waddr_mem_i     == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_alu_is_reg_a_id    = regfile_alu_we_fw_i& (regfile_alu_waddr_fw_i  == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_alu_is_reg_b_id    = regfile_alu_we_fw_i& (regfile_alu_waddr_fw_i  == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_alu_is_reg_c_id    = regfile_alu_we_fw_i& (regfile_alu_waddr_fw_i  == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_alu_mem_is_reg_a_id= regfile_alu_we_mem_i&(regfile_alu_waddr_mem_i == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_alu_mem_is_reg_b_id= regfile_alu_we_mem_i&(regfile_alu_waddr_mem_i == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_alu_mem_is_reg_c_id= regfile_alu_we_mem_i&(regfile_alu_waddr_mem_i == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_alu_wb_is_reg_a_id = regfile_alu_we_wb_i& (regfile_alu_waddr_wb_i  == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_alu_wb_is_reg_b_id = regfile_alu_we_wb_i& (regfile_alu_waddr_wb_i  == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_alu_wb_is_reg_c_id = regfile_alu_we_wb_i& (regfile_alu_waddr_wb_i  == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);

  // kill instruction in the IF/ID stage by setting the instr_valid_id control
  // signal to 0 for instructions that are done
  assign clear_instr_valid_o = id_ready_o | halt_id | branch_taken_ex;

  assign branch_taken_ex     = branch_in_ex_o & branch_decision_i;


  assign mult_en = mult_int_en ;

  //////////////////////////////////////////////////////////////////
  //      _                         _____                    _    //
  //     | |_   _ _ __ ___  _ __   |_   _|_ _ _ __ __ _  ___| |_  //
  //  _  | | | | | '_ ` _ \| '_ \    | |/ _` | '__/ _` |/ _ \ __| //
  // | |_| | |_| | | | | | | |_) |   | | (_| | | | (_| |  __/ |_  //
  //  \___/ \__,_|_| |_| |_| .__/    |_|\__,_|_|  \__, |\___|\__| //
  //                       |_|                    |___/           //
  //////////////////////////////////////////////////////////////////

  always_comb
  begin : jump_target_mux
    unique case (jump_target_mux_sel)
      JT_JAL:  jump_target = pc_id_i + imm_uj_type;
      JT_COND: jump_target = pc_id_i + imm_sb_type;

      // JALR: Cannot forward RS1, since the path is too long
      JT_JALR: jump_target = regfile_data_ra_id + imm_i_type;
      default:  jump_target = regfile_data_ra_id + imm_i_type;
    endcase
  end

  assign jump_target_o = jump_target;


  ////////////////////////////////////////////////////////
  //   ___                                 _      _     //
  //  / _ \ _ __   ___ _ __ __ _ _ __   __| |    / \    //
  // | | | | '_ \ / _ \ '__/ _` | '_ \ / _` |   / _ \   //
  // | |_| | |_) |  __/ | | (_| | | | | (_| |  / ___ \  //
  //  \___/| .__/ \___|_|  \__,_|_| |_|\__,_| /_/   \_\ //
  //       |_|                                          //
  ////////////////////////////////////////////////////////

  // ALU_Op_a Mux
  always_comb
  begin : alu_operand_a_mux
    case (alu_op_a_mux_sel)
      OP_A_REGA_OR_FWD:  alu_operand_a = operand_a_fw_id;
      OP_A_REGB_OR_FWD:  alu_operand_a = operand_b_fw_id;
      OP_A_REGC_OR_FWD:  alu_operand_a = operand_c_fw_id;
      OP_A_CURRPC:       alu_operand_a = pc_id_i;
      OP_A_IMM:          alu_operand_a = imm_a;
      default:           alu_operand_a = operand_a_fw_id;
    endcase; // case (alu_op_a_mux_sel)
  end

  always_comb
  begin : immediate_a_mux
    unique case (imm_a_mux_sel)
      IMMA_Z:      imm_a = imm_z_type;
      IMMA_ZERO:   imm_a = '0;
      default:     imm_a = '0;
    endcase
  end

  // Operand a forwarding mux
  always_comb
  begin : operand_a_fw_mux
    case (operand_a_fw_mux_sel)
      SEL_FW_LOAD_WB: operand_a_fw_id = regfile_wdata_wb_i;
      SEL_FW_ALU_EX:  operand_a_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_ALU_MEM: operand_a_fw_id = regfile_alu_wdata_mem_i;
      SEL_FW_ALU_WB:  operand_a_fw_id = regfile_alu_wdata_wb_i;
      SEL_REGFILE:    operand_a_fw_id = regfile_data_ra_id;
      default:        operand_a_fw_id = regfile_data_ra_id;
    endcase; // case (operand_a_fw_mux_sel)
  end

  //////////////////////////////////////////////////////
  //   ___                                 _   ____   //
  //  / _ \ _ __   ___ _ __ __ _ _ __   __| | | __ )  //
  // | | | | '_ \ / _ \ '__/ _` | '_ \ / _` | |  _ \  //
  // | |_| | |_) |  __/ | | (_| | | | | (_| | | |_) | //
  //  \___/| .__/ \___|_|  \__,_|_| |_|\__,_| |____/  //
  //       |_|                                        //
  //////////////////////////////////////////////////////

  // Immediate Mux for operand B
  // TODO: check if sign-extension stuff works well here, maybe able to save
  // some area here
  always_comb
  begin : immediate_b_mux
    unique case (imm_b_mux_sel)
      IMMB_I:      imm_b = imm_i_type;
      IMMB_S:      imm_b = imm_s_type;
      IMMB_U:      imm_b = imm_u_type;
      IMMB_PCINCR: imm_b = 32'h4;
      IMMB_S2:     imm_b = imm_s2_type;
      IMMB_BI:     imm_b = imm_bi_type;
      IMMB_S3:     imm_b = imm_s3_type;
      IMMB_VS:     imm_b = imm_vs_type;
      IMMB_VU:     imm_b = imm_vu_type;
      default:     imm_b = imm_i_type;
    endcase
  end

  // ALU_Op_b Mux
  always_comb
  begin : alu_operand_b_mux
    case (alu_op_b_mux_sel)
      OP_B_REGA_OR_FWD:  operand_b = operand_a_fw_id;
      OP_B_REGB_OR_FWD:  operand_b = operand_b_fw_id;
      OP_B_REGC_OR_FWD:  operand_b = operand_c_fw_id;
      OP_B_IMM:          operand_b = imm_b;
      OP_B_BMASK:        operand_b = $unsigned(operand_b_fw_id[4:0]);
      default:           operand_b = operand_b_fw_id;
    endcase // case (alu_op_b_mux_sel)
  end

  // choose normal or scalar replicated version of operand b
  assign alu_operand_b = operand_b; 


  // Operand b forwarding mux
  always_comb
  begin : operand_b_fw_mux
    case (operand_b_fw_mux_sel)
      SEL_FW_LOAD_WB: operand_b_fw_id = regfile_wdata_wb_i;
      SEL_FW_ALU_EX:  operand_b_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_ALU_MEM: operand_b_fw_id = regfile_alu_wdata_mem_i;
      SEL_FW_ALU_WB:  operand_b_fw_id = regfile_alu_wdata_wb_i;
      SEL_REGFILE:    operand_b_fw_id = regfile_data_rb_id;
      default:        operand_b_fw_id = regfile_data_rb_id;
    endcase; // case (operand_b_fw_mux_sel)
  end


  //////////////////////////////////////////////////////
  //   ___                                 _    ____  //
  //  / _ \ _ __   ___ _ __ __ _ _ __   __| |  / ___| //
  // | | | | '_ \ / _ \ '__/ _` | '_ \ / _` | | |     //
  // | |_| | |_) |  __/ | | (_| | | | | (_| | | |___  //
  //  \___/| .__/ \___|_|  \__,_|_| |_|\__,_|  \____| //
  //       |_|                                        //
  //////////////////////////////////////////////////////

  // ALU OP C Mux
  always_comb
  begin : alu_operand_c_mux
    case (alu_op_c_mux_sel)
      OP_C_REGC_OR_FWD:  alu_operand_c = operand_c_fw_id;
      OP_C_REGB_OR_FWD:  alu_operand_c = operand_b_fw_id;
      OP_C_JT:           alu_operand_c = jump_target;
      default:           alu_operand_c = operand_c_fw_id;
    endcase // case (alu_op_c_mux_sel)
  end

  // Operand c forwarding mux
  always_comb
  begin : operand_c_fw_mux
    case (operand_c_fw_mux_sel)
      SEL_FW_LOAD_WB: operand_c_fw_id = regfile_wdata_wb_i;
      SEL_FW_ALU_EX:  operand_c_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_ALU_MEM: operand_c_fw_id = regfile_alu_wdata_mem_i;
      SEL_FW_ALU_WB:  operand_c_fw_id = regfile_alu_wdata_wb_i;
      SEL_REGFILE:    operand_c_fw_id = regfile_data_rc_id;
      default:        operand_c_fw_id = regfile_data_rc_id;
    endcase; // case (operand_c_fw_mux_sel)
  end


  ///////////////////////////////////////////////////////////////////////////
  //  ___                              _ _       _              ___ ____   //
  // |_ _|_ __ ___  _ __ ___   ___  __| (_) __ _| |_ ___  ___  |_ _|  _ \  //
  //  | || '_ ` _ \| '_ ` _ \ / _ \/ _` | |/ _` | __/ _ \/ __|  | || | | | //
  //  | || | | | | | | | | | |  __/ (_| | | (_| | ||  __/\__ \  | || |_| | //
  // |___|_| |_| |_|_| |_| |_|\___|\__,_|_|\__,_|\__\___||___/ |___|____/  //
  //                                                                       //
  ///////////////////////////////////////////////////////////////////////////

  assign imm_vec_ext_id = imm_vu_type[1:0];
  
  always_comb
  begin
    unique case (mult_imm_mux)
      MIMM_ZERO: mult_imm_id = '0;
      MIMM_S3:   mult_imm_id = imm_s3_type[4:0];
      default:   mult_imm_id = '0;
    endcase
  end

  /////////////////////////////////////////////////////////
  //  ____  _____ ____ ___ ____ _____ _____ ____  ____   //
  // |  _ \| ____/ ___|_ _/ ___|_   _| ____|  _ \/ ___|  //
  // | |_) |  _|| |  _ | |\___ \ | | |  _| | |_) \___ \  //
  // |  _ <| |__| |_| || | ___) || | | |___|  _ < ___) | //
  // |_| \_\_____\____|___|____/ |_| |_____|_| \_\____/  //
  //                                                     //
  /////////////////////////////////////////////////////////
  riscv_register_file
    #(
      .ADDR_WIDTH(6)
      //.FPU(FPU)
     )
  registers_i
  (
    .clk                ( clk                ),
    .rst_n              ( rst_n              ),

    .test_en_i          ( test_en_i          ),

    .fregfile_disable_i ( '0                 ),

    // Read port a
    .raddr_a_i          ( regfile_addr_ra_id ),
    .rdata_a_o          ( regfile_data_ra_id ),

    // Read port b
    .raddr_b_i          ( regfile_addr_rb_id ),
    .rdata_b_o          ( regfile_data_rb_id ),

    // Read port c
    .raddr_c_i          ( (dbg_reg_rreq_i == 1'b0) ? regfile_addr_rc_id : dbg_reg_raddr_i),
    .rdata_c_o          ( regfile_data_rc_id ),

    // Write port a
    .waddr_a_i          ( regfile_waddr_wb_i ),
    .wdata_a_i          ( regfile_wdata_wb_i ),
    .we_a_i             ( regfile_we_wb_i    ),

    // Write port b
    .waddr_b_i          ( (dbg_reg_wreq_i == 1'b0) ? regfile_alu_waddr_wb_i : dbg_reg_waddr_i  ),
    .wdata_b_i          ( (dbg_reg_wreq_i == 1'b0) ? regfile_alu_wdata_wb_i : dbg_reg_wdata_i ),
    .we_b_i             ( (dbg_reg_wreq_i == 1'b0) ? regfile_alu_we_wb_i    : 1'b1            )
  );

  assign dbg_reg_rdata_o = regfile_data_rc_id;


  ///////////////////////////////////////////////
  //  ____  _____ ____ ___  ____  _____ ____   //
  // |  _ \| ____/ ___/ _ \|  _ \| ____|  _ \  //
  // | | | |  _|| |  | | | | | | |  _| | |_) | //
  // | |_| | |__| |__| |_| | |_| | |___|  _ <  //
  // |____/|_____\____\___/|____/|_____|_| \_\ //
  //                                           //
  ///////////////////////////////////////////////

  riscv_decoder
    #(
      .RISCV_SECURE         ( RISCV_SECURE          )
      )
  decoder_i
  (
    // controller related signals
    .deassert_we_i                   ( deassert_we               ),
    .data_misaligned_i               ( data_misaligned_i         ),
    .mult_multicycle_i               ( mult_multicycle_i         ),
    .instr_multicycle_o              ( instr_multicycle          ),

    .illegal_insn_o                  ( illegal_insn_dec          ),
    .ebrk_insn_o                     ( ebrk_insn                 ),
    .mret_insn_o                     ( mret_insn_dec             ),
    .uret_insn_o                     ( uret_insn_dec             ),
    .sret_insn_o                     ( sret_insn_dec             ), //add by **, 2018.5.10
    .dret_insn_o                     ( dret_insn_dec             ),
    .ecall_insn_o                    ( ecall_insn_dec            ),
    .pipe_flush_o                    ( pipe_flush_dec            ),

    .rega_used_o                     ( rega_used_dec             ),
    .regb_used_o                     ( regb_used_dec             ),
    .regc_used_o                     ( regc_used_dec             ),

    // from IF/ID pipeline
    .instr_rdata_i                   ( instr                     ),

    // from Debug Unit
    .debug_mode_i                    ( debug_mode_i              ),

    // ALU signals
    .alu_en_o                        ( alu_en                    ),
    .alu_operator_o                  ( alu_operator              ),
    .alu_op_a_mux_sel_o              ( alu_op_a_mux_sel          ),
    .alu_op_b_mux_sel_o              ( alu_op_b_mux_sel          ),
    .alu_op_c_mux_sel_o              ( alu_op_c_mux_sel          ),
    .imm_a_mux_sel_o                 ( imm_a_mux_sel             ),
    .imm_b_mux_sel_o                 ( imm_b_mux_sel             ),
    .regc_mux_o                      ( regc_mux                  ),

    // MUL signals
    .mult_operator_o                 ( mult_operator             ),
    .mult_int_en_o                   ( mult_int_en               ),
    .mult_signed_mode_o              ( mult_signed_mode          ),
    .mult_imm_mux_o                  ( mult_imm_mux              ),

    // Register file control signals
    .regfile_mem_we_o                ( regfile_we_id             ),
    .regfile_alu_we_o                ( regfile_alu_we_id         ),

    // CSR control signals
    .csr_access_o                    ( csr_access                ),
    .csr_status_o                    ( csr_status                ),
    .csr_op_o                        ( csr_op                    ),
    .current_priv_lvl_i              ( current_priv_lvl_i        ),

    // Data bus interface
    .data_req_o                      ( data_req_id               ),
    .data_we_o                       ( data_we_id                ),
    .data_type_o                     ( data_type_id              ),
    .data_sign_extension_o           ( data_sign_ext_id          ),
    .data_reg_offset_o               ( data_reg_offset_id        ),

    // jump/branches
    .jump_in_dec_o                   ( jump_in_dec               ),
    .jump_in_id_o                    ( jump_in_id                ),
    .jump_target_mux_sel_o           ( jump_target_mux_sel       ),
	.jump_out						 ( jump_out					 )

  );

  ////////////////////////////////////////////////////////////////////
  //    ____ ___  _   _ _____ ____   ___  _     _     _____ ____    //
  //   / ___/ _ \| \ | |_   _|  _ \ / _ \| |   | |   | ____|  _ \   //
  //  | |  | | | |  \| | | | | |_) | | | | |   | |   |  _| | |_) |  //
  //  | |__| |_| | |\  | | | |  _ <| |_| | |___| |___| |___|  _ <   //
  //   \____\___/|_| \_| |_| |_| \_\\___/|_____|_____|_____|_| \_\  //
  //                                                                //
  ////////////////////////////////////////////////////////////////////

  riscv_controller controller_i
  (
    .clk                            ( clk                    ),
    .rst_n                          ( rst_n                  ),

    .fetch_enable_i                 ( fetch_enable_i         ),
    .ctrl_busy_o                    ( ctrl_busy_o            ),
    .first_fetch_o                  ( core_ctrl_firstfetch_o ),
    .is_decoding_o                  ( is_decoding_o          ),

    //debug irq
    .irq_debug_i                    ( irq_debug              ),
    .debug_mode_i                   ( debug_mode_i           ),

    // decoder related signals
    .deassert_we_o                  ( deassert_we            ),

    .illegal_insn_i                 ( illegal_insn_dec       ),
    .ecall_insn_i                   ( ecall_insn_dec         ),
    .mret_insn_i                    ( mret_insn_dec          ),
    .uret_insn_i                    ( uret_insn_dec          ),
    .sret_insn_i                    ( sret_insn_dec          ),  //add by **, 2018.5.10
    .dret_insn_i                    ( dret_insn_dec          ),  //add by **, 2018.5.10
    .pipe_flush_i                   ( pipe_flush_dec         ),
    .ebrk_insn_i                    ( ebrk_insn              ),
    .csr_status_i                   ( csr_status             ),
    .instr_multicycle_i             ( instr_multicycle       ),

    // from IF/ID pipeline
    .instr_valid_i                  ( instr_valid_i          ),

    // from prefetcher
    .instr_req_o                    ( instr_req_o            ),

    // to prefetcher
    .pc_set_o                       ( pc_set_o               ),
    .pc_mux_o                       ( pc_mux_o               ),
    .exc_pc_mux_o                   ( exc_pc_mux_o           ),
    .exc_cause_o                    ( exc_cause_o            ),
    .trap_addr_mux_o                ( trap_addr_mux_o        ),

    // LSU
    .data_req_mem_i                 ( data_req_mem_i         ),
    .data_req_ex_i                  ( data_req_ex_o          ),
    .data_misaligned_i              ( data_misaligned_i      ),

    // ALU
    .mult_multicycle_i              ( mult_multicycle_i      ),

    // jump/branch control
    .branch_taken_ex_i              ( branch_taken_ex        ),
    .jump_in_id_i                   ( jump_in_id             ),
    .jump_in_dec_i                  ( jump_in_dec            ),
	
    // Interrupt Controller Signals
    .irq_i                          ( irq_i                  ), ///****///
    .irq_req_ctrl_i                 ( irq_req_ctrl           ),
    .irq_sec_ctrl_i                 ( irq_sec_ctrl           ),
    .irq_id_ctrl_i                  ( irq_id_ctrl            ),
    .irq_enable_ctrl_i              ( irq_enable_ctrl        ),      
    .current_priv_lvl_i             ( current_priv_lvl_i     ),

    .irq_ack_o                      ( irq_ack_o              ),
    .irq_id_o                       ( irq_id_o               ),

    .exc_ack_o                      ( exc_ack                ),
    .exc_kill_o                     ( exc_kill               ),

     //from mmu exc ��2018.5.18
    .mmu_data_exception_i           ( mmu_data_exception_i   ),
    .mmu_fetch_exception_i          ( mmu_fetch_exception_i  ),
    
    // CSR Controller Signals
    .csr_save_cause_o               ( csr_save_cause_o       ),
    .csr_cause_o                    ( csr_cause_o            ),
    .csr_save_if_o                  ( csr_save_if_o          ),
    .csr_save_id_o                  ( csr_save_id_o          ),
    .csr_restore_mret_id_o          ( csr_restore_mret_id_o  ),
    .csr_restore_uret_id_o          ( csr_restore_uret_id_o  ),
    .csr_restore_sret_id_o          ( csr_restore_sret_id_o  ),     // add by **, 2018.5.10
    .csr_restore_dret_id_o          ( csr_restore_dret_id_o  ),
    .csr_irq_sec_o                  ( csr_irq_sec_o          ),
    .csr_tval_o                     ( csr_tval_o             ),     // add by **, 2018.5.17 
    .debug_pc_id_o                  ( debug_pc_id_o          ), 
    .debug_pc_if_o                  ( debug_pc_if_o          ),       
    .debug_irq_cause_en_o           ( debug_irq_cause_en_o   ),      
    .debug_ebk_cause_en_o           ( debug_ebk_cause_en_o   ),
    .debug_halt_cause_en_o          (debug_halt_cause_en_o   ),
    .debug_step_cause_en_o          (debug_step_cause_en_o   ),
	.cause_clr_o					(cause_clr_o				 ),

    //debug unit
    .debug_ebreakm_i                ( debug_ebreakm_i        ),
    .debug_ebreaku_i                ( debug_ebreaku_i        ),
    .debug_ebreaks_i                ( debug_ebreaks_i        ),
    .debug_halt_new_i                   (debug_halt_new_i),
    .debug_step_i                   (debug_step_i),
    // Debug Unit Signals
    .dbg_req_i                      ( dbg_req_i              ),
    .dbg_ack_o                      ( dbg_ack_o              ),
    .dbg_stall_i                    ( dbg_stall_i            ),
    .dbg_jump_req_i                 ( dbg_jump_req_i         ),
    .dbg_settings_i                 ( dbg_settings_i         ),
    .dbg_trap_o                     ( dbg_trap_o             ),

    // Write targets from ID
    .regfile_alu_waddr_id_i         ( regfile_alu_waddr_id   ),
    .regfile_alu_waddr_fw_i         ( regfile_alu_waddr_fw_i ),
    .regfile_waddr_mem_i            ( regfile_waddr_mem_i    ),

    // Forwarding signals from regfile
    .regfile_we_ex_i                ( regfile_we_ex_o        ),
    .regfile_we_mem_i               ( regfile_we_mem_i       ),
    .regfile_we_wb_i                ( regfile_we_wb_i        ),

    // regfile port 2
    .regfile_alu_we_fw_i            ( regfile_alu_we_fw_i    ),
    .regfile_alu_we_mem_i           ( regfile_alu_we_mem_i   ),
    .regfile_alu_we_wb_i            ( regfile_alu_we_wb_i    ),

    // Forwarding detection signals
    .reg_d_ex_is_reg_a_i            ( reg_d_ex_is_reg_a_id   ),
    .reg_d_ex_is_reg_b_i            ( reg_d_ex_is_reg_b_id   ),
    .reg_d_ex_is_reg_c_i            ( reg_d_ex_is_reg_c_id   ),
    .reg_d_wb_is_reg_a_i            ( reg_d_wb_is_reg_a_id   ),
    .reg_d_wb_is_reg_b_i            ( reg_d_wb_is_reg_b_id   ),
    .reg_d_wb_is_reg_c_i            ( reg_d_wb_is_reg_c_id   ),
    .reg_d_mem_is_reg_a_i           ( reg_d_mem_is_reg_a_id   ),
    .reg_d_mem_is_reg_b_i           ( reg_d_mem_is_reg_b_id   ),
    .reg_d_mem_is_reg_c_i           ( reg_d_mem_is_reg_c_id   ),
    .reg_d_alu_is_reg_a_i           ( reg_d_alu_is_reg_a_id  ),
    .reg_d_alu_is_reg_b_i           ( reg_d_alu_is_reg_b_id  ),
    .reg_d_alu_is_reg_c_i           ( reg_d_alu_is_reg_c_id  ),
    .reg_d_alu_mem_is_reg_a_i       ( reg_d_alu_mem_is_reg_a_id  ),
    .reg_d_alu_mem_is_reg_b_i       ( reg_d_alu_mem_is_reg_b_id  ),
    .reg_d_alu_mem_is_reg_c_i       ( reg_d_alu_mem_is_reg_c_id  ),
    .reg_d_alu_wb_is_reg_a_i        ( reg_d_alu_wb_is_reg_a_id  ),
    .reg_d_alu_wb_is_reg_b_i        ( reg_d_alu_wb_is_reg_b_id  ),
    .reg_d_alu_wb_is_reg_c_i        ( reg_d_alu_wb_is_reg_c_id  ),

    // Forwarding signals
    .operand_a_fw_mux_sel_o         ( operand_a_fw_mux_sel   ),
    .operand_b_fw_mux_sel_o         ( operand_b_fw_mux_sel   ),
    .operand_c_fw_mux_sel_o         ( operand_c_fw_mux_sel   ),

    // Stall signals
    .halt_if_o                      ( halt_if_o              ),
    .halt_id_o                      ( halt_id                ),

    .misaligned_stall_o             ( misaligned_stall       ),
    .jr_stall_o                     ( jr_stall               ),
    .load_stall_o                   ( load_stall             ),
    .load_wfw_stall_o               ( load_wfw_stall_o       ),
    .lsu_successive_stall_o         ( lsu_successive_stall_o ),

    .id_ready_i                     ( id_ready_o             ),

    .ex_valid_i                     ( ex_valid_i             ),

    .mem_valid_i                    ( mem_valid_i            ),

    .wb_ready_i                     ( wb_ready_i             ),

    .lsu_ready_mem_i                ( lsu_ready_mem_i        ),

    // Performance Counters
    .perf_jump_o                    ( perf_jump_o            ),
    .perf_jr_stall_o                ( perf_jr_stall_o        ),
    .perf_ld_stall_o                ( perf_ld_stall_o        )
  );


////////////////////////////////////////////////////////////////////////
//  _____      _       _____             _             _ _            //
// |_   _|    | |     /  __ \           | |           | | |           //
//   | | _ __ | |_    | /  \/ ___  _ __ | |_ _ __ ___ | | | ___ _ __  //
//   | || '_ \| __|   | |    / _ \| '_ \| __| '__/ _ \| | |/ _ \ '__| //
//  _| || | | | |_ _  | \__/\ (_) | | | | |_| | | (_) | | |  __/ |    //
//  \___/_| |_|\__(_)  \____/\___/|_| |_|\__|_|  \___/|_|_|\___|_|    //
//                                                                    //
////////////////////////////////////////////////////////////////////////

  riscv_int_controller
  #(
    .RISCV_SECURE(RISCV_SECURE)
   )
  int_controller_i
  (
    .clk                  ( clk                ),
    .rst_n                ( rst_n              ),

    .irq_debug_o          ( irq_debug          ),
    .debug_mode_i         ( debug_mode_i       ),
    .debug_halt_new_i                   (debug_halt_new_i),
    .debug_step_i                   (debug_step_i),

    // to controller
    .irq_req_ctrl_o       ( irq_req_ctrl       ),
    .irq_sec_ctrl_o       ( irq_sec_ctrl       ),
    .irq_id_ctrl_o        ( irq_id_ctrl        ),
    .irq_enable_ctrl_o    ( irq_enable_ctrl    ),
    .irq_req_happen_o     ( irq_req_happen_o   ), 
    .irq_req_event_o      ( irq_req_event_o    ),  

    .ctrl_ack_i           ( exc_ack            ),
    .ctrl_kill_i          ( exc_kill           ),

    // Interrupt signals
    .irq_i                ( irq_i              ),
    .irq_sec_i            ( irq_sec_i          ),
    .irq_id_i             ( irq_id_i           ),
    .mip_i                ( mip_i              ),
    .mie_i                ( mie_i              ),

    .m_IE_i               ( m_irq_enable_i     ),
    .s_IE_i               ( s_irq_enable_i     ),
    .u_IE_i               ( u_irq_enable_i     ),
    .csr_mideleg_i        ( csr_mideleg_i      ),

    .current_priv_lvl_i   ( current_priv_lvl_i )

  );

  /////////////////////////////////////////////////////////////////////////////////
  //   ___ ____        _______  __  ____ ___ ____  _____ _     ___ _   _ _____   //
  //  |_ _|  _ \      | ____\ \/ / |  _ \_ _|  _ \| ____| |   |_ _| \ | | ____|  //
  //   | || | | |_____|  _|  \  /  | |_) | || |_) |  _| | |    | ||  \| |  _|    //
  //   | || |_| |_____| |___ /  \  |  __/| ||  __/| |___| |___ | || |\  | |___   //
  //  |___|____/      |_____/_/\_\ |_|  |___|_|   |_____|_____|___|_| \_|_____|  //
  //                                                                             //
  /////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk, negedge rst_n)
  begin : ID_EX_PIPE_REGISTERS
    if (rst_n == 1'b0)
    begin
      alu_en_ex_o                 <= '0;
      alu_operator_ex_o           <= ALU_SLTU;
      alu_operand_a_ex_o          <= '0;
      alu_operand_b_ex_o          <= '0;
      alu_operand_c_ex_o          <= '0;
      imm_vec_ext_ex_o            <= '0;

      mult_operator_ex_o          <= '0;
      mult_operand_a_ex_o         <= '0;
      mult_operand_b_ex_o         <= '0;
      mult_operand_c_ex_o         <= '0;
      mult_en_ex_o                <= 1'b0;
      mult_signed_mode_ex_o       <= 2'b00;
      mult_imm_ex_o               <= '0;

      regfile_waddr_ex_o          <= 6'b0;
      regfile_we_ex_o             <= 1'b0;

      regfile_alu_waddr_ex_o      <= 6'b0;
      regfile_alu_we_ex_o         <= 1'b0;

      csr_access_ex_o             <= 1'b0;
      csr_op_ex_o                 <= CSR_OP_NONE;

      data_we_ex_o                <= 1'b0;
      data_type_ex_o              <= 2'b0;
      data_sign_ext_ex_o          <= 1'b0;
      data_reg_offset_ex_o        <= 2'b0;
      data_req_ex_o               <= 1'b0;

      data_misaligned_ex_o        <= 1'b0;

      pc_ex_o                     <= '0;

      branch_in_ex_o              <= 1'b0;

    end
    else if (data_misaligned_i) begin
      // misaligned data access case
      if (ex_ready_i)
      begin // misaligned access case, only unstall alu operands
        alu_operand_a_ex_o        <= alu_operand_a;
        alu_operand_b_ex_o        <= alu_operand_b;
        regfile_alu_we_ex_o       <= regfile_alu_we_id;
        data_misaligned_ex_o      <= 1'b1;
      end
    end else if (mult_multicycle_i) begin
      mult_operand_c_ex_o <= alu_operand_c;
    end
    else begin
      // normal pipeline unstall case

      if (id_valid_o)
      begin // unstall the whole pipeline

        alu_en_ex_o                 <= alu_en;
        if (alu_en)
        begin // only change those registers when we actually need to
          alu_operator_ex_o         <= alu_operator;
          alu_operand_a_ex_o        <= alu_operand_a;
          alu_operand_b_ex_o        <= alu_operand_b;
          alu_operand_c_ex_o        <= alu_operand_c;
          imm_vec_ext_ex_o          <= imm_vec_ext_id;
        end

        mult_en_ex_o                <= mult_en;
        if (mult_int_en) begin
          mult_operator_ex_o        <= mult_operator;
          mult_signed_mode_ex_o     <= mult_signed_mode;
          mult_operand_a_ex_o       <= alu_operand_a;
          mult_operand_b_ex_o       <= alu_operand_b;
          mult_operand_c_ex_o       <= alu_operand_c;
          mult_imm_ex_o             <= mult_imm_id;
        end

        regfile_we_ex_o             <= regfile_we_id;
        if (regfile_we_id) begin
          regfile_waddr_ex_o        <= regfile_waddr_id;
        end

        regfile_alu_we_ex_o         <= regfile_alu_we_id;
        if (regfile_alu_we_id) begin
          regfile_alu_waddr_ex_o    <= regfile_alu_waddr_id;
        end

        csr_access_ex_o             <= csr_access;
        csr_op_ex_o                 <= csr_op;

        data_req_ex_o               <= data_req_id;
        if (data_req_id)
        begin // only needed for LSU when there is an active request
          data_we_ex_o              <= data_we_id;
          data_type_ex_o            <= data_type_id;
          data_sign_ext_ex_o        <= data_sign_ext_id;
          data_reg_offset_ex_o      <= data_reg_offset_id;
        end 

        data_misaligned_ex_o        <= 1'b0;

        if ((jump_in_id == BRANCH_COND) ) begin
          pc_ex_o                   <= pc_id_i;
        end

        branch_in_ex_o              <= jump_in_id == BRANCH_COND;
      end else if(ex_ready_i) begin
        // EX stage is ready but we don't have a new instruction for it,
        // so we set all write enables to 0, but unstall the pipe

        regfile_we_ex_o             <= 1'b0;

        regfile_alu_we_ex_o         <= 1'b0;

        csr_op_ex_o                 <= CSR_OP_NONE;

        data_req_ex_o               <= 1'b0;

        data_misaligned_ex_o        <= 1'b0;

        branch_in_ex_o              <= 1'b0;

        //alu_operator_ex_o           <= ALU_SLTU;

        mult_en_ex_o                <= 1'b0;

      end else if (csr_access_ex_o) begin
       //In the EX stage there was a CSR access, to avoid multiple
       //writes to the RF, disable regfile_alu_we_ex_o.
       //Not doing it can overwrite the RF file with the currennt CSR value rather than the old one
       regfile_alu_we_ex_o         <= 1'b0;
      end
    end
  end


  // stall control
  assign id_ready_o = ((~misaligned_stall) & (~jr_stall) & (~load_stall) &  ex_ready_i);
  assign id_valid_o = (~halt_id) & id_ready_o;


  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------
  `ifndef SIMULATION
    // make sure that branch decision is valid when jumping
    assert property (
      @(posedge clk) (branch_in_ex_o) |-> (branch_decision_i !== 1'bx) ) else $display("%t, Branch decision is X", $time);

    // the instruction delivered to the ID stage should always be valid
    assert property (
      @(posedge clk) (instr_valid_i) |-> (!$isunknown(instr_rdata_i)) ) else $display("Instruction is valid, but has at least one X");
  `endif
endmodule
