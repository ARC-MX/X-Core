   
`timescale 1ns / 1ps

import riscv_package::*;
`include "../../rtl/core/riscv_config.sv"
// `include "axi_bus.sv"

module riscv_soc_top(
	
	input clk_i,
	input resetn,
	input clk_ila,
	input jtag_tms,                                   
	input jtag_tdi,   

	output jtag_tdo,   
	input jtag_clk,
	output   iic_intr,
    inout iic_scl_io,
    inout iic_sda_io,
    output pwm0,
	//output pwm1,
    output spi0_intr,
    output spi1_intr,
    inout spi_0_io0_io,
    inout spi_0_io1_io,
    inout spi_0_io2_io,
    inout spi_0_io3_io,
    output spi_0_sck_io,
    output spi_0_ss_io,
    inout spi_1_io0_io,
    inout spi_1_io1_io,
    inout spi_1_io2_io,
    inout spi_1_io3_io,
    inout spi_1_sck_io,
    inout spi_1_ss_io,
    output timer0_intr,
    output uart_intr,
	input	irq_gpio_i,
	input 	irq_timer_i,
	input 	UART_rxd,
	output 	UART_txd,
	input Vaux10_0_v_n,
    input Vaux10_0_v_p,
    input Vaux1_0_v_n,
    input Vaux1_0_v_p,
    input Vaux2_0_v_n,
    input Vaux2_0_v_p,
    input Vaux9_0_v_n,
    input Vaux9_0_v_p,
	input Vp_Vn_v_n,
	input Vp_Vn_v_p,
	AXI_BUS.Master                          PPI_AXi,
	AXI_BUS.Master                          MEM_AXi,
	AXI_BUS.Master                          PLIC_AXi,
	AXI_BUS.Master                          CLINT_AXi
);
	
	AXI_BUS	#(.C_M_AXI_ADDR_WIDTH(32), .C_M_AXI_ID_WIDTH(2))Instr_AXI ();
	AXI_BUS	#(.C_M_AXI_ADDR_WIDTH(32), .C_M_AXI_ID_WIDTH(2))Data_AXI ();
	// AXI_BUS	#(.C_M_AXI_ADDR_WIDTH(32))PPI_AXi ();
	// AXI_BUS	#(.C_M_AXI_ADDR_WIDTH(32))MEM_AXi ();
	// AXI_BUS	#(.C_M_AXI_ADDR_WIDTH(32))PLIC_AXi ();
	AXI_BUS	#(.C_M_AXI_ADDR_WIDTH(32), .C_M_AXI_ID_WIDTH(2))DEBUG_AXI ();
	
	logic fetch_enable_i;
	logic [3:0]fetch_enable_i_d;
	
	

	logic counter_clk;
	
	logic		refill_instr_req;
	logic		refill_gnt;
	logic		refill_r_valid;
	logic		[33:0]	refill_addr;
	logic		[31:0]	refill_r_data;		
	
	logic		Data_req;
	logic		Data_gnt;
	logic		Data_valid;
	logic		Data_we;
	logic	[3:0]	Data_be;
	logic	[33:0]	Data_addr;
	logic	[31:0]	Data_wdata;
	logic	[31:0]	Data_rdata;
	logic   [2:0]   size;
	
	parameter ADDR_MUX = 'b1;
	
	logic refill_instr_req_itcm;
	logic refill_instr_req_axi;
	logic Data_req_dtcm;
	logic Data_req_axi;
	logic Data_we_dtcm;
	logic Data_we_axi;
	logic Data_gnt_axi;
	logic Data_valid_axi;
	logic Data_valid_dtcm;
	logic Data_gnt_dtcm;
	logic [31:0]refill_r_data_itcm;
	logic [31:0]refill_r_data_axi;
	logic [31:0]Data_rdata_dtcm;
	logic [31:0]Data_rdata_axi;
	
	logic refill_r_valid_itcm; 
	logic refill_r_valid_axi;
	logic refill_gnt_itcm;
	logic refill_gnt_axi;
	logic clk_counter;
	logic io0_o_0;
	logic io0_i_0;
    logic io0_t_0;
	logic io1_i_0;
    logic io1_o_0;
    logic io1_t_0;
	logic sck_i_0;
	logic sck_o_0;
    logic sck_t_0;
	logic ss_i_0;
	logic ss_o_0;
	logic ss_t_0;
	wire spi_0_io0_i;
 // wire spi_0_io0_io;
  wire spi_0_io0_o;
  wire spi_0_io0_t;
  wire spi_0_io1_i;
  //wire spi_0_io1_io;
  wire spi_0_io1_o;
  wire spi_0_io1_t;
  wire spi_0_io2_i;
  //wire spi_0_io2_io;
  wire spi_0_io2_o;
  wire spi_0_io2_t;
  wire spi_0_io3_i;
  //wire spi_0_io3_io;
  wire spi_0_io3_o;
  wire spi_0_io3_t;
	
	always @ (posedge clk_i)
    begin
        if(!resetn)
           begin
             fetch_enable_i_d <= 0;
             fetch_enable_i <= 0;
            end
         else
             begin
                fetch_enable_i_d[0] <= 1;
                fetch_enable_i_d[1] <= fetch_enable_i_d[0];
                fetch_enable_i_d[2] <= fetch_enable_i_d[1];
                fetch_enable_i_d[3] <= fetch_enable_i_d[2];
                fetch_enable_i <= fetch_enable_i_d[3];                              
             end
    end
	riscv_cpu_top #(
		.N_EXT_PERF_COUNTERS 	( 0),
		.INSTR_RDATA_WIDTH   	(32),
		.RISCV_SECURE        	( 1),
		.RISCV_CLUSTER       	( 1),
		.INSTR_TLB_ENTRIES   	(4),
		.DATA_TLB_ENTRIES    	(4),
		.MMU_ASID_WIDTH      	( 9),
	
		.INSTR_ADDR_WIDTH 		(34),       
		.INSTR_DATA_WIDTH 		(32),       
		.INSTR_ID_WIDTH   		(4 ),
	
		.INSTR_AXI_ADDR_WIDTH   ( 34),
		.INSTR_AXI_DATA_WIDTH   ( 32),
		.INSTR_AXI_USER_WIDTH   ( 6),
								
		.INSTR_AXI_ID_WIDTH     ( 4),
		.INSTR_SLICE_DEPTH      ( 2),
		.INSTR_AXI_STRB_WIDTH   ( 4),
								
		.INSTR_NB_BANKS         ( 1),       
		.INSTR_NB_WAYS          ( 2),      
		.INSTR_CACHE_SIZE       ( 8*64),  
		.INSTR_CACHE_LINE       ( 2),
								
		.DATA_CACHE_START_ADDR  ( 32'h0000_0000),
		.DATA_AXI_ID_WIDTH      ( 10),
		.DATA_AXI_USER_WIDTH    ( 1))
	U_riscv_cpu_top(
		.clk_i         				(clk_i				),
		.rst_ni        				(resetn				),
		.clk_ila					(clk_ila			),		
		.clock_en_i    				('1					),
		.test_en_i     				('0					),
						
		.boot_addr_i   				(32'h20000000		),
		.core_id_i     				('0					),
		.cluster_id_i  				('0					),
						
		.irq_gpio_i    				(irq_gpio_i			),
		.irq_timer_i   				(irq_timer_i		),
					
		.sec_lvl_o     				(					),
					
					
		.debug_req_i    			('0					),
		.debug_gnt_o    			(					),
		.debug_rvalid_o 			(					),
		.debug_addr_i   			('0					),
		.debug_we_i     			('0					),
		.debug_wdata_i  			('0					),
		.debug_rdata_o  			(					),
		.debug_halted_o 			(					),
		.debug_halt_i   			('0					),
		.debug_resume_i 			('0					),
					
		.fetch_enable_i 			(fetch_enable_i		),
		.core_busy_o    			(					),
	
		.ext_perf_counters_i 		('0					),
`ifdef DIS_CACHE	
		.instr_req_o				(refill_instr_req	),
		.instr_gnt_i				(refill_gnt			),
		.instr_rvalid_i				(refill_r_valid		),
		.instr_addr_o				(refill_addr		),
		.instr_rdata_i				(refill_r_data		),
	
	  // Data memory interface	
		.data_req_o					(Data_req			),
		.data_gnt_i					(Data_gnt			),
		.data_rvalid_i				(Data_valid			),
		.data_we_o					(Data_we			),
		.data_be_o					(Data_be			),
		.data_addr_o				(Data_addr			),
		.data_wdata_o				(Data_wdata			),
		.data_rdata_i				(Data_rdata			),
`else 	
		.axi_instr      			(Instr_AXI			),
		.axi_data       			(Data_AXI			),
		.axi_bypass     			(BYPASS_AXI			),
`endif
  
  //debug unit interface	
		.io_pads_jtag_TCK_i_ival	(jtag_clk			),   
		.io_pads_jtag_TMS_i_ival	(jtag_tms			),                                   
		.io_pads_jtag_TDI_i_ival	(jtag_tdi			),   
			
		.io_pads_jtag_TDO_o_oval	(jtag_tdo			),   
		.io_pads_jtag_TDO_o_oe		(					),     
		.io_pads_jtag_TRST_n_i_ival	(resetn				),
		.hfclk_i					(clk_i				),
		.inspect_jtag_clk_i			(					),    
		
		.axi_debug 			 		(DEBUG_AXI			)    

	);
	
	
	/*ila_0 your_instance_name (
	.clk(clk_i), // input wire clk


	.probe0(Data_wdata), // input wire [31:0]  probe0  
	.probe1(Data_addr[31:0]),
	.probe2(Data_rdata),
	.probe3(pc_id),
	// .probe4(refill_r_data),
	// .probe5(refill_addr[31:0]),
	// .probe6(refill_r_valid),
	// .probe7(Data_we),
	// .probe8(Data_valid),
	// .probe9(Data_gnt),
	// .probe10(Data_req),
	// .probe11(Data_be)
	.probe4(Data_we),
	.probe5(Data_valid),
	.probe6(Data_gnt),
	.probe7(Data_req),
	.probe8(Data_be)
		
);*/
	
	always_comb 
	begin
		if(refill_addr[33:28] == 8)
		// if(refill_addr[33:28] == 8)
			begin	
				refill_instr_req_itcm = refill_instr_req;
				refill_instr_req_axi = 'b0;
			end
		else
			begin
				refill_instr_req_itcm = 'b0;
				refill_instr_req_axi = refill_instr_req;
			end
	end
	
	always_comb 
	begin
		if(Data_addr[33:28] == 8)
		// if(Data_addr[33:28] == 9) 
			begin	
				Data_req_dtcm = Data_req;
				Data_we_dtcm = Data_we;
				Data_req_axi = 0;
				Data_we_axi = 0;
			end
		else
			begin
				Data_req_dtcm = 0;
				Data_we_dtcm = 0;
				Data_req_axi = Data_req;
				Data_we_axi = Data_we;
			end
	end
	
	assign refill_r_valid = refill_r_valid_axi || refill_r_valid_itcm;
	assign refill_gnt = refill_gnt_axi || refill_gnt_itcm;

	always_comb
	begin
		if(refill_r_valid_itcm)
			refill_r_data = refill_r_data_itcm;
		else if(refill_r_valid_axi)
			refill_r_data = refill_r_data_axi;
		else
			refill_r_data = 0;
	end
	
	assign Data_valid = Data_valid_dtcm || Data_valid_axi;
	assign Data_gnt = Data_gnt_dtcm || Data_gnt_axi;
	
	always_comb
	begin
		if(Data_valid_dtcm)
			Data_rdata = Data_rdata_dtcm;
		else
			Data_rdata = Data_rdata_axi;
	end
			
	instr_axi	Instr_axi(
		.clk_i						(clk_i							),
		.rst_ni						(resetn							),
		.refill_req_i				(refill_instr_req_axi			),
		.refill_type_i				(1'b0							),	// 0 | 1 : 0 --> 32 Bit ,  1--> 64bit
		.refill_gnt_o				(refill_gnt_axi					),
		.refill_addr_i				(refill_addr					),
		.refill_ID_i				(4'd0							),
		
		.refill_r_valid_o			(refill_r_valid_axi				),
		.refill_r_data_o			(refill_r_data_axi				),
		.refill_r_last_o			(								),
		.refill_r_ID_o				(								),
		
		.axi						(Instr_AXI						)
	); 
		
	data_axi #(
        .DATA_WIDTH            		(32								))
	Data_axi(
		.clk_i						(clk_i							),
		.rst_ni						(resetn							),
		.req_i                 		(Data_req_axi					),
        .type_i                		(SINGLE_REQ						),        
        .gnt_o                 		(Data_gnt_axi					),  
        .addr_i                		(Data_addr						), 
        .we_i                  		(Data_we_axi					),   
        .wdata_i               		(Data_wdata						),
        .be_i                  		(Data_be						),   
        .size_i                		(2'b10							),
        .id_i                  		(4'd0							),
        .valid_o               		(Data_valid_axi					),
        .rdata_o               		(Data_rdata_axi					),
        .gnt_id_o      				(								),            
        .id_o                  		(								),            
        .critical_word_o       		(								),            
        .critical_word_valid_o 	    (								),            
        .axi                   		(Data_AXI						) 
    );
	
	ram 
		#(. ADDR_WIDTH ( 34))
	RAM(
		.clk						(clk_i							),
				
		.instr_req_i				(refill_instr_req_itcm			),
		.instr_addr_i				(refill_addr					),
		.instr_rdata_o				(refill_r_data_itcm				),
		.instr_rvalid_o				(refill_r_valid_itcm			),
		.instr_gnt_o				(refill_gnt_itcm				),
				
		.data_req_i					(Data_req_dtcm					),
		.data_addr_i				(Data_addr						),
		.data_we_i					(Data_we_dtcm					),
		.data_be_i					(Data_be						),
		.data_wdata_i				(Data_wdata						),
		.data_rdata_o				(Data_rdata_dtcm				),
		.data_rvalid_o				(Data_valid_dtcm				),
		.data_gnt_o					(Data_gnt_dtcm					)
	);
	
	
	design_top AXI_INTERCONNECT(
		.ACLK						(clk_i							),
		.ARESETN					(resetn							),
		.DATA_araddr				(Data_AXI.ar_addr[31:0]			),
		.DATA_arburst				(Data_AXI.ar_burst				),
		.DATA_arcache				(Data_AXI.ar_cache				),
		.DATA_arid					(Data_AXI.ar_id[1:0]			),
		.DATA_arlen					(Data_AXI.ar_len				),
		.DATA_arlock				(Data_AXI.ar_lock				),
		.DATA_arprot				(Data_AXI.ar_prot				),
		.DATA_arqos					(Data_AXI.ar_qos				),
		.DATA_arready				(Data_AXI.ar_ready				),
		.DATA_arsize				(Data_AXI.ar_size				),
		.DATA_arvalid				(Data_AXI.ar_valid				),
				
		.DATA_awaddr				(Data_AXI.aw_addr[31:0]			),
		.DATA_awburst				(Data_AXI.aw_burst				),
		.DATA_awcache				(Data_AXI.aw_cache				),
		.DATA_awid					(Data_AXI.aw_id[1:0]			),
		.DATA_awlen					(Data_AXI.aw_len				),
		.DATA_awlock				(Data_AXI.aw_lock				),
		.DATA_awprot				(Data_AXI.aw_prot				),
		.DATA_awqos					(Data_AXI.aw_qos				),
		.DATA_awready				(Data_AXI.aw_ready				),
		.DATA_awsize				(Data_AXI.aw_size				),
		.DATA_awvalid				(Data_AXI.aw_valid				),
						
		.DATA_bid					(Data_AXI.b_id[1:0]				),
		.DATA_bready				(Data_AXI.b_ready				),
		.DATA_bresp					(Data_AXI.b_resp				),
		.DATA_bvalid				(Data_AXI.b_valid				),
		.DATA_rdata					(Data_AXI.r_data				),
		.DATA_rid					(Data_AXI.r_id[1:0]				),
		.DATA_rlast					(Data_AXI.r_last				),
		.DATA_rready				(Data_AXI.r_ready				),
		.DATA_rresp					(Data_AXI.r_resp				),
		.DATA_rvalid				(Data_AXI.r_valid				),
		.DATA_wdata					(Data_AXI.w_data				),
		.DATA_wlast					(Data_AXI.w_last				),
		.DATA_wready				(Data_AXI.w_ready				),
		.DATA_wstrb					(Data_AXI.w_strb				),
		.DATA_wvalid				(Data_AXI.w_valid				),
				
				
		.INSTR_araddr				(Instr_AXI.ar_addr				),
		.INSTR_arburst				(Instr_AXI.ar_burst				),
		.INSTR_arcache				(Instr_AXI.ar_cache				),
		.INSTR_arid					(Instr_AXI.ar_id				),
		.INSTR_arlen				(Instr_AXI.ar_len				),
		.INSTR_arlock				(Instr_AXI.ar_lock				),
		.INSTR_arprot				(Instr_AXI.ar_prot				),
		.INSTR_arqos				(Instr_AXI.ar_qos				),
		.INSTR_arready				(Instr_AXI.ar_ready				),
		.INSTR_arsize				(Instr_AXI.ar_size				),
		.INSTR_arvalid				(Instr_AXI.ar_valid				),
		.INSTR_awaddr				(Instr_AXI.aw_addr				),
		.INSTR_awburst				(Instr_AXI.aw_burst				),
		.INSTR_awcache				(Instr_AXI.aw_cache				),
		.INSTR_awid					(Instr_AXI.aw_id				),
		.INSTR_awlen				(Instr_AXI.aw_len				),
		.INSTR_awlock				(Instr_AXI.aw_lock				),
		.INSTR_awprot				(Instr_AXI.aw_prot				),
		.INSTR_awqos				(Instr_AXI.aw_qos				),
		.INSTR_awready				(Instr_AXI.aw_ready				),
		.INSTR_awsize				(Instr_AXI.aw_size				),
		.INSTR_awvalid				(Instr_AXI.aw_valid				),
		.INSTR_bid					(Instr_AXI.b_id[1:0]			),
		.INSTR_bready				(Instr_AXI.aw_ready				),
		.INSTR_bresp				(Instr_AXI.b_resp				),
		.INSTR_bvalid				(Instr_AXI.b_valid				),
		.INSTR_rdata				(Instr_AXI.r_data				),
		.INSTR_rid					(Instr_AXI.r_id					),
		.INSTR_rlast				(Instr_AXI.r_last				),
		.INSTR_rready				(Instr_AXI.r_ready				),
		.INSTR_rresp				(Instr_AXI.r_resp				),
		.INSTR_rvalid				(Instr_AXI.r_valid				),
		.INSTR_wdata				(Instr_AXI.w_data				),
		.INSTR_wlast				(Instr_AXI.w_last				),
		.INSTR_wready				(Instr_AXI.w_ready				),
		.INSTR_wstrb				(Instr_AXI.w_strb				),
		.INSTR_wvalid				(Instr_AXI.w_valid				),
							
		.DEBUG_araddr				(DEBUG_AXI.ar_addr				),
		.DEBUG_arburst				(DEBUG_AXI.ar_burst				),
		.DEBUG_arcache				(DEBUG_AXI.ar_cache				),
		.DEBUG_arid					(DEBUG_AXI.ar_id				),
		.DEBUG_arlen				(DEBUG_AXI.ar_len				),
		.DEBUG_arlock				(DEBUG_AXI.ar_lock				),
		.DEBUG_arprot				(DEBUG_AXI.ar_prot				),
		.DEBUG_arqos				(DEBUG_AXI.ar_qos				),
		.DEBUG_arready				(DEBUG_AXI.ar_ready				),
		.DEBUG_arregion				(),			
		.DEBUG_arsize				(DEBUG_AXI.ar_size				),
		.DEBUG_arvalid				(DEBUG_AXI.ar_valid				),
		.DEBUG_awaddr				(DEBUG_AXI.aw_addr				),
		.DEBUG_awburst				(DEBUG_AXI.aw_burst				),
		.DEBUG_awcache				(DEBUG_AXI.aw_cache				),
		.DEBUG_awid					(DEBUG_AXI.aw_id				),
		.DEBUG_awlen				(DEBUG_AXI.aw_len				),
		.DEBUG_awlock				(DEBUG_AXI.aw_lock				),
		.DEBUG_awprot				(DEBUG_AXI.aw_prot				),
		.DEBUG_awqos				(DEBUG_AXI.aw_qos				),
		.DEBUG_awready				(DEBUG_AXI.aw_ready				),
		.DEBUG_awregion				(								),
		.DEBUG_awsize				(DEBUG_AXI.aw_size				),
		.DEBUG_awvalid				(DEBUG_AXI.aw_valid				),
		.DEBUG_bid					(DEBUG_AXI.b_id[1:0]			),
		.DEBUG_bready				(DEBUG_AXI.b_ready				),
		.DEBUG_bresp				(DEBUG_AXI.b_resp				),
		.DEBUG_bvalid				(DEBUG_AXI.b_valid				),
		.DEBUG_rdata				(DEBUG_AXI.r_data				),
		.DEBUG_rid					(DEBUG_AXI.r_id[1:0]			),
		.DEBUG_rlast				(DEBUG_AXI.r_last				),
		.DEBUG_rready				(DEBUG_AXI.r_ready				),
		.DEBUG_rresp				(DEBUG_AXI.r_resp				),
		.DEBUG_rvalid				(DEBUG_AXI.r_valid				),
		.DEBUG_wdata				(DEBUG_AXI.w_data				),
		.DEBUG_wlast				(DEBUG_AXI.w_last				),
		.DEBUG_wready				(DEBUG_AXI.w_ready				),
		.DEBUG_wstrb				(DEBUG_AXI.w_strb				),
		.DEBUG_wvalid				(DEBUG_AXI.w_valid				),
        .Vaux10_0_v_n(Vaux10_0_v_n),
        .Vaux10_0_v_p(Vaux10_0_v_p),
        .Vaux1_0_v_n(Vaux1_0_v_n),
        .Vaux1_0_v_p(Vaux1_0_v_p),
        .Vaux2_0_v_n(Vaux2_0_v_n),
        .Vaux2_0_v_p(Vaux2_0_v_p),
        .Vaux9_0_v_n(Vaux9_0_v_n),
        .Vaux9_0_v_p(Vaux9_0_v_p),
						
		.PPI_araddr				(PPI_AXi.ar_addr				),
		.PPI_arburst			(PPI_AXi.ar_burst				),
		.PPI_arcache			(PPI_AXi.ar_cache				),
		.PPI_arid				(PPI_AXi.ar_id					),
		.PPI_arlen				(PPI_AXi.ar_len					),
		.PPI_arlock				(PPI_AXi.ar_lock				),
		.PPI_arprot				(PPI_AXi.ar_prot				),
		.PPI_arqos				(PPI_AXi.ar_qos					),
		.PPI_arready			(PPI_AXi.ar_ready				),
		.PPI_arregion			(								),
		.PPI_arsize				(PPI_AXi.ar_size				),
		.PPI_arvalid			(PPI_AXi.ar_valid				),
		.PPI_awaddr				(PPI_AXi.aw_addr				),
		.PPI_awburst			(PPI_AXi.aw_burst				),
		.PPI_awcache			(PPI_AXi.aw_cache				),
		.PPI_awid				(PPI_AXi.aw_id					),
		.PPI_awlen				(PPI_AXi.aw_len					),
		.PPI_awlock				(PPI_AXi.aw_lock				),
		.PPI_awprot				(PPI_AXi.aw_prot				),
		.PPI_awqos				(PPI_AXi.aw_qos					),
		.PPI_awready			(PPI_AXi.aw_ready				),
		.PPI_awregion			(								),
		.PPI_awsize				(PPI_AXi.aw_size				),
		.PPI_awvalid			(PPI_AXi.aw_valid				),
		.PPI_bid				(PPI_AXi.b_id					),
		.PPI_bready				(PPI_AXi.b_ready				),
		.PPI_bresp				(PPI_AXi.b_resp					),
		.PPI_bvalid				(PPI_AXi.b_valid				),
		.PPI_rdata				(PPI_AXi.r_data					),
		.PPI_rid				(PPI_AXi.r_id					),
		.PPI_rlast				(PPI_AXi.r_last					),
		.PPI_rready				(PPI_AXi.r_ready				),
		.PPI_rresp				(PPI_AXi.r_resp					),
		.PPI_rvalid				(PPI_AXi.r_valid				),
		.PPI_wdata				(PPI_AXi.w_data					),
		.PPI_wlast				(PPI_AXi.w_last					),
		.PPI_wready				(PPI_AXi.w_ready				),
		.PPI_wstrb				(PPI_AXi.w_strb					),
		.PPI_wvalid				(PPI_AXi.w_valid				),
						
		.MEM_araddr				(MEM_AXi.ar_addr				),
		.MEM_arburst			(MEM_AXi.ar_burst				),
		.MEM_arcache			(MEM_AXi.ar_cache				),
		.MEM_arid				(MEM_AXi.ar_id					),
		.MEM_arlen				(MEM_AXi.ar_len					),
		.MEM_arlock				(MEM_AXi.ar_lock				),
		.MEM_arprot				(MEM_AXi.ar_prot				),
		.MEM_arqos				(MEM_AXi.ar_qos	),			
		.MEM_arready			(MEM_AXi.ar_ready				),
		.MEM_arregion			(								),
		.MEM_arsize				(MEM_AXi.ar_size				),
		.MEM_arvalid			(MEM_AXi.ar_valid				),
		.MEM_awaddr				(MEM_AXi.aw_addr				),
		.MEM_awburst			(MEM_AXi.aw_burst				),
		.MEM_awcache			(MEM_AXi.aw_cache				),
		.MEM_awid				(MEM_AXi.aw_id					),
		.MEM_awlen				(MEM_AXi.aw_len					),
		.MEM_awlock				(MEM_AXi.aw_lock				),
		.MEM_awprot				(MEM_AXi.aw_prot				),
		.MEM_awqos				(MEM_AXi.aw_qos					),
		.MEM_awready			(MEM_AXi.aw_ready				),
		.MEM_awregion			(								),
		.MEM_awsize				(MEM_AXi.aw_size				),
		.MEM_awvalid			(MEM_AXi.aw_valid				),
		.MEM_bid				(MEM_AXi.b_id					),
		.MEM_bready				(MEM_AXi.b_ready				),
		.MEM_bresp				(MEM_AXi.b_resp					),
		.MEM_bvalid				(MEM_AXi.b_valid				),
		.MEM_rdata				(MEM_AXi.r_data					),
		.MEM_rid				(MEM_AXi.r_id					),
		.MEM_rlast				(MEM_AXi.r_last					),
		.MEM_rready				(MEM_AXi.r_ready				),
		.MEM_rresp				(MEM_AXi.r_resp					),
		.MEM_rvalid				(MEM_AXi.r_valid				),
		.MEM_wdata				(MEM_AXi.w_data					),
		.MEM_wlast				(MEM_AXi.w_last					),
		.MEM_wready				(MEM_AXi.w_ready				),
		.MEM_wstrb				(MEM_AXi.w_strb					),
		.MEM_wvalid				(MEM_AXi.w_valid				),
						
		.PLIC_araddr			(PLIC_AXi.ar_addr				),
		.PLIC_arburst			(PLIC_AXi.ar_burst				),
		.PLIC_arcache			(PLIC_AXi.ar_cache				),
		.PLIC_arid				(PLIC_AXi.ar_id					),
		.PLIC_arlen				(PLIC_AXi.ar_len				),
		.PLIC_arlock			(PLIC_AXi.ar_lock				),
		.PLIC_arprot			(PLIC_AXi.ar_prot				),
		.PLIC_arqos				(PLIC_AXi.ar_qos				),
		.PLIC_arready			(PLIC_AXi.ar_ready				),
		.PLIC_arregion			(								),
		.PLIC_arsize			(PLIC_AXi.ar_size				),
		.PLIC_arvalid			(PLIC_AXi.ar_valid				),
		.PLIC_awaddr			(PLIC_AXi.aw_addr				),
		.PLIC_awburst			(PLIC_AXi.aw_burst				),
		.PLIC_awcache			(PLIC_AXi.aw_cache				),
		.PLIC_awid				(PLIC_AXi.aw_id	),			
		.PLIC_awlen				(PLIC_AXi.aw_len				),
		.PLIC_awlock			(PLIC_AXi.aw_lock				),
		.PLIC_awprot			(PLIC_AXi.aw_prot				),
		.PLIC_awqos				(PLIC_AXi.aw_qos				),
		.PLIC_awready			(PLIC_AXi.aw_ready				),
		.PLIC_awregion			(								),
		.PLIC_awsize			(PLIC_AXi.aw_size				),
		.PLIC_awvalid			(PLIC_AXi.aw_valid				),
		.PLIC_bid				(PLIC_AXi.b_id					),
		.PLIC_bready			(PLIC_AXi.b_ready				),
		.PLIC_bresp				(PLIC_AXi.b_resp				),
		.PLIC_bvalid			(PLIC_AXi.b_valid				),
		.PLIC_rdata				(PLIC_AXi.r_data				),
		.PLIC_rid				(PLIC_AXi.r_id					),
		.PLIC_rlast				(PLIC_AXi.r_last				),
		.PLIC_rready			(PLIC_AXi.r_ready				),
		.PLIC_rresp				(PLIC_AXi.r_resp				),
		.PLIC_rvalid			(PLIC_AXi.r_valid				),
		.PLIC_wdata				(PLIC_AXi.w_data				),
		.PLIC_wlast				(PLIC_AXi.w_last				),
		.PLIC_wready			(PLIC_AXi.w_ready				),
		.PLIC_wstrb				(PLIC_AXi.w_strb				),
		.PLIC_wvalid			(PLIC_AXi.w_valid				),

		
		.CLINT_araddr			(CLINT_AXi.ar_addr				),
		.CLINT_arburst			(CLINT_AXi.ar_burst				),
		.CLINT_arcache			(CLINT_AXi.ar_cache				),
		.CLINT_arid				(CLINT_AXi.ar_id					),
		.CLINT_arlen			(CLINT_AXi.ar_len				),
		.CLINT_arlock			(CLINT_AXi.ar_lock				),
		.CLINT_arprot			(CLINT_AXi.ar_prot				),
		.CLINT_arqos			(CLINT_AXi.ar_qos				),
		.CLINT_arready			(CLINT_AXi.ar_ready				),
		.CLINT_arregion			(								),
		.CLINT_arsize			(CLINT_AXi.ar_size				),
		.CLINT_arvalid			(CLINT_AXi.ar_valid				),
		.CLINT_awaddr			(CLINT_AXi.aw_addr				),
		.CLINT_awburst			(CLINT_AXi.aw_burst				),
		.CLINT_awcache			(CLINT_AXi.aw_cache				),
		.CLINT_awid				(CLINT_AXi.aw_id				),			
		.CLINT_awlen			(CLINT_AXi.aw_len				),
		.CLINT_awlock			(CLINT_AXi.aw_lock				),
		.CLINT_awprot			(CLINT_AXi.aw_prot				),
		.CLINT_awqos			(CLINT_AXi.aw_qos				),
		.CLINT_awready			(CLINT_AXi.aw_ready				),
		.CLINT_awregion			(								),
		.CLINT_awsize			(CLINT_AXi.aw_size				),
		.CLINT_awvalid			(CLINT_AXi.aw_valid				),
		.CLINT_bid				(CLINT_AXi.b_id					),
		.CLINT_bready			(CLINT_AXi.b_ready				),
		.CLINT_bresp			(CLINT_AXi.b_resp				),
		.CLINT_bvalid			(CLINT_AXi.b_valid				),
		.CLINT_rdata			(CLINT_AXi.r_data				),
		.CLINT_rid				(CLINT_AXi.r_id					),
		.CLINT_rlast			(CLINT_AXi.r_last				),
		.CLINT_rready			(CLINT_AXi.r_ready				),
		.CLINT_rresp			(CLINT_AXi.r_resp				),
		.CLINT_rvalid			(CLINT_AXi.r_valid				),
		.CLINT_wdata			(CLINT_AXi.w_data				),
		.CLINT_wlast			(CLINT_AXi.w_last				),
		.CLINT_wready			(CLINT_AXi.w_ready				),
		.CLINT_wstrb			(CLINT_AXi.w_strb				),
		.CLINT_wvalid			(CLINT_AXi.w_valid				),
		  .iic_intr(iic_intr),
        .io0_i_0(io0_i_0),
        .io0_t_0(io0_t_0),
		.io0_o_0(io0_o_0),
        .io1_i_0(io1_i_0),
        .io1_o_0(io1_o_0),
        .io1_t_0(io1_t_0),
		.sck_i_0(sck_i_0),
		.sck_o_0(sck_o_0),
        .sck_t_0(sck_t_0),
		.ss_i_0(ss_i_0),
        .ss_t_0(ss_t_0),
		.ss_o_0(ss_o_0),
    .spi0_intr(spi0_intr),
    .spi1_intr(spi1_intr),
	.IIC_scl_io(iic_scl_io),
    .IIC_sda_io(iic_sda_io),
    .pwm0(pwm0),
	//.pwm1(pwm1),
	.io_port_cs_0(spi_0_ss_io),
    .io_port_dq_0_i(spi_0_io0_i),
    .io_port_dq_0_o(spi_0_io0_o),
    .io_port_dq_0_oe(spi_0_io0_t),
    .io_port_dq_1_i(spi_0_io1_i),
    .io_port_dq_1_o(spi_0_io1_o),
    .io_port_dq_1_oe(spi_0_io1_t),
	.io_port_dq_2_i(spi_0_io2_i),
    .io_port_dq_2_o(spi_0_io2_o),
    .io_port_dq_2_oe(spi_0_io2_t),
	.io_port_dq_3_i(spi_0_io3_i),
    .io_port_dq_3_o(spi_0_io3_o),
    .io_port_dq_3_oe(spi_0_io3_t),
    .io_port_sck(spi_0_sck_io),
	// .SPI_1_io0_io(spi_1_io0_io),
    // .SPI_1_io1_io(spi_1_io1_io),
    //.SPI_1_io2_io(spi_1_io2_io),
   // .SPI_1_io3_io(spi_1_io3_io),
    // .SPI_1_sck_io(spi_1_sck_io),
    // .SPI_1_ss_io(spi_1_ss_io),
    .timer0_intr(timer0_intr),
    .uart_intr(uart_intr),
		.UART_rxd				(UART_rxd						),
		.UART_txd				(UART_txd						),
		.Vp_Vn_v_n				(Vp_Vn_v_n						),
		.Vp_Vn_v_p				(Vp_Vn_v_p						)
	);			
		
  PULLUP qspi_pullup0
  (
    .O(spi_0_io0_io)
  );
    PULLUP qspi_pullup1
  (
    .O(spi_0_io1_io)
  );
    PULLUP qspi_pullup2
  (
    .O(spi_0_io2_io)
  );
    PULLUP qspi_pullup3
  (
    .O(spi_0_io3_io)
  );
  
   IOBUF spi_1_io0_io_iobuf
		(
		.I(io0_o_0),//
		.T(io0_t_0),
		.O(io0_i_0),
		.IO(spi_1_io0_io)
		);
   IOBUF spi_1_io1_io_iobuf
   		(
		.I(io1_o_0),
		.T(io1_t_0),
		.O(io1_i_0),
		.IO(spi_1_io1_io)
		);
		   IOBUF spi_1_io2_io_iobuf
   		(
		.I(0),
		.T(0),
		.O(0),
		.IO(spi_1_io2_io)
		);
		   IOBUF spi_1_io3_io_iobuf
   		(
		.I(0),
		.T(0),
		.O(0),
		.IO(spi_1_io3_io)
		);

   IOBUF spi_1_sck_io_iobuf
      	(
		.I(sck_o_0), //
		.T(sck_t_0),
		.O(sck_i_0),
		.IO(spi_1_sck_io)
		);
   IOBUF spi_1_ss_io_iobuf
   		(
		.I(ss_o_0), //
		.T(ss_t_0),
		.O(ss_i_0),
		.IO(spi_1_ss_io)
		);

  IOBUF spi_0_io0_iobuf
       (.I(spi_0_io0_o),
        .IO(spi_0_io0_io),
        .O(spi_0_io0_i),
        .T(~spi_0_io0_t));
  IOBUF spi_0_io1_iobuf
       (.I(spi_0_io1_o),
        .IO(spi_0_io1_io),
        .O(spi_0_io1_i),
        .T(~spi_0_io1_t));
  IOBUF spi_0_io2_iobuf
       (.I(spi_0_io2_o),
        .IO(spi_0_io2_io),
        .O(spi_0_io2_i),
        .T(~spi_0_io2_t));
  IOBUF spi_0_io3_iobuf
       (.I(spi_0_io3_o),
        .IO(spi_0_io3_io),
        .O(spi_0_io3_i),
        .T(~spi_0_io3_t));
endmodule
