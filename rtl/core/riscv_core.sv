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
// Engineer:       Matthias Baer - baermatt@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Top level module                                           //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Top level module of the RISC-V core.                       //
//                 added APU, FPU parameter to include the APU_dispatcher     //
//                 and the FPU                                                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`include "../../rtl/core/riscv_config.sv"

import riscv_defines::*;
import riscv_package::*;

module riscv_core
#(
  parameter  N_EXT_PERF_COUNTERS =  0,
  parameter  INSTR_RDATA_WIDTH   = 32,
  parameter  RISCV_SECURE        =  1,
  parameter  RISCV_CLUSTER       =  1,
  parameter  INSTR_TLB_ENTRIES   =  4,
  parameter  DATA_TLB_ENTRIES    =  4,
  parameter  ASID_WIDTH          =  9
)
(
  // Clock and Reset
	input  logic                         	clk_i,
	input  logic                         	rst_ni,
	input  logic							clk_ila,             
	input  logic                         	clock_en_i,    // enable clock, otherwise it is gated
	input  logic                         	test_en_i,     // enable all clock gates for testing
	input  logic							ext_irq_r,
	input  logic							sft_irq_r,
	input  logic							tmr_irq_r,
  // Core ID, Cluster ID and boot address are considered more or less static
	input  logic [31:0]                  	boot_addr_i,
	input  logic [ 3:0]                  	core_id_i,
	input  logic [ 5:0]                  	cluster_id_i,

  // Instruction memory interface
	output logic                         	instr_req_o,
	input  logic                         	instr_gnt_i,
	input  logic                         	instr_rvalid_i,
	output logic [33:0]                  	instr_addr_o,
	input  logic [INSTR_RDATA_WIDTH-1:0] 	instr_rdata_i,

  // Data memory interface
	output logic                         	data_req_o,
	input  logic                         	data_gnt_i,
	input  logic                         	data_rvalid_i,
	output logic                         	data_we_o,
	output logic [3:0]                   	data_be_o,
	output logic [33:0]                  	data_addr_o,
	output logic [31:0]                  	data_wdata_o,
	input  logic [31:0]                  	data_rdata_i,
	input  logic                         	data_err_i,

  // Interrupt inputs
	input  logic                        	irq_i,                 // level sensitive IR lines
	input  logic [4:0]                   	irq_id_i,
	output logic                         	irq_ack_o,
	output logic [4:0]                   	irq_id_o,
	input  logic                         	irq_sec_i,

	output logic                         	sec_lvl_o,

  // Debug Interface
	input  logic                         	debug_req_i,
	output logic                         	debug_gnt_o,
	output logic                        	debug_rvalid_o,
	input  logic [14:0]                  	debug_addr_i,
	input  logic                         	debug_we_i,
	input  logic [31:0]                  	debug_wdata_i,
	output logic [31:0]                  	debug_rdata_o,
	output logic                         	debug_halted_o,
	input  logic                         	debug_halt_i,
	input  logic                         	debug_resume_i,

  //Debug Unit interface
	input  logic            			 	debug_mode_i,
	input  logic                         	debug_stopcycle_i,
	input  logic                        	debug_ebreakm_i,
	input  logic                         	debug_ebreaks_i,
	input  logic                         	debug_ebreaku_i,
	input  logic                         	debug_halt_new_i,
	input  logic                         	debug_step_i,
			   
	input  logic [31:0]     			 	debug_csr_dpc_i,
	input  logic [31:0]                  	debug_csr_dcsr_i,
			   
	input  logic [31:0]     			 	debug_csr_rdata_i,
	output logic [31:0]     				debug_csr_wdata_o,
	output logic [31:0]     			 	debug_csr_addr_o,
	output logic            			 	debug_csr_we_o,
	output logic							dbg_csr_set_o,
	
	output logic [31:0]     			   	debug_dpc_o,      
	output logic            			   	debug_dpc_en_o,   
	output logic            			   	debug_dcause_en_o,
	output logic [2:0]      			   	debug_dcause_o, 
	output logic                         	debug_csr_dret_o,

  // CPU Control Signals
	input  logic                         	fetch_enable_i,
	output logic                         	core_busy_o,

	input  logic [N_EXT_PERF_COUNTERS-1:0] 	ext_perf_counters_i,

	output logic                         	clk_core_o,// thought clk gate by test

  //cache control
	output logic                         	icache_en_o,
	output logic                         	dcache_en_o
	);

  logic                     instr_valid_id;
  logic [31:0]              instr_rdata_id;    // Instruction sampled inside IF stage
       
  logic [31:0]              pc_if;             // Program counter in IF stage
  logic [31:0]              pc_id;             // Program counter in ID stage
       
  logic                     clear_instr_valid;
  logic                     pc_set;
  logic [2:0]               pc_mux_id;     // Mux selector for next PC
  logic [1:0]               exc_pc_mux_id; // Mux selector for exception PC
  logic [5:0]               exc_cause;
  logic [1:0]               trap_addr_mux; //Change the bit width from 1 bit to 2 bit by **, 2018.5.10
  logic                     lsu_load_err;
  logic                     lsu_store_err;
  exception_t               mmu_data_exception;
  exception_t               mmu_fetch_exception;
  // ID performance counter signals
  logic                     is_decoding;
       
  logic                     data_misaligned;
       
  logic                     mult_multicycle;

  // Jump and branch target and decision (EX->IF)
  logic [31:0]              jump_target_id, jump_target_ex;
  logic                     branch_in_ex;
  logic                     branch_decision;
             
  logic                     ctrl_busy;
  logic                     if_busy;
  logic                     lsu_busy;
       
  logic [31:0]              pc_ex; // PC of last executed branch or p.elw

  // ALU Control
  logic                     alu_en_ex;
  logic [ALU_OP_WIDTH-1:0]  alu_operator_ex;
  logic [31:0]              alu_operand_a_ex;
  logic [31:0]              alu_operand_b_ex;
  logic [31:0]              alu_operand_c_ex;
  logic [ 1:0]              imm_vec_ext_ex;

  // Multiplier Control
  logic [ 2:0]              mult_operator_ex;
  logic [31:0]              mult_operand_a_ex;
  logic [31:0]              mult_operand_b_ex;
  logic [31:0]              mult_operand_c_ex;
  logic                     mult_en_ex;
  logic [ 1:0]              mult_signed_mode_ex;
  logic [ 4:0]              mult_imm_ex;

  // Register Write Control
  logic [5:0]               regfile_waddr_ex;
  logic                     regfile_we_ex;
  logic [5:0]               regfile_waddr_mem;        // From WB to ID
  logic                     regfile_we_mem;
  logic [5:0]               regfile_waddr_wb;        // From WB to ID
  logic                     regfile_we_wb;
  logic [31:0]              regfile_wdata_wb;
             
  logic [5:0]               regfile_alu_waddr_ex;
  logic                     regfile_alu_we_ex;
             
  logic [5:0]               regfile_alu_waddr_fw;
  logic                     regfile_alu_we_fw;
  logic [31:0]              regfile_alu_wdata_fw;

  logic [5:0]               regfile_alu_waddr_mem;
  logic                     regfile_alu_we_mem;   
  logic [31:0]              regfile_alu_wdata_mem;

  logic [5:0]               regfile_alu_waddr_wb;
  logic                     regfile_alu_we_wb;   
  logic [31:0]              regfile_alu_wdata_wb;
  // CSR control
  logic                     csr_access_ex;
  logic  [1:0]              csr_op_ex;
  logic [31:0]              mtvec, utvec;
  logic [31:0]              stvec; //add by **, for Supervisor mode, 2018.5.10
             
  logic                     csr_access;
  logic  [1:0]              csr_op;
  logic [11:0]              csr_addr;
  logic [11:0]              csr_addr_int;
  logic [31:0]              csr_rdata;
  logic [31:0]              csr_wdata;
               
  logic                     en_translation;
  logic                     en_ld_st_translation;
  PrivLvl_t                 current_priv_lvl;
  PrivLvl_t                 ld_st_priv_lvl;
  Status_t                  mstatus;
  satp_t                    satp;

  // Data Memory Control:  From ID stage (id-ex pipe) <--> load store unit
  logic                     data_we_ex;
  logic [1:0]               data_type_ex;
  logic                     data_sign_ext_ex;
  logic [1:0]               data_reg_offset_ex;
  logic                     data_req_ex;
  logic                     data_misaligned_ex;

  logic [31:0]              data_addr_mem;
  logic                     data_we_mem;        
  logic [1:0]               data_type_mem;      
  logic [31:0]              data_wdata_mem;     
  logic [1:0]               data_reg_offset_mem;
  logic                     data_sign_ext_mem;  
  logic                     data_req_mem;       
 
  logic [31:0]              lsu_rdata;

  logic                         mmu_fetch_req;
  logic                         mmu_fetch_rvalid;
  logic                         mmu_fetch_gnt;
  logic [31:0]                  mmu_fetch_addr;
  logic [INSTR_RDATA_WIDTH-1:0] mmu_fetch_rdata;

  // stall control
  logic                   halt_if;
  logic                   id_ready;
  logic                   ex_ready;
  logic                   mem_ready;
  logic                   wb_ready;

  logic                   id_valid;
  logic                   ex_valid;
  logic                   mem_valid;
  logic                   wb_valid;
  logic                   lsu_ready_mem;

  logic                   load_wfw_stall;
  logic                   lsu_successive_stall_o;
  // Signals between instruction core interface and pipe (if and id stages)
  logic                   instr_req_int;    // Id stage asserts a req to instruction core interface

  // Interrupts
  logic                   m_irq_enable,s_irq_enable,u_irq_enable;
  logic                   csr_irq_sec;
  logic [31:0]            epc;
  logic [31:0]            mie,mip;
  logic                   irq_req_happen;
  logic [31:0]            irq_req_event; 
  logic [31:0]            csr_mideleg;
           
  logic [31:0]            csr_tval;               // add by **, 2018.5.17
  logic                   csr_save_cause;
  logic                   csr_save_if;
  logic                   csr_save_id;
  logic [5:0]             csr_cause;
  logic                   csr_restore_mret_id;
  logic                   csr_restore_uret_id;
  logic                   csr_restore_sret_id;    // add by **, 2018.5.10
  logic                   debug_pc_id;  
  logic                   debug_pc_if;         
  logic                   debug_irq_cause_en;     
  logic                   debug_ebk_cause_en;
   logic                  debug_halt_cause_en;
   logic                  debug_step_cause_en;

  // Debug Unit
  logic [DBG_SETS_W-1:0]  dbg_settings;
  logic                   dbg_req;
  logic                   dbg_ack;
  logic                   dbg_stall;
  logic                   dbg_trap;
  logic                   cause_clr;
  logic					  jump_dbg;
  // Debug GPR Read Access
  logic                   dbg_reg_rreq;
  logic [ 5:0]            dbg_reg_raddr;
  logic [31:0]            dbg_reg_rdata;

  // Debug GPR Write Access
  logic                   dbg_reg_wreq;
  logic [ 5:0]            dbg_reg_waddr;
  logic [31:0]            dbg_reg_wdata;

  // Debug CSR Access
  logic                   dbg_csr_req;
  logic [11:0]            dbg_csr_addr;
  logic                   dbg_csr_we;
  logic [31:0]            dbg_csr_wdata;
           
  logic [31:0]            dbg_jump_addr;
  logic                   dbg_jump_req;

  // Performance Counters
  logic                   perf_imiss;
  logic                   perf_jump;
  logic                   perf_jr_stall;
  logic                   perf_ld_stall;

  //core busy signals
  logic                   core_ctrl_firstfetch, core_busy_int, core_busy_q;

  //Simchecker signal
  logic                   is_interrupt;

  assign is_interrupt = (pc_mux_id == PC_EXCEPTION) && (exc_pc_mux_id == EXC_PC_IRQ);

  //////////////////////////////////////////////////////////////////////////////////////////////
  //   ____ _            _      __  __                                                   _    //
  //  / ___| | ___   ___| | __ |  \/  | __ _ _ __   __ _  __ _  ___ _ __ ___   ___ _ __ | |_  //
  // | |   | |/ _ \ / __| |/ / | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '_ ` _ \ / _ \ '_ \| __| //
  // | |___| | (_) | (__|   <  | |  | | (_| | | | | (_| | (_| |  __/ | | | | |  __/ | | | |_  //
  //  \____|_|\___/ \___|_|\_\ |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_| |_| |_|\___|_| |_|\__| //
  //                                                     |___/                                //
  //////////////////////////////////////////////////////////////////////////////////////////////

  logic        clk;

  logic        clock_en;
  logic        dbg_busy;

  logic        sleeping;

  assign dbg_busy    = dbg_req | dbg_csr_req | dbg_jump_req | dbg_reg_wreq | debug_req_i;
  assign core_busy_o = core_ctrl_firstfetch ? 1'b1 : core_busy_q;

  // if we are sleeping on a barrier let's just wait on the instruction
  // interface to finish loading instructions
  assign core_busy_int = (RISCV_CLUSTER  & data_req_o) ? (if_busy ) : (if_busy | ctrl_busy | lsu_busy);

  assign clock_en      = RISCV_CLUSTER ? clock_en_i | core_busy_o | dbg_busy : irq_i | core_busy_o | dbg_busy;

  assign sleeping      = ~core_busy_o;


  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if (rst_ni == 1'b0) begin
      core_busy_q <= 1'b0;
    end else begin
      core_busy_q <= core_busy_int;
    end
  end

  // main clock gate of the core
  // generates all clocks except the one for the debug unit which is
  // independent
  cluster_clock_gating core_clock_gate_i
  (
    .clk_i     ( clk_i           ),
    .en_i      ( clock_en        ),
    .test_en_i ( test_en_i       ),
    .clk_o     ( clk             )
  );

assign clk_core_o = clk;
	
//ila_pc u_ila_pc (
//		.clk(clk_ila), // input wire clk

//		.probe0(pc_id), 					// input wire [31:0] probe0
//		.probe1(instr_rdata_id), 			// input wire [31:0] probe0
//		.probe2(data_wdata_o), 				// input wire [31:0] probe0
//		.probe3(data_rdata_i), 				// input wire [31:0] probe0
//		.probe4(data_addr_o), 				// input wire [31:0] probe0
//		.probe5(data_be_o), 				// input wire [31:0] probe0
//		.probe6(data_we_o), 				// input wire [31:0] probe0
//		.probe7(data_rvalid_i), 			// input wire [31:0] probe0
//		.probe8(data_gnt_i), 				// input wire [31:0] probe0
//		.probe9(data_req_o),				// input wire [31:0] probe0.probe5(data_be_o), // input wire [31:0] probe0
//		.probe10(instr_rdata_i), 			// input wire [31:0] probe0
//		.probe11(instr_addr_o[31:0]), 		// input wire [31:0] probe0
//		.probe12(instr_rvalid_i), 			// input wire [31:0] probe0
//		.probe13(instr_gnt_i),				// input wire [31:0] probe0
//		.probe14(instr_req_o)				// input wire [31:0] probe0
		
//	);

  //////////////////////////////////////////////////
  //   ___ _____   ____ _____  _    ____ _____    //
  //  |_ _|  ___| / ___|_   _|/ \  / ___| ____|   //
  //   | || |_    \___ \ | | / _ \| |  _|  _|     //
  //   | ||  _|    ___) || |/ ___ \ |_| | |___    //
  //  |___|_|     |____/ |_/_/   \_\____|_____|   //
  //                                              //
  //////////////////////////////////////////////////
  riscv_if_stage
  #(
   // .N_HWLP              ( N_HWLP            ),
    .RDATA_WIDTH         ( INSTR_RDATA_WIDTH )
   // .FPU                 ( FPU               )
  )
  riscv_if_stage
  (
    .clk                 ( clk               ),
    .rst_n               ( rst_ni            ),

    // boot address
    .boot_addr_i         ( boot_addr_i[31:8] ),

    // trap vector location
    .m_trap_base_addr_i  ( mtvec             ),
    .u_trap_base_addr_i  ( utvec             ),
    .s_trap_base_addr_i  ( stvec             ),        //add by **, for Supervison, 2018.5.10
    .trap_addr_mux_i     ( trap_addr_mux     ),

    // instruction request control
    .req_i               ( instr_req_int     ),

    // instruction cache interface
    .instr_req_o         ( mmu_fetch_req       ),
    .instr_addr_o        ( mmu_fetch_addr      ),
    .instr_gnt_i         ( mmu_fetch_gnt       ),
    .instr_rvalid_i      ( mmu_fetch_rvalid    ),
    .instr_rdata_i       ( mmu_fetch_rdata     ),

    // outputs to ID stage

    .instr_valid_id_o    ( instr_valid_id    ),
    .instr_rdata_id_o    ( instr_rdata_id    ),
    .pc_if_o             ( pc_if             ),
    .pc_id_o             ( pc_id             ),

    // control signals
    .clear_instr_valid_i ( clear_instr_valid ),
    .pc_set_i            ( pc_set            ),
    .exception_pc_reg_i  ( epc               ), // exception return address
    .pc_mux_i            ( pc_mux_id         ), // sel for pc multiplexer
    .exc_pc_mux_i        ( exc_pc_mux_id     ),
    .exc_vec_pc_mux_i    ( exc_cause[4:0]    ),

    // from debug unit
    .dbg_jump_addr_i     ( dbg_jump_addr     ),
    .dbg_jump_req_i      ( dbg_jump_req      ),
    .debug_csr_dpc_i     ( debug_csr_dpc_i   ),

    // Jump targets
    .jump_target_id_i    ( jump_target_id    ),
    .jump_target_ex_i    ( jump_target_ex    ),

    // pipeline stalls
    .halt_if_i           ( halt_if           ),
    .id_ready_i          ( id_ready          ),

    .if_busy_o           ( if_busy           ),
    .perf_imiss_o        ( perf_imiss        )
  );


  /////////////////////////////////////////////////
  //   ___ ____    ____ _____  _    ____ _____   //
  //  |_ _|  _ \  / ___|_   _|/ \  / ___| ____|  //
  //   | || | | | \___ \ | | / _ \| |  _|  _|    //
  //   | || |_| |  ___) || |/ ___ \ |_| | |___   //
  //  |___|____/  |____/ |_/_/   \_\____|_____|  //
  //                                             //
  /////////////////////////////////////////////////
  riscv_id_stage
  #(
    .RISCV_SECURE                 ( RISCV_SECURE         )
  )
  riscv_id_stage
  (
    .clk                          ( clk                  ),
    .rst_n                        ( rst_ni               ),

    .test_en_i                    ( test_en_i            ),

    // Processor Enable
    .fetch_enable_i               ( fetch_enable_i       ),
    .ctrl_busy_o                  ( ctrl_busy            ),
    .core_ctrl_firstfetch_o       ( core_ctrl_firstfetch ),
    .is_decoding_o                ( is_decoding          ),

    // Interface to instruction memory
    .instr_valid_i                ( instr_valid_id       ),
    .instr_rdata_i                ( instr_rdata_id       ),
    .instr_req_o                  ( instr_req_int        ),

    // Jumps and branches
    .branch_in_ex_o               ( branch_in_ex         ),
    .branch_decision_i            ( branch_decision      ),
    .jump_target_o                ( jump_target_id       ),
	.jump_out					  (	jump_dbg			 ),
    // IF and ID control signals
    .clear_instr_valid_o          ( clear_instr_valid    ),
    .pc_set_o                     ( pc_set               ),
    .pc_mux_o                     ( pc_mux_id            ),
    .exc_pc_mux_o                 ( exc_pc_mux_id        ),
    .exc_cause_o                  ( exc_cause            ),
    .trap_addr_mux_o              ( trap_addr_mux        ),

    .pc_if_i                      ( pc_if                ),
    .pc_id_i                      ( pc_id                ),

    // Stalls
    .halt_if_o                    ( halt_if              ),
    .load_wfw_stall_o             ( load_wfw_stall       ),
    .lsu_successive_stall_o       ( lsu_successive_stall ),

    .id_ready_o                   ( id_ready             ),
    .ex_ready_i                   ( ex_ready             ),
    .wb_ready_i                   ( wb_ready             ),

    .id_valid_o                   ( id_valid             ),
    .ex_valid_i                   ( ex_valid             ),
    .mem_valid_i                  ( mem_valid            ),
    .lsu_ready_mem_i              ( lsu_ready_mem        ),

    // From the Pipeline ID/EX
    .pc_ex_o                      ( pc_ex                ),

    .alu_en_ex_o                  ( alu_en_ex            ),
    .alu_operator_ex_o            ( alu_operator_ex      ),
    .alu_operand_a_ex_o           ( alu_operand_a_ex     ),
    .alu_operand_b_ex_o           ( alu_operand_b_ex     ),
    .alu_operand_c_ex_o           ( alu_operand_c_ex     ),
    .imm_vec_ext_ex_o             ( imm_vec_ext_ex       ),

    .regfile_waddr_ex_o           ( regfile_waddr_ex     ),
    .regfile_we_ex_o              ( regfile_we_ex        ),

    .regfile_alu_we_ex_o          ( regfile_alu_we_ex    ),
    .regfile_alu_waddr_ex_o       ( regfile_alu_waddr_ex ),

    // MUL
    .mult_operator_ex_o           ( mult_operator_ex     ), // from ID to EX stage
    .mult_en_ex_o                 ( mult_en_ex           ), // from ID to EX stage
    .mult_signed_mode_ex_o        ( mult_signed_mode_ex  ), // from ID to EX stage
    .mult_operand_a_ex_o          ( mult_operand_a_ex    ), // from ID to EX stage
    .mult_operand_b_ex_o          ( mult_operand_b_ex    ), // from ID to EX stage
    .mult_operand_c_ex_o          ( mult_operand_c_ex    ), // from ID to EX stage
    .mult_imm_ex_o                ( mult_imm_ex          ), // from ID to EX stage

    // CSR ID/EX
    .csr_access_ex_o              ( csr_access_ex        ),
    .csr_op_ex_o                  ( csr_op_ex            ),
    .current_priv_lvl_i           ( current_priv_lvl     ),
    .csr_irq_sec_o                ( csr_irq_sec          ),
    .csr_cause_o                  ( csr_cause            ),
    .csr_save_if_o                ( csr_save_if          ), // control signal to save pc
    .csr_save_id_o                ( csr_save_id          ), // control signal to save pc
    .csr_restore_mret_id_o        ( csr_restore_mret_id  ), // control signal to restore pc
    .csr_restore_uret_id_o        ( csr_restore_uret_id  ), // control signal to restore pc
    .csr_restore_sret_id_o        ( csr_restore_sret_id  ), // control signal to restore pc //add by **m, 2018.5.10
    .csr_restore_dret_id_o        ( debug_csr_dret_o     ),
    .csr_save_cause_o             ( csr_save_cause       ),
    .csr_tval_o                   ( csr_tval             ), // add by **, 2018.5.17
    .debug_pc_id_o                ( debug_pc_id          ),  
    .debug_pc_if_o                ( debug_pc_if          ),       
    .debug_irq_cause_en_o         ( debug_irq_cause_en   ),      
    .debug_ebk_cause_en_o         ( debug_ebk_cause_en   ),
    .debug_halt_cause_en_o        (debug_halt_cause_en),
    .debug_step_cause_en_o        (debug_step_cause_en),

    // LSU
    .data_req_ex_o                ( data_req_ex          ), 
    .data_we_ex_o                 ( data_we_ex           ), 
    .data_type_ex_o               ( data_type_ex         ), 
    .data_sign_ext_ex_o           ( data_sign_ext_ex     ), 
    .data_reg_offset_ex_o         ( data_reg_offset_ex   ), 

    .data_misaligned_ex_o         ( data_misaligned_ex   ), 
    .data_misaligned_i            ( 1'b0      ),

    .data_req_mem_i               ( data_req_mem          ),

    // Interrupt Signals
    .irq_i                        ( irq_i                ), // incoming interrupts
    .irq_sec_i                    ( (RISCV_SECURE) ? irq_sec_i : 1'b0 ),
    .irq_id_i                     ( irq_id_i             ),
    .m_irq_enable_i               ( m_irq_enable         ),
    .s_irq_enable_i               ( s_irq_enable         ),
    .u_irq_enable_i               ( u_irq_enable         ),
    .mip_i                        ( mip                  ),
    .mie_i                        ( mie                  ),
    .csr_mideleg_i                ( csr_mideleg          ),
    .irq_ack_o                    ( irq_ack_o            ),
    .irq_id_o                     ( irq_id_o             ),
    .irq_req_happen_o             ( irq_req_happen       ), 
    .irq_req_event_o              ( irq_req_event        ),  

    .lsu_load_err_i               ( lsu_load_err         ),
    .lsu_store_err_i              ( lsu_store_err        ),

    //from mmu exc £¬2018.5.18
    .mmu_data_exception_i         ( mmu_data_exception   ),
    .mmu_fetch_exception_i        ( mmu_fetch_exception  ),

    // Debug Unit Signals
    .dbg_settings_i               ( dbg_settings         ),
    .dbg_req_i                    ( dbg_req              ),
    .dbg_ack_o                    ( dbg_ack              ),
    .dbg_stall_i                  ( dbg_stall            ),
    .dbg_trap_o                   ( dbg_trap             ),

    .dbg_reg_rreq_i               ( dbg_reg_rreq         ),
    .dbg_reg_raddr_i              ( dbg_reg_raddr        ),
    .dbg_reg_rdata_o              ( dbg_reg_rdata        ),

    .dbg_reg_wreq_i               ( dbg_reg_wreq         ),
    .dbg_reg_waddr_i              ( dbg_reg_waddr        ),
    .dbg_reg_wdata_i              ( dbg_reg_wdata        ),

    .dbg_jump_req_i               ( dbg_jump_req         ),
	
    //Debug Unit
    .debug_mode_i            		  ( debug_mode_i        ),
    .debug_ebreakm_i              ( debug_ebreakm_i     ),
    .debug_ebreaku_i              ( debug_ebreaku_i     ),
    .debug_ebreaks_i              ( debug_ebreaks_i     ),
    .debug_halt_new_i                 (debug_halt_new_i),
    .debug_step_i                 (debug_step_i),
	.cause_clr_o				  (cause_clr			),
    // Forward Signals from ex stage
    .regfile_alu_waddr_fw_i       ( regfile_alu_waddr_fw ),
    .regfile_alu_we_fw_i          ( regfile_alu_we_fw    ),
    .regfile_alu_wdata_fw_i       ( regfile_alu_wdata_fw ),

    .regfile_alu_wdata_mem_i      ( regfile_alu_wdata_mem ), // Write address ex-wb pipeline
    .regfile_alu_we_mem_i         ( regfile_alu_we_mem    ), // write enable for the register file  
    .regfile_alu_waddr_mem_i      ( regfile_alu_waddr_mem ), // write data to commit in the register file

    //from wb stage
    .regfile_alu_wdata_wb_i       ( regfile_alu_wdata_wb ), // Write address ex-wb pipeline
    .regfile_alu_we_wb_i          ( regfile_alu_we_wb    ), // write enable for the register file  
    .regfile_alu_waddr_wb_i       ( regfile_alu_waddr_wb ), // write data to commit in the register file
       
    .regfile_waddr_wb_i           ( regfile_waddr_wb     ),    
    .regfile_we_wb_i              ( regfile_we_wb        ),     
    .regfile_wdata_wb_i           ( regfile_wdata_wb     ), 

    .regfile_waddr_mem_i          ( regfile_waddr_mem    ),    
    .regfile_we_mem_i             ( regfile_we_mem       ),  
    // from ALU
    .mult_multicycle_i            ( mult_multicycle      ),

    // Performance Counters
    .perf_jump_o                  ( perf_jump            ),
    .perf_jr_stall_o              ( perf_jr_stall        ),
    .perf_ld_stall_o              ( perf_ld_stall        )
  );


  /////////////////////////////////////////////////////
  //   _______  __  ____ _____  _    ____ _____      //
  //  | ____\ \/ / / ___|_   _|/ \  / ___| ____|     //
  //  |  _|  \  /  \___ \ | | / _ \| |  _|  _|       //
  //  | |___ /  \   ___) || |/ ___ \ |_| | |___      //
  //  |_____/_/\_\ |____/ |_/_/   \_\____|_____|     //
  //                                                 //
  /////////////////////////////////////////////////////
  riscv_ex_stage_fpga u_riscv_ex_stage
  (
    // Global signals: Clock and active low asynchronous reset
    .clk                        ( clk                          ),
    .rst_n                      ( rst_ni                       ),

    // Alu signals from ID stage
    .alu_en_i                   ( alu_en_ex                    ),
    .alu_operator_i             ( alu_operator_ex              ), // from ID/EX pipe registers
    .alu_operand_a_i            ( alu_operand_a_ex             ), // from ID/EX pipe registers
    .alu_operand_b_i            ( alu_operand_b_ex             ), // from ID/EX pipe registers
    .alu_operand_c_i            ( alu_operand_c_ex             ), // from ID/EX pipe registers
    .imm_vec_ext_i              ( imm_vec_ext_ex               ), // from ID/EX pipe registers

    // Multipler
    .mult_operator_i            ( mult_operator_ex             ), // from ID/EX pipe registers
    .mult_operand_a_i           ( mult_operand_a_ex            ), // from ID/EX pipe registers
    .mult_operand_b_i           ( mult_operand_b_ex            ), // from ID/EX pipe registers
    .mult_operand_c_i           ( mult_operand_c_ex            ), // from ID/EX pipe registers
    .mult_en_i                  ( mult_en_ex                   ), // from ID/EX pipe registers
    //.mult_sel_subword_i         ( mult_sel_subword_ex          ), // from ID/EX pipe registers
    .mult_signed_mode_i         ( mult_signed_mode_ex          ), // from ID/EX pipe registers
    .mult_imm_i                 ( mult_imm_ex                  ), // from ID/EX pipe registers

    .mult_multicycle_o          ( mult_multicycle              ), // to ID/EX pipe registers

    // interface with CSRs
    .csr_access_i               ( csr_access_ex                ),
    .csr_rdata_i                ( csr_rdata                    ),

    //through to MEM stage
    .data_we_ex_i               ( data_we_ex                   ),
    .data_type_ex_i             ( data_type_ex                 ),
    .data_wdata_ex_i            ( alu_operand_c_ex             ),
    .data_reg_offset_ex_i       ( data_reg_offset_ex           ),
    .data_sign_ext_ex_i         ( data_sign_ext_ex             ),  // sign extension
    .data_req_ex_i              ( data_req_ex                  ),
 
    // From ID Stage: Regfile control signals
    .branch_in_ex_i             ( branch_in_ex                 ),
    .regfile_alu_waddr_i        ( regfile_alu_waddr_ex         ),
    .regfile_alu_we_i           ( regfile_alu_we_ex            ),

    .regfile_waddr_i            ( regfile_waddr_ex             ),
    .regfile_we_i               ( regfile_we_ex                ),

    // To IF: Jump and branch target and decision
    .jump_target_o              ( jump_target_ex               ),
    .branch_decision_o          ( branch_decision              ),

    // To ID stage: Forwarding signals
    .regfile_alu_waddr_fw_o     ( regfile_alu_waddr_fw         ),
    .regfile_alu_we_fw_o        ( regfile_alu_we_fw            ),
    .regfile_alu_wdata_fw_o     ( regfile_alu_wdata_fw         ),

    // Output of EX stage pipeline
    .regfile_alu_wdata_mem_o    ( regfile_alu_wdata_mem        ),
    .regfile_alu_we_mem_o       ( regfile_alu_we_mem           ), 
    .regfile_alu_waddr_mem_o    ( regfile_alu_waddr_mem        ),
   
    .regfile_waddr_mem_o        ( regfile_waddr_mem            ),
    .regfile_we_mem_o           ( regfile_we_mem               ),
 
    .data_addr_mem_o            ( data_addr_mem                ),
    .data_we_mem_o              ( data_we_mem                  ),   // write enable                      -> to LSU
    .data_type_mem_o            ( data_type_mem                ),   // Data type word, halfword, byte    -> to LSU
    .data_wdata_mem_o           ( data_wdata_mem               ),   // data to write to memory           -> to LSU
    .data_reg_offset_mem_o      ( data_reg_offset_mem          ),   // offset inside register for stores -> to LSU
    .data_sign_ext_mem_o        ( data_sign_ext_mem            ),   // sign extension                    -> to LSU
    .data_req_mem_o             ( data_req_mem                 ),   // data request                      -> to LSU
 
    // stall control 
    .load_wfw_stall_i           ( load_wfw_stall               ),
    .lsu_successive_stall_i     ( lsu_successive_stall         ),
    .ex_ready_o                 ( ex_ready                     ),
    .ex_valid_o                 ( ex_valid                     ),
    .wb_ready_i                 ( wb_ready                     ),
    .mem_ready_i                ( mem_ready                    )
  );
/////////////////////////////////////////////////////////////
//
//
//mem
//
//
////////////////////////////////////////////////////////////

riscv_mem_stage 
  #(
    .INSTR_TLB_ENTRIES      ( INSTR_TLB_ENTRIES   ),
    .DATA_TLB_ENTRIES       ( DATA_TLB_ENTRIES    ),
    .ASID_WIDTH             ( ASID_WIDTH          ),
    .INSTR_RDATA_WIDTH      ( INSTR_RDATA_WIDTH   )

  ) riscv_mem_stage (

    .clk                    ( clk                 ),
    .rst_n                  ( rst_ni              ),

    // signal from mem stage
    .data_req_mem_i         ( data_req_mem        ),
    .data_addr_mem_i        ( data_addr_mem       ),       // data request addr                 -> from mem stage

    .data_we_mem_i          ( data_we_mem         ),
    .data_type_mem_i        ( data_type_mem       ),
    .data_wdata_mem_i       ( data_wdata_mem   ),
    .data_reg_offset_mem_i  ( data_reg_offset_mem ),
    .data_sign_ext_mem_i    ( data_sign_ext_mem   ),       // sign extension

    .regfile_waddr_mem_i    ( regfile_waddr_mem   ),       //we to reg addr for lsu
    .regfile_we_mem_i       ( regfile_we_mem      ),       //we to reg en for lsu
        
    .regfile_alu_wdata_mem_i(regfile_alu_wdata_mem),       //wb to reg's data for alu/multi
    .regfile_alu_we_mem_i   (regfile_alu_we_mem   ),       //wb to reg's en for alu/multi
    .regfile_alu_waddr_mem_i(regfile_alu_waddr_mem),       //wb to reg's addr for alu/multi

    //to wb stage
    .regfile_alu_wdata_wb_o ( regfile_alu_wdata_wb),
    .regfile_alu_we_wb_o    ( regfile_alu_we_wb   ),   
    .regfile_alu_waddr_wb_o ( regfile_alu_waddr_wb),

    .regfile_waddr_wb_o     ( regfile_waddr_wb    ),    
    .regfile_we_wb_o        ( regfile_we_wb       ),     
    .regfile_wdata_wb_o     ( regfile_wdata_wb    ), 
 
    //**
    .data_misaligned_ex_i  ( 1'b0 ),    // misaligned access in last ld/st   -> from ID/EX pipeline
    .data_misaligned_o      (),    // misaligned access was detected    -> to controller

    // exception signals
    .load_err_o             ( lsu_load_err       ),
    .store_err_o            ( lsu_store_err      ),

    // stall signal
    .mem_ready_o            ( mem_ready           ),
    .mem_valid_o            ( mem_valid           ),
    .wb_ready_o             ( wb_ready            ),
    .wb_valid_o             ( wb_valid            ),
    .lsu_ready_mem_o        ( lsu_ready_mem       ),
    .busy_o                 ( lsu_busy            ),   

    .enable_translation_i   ( en_translation      ),
    .en_ld_st_translation_i ( en_ld_st_translation),     // enable virtual memory translation for load/stores
 
    // IF interface 
    .fetch_req_i            ( mmu_fetch_req       ),
    .fetch_gnt_o            ( mmu_fetch_gnt       ),
    .fetch_valid_o          ( mmu_fetch_rvalid    ),
    .fetch_vaddr_i          ( mmu_fetch_addr      ),
    .fetch_rdata_o          ( mmu_fetch_rdata     ),     // pass-through because of interfaces
    .fetch_ex_o             ( mmu_fetch_exception ),     // write-back fetch exceptions (e.g.: bus faults, page faults, etc.)

    // if we need to walk the page table we can't grant in the same cycle
    // Cycle 0
    .lsu_dtlb_hit_o         (),   // sent in the same cycle as the request if translation hits in the DTLB
    .lsu_exception_o        ( mmu_data_exception),  // address translation threw an exception

    // General control signals
    .priv_lvl_i             ( current_priv_lvl  ),
    .ld_st_priv_lvl_i       ( ld_st_priv_lvl    ),
    .sum_i                  ( mstatus.sum       ),
    .mxr_i                  ( mstatus.mxr       ),
 
    // input logic flag_mprv_i,  
    .satp_ppn_i             ( satp.ppn          ),
    .asid_i                 ( satp.asid         ),
    .flush_tlb_i            ( 1'b0              ),

    // Performance counters 
    .itlb_miss_o            ( ),
    .dtlb_miss_o            ( ),

    // Memory interfaces
    // Instruction memory/cache
    .instr_if_address_o     ( instr_addr_o      ),
    .instr_if_data_req_o    ( instr_req_o       ),
    .instr_if_data_gnt_i    ( instr_gnt_i       ),
    .instr_if_data_rvalid_i ( instr_rvalid_i    ), 
    .instr_if_data_rdata_i  ( instr_rdata_i     ),

    // Data memory/cache
    .data_addr_o            ( data_addr_o       ),
    .data_wdata_o           ( data_wdata_o      ),
    .data_req_o             ( data_req_o        ),
    .data_we_o              ( data_we_o         ),
    .data_be_o              ( data_be_o         ),
    .data_size_o            ( ),     
    .tag_valid_o            ( ),    
    .data_gnt_i             ( data_gnt_i        ),
    .data_rvalid_i          ( data_rvalid_i     ),
    .data_rdata_i           ( data_rdata_i      )
);


  //////////////////////////////////////
  //        ____ ____  ____           //
  //       / ___/ ___||  _ \ ___      //
  //      | |   \___ \| |_) / __|     //
  //      | |___ ___) |  _ <\__ \     //
  //       \____|____/|_| \_\___/     //
  //                                  //
  //   Control and Status Registers   //
  //////////////////////////////////////
	logic set_mie;

	assign set_mie = (instr_addr_o == boot_addr_i) ? 'b1 : 'b0;
  riscv_cs_registers
  #(
    .N_EXT_CNT       ( N_EXT_PERF_COUNTERS   )
  )
  riscv_cs_registers
  (
    .clk                     ( clk                ),
    .rst_n                   ( rst_ni             ),
	.ext_irq_r(ext_irq_r),
	.sft_irq_r(0),
	.tmr_irq_r(tmr_irq_r),
    // Core and Cluster ID from outside
    .core_id_i               ( core_id_i          ),
    .cluster_id_i            ( cluster_id_i       ),
    .mtvec_o                 ( mtvec              ),
    .utvec_o                 ( utvec              ),
    .stvec_o                 ( stvec              ),   //add for SUPERVISOR  Mode by **, 2018.5.10
    // boot address
    .boot_addr_i             ( boot_addr_i[31:8]  ),
	.set_mie_i					(set_mie),
    // Interface to CSRs (SRAM like)
    .csr_access_i            ( csr_access         ),
    .csr_addr_i              ( csr_addr           ),
    .csr_wdata_i             ( csr_wdata          ),
    .csr_op_i                ( csr_op             ),
    .csr_rdata_o             ( csr_rdata          ),
    ////Debug Unit interface
    .debug_mode_i            ( debug_mode_i       ),
    .debug_stopcycle_i       ( debug_stopcycle_i  ),
    .debug_csr_dcsr_i        ( debug_csr_dcsr_i   ),
	  .debug_csr_dpc_i         ( debug_csr_dpc_i    ),
	  .debug_csr_rdata_i       ( debug_csr_rdata_i  ),
	  .debug_csr_wdata_o       ( debug_csr_wdata_o  ),
	  .debug_csr_addr_o        ( debug_csr_addr_o   ),
	  .debug_csr_we_o          ( debug_csr_we_o     ),
	  .dbg_csr_set_o			(dbg_csr_set_o		),
	  .debug_dpc_o             ( debug_dpc_o        ),      
	  .debug_dpc_en_o          ( debug_dpc_en_o     ),   
	  .debug_dcause_en_o       ( debug_dcause_en_o  ),
	  .debug_dcause_o          ( debug_dcause_o     ), 
	  .jump_dbg_i			   ( jump_dbg			),
	  .jump_target_i		   ( jump_target_id		),
    // Interrupt related control signals
    .m_irq_enable_o          ( m_irq_enable       ),
    .s_irq_enable_o          ( s_irq_enable       ),
    .u_irq_enable_o          ( u_irq_enable       ),
    .mip_o                   ( mip                ),
    .mie_o                   ( mie                ),
    .mideleg_o               ( csr_mideleg        ),
    .csr_irq_sec_i           ( csr_irq_sec        ),
    .irq_req_happen_i        ( irq_req_happen     ),
    .irq_req_event_i         ( irq_req_event      ),
    .sec_lvl_o               ( sec_lvl_o          ),
    .epc_o                   ( epc                ),
    .priv_lvl_o              ( current_priv_lvl   ),

    .pc_if_i                 ( pc_if              ),
    .pc_id_i                 ( pc_id              ), // from IF stage

    .csr_save_if_i           ( csr_save_if        ),
    .csr_save_id_i           ( csr_save_id        ),
    .csr_restore_mret_i      ( csr_restore_mret_id ),
    .csr_restore_uret_i      ( csr_restore_uret_id ),
    .csr_restore_sret_i      ( csr_restore_sret_id ), // add by **, 2018.5.10
    .csr_restore_dret_i      ( debug_csr_dret_o    ),
    .csr_cause_i             ( csr_cause          ),
    .csr_save_cause_i        ( csr_save_cause     ),
    .csr_tval_i              ( csr_tval           ),  // add by **, 2018.5.17

    .debug_pc_id_i           ( debug_pc_id        ),   
    .debug_pc_if_i           ( debug_pc_if        ),       
    .debug_irq_cause_en_i    ( debug_irq_cause_en ),     
    .debug_ebk_cause_en_i    ( debug_ebk_cause_en ),
    .debug_halt_cause_en_i   (debug_halt_cause_en),
    .debug_step_cause_en_i   (debug_step_cause_en),
	.cause_clr_i			   ( cause_clr			),

    // performance counter related signals
    .id_valid_i              ( id_valid           ),
    .is_decoding_i           ( is_decoding        ),

    .imiss_i                 ( perf_imiss         ),
    .pc_set_i                ( pc_set             ),
    .jump_i                  ( perf_jump          ),
    .branch_i                ( branch_in_ex       ),
    .branch_taken_i          ( branch_decision    ),
    .ld_stall_i              ( perf_ld_stall      ),
    .jr_stall_i              ( perf_jr_stall      ),

    .mem_load_i              ( data_req_o & data_gnt_i & (~data_we_o) ),
    .mem_store_i             ( data_req_o & data_gnt_i & data_we_o    ),

    .ext_counters_i          ( ext_perf_counters_i                    ),
    //output add by **, for mmu, 2018.5.11
    .en_translation_o        (en_translation      ),
    .ld_st_priv_lvl_o        (ld_st_priv_lvl      ),
    .en_ld_st_translation_o  (en_ld_st_translation),
    .mstatus_o               (mstatus),
    .satp_o                  (satp),

    //cache control
    .icache_en_o             ( icache_en_o        ),
    .dcache_en_o             ( dcache_en_o        )
  );

  // Mux for CSR access through Debug Unit
  assign csr_access   = (dbg_csr_req == 1'b0) ? csr_access_ex    : 1'b1;
  assign csr_addr     = (dbg_csr_req == 1'b0) ? csr_addr_int     : dbg_csr_addr;
  assign csr_wdata    = (dbg_csr_req == 1'b0) ? alu_operand_a_ex : dbg_csr_wdata;
  assign csr_op       = (dbg_csr_req == 1'b0) ? csr_op_ex
                                              : (dbg_csr_we == 1'b1 ? CSR_OP_WRITE
                                                                    : CSR_OP_NONE );
  assign csr_addr_int = csr_access_ex ? alu_operand_b_ex[11:0] : '0;


  /////////////////////////////////////////////////////////////
  //  ____  _____ ____  _   _  ____   _   _ _   _ ___ _____  //
  // |  _ \| ____| __ )| | | |/ ___| | | | | \ | |_ _|_   _| //
  // | | | |  _| |  _ \| | | | |  _  | | | |  \| || |  | |   //
  // | |_| | |___| |_) | |_| | |_| | | |_| | |\  || |  | |   //
  // |____/|_____|____/ \___/ \____|  \___/|_| \_|___| |_|   //
  //                                                         //
  /////////////////////////////////////////////////////////////

  riscv_debug_unit riscv_debug_unit
  (
    .clk               ( clk_i              ), // always-running clock for debug
    .rst_n             ( rst_ni             ),

    // Debug Interface
    .debug_req_i       ( debug_req_i        ),
    .debug_gnt_o       ( debug_gnt_o        ),
    .debug_rvalid_o    ( debug_rvalid_o     ),
    .debug_addr_i      ( debug_addr_i       ),
    .debug_we_i        ( debug_we_i         ),
    .debug_wdata_i     ( debug_wdata_i      ),
    .debug_rdata_o     ( debug_rdata_o      ),
    .debug_halt_i      ( debug_halt_i       ),
    .debug_resume_i    ( debug_resume_i     ),
    .debug_halted_o    ( debug_halted_o     ),

    // To/From Core
    .settings_o        ( dbg_settings       ),
    .trap_i            ( dbg_trap           ),
    .exc_cause_i       ( exc_cause          ),
    .stall_o           ( dbg_stall          ),
    .dbg_req_o         ( dbg_req            ),
    .dbg_ack_i         ( dbg_ack            ),

    // register file read port
    .regfile_rreq_o    ( dbg_reg_rreq       ),
    .regfile_raddr_o   ( dbg_reg_raddr      ),
    .regfile_rdata_i   ( dbg_reg_rdata      ),

    // register file write port
    .regfile_wreq_o    ( dbg_reg_wreq       ),
    .regfile_waddr_o   ( dbg_reg_waddr      ),
    .regfile_wdata_o   ( dbg_reg_wdata      ),

    // CSR read/write port
    .csr_req_o         ( dbg_csr_req        ),
    .csr_addr_o        ( dbg_csr_addr       ),
    .csr_we_o          ( dbg_csr_we         ),
    .csr_wdata_o       ( dbg_csr_wdata      ),
    .csr_rdata_i       ( csr_rdata          ),

    // signals for PPC and NPC
    .pc_if_i           ( pc_if              ), // from IF stage
    .pc_id_i           ( pc_id              ), // from IF stage
    .pc_ex_i           ( pc_ex              ), // PC of last executed branch (in EX stage) or p.elw
 
    .data_load_event_i ( 1'b0 ),
    .instr_valid_id_i  ( instr_valid_id     ),

    .sleeping_i        ( sleeping           ),

    .branch_in_ex_i    ( branch_in_ex       ),
    .branch_taken_i    ( branch_decision    ),

    .jump_addr_o       ( dbg_jump_addr      ), // PC from debug unit
    .jump_req_o        ( dbg_jump_req       )  // set PC to new value
  );

`ifndef VERILATOR
`ifdef TRACE_EXECUTION
  riscv_tracer riscv_tracer
  (
    .clk            ( clk_i                                ), // always-running clock for tracing
    .rst_n          ( rst_ni                               ),

    .fetch_enable   ( fetch_enable_i                       ),
    .core_id        ( core_id_i                            ),
    .cluster_id     ( cluster_id_i                         ),

    .pc             ( id_stage_i.pc_id_i                   ),
    .instr          ( id_stage_i.instr                     ),
    .compressed     ( id_stage_i.is_compressed_i           ),
    .id_valid       ( id_stage_i.id_valid_o                ),
    .is_decoding    ( id_stage_i.is_decoding_o             ),
    .pipe_flush     ( id_stage_i.controller_i.pipe_flush_i ),
    .mret           ( id_stage_i.controller_i.mret_insn_i  ),
    .uret           ( id_stage_i.controller_i.uret_insn_i  ),
    .ecall          ( id_stage_i.controller_i.ecall_insn_i ),
    .ebreak         ( id_stage_i.controller_i.ebrk_insn_i  ),
    .rs1_value      ( id_stage_i.operand_a_fw_id           ),
    .rs2_value      ( id_stage_i.operand_b_fw_id           ),
    .rs3_value      ( id_stage_i.alu_operand_c             ),
    .rs2_value_vec  ( id_stage_i.alu_operand_b             ),

    .rs1_is_fp      ( id_stage_i.regfile_fp_a              ),
    .rs2_is_fp      ( id_stage_i.regfile_fp_b              ),
    .rs3_is_fp      ( id_stage_i.regfile_fp_c              ),
    .rd_is_fp       ( id_stage_i.regfile_fp_d              ),

    .ex_valid       ( ex_valid                             ),
    .ex_reg_addr    ( regfile_alu_waddr_fw                 ),
    .ex_reg_we      ( regfile_alu_we_fw                    ),
    .ex_reg_wdata   ( regfile_alu_wdata_fw                 ),

    .ex_data_addr   ( data_addr_o                          ),
    .ex_data_req    ( data_req_o                           ),
    .ex_data_gnt    ( data_gnt_i                           ),
    .ex_data_we     ( data_we_o                            ),
    .ex_data_wdata  ( data_wdata_o                         ),

    .wb_bypass      ( ex_stage_i.branch_in_ex_i            ),

    .wb_valid       ( wb_valid                             ),
    .wb_reg_addr    ( regfile_waddr_wb_o                   ),
    .wb_reg_we      ( regfile_we_wb                        ),
    .wb_reg_wdata   ( regfile_wdata_wb_o                   ),

    .imm_u_type     ( id_stage_i.imm_u_type                ),
    .imm_uj_type    ( id_stage_i.imm_uj_type               ),
    .imm_i_type     ( id_stage_i.imm_i_type                ),
    .imm_iz_type    ( id_stage_i.imm_iz_type[11:0]         ),
    .imm_z_type     ( id_stage_i.imm_z_type                ),
    .imm_s_type     ( id_stage_i.imm_s_type                ),
    .imm_sb_type    ( id_stage_i.imm_sb_type               ),
    .imm_s2_type    ( id_stage_i.imm_s2_type               ),
    .imm_s3_type    ( id_stage_i.imm_s3_type               ),
    .imm_vs_type    ( id_stage_i.imm_vs_type               ),
    .imm_vu_type    ( id_stage_i.imm_vu_type               ),
    .imm_shuffle_type ( id_stage_i.imm_shuffle_type        ),
    .imm_clip_type  ( id_stage_i.instr_rdata_i[11:7]       )
  );
`endif
`endif
endmodule
