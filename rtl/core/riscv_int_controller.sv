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
// Engineer:       Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Additional contributions by:                                               //
//                                                                            //
// Design Name:    Interrupt Controller                                       //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Interrupt Controller of the pipelined processor            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////
// Based on PULP RISCV Core by perfxlab
// RSIC V top module 
// 2018/5/26
/////////////////////////////////////////////////

import riscv_defines::*;
import riscv_package::*;

module riscv_int_controller
#(
  parameter RISCV_SECURE = 1
)
(
  input  logic        clk,
  input  logic        rst_n,
  //irq for debug unit
  output logic        irq_debug_o,
  input logic         debug_mode_i,
  input  logic        debug_halt_new_i,
  input  logic        debug_step_i,

  // irq_req for controller
  output logic        irq_req_ctrl_o,
  output logic        irq_sec_ctrl_o,
  output logic  [4:0] irq_id_ctrl_o,
  output logic        irq_enable_ctrl_o,

  // handshake signals to controller
  input  logic        ctrl_ack_i,
  input  logic        ctrl_kill_i,

  // irq req for csr
  output  logic        irq_req_happen_o, 
  output  logic [31:0] irq_req_event_o,  

  // external interrupt lines
  input  logic        irq_i,          // level-triggered interrupt inputs
  input  logic        irq_sec_i,      // interrupt secure bit from EU
  input  logic  [4:0] irq_id_i,       // interrupt id [0,1,....31]

  input  logic        m_IE_i,         // interrupt enable bit from CSR (M mode)
  input  logic        s_IE_i,         // interrupt enable bit from CSR (S mode)
  input  logic        u_IE_i,         // interrupt enable bit from CSR (U mode)
  input  logic [31:0] mip_i,
  input  logic [31:0] mie_i,
  input  logic [31:0] csr_mideleg_i,  // from CSR
  input  PrivLvl_t    current_priv_lvl_i
  
);

  enum logic [1:0] { IDLE, IRQ_PENDING, IRQ_DONE} exc_ctrl_cs, exc_ctrl_ns;

  logic irq_enable_ext;
  logic [4:0] irq_id_q;
  logic irq_sec_q;
////////////////////////////////////////////global enbale///////////////////////////
if(RISCV_SECURE)
  // However, if bit i in mideleg is set, interrupts are considered to be globally enabled if the hart’s current privilege
  // mode equals the delegated privilege mode (S or U) and that mode’s interrupt enable bit
  // (SIE or UIE in mstatus) is set, or if the current privilege mode is less than the delegated privilege mode.
  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
            irq_enable_ext = 1'b0;
    end else begin 
        if(csr_mideleg_i[irq_id_q[4:0]]) begin
          irq_enable_ext = s_IE_i || current_priv_lvl_i == PRIV_LVL_U;
        end else begin
          irq_enable_ext = m_IE_i || current_priv_lvl_i == PRIV_LVL_U || current_priv_lvl_i == PRIV_LVL_S;
        end
    end
  end
else
  assign irq_enable_ext =  m_IE_i;
////////////////////////////////////local enable/////////////////////////////////////

assign irq_req_happen_o = mie_i[irq_id_i] &irq_i;
assign irq_req_event_o  = 32'd1<<irq_id_i;


always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		irq_debug_o <= 1'b0;
	else if(irq_i&(irq_id_i == 5'd12)&~debug_mode_i&~debug_step_i&~debug_halt_new_i) begin
		irq_debug_o <= 1'b1;
	end else if(ctrl_ack_i|ctrl_kill_i)
		irq_debug_o <= 1'b0;
end

/////////////////////////////////output//////////////////////////////////////////////

  assign irq_req_ctrl_o = exc_ctrl_cs == IRQ_PENDING; 
  assign irq_sec_ctrl_o = irq_sec_q;
  assign irq_id_ctrl_o  = irq_id_q;
  assign irq_enable_ctrl_o = irq_enable_ext;

//////////////////////////////interrupt control///////////////////////////////////////

  always_ff @(posedge clk, negedge rst_n)
  begin
    if (rst_n == 1'b0) begin

      irq_id_q    <= '0;
      irq_sec_q   <= 1'b0;
      exc_ctrl_cs <= IDLE;

    end else begin

      unique case (exc_ctrl_cs)

        IDLE:
        begin
          if(~debug_mode_i & irq_enable_ext & (|(mip_i&mie_i))) begin  // global and local enable 
            exc_ctrl_cs <= IRQ_PENDING;
            irq_id_q    <= irq_id_i;
            irq_sec_q   <= irq_sec_i;
          end
        end

        IRQ_PENDING:
        begin
          unique case(1'b1)
            ctrl_ack_i:
              exc_ctrl_cs <= IRQ_DONE;
            ctrl_kill_i:
              exc_ctrl_cs <= IDLE;
            default:
              exc_ctrl_cs <= IRQ_PENDING;
          endcase
        end

        IRQ_DONE:
        begin
          irq_sec_q   <= 1'b0;
          exc_ctrl_cs <= IDLE;
        end
		default:exc_ctrl_cs<=IDLE;
      endcase

    end
  end


`ifndef SYNTHESIS
  // synopsys translate_off
  // evaluate at falling edge to avoid duplicates during glitches
  // Removed this message as it pollutes too much the output and makes tests fail
  //always_ff @(negedge clk)
  //begin
  //  if (rst_n && exc_ctrl_cs == IRQ_DONE)
  //    $display("%t: Entering interrupt service routine. [%m]", $time);
  //end
  // synopsys translate_on
`endif

endmodule
