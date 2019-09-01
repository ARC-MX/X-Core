// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the 芒鈧揕icense芒鈧??); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an 芒鈧揂S IS芒鈧?? BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 3/18/2017
// Description: Generic memory interface used by the core.
//              The interface can be used in Master or Slave mode.

// Guard statement proposed by "Easier UVM" (doulos)
`ifndef AXI_IF_SV
`define AXI_IF_SV
interface AXI_BUS
    #( //parameter  C_M_AXI_TARGET_SLAVE_BASE_ADDR  = 32'h00000000,
    parameter integer C_M_AXI_BURST_LEN = 16,
    parameter integer C_M_AXI_ID_WIDTH  = 2,
    parameter integer C_M_AXI_ADDR_WIDTH  = 32,
    parameter integer C_M_AXI_DATA_WIDTH  = 32,
    parameter integer C_M_AXI_AWUSER_WIDTH  = 0,
    parameter integer C_M_AXI_ARUSER_WIDTH  = 0,
    parameter integer C_M_AXI_WUSER_WIDTH = 0,
    parameter integer C_M_AXI_RUSER_WIDTH = 0,
    parameter integer C_M_AXI_BUSER_WIDTH = 0
    );
        // Master Interface Write Address ID
	logic [C_M_AXI_ID_WIDTH-1 : 0] aw_id;
	logic [C_M_AXI_ADDR_WIDTH-1 : 0] aw_addr;
	logic [7 : 0] aw_len;
	logic [2 : 0] aw_size;
	logic [1 : 0] aw_burst;
	logic  aw_lock;
    logic [3 : 0] aw_cache;
    logic [2 : 0] aw_prot;
    logic [3 : 0] aw_qos;
    // logic [C_M_AXI_AWUSER_WIDTH-1 : 0] aw_user;
    logic  aw_valid;
    logic  aw_ready;
    
    // Master Interface Write Data.
    logic [C_M_AXI_DATA_WIDTH-1 : 0] w_data;
    logic [C_M_AXI_DATA_WIDTH/8-1 : 0] w_strb;
    logic  w_last;
    // logic [C_M_AXI_WUSER_WIDTH-1 : 0] w_user;
    logic  w_valid;
    logic  w_ready;
    
    
    // Master Interface Write Response.
    logic [C_M_AXI_ID_WIDTH-1 : 0] b_id;
    logic [1 : 0] b_resp;
    // logic [C_M_AXI_BUSER_WIDTH-1 : 0] b_user;
    logic  b_valid;
    logic  b_ready;
    
    
    // Master Interface Read Address.
    logic [C_M_AXI_ID_WIDTH-1 : 0] ar_id;
    logic [C_M_AXI_ADDR_WIDTH-1 : 0] ar_addr;
    logic [7 : 0] ar_len;
    logic [2 : 0] ar_size;
    logic [1 : 0] ar_burst;
    logic  ar_lock;
    logic [3 : 0] ar_cache;
    logic [2 : 0] ar_prot;
    logic [3 : 0] ar_qos;
    // logic [C_M_AXI_ARUSER_WIDTH-1 : 0] ar_user;
    logic  ar_valid;
    logic  ar_ready;
    
    logic [C_M_AXI_ID_WIDTH-1 : 0] r_id;
    // Master Read Data
    logic [C_M_AXI_DATA_WIDTH-1 : 0] r_data;
    logic [1 : 0] r_resp;
    logic  r_last;
    // logic [C_M_AXI_RUSER_WIDTH-1 : 0] r_user;
    logic  r_valid;
    logic  r_ready;

        // super hack in assigning the logic a value
        // we need to keep all interface signals as logic as
        // the simulator does not now if this interface will be used
        // as an active or passive device
        // only helpful thread so far:
        // https://verificationacademy.com/forums/uvm/getting-multiply-driven-warnings-vsim-passive-agent

        // Memory interface configured as master
        // we are also synthesizing this interface
        //`ifndef VERILATOR
        //`ifndef SYNTHESIS
        //clocking mck @(posedge clk);
        //    input   aw_ready, ar_ready, ar_id, r_data, r_user, r_resp, r_last, r_valid, r_id,  w_ready, wb_id, wb_resp, wb_valid, wb_user; 
        //    output  aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, 
    //      aw_qos, aw_user, aw_valid, w_data, w_strb, w_last,  w_user, w_valid, wb_ready,
    //      ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_user, ar_valid, r_ready;
        //endclocking
        //// Memory interface configured as slave
        //clocking sck @(posedge clk);
        //    output  aw_ready, ar_ready, ar_id, r_data, r_user, r_resp, r_last, r_valid, r_id,  w_ready, wb_id, wb_resp, wb_valid, wb_user; 
        //    input   aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, 
    //      aw_qos, aw_user, aw_valid, w_data, w_strb, w_last,  w_user, w_valid, wb_ready,
    //      ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_user, ar_valid, r_ready;
        //endclocking

        /*clocking pck @(posedge clk);
            // default input #1ns output #1ns;
            input  address, data_wdata, data_req, data_we, data_be,
                   data_gnt, data_rvalid, data_rdata;
        endclocking*/
        //`endif
        //`endif


        modport Master (
            `ifndef VERILATOR
            `ifndef SYNTHESIS
            //clocking mck,
            `endif
            `endif
            input   aw_ready, ar_ready, r_data, /*r_user,*/ r_resp, r_last, r_valid, r_id,  w_ready, b_id, b_resp, b_valid, //b_user,
            output  aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, 
          aw_qos,/* aw_user, */aw_valid, w_data, w_strb, w_last,  //w_user,
		  w_valid, b_ready,
          ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, //ar_user, 
		  ar_valid, r_ready
        );
        modport Slave  (
            `ifndef VERILATOR
            `ifndef SYNTHESIS
            //clocking sck,
            `endif
            `endif
            output  aw_ready, ar_ready, r_data, //r_user, 
			r_resp, r_last, r_valid, r_id,  w_ready, b_id, b_resp, b_valid, //b_user,
            input   aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, 
          aw_qos, //aw_user, 
		  aw_valid, w_data, w_strb, w_last,  //w_user, 
		  w_valid, b_ready,
           ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, //ar_user, 
		   ar_valid, r_ready
        );
        // modport Passive (clocking pck);

endinterface
`endif
