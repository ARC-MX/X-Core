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
// Engineer:       Sven Stucki - svstucki@student.ethz.ch                     //
//                                                                            //
// Additional contributions by:                                               //
//                 Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Control and Status Registers                               //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Control and Status Registers (CSRs) loosely following the  //
//                 RiscV draft priviledged instruction set spec (v1.9)        //
//                 Added Floating point support                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////
// Based on PULP RISCV Core by perfxlab
// RSIC V top module 
// 2018/5/26
/////////////////////////////////////////////////

import riscv_defines::*;
import riscv_package::*;

`ifndef RISCV_FPGA_EMUL
 `ifdef SYNTHESIS
  `define ASIC_SYNTHESIS
 `endif
`endif

module riscv_cs_registers
#(
  parameter N_EXT_CNT    = 0, 
  parameter ASID_WIDTH   = 1
)
(
  // Clock and Reset
  input  logic            clk,
  input  logic            rst_n,
  
input  ext_irq_r,
  input  sft_irq_r,
  input  tmr_irq_r,
  
  // Core and Cluster ID
  input  logic  [3:0]     core_id_i,
  input  logic  [5:0]     cluster_id_i,
  output logic [31:0]     mtvec_o,
  output logic [31:0]     utvec_o, 
  output logic [31:0]     stvec_o, //add for SUPERVISOR  Mode by **, 2018.5.10

  // Used for boot address
  input  logic [23:0]     boot_addr_i,
  input 	logic 				set_mie_i, // --zhou 
  // Interface to registers (SRAM like)
  input  logic            csr_access_i,
  input  logic [11:0]     csr_addr_i,
  input  logic [31:0]     csr_wdata_i,
  input  logic  [1:0]     csr_op_i,
  output logic [31:0]     csr_rdata_o,

  //Debug Unit interface
  input  logic            debug_mode_i,
  input  logic            debug_stopcycle_i,

  input  logic [31:0]     debug_csr_dpc_i,
  input  logic [31:0]     debug_csr_dcsr_i,

  input  logic [31:0]     debug_csr_rdata_i,
  output logic [31:0]     debug_csr_wdata_o,
  output logic [31:0]     debug_csr_addr_o,
  output logic            debug_csr_we_o,
  output logic 			  dbg_csr_set_o,
  output logic [31:0]     debug_dpc_o,      
  output logic            debug_dpc_en_o,   
  output logic            debug_dcause_en_o,
  output logic [2:0]      debug_dcause_o,  
  input	 logic 			  jump_dbg_i,
  input  logic [31:0] 	  jump_target_i,
  // Interrupts
  output logic            m_irq_enable_o,
  output logic            s_irq_enable_o,
  output logic            u_irq_enable_o,
  output logic [31:0]     mip_o,
  output logic [31:0]     mie_o,
  output logic [31:0]     mideleg_o,
  //csr_irq_sec_i is always 0 if RISCV_SECURE is zero
  input  logic            irq_req_happen_i,
  input  logic [31:0]     irq_req_event_i,
  input  logic            csr_irq_sec_i,
  output logic            sec_lvl_o,
  output logic [31:0]     epc_o,
  output PrivLvl_t        priv_lvl_o,

  input  logic [31:0]     pc_if_i,
  input  logic [31:0]     pc_id_i,
  input  logic            csr_save_if_i,
  input  logic            csr_save_id_i,
  input  logic            csr_restore_mret_i,
  input  logic            csr_restore_uret_i,
  input  logic            csr_restore_sret_i,
  input  logic            csr_restore_dret_i,
  //coming from controller
  input  logic [5:0]      csr_cause_i, 

  input  logic            debug_pc_id_i,  
  input  logic            debug_pc_if_i,              
  input  logic            debug_irq_cause_en_i,            
  input  logic            debug_ebk_cause_en_i,
  input  logic            debug_halt_cause_en_i,
  input  logic            debug_step_cause_en_i,
  input  logic  		  cause_clr_i,

  //coming from controller
  input  logic            csr_save_cause_i,
  input  logic [31:0]     csr_tval_i,              //add by **,2018.5.17

 
  // Performance Counters
  input  logic                 id_valid_i,        // ID stage is done 
  input  logic                 is_decoding_i,     // controller is in DECODE state

  input  logic                 imiss_i,           // instruction fetch
  input  logic                 pc_set_i,          // pc was set to a new value
  input  logic                 jump_i,            // jump instruction seen   (j, jr, jal, jalr)
  input  logic                 branch_i,          // branch instruction seen (bf, bnf)
  input  logic                 branch_taken_i,    // branch was taken
  input  logic                 ld_stall_i,        // load use hazard
  input  logic                 jr_stall_i,        // jump register use hazard

  input  logic                 mem_load_i,        // load from memory in this cycle
  input  logic                 mem_store_i,       // store to memory in this cycle

  input  logic [N_EXT_CNT-1:0] ext_counters_i,

  //MMU protect, add by **, 2018.5.11
  output logic                 en_translation_o,
  output PrivLvl_t             ld_st_priv_lvl_o,
  output logic                 en_ld_st_translation_o,
  output Status_t              mstatus_o,
  output satp_t                satp_o,

  //cache control
  output logic                 icache_en_o,
  output logic                 dcache_en_o
);

 //localparam N_APU_CNT       = (APU==1) ? 4 : 0;
  localparam N_PERF_COUNTERS = 12 + N_EXT_CNT ;//+ N_APU_CNT;

  localparam PERF_EXT_ID   = 11;
  //localparam PERF_APU_ID   = PERF_EXT_ID + 1 + N_EXT_CNT;


`ifdef ASIC_SYNTHESIS
  localparam N_PERF_REGS     = 1;
`else
  localparam N_PERF_REGS     = N_PERF_COUNTERS;
`endif

  `define MSTATUS_UIE_BITS        0
  `define MSTATUS_SIE_BITS        1
  `define MSTATUS_MIE_BITS        3
  `define MSTATUS_UPIE_BITS       4
  `define MSTATUS_SPIE_BITS       5
  `define MSTATUS_MPIE_BITS       7
  `define MSTATUS_SPP_BITS        8
  `define MSTATUS_MPP_BITS    12:11
  `define MSTATUS_MPRV_BITS      17
  `define MSTATUS_TVM_BITS       20

  

  // CSR update logic
  logic [31:0] csr_wdata_int;
  logic [31:0] csr_rdata_int;
  logic        csr_we_int;
  logic [C_RM-1:0]     frm_q, frm_n;
  logic [C_FFLAG-1:0]  fflags_q, fflags_n;
  logic [C_PC-1:0]     fprec_q, fprec_n;

  // Interrupt control signals
  logic [31:0] mepc_q, mepc_n;
  logic [31:0] uepc_q, uepc_n;
  logic [31:0] sepc_q, sepc_n;       // add by **, 2018.5.10
  logic [31:0] mie_q , mie_n;        // add by **, 2018.5.14
  logic [31:0] mip_q , mip_n;        // add by **, 2018.5.14
  logic [31:0] exception_pc;
  Status_t     mstatus_q, mstatus_n;
  logic [ 5:0] mcause_q, mcause_n;
  logic [ 5:0] ucause_q, ucause_n;
  logic [ 5:0] scause_q, scause_n;   // add by **, 2018.5.10
  //not implemented yet
  logic [31:0] mtvec_n, mtvec_q ;
  logic [31:0] utvec_n, utvec_q;
  logic [31:0] stvec_n, stvec_q;     //add for SUPERVISOR  Mode by **, 2018.5.10
  logic [31:0] sscratch_n,sscratch_q;
  logic [31:0] medeleg_n, medeleg_q; //add for SUPERVISOR  Mode by **, 2018.5.11
  logic [31:0] mideleg_n, mideleg_q; //add for SUPERVISOR  Mode by **, 2018.5.11
  logic        is_irq;
  logic        read_access_exception;
  logic        update_access_exception;
  logic        en_ld_st_translation_n,en_ld_st_translation_q;
  PrivLvl_t    priv_lvl_n, priv_lvl_q, priv_lvl_reg_q,trap_to_priv_lvl;
  satp_t       satp_q,  satp_n;
  logic [31:0] mtval_q, mtval_n;    //add by **, 2018.5.17
  logic [31:0] stval_q, stval_n;    //add by **, 2018.5.17
  logic [31:0] utval_q, utval_n;    //add by **, 2018.5.17
  logic [31:0] mcycle_q,mcycle_n;
  logic [31:0] mcycleh_q,mcycleh_n;

  // Performance Counter Signals
  logic                          id_valid_q;
  logic [N_PERF_COUNTERS-1:0]    PCCR_in;  // input signals for each counter category
  logic [N_PERF_COUNTERS-1:0]    PCCR_inc, PCCR_inc_q; // should the counter be increased?

  logic [N_PERF_REGS-1:0] [31:0] PCCR_q, PCCR_n; // performance counters counter register
  logic [1:0]                    PCMR_n, PCMR_q; // mode register, controls saturation and global enable
  logic [N_PERF_COUNTERS-1:0]    PCER_n, PCER_q; // selected counter input

  logic [31:0]                   perf_rdata;
  logic [4:0]                    pccr_index;
  logic                          pccr_all_sel;
  logic                          is_pccr;
  logic                          is_pcer;
  logic                          is_pcmr;

  // cache control
  logic [31:0]  icache_ctrl_n, icache_ctrl_q;
  logic [31:0]  dcache_ctrl_n, dcache_ctrl_q;


  assign is_irq = csr_cause_i[5];

  ///////////////////////////related todebug unit////////////////
  assign debug_csr_addr_o = csr_addr_i;
  assign debug_csr_wdata_o= csr_wdata_int;

  assign debug_dpc_o      = jump_dbg_i ? {32{debug_pc_id_i}} & pc_id_i | {32{debug_pc_if_i}} & jump_target_i:({32{debug_pc_id_i}} & pc_id_i | {32{debug_pc_if_i}} & pc_if_i);   
  assign debug_dpc_en_o   = debug_pc_id_i | debug_pc_if_i; 
  assign debug_dcause_en_o= cause_clr_i | debug_ebk_cause_en_i | debug_irq_cause_en_i | debug_halt_cause_en_i | debug_step_cause_en_i;
  assign debug_dcause_o   = cause_clr_i  ? 3'b0 : {3{debug_ebk_cause_en_i}} & DBG_EBREAK | {3{debug_irq_cause_en_i}} & DBG_IRQ |{3{debug_halt_cause_en_i}} & DBG_HALT | {3{debug_step_cause_en_i}} & DBG_STEP;

  
  
  //////////////////////////read logic///////////////////////////
  // read logic
  always_comb begin 
    case (csr_addr_i)
      // mstatus
      12'h300: csr_rdata_int = mstatus_q; //change by **, 2018.5.11
      //medeleg, add by **, 2018.5.11
      12'h302: csr_rdata_int = medeleg_q;
      //mideleg, add by **, 2018.5.11
      12'h303: csr_rdata_int = mideleg_q;
      //mie
      12'h304: csr_rdata_int = mie_q; 
      // mtvec: machine trap-handler base address
      12'h305: csr_rdata_int = mtvec_q;
      // mepc: exception program counter
      12'h341: csr_rdata_int = mepc_q;
      // mcause: exception cause
      12'h342: csr_rdata_int = {mcause_q[5], 26'b0, mcause_q[4:0]};
      // mtval://add by **, 2018.5.16
      12'h343: csr_rdata_int = mtval_q;
      // mhartid: unique hardware thread id
      12'hF14: csr_rdata_int = {21'b0, cluster_id_i[5:0], 1'b0, core_id_i[3:0]};
      // icache control
      12'h7C0: csr_rdata_int = icache_ctrl_q;
      // dcache control
      12'h7C1: csr_rdata_int = dcache_ctrl_q;
      // mcycle
      12'hB00: csr_rdata_int =  mcycle_q;
      // mcycleh
      12'hB80: csr_rdata_int =  mcycleh_q;
      /* USER CSR */
      // ustatus
      12'h000: csr_rdata_int = {
                                  27'b0,
                                  mstatus_q.upie,
                                  3'h0,
                                  mstatus_q.uie
                                };
      // utvec: user trap-handler base address
      12'h005: csr_rdata_int = utvec_q;
      // dublicated mhartid: unique hardware thread id (not official)
      12'h014: csr_rdata_int = {21'b0, cluster_id_i[5:0], 1'b0, core_id_i[3:0]};
      // uepc: exception program counter
      12'h041: csr_rdata_int = uepc_q;
      // ucause: exception cause
      12'h042: csr_rdata_int = {ucause_q[5], 26'h0, ucause_q[4:0]};
      // utval://add by **, 2018.5.16
      12'h043: csr_rdata_int = utval_q;
      // current priv level (not official)
      12'hC10: csr_rdata_int = {30'h0, priv_lvl_q};

      /*Supervisor CSR, add by **,2018.5.10*////////////////////////////
      //
      //sstatus
      12'h100: csr_rdata_int = mstatus_q & 32'h8de133;
      //sie
      12'h104: csr_rdata_int = mie_q & mideleg_q;
      //stvec
      12'h105: csr_rdata_int = stvec_q;
      //sscratch
      12'h140: csr_rdata_int = sscratch_q;
      //sepc
      12'h141: csr_rdata_int = sepc_q;
      // scause: exception cause
      12'h142: csr_rdata_int = {scause_q[5], 26'd0, scause_q[4:0]};
      // stval
      12'h143: csr_rdata_int = stval_q;
      //sip
      12'h144: csr_rdata_int = mip_q & mideleg_q;
      //satp
      12'h180: begin
               // intercept reads to SATP if in S-Mode and TVM is enabled
                    if (priv_lvl_q == PRIV_LVL_S && mstatus_q.tvm) begin
                        read_access_exception = 1'b1; //illegal instruction exception
                        csr_rdata_int = '0;
                    end else begin
                        read_access_exception = 1'b0;
                        csr_rdata_int = satp_q;
                    end
              end 

      default: begin
        csr_rdata_int = debug_csr_rdata_i;
        read_access_exception = 1'b0;
      end 
    endcase
end


// wire meip_r, meip_r1, meip_r2;
// wire msip_r;
// wire mtip_r;
// sirv_gnrl_dffr #(1) meip_dffr (ext_irq_r, meip_r, clk, rst_n);
// sirv_gnrl_dffr #(1) msip_dffr (sft_irq_r, msip_r, clk, rst_n);
// sirv_gnrl_dffr #(1) mtip_dffr (tmr_irq_r, mtip_r, clk, rst_n);

// sirv_gnrl_dffr #(1) meip_dffr1 (meip_r, meip_r1, clk, rst_n);
// sirv_gnrl_dffr #(1) meip_dffr2 (meip_r1, meip_r2, clk, rst_n);
wire [32-1:0] ip_r;
assign ip_r[31:12] = 20'b0;
assign ip_r[11] = ext_irq_r;
assign ip_r[10:8] = 3'b0;
assign ip_r[ 7] = tmr_irq_r;
assign ip_r[6:4] = 3'b0;
assign ip_r[ 3] = sft_irq_r;
assign ip_r[2:0] = 3'b0;


////////////////////////////write logic//////////////////////////////////
  // write logic
  always_comb
  begin
    automatic satp_t satp;
    automatic logic [31:0] mip;
    satp = satp_q;
    mip = csr_wdata_int & 32'h0333;

    update_access_exception = 1'b0; //add at 2018.5.14
    debug_csr_we_o = 1'b0;
    //////////////////////////////////
    fflags_n     = fflags_q;
    frm_n        = frm_q;
    fprec_n      = fprec_q;
    epc_o        = mepc_q;
    mepc_n       = mepc_q;
    uepc_n       = uepc_q;
    sepc_n       = sepc_q;       //add by **, 2018.5.10
    mstatus_n    = mstatus_q;
    mcause_n     = mcause_q;
    ucause_n     = ucause_q;
    scause_n     = scause_q;     //add by **, 2018.5.10
    icache_ctrl_n= icache_ctrl_q;
    dcache_ctrl_n= dcache_ctrl_q;
    exception_pc = pc_id_i;
    priv_lvl_n   = priv_lvl_q;
    mtvec_n      = mtvec_q;
    utvec_n      = utvec_q;
    stvec_n      = stvec_q;
    sscratch_n   = sscratch_q;  
    mideleg_n    = mideleg_q;   //add by **, 2018.5.11
    medeleg_n    = medeleg_q;   //add by **, 2018.5.11
    satp_n       = satp_q;      //add by **, 2018.5.12
    mie_n        = mie_q;       //add by **, 2018.5.14
    mip_n        = mip_q;       //add by **, 2018.5.14
    mtval_n      = mtval_q;     //add by **, 2018.5.16
    stval_n      = stval_q;     //add by **, 2018.5.16
    utval_n      = utval_q;     //add by **, 2018.5.16

    mstatus_o    = mstatus_q;   //add by **, 2018.5.12
    satp_o       = satp_q;      //add by **, 2018.5.12
    mcycle_n     = mcycle_q;
    mcycleh_n    = mcycleh_q;
    mideleg_o    = mideleg_q; 
    icache_en_o  = icache_ctrl_q[0];
    dcache_en_o  = dcache_ctrl_q[0]; 
    ///////////////////////////////////
     

    case (csr_addr_i)
      // mstatus: IE bit
      12'h300: if (csr_we_int) begin
        //change it by **, 2018.5.11
        mstatus_n = csr_wdata_int ;
        // hardwired zero registers
        mstatus_n.sd   = 1'b0;
        mstatus_n.xs   = 2'b0;
        mstatus_n.fs   = 2'b0;
      end
      //medeleg, add by **, 2018.5.11
      12'h302: if(csr_we_int) begin
        medeleg_n  = csr_wdata_int & 32'h0000_BBFF;  
      end
      //mideleg, add by **, 2018.5.11
      12'h303: if(csr_we_int) begin
        mideleg_n  = csr_wdata_int & 32'h0000_0BBB;  
      end
      //mie, add by **, 2018.5.14
      12'h304: if(csr_we_int) begin
        mie_n      = csr_wdata_int & 32'h0000_0BBB;  // we only support supervisor and m-mode interrupts
      end
      // mtvec: machine trap-handler base address
      12'h305: if (csr_we_int) begin
                  if(csr_wdata_int[0]) begin
                    mtvec_n    = {csr_wdata_int[31:8],7'b0,csr_rdata_int[0]};
                  end else begin
                    mtvec_n    = {csr_wdata_int[31:2],1'b0,csr_rdata_int[0]};
                  end // end else
              end
      // mepc: exception program counter
      12'h341: if (csr_we_int) begin
        mepc_n       = csr_wdata_int;
      end
      // mcause
      12'h342: if (csr_we_int) mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
      // mtval
      12'h343: if (csr_we_int) begin
        mtval_n    = csr_wdata_int ;
      end
      // mip, add by **, 2018.5.14
      12'h344: if (csr_we_int) mip_n    = mip;
      // icache
      12'h7C0: if (csr_we_int) begin 
        icache_ctrl_n = csr_wdata_int; 
      end
      // dcache
      12'h7C1: if (csr_we_int) begin 
        dcache_ctrl_n = csr_wdata_int; 
      end
      // mcycle
      12'hB00: if(csr_we_int) begin
        mcycle_n = csr_wdata_int;
      end
      // mcycleh
      12'hB80: if(csr_we_int) begin
        mcycleh_n = csr_wdata_int;
      end
      /* USER CSR */
      // ustate
      12'h000: if (csr_we_int) begin
        mstatus_n = csr_wdata_int & 32'h800D_E133;
        // hardwired zero registers
        mstatus_n.sd   = 1'b0;
        mstatus_n.xs   = 2'b0;
        mstatus_n.fs   = 2'b0;
      end
      // utvec: user trap-handler base address
      12'h005: if (csr_we_int) begin
        utvec_n    = {csr_wdata_int[31:2],1'b0,csr_wdata_int[0]};
      end
      // uepc: exception program counter
      12'h041: if (csr_we_int) begin
        uepc_n     = csr_wdata_int;
      end
      // ucause: exception cause
      12'h042: if (csr_we_int) ucause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
      //utval
      12'h043: if (csr_we_int) begin
        utval_n    = csr_wdata_int ;
      end

      /*Supervisor CSR, add by **,2018.5.10*///////////////////////////////
      //sstatus
      12'h100: if (csr_we_int) begin 
        mstatus_n  = csr_wdata_int & 32'h8de133;
      end
      //sie     
      12'h104: if(csr_we_int) begin
        // even machine mode interrupts can be visible and set-able to supervisor
        // if the corresponding bit in mideleg is set
        // the mideleg makes sure only delegate-able register (and therefore also only implemented registers) are written
        //for (int unsigned i = 0; i < 64; i++) ,modf,2018-6-9
        for (int unsigned i = 0; i < 32; i++)
            if (mideleg_q[i])
                mie_n[i] = csr_wdata_int[i]; 
      end
      //stvec 
      12'h105: if (csr_we_int) begin
        stvec_n    = {csr_wdata_int[31:2],1'b0,csr_wdata_int[0]};
      end
      //sscratch
      12'h140:if(csr_we_int) begin
        sscratch_n = csr_wdata_int;
      end
      //sepc
      12'h141: if(csr_we_int) begin
        sepc_n     = csr_wdata_int;
      end 
      // scause: exception cause
      12'h142: if (csr_we_int) scause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
      // stval
      12'h143: if (csr_we_int) begin
        stval_n    = csr_wdata_int ;
      end
      //sip
      12'h144: if(csr_we_int) begin
    //for (int unsigned i = 0; i < 64; i++) ,modf,2018-6-11
        for (int unsigned i = 0; i < 32; i++)
            if (mideleg_q[i])
                mip_n[i] = mip[i];
      end
      //satp
      12'h180: if (csr_we_int) begin
        // intercept SATP writes if in S-Mode and TVM is enabled
        if (priv_lvl_q == PRIV_LVL_S && mstatus_q.tvm)
            update_access_exception = 1'b1;
        else begin
            satp      = satp_t'(csr_wdata_int);
            // only make ASID_LEN - 1 bit stick, that way software can figure out how many ASID bits are supported
            satp.asid = satp.asid & {{(9-ASID_WIDTH){1'b0}}, {ASID_WIDTH{1'b1}}};
            satp_n    = satp;
        end
        // changing the mode can have side-effects on address translation (e.g.: other instructions), re-fetch
        // the next instruction by executing a flush 
      end
      default: begin
              debug_csr_we_o = csr_we_int & debug_mode_i;
              end
    endcase
    //////////////////////recoder int happen///////////////////
    
	// if(irq_req_happen_i) begin
      // mip_n = irq_req_event_i;
    // end
	
	// mip_n = ip_r;
	mip_n = {20'd0, ext_irq_r, 3'd0, tmr_irq_r, 3'd0, sft_irq_r, 3'd0};
	
    ////////////////////// Counters///////////////////////////
     if((csr_we_int&csr_addr_i!=12'hB00&csr_addr_i!=12'hB80 | ~csr_we_int) & ~(debug_stopcycle_i&debug_mode_i)) begin
         {mcycleh_n,mcycle_n} = {mcycleh_q,mcycle_q} + 1'b1;
     end
    //////////////////////////////////////////////////////////
    // exception controller gets priority over other writes
    unique case (1'b1)
      
      csr_save_cause_i: begin

        unique case (1'b1)
          csr_save_if_i:
            exception_pc = pc_if_i;
          csr_save_id_i:
            exception_pc = pc_id_i;
          default:;
        endcase

        ////add by **, for change mode by (mideleg & sideleg), 2018.5.11/////////////////////// 
        if(is_irq && mideleg_q[csr_cause_i[4:0]] && csr_irq_sec_i | ~is_irq && medeleg_q[csr_cause_i[4:0]]) begin
            if(priv_lvl_q == PRIV_LVL_M) begin // if cur is m, not to change
                trap_to_priv_lvl = PRIV_LVL_M;
            end else begin 
              //if(is_irq && sideleg_q[csr_cause_i[4:0]] | ~is_irq && sideleg_q[csr_cause_i[4:0]]) begin
              //    if(priv_lvl_q == PRIV_LVL_S) begin
                    trap_to_priv_lvl = PRIV_LVL_S; // if cur if s, handler trap mode from m to s
              //    end else begin
              //     trap_to_priv_lvl = PRIV_LVL_U; // if cur if s, handler trap mode from m to u
              //    end   
              //end else begin
              //    trap_to_priv_lvl = PRIV_LVL_M;
              //end      
            end 
        end else begin
            trap_to_priv_lvl = PRIV_LVL_M;
        end

        // trap to less mode
        if (trap_to_priv_lvl == PRIV_LVL_S) begin
            //update state
            mstatus_n.spie = mstatus_q.sie;
            mstatus_n.sie  = 1'b0;
            mstatus_n.spp  = logic'(priv_lvl_q);
            //set epc
            sepc_n         = exception_pc;
            //set cause
            scause_n       = csr_cause_i;   
            //set tval
            stval_n        = csr_tval_i;       
        // trap to machine mode
        end else if (trap_to_priv_lvl == PRIV_LVL_U) begin
            mstatus_n.upie = mstatus_q.uie;
            mstatus_n.uie  = 1'b0;
            uepc_n         = exception_pc;
            ucause_n       = csr_cause_i;
            //set tval
            utval_n        = csr_tval_i;
        end else begin
            mstatus_n.mpie = mstatus_q.mie;
            mstatus_n.mie  = 1'b0;
            mstatus_n.mpp  = priv_lvl_q;
            mepc_n         = exception_pc;
            mcause_n       = csr_cause_i;
            //set tval
            mtval_n        = csr_tval_i;
        end

        priv_lvl_n = trap_to_priv_lvl ;
        
        ///////////////////////////////////////////////////////////
        // ------------------------------
        // MPRV - Modify Privilege Level //add by **,  2018.5.11
        // ------------------------------
        // Set the address translation at which the load and stores should occur
        // we can use the previous values since changing the address translation will always involve a pipeline flush
        if (mstatus_q.mprv && satp_q.mode == 4'h1 && (mstatus_q.mpp != PRIV_LVL_M))
            en_ld_st_translation_n = 1'b1;
        else // otherwise we go with the regular settings
            en_ld_st_translation_n = en_translation_o;

        ld_st_priv_lvl_o = (mstatus_q.mprv) ? mstatus_q.mpp : priv_lvl_o;
        en_ld_st_translation_o = en_ld_st_translation_q;
      
      end //csr_save_cause_i

      csr_restore_uret_i: begin //URET
        //mstatus_q.upp is implicitly 0, i.e PRIV_LVL_U
        mstatus_n.uie  = mstatus_q.upie;
        priv_lvl_n     = PRIV_LVL_U;
        mstatus_n.upie = 1'b1;
        epc_o          = uepc_q;
      end //csr_restore_uret_i

      csr_restore_sret_i: begin //SRET //add by **, 2018.5.10
        //return the previous supervisor interrupt enable flag
        mstatus_n.sie  = mstatus_q.spie;
        // restore the previous priviledge level
        priv_lvl_n     = PrivLvl_t'({1'b0, mstatus_q.spp}) ;
        // set spp to user mode
        mstatus_n.spp  = logic'(PRIV_LVL_U);
        // set spie to 1
        mstatus_n.spie = 1'b1;

        epc_o          = sepc_q;
      end //csr_restore_uret_i

      csr_restore_mret_i: begin //MRET
        unique case (mstatus_q.mpp)
          PRIV_LVL_U: begin
            mstatus_n.uie  = mstatus_q.mpie;
            priv_lvl_n     = PRIV_LVL_U;
            mstatus_n.mpie = 1'b1;
            mstatus_n.mpp  = PRIV_LVL_U;
          end
          PRIV_LVL_M: begin
            mstatus_n.mie  = mstatus_q.mpie;
            priv_lvl_n     = PRIV_LVL_M;
            mstatus_n.mpie = 1'b1;
            mstatus_n.mpp  = PRIV_LVL_U;
             //mip_n = irq_req_event_i;//'d0;
          end
          default:;
        endcase
        epc_o              = mepc_q;
      end //csr_restore_mret_i

      csr_restore_dret_i: begin //DRET
            priv_lvl_n     = PrivLvl_t'(debug_csr_dcsr_i[1:0]);
      end //csr_restore_dret_i
	  //-------------------------------------------------------//
	   // --zhou 重新编程之后清除中断使能及中断屏蔽信�?
	  set_mie_i  : 	begin
						mstatus_n.mie = 'b0;
						mie_n 		=	'b0;
						mip_n  		=	'b0;
					end
		//-------------------------------------------------//			
      default:;
    endcase

    //In Debug Mode,All operations happen in machine mode, from debug spec 0.11
    if(debug_mode_i) begin
      priv_lvl_n = PRIV_LVL_M;
    end
      
  end

/////////////////////////////////////////////////////////////////////    

  // CSR operation logic
  always_comb
  begin
    csr_wdata_int = csr_wdata_i;
    csr_we_int    = 1'b1;
	dbg_csr_set_o = 1'b0;
    unique case (csr_op_i)
      CSR_OP_WRITE: csr_wdata_int = csr_wdata_i;
      CSR_OP_SET:   begin 
						csr_wdata_int = csr_wdata_i | csr_rdata_o;
						dbg_csr_set_o = 1;
					end
      CSR_OP_CLEAR: csr_wdata_int = (~csr_wdata_i) & csr_rdata_o;

      CSR_OP_NONE: begin
        csr_wdata_int = csr_wdata_i;
        csr_we_int    = 1'b0;
      end

      default:;
    endcase
  end


  // output mux
  always_comb
  begin
    csr_rdata_o = csr_rdata_int;

    // performance counters
    if (is_pccr || is_pcer || is_pcmr)
      csr_rdata_o = perf_rdata;
  end


  // directly output some registers
  assign m_irq_enable_o  = mstatus_q.mie & priv_lvl_q == PRIV_LVL_M;
  assign s_irq_enable_o  = mstatus_q.sie & priv_lvl_q == PRIV_LVL_S;
  assign u_irq_enable_o  = mstatus_q.uie & priv_lvl_q == PRIV_LVL_U;
  assign priv_lvl_o      = priv_lvl_q;
  assign sec_lvl_o       = priv_lvl_q[0];
  //assign frm_o           = (FPU == 1) ? frm_q : '0;
  //assign fprec_o         = (FPU == 1) ? fprec_q : '0;

  assign mtvec_o         = mtvec_q;
  assign utvec_o         = utvec_q;
  assign stvec_o         = stvec_q; //add  2018.5.10

  assign mip_o           = mip_q;
  assign mie_o           = mie_q;
  // we support bare memory addressing and SV32
  assign en_translation_o = (satp_q.mode == 4'h1 && priv_lvl_q != PRIV_LVL_M) ? 1'b1 : 1'b0;
  ///////////////////////////////////////////////////////////////////
  // actual registers
  always_ff @(posedge clk, negedge rst_n)
  begin
    if (rst_n == 1'b0)
    begin
        uepc_q         <= '0;
        ucause_q       <= '0;
        mtvec_q        <= '0;
        utvec_q        <= '0;
        sscratch_q     <= '0;       
        stvec_q        <= '0; //add for SUPERVISOR  Mode by **, 2018.5.10
        sepc_q         <= '0; //add by **, 2018.5.10
        scause_q       <= '0; //add by **, 2018.5.10
        satp_q         <= '0; //add by **, 2018.5.12
        mip_q          <= '0; //add by **, 2018.5.14
        mie_q          <= '0; //add by **, 2018.5.14// '1;***
        mtval_q        <= '0; //add by **, 2018.5.16
        stval_q        <= '0; //add by **, 2018.5.16
        utval_q        <= '0; //add by **, 2018.5.16
        medeleg_q      <= '0;
        mideleg_q      <= '0;
        en_ld_st_translation_q <= '0;
 
      priv_lvl_q <= PRIV_LVL_M;
      mstatus_q  <= 32'h0000_1800; //add by **, 2018.5.14 //32'h0000_1808;****
           // '{
           //   uie:  1'b0,
           //   mie:  1'b0,
           //   upie: 1'b0,
           //   mpie: 1'b0,
           //   mpp:  PRIV_LVL_M
           // };
      mepc_q      <= '0;
      mcause_q    <= '0;
      icache_ctrl_q  <= 32'd1;
      dcache_ctrl_q  <= 32'd1; 
      mcycle_q       <= 32'd0;
      mcycleh_q      <= 32'd0; 
    end
    else
    begin
        mstatus_q      <= mstatus_n ;
        uepc_q         <= uepc_n    ;
        ucause_q       <= ucause_n  ;
        priv_lvl_q     <= priv_lvl_n;
        utvec_q        <= utvec_n;
        mtvec_q        <= mtvec_n;
        sscratch_q     <= sscratch_n;
        stvec_q        <= stvec_n;    //add for SUPERVISOR  Mode by **, 2018.5.10
        sepc_q         <= sepc_n    ; //add by **, 2018.5.10
        scause_q       <= scause_n  ; //add by **, 2018.5.10
        satp_q         <= satp_n    ; //add by **, 2018.5.12
        mie_q          <= mie_n     ; //add by **, 2018.5.14
        mip_q          <= mip_n     ; //add by **, 2018.5.14
        mtval_q        <= mtval_n   ; //add by **, 2018.5.16
        stval_q        <= stval_n   ; //add by **, 2018.5.16
        utval_q        <= utval_n   ; //add by **, 2018.5.16
        medeleg_q      <= medeleg_n ;
        mideleg_q      <= mideleg_n ;
        en_ld_st_translation_q <= en_ld_st_translation_n;
       
        mepc_q         <= mepc_n    ;
        mcause_q       <= mcause_n  ;
        icache_ctrl_q  <= icache_ctrl_n;
        icache_ctrl_q  <= icache_ctrl_n;
        mcycle_q       <= mcycle_n;
        mcycleh_q      <= mcycleh_n;
    end
  end

  /////////////////////////////////////////////////////////////////
  //   ____            __     ____                  _            //
  // |  _ \ ___ _ __ / _|   / ___|___  _   _ _ __ | |_ ___ _ __  //
  // | |_) / _ \ '__| |_   | |   / _ \| | | | '_ \| __/ _ \ '__| //
  // |  __/  __/ |  |  _|  | |__| (_) | |_| | | | | ||  __/ |    //
  // |_|   \___|_|  |_|(_)  \____\___/ \__,_|_| |_|\__\___|_|    //
  //                                                             //
  /////////////////////////////////////////////////////////////////

  assign PCCR_in[0]  = 1'b1;                          // cycle counter
  assign PCCR_in[1]  = id_valid_i & is_decoding_i;    // instruction counter
  assign PCCR_in[2]  = ld_stall_i & id_valid_q;       // nr of load use hazards
  assign PCCR_in[3]  = jr_stall_i & id_valid_q;       // nr of jump register hazards
  assign PCCR_in[4]  = imiss_i & (~pc_set_i);         // cycles waiting for instruction fetches, excluding jumps and branches
  assign PCCR_in[5]  = mem_load_i;                    // nr of loads
  assign PCCR_in[6]  = mem_store_i;                   // nr of stores
  assign PCCR_in[7]  = jump_i                     & id_valid_q; // nr of jumps (unconditional)
  assign PCCR_in[8]  = branch_i                   & id_valid_q; // nr of branches (conditional)
  assign PCCR_in[9]  = branch_i & branch_taken_i  & id_valid_q; // nr of taken branches (conditional)
  //assign PCCR_in[10] = id_valid_i & is_decoding_i & is_compressed_i;  // compressed instruction counter

  // assign external performance counters
  generate
    genvar i;
    for(i = 0; i < N_EXT_CNT; i++)
    begin
      assign PCCR_in[PERF_EXT_ID + i] = ext_counters_i[i];
    end
  endgenerate

  // address decoder for performance counter registers
  always_comb
  begin
    is_pccr      = 1'b0;
    is_pcmr      = 1'b0;
    is_pcer      = 1'b0;
    pccr_all_sel = 1'b0;
    pccr_index   = '0;
    perf_rdata   = '0;

    // only perform csr access if we actually care about the read data
    if (csr_access_i) begin
      unique case (csr_addr_i)
        12'h7A0: begin
          is_pcer = 1'b1;
          perf_rdata[N_PERF_COUNTERS-1:0] = PCER_q;
        end
        12'h7A1: begin
          is_pcmr = 1'b1;
          perf_rdata[1:0] = PCMR_q;
        end
        12'h79F: begin
          is_pccr = 1'b1;
          pccr_all_sel = 1'b1;
        end
        default:;
      endcase

      // look for 780 to 79F, Performance Counter Counter Registers
      if (csr_addr_i[11:5] == 7'b0111100) begin
        is_pccr     = 1'b1;

        pccr_index = csr_addr_i[4:0];
`ifdef  ASIC_SYNTHESIS
        perf_rdata = PCCR_q[0];
`else
        perf_rdata = csr_addr_i[4:0] < N_PERF_COUNTERS ? PCCR_q[csr_addr_i[4:0]] : '0;
`endif
      end
    end
  end


  // performance counter counter update logic
`ifdef ASIC_SYNTHESIS
  // for synthesis we just have one performance counter register
  assign PCCR_inc[0] = (|(PCCR_in & PCER_q)) & PCMR_q[0];

  always_comb
  begin
    PCCR_n[0]   = PCCR_q[0];

    if ((PCCR_inc_q[0] == 1'b1) && ((PCCR_q[0] != 32'hFFFFFFFF) || (PCMR_q[1] == 1'b0)))
      PCCR_n[0] = PCCR_q[0] + 1;

    if (is_pccr == 1'b1) begin
      unique case (csr_op_i)
        CSR_OP_NONE:   ;
        CSR_OP_WRITE:  PCCR_n[0] = csr_wdata_i;
        CSR_OP_SET:    PCCR_n[0] = csr_wdata_i | PCCR_q[0];
        CSR_OP_CLEAR:  PCCR_n[0] = csr_wdata_i & ~(PCCR_q[0]);
      endcase
    end
  end
`else
  always_comb
  begin
    for(int i = 0; i < N_PERF_COUNTERS; i++)
    begin : PERF_CNT_INC
      PCCR_inc[i] = PCCR_in[i] & PCER_q[i] & PCMR_q[0];

      PCCR_n[i]   = PCCR_q[i];

      if ((PCCR_inc_q[i] == 1'b1) && ((PCCR_q[i] != 32'hFFFFFFFF) || (PCMR_q[1] == 1'b0)))
        PCCR_n[i] = PCCR_q[i] + 1;

      if (is_pccr == 1'b1 && (pccr_all_sel == 1'b1 || pccr_index == i)) begin
        unique case (csr_op_i)
          CSR_OP_NONE:   ;
          CSR_OP_WRITE:  PCCR_n[i] = csr_wdata_i;
          CSR_OP_SET:    PCCR_n[i] = csr_wdata_i | PCCR_q[i];
          CSR_OP_CLEAR:  PCCR_n[i] = csr_wdata_i & ~(PCCR_q[i]);
        endcase
      end
    end
  end
`endif

  // update PCMR and PCER
  always_comb
  begin
    PCMR_n = PCMR_q;
    PCER_n = PCER_q;

    if (is_pcmr) begin
      unique case (csr_op_i)
        CSR_OP_NONE:   ;
        CSR_OP_WRITE:  PCMR_n = csr_wdata_i[1:0];
        CSR_OP_SET:    PCMR_n = csr_wdata_i[1:0] | PCMR_q;
        CSR_OP_CLEAR:  PCMR_n = csr_wdata_i[1:0] & ~(PCMR_q);
      endcase
    end

    if (is_pcer) begin
      unique case (csr_op_i)
        CSR_OP_NONE:   ;
        CSR_OP_WRITE:  PCER_n = csr_wdata_i[N_PERF_COUNTERS-1:0];
        CSR_OP_SET:    PCER_n = csr_wdata_i[N_PERF_COUNTERS-1:0] | PCER_q;
        CSR_OP_CLEAR:  PCER_n = csr_wdata_i[N_PERF_COUNTERS-1:0] & ~(PCER_q);
      endcase
    end
  end

  // Performance Counter Registers
  always_ff @(posedge clk, negedge rst_n)
  begin
    if (rst_n == 1'b0)
    begin
      id_valid_q <= 1'b0;

      PCER_q <= '0;
      PCMR_q <= 2'h3;

      for(int i = 0; i < N_PERF_REGS; i++)
      begin
        PCCR_q[i]     <= '0;
        PCCR_inc_q[i] <= '0;
      end
    end
    else
    begin
      id_valid_q <= id_valid_i;

      PCER_q <= PCER_n;
      PCMR_q <= PCMR_n;

      for(int i = 0; i < N_PERF_REGS; i++)
      begin
        PCCR_q[i]     <= PCCR_n[i];
        PCCR_inc_q[i] <= PCCR_inc[i];
      end

    end
  end

endmodule
