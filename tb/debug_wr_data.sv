`timescale 1ns/1ps
module wrdata(  reset,
				clk,
				tdi,
				tdo,
				tms,
				ram_data_out
				);
				
input clk,reset;
input tdo;
output tdi,tms;
output [41-1:0] ram_data_out [0:6];

// JTAG State Machine
//enum {TEST_LOGIC_RESET,RUN_TEST_IDLE,SELECT_DR,CAPTURE_DR,SHIFT_DR,EXIT1_DR,PAUSE_DR,EXIT2_DR,UPDATE_DR,SELECT_IR,CAPTURE_IR,SHIFT_IR,EXIT1_IR,PAUSE_IR,EXIT2_IR,UPDATE_IR} jtagStateReg;

   localparam TEST_LOGIC_RESET  = 4'h0;
   localparam RUN_TEST_IDLE     = 4'h1;
   localparam SELECT_DR         = 4'h2;
   localparam CAPTURE_DR        = 4'h3;
   localparam SHIFT_DR          = 4'h4;
   localparam EXIT1_DR          = 4'h5;
   localparam PAUSE_DR          = 4'h6;
   localparam EXIT2_DR          = 4'h7;
   localparam UPDATE_DR         = 4'h8;
   localparam SELECT_IR         = 4'h9;
   localparam CAPTURE_IR        = 4'hA;
   localparam SHIFT_IR          = 4'hB;
   localparam EXIT1_IR          = 4'hC;
   localparam PAUSE_IR          = 4'hD;
   localparam EXIT2_IR          = 4'hE;
   localparam UPDATE_IR         = 4'hF;
   
   localparam REG_BYPASS       = 5'b11111;
   localparam REG_IDCODE       = 5'b00001;
   localparam REG_DEBUG_ACCESS = 5'b10001;
   localparam REG_DTM_INFO     = 5'b10000;

localparam SHIFT_REG=41;   
localparam DATASIZE=41;
localparam INSTSIZE=5;
localparam ADDRESSSIZE=5;
localparam CTRSIZE=2000;
localparam ALLDATASIZE=DATASIZE*8;

localparam run_test_shiftDR=3'b001;
localparam shiftDR_updateDR=2'b11;
localparam updateDR_captureDR=2'b01;
localparam captureDR_shiftDR=1'b0;
localparam updateDR_shiftIR=4'b0011;
localparam readop=2'b01;
localparam writeop=2'b10;

localparam [12:0] change_debug_access_ctr={3'b011,{(INSTSIZE-1){1'b0}},5'b00110};
localparam [65:0] update_data={{21{1'b0}},shiftDR_updateDR,{(SHIFT_REG-1){1'b0}},run_test_shiftDR};
localparam [527:0]	re_update={8{update_data}};
//reg [75:0] read_data={{30{1'b0}},shiftDR_updateDR,{(SHIFT_REG-1){1'b0}},run_test_shiftDR};

reg jtag_tdi,jtag_tdo,jtag_tms,jtag_reset,jtag_DRV_TDO;
reg dtm_req_valid,dtm_req_ready,dtm_resp_valid,dtm_resp_ready;
reg [SHIFT_REG-1:0] dtm_req_bits;
reg [SHIFT_REG-ADDRESSSIZE-1:0] dtm_resp_bits;
reg [3:0]  jtagStateReg;
reg [4:0] address=5'b00000;

reg [SHIFT_REG-1:0] data [0:7];
//reg [40:0] readdata [0:6];

reg [ALLDATASIZE-1:0] datain=0;
//reg [ALLDATASIZE-1:0] readdatain;
reg [INSTSIZE-1:0] instin=0;
reg [SHIFT_REG-1:0] dataout=0;
reg [INSTSIZE-1:0] instout=0;
reg [CTRSIZE-1:0] ctrin=0;
reg [CTRSIZE-1:0] readctrin=0;
reg [SHIFT_REG-1:0] ram_data [0:6];

static reg [31:0] writedata [0:7];
int unsigned instrnum=0,data_count=0;
integer i,j;

reg num=0;
reg [1:0] option=0;//0 doing nothing;1 write;2 read



initial begin
	$readmemh ("test.txt",writedata);//("F:/riscv/riscv_dbg_20180731/riscv_dbg_20180727/ram_csr_read.txt",writedata);//ram_data_halt ram_data_write  ram_data_read
	for(j=0;j<8;j++)begin
		if(writedata[j]==0)begin
			instrnum=j;
			break;
		end
	end
			
	for(i=0;i<instrnum;i++) begin
		data[i]={address+i,{{2'b00},writedata[i]},writeop};
//		readdata[i]={address+i,{{2'b01},32'b0},writeop};
	end
	data[instrnum-1] ={address+instrnum-1,{2'b10},writedata[instrnum-1],writeop};
//	data[instrnum] ={address+instrnum-1,{2'b01},32'b0,readop};
	
	jtag_tdi = 1'b1;
	jtag_tms = 1'b0;
	datain = {data[7],data[6],data[5],data[4],data[3],data[2],data[1],data[0]};
//	readdatain ={readdata[6],readdata[5],readdata[4],readdata[3],readdata[2],readdata[1],readdata[0]};
	instin = REG_DEBUG_ACCESS;
	ctrin = {{8{update_data}},change_debug_access_ctr};
//	readctrin = {8{read_data}};
	option = 2'b01;
//	#3000 option = 2'b10;
end


always @(posedge clk or posedge jtag_reset) begin
      if (jtag_reset) begin
         jtagStateReg <= TEST_LOGIC_RESET;
      end 
	  else begin
         case (jtagStateReg)
           TEST_LOGIC_RESET  : jtagStateReg <= jtag_tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
           RUN_TEST_IDLE     : jtagStateReg <= jtag_tms ? SELECT_DR        : RUN_TEST_IDLE;
           SELECT_DR         : jtagStateReg <= jtag_tms ? SELECT_IR        : CAPTURE_DR;
           CAPTURE_DR        : jtagStateReg <= jtag_tms ? EXIT1_DR         : SHIFT_DR;
           SHIFT_DR          : jtagStateReg <= jtag_tms ? EXIT1_DR         : SHIFT_DR;
           EXIT1_DR          : jtagStateReg <= jtag_tms ? UPDATE_DR        : PAUSE_DR;
           PAUSE_DR          : jtagStateReg <= jtag_tms ? EXIT2_DR         : PAUSE_DR;
           EXIT2_DR          : jtagStateReg <= jtag_tms ? UPDATE_DR        : SHIFT_DR;
           UPDATE_DR         : jtagStateReg <= jtag_tms ? SELECT_DR        : RUN_TEST_IDLE;
           SELECT_IR         : jtagStateReg <= jtag_tms ? TEST_LOGIC_RESET : CAPTURE_IR;
           CAPTURE_IR        : jtagStateReg <= jtag_tms ? EXIT1_IR         : SHIFT_IR;
           SHIFT_IR          : jtagStateReg <= jtag_tms ? EXIT1_IR         : SHIFT_IR;
           EXIT1_IR          : jtagStateReg <= jtag_tms ? UPDATE_IR        : PAUSE_IR;
           PAUSE_IR          : jtagStateReg <= jtag_tms ? EXIT2_IR         : PAUSE_IR;
           EXIT2_IR          : jtagStateReg <= jtag_tms ? UPDATE_IR        : SHIFT_IR;
           UPDATE_IR         : jtagStateReg <= jtag_tms ? SELECT_DR        : RUN_TEST_IDLE; 
         endcase // case (jtagStateReg)
      end // else: !if(jtag_TRST)
   end // always @ (posedge jtag_TCK or posedge jtag_TRST)
   
   
always @(negedge clk && jtag_reset == 1'b0) begin
	
	case(jtagStateReg)
	SHIFT_DR:
	begin
		jtag_tdi = datain[0];
		datain = {1'b0,datain[ALLDATASIZE-1:1]};
		
		dataout[SHIFT_REG-2:0] = dataout[SHIFT_REG-1:1];
		dataout[SHIFT_REG-1] = jtag_tdo;
	end
	SHIFT_IR: 
	begin
		jtag_tdi = instin[0];
		instin = {1'b0,instin[INSTSIZE-1:1]};
		
		instout[INSTSIZE-1:1] = instout[INSTSIZE-2:0];
		instout[0] = jtag_tdo;
	end
	EXIT1_DR:
	begin
		dataout[SHIFT_REG-2:0] = dataout[SHIFT_REG-1:1];
		dataout[SHIFT_REG-1] = jtag_tdo;
	end
	UPDATE_DR:
	begin
		ram_data[dataout[SHIFT_REG-1:SHIFT_REG-5]] = dataout;
		data_count++;
	end
	default:;
	endcase
	
	jtag_tms = ctrin[0];
	ctrin = ctrin[CTRSIZE-1:1];
	
	if(data_count==8) begin
		data[instrnum-1]={address+instrnum-1,{2'b11},writedata[instrnum-1]+4,writeop};
		datain={data[7],data[6],data[5],data[4],data[3],data[2],data[1],data[0]};
		ctrin=re_update;
	end
	
end

assign ram_data_out[0]=ram_data[0];
assign ram_data_out[1]=ram_data[1];
assign ram_data_out[2]=ram_data[2];
assign ram_data_out[3]=ram_data[3];
assign ram_data_out[4]=ram_data[4];
assign ram_data_out[5]=ram_data[5];
assign ram_data_out[6]=ram_data[6];
assign jtag_reset=reset;
assign tdi=jtag_tdi;
assign jtag_tdo=tdo;
assign tms=jtag_tms;

endmodule
