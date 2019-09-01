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
//  The module for debug RAM program
//
// ====================================================================                                                               
                                                                         


module sirv_debug_ram(
  input  clk,
  input  rst_n,
  input  ram_cs,
  input  ram_rd,
  input  [ 3-1:0] ram_addr, 
  input  [32-1:0] ram_wdat,  
  output [32-1:0] ram_dout ,
  input    			dbg_irq_r		     ,
  input    			dbg_mode		     ,
  input    			dbg_halt_r		     ,
  input    			dbg_step_r		     ,
  input    			dbg_ebreakm_r	     ,
  input    			dbg_ebreaku_r	     ,
  input    			dbg_stopcycle	     ,
  input    			dbg_ebreaks_r	     ,
  input    			o_dbg_irq		     
  );
        
  wire [31:0] debug_ram_r [0:6]; 
  wire [6:0]  ram_wen;

// ila_ram your_instance_name (
//	 .clk(clk), // input wire clk


//	 .probe0(debug_ram_r[0]), // input wire [31:0]  probe0  
//	 .probe1(debug_ram_r[1]), // input wire [31:0]  probe1 
//	 .probe2(debug_ram_r[2]), // input wire [31:0]  probe2 
//	 .probe3(debug_ram_r[3]), // input wire [31:0]  probe3 
//	 .probe4(debug_ram_r[4]), // input wire [31:0]  probe4 
//	 .probe5(debug_ram_r[5]), // input wire [31:0]  probe5 
//	 .probe6(debug_ram_r[6]) // input wire [31:0]  probe6
// );


// ila_debug u_ila_debug (
		// .clk			(clk					), // input wire clk


		// .probe0			(dbg_irq_r				), // input wire [0:0]  probe0  
		// .probe1			(dbg_mode				), // input wire [0:0]  probe1 
		// .probe2			(dbg_halt_r				), // input wire [0:0]  probe2 
		// .probe3			(dbg_step_r				), // input wire [0:0]  probe3 
		// .probe4			(dbg_ebreakm_r			), // input wire [0:0]  probe4 
		// .probe5			(dbg_ebreaku_r			), // input wire [0:0]  probe5 
		// .probe6			(dbg_stopcycle			), // input wire [0:0]  probe6 
		// .probe7			(dbg_ebreaks_r			), // input wire [0:0]  probe7 
		// .probe8			(o_dbg_irq				), // input wire [0:0]  probe8
		// .probe9			(debug_ram_r[0]			), // input wire [0:0]  probe8
		// .probe10		(debug_ram_r[1]			), // input wire [0:0]  probe8
		// .probe11		(debug_ram_r[2]			), // input wire [0:0]  probe8
		// .probe12		(debug_ram_r[3]			), // input wire [0:0]  probe8
		// .probe13		(debug_ram_r[4]			), // input wire [0:0]  probe8
		// .probe14		(debug_ram_r[5]			), // input wire [0:0]  probe8
		// .probe15		(debug_ram_r[6]			) // input wire [0:0]  probe8
		
	// );
  assign ram_dout = debug_ram_r[ram_addr]; 

  genvar i;
  generate //{
  
      for (i=0; i<7; i=i+1) begin:debug_ram_gen//{
  
            assign ram_wen[i] = ram_cs & (~ram_rd) & (ram_addr == i) ;
            sirv_gnrl_dfflr #(32) ram_dfflr (ram_wen[i], ram_wdat, debug_ram_r[i], clk, rst_n);
  
      end//}
  endgenerate//}

endmodule

