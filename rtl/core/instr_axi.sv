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
// instruction to AXI
module instr_axi #(
    parameter int unsigned FETCH_ADDR_WIDTH = 34,
    parameter int unsigned FETCH_DATA_WIDTH = 32,
    parameter int unsigned ID_WIDTH         = 4,

    parameter int unsigned AXI_ADDR_WIDTH   = FETCH_ADDR_WIDTH,
    //parameter int unsigned AXI_DATA_WIDTH   = 32,
    //parameter int unsigned AXI_USER_WIDTH   = 6,
    parameter int unsigned AXI_ID_WIDTH     = ID_WIDTH
    //parameter int unsigned SLICE_DEPTH      = 2,
    //parameter int unsigned AXI_STRB_WIDTH   = AXI_DATA_WIDTH/8
)(
   input  logic                         clk_i,
   input  logic                         rst_ni,
   //input  logic                         test_en_i,

   // Interface between cache_controller_to and Compactor
   input  logic                         refill_req_i,
   input  logic                         refill_type_i, // 0 | 1 : 0 --> 32 Bit ,  1--> 64bit
   output logic                         refill_gnt_o,
   input  logic [FETCH_ADDR_WIDTH-1:0]  refill_addr_i,
   input  logic [ID_WIDTH-1:0]          refill_ID_i,

   output logic                         refill_r_valid_o,
   output logic [FETCH_DATA_WIDTH-1:0]  refill_r_data_o,
   output logic                         refill_r_last_o,
   // ID may not be used if there has no cache
   output logic [ID_WIDTH-1:0]          refill_r_ID_o,

   AXI_BUS.Master                       axi
);

    assign axi.aw_valid  = '0;
    assign axi.aw_addr   = '0;
    assign axi.aw_prot   = '0;
    //assign axi.aw_region = '0;
    assign axi.aw_len    = '0;
    assign axi.aw_size   = 3'b000;
    assign axi.aw_burst  = 2'b00;
    assign axi.aw_lock   = '0;
    assign axi.aw_cache  = '0;
    assign axi.aw_qos    = '0;
    assign axi.aw_id     = '0;
    // assign axi.aw_user   = '0;

    assign axi.w_valid   = '0;
    assign axi.w_data    = '0;
    assign axi.w_strb    = '0;
    // assign axi.w_user    = '0;
    assign axi.w_last    = 1'b0;
    assign axi.b_ready   = 1'b0;

always_ff @(posedge clk_i or negedge rst_ni) begin 
    if(~rst_ni) begin
        axi.ar_valid  <='0;
        axi.ar_addr   <='0;      
    end else begin
        axi.ar_valid  <= refill_req_i;
        axi.ar_addr   <= {{(AXI_ADDR_WIDTH-FETCH_ADDR_WIDTH){1'b0}},refill_addr_i};
    end
end
   // assign axi.ar_valid  = refill_req_i;
   // assign axi.ar_addr   = {{(AXI_ADDR_WIDTH-FETCH_ADDR_WIDTH){1'b0}},refill_addr_i};
    assign axi.ar_prot   = '0;
    //assign axi.ar_region = '0; 
    assign axi.ar_len    = (refill_type_i) ? 8'h01 : 8'h00;
    assign axi.ar_size   = 3'b010;
    assign axi.ar_burst  = 2'b01;
    assign axi.ar_lock   = '0;
    assign axi.ar_cache  = '0;
    assign axi.ar_qos    = '0;
    assign axi.ar_id     = refill_ID_i;
    // assign axi.ar_user   = '0;

    assign axi.r_ready   = 1'b1;
	
	// assign axi.b_id	 = '0;
	// assign axi.b_user	 = '0;
	// assign axi.ar_id	 = '0;
//	assign axi.r_id	 = '0;
	// assign axi.r_user	 = '0;

	
    assign refill_gnt_o     = axi.ar_ready & axi.ar_valid;
    assign refill_r_valid_o = axi.r_valid;
    assign refill_r_ID_o    = axi.r_id;
    assign refill_r_data_o  = axi.r_data;
    assign refill_r_last_o  = axi.r_last;

endmodule