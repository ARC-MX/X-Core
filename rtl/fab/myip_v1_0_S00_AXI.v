   
`timescale 1 ns / 1 ps

module myip_v1_0_S00_AXI #
	(
		// Users to add parameters here
		
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of ID for for write address, write data, read address and read data
		parameter integer C_S_AXI_ID_WIDTH	= 2,
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter integer C_S_AXI_AWUSER_WIDTH	= 0,
		parameter integer C_S_AXI_ARUSER_WIDTH	= 0,
		parameter integer C_S_AXI_WUSER_WIDTH	= 0,
		parameter integer C_S_AXI_RUSER_WIDTH	= 0,
		parameter integer C_S_AXI_BUSER_WIDTH	= 0
	)
	(
		// Users to add ports here
		output	reg					icb_cmd_valid,
		input 						icb_cmd_ready,
		output	reg [31:0] 			icb_cmd_addr,
		output	reg 				icb_cmd_read,
		output	reg [31:0] 			icb_cmd_wdata,
		input 						icb_rsp_valid,
		input  	[31:0]				icb_rsp_rdata,
		output	reg 				icb_rsp_ready,
		// User ports ends
		// Do not modify the ports beyond this line

		input wire  S_AXI_ACLK,
		input wire  S_AXI_ARESETN,
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		input wire [7 : 0] S_AXI_AWLEN,
		input wire [2 : 0] S_AXI_AWSIZE,
		input wire [1 : 0] S_AXI_AWBURST,
		input wire  S_AXI_AWLOCK,
		input wire [3 : 0] S_AXI_AWCACHE,
		input wire [2 : 0] S_AXI_AWPROT,
		input wire [3 : 0] S_AXI_AWQOS,
		input wire  S_AXI_AWVALID,
		output wire  S_AXI_AWREADY,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input wire  S_AXI_WLAST,
		input wire  S_AXI_WVALID,
		output wire  S_AXI_WREADY,
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
		output wire [1 : 0] S_AXI_BRESP,
		output wire  S_AXI_BVALID,
		input wire  S_AXI_BREADY,
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		input wire [7 : 0] S_AXI_ARLEN,
		input wire [2 : 0] S_AXI_ARSIZE,
		input wire [1 : 0] S_AXI_ARBURST,
		input wire  S_AXI_ARLOCK,
		input wire [3 : 0] S_AXI_ARCACHE,
		input wire [2 : 0] S_AXI_ARPROT,
		input wire [3 : 0] S_AXI_ARQOS,
		input wire  S_AXI_ARVALID,
		output wire  S_AXI_ARREADY,
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		output wire [1 : 0] S_AXI_RRESP,
		output wire  S_AXI_RLAST,
		output wire  S_AXI_RVALID,
		input wire  S_AXI_RREADY
	);

	// AXI4FULL signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  							axi_awready;
	wire  							axi_wready;
	reg [1 : 0] 					axi_bresp;
	reg  							axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  							axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 					axi_rresp;
	reg  							axi_rlast;
	wire  							axi_rvalid;
	// aw_wrap_en determines wrap boundary and enables wrapping
	wire aw_wrap_en;
	// ar_wrap_en determines wrap boundary and enables wrapping
	wire ar_wrap_en;
	// aw_wrap_size is the size of the write transfer, the
	// write address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  aw_wrap_size ; 
	// ar_wrap_size is the size of the read transfer, the
	// read address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  ar_wrap_size ; 
	// The axi_awv_awr_flag flag marks the presence of write address valid
	reg axi_awv_awr_flag;
	//The axi_arv_arr_flag flag marks the presence of read address valid
	reg axi_arv_arr_flag; 
	// The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
	reg [7:0] axi_awlen_cntr;
	//The axi_arlen_cntr internal read address counter to keep track of beats in a burst transaction
	reg [7:0] axi_arlen_cntr;
	reg [1:0] axi_arburst;
	reg [1:0] axi_awburst;
	reg [7:0] axi_arlen;
	reg [7:0] axi_awlen;
	//local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	//ADDR_LSB is used for addressing 32/64 bit registers/memories
	//ADDR_LSB = 2 for 32 bits (n downto 2) 
	//ADDR_LSB = 3 for 42 bits (n downto 3)

	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32)+ 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	localparam integer USER_NUM_MEM = 1;
	//----------------------------------------------
	//-- Signals for user logic memory space example
	//------------------------------------------------
	wire [OPT_MEM_ADDR_BITS:0] mem_address;
	wire [USER_NUM_MEM-1:0] mem_select;
	reg [C_S_AXI_DATA_WIDTH-1:0] mem_data_out[0 : USER_NUM_MEM-1];
	reg r_last;
	reg [C_S_AXI_ID_WIDTH-1:0]r_id;
	reg [C_S_AXI_ID_WIDTH-1:0]r_id_temp;
	genvar i;
	genvar j;
	genvar mem_byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RLAST	= r_last;//axi_rlast;
	assign S_AXI_RVALID	= axi_rvalid;
	assign S_AXI_BID = S_AXI_AWID;
	assign S_AXI_RID = r_id;
	assign  aw_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_awlen)); 
	assign  ar_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_arlen)); 
	assign  aw_wrap_en = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
	assign  ar_wrap_en = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;

	// Implement axi_awready generation

	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.
	// always @ (posedge S_AXI_ACLK)
	// if(!S_AXI_ARESETN)
		// r_id <= 0;
	// else if(S_AXI_ARVALID)
		// r_id <= S_AXI_ARID;
	// else
		// r_id <= r_id;
		
		
		
		
	// always @ (*)
	// if(!S_AXI_ARESETN)
		// begin
			// r_id_temp = 0;
			// r_id = 0;
		// end
	// else begin
		// if(icb_cmd_valid)
			// r_id_temp = S_AXI_ARID;
		// if(icb_rsp_valid)
			// r_id = r_id_temp;
	// end
		
	always @ (*)
	if(!S_AXI_ARESETN)
		r_id = 0;
	else if(icb_rsp_valid)
		r_id = r_id_temp;
	else
		r_id = r_id;
	
	always @ (posedge S_AXI_ACLK, negedge S_AXI_ARESETN)
	if(!S_AXI_ARESETN)
		r_id_temp <= 0;
	else if(icb_cmd_valid)
		r_id_temp <= S_AXI_ARID;
		
	
		
		
		
	always @ (posedge S_AXI_ACLK)
	if(!S_AXI_ARESETN)
		r_last <= 0;
	else if(S_AXI_ARREADY & S_AXI_ARVALID)
		r_last <= 1;
	else if(S_AXI_RVALID & S_AXI_RREADY) 
		r_last <= 0;
	
	
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      axi_awv_awr_flag <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          // slave is ready to accept an address and associated control signals
	          axi_awready <= 1'b1;
	          axi_awv_awr_flag  <= 1'b1; 
	          // used for generation of bresp() and bvalid
	        end
	      else if (S_AXI_WLAST && axi_wready)          
	      // preparing to accept next address after current write burst tx completion
	        begin
	          axi_awv_awr_flag  <= 1'b0;
	        end
	      else        
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       
	// Implement axi_awaddr latching

	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	      axi_awlen_cntr <= 0;
	      axi_awburst <= 0;
	      axi_awlen <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag)
	        begin
	          // address latching 
	          axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:0];  
	           axi_awburst <= S_AXI_AWBURST; 
	           axi_awlen <= S_AXI_AWLEN;     
	          // start address of transfer
	          axi_awlen_cntr <= 0;
	        end   
	      else if((axi_awlen_cntr <= axi_awlen) && axi_wready && S_AXI_WVALID)        
	        begin

	          axi_awlen_cntr <= axi_awlen_cntr + 1;

	          case (axi_awburst)
	            2'b00: // fixed burst
	            // The write address for all the beats in the transaction are fixed
	              begin
	                axi_awaddr <= axi_awaddr;          
	                //for awsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The write address for all the beats in the transaction are increments by awsize
	              begin
	                axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //awaddr aligned to 4 byte boundary
	                axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The write address wraps when the address reaches wrap boundary 
	              if (aw_wrap_en)
	                begin
	                  axi_awaddr <= (axi_awaddr - aw_wrap_size); 
	                end
	              else 
	                begin
	                  axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                  axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}}; 
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //for awsize = 4 bytes (010)
	              end
	          endcase              
	        end
	    end 
	end       
	// Implement axi_wready generation

	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 
	reg axi_wready_temp;
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready_temp <= 1'b0;
	    end 
	  else
	    begin    
	      if ( ~axi_wready_temp && S_AXI_WVALID && axi_awv_awr_flag)
	        begin
	          // slave can accept the write data
	          axi_wready_temp <= 1'b1;
	        end
	      //else if (~axi_awv_awr_flag)
	      else if (S_AXI_WLAST && axi_wready)
	        begin
	          axi_wready_temp <= 1'b0;
	        end
	    end 
	end   
	assign axi_wready = axi_wready_temp && icb_cmd_ready;
	// Implement write response logic generation

	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.
	reg axi_bvalid_temp;
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid_temp <= 0;
	      axi_bresp <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awv_awr_flag && axi_wready && S_AXI_WVALID && ~axi_bvalid_temp && S_AXI_WLAST)
	        begin
	          axi_bvalid_temp <= 1'b1;
	          axi_bresp  <= 2'b0; 
	          // 'OKAY' response 
	        end                   
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	          //check if bready is asserted while bvalid is high) 
	          //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid_temp <= 1'b0; 
	            end  
	        end
	    end
	 end
	 always @ (posedge S_AXI_ACLK)
	 if(axi_bvalid_temp && icb_rsp_valid)
		axi_bvalid = 1;
	else if(S_AXI_BREADY)
		axi_bvalid = 0;
	 // assign axi_bvalid = axi_bvalid_temp && icb_rsp_valid;
	/*always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid <= 0;
	      axi_bresp <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awv_awr_flag && axi_wready && S_AXI_WVALID && ~axi_bvalid && S_AXI_WLAST)
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; 
	          // 'OKAY' response 
	        end                   
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	          //check if bready is asserted while bvalid is high) 
	          //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	 end  */ 
	// Implement axi_arready generation

	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_arv_arr_flag <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          axi_arready <= 1'b1;
	          axi_arv_arr_flag <= 1'b1;
	        end
	      else if (axi_rvalid && S_AXI_RREADY && axi_arlen_cntr == axi_arlen)
	      // preparing to accept next address after current read completion
	        begin
	          axi_arv_arr_flag  <= 1'b0;
	        end
	      else        
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       
	// Implement axi_araddr latching

	//This process is used to latch the address when both  S_AXI_ARVALID and S_AXI_RVALID are valid. 
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_araddr <= 0;
	      axi_arlen_cntr <= 0;
	      axi_arburst <= 0;
	      axi_arlen <= 0;
	      axi_rlast <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_arv_arr_flag)
	        begin
	          // address latching 
	          axi_araddr <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH - 1:0]; 
	          axi_arburst <= S_AXI_ARBURST; 
	          axi_arlen <= S_AXI_ARLEN;     
	          // start address of transfer
	          axi_arlen_cntr <= 0;
	          axi_rlast <= 1'b0;
	        end   
	      else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && S_AXI_RREADY)        
	        begin
	         
	          axi_arlen_cntr <= axi_arlen_cntr + 1;
	          axi_rlast <= 1'b0;
	        
	          case (axi_arburst)
	            2'b00: // fixed burst
	             // The read address for all the beats in the transaction are fixed
	              begin
	                axi_araddr       <= axi_araddr;        
	                //for arsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The read address for all the beats in the transaction are increments by awsize
	              begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The read address wraps when the address reaches wrap boundary 
	              if (ar_wrap_en) 
	                begin
	                  axi_araddr <= (axi_araddr - ar_wrap_size); 
	                end
	              else 
	                begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_araddr <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]+1;
	                //for arsize = 4 bytes (010)
	              end
	          endcase              
	        end
	      else if((axi_arlen_cntr == axi_arlen) && ~axi_rlast && axi_arv_arr_flag )   
	        begin
	          axi_rlast <= 1'b1;
	        end          
	      else if (S_AXI_RREADY)   
	        begin
	          axi_rlast <= 1'b0;
	        end          
	    end 
	end       
	// Implement axi_arvalid generation

	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	reg axi_rvalid_temp;
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid_temp <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arv_arr_flag && ~axi_rvalid_temp )
	        begin
	          axi_rvalid_temp <= 1'b1;
	          axi_rresp  <= 2'b0; 
	          // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          axi_rvalid_temp <= 1'b0;
	        end            
	    end
	end    
	assign axi_rvalid = icb_rsp_valid & axi_rvalid_temp;
	
	//Output register or memory read data
	reg [31:0] 	rdata_temp;
	reg 		[1:0] 	state_d, state_q;
	wire mem_rden;
	reg mem_wren;
	reg mem_wren_reg;
	
	always @ (* )//(posedge S_AXI_ACLK)
		if(!S_AXI_ARESETN)
			mem_wren = 0;
		else if(axi_wready_temp && S_AXI_WVALID )
			mem_wren = 1;
		else if(icb_rsp_valid)
			mem_wren = 0;
		else
			mem_wren = mem_wren_reg;
		
		always @ (posedge S_AXI_ACLK,negedge S_AXI_ARESETN)//(posedge S_AXI_ACLK)
		if(!S_AXI_ARESETN)
			mem_wren_reg <= 0;
		else if(axi_wready_temp && S_AXI_WVALID )
			mem_wren_reg <= 1;
		else if(icb_rsp_valid)
			mem_wren_reg <= 0;
		
		
	 // always @ (* )//(posedge S_AXI_ACLK)
			// if(axi_wready_temp && S_AXI_WVALID )
				// mem_wren = 1;
			// else if(icb_rsp_valid)
				// mem_wren = 0;
	
	
	      assign mem_rden = axi_arv_arr_flag ; //& ~axi_rvalid
	always @( rdata_temp, axi_rvalid, S_AXI_ARESETN)
	begin
		if(!S_AXI_ARESETN)
			axi_rdata = 32'h0000_0000;
		if (axi_rvalid) 
			axi_rdata = rdata_temp;  
	  else
			axi_rdata = 32'h0000_0000;      
	end    

	// Add user logic here
		reg [1:0] w_state_d, w_state_q;
		reg [31:0]icb_cmd_addr_r;
		reg [31:0] icb_cmd_wdata_r;
		reg [31:0] rdata_temp_r;
	always @ (*)
		if(!S_AXI_ARESETN)
			begin
				icb_cmd_valid 	= 0;
				icb_cmd_addr 	= 0;
				icb_cmd_read 	= 0;
				icb_cmd_wdata 	= 0;
				icb_rsp_ready 	= 0;
				rdata_temp 		= 0;
				state_d			= 0;
				w_state_d		= 0;
			end
		else
			begin
				case(1)
					mem_wren 	:	begin
						rdata_temp 		= 0;
						state_d = 0;
						case(w_state_q)
							0	:	begin
										icb_cmd_valid = 1;
										icb_cmd_addr = axi_awaddr;
										icb_cmd_read = 0;
										icb_cmd_wdata = S_AXI_WDATA;
										icb_rsp_ready = 1;
										w_state_d = 1;
										
									end 
							1	:	begin
										icb_rsp_ready = 1;
										icb_cmd_read = 0;
										icb_cmd_addr = icb_cmd_addr_r;
										icb_cmd_wdata = icb_cmd_wdata_r;
										if(icb_cmd_ready)
											begin
												w_state_d = 2;
												icb_cmd_valid = 0;
											end		
										else	
											begin
												w_state_d = 1;
												icb_cmd_valid = 1;
											end
										
									end
							2	:	begin
										icb_cmd_valid = 0;
										icb_cmd_read = 0;
										icb_cmd_addr = icb_cmd_addr_r;
										icb_cmd_wdata = icb_cmd_wdata_r;
										if(icb_rsp_valid)
											begin
												w_state_d = 0;
												icb_rsp_ready = 0;
											end
										else
											begin
												w_state_d = 2;
												icb_rsp_ready = 1;
											end
									end
							default	:	begin
											icb_cmd_valid = 0;
											w_state_d = 0;
											icb_cmd_addr = 0;
											icb_cmd_wdata = 0;
											icb_cmd_read = 0;
											icb_rsp_ready = 0;
										end
						endcase
					end
					mem_rden : 
						begin
							w_state_d = 0;
							icb_cmd_wdata = 0;
							case (state_q)
								0	:	begin
											icb_cmd_valid = 1;
											icb_cmd_addr = axi_araddr;
											icb_cmd_read = 1;
											icb_rsp_ready = 1;
											rdata_temp 		= rdata_temp_r;
											if(icb_cmd_ready)
												state_d = 1;
											else	
												state_d = 0;
										end
								1	:	begin
											icb_cmd_valid 			= 0; 
											icb_cmd_read 			= 1;
											icb_cmd_addr 			= icb_cmd_addr_r;
											if(icb_rsp_valid)
												begin
													state_d 		= 2;
													rdata_temp 		= icb_rsp_rdata;
													icb_rsp_ready 	= 0;
												end
											else
												begin
													state_d 		= 1;
													rdata_temp 		= rdata_temp_r;
													icb_rsp_ready 	= 1;
												end
										end
								2	:	begin	
											state_d 		= 0;
											icb_cmd_valid 	= 0; 
											icb_rsp_ready 	= 0;
											icb_cmd_read 	= 1;
											icb_cmd_addr 	= icb_cmd_addr_r;
											rdata_temp 		= rdata_temp_r;
										end
							default	:	begin
											icb_cmd_valid 	= 0; 
											icb_rsp_ready	= 0;
											icb_cmd_addr 	= 0;
											icb_cmd_read 	= 1;
											state_d 		= 0;
											rdata_temp 		= 0;
										end
							endcase
						end
					default	:	begin
									icb_cmd_valid 	= 0;
									icb_cmd_addr 	= 0;
									icb_cmd_read 	= 0;
									icb_cmd_wdata 	= 0;
									icb_rsp_ready 	= 0;
									rdata_temp 		= 0;
									state_d			= 0;
									w_state_d 		= 0;
								end
				endcase
			end
		
		always @ (posedge S_AXI_ACLK, negedge S_AXI_ARESETN)
		if(!S_AXI_ARESETN)
			begin
				icb_cmd_wdata_r <= 0;
				icb_cmd_addr_r <= 0;
				rdata_temp_r <= 0;
			end
		else
			case(1)
				mem_wren :
					case(w_state_q)
						0	:	begin
									icb_cmd_addr_r <= axi_awaddr;
									icb_cmd_wdata_r <= S_AXI_WDATA;
								end
						default :	begin
										icb_cmd_addr_r <= icb_cmd_addr_r;
										icb_cmd_wdata_r <= icb_cmd_wdata_r;
									end
					endcase
				mem_rden :
					case(state_q)
						0	:	begin
									icb_cmd_addr_r <= axi_araddr;
									
								end
						1	:	begin
									if(icb_rsp_valid)
										rdata_temp_r <= icb_rsp_rdata;
								end
						default :	begin
										icb_cmd_addr_r <= icb_cmd_addr_r;
										rdata_temp_r <= rdata_temp_r;
									end
					endcase
				default : 	begin
								icb_cmd_addr_r <= icb_cmd_addr_r;
								icb_cmd_wdata_r <= icb_cmd_wdata_r;
								rdata_temp_r <= rdata_temp_r;
							end
			endcase
		
		always @ (posedge S_AXI_ACLK)
			begin
				state_q <= state_d;
				w_state_q <= w_state_d;
			end
		
	// User logic ends

	endmodule
	
