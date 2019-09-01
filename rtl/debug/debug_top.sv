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

// `include "axi_bus.sv"
module debug_top  # (
                parameter SUPPORT_JTAG_DTM = 1,
                parameter ASYNC_FF_LEVELS = 2,
                parameter PC_SIZE = 32,
                parameter HART_NUM = 1,
                parameter HART_ID_W = 1
  )
                (
                AXI_BUS.Slave      debug_axi,
                input   core_csr_clk,
                input   hfclk,
                input   corerst,

                output  inspect_jtag_clk,

                input   test_mode,
                  // The interface with commit stage
                input   [PC_SIZE-1:0] cmt_dpc,
                input   cmt_dpc_ena,

                input   [3-1:0] cmt_dcause,
                input   cmt_dcause_ena,

                input  dbg_irq_r,

                output[32-1:0] dcsr_r    ,
                output[PC_SIZE-1:0] dpc_r,
                output[32-1:0] dscratch_r,

                output [31:0] debug_csr_rdata_o,
                input  [31:0] debug_csr_wdata_i,
                input  [31:0] debug_csr_addr_i,
                input         debug_csr_we_i,
				input 		  dbg_csr_set_i,

                output dbg_mode,
                output dbg_halt_r,
                output dbg_step_r,
                output dbg_ebreakm_r,
                output dbg_ebreaku_r,
                output dbg_ebreaks_r,
                output dbg_stopcycle,
                // To the target hart
                output [HART_NUM-1:0]      o_dbg_irq,
                output [HART_NUM-1:0]      o_ndreset,
                output [HART_NUM-1:0]      o_fullreset,

                // The JTAG TCK is input, need to be pull-up
                input   io_pads_jtag_TCK_i_ival,

                // The JTAG TMS is input, need to be pull-up
                input   io_pads_jtag_TMS_i_ival,

                // The JTAG TDI is input, need to be pull-up
                input   io_pads_jtag_TDI_i_ival,

                // The JTAG TDO is output have enable
                output  io_pads_jtag_TDO_o_oval,
                output  io_pads_jtag_TDO_o_oe,
                input   io_pads_jtag_TRST_n_i_ival
  );

  	logic 				icb_cmd_valid;	
	logic 				icb_cmd_ready;	
	logic 	[31:0]		icb_cmd_addr;	
	logic 				icb_cmd_read;	
	logic 	[31:0]		icb_cmd_wdata;	
	logic 				icb_rsp_valid_d;
	logic 	[31:0]		icb_rsp_rdata_d;
	logic 				icb_rsp_valid;
	logic 	[31:0]		icb_rsp_rdata;
	logic 				icb_rsp_ready;	
	
	
	sirv_debug_module u_sirv_debug_module(
		.inspect_jtag_clk    (inspect_jtag_clk),
		
		.test_mode       (test_mode ),
		.core_csr_clk    (core_csr_clk),
		
		.dbg_irq_r       (dbg_irq_r      ),
		
		.cmt_dpc         (cmt_dpc        ),
		.cmt_dpc_ena     (cmt_dpc_ena    ),
		.cmt_dcause      (cmt_dcause     ),
		.cmt_dcause_ena  (cmt_dcause_ena ),
		
		.dcsr_r          (dcsr_r         ),
		.dpc_r           (dpc_r          ),
		.dscratch_r      (dscratch_r     ),
		
		.dbg_mode        (dbg_mode),
		.dbg_halt_r      (dbg_halt_r),
		.dbg_step_r      (dbg_step_r),
		.dbg_ebreakm_r   (dbg_ebreakm_r),
		.dbg_ebreaku_r   (dbg_ebreaku_r),
		.dbg_ebreaks_r   (dbg_ebreaks_r),
		.dbg_stopcycle   (dbg_stopcycle),
		
		.debug_csr_rdata_o(debug_csr_rdata_o),
		.debug_csr_wdata_i(debug_csr_wdata_i),
		.debug_csr_addr_i(debug_csr_addr_i),
		.debug_csr_we_i(debug_csr_we_i),
		.dbg_csr_set_i(dbg_csr_set_i),
		.io_pads_jtag_TCK_i_ival     (io_pads_jtag_TCK_i_ival    ),
		.io_pads_jtag_TCK_o_oval     (),
		.io_pads_jtag_TCK_o_oe       (),
		.io_pads_jtag_TCK_o_ie       (),
		.io_pads_jtag_TCK_o_pue      (),
		.io_pads_jtag_TCK_o_ds       (),
		.io_pads_jtag_TMS_i_ival     (io_pads_jtag_TMS_i_ival    ),
		.io_pads_jtag_TMS_o_oval     (),
		.io_pads_jtag_TMS_o_oe       (),
		.io_pads_jtag_TMS_o_ie       (),
		.io_pads_jtag_TMS_o_pue      (),
		.io_pads_jtag_TMS_o_ds       (),
		.io_pads_jtag_TDI_i_ival     (io_pads_jtag_TDI_i_ival    ),
		.io_pads_jtag_TDI_o_oval     (),
		.io_pads_jtag_TDI_o_oe       (),
		.io_pads_jtag_TDI_o_ie       (),
		.io_pads_jtag_TDI_o_pue      (),
		.io_pads_jtag_TDI_o_ds       (),
		.io_pads_jtag_TDO_i_ival     (1'b1),
		.io_pads_jtag_TDO_o_oval     (io_pads_jtag_TDO_o_oval    ),
		.io_pads_jtag_TDO_o_oe       (io_pads_jtag_TDO_o_oe      ),
		.io_pads_jtag_TDO_o_ie       (),
		.io_pads_jtag_TDO_o_pue      (),
		.io_pads_jtag_TDO_o_ds       (),
		.io_pads_jtag_TRST_n_i_ival  (io_pads_jtag_TRST_n_i_ival ),
		.io_pads_jtag_TRST_n_o_oval  (),
		.io_pads_jtag_TRST_n_o_oe    (),
		.io_pads_jtag_TRST_n_o_ie    (),
		.io_pads_jtag_TRST_n_o_pue   (),
		.io_pads_jtag_TRST_n_o_ds    (),
		
		.i_icb_cmd_valid         (icb_cmd_valid),
		.i_icb_cmd_ready         (icb_cmd_ready),
		.i_icb_cmd_addr          (icb_cmd_addr[11:0] ),
		.i_icb_cmd_read          (icb_cmd_read),
		.i_icb_cmd_wdata         (icb_cmd_wdata),
		
		.i_icb_rsp_valid         (icb_rsp_valid),
		.i_icb_rsp_ready         (icb_rsp_ready),
		.i_icb_rsp_rdata         (icb_rsp_rdata),
		
		.o_dbg_irq               (o_dbg_irq),
		.o_ndreset               (o_ndreset),
		.o_fullreset             (o_fullreset),
		
		.hfclk           (hfclk),
		.corerst         (corerst)
	);

	always_ff @(posedge hfclk) begin
		icb_rsp_valid_d<=icb_rsp_valid;
		icb_rsp_rdata_d <= icb_rsp_rdata;
	end

// ila_ram u_ila_ram (
	// .clk(hfclk), // input wire clk


	// .probe0(i_icb_cmd_valid), // input wire [31:0]  probe0  
	// .probe1(i_icb_cmd_we), // input wire [31:0]  probe1 
	// .probe2(i_icb_cmd_addr), // input wire [31:0]  probe2 
	// .probe3(i_icb_cmd_wdata), // input wire [31:0]  probe3 
	// .probe4(i_icb_rsp_rdata_dly), // input wire [31:0]  probe4 
	// .probe5(icb_r_valid_d), // input wire [31:0]  probe5 
	// .probe6(icb_ready) // input wire [31:0]  probe6
// );

	axi_slave2icb_dbg u_debug_axi (
		.icb_cmd_valid			(icb_cmd_valid		),       	 	// output wire icb_cmd_valid
		.icb_cmd_ready			(icb_cmd_ready		),        		// input wire icb_cmd_ready
		.icb_cmd_addr			(icb_cmd_addr		),          	// output wire [31 : 0] icb_cmd_addr
		.icb_cmd_read			(icb_cmd_read		),          	// output wire icb_cmd_read
		.icb_cmd_wdata			(icb_cmd_wdata		),        		// output wire [31 : 0] icb_cmd_wdata
		.icb_rsp_valid			(icb_rsp_valid_d	),        		// input wire icb_rsp_valid
		.icb_rsp_rdata			(icb_rsp_rdata_d	),        		// input wire [31 : 0] icb_rsp_rdata
		.icb_rsp_ready			(icb_rsp_ready		),        		// output wire icb_rsp_ready
		.s00_axi_awid			(debug_axi.aw_id	),  	        // input wire [0 : 0] s00_axi_awid
		.s00_axi_awaddr			(debug_axi.aw_addr	),  	    	// input wire [31 : 0] s00_axi_awaddr
		.s00_axi_awlen			(debug_axi.aw_len	),  	    	// input wire [7 : 0] s00_axi_awlen
		.s00_axi_awsize			(debug_axi.aw_size	),  	    	// input wire [2 : 0] s00_axi_awsize
		.s00_axi_awburst		(debug_axi.aw_burst	),  	  		// input wire [1 : 0] s00_axi_awburst
		.s00_axi_awlock			(debug_axi.aw_lock	),  	    	// input wire s00_axi_awlock
		.s00_axi_awcache		(debug_axi.aw_cache	),  	  		// input wire [3 : 0] s00_axi_awcache
		.s00_axi_awprot			(debug_axi.aw_prot	),  	    	// input wire [2 : 0] s00_axi_awprot
		.s00_axi_awqos			(debug_axi.aw_qos	),        		// input wire [3 : 0] s00_axi_awqos
		.s00_axi_awvalid		(debug_axi.aw_valid	),    			// input wire s00_axi_awvalid
		.s00_axi_awready		(debug_axi.aw_ready	),    			// output wire s00_axi_awready
		.s00_axi_wdata			(debug_axi.w_data	),        		// input wire [31 : 0] s00_axi_wdata
		.s00_axi_wstrb			(debug_axi.w_strb	),        		// input wire [3 : 0] s00_axi_wstrb
		.s00_axi_wlast			(debug_axi.w_last	),        		// input wire s00_axi_wlast
		.s00_axi_wvalid			(debug_axi.w_valid	),      		// input wire s00_axi_wvalid
		.s00_axi_wready			(debug_axi.w_ready	),      		// output wire s00_axi_wready
		.s00_axi_bid			(debug_axi.b_id		),            	// output wire [0 : 0] s00_axi_bid
		.s00_axi_bresp			(debug_axi.b_resp	),        		// output wire [1 : 0] s00_axi_bresp
		.s00_axi_bvalid			(debug_axi.b_valid	),      		// output wire s00_axi_bvalid
		.s00_axi_bready			(debug_axi.b_ready	),      		// input wire s00_axi_bready
		.s00_axi_arid			(debug_axi.ar_id	),          	// input wire [0 : 0] s00_axi_arid
		.s00_axi_araddr			(debug_axi.ar_addr	),      		// input wire [31 : 0] s00_axi_araddr
		.s00_axi_arlen			(debug_axi.ar_len	),        		// input wire [7 : 0] s00_axi_arlen
		.s00_axi_arsize			(debug_axi.ar_size	),      		// input wire [2 : 0] s00_axi_arsize
		.s00_axi_arburst		(debug_axi.ar_burst	),    			// input wire [1 : 0] s00_axi_arburst
		.s00_axi_arlock			(debug_axi.ar_lock	),      		// input wire s00_axi_arlock
		.s00_axi_arcache		(debug_axi.ar_cache	),    			// input wire [3 : 0] s00_axi_arcache
		.s00_axi_arprot			(debug_axi.ar_prot	),      		// input wire [2 : 0] s00_axi_arprot
		.s00_axi_arqos			(debug_axi.ar_qos	),        		// input wire [3 : 0] s00_axi_arqos
		.s00_axi_arvalid		(debug_axi.ar_valid	),    			// input wire s00_axi_arvalid
		.s00_axi_arready		(debug_axi.ar_ready	),    			// output wire s00_axi_arready
		.s00_axi_rid			(debug_axi.r_id		),           	// output wire [0 : 0] s00_axi_rid
		.s00_axi_rdata			(debug_axi.r_data	),        		// output wire [31 : 0] s00_axi_rdata
		.s00_axi_rresp			(debug_axi.r_resp	),        		// output wire [1 : 0] s00_axi_rresp
		.s00_axi_rlast			(debug_axi.r_last	),        		// output wire s00_axi_rlast
		.s00_axi_rvalid			(debug_axi.r_valid	),      		// output wire s00_axi_rvalid
		.s00_axi_rready			(debug_axi.r_ready	),      		// input wire s00_axi_rready
		.s00_axi_aclk			(hfclk				),          	// input wire s00_axi_aclk
		.s00_axi_aresetn		(~corerst			)    			// input wire s00_axi_aresetn
	);

endmodule


