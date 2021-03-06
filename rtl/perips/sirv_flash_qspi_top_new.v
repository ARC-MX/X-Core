 /*                                                                      
 Copyright 2017 Silicon Integrated Microelectronics, Inc.                
                                                                         
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
                                                                         
                                                                         
                                                                         
//=====================================================================
//--        _______   ___
//--       (   ____/ /__/
//--        \ \     __
//--     ____\ \   / /
//--    /_______\ /_/   MICROELECTRONICS
//--
//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  The top level module of flash-qspi
//
// ====================================================================

module flash_qspi_top(
  input   clk,
  input   rst_n,
//  input  clk_ila,	
  input                      i_icb_cmd_valid,
  output                     i_icb_cmd_ready,
  input  [32-1:0]            i_icb_cmd_addr, 
  input                      i_icb_cmd_read, 
  input  [32-1:0]            i_icb_cmd_wdata,
  
  output                    i_icb_rsp_valid,
  input                      i_icb_rsp_ready,
  output [32-1:0]          i_icb_rsp_rdata,

  input                      f_icb_cmd_valid,
  output                     f_icb_cmd_ready,
  input  [32-1:0]            f_icb_cmd_addr, 
  input                      f_icb_cmd_read, 
  input  [32-1:0]            f_icb_cmd_wdata,
  
  output                    f_icb_rsp_valid,
  input                      f_icb_rsp_ready,
  output [32-1:0]          f_icb_rsp_rdata,

  output  io_port_sck,
  input   io_port_dq_0_i,
  output  io_port_dq_0_o,
  output  io_port_dq_0_oe,
  input   io_port_dq_1_i,
  output  io_port_dq_1_o,
  output  io_port_dq_1_oe,
  input   io_port_dq_2_i,
  output  io_port_dq_2_o,
  output  io_port_dq_2_oe,
  input   io_port_dq_3_i,
  output  io_port_dq_3_o,
  output  io_port_dq_3_oe,
  output  io_port_cs_0,
  output  io_tl_i_0_0 
);
  reg [32-1:0] f_icb_rsp_rdata_r;
  reg [32-1:0] i_icb_rsp_rdata_r;
  reg i_icb_rsp_valid_r;
  reg f_icb_rsp_valid_r;
  reg [32-1:0] f_icb_rsp_rdata_rr;
  reg [32-1:0] i_icb_rsp_rdata_rr;
  reg i_icb_rsp_valid_rr;
  reg f_icb_rsp_valid_rr;
  always @(posedge clk )
  begin
	f_icb_rsp_rdata_rr <= io_tl_f_0_d_bits_data;
	i_icb_rsp_rdata_rr <= io_tl_r_0_d_bits_data;
	i_icb_rsp_valid_rr <= io_tl_r_0_d_valid;
	f_icb_rsp_valid_rr <= io_tl_f_0_d_valid;
  end                                       
  assign f_icb_rsp_rdata = f_icb_rsp_rdata_rr;
  assign f_icb_rsp_valid = f_icb_rsp_valid_rr;
  assign i_icb_rsp_rdata = i_icb_rsp_rdata_rr;
  assign i_icb_rsp_valid = i_icb_rsp_valid_rr;
// ila_1 u_ila_1 (
	// .clk(clk_ila), // input wire clk


	// .probe0(f_icb_cmd_valid), // input wire [0:0]  probe0  
	// .probe1(f_icb_cmd_ready), // input wire [0:0]  probe1 
	// .probe2(f_icb_cmd_addr ), // input wire [0:0]  probe2 
	// .probe3(f_icb_cmd_read ), // input wire [0:0]  probe3 
	// .probe4(f_icb_cmd_wdata), // input wire [0:0]  probe4 
	// .probe5(f_icb_rsp_valid), // input wire [0:0]  probe5 
	// .probe6(f_icb_rsp_ready), // input wire [0:0]  probe6 
	// .probe7(f_icb_rsp_rdata), // input wire [0:0]  probe7
	// .probe8(i_icb_cmd_valid), // input wire [0:0]  probe0  
	// .probe9(i_icb_cmd_ready), // input wire [0:0]  probe1 
	// .probe10(i_icb_cmd_addr ), // input wire [0:0]  probe2 
	// .probe11(i_icb_cmd_read ), // input wire [0:0]  probe3 
	// .probe12(i_icb_cmd_wdata), // input wire [0:0]  probe4 
	// .probe13(i_icb_rsp_valid), // input wire [0:0]  probe5 
	// .probe14(i_icb_rsp_ready), // input wire [0:0]  probe6 
	// .probe15(i_icb_rsp_rdata)  // input wire [0:0]  probe7
	// .probe16(io_port_sck	), // input wire [0:0]  probe6 
	// .probe17(io_port_dq_0_i	), // input wire [0:0]  probe7
	// .probe18(io_port_dq_0_o	), // input wire [0:0]  probe0  
	// .probe19(io_port_dq_0_oe), // input wire [0:0]  probe1 
	// .probe20(io_port_dq_1_i	), // input wire [0:0]  probe2 
	// .probe21(io_port_dq_1_o	), // input wire [0:0]  probe3 
	// .probe22(io_port_dq_1_oe), // input wire [0:0]  probe4 
	// .probe23(io_port_dq_2_i	), // input wire [0:0]  probe5 
	// .probe24(io_port_dq_2_o	), // input wire [0:0]  probe6 
	// .probe25(io_port_dq_2_oe), // input wire [0:0]  probe7
	// .probe26(io_port_dq_3_i	), // input wire [0:0]  probe6 
	// .probe27(io_port_dq_3_o	), // input wire [0:0]  probe7
	// .probe28(io_port_dq_3_oe), // input wire [0:0]  probe0  
	// .probe29(io_port_cs_0	), // input wire [0:0]  probe1 
	// .probe30(io_tl_i_0_0 	)  // input wire [0:0]  probe2 
// );
	// ila_2 u_ila_2(
	// .clk(clk_ila), // input wire clk


	// .probe0(i_icb_cmd_valid), // input wire [0:0]  probe0  
	// .probe1(i_icb_cmd_ready), // input wire [0:0]  probe1 
	// .probe2(i_icb_cmd_addr ), // input wire [0:0]  probe2 
	// .probe3(i_icb_cmd_read ), // input wire [0:0]  probe3 
	// .probe4(i_icb_cmd_wdata), // input wire [0:0]  probe4 
	// .probe5(i_icb_rsp_valid), // input wire [0:0]  probe5 
	// .probe6(i_icb_rsp_ready), // input wire [0:0]  probe6 
	// .probe7(i_icb_rsp_rdata) // input wire [0:0]  probe7
// );
  wire  io_tl_r_0_a_ready;
  assign  i_icb_cmd_ready  = io_tl_r_0_a_ready;
  wire  io_tl_r_0_a_valid  = i_icb_cmd_valid;
  wire  [2:0] io_tl_r_0_a_bits_opcode  = i_icb_cmd_read ? 3'h4 : 3'h0;
  wire  [2:0] io_tl_r_0_a_bits_param  = 3'b0;
  wire  [2:0] io_tl_r_0_a_bits_size = 3'd2;
  wire  [4:0] io_tl_r_0_a_bits_source  = 5'b0;
  wire  [28:0] io_tl_r_0_a_bits_address  = i_icb_cmd_addr[28:0];
  wire  [3:0] io_tl_r_0_a_bits_mask  = 4'b1111;
  wire  [31:0] io_tl_r_0_a_bits_data  = i_icb_cmd_wdata;

  
  wire  io_tl_r_0_d_ready = i_icb_rsp_ready;

  wire  [2:0] io_tl_r_0_d_bits_opcode;
  wire  [1:0] io_tl_r_0_d_bits_param;
  wire  [2:0] io_tl_r_0_d_bits_size;
  wire  [4:0] io_tl_r_0_d_bits_source;
  wire  io_tl_r_0_d_bits_sink;
  wire  [1:0] io_tl_r_0_d_bits_addr_lo;
  wire  [31:0] io_tl_r_0_d_bits_data;
  wire  io_tl_r_0_d_bits_error;
  wire  io_tl_r_0_d_valid;

//  assign  i_icb_rsp_valid_r = io_tl_r_0_d_valid;
//  assign  i_icb_rsp_rdata_r = io_tl_r_0_d_bits_data;

  // Not used
  wire  io_tl_r_0_b_ready = 1'b0;
  wire  io_tl_r_0_b_valid;
  wire  [2:0] io_tl_r_0_b_bits_opcode;
  wire  [1:0] io_tl_r_0_b_bits_param;
  wire  [2:0] io_tl_r_0_b_bits_size;
  wire  [4:0] io_tl_r_0_b_bits_source;
  wire  [28:0] io_tl_r_0_b_bits_address;
  wire  [3:0] io_tl_r_0_b_bits_mask;
  wire  [31:0] io_tl_r_0_b_bits_data;

  // Not used
  wire  io_tl_r_0_c_ready;
  wire  io_tl_r_0_c_valid = 1'b0;
  wire  [2:0] io_tl_r_0_c_bits_opcode = 3'b0;
  wire  [2:0] io_tl_r_0_c_bits_param = 3'b0;
  wire  [2:0] io_tl_r_0_c_bits_size = 3'd2;
  wire  [4:0] io_tl_r_0_c_bits_source = 5'b0;
  wire  [28:0] io_tl_r_0_c_bits_address = 29'b0;
  wire  [31:0] io_tl_r_0_c_bits_data = 32'b0;
  wire  io_tl_r_0_c_bits_error = 1'b0;

  // Not used
  wire  io_tl_r_0_e_ready;
  wire  io_tl_r_0_e_valid = 1'b0;
  wire  io_tl_r_0_e_bits_sink = 1'b0;

  /////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////

  wire  io_tl_f_0_a_ready;
  assign  f_icb_cmd_ready  = io_tl_f_0_a_ready;
  wire  io_tl_f_0_a_valid  = f_icb_cmd_valid;
  wire  [2:0] io_tl_f_0_a_bits_opcode  = f_icb_cmd_read ? 3'h4 : 3'h0;
  wire  [2:0] io_tl_f_0_a_bits_param  = 3'b0;
  wire  [2:0] io_tl_f_0_a_bits_size = 3'd2;
  wire  [1:0] io_tl_f_0_a_bits_source  = 2'b0;
  // We must force the address to be aligned to 32bits
  wire  [29:0] io_tl_f_0_a_bits_address  = {f_icb_cmd_addr[29:2],2'b0};
  wire  [3:0] io_tl_f_0_a_bits_mask  = 4'b1111;
  wire  [31:0] io_tl_f_0_a_bits_data  = f_icb_cmd_wdata;

  
  wire  io_tl_f_0_d_ready = f_icb_rsp_ready;

  wire  [2:0] io_tl_f_0_d_bits_opcode;
  wire  [1:0] io_tl_f_0_d_bits_param;
  wire  [2:0] io_tl_f_0_d_bits_size;
  wire  [1:0] io_tl_f_0_d_bits_source;
  wire  io_tl_f_0_d_bits_sink;
  wire  [1:0] io_tl_f_0_d_bits_addr_lo;
  wire  [31:0] io_tl_f_0_d_bits_data;
  wire  io_tl_f_0_d_bits_error;
  wire  io_tl_f_0_d_valid;

  //assign  f_icb_rsp_valid_r = io_tl_f_0_d_valid;
  //assign  f_icb_rsp_rdata_r = io_tl_f_0_d_bits_data;

  // Not used
  wire  io_tl_f_0_b_ready = 1'b0;
  wire  io_tl_f_0_b_valid;
  wire  [2:0] io_tl_f_0_b_bits_opcode;
  wire  [1:0] io_tl_f_0_b_bits_param;
  wire  [2:0] io_tl_f_0_b_bits_size;
  wire  [1:0] io_tl_f_0_b_bits_source;
  wire  [29:0] io_tl_f_0_b_bits_address;
  wire  [3:0] io_tl_f_0_b_bits_mask;
  wire  [31:0] io_tl_f_0_b_bits_data;

  // Not used
  wire  io_tl_f_0_c_ready;
  wire  io_tl_f_0_c_valid = 1'b0;
  wire  [2:0] io_tl_f_0_c_bits_opcode = 3'b0;
  wire  [2:0] io_tl_f_0_c_bits_param = 3'b0;
  wire  [2:0] io_tl_f_0_c_bits_size = 3'd2;
  wire  [1:0] io_tl_f_0_c_bits_source = 2'b0;
  wire  [29:0] io_tl_f_0_c_bits_address = 30'b0;
  wire  [31:0] io_tl_f_0_c_bits_data = 32'b0;
  wire  io_tl_f_0_c_bits_error = 1'b0;

  // Not used
  wire  io_tl_f_0_e_ready;
  wire  io_tl_f_0_e_valid = 1'b0;
  wire  io_tl_f_0_e_bits_sink = 1'b0;

  /////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////

  wire  tl_f_0_a_ready;
  wire  tl_f_0_a_valid;
  wire  [2:0] tl_f_0_a_bits_opcode;
  wire  [2:0] tl_f_0_a_bits_param;
  wire  [2:0] tl_f_0_a_bits_size;
  wire  [6:0] tl_f_0_a_bits_source;
  wire  [29:0] tl_f_0_a_bits_address;
  wire  tl_f_0_a_bits_mask;
  wire  [7:0] tl_f_0_a_bits_data;

  
  wire  io_in_0_a_ready;
  wire  io_in_0_a_valid;
  wire [2:0] io_in_0_a_bits_opcode;
  wire [2:0] io_in_0_a_bits_param;
  wire [2:0] io_in_0_a_bits_size;
  wire [1:0] io_in_0_a_bits_source;
  wire [29:0] io_in_0_a_bits_address;
  wire  io_in_0_a_bits_mask;
  wire [7:0] io_in_0_a_bits_data;
  wire  io_in_0_b_ready;
  wire  io_in_0_b_valid;
  wire [2:0] io_in_0_b_bits_opcode;
  wire [1:0] io_in_0_b_bits_param;
  wire [2:0] io_in_0_b_bits_size;
  wire [1:0] io_in_0_b_bits_source;
  wire [29:0] io_in_0_b_bits_address;
  wire  io_in_0_b_bits_mask;
  wire [7:0] io_in_0_b_bits_data;
  wire  io_in_0_c_ready;
  wire  io_in_0_c_valid;
  wire [2:0] io_in_0_c_bits_opcode;
  wire [2:0] io_in_0_c_bits_param;
  wire [2:0] io_in_0_c_bits_size;
  wire [1:0] io_in_0_c_bits_source;
  wire [29:0] io_in_0_c_bits_address;
  wire [7:0] io_in_0_c_bits_data;
  wire  io_in_0_c_bits_error;
  wire  io_in_0_d_ready;
  wire  io_in_0_d_valid;
  wire [2:0] io_in_0_d_bits_opcode;
  wire [1:0] io_in_0_d_bits_param;
  wire [2:0] io_in_0_d_bits_size;
  wire [1:0] io_in_0_d_bits_source;
  wire  io_in_0_d_bits_sink;
  wire  io_in_0_d_bits_addr_lo;
  wire [7:0] io_in_0_d_bits_data;
  wire  io_in_0_d_bits_error;
  wire  io_in_0_e_ready;
  wire  io_in_0_e_valid;
  wire  io_in_0_e_bits_sink;

  wire  io_out_0_a_ready;
  wire  io_out_0_a_valid;
  wire [2:0] io_out_0_a_bits_opcode;
  wire [2:0] io_out_0_a_bits_param;
  wire [2:0] io_out_0_a_bits_size;
  wire [6:0] io_out_0_a_bits_source;
  wire [29:0] io_out_0_a_bits_address;
  wire  io_out_0_a_bits_mask;
  wire [7:0] io_out_0_a_bits_data;
  wire  io_out_0_b_ready;
  wire  io_out_0_b_valid;
  wire [2:0] io_out_0_b_bits_opcode;
  wire [1:0] io_out_0_b_bits_param;
  wire [2:0] io_out_0_b_bits_size;
  wire [6:0] io_out_0_b_bits_source;
  wire [29:0] io_out_0_b_bits_address;
  wire  io_out_0_b_bits_mask;
  wire [7:0] io_out_0_b_bits_data;
  wire  io_out_0_c_ready;
  wire  io_out_0_c_valid;
  wire [2:0] io_out_0_c_bits_opcode;
  wire [2:0] io_out_0_c_bits_param;
  wire [2:0] io_out_0_c_bits_size;
  wire [6:0] io_out_0_c_bits_source;
  wire [29:0] io_out_0_c_bits_address;
  wire [7:0] io_out_0_c_bits_data;
  wire  io_out_0_c_bits_error;
  wire  io_out_0_d_ready;
  wire  io_out_0_d_valid;
  wire [2:0] io_out_0_d_bits_opcode;
  wire [1:0] io_out_0_d_bits_param;
  wire [2:0] io_out_0_d_bits_size;
  wire [6:0] io_out_0_d_bits_source;
  wire  io_out_0_d_bits_sink;
  wire  io_out_0_d_bits_addr_lo;
  wire [7:0] io_out_0_d_bits_data;
  wire  io_out_0_d_bits_error;
  wire  io_out_0_e_ready;
  wire  io_out_0_e_valid;
  wire  io_out_0_e_bits_sink;


  sirv_tlwidthwidget_qspi qspi_TLWidthWidget (
    .clock(clk),
    .reset(~rst_n),
    .io_in_0_a_ready(io_tl_f_0_a_ready),
    .io_in_0_a_valid(io_tl_f_0_a_valid),
    .io_in_0_a_bits_opcode(io_tl_f_0_a_bits_opcode),
    .io_in_0_a_bits_param(io_tl_f_0_a_bits_param),
    .io_in_0_a_bits_size(io_tl_f_0_a_bits_size),
    .io_in_0_a_bits_source(io_tl_f_0_a_bits_source),
    .io_in_0_a_bits_address(io_tl_f_0_a_bits_address),
    .io_in_0_a_bits_mask(io_tl_f_0_a_bits_mask),
    .io_in_0_a_bits_data(io_tl_f_0_a_bits_data),
    .io_in_0_b_ready(io_tl_f_0_b_ready),
    .io_in_0_b_valid(io_tl_f_0_b_valid),
    .io_in_0_b_bits_opcode(io_tl_f_0_b_bits_opcode),
    .io_in_0_b_bits_param(io_tl_f_0_b_bits_param),
    .io_in_0_b_bits_size(io_tl_f_0_b_bits_size),
    .io_in_0_b_bits_source(io_tl_f_0_b_bits_source),
    .io_in_0_b_bits_address(io_tl_f_0_b_bits_address),
    .io_in_0_b_bits_mask(io_tl_f_0_b_bits_mask),
    .io_in_0_b_bits_data(io_tl_f_0_b_bits_data),
    .io_in_0_c_ready(io_tl_f_0_c_ready),
    .io_in_0_c_valid(io_tl_f_0_c_valid),
    .io_in_0_c_bits_opcode(io_tl_f_0_c_bits_opcode),
    .io_in_0_c_bits_param(io_tl_f_0_c_bits_param),
    .io_in_0_c_bits_size(io_tl_f_0_c_bits_size),
    .io_in_0_c_bits_source(io_tl_f_0_c_bits_source),
    .io_in_0_c_bits_address(io_tl_f_0_c_bits_address),
    .io_in_0_c_bits_data(io_tl_f_0_c_bits_data),
    .io_in_0_c_bits_error(io_tl_f_0_c_bits_error),
    .io_in_0_d_ready(io_tl_f_0_d_ready),
    .io_in_0_d_valid(io_tl_f_0_d_valid),
    .io_in_0_d_bits_opcode(io_tl_f_0_d_bits_opcode),
    .io_in_0_d_bits_param(io_tl_f_0_d_bits_param),
    .io_in_0_d_bits_size(io_tl_f_0_d_bits_size),
    .io_in_0_d_bits_source(io_tl_f_0_d_bits_source),
    .io_in_0_d_bits_sink(io_tl_f_0_d_bits_sink),
    .io_in_0_d_bits_addr_lo(io_tl_f_0_d_bits_addr_lo),
    .io_in_0_d_bits_data(io_tl_f_0_d_bits_data),
    .io_in_0_d_bits_error(io_tl_f_0_d_bits_error),
    .io_in_0_e_ready(io_tl_f_0_e_ready),
    .io_in_0_e_valid(io_tl_f_0_e_valid),
    .io_in_0_e_bits_sink(io_tl_f_0_e_bits_sink),

    .io_out_0_a_ready(io_in_0_a_ready),
    .io_out_0_a_valid(io_in_0_a_valid),
    .io_out_0_a_bits_opcode(io_in_0_a_bits_opcode),
    .io_out_0_a_bits_param(io_in_0_a_bits_param),
    .io_out_0_a_bits_size(io_in_0_a_bits_size),
    .io_out_0_a_bits_source(io_in_0_a_bits_source),
    .io_out_0_a_bits_address(io_in_0_a_bits_address),
    .io_out_0_a_bits_mask(io_in_0_a_bits_mask),
    .io_out_0_a_bits_data(io_in_0_a_bits_data),
    .io_out_0_b_ready(io_in_0_b_ready),
    .io_out_0_b_valid(io_in_0_b_valid),
    .io_out_0_b_bits_opcode(io_in_0_b_bits_opcode),
    .io_out_0_b_bits_param(io_in_0_b_bits_param),
    .io_out_0_b_bits_size(io_in_0_b_bits_size),
    .io_out_0_b_bits_source(io_in_0_b_bits_source),
    .io_out_0_b_bits_address(io_in_0_b_bits_address),
    .io_out_0_b_bits_mask(io_in_0_b_bits_mask),
    .io_out_0_b_bits_data(io_in_0_b_bits_data),
    .io_out_0_c_ready(io_in_0_c_ready),
    .io_out_0_c_valid(io_in_0_c_valid),
    .io_out_0_c_bits_opcode(io_in_0_c_bits_opcode),
    .io_out_0_c_bits_param(io_in_0_c_bits_param),
    .io_out_0_c_bits_size(io_in_0_c_bits_size),
    .io_out_0_c_bits_source(io_in_0_c_bits_source),
    .io_out_0_c_bits_address(io_in_0_c_bits_address),
    .io_out_0_c_bits_data(io_in_0_c_bits_data),
    .io_out_0_c_bits_error(io_in_0_c_bits_error),
    .io_out_0_d_ready(io_in_0_d_ready),
    .io_out_0_d_valid(io_in_0_d_valid),
    .io_out_0_d_bits_opcode(io_in_0_d_bits_opcode),
    .io_out_0_d_bits_param(io_in_0_d_bits_param),
    .io_out_0_d_bits_size(io_in_0_d_bits_size),
    .io_out_0_d_bits_source(io_in_0_d_bits_source),
    .io_out_0_d_bits_sink(io_in_0_d_bits_sink),
    .io_out_0_d_bits_addr_lo(io_in_0_d_bits_addr_lo),
    .io_out_0_d_bits_data(io_in_0_d_bits_data),
    .io_out_0_d_bits_error(io_in_0_d_bits_error),
    .io_out_0_e_ready(io_in_0_e_ready),
    .io_out_0_e_valid(io_in_0_e_valid),
    .io_out_0_e_bits_sink(io_in_0_e_bits_sink)
  );

  sirv_tlfragmenter_qspi_1 qspi_TLFragmenter_1 (
    .clock (clk   ),
    .reset (~rst_n),
    .io_in_0_a_ready(io_in_0_a_ready),
    .io_in_0_a_valid(io_in_0_a_valid),
    .io_in_0_a_bits_opcode(io_in_0_a_bits_opcode),
    .io_in_0_a_bits_param(io_in_0_a_bits_param),
    .io_in_0_a_bits_size(io_in_0_a_bits_size),
    .io_in_0_a_bits_source(io_in_0_a_bits_source),
    .io_in_0_a_bits_address(io_in_0_a_bits_address),
    .io_in_0_a_bits_mask(io_in_0_a_bits_mask),
    .io_in_0_a_bits_data(io_in_0_a_bits_data),
    .io_in_0_b_ready(io_in_0_b_ready),
    .io_in_0_b_valid(io_in_0_b_valid),
    .io_in_0_b_bits_opcode(io_in_0_b_bits_opcode),
    .io_in_0_b_bits_param(io_in_0_b_bits_param),
    .io_in_0_b_bits_size(io_in_0_b_bits_size),
    .io_in_0_b_bits_source(io_in_0_b_bits_source),
    .io_in_0_b_bits_address(io_in_0_b_bits_address),
    .io_in_0_b_bits_mask(io_in_0_b_bits_mask),
    .io_in_0_b_bits_data(io_in_0_b_bits_data),
    .io_in_0_c_ready(io_in_0_c_ready),
    .io_in_0_c_valid(io_in_0_c_valid),
    .io_in_0_c_bits_opcode(io_in_0_c_bits_opcode),
    .io_in_0_c_bits_param(io_in_0_c_bits_param),
    .io_in_0_c_bits_size(io_in_0_c_bits_size),
    .io_in_0_c_bits_source(io_in_0_c_bits_source),
    .io_in_0_c_bits_address(io_in_0_c_bits_address),
    .io_in_0_c_bits_data(io_in_0_c_bits_data),
    .io_in_0_c_bits_error(io_in_0_c_bits_error),
    .io_in_0_d_ready(io_in_0_d_ready),
    .io_in_0_d_valid(io_in_0_d_valid),
    .io_in_0_d_bits_opcode(io_in_0_d_bits_opcode),
    .io_in_0_d_bits_param(io_in_0_d_bits_param),
    .io_in_0_d_bits_size(io_in_0_d_bits_size),
    .io_in_0_d_bits_source(io_in_0_d_bits_source),
    .io_in_0_d_bits_sink(io_in_0_d_bits_sink),
    .io_in_0_d_bits_addr_lo(io_in_0_d_bits_addr_lo),
    .io_in_0_d_bits_data(io_in_0_d_bits_data),
    .io_in_0_d_bits_error(io_in_0_d_bits_error),
    .io_in_0_e_ready(io_in_0_e_ready),
    .io_in_0_e_valid(io_in_0_e_valid),
    .io_in_0_e_bits_sink(io_in_0_e_bits_sink),
    .io_out_0_a_ready(io_out_0_a_ready),
    .io_out_0_a_valid(io_out_0_a_valid),
    .io_out_0_a_bits_opcode(io_out_0_a_bits_opcode),
    .io_out_0_a_bits_param(io_out_0_a_bits_param),
    .io_out_0_a_bits_size(io_out_0_a_bits_size),
    .io_out_0_a_bits_source(io_out_0_a_bits_source),
    .io_out_0_a_bits_address(io_out_0_a_bits_address),
    .io_out_0_a_bits_mask(io_out_0_a_bits_mask),
    .io_out_0_a_bits_data(io_out_0_a_bits_data),
    .io_out_0_b_ready(io_out_0_b_ready),
    .io_out_0_b_valid(io_out_0_b_valid),
    .io_out_0_b_bits_opcode(io_out_0_b_bits_opcode),
    .io_out_0_b_bits_param(io_out_0_b_bits_param),
    .io_out_0_b_bits_size(io_out_0_b_bits_size),
    .io_out_0_b_bits_source(io_out_0_b_bits_source),
    .io_out_0_b_bits_address(io_out_0_b_bits_address),
    .io_out_0_b_bits_mask(io_out_0_b_bits_mask),
    .io_out_0_b_bits_data(io_out_0_b_bits_data),
    .io_out_0_c_ready(io_out_0_c_ready),
    .io_out_0_c_valid(io_out_0_c_valid),
    .io_out_0_c_bits_opcode(io_out_0_c_bits_opcode),
    .io_out_0_c_bits_param(io_out_0_c_bits_param),
    .io_out_0_c_bits_size(io_out_0_c_bits_size),
    .io_out_0_c_bits_source(io_out_0_c_bits_source),
    .io_out_0_c_bits_address(io_out_0_c_bits_address),
    .io_out_0_c_bits_data(io_out_0_c_bits_data),
    .io_out_0_c_bits_error(io_out_0_c_bits_error),
    .io_out_0_d_ready(io_out_0_d_ready),
    .io_out_0_d_valid(io_out_0_d_valid),
    .io_out_0_d_bits_opcode(io_out_0_d_bits_opcode),
    .io_out_0_d_bits_param(io_out_0_d_bits_param),
    .io_out_0_d_bits_size(io_out_0_d_bits_size),
    .io_out_0_d_bits_source(io_out_0_d_bits_source),
    .io_out_0_d_bits_sink(io_out_0_d_bits_sink),
    .io_out_0_d_bits_addr_lo(io_out_0_d_bits_addr_lo),
    .io_out_0_d_bits_data(io_out_0_d_bits_data),
    .io_out_0_d_bits_error(io_out_0_d_bits_error),
    .io_out_0_e_ready(io_out_0_e_ready),
    .io_out_0_e_valid(io_out_0_e_valid),
    .io_out_0_e_bits_sink(io_out_0_e_bits_sink)
  );
sirv_flash_qspi u_sirv_flash_qspi(
  .clock                            (clk                              ),
  .reset                            (~rst_n                           ),

  .io_tl_r_0_a_ready                  (io_tl_r_0_a_ready                  ),
  .io_tl_r_0_a_valid                  (io_tl_r_0_a_valid                  ),
  .io_tl_r_0_a_bits_opcode            (io_tl_r_0_a_bits_opcode            ),
  .io_tl_r_0_a_bits_param             (io_tl_r_0_a_bits_param             ),
  .io_tl_r_0_a_bits_size              (io_tl_r_0_a_bits_size              ),
  .io_tl_r_0_a_bits_source            (io_tl_r_0_a_bits_source            ),
  .io_tl_r_0_a_bits_address           (io_tl_r_0_a_bits_address           ),
  .io_tl_r_0_a_bits_mask              (io_tl_r_0_a_bits_mask              ),
  .io_tl_r_0_a_bits_data              (io_tl_r_0_a_bits_data              ),
  .io_tl_r_0_b_ready                  (io_tl_r_0_b_ready                  ),
  .io_tl_r_0_b_valid                  (io_tl_r_0_b_valid                  ),
  .io_tl_r_0_b_bits_opcode            (io_tl_r_0_b_bits_opcode            ),
  .io_tl_r_0_b_bits_param             (io_tl_r_0_b_bits_param             ),
  .io_tl_r_0_b_bits_size              (io_tl_r_0_b_bits_size              ),
  .io_tl_r_0_b_bits_source            (io_tl_r_0_b_bits_source            ),
  .io_tl_r_0_b_bits_address           (io_tl_r_0_b_bits_address           ),
  .io_tl_r_0_b_bits_mask              (io_tl_r_0_b_bits_mask              ),
  .io_tl_r_0_b_bits_data              (io_tl_r_0_b_bits_data              ),
  .io_tl_r_0_c_ready                  (io_tl_r_0_c_ready                  ),
  .io_tl_r_0_c_valid                  (io_tl_r_0_c_valid                  ),
  .io_tl_r_0_c_bits_opcode            (io_tl_r_0_c_bits_opcode            ),
  .io_tl_r_0_c_bits_param             (io_tl_r_0_c_bits_param             ),
  .io_tl_r_0_c_bits_size              (io_tl_r_0_c_bits_size              ),
  .io_tl_r_0_c_bits_source            (io_tl_r_0_c_bits_source            ),
  .io_tl_r_0_c_bits_address           (io_tl_r_0_c_bits_address           ),
  .io_tl_r_0_c_bits_data              (io_tl_r_0_c_bits_data              ),
  .io_tl_r_0_c_bits_error             (io_tl_r_0_c_bits_error             ),
  .io_tl_r_0_d_ready                  (io_tl_r_0_d_ready                  ),
  .io_tl_r_0_d_valid                  (io_tl_r_0_d_valid                  ),
  .io_tl_r_0_d_bits_opcode            (io_tl_r_0_d_bits_opcode            ),
  .io_tl_r_0_d_bits_param             (io_tl_r_0_d_bits_param             ),
  .io_tl_r_0_d_bits_size              (io_tl_r_0_d_bits_size              ),
  .io_tl_r_0_d_bits_source            (io_tl_r_0_d_bits_source            ),
  .io_tl_r_0_d_bits_sink              (io_tl_r_0_d_bits_sink              ),
  .io_tl_r_0_d_bits_addr_lo           (io_tl_r_0_d_bits_addr_lo           ),
  .io_tl_r_0_d_bits_data              (io_tl_r_0_d_bits_data              ),
  .io_tl_r_0_d_bits_error             (io_tl_r_0_d_bits_error             ),
  .io_tl_r_0_e_ready                  (io_tl_r_0_e_ready                  ),
  .io_tl_r_0_e_valid                  (io_tl_r_0_e_valid                  ),
  .io_tl_r_0_e_bits_sink              (io_tl_r_0_e_bits_sink              ),

  .io_tl_f_0_a_ready                  (io_out_0_a_ready                  ),
  .io_tl_f_0_a_valid                  (io_out_0_a_valid                  ),
  .io_tl_f_0_a_bits_opcode            (io_out_0_a_bits_opcode            ),
  .io_tl_f_0_a_bits_param             (io_out_0_a_bits_param             ),
  .io_tl_f_0_a_bits_size              (io_out_0_a_bits_size              ),
  .io_tl_f_0_a_bits_source            (io_out_0_a_bits_source            ),
  .io_tl_f_0_a_bits_address           (io_out_0_a_bits_address           ),
  .io_tl_f_0_a_bits_mask              (io_out_0_a_bits_mask              ),
  .io_tl_f_0_a_bits_data              (io_out_0_a_bits_data              ),
  .io_tl_f_0_b_ready                  (io_out_0_b_ready                  ),
  .io_tl_f_0_b_valid                  (io_out_0_b_valid                  ),
  .io_tl_f_0_b_bits_opcode            (io_out_0_b_bits_opcode            ),
  .io_tl_f_0_b_bits_param             (io_out_0_b_bits_param             ),
  .io_tl_f_0_b_bits_size              (io_out_0_b_bits_size              ),
  .io_tl_f_0_b_bits_source            (io_out_0_b_bits_source            ),
  .io_tl_f_0_b_bits_address           (io_out_0_b_bits_address           ),
  .io_tl_f_0_b_bits_mask              (io_out_0_b_bits_mask              ),
  .io_tl_f_0_b_bits_data              (io_out_0_b_bits_data              ),
  .io_tl_f_0_c_ready                  (io_out_0_c_ready                  ),
  .io_tl_f_0_c_valid                  (io_out_0_c_valid                  ),
  .io_tl_f_0_c_bits_opcode            (io_out_0_c_bits_opcode            ),
  .io_tl_f_0_c_bits_param             (io_out_0_c_bits_param             ),
  .io_tl_f_0_c_bits_size              (io_out_0_c_bits_size              ),
  .io_tl_f_0_c_bits_source            (io_out_0_c_bits_source            ),
  .io_tl_f_0_c_bits_address           (io_out_0_c_bits_address           ),
  .io_tl_f_0_c_bits_data              (io_out_0_c_bits_data              ),
  .io_tl_f_0_c_bits_error             (io_out_0_c_bits_error             ),
  .io_tl_f_0_d_ready                  (io_out_0_d_ready                  ),
  .io_tl_f_0_d_valid                  (io_out_0_d_valid                  ),
  .io_tl_f_0_d_bits_opcode            (io_out_0_d_bits_opcode            ),
  .io_tl_f_0_d_bits_param             (io_out_0_d_bits_param             ),
  .io_tl_f_0_d_bits_size              (io_out_0_d_bits_size              ),
  .io_tl_f_0_d_bits_source            (io_out_0_d_bits_source            ),
  .io_tl_f_0_d_bits_sink              (io_out_0_d_bits_sink              ),
  .io_tl_f_0_d_bits_addr_lo           (io_out_0_d_bits_addr_lo           ),
  .io_tl_f_0_d_bits_data              (io_out_0_d_bits_data              ),
  .io_tl_f_0_d_bits_error             (io_out_0_d_bits_error             ),
  .io_tl_f_0_e_ready                  (io_out_0_e_ready                  ),
  .io_tl_f_0_e_valid                  (io_out_0_e_valid                  ),
  .io_tl_f_0_e_bits_sink              (io_out_0_e_bits_sink              ),


  .io_port_sck       (io_port_sck    ),
  .io_port_dq_0_i    (io_port_dq_0_i ),
  .io_port_dq_0_o    (io_port_dq_0_o ),
  .io_port_dq_0_oe   (io_port_dq_0_oe),
  .io_port_dq_1_i    (io_port_dq_1_i ),
  .io_port_dq_1_o    (io_port_dq_1_o ),
  .io_port_dq_1_oe   (io_port_dq_1_oe),
  .io_port_dq_2_i    (io_port_dq_2_i ),
  .io_port_dq_2_o    (io_port_dq_2_o ),
  .io_port_dq_2_oe   (io_port_dq_2_oe),
  .io_port_dq_3_i    (io_port_dq_3_i ),
  .io_port_dq_3_o    (io_port_dq_3_o ),
  .io_port_dq_3_oe   (io_port_dq_3_oe), 
  .io_port_cs_0      (io_port_cs_0   ),
  .io_tl_i_0_0       (io_tl_i_0_0    ) 

);

endmodule
