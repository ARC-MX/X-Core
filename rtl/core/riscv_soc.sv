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
   
import riscv_package::*;
`include "../../rtl/core/axi_bus.sv"
`include "../../rtl/core/riscv_config.sv"
module riscv_cpu_top
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
                    
  input  logic                            fetch_enable_i ,
  output logic                            core_busy_o    ,

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
  input  logic                            data_rvalid_i,
`else 
  AXI_BUS.Master                          axi_instr      ,
  AXI_BUS.Master                          axi_data       ,
  AXI_BUS.Master                          axi_bypass     ,
`endif
  
  //debug unit interface
  input  logic                            io_pads_jtag_TCK_i_ival,   
  input  logic                            io_pads_jtag_TMS_i_ival,                                   
  input  logic                            io_pads_jtag_TDI_i_ival,   
                               
  output logic                            io_pads_jtag_TDO_o_oval,   
  output logic                            io_pads_jtag_TDO_o_oe,     
  input logic                            io_pads_jtag_TRST_n_i_ival,

  input  logic                            hfclk_i,
  output  logic                            inspect_jtag_clk_i,    

  AXI_BUS.Slave                           axi_debug      

);


logic           clk_core;
logic  [31:0]   core_dpc;    
logic           core_dpc_ena;
logic  [2:0]    core_dcause;
logic           core_dcause_ena;
logic  [31:0]   core_csr_rdata;
logic  [31:0]   core_csr_wdata;
logic  [31:0]   core_csr_addr; 
logic           core_csr_we;   

logic           core_dbg_mode;
logic           core_dbg_ebreakm;
logic           core_dbg_ebreaku;
logic           core_dbg_ebreaks;
logic           core_dbg_stopcycle;

logic           core_dbg_irq;
logic           core_irq_debug_sync;

logic [31:0]    core_csr_dcsr;
logic [31:0]    core_csr_dpc;
logic 		    debug_step;
logic     		debug_halt_new;
logic			dbg_csr_set;

riscv_cpu
#(
  .N_EXT_PERF_COUNTERS    ( N_EXT_PERF_COUNTERS   ),
  .INSTR_RDATA_WIDTH      ( INSTR_RDATA_WIDTH     ),
  .RISCV_SECURE           ( RISCV_SECURE          ),
  .RISCV_CLUSTER          ( RISCV_CLUSTER         ),
  .INSTR_TLB_ENTRIES      ( INSTR_TLB_ENTRIES     ),
  .DATA_TLB_ENTRIES       ( DATA_TLB_ENTRIES      ),
  .MMU_ASID_WIDTH         ( MMU_ASID_WIDTH        ),
        
  .INSTR_ADDR_WIDTH       ( INSTR_ADDR_WIDTH      ),    
  .INSTR_DATA_WIDTH       ( INSTR_DATA_WIDTH      ),    
  .INSTR_ID_WIDTH         ( INSTR_ID_WIDTH        ),
                              
  .INSTR_AXI_ADDR_WIDTH   ( INSTR_AXI_ADDR_WIDTH  ),
  .INSTR_AXI_DATA_WIDTH   ( INSTR_AXI_DATA_WIDTH  ),
  .INSTR_AXI_USER_WIDTH   ( INSTR_AXI_USER_WIDTH  ),
                                  
  .INSTR_AXI_ID_WIDTH     ( INSTR_AXI_ID_WIDTH    ),
  .INSTR_SLICE_DEPTH      ( INSTR_SLICE_DEPTH     ),
  .INSTR_AXI_STRB_WIDTH   ( INSTR_AXI_STRB_WIDTH  ),
                                  
  .INSTR_NB_BANKS         ( INSTR_NB_BANKS        ),
  .INSTR_NB_WAYS          ( INSTR_NB_WAYS         ),
  .INSTR_CACHE_SIZE       ( INSTR_CACHE_SIZE      ),
  .INSTR_CACHE_LINE       ( INSTR_CACHE_LINE      ),

  .DATA_CACHE_START_ADDR  ( DATA_CACHE_START_ADDR ),
  .DATA_AXI_ID_WIDTH      ( DATA_AXI_ID_WIDTH     ),
  .DATA_AXI_USER_WIDTH    ( DATA_AXI_USER_WIDTH   )

) riscv_cpu (
  .clk_i            ( clk_i                   ),
  .rst_ni           ( rst_ni                  ),
  .clk_ila			(clk_ila					),                 
  .clock_en_i       ( clock_en_i              ), 
  .test_en_i        ( test_en_i               ), 
                        
  .boot_addr_i      ( boot_addr_i             ),
  .core_id_i        ( core_id_i               ), 
  .cluster_id_i     ( cluster_id_i            ),
    
  .irq_gpio_i       ( irq_gpio_i              ),
  .irq_timer_i      ( irq_timer_i             ),                             
  .sec_lvl_o        ( sec_lvl_o               ),
   
   ////PULP reserve debug interface//////////                           
  .debug_req_i      ( debug_req_i                    ),
  .debug_gnt_o      ( debug_gnt_o                    ),
  .debug_rvalid_o   ( debug_rvalid_o                 ), 
  .debug_addr_i     ( debug_addr_i                   ),
  .debug_we_i       ( debug_we_i                     ), 
  .debug_wdata_i    ( debug_wdata_i                  ),
  .debug_rdata_o    ( debug_rdata_o                  ),
  .debug_halted_o   ( debug_halted_o                 ), 
  .debug_halt_i     ( debug_halt_i                   ),     
  .debug_resume_i   ( debug_resume_i                 ),  
  ////////////////////////////////////////////

  // sifive Debug Unit
  .irq_debug_sync_o ( core_irq_debug_sync   ),
  .irq_debug_i      ( core_dbg_irq          ),
  
  .debug_mode_i     ( core_dbg_mode         ),
  .debug_stopcycle_i( core_dbg_stopcycle    ),
  .debug_ebreakm_i  ( core_dbg_ebreakm      ),
  .debug_ebreaks_i  ( core_dbg_ebreaks	    ),
  .debug_ebreaku_i  ( core_dbg_ebreaku      ),
  .debug_step_i		( debug_step			),
  .debug_halt_new_i ( debug_halt_new		),
  .debug_csr_dpc_i  ( core_csr_dpc          ),
  .debug_csr_dcsr_i ( core_csr_dcsr	        ),
  .debug_csr_rdata_i( core_csr_rdata        ),
  .debug_csr_wdata_o( core_csr_wdata        ),
  .debug_csr_addr_o ( core_csr_addr         ),
  .debug_csr_we_o   ( core_csr_we           ),
  .dbg_csr_set_o	(dbg_csr_set),
  .debug_dpc_o      ( core_dpc              ),      
  .debug_dpc_en_o   ( core_dpc_ena          ),   
  .debug_dcause_en_o( core_dcause_ena       ),
  .debug_dcause_o   ( core_dcause           ), 
  .debug_csr_dret_o ( ),      
                   
  .fetch_enable_i   ( fetch_enable_i        ), 
  .core_busy_o      ( core_busy_o           ),
       
  .clk_core_o       ( clk_core              ),
                               
  .ext_perf_counters_i  (  '0               ),
   
`ifdef DIS_CACHE   
      // Instruction memory interface   
  .instr_addr_o  ( instr_addr_o               ),
  .instr_req_o   ( instr_req_o                ),
  .instr_rdata_i ( instr_rdata_i              ),
  .instr_gnt_i   ( instr_gnt_i                ),
  .instr_rvalid_i( instr_rvalid_i             ),
        
  .data_addr_o   ( data_addr_o                ),
  .data_wdata_o  ( data_wdata_o               ),
  .data_we_o     ( data_we_o                  ),
  .data_req_o    ( data_req_o                 ),
  .data_be_o     ( data_be_o                  ),
  .data_rdata_i  ( data_rdata_i               ),
  .data_gnt_i    ( data_gnt_i                 ),
  .data_rvalid_i ( data_rvalid_i              )
`else    
  .axi_bypass    ( axi_bypass            ),
  .axi_data      ( axi_data              ),
  .axi_instr     ( axi_instr             )
`endif
);


debug_top  #(
  .SUPPORT_JTAG_DTM (1),
  .ASYNC_FF_LEVELS (2),
  .PC_SIZE (32),
  .HART_NUM (1),
  .HART_ID_W (1)
  ) debug_top (
  .debug_axi        (  axi_debug         ),
  .core_csr_clk     (  clk_core          ),
  .hfclk            (  hfclk_i           ),
  .corerst          (  ~rst_ni            ),
    
  .inspect_jtag_clk ( inspect_jtag_clk_i ),
  
  .test_mode        ( test_en_i         ),
  // The interface with commit stage
  .cmt_dpc          ( core_dpc          ),
  .cmt_dpc_ena      ( core_dpc_ena      ),
      
  .cmt_dcause       ( core_dcause       ),
  .cmt_dcause_ena   ( core_dcause_ena   ),
      
  .dbg_irq_r        ( core_irq_debug_sync),
          
  .dcsr_r           ( core_csr_dcsr       ),
  .dpc_r            ( core_csr_dpc        ),
  .dscratch_r       ( ),

  .debug_csr_rdata_o( core_csr_rdata      ),
  .debug_csr_wdata_i( core_csr_wdata      ),
  .debug_csr_addr_i ( core_csr_addr       ),
  .debug_csr_we_i   ( core_csr_we         ),
  .dbg_csr_set_i	(dbg_csr_set		  ),

  .dbg_mode         ( core_dbg_mode       ),
  .dbg_halt_r       ( debug_halt_new),
  .dbg_step_r       ( debug_step),
  .dbg_ebreakm_r    ( core_dbg_ebreakm    ),
  .dbg_ebreaku_r    ( core_dbg_ebreaku    ),
  .dbg_ebreaks_r    ( core_dbg_ebreaks    ),
  .dbg_stopcycle    ( core_dbg_stopcycle  ),
  // To the target hart
  .o_dbg_irq        ( core_dbg_irq        ),
  .o_ndreset        ( ),
  .o_fullreset      ( ),

   // The JTAG TCK is input, need to be pull-up
  .io_pads_jtag_TCK_i_ival    ( io_pads_jtag_TCK_i_ival    ),
    
   // The JTAG TMS is input, need to be pull-up   
  .io_pads_jtag_TMS_i_ival    ( io_pads_jtag_TMS_i_ival    ),
    
   // The JTAG TDI is input, need to be pull-up   
  .io_pads_jtag_TDI_i_ival    ( io_pads_jtag_TDI_i_ival    ),
    
   // The JTAG TDO is output have enable    
  .io_pads_jtag_TDO_o_oval    ( io_pads_jtag_TDO_o_oval    ),
  .io_pads_jtag_TDO_o_oe      ( io_pads_jtag_TDO_o_oe      ),
  .io_pads_jtag_TRST_n_i_ival ( io_pads_jtag_TRST_n_i_ival )
  );


endmodule