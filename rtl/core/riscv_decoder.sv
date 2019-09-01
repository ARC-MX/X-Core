// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the 鈥淟icense鈥�); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an 鈥淎S IS鈥� BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer        Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                                                                            //
// Additional contributions by:                                               //
//                 Matthias Baer - baermatt@student.ethz.ch                   //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Decoder                                                    //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Decoder                                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////
// Based on PULP RISCV Core by perfxlab
// RSIC V top module 
// 2018/5/26
/////////////////////////////////////////////////


//`include "./include/apu_macros.sv"
import riscv_package::*;
import riscv_defines::*;

module riscv_decoder
#(
  parameter RISCV_SECURE       = 1
)
(
  // singals running to/from controller
  input  logic        deassert_we_i,           // deassert we, we are stalled or not active
  input  logic        data_misaligned_i,       // misaligned data load/store in progress
  input  logic        mult_multicycle_i,       // multiplier taking multiple cycles, using op c as storage
  output logic        instr_multicycle_o,      // true when multiple cycles are decoded

  output logic        illegal_insn_o,          // illegal instruction encountered
  output logic        ebrk_insn_o,             // trap instruction encountered
  output logic        mret_insn_o,             // return from exception instruction encountered (M)
  output logic        uret_insn_o,             // return from exception instruction encountered (S) // comment: why is it S mode, not U-mode?
  output logic        sret_insn_o,             // return from exception instruction encountered (S) // add by 2018.5.10
  output logic        dret_insn_o,
  output logic        ecall_insn_o,            // environment call (syscall) instruction encountered
  output logic        pipe_flush_o,            // pipeline flush is requested

  output logic        rega_used_o,             // rs1 is used by current instruction
  output logic        regb_used_o,             // rs2 is used by current instruction
  output logic        regc_used_o,             // rs3 is used by current instruction

  // from IF/ID pipeline
  input  logic [31:0] instr_rdata_i,           // instruction read from instr memory/cache

  //from Debug Unit
  input  logic        debug_mode_i,

  // ALU signals
  output logic        alu_en_o,                // ALU enable
  output logic [ALU_OP_WIDTH-1:0] alu_operator_o, // ALU operation selection
  output logic [2:0]  alu_op_a_mux_sel_o,      // operand a selection: reg value, PC, immediate or zero
  output logic [2:0]  alu_op_b_mux_sel_o,      // operand b selection: reg value or immediate
  output logic [1:0]  alu_op_c_mux_sel_o,      // operand c selection: reg value or jump target

  output logic [0:0]  imm_a_mux_sel_o,         // immediate selection for operand a
  output logic [3:0]  imm_b_mux_sel_o,         // immediate selection for operand b
  output logic [1:0]  regc_mux_o,              // register c selection: S3, RD or 0

  // MUL related control signals
  output logic [2:0]  mult_operator_o,         // Multiplication operation selection
  output logic        mult_int_en_o,           // perform integer multiplication
  output logic [0:0]  mult_imm_mux_o,          // Multiplication immediate mux selector
  output logic [1:0]  mult_signed_mode_o,      // Multiplication in signed mode

  // register file related signals
  output logic        regfile_mem_we_o,        // write enable for regfile
  output logic        regfile_alu_we_o,        // write enable for 2nd regfile port
  //output logic        regfile_alu_waddr_sel_o, // Select register write address for ALU/MUL operations

  // CSR manipulation
  output logic        csr_access_o,            // access to CSR
  output logic        csr_status_o,            // access to xstatus CSR
  output logic [1:0]  csr_op_o,                // operation to perform on CSR
  input  PrivLvl_t    current_priv_lvl_i,      // The current privilege level

  // LD/ST unit signals
  output logic        data_req_o,              // start transaction to data memory
  output logic        data_we_o,               // data memory write enable
  output logic [1:0]  data_type_o,             // data type on data memory: byte, half word or word
  output logic        data_sign_extension_o,   // sign extension on read data from data memory
  output logic [1:0]  data_reg_offset_o,       // offset in byte inside register for stores
  //output logic        data_load_event_o,       // data request is in the special event range

  // jump/branches
  output logic [1:0]  jump_in_dec_o,           // jump_in_id without deassert
  output logic [1:0]  jump_in_id_o,            // jump is being calculated in ALU
  output logic [1:0]  jump_target_mux_sel_o,    // jump target selection
  output logic 		  jump_out
);

  // write enable/request control
  logic       regfile_mem_we;
  logic       regfile_alu_we;
  logic       data_req;
  logic       csr_illegal;
  logic [1:0] jump_in_id;

  logic [1:0] csr_op;

  /////////////////////////////////////////////
  //   ____                     _            //
  //  |  _ \  ___  ___ ___   __| | ___ _ __  //
  //  | | | |/ _ \/ __/ _ \ / _` |/ _ \ '__| //
  //  | |_| |  __/ (_| (_) | (_| |  __/ |    //
  //  |____/ \___|\___\___/ \__,_|\___|_|    //
  //                                         //
  /////////////////////////////////////////////

  always_comb
  begin
    jump_in_id                  = BRANCH_NONE;
    jump_target_mux_sel_o       = JT_JAL;

    alu_en_o                    = 1'b1;
    alu_operator_o              = ALU_SLTU;
    alu_op_a_mux_sel_o          = OP_A_REGA_OR_FWD;
    alu_op_b_mux_sel_o          = OP_B_REGB_OR_FWD;
    alu_op_c_mux_sel_o          = OP_C_REGC_OR_FWD;

   // scalar_replication_o        = 1'b0;
    regc_mux_o                  = REGC_ZERO;
    imm_a_mux_sel_o             = IMMA_ZERO;
    imm_b_mux_sel_o             = IMMB_I;

    mult_operator_o             = MUL_I;
    mult_int_en_o               = 1'b0;
    mult_imm_mux_o              = MIMM_ZERO;
    mult_signed_mode_o          = 2'b00;

    regfile_mem_we              = 1'b0;
    regfile_alu_we              = 1'b0;
    //regfile_alu_waddr_sel_o     = 1'b1;

    csr_access_o                = 1'b0;
    csr_status_o                = 1'b0;
    csr_illegal                 = 1'b0;
    csr_op                      = CSR_OP_NONE;
    mret_insn_o                 = 1'b0;
    uret_insn_o                 = 1'b0;
    sret_insn_o                 = 1'b0;          //add by 2018.5.10
    dret_insn_o                 = 1'b0;

    data_we_o                   = 1'b0;
    data_type_o                 = 2'b00;
    data_sign_extension_o       = 1'b0;
    data_reg_offset_o           = 2'b00;
    data_req                    = 1'b0;
    //data_load_event_o           = 1'b0;

    illegal_insn_o              = 1'b0;
    ebrk_insn_o                 = 1'b0;
    ecall_insn_o                = 1'b0;
    pipe_flush_o                = 1'b0;

    rega_used_o                 = 1'b0;
    regb_used_o                 = 1'b0;
    regc_used_o                 = 1'b0;

    instr_multicycle_o          = 1'b0;
	jump_out					= 1'b0;//2018-8-29 by zhou,Dpc stores errors when jump
    unique case (instr_rdata_i[6:0])

      //////////////////////////////////////
      //      _ _   _ __  __ ____  ____   //
      //     | | | | |  \/  |  _ \/ ___|  //
      //  _  | | | | | |\/| | |_) \___ \  //
      // | |_| | |_| | |  | |  __/ ___) | //
      //  \___/ \___/|_|  |_|_|   |____/  //
      //                                  //
      //////////////////////////////////////

`ifndef DIS_JAL
      OPCODE_JAL: begin   // Jump and Link
        jump_target_mux_sel_o = JT_JAL;
        jump_in_id            = BRANCH_JAL;
        // Calculate and store PC+4
        alu_op_a_mux_sel_o  = OP_A_CURRPC;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_PCINCR;
        alu_operator_o      = ALU_ADD;
        regfile_alu_we      = 1'b1;
		jump_out			= 1'b1;//2018-8-29 by zhou,Dpc stores errors when jump
        // Calculate jump target (= PC + UJ imm)
      end
`endif
`ifndef DIS_JALR
      OPCODE_JALR: begin  // Jump and Link Register
        jump_target_mux_sel_o = JT_JALR;
        jump_in_id            = BRANCH_JALR;
        // Calculate and store PC+4
        alu_op_a_mux_sel_o  = OP_A_CURRPC;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_PCINCR;
        alu_operator_o      = ALU_ADD;
        regfile_alu_we      = 1'b1;
        // Calculate jump target (= RS1 + I imm)
        rega_used_o         = 1'b1;
		jump_out			= 1'b1;//2018-8-29 by zhou,Dpc stores errors when jump
        if (instr_rdata_i[14:12] != 3'b0) begin
          jump_in_id       = BRANCH_NONE;
          regfile_alu_we   = 1'b0;
          illegal_insn_o   = 1'b1;
        end
      end
`endif

      OPCODE_BRANCH: begin // Branch
        jump_target_mux_sel_o = JT_COND;
        jump_in_id            = BRANCH_COND;
        alu_op_c_mux_sel_o    = OP_C_JT;
        rega_used_o           = 1'b1;
        regb_used_o           = 1'b1;
		jump_out 			  = 1'b1;
        unique case (instr_rdata_i[14:12])
`ifndef DIS_BEQ
          3'b000: alu_operator_o = ALU_EQ;
`endif
`ifndef DIS_BNE
          3'b001: alu_operator_o = ALU_NE;
`endif
`ifndef DIS_BLT  
          3'b100: alu_operator_o = ALU_LTS;
`endif
`ifndef DIS_BGE
          3'b101: alu_operator_o = ALU_GES;
`endif
`ifndef DIS_BLTU
          3'b110: alu_operator_o = ALU_LTU;
`endif
`ifndef DIS_BGEU
          3'b111: alu_operator_o = ALU_GEU;
`endif
          3'b010: begin
            alu_operator_o      = ALU_EQ;
            regb_used_o         = 1'b0;
            alu_op_b_mux_sel_o  = OP_B_IMM;
            imm_b_mux_sel_o     = IMMB_BI;
          end
          3'b011: begin
            alu_operator_o      = ALU_NE;
            regb_used_o         = 1'b0;
            alu_op_b_mux_sel_o  = OP_B_IMM;
            imm_b_mux_sel_o     = IMMB_BI;
          end
          default: begin
            illegal_insn_o = 1'b1;
          end
        endcase
      end

      //////////////////////////////////
      //  _     ____    ______ _____  //
      // | |   |  _ \  / / ___|_   _| //
      // | |   | | | |/ /\___ \ | |   //
      // | |___| |_| / /  ___) || |   //
      // |_____|____/_/  |____/ |_|   //
      //                              //
      //////////////////////////////////

`ifndef DIS_STORE
      OPCODE_STORE: begin
        data_req       = 1'b1;
        data_we_o      = 1'b1;
        rega_used_o    = 1'b1;
        regb_used_o    = 1'b1;
        alu_operator_o = ALU_ADD;
        instr_multicycle_o = 1'b1;
        // pass write data through ALU operand c
        alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;

        if (instr_rdata_i[14] == 1'b0) begin
          // offset from immediate
          imm_b_mux_sel_o     = IMMB_S;
          alu_op_b_mux_sel_o  = OP_B_IMM;
        end else begin
          // offset from register
          regc_used_o        = 1'b1;
          alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
          regc_mux_o         = REGC_RD;
        end

        // store size
        unique case (instr_rdata_i[13:12])
          2'b00: data_type_o = 2'b10; // SB
          2'b01: data_type_o = 2'b01; // SH
          2'b10: data_type_o = 2'b00; // SW
          default: begin
            data_req       = 1'b0;
            data_we_o      = 1'b0;
            illegal_insn_o = 1'b1;
          end
        endcase
      end
`endif
`ifndef DIS_LOAD
      OPCODE_LOAD: begin
        data_req        = 1'b1;
        regfile_mem_we  = 1'b1;
        rega_used_o     = 1'b1;
        data_type_o     = 2'b00;
        instr_multicycle_o = 1'b1;
        // offset from immediate
        alu_operator_o      = ALU_ADD;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_I;

        // sign/zero extension
        data_sign_extension_o = ~instr_rdata_i[14];

        // load size
        unique case (instr_rdata_i[13:12])
          2'b00:   data_type_o = 2'b10; // LB
          2'b01:   data_type_o = 2'b01; // LH
          2'b10:   data_type_o = 2'b00; // LW
          default: data_type_o = 2'b00; // illegal or reg-reg
        endcase

        // reg-reg load (different encoding)
        //if (instr_rdata_i[14:12] == 3'b111) begin
          // offset from RS2
        //  regb_used_o        = 1'b1;
        //  alu_op_b_mux_sel_o = OP_B_REGB_OR_FWD;

          // sign/zero extension
        //  data_sign_extension_o = ~instr_rdata_i[30];

          // load size
        //  unique case (instr_rdata_i[31:25])
        //    7'b0000_000,
        //    7'b0100_000: data_type_o = 2'b10; // LB, LBU
        //    7'b0001_000,
        //    7'b0101_000: data_type_o = 2'b01; // LH, LHU
        //    7'b0010_000: data_type_o = 2'b00; // LW
        //    default: begin
        //      illegal_insn_o = 1'b1;
        //    end
        //  endcase
        //end

        // special p.elw (event load)
        //if (instr_rdata_i[14:12] == 3'b110)
        //  data_load_event_o = 1'b1;

        if (instr_rdata_i[14:12] == 3'b111 || instr_rdata_i[14:12] == 3'b110 || instr_rdata_i[14:12] == 3'b011) begin
          illegal_insn_o = 1'b1;
        end
      end
`endif

      //////////////////////////
      //     _    _    _   _  //
      //    / \  | |  | | | | //
      //   / _ \ | |  | | | | //
      //  / ___ \| |__| |_| | //
      // /_/   \_\_____\___/  //
      //                      //
      //////////////////////////

`ifndef DIS_LUI
      OPCODE_LUI: begin  // Load Upper Immediate
        alu_op_a_mux_sel_o  = OP_A_IMM;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_a_mux_sel_o     = IMMA_ZERO;
        imm_b_mux_sel_o     = IMMB_U;
        alu_operator_o      = ALU_ADD;
        regfile_alu_we      = 1'b1;
      end
`endif
`ifndef DIS_AUIPC
      OPCODE_AUIPC: begin  // Add Upper Immediate to PC
        alu_op_a_mux_sel_o  = OP_A_CURRPC;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_U;
        alu_operator_o      = ALU_ADD;
        regfile_alu_we      = 1'b1;
      end
`endif
      OPCODE_OPIMM: begin // Register-Immediate ALU Operations
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_I;
        regfile_alu_we      = 1'b1;
        rega_used_o         = 1'b1;

        unique case (instr_rdata_i[14:12])
`ifndef DIS_ADDI
          3'b000: alu_operator_o = ALU_ADD;  // Add Immediate
`endif
`ifndef DIS_SLTIS
          3'b010: alu_operator_o = ALU_SLTS; // Set to one if Lower Than Immediate
`endif
`ifndef DIS_SLTIU
          3'b011: alu_operator_o = ALU_SLTU; // Set to one if Lower Than Immediate Unsigned
`endif
`ifndef DIS_XORI
          3'b100: alu_operator_o = ALU_XOR;  // Exclusive Or with Immediate
`endif
`ifndef DIS_ORI
          3'b110: alu_operator_o = ALU_OR;   // Or with Immediate
`endif
`ifndef DIS_ANDI
          3'b111: alu_operator_o = ALU_AND;  // And with Immediate
`endif
`ifndef DIS_SLLI
          3'b001: begin
            alu_operator_o = ALU_SLL;  // Shift Left Logical by Immediate
            if (instr_rdata_i[31:25] != 7'b0)
              illegal_insn_o = 1'b1;
          end
`endif

          3'b101: begin
`ifndef DIS_SRLI
            if (instr_rdata_i[31:25] == 7'b0)
              alu_operator_o = ALU_SRL;  // Shift Right Logical by Immediate
            else 
`endif
            begin
`ifndef DIS_SRAI
              if (instr_rdata_i[31:25] == 7'b010_0000)
                alu_operator_o = ALU_SRA;  // Shift Right Arithmetically by Immediate
              else
`endif
                illegal_insn_o = 1'b1;
            end // else
          end

          default: begin
              illegal_insn_o = 1'b1;
            end
        endcase
      end

      OPCODE_OP: begin  // Register-Register ALU operation
        regfile_alu_we = 1'b1;
        rega_used_o    = 1'b1;

          if (~instr_rdata_i[28])
            regb_used_o = 1'b1;

          unique case ({instr_rdata_i[30:25], instr_rdata_i[14:12]})
            // RV32I ALU operations
`ifndef DIS_ADD
            {6'b00_0000, 3'b000}: alu_operator_o = ALU_ADD;   // Add
`endif
`ifndef DIS_SUB
            {6'b10_0000, 3'b000}: alu_operator_o = ALU_SUB;   // Sub
`endif
`ifndef DIS_SLTS
            {6'b00_0000, 3'b010}: alu_operator_o = ALU_SLTS;  // Set Lower Than
`endif
`ifndef DIS_SLTU
            {6'b00_0000, 3'b011}: alu_operator_o = ALU_SLTU;  // Set Lower Than Unsigned
`endif
`ifndef DIS_XOR
            {6'b00_0000, 3'b100}: alu_operator_o = ALU_XOR;   // Xor
`endif
`ifndef DIS_OR
            {6'b00_0000, 3'b110}: alu_operator_o = ALU_OR;    // Or
`endif
`ifndef DIS_AND
            {6'b00_0000, 3'b111}: alu_operator_o = ALU_AND;   // And
`endif
`ifndef DIS_SLL
            {6'b00_0000, 3'b001}: alu_operator_o = ALU_SLL;   // Shift Left Logical
`endif
`ifndef DIS_SRL
            {6'b00_0000, 3'b101}: alu_operator_o = ALU_SRL;   // Shift Right Logical
`endif
`ifndef DIS_SRA
            {6'b10_0000, 3'b101}: alu_operator_o = ALU_SRA;   // Shift Right Arithmetic
`endif
`ifndef DIS_MUL
            // supported RV32M instructions
            {6'b00_0001, 3'b000}: begin // mul
              alu_en_o        = 1'b0;
              mult_int_en_o   = 1'b1;
              mult_operator_o = MUL_MAC32;
              regc_mux_o      = REGC_ZERO;
            end
`endif
`ifndef DIS_MULH
            {6'b00_0001, 3'b001}: begin // mulh
              alu_en_o           = 1'b0;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b11;
              mult_int_en_o      = 1'b1;
              mult_operator_o    = MUL_H;
              instr_multicycle_o = 1'b1;
            end
`endif
`ifndef DIS_MULHSU
            {6'b00_0001, 3'b010}: begin // mulhsu
              alu_en_o           = 1'b0;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b01;
              mult_int_en_o      = 1'b1;
              mult_operator_o    = MUL_H;
              instr_multicycle_o = 1'b1;
            end
`endif
`ifndef DIS_MULHU
            {6'b00_0001, 3'b011}: begin // mulhu
              alu_en_o           = 1'b0;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b00;
              mult_int_en_o      = 1'b1;
              mult_operator_o    = MUL_H;
              instr_multicycle_o = 1'b1;
            end
`endif
`ifndef DIS_DIV
            {6'b00_0001, 3'b100}: begin // div
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
              regc_mux_o         = REGC_S1;
              regc_used_o        = 1'b1;
              regb_used_o        = 1'b1;
              rega_used_o        = 1'b0;
              alu_operator_o     = ALU_DIV;
              instr_multicycle_o = 1'b1;
              //`USE_APU_INT_DIV
            end
`endif
`ifndef DIS_DIVU
            {6'b00_0001, 3'b101}: begin // divu
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
              regc_mux_o         = REGC_S1;
              regc_used_o        = 1'b1;
              regb_used_o        = 1'b1;
              rega_used_o        = 1'b0;
              alu_operator_o     = ALU_DIVU;
              instr_multicycle_o = 1'b1;
              //`USE_APU_INT_DIV
            end
`endif
`ifndef DIS_REM
            {6'b00_0001, 3'b110}: begin // rem
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
              regc_mux_o         = REGC_S1;
              regc_used_o        = 1'b1;
              regb_used_o        = 1'b1;
              rega_used_o        = 1'b0;
              alu_operator_o     = ALU_REM;
              instr_multicycle_o = 1'b1;
              //`USE_APU_INT_DIV
            end
`endif
`ifndef DIS_REMU
            {6'b00_0001, 3'b111}: begin // remu
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
              regc_mux_o         = REGC_S1;
              regc_used_o        = 1'b1;
              regb_used_o        = 1'b1;
              rega_used_o        = 1'b0;
              alu_operator_o     = ALU_REMU;
              instr_multicycle_o = 1'b1;
              //`USE_APU_INT_DIV
            end
`endif
            default: begin
              illegal_insn_o = 1'b1;
            end
          endcase
        //end
      end



      ////////////////////////////////////////////////
      //  ____  ____  _____ ____ ___    _    _      //
      // / ___||  _ \| ____/ ___|_ _|  / \  | |     //
      // \___ \| |_) |  _|| |    | |  / _ \ | |     //
      //  ___) |  __/| |__| |___ | | / ___ \| |___  //
      // |____/|_|   |_____\____|___/_/   \_\_____| //
      //                                            //
      ////////////////////////////////////////////////

      OPCODE_SYSTEM: begin
        if (instr_rdata_i[14:12] == 3'b000)
        begin
          if(instr_rdata_i[31:25] == 7'b0001001) begin //fence.vma, not implement
             illegal_insn_o = 1'b0;
          end else begin
          // non CSR related SYSTEM instructions
            unique case (instr_rdata_i[31:20])
`ifndef DIS_ECALL
              12'h000:  // ECALL
              begin
                // environment (system) call
                ecall_insn_o  = 1'b1;
              end
`endif  
`ifndef DIS_EBREAK
              12'h001:  // ebreak
              begin
                // debugger trap
                ebrk_insn_o = 1'b1;
              end
`endif  
`ifndef DIS_MRET 
              12'h302:  // mret
              begin
                illegal_insn_o = (RISCV_SECURE) ? current_priv_lvl_i != PRIV_LVL_M : 1'b0;
                mret_insn_o    = ~illegal_insn_o;
              end
`endif  
`ifndef DIS_SRET   
              12'h102: // sret //add  2018.5.10
              begin
                illegal_insn_o =  (RISCV_SECURE) ? current_priv_lvl_i == PRIV_LVL_U : 1'b0;
	             sret_insn_o    = ~illegal_insn_o;
              end
`endif  
`ifndef DIS_URET  
              12'h002:  // uret
              begin
                uret_insn_o   = (RISCV_SECURE) ? 1'b1 : 1'b0;
              end
`endif  
`ifndef DIS_WFI   
              12'h105:  // wfi
              begin
                // flush pipeline
                pipe_flush_o = 1'b1;
              end
`endif  
`ifndef DIS_DRET 
              12'h7B2:  //dret
                if(debug_mode_i) begin
                  dret_insn_o  = 1'b1;
                  illegal_insn_o = 1'b0;
                end else begin
                  dret_insn_o  = 1'b0;
                  illegal_insn_o = 1'b1;
                end // end else
`endif                 
              default:
              begin
                illegal_insn_o = 1'b1;
              end
            endcase
          end
        end
        else
        begin
          // instruction to read/modify CSR
          csr_access_o        = 1'b1;
          regfile_alu_we      = 1'b1;
          alu_op_b_mux_sel_o  = OP_B_IMM;
          imm_a_mux_sel_o     = IMMA_Z;
          imm_b_mux_sel_o     = IMMB_I;    // CSR address is encoded in I imm
          instr_multicycle_o  = 1'b1;

          if (instr_rdata_i[14] == 1'b1) begin
            // rs1 field is used as immediate
            alu_op_a_mux_sel_o = OP_A_IMM;
          end else begin
            rega_used_o        = 1'b1;
            alu_op_a_mux_sel_o = OP_A_REGA_OR_FWD;
          end

          unique case (instr_rdata_i[13:12])
            2'b01:   csr_op   = CSR_OP_WRITE;
            2'b10:   csr_op   = CSR_OP_SET;
            2'b11:   csr_op   = CSR_OP_CLEAR;
            default: csr_illegal = 1'b1;
          endcase

          if (instr_rdata_i[29:28] > current_priv_lvl_i) begin
            // No access to higher privilege CSR
            csr_illegal = 1'b1;
          end

          if(~csr_illegal)
            if (instr_rdata_i[31:20] == 12'h300 || instr_rdata_i[31:20] == 12'h000)
              //access to xstatus
              csr_status_o = 1'b1;

          illegal_insn_o = csr_illegal;

        end

      end

      OPCODE_FENCE: begin
        if (instr_rdata_i[14:12] == 3'b000) begin         //fence  not implement
            illegal_insn_o = 1'b0;
        end else if(instr_rdata_i[14:12] == 3'b001) begin //fence.i not implement
            illegal_insn_o = 1'b0;
        end

      end // OPCODE_FENCE:
     default: begin
       illegal_insn_o = 1'b1;
     end
    endcase

    // misaligned access was detected by the LSU
    // TODO: this section should eventually be moved out of the decoder
    if (data_misaligned_i == 1'b1)
    begin
      // only part of the pipeline is unstalled, make sure that the
      // correct operands are sent to the AGU
      alu_op_a_mux_sel_o  = OP_A_REGA_OR_FWD;
      alu_op_b_mux_sel_o  = OP_B_IMM;
      imm_b_mux_sel_o     = IMMB_PCINCR;

      // if prepost increments are used, we do not write back the
      // second address since the first calculated address was
      // the correct one
      regfile_alu_we = 1'b0;

    end else if (mult_multicycle_i) begin
      alu_op_c_mux_sel_o = OP_C_REGC_OR_FWD;
    end
  end

  // deassert we signals (in case of stalls)
  assign regfile_mem_we_o  = (deassert_we_i) ? 1'b0          : regfile_mem_we;
  assign regfile_alu_we_o  = (deassert_we_i) ? 1'b0          : regfile_alu_we;
  assign data_req_o        = (deassert_we_i) ? 1'b0          : data_req;
  assign csr_op_o          = (deassert_we_i) ? CSR_OP_NONE   : csr_op;
  assign jump_in_id_o      = (deassert_we_i) ? BRANCH_NONE   : jump_in_id;

  assign jump_in_dec_o     = jump_in_id;

endmodule // controller
