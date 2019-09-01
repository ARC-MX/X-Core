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
`include "../../rtl/core/riscv_config.sv"
// `include "./include/axi_bus.sv"
import riscv_defines::*;
import riscv_package::*;

`include "riscv_config.sv"
// `include "./include/axi_bus.sv"
import riscv_defines::*;
import riscv_package::*;

module riscv_cpu
#(
  parameter  N_EXT_PERF_COUNTERS =  0,
  parameter  INSTR_RDATA_WIDTH   = 32,
  parameter  RISCV_SECURE        =  1,
  parameter  RISCV_CLUSTER       =  1,
  parameter  INSTR_TLB_ENTRIES   =  4,
  parameter  DATA_TLB_ENTRIES    =  4,
  parameter  MMU_ASID_WIDTH      =  9,

  parameter int unsigned INSTR_ADDR_WIDTH = 34,       
  parameter int unsigned INSTR_DATA_WIDTH = 32,       
  parameter int unsigned INSTR_ID_WIDTH   = 4,

  parameter int unsigned INSTR_AXI_ADDR_WIDTH   = 34,
  parameter int unsigned INSTR_AXI_DATA_WIDTH   = 32,
  parameter int unsigned INSTR_AXI_USER_WIDTH   = 6,
  
  parameter int unsigned INSTR_AXI_ID_WIDTH     = INSTR_ID_WIDTH,
  parameter int unsigned INSTR_SLICE_DEPTH      = 2,
  parameter int unsigned INSTR_AXI_STRB_WIDTH   = INSTR_AXI_DATA_WIDTH/8,

  parameter int unsigned INSTR_NB_BANKS         = 1,       
  parameter int unsigned INSTR_NB_WAYS          = 4,      
  parameter int unsigned INSTR_CACHE_SIZE       = 8*1024,  
  parameter int unsigned INSTR_CACHE_LINE       = 2,

  parameter logic [31:0] DATA_CACHE_START_ADDR  = 32'h0000_0000,
  parameter int unsigned DATA_AXI_ID_WIDTH      = 10,
  parameter int unsigned DATA_AXI_USER_WIDTH    = 1        

)
(
  input  logic                            clk_i         ,
  input  logic                            rst_ni        ,
  input	 logic							  clk_ila,                         
  input  logic                            clock_en_i    ,
  input  logic                            test_en_i     ,
                              
  input  logic  [31:0]                    boot_addr_i   ,
  input  logic  [ 3:0]                    core_id_i     ,
  input  logic  [ 5:0]                    cluster_id_i  ,
                            
  input  logic                            irq_gpio_i    ,
  input  logic                            irq_timer_i   ,
  
  output logic                            sec_lvl_o     ,

                    
  input  logic                            debug_req_i    ,
  output logic                            debug_gnt_o    ,
  output logic                            debug_rvalid_o ,
  input  logic  [14:0]                    debug_addr_i   ,
  input  logic                            debug_we_i     ,
  input  logic  [31:0]                    debug_wdata_i  ,
  output logic  [31:0]                    debug_rdata_o  ,
  output logic                            debug_halted_o ,
  input  logic                            debug_halt_i   ,
  input  logic                            debug_resume_i ,

  //Debug Unit interface
  input  logic                            irq_debug_i   ,
  output logic                            irq_debug_sync_o,

  input  logic                            debug_mode_i,
  input  logic                            debug_stopcycle_i,
  input  logic                            debug_ebreakm_i,
  input  logic                            debug_ebreaks_i,
  input  logic                            debug_ebreaku_i,
  input  logic                            debug_halt_new_i,
  input  logic                            debug_step_i,
            
  input  logic [31:0]                     debug_csr_dpc_i,
  input  logic [31:0]                     debug_csr_dcsr_i,
            
  input  logic [31:0]                     debug_csr_rdata_i,
  output logic [31:0]                     debug_csr_wdata_o,
  output logic [31:0]                     debug_csr_addr_o,
  output logic                            debug_csr_we_o,
  output logic 							  dbg_csr_set_o,              
  output logic [31:0]                     debug_dpc_o,      
  output logic                            debug_dpc_en_o,   
  output logic                            debug_dcause_en_o,
  output logic [2:0]                      debug_dcause_o, 
  output logic                            debug_csr_dret_o,
  ////////////

  input  logic                            fetch_enable_i ,
  output logic                            core_busy_o    ,
  output logic                            clk_core_o     ,

  input  logic  [N_EXT_PERF_COUNTERS-1:0] ext_perf_counters_i ,
`ifdef DIS_CACHE
  output logic [33:0]                     instr_addr_o , 
  output logic                            instr_req_o  ,
  input  logic [31:0]                     instr_rdata_i, 
  input  logic                            instr_gnt_i  , 
  input  logic                            instr_rvalid_i,

  output logic [33:0]                     data_addr_o  ,
  output logic [31:0]                     data_wdata_o ,
  output logic                            data_we_o    ,
  output logic                            data_req_o   ,
  output logic [3:0]                      data_be_o    ,
  input  logic [31:0]                     data_rdata_i ,
  input  logic                            data_gnt_i   ,
  input  logic                            data_rvalid_i
`else 
  AXI_BUS.Master                          axi_instr      ,
  AXI_BUS.Master                          axi_data       ,
  AXI_BUS.Master                          axi_bypass
`endif

);

//////////////////////////////////////////////////////////
  logic [33:0]               core_instr_addr;
  logic                      core_instr_req;
  logic                      core_instr_gnt;
  logic                      core_instr_rvalid;
  logic [31:0]               core_instr_rdata;

  logic [33:0]               core_data_addr;
  logic [31:0]               core_data_wdata;
  logic                      core_data_we;
  logic                      core_data_req;
  logic [ 3:0]               core_data_be;
  logic [31:0]               core_data_rdata;
  logic                      core_data_gnt;
  logic                      core_data_rvalid;

  logic [2:0]   [33:0]       dcache_data_addr;
  logic [2:0]   [31:0]       dcache_data_wdata;
  logic [2:0]                dcache_data_we;
  logic [2:0]                dcache_data_req;
  logic [2:0]   [ 3:0]       dcache_data_be;
  logic [2:0]   [31:0]       dcache_data_rdata;
  logic [2:0]                dcache_data_gnt;
  logic [2:0]                dcache_data_rvalid; 
  logic [2:0]   [1:0]        dcache_data_size;

  logic                      icache_en;
  logic                      dcache_en;


  logic                      irq;
  logic [4:0]                irq_id_in;
  logic                      irq_ack;
  logic [4:0]                irq_id_out;
  logic                      irq_sec;                   
  
  logic						irq_gpio_sync;
  logic						irq_timer_sync;

  assign  core_data_rvalid      =   dcache_data_rvalid[0];
  assign  core_data_gnt         =   dcache_data_gnt[0];
  assign  core_data_rdata       =   dcache_data_rdata[0];
  
  assign  dcache_data_addr  [0] =   core_data_addr  ;
  assign  dcache_data_wdata [0] =   core_data_wdata ;
  assign  dcache_data_we    [0] =   core_data_we    ;
  assign  dcache_data_req   [0] =   core_data_req   ;
  assign  dcache_data_be    [0] =   core_data_be    ;
  assign  dcache_data_addr  [1] =   '0;
  assign  dcache_data_wdata [1] =   '0;
  assign  dcache_data_we    [1] =   '0;
  assign  dcache_data_req   [1] =   '0;
  assign  dcache_data_be    [1] =   '0;
  assign  dcache_data_addr  [2] =   '0;
  assign  dcache_data_wdata [2] =   '0;
  assign  dcache_data_we    [2] =   '0;
  assign  dcache_data_req   [2] =   '0;
  assign  dcache_data_be    [2] =   '0;
  
  assign  dcache_data_size  [0] =   2'b10;
  assign  dcache_data_size  [1] =   '0;
  assign  dcache_data_size  [2] =   '0;

//////////////////////////////////////////////////////////
  riscv_core
  #(
    .N_EXT_PERF_COUNTERS    (N_EXT_PERF_COUNTERS),
    .INSTR_RDATA_WIDTH      (INSTR_RDATA_WIDTH  ),
    .RISCV_SECURE           (RISCV_SECURE       ),
    .RISCV_CLUSTER          (RISCV_CLUSTER      ),
    .INSTR_TLB_ENTRIES      (INSTR_TLB_ENTRIES  ),
    .DATA_TLB_ENTRIES       (DATA_TLB_ENTRIES   ),
    .ASID_WIDTH             (MMU_ASID_WIDTH     )
  ) riscv_core
    (
    .clk_i                  ( clk_i             ),
    .rst_ni                 ( rst_ni            ),
	.clk_ila				(clk_ila),
    .clock_en_i             ( clock_en_i        ),
    .test_en_i              ( test_en_i         ),
    // Core ID, Cluster ID and boot address are considered more or less static
    .boot_addr_i            ( boot_addr_i       ),
    .core_id_i              ( core_id_i         ),
    .cluster_id_i           ( cluster_id_i      ),
	.ext_irq_r(irq_gpio_sync),
	.sft_irq_r('d0),
	.tmr_irq_r(irq_timer_sync),
`ifdef DIS_CACHE
    // Instruction memory interface
    .instr_addr_o           ( instr_addr_o   ),
    .instr_req_o            ( instr_req_o    ),
    .instr_rdata_i          ( instr_rdata_i  ),
    .instr_gnt_i            ( instr_gnt_i    ),
    .instr_rvalid_i         ( instr_rvalid_i ),
    // Data memory interface
    .data_addr_o            ( data_addr_o    ),
    .data_wdata_o           ( data_wdata_o   ),
    .data_we_o              ( data_we_o      ),
    .data_req_o             ( data_req_o     ),
    .data_be_o              ( data_be_o      ),
    .data_rdata_i           ( data_rdata_i   ),
    .data_gnt_i             ( data_gnt_i     ),
    .data_rvalid_i          ( data_rvalid_i  ),
    .data_err_i             ( 1'b0           ),
`else 
    // Instruction memory interface
    .instr_addr_o           ( core_instr_addr   ),
    .instr_req_o            ( core_instr_req    ),
    .instr_rdata_i          ( core_instr_rdata  ),
    .instr_gnt_i            ( core_instr_gnt    ),
    .instr_rvalid_i         ( core_instr_rvalid ),
    // Data memory interface
    .data_addr_o            ( core_data_addr    ),
    .data_wdata_o           ( core_data_wdata   ),
    .data_we_o              ( core_data_we      ),
    .data_req_o             ( core_data_req     ),
    .data_be_o              ( core_data_be      ),
    .data_rdata_i           ( core_data_rdata   ),
    .data_gnt_i             ( core_data_gnt     ),
    .data_rvalid_i          ( core_data_rvalid  ),
    .data_err_i             ( 1'b0              ),
`endif
    // Interrupt inputs
    .irq_i                  ( irq               ),
    .irq_id_i               ( irq_id_out         ),
    .irq_ack_o              ( irq_ack           ),
    .irq_id_o               ( irq_id_in         ),
    .irq_sec_i              ( irq_sec           ),
    .sec_lvl_o              ( sec_lvl_o         ),
    // Debug Interface
    .debug_req_i            ( debug_req_i       ),
    .debug_gnt_o            ( debug_gnt_o       ),
    .debug_rvalid_o         ( debug_rvalid_o    ),
    .debug_addr_i           ( debug_addr_i      ),
    .debug_we_i             ( debug_we_i        ),
    .debug_wdata_i          ( debug_wdata_i     ),
    .debug_rdata_o          ( debug_rdata_o     ),
    .debug_halted_o         ( debug_halted_o    ),
    .debug_halt_i           ( debug_halt_i      ),
    .debug_resume_i         ( debug_resume_i    ),
    // Debug Unit
    .debug_mode_i           ( debug_mode_i      ),
    .debug_stopcycle_i      ( debug_stopcycle_i ),
    .debug_halt_new_i           (debug_halt_new_i       ),
    .debug_step_i           (debug_step_i       ),
    .debug_ebreakm_i        ( debug_ebreakm_i   ),
    .debug_ebreaks_i        ( debug_ebreaks_i   ),
    .debug_ebreaku_i        ( debug_ebreaku_i   ),
    .debug_csr_dpc_i        ( debug_csr_dpc_i   ),
    .debug_csr_dcsr_i       ( debug_csr_dcsr_i  ),
    .debug_csr_rdata_i      ( debug_csr_rdata_i ),
    .debug_csr_wdata_o      ( debug_csr_wdata_o ),
    .debug_csr_addr_o       ( debug_csr_addr_o  ),
    .debug_csr_we_o         ( debug_csr_we_o    ),
	.dbg_csr_set_o			(dbg_csr_set_o		),
    .debug_dpc_o            ( debug_dpc_o       ),      
    .debug_dpc_en_o         ( debug_dpc_en_o    ),   
    .debug_dcause_en_o      ( debug_dcause_en_o ),
    .debug_dcause_o         ( debug_dcause_o    ), 
    .debug_csr_dret_o       ( debug_csr_dret_o  ),
    // CPU Control Signals
    .fetch_enable_i         ( fetch_enable_i    ),
    .core_busy_o            ( core_busy_o       ),

    .ext_perf_counters_i    ( ext_perf_counters_i),

    .clk_core_o             ( clk_core_o         ),

    //cache control
    .icache_en_o            ( icache_en         ),
    .dcache_en_o            ( dcache_en         )
  );
      
 /////////////////////////////////////////////////  
 `ifndef DIS_CACHE    
  riscv_icache 
  #(
    .FETCH_ADDR_WIDTH       ( INSTR_ADDR_WIDTH     ),
    .FETCH_DATA_WIDTH       ( INSTR_DATA_WIDTH     ),
    .ID_WIDTH               ( INSTR_ID_WIDTH       ),
    .AXI_ADDR_WIDTH         ( INSTR_AXI_ADDR_WIDTH ),
    .AXI_DATA_WIDTH         ( INSTR_AXI_DATA_WIDTH ),
    .AXI_USER_WIDTH         ( INSTR_AXI_USER_WIDTH ),
    .AXI_ID_WIDTH           ( INSTR_AXI_ID_WIDTH   ),
    .SLICE_DEPTH            ( INSTR_SLICE_DEPTH    ),
    .AXI_STRB_WIDTH         ( INSTR_AXI_STRB_WIDTH ),
    .NB_BANKS               ( INSTR_NB_BANKS       ),
    .NB_WAYS                ( INSTR_NB_WAYS        ), 
    .CACHE_SIZE             ( INSTR_CACHE_SIZE     ),  
    .CACHE_LINE             ( INSTR_CACHE_LINE     )
  ) riscv_icache (
    .clk_i                  ( clk_i             ),
    .rst_n                  ( 1'b1             ),
    // interface with processor  
    .fetch_req_i            ( core_instr_req    ),
    .fetch_addr_i           ( core_instr_addr   ),
    .fetch_gnt_o            ( core_instr_gnt    ),
    .fetch_rvalid_o         ( core_instr_rvalid ),
    .fetch_rdata_o          ( core_instr_rdata  ),  
  
    .axi                    ( axi_instr         ),               
                
    // From CSR_regfile           
    .bypass_icache_i        ( '1),//~icache_en        ),
    // Is opened            
    .cache_is_bypassed_o    ( ),      
                
    // From controller            
    .flush_icache_i         ( 1'b0              ),
    .cache_is_flushed_o     ( ),      
              
    // They are all not used        
    .flush_set_ID_req_i     ( 1'b0              ),
    .flush_set_ID_addr_i    ( '0                ),
    .flush_set_ID_ack_o     ( )
  );
  
/////////////////////////////////////////////////

// assign for_debug_sim = dcache_data_addr>=32'h100&&dcache_data_addr<=32'h2ff&&
                       // dcache_data_addr>=32'h400&&dcache_data_addr<=32'h4ff&&
                       // dcache_data_addr>=32'h800&&dcache_data_addr<=32'h9ff;

  riscv_nbdcache 
  #(
    .CACHE_START_ADDR       ( DATA_CACHE_START_ADDR),
    .AXI_ID_WIDTH           ( DATA_AXI_ID_WIDTH    ),
    .AXI_USER_WIDTH         ( DATA_AXI_USER_WIDTH  )
  )   
  riscv_nbdcache (  
    .clk_i                  ( clk_i                ),       
    .rst_ni                 ( rst_ni               ),      
    // Cache management          
    //.enable_i               ( dcache_en & ~debug_mode_i           ),
     .enable_i               (0),// dcache_en & ~debug_mode_i &~(dcache_data_addr==32'h200bff8)),//for sim
    .flush_i                ( '0                ),
    .flush_ack_o            ( ),         
    .miss_o                 ( ),           
                
    .data_if                ( axi_data             ),
    .bypass_if              ( axi_bypass           ),
      
    .data_addr_i            ( dcache_data_addr     ),
    .data_wdata_i           ( dcache_data_wdata    ),
    .data_we_i              ( dcache_data_we       ),
    .data_req_i             ( dcache_data_req      ),
    .data_be_i              ( dcache_data_be       ),
    .data_rdata_o           ( dcache_data_rdata    ),
    .data_gnt_o             ( dcache_data_gnt      ),
    .data_rvalid_o          ( dcache_data_rvalid   ),
        
    .data_size_i            ( dcache_data_size     ),
                
    .kill_req_i             ('0                    ),
    .tag_valid_i            ('0                    )  
);

`endif
/////////////////////////////////////////////////////////////
riscv_irq_sync u_riscv_irq_sync(
  .clk        ( clk_i      ),    // Clock
  .rst_n      ( rst_ni      ),  // Asynchronous reset active low
  .irq_gpio_i ( irq_gpio_i ),
  .irq_timer_i( irq_timer_i),
  .irq_debug_i( irq_debug_i),
  .irq_debug_sync_o (irq_debug_sync_o),
  .debug_mode_i(debug_mode_i),
  .irq_o      ( irq        ),
  .irq_id_o   ( irq_id_out  ),
  .irq_ack_i  ( irq_ack    ),
  .irq_id_i   ( irq_id_in  ),
  .irq_sec_o  ( irq_sec    ),
  .irq_timer_sync_o(irq_timer_sync),  
  .irq_gpio_sync_o  (irq_gpio_sync));
endmodule