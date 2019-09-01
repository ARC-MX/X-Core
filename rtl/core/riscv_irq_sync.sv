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

`timescale 1ns / 1ps

module riscv_irq_sync(

	input  logic 							clk,    // Clock
	input  logic 							rst_n,  // Asynchronous reset active low
	input  logic 							irq_gpio_i,
	input  logic                            irq_timer_i,
	input  logic                            irq_debug_i,
	output logic                            irq_debug_sync_o,
	input 	logic							debug_mode_i,
	
	output logic    	                    irq_o         ,
  	output logic  [ 4:0]                    irq_id_o      ,
  	input  logic                            irq_ack_i     ,
  	input  logic  [ 4:0]                    irq_id_i      ,
  	output logic                            irq_sec_o     ,
	output logic							irq_timer_sync_o,
	output logic							irq_gpio_sync_o  
);

logic 		irq_timer;
logic 		irq_gpio;
logic [4:0] irq_id;
logic       irq_happen;
logic		debug_mode_i_r;

sync_pose timer_sync (
	.clk  (clk),
	.rst_n(rst_n),
	.d    (irq_timer_i),
	.q    (irq_timer)
	);

sync_pose gpio_sync (
	.clk  (clk),
	.rst_n(rst_n),
	.d    (irq_gpio_i),
	.q    (irq_gpio)
	);

sync_pose debug_sync (
	.clk  (clk),
	.rst_n(rst_n),
	.d    (irq_debug_i),
	.q    (irq_debug)
	);	
	
sync     debug_sync_level (
	.clk  (clk),
	.rst_n(rst_n),
	.d    (irq_debug_i),
	.q    (irq_debug_sync_o)
	);

sync     gpio_sync_level (
	.clk  (clk),
	.rst_n(rst_n),
	.d    (irq_gpio_i),
	.q    (irq_gpio_sync_o)
	);
	
	sync     timer_sync_level (
	.clk  (clk),
	.rst_n(rst_n),
	.d    (irq_timer_i),
	.q    (irq_timer_sync_o)
	);
///////////////////////////////////////////////////////
//Interrupt Exception Code Description
//1 		0 			User software interrupt
//1 		1 			Supervisor software interrupt
//1 		2 			Reserved
//1 		3 			Machine software interrupt
//1 		4 			User timer interrupt
//1 		5 			Supervisor timer interrupt
//1 		6 			Reserved
//1 		7 			Machine timer interrupt
//1 		8 			User external interrupt
//1 		9 			Supervisor external interrupt
//1 		10			Reserved
//1 		11			Machine external interrupt
//////////////////////////////////////////////////////
always_comb begin  
 	irq_happen = irq_timer | irq_gpio | irq_debug;
	case(1)
		irq_timer:  irq_id = 5'd7; 
		irq_gpio :  irq_id = 5'd11;

		irq_debug:	irq_id = 5'd12;  //use 12 for debug irq
		default:   irq_id = 5'd7;
	endcase // 1

end

always_ff @(posedge clk or negedge rst_n) begin 
		if(~rst_n) begin
			debug_mode_i_r <= '0;
			
		end else begin
			debug_mode_i_r <= debug_mode_i;
		end
	end
	
	logic debug_mode_i_nege;
	assign debug_mode_i_nege = ~debug_mode_i & debug_mode_i_r;

logic [4:0] irq_id_t;
assign irq_id_o =debug_mode_i_nege ? irq_id : irq_id_t;
always_ff @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		irq_id_t<= '0;
		irq_o   <= '0;
	end else begin
		irq_o   <= irq_happen;
		if(irq_happen | debug_mode_i_nege)
		 	irq_id_t<= irq_id;
	end
end

assign irq_sec_o = 1'b1;


endmodule

module sync_pose 
#(
	parameter int width = 1
)
(
	input                 clk,    // Clock
	input                 rst_n,  // Asynchronous reset active low
	input  [width-1 : 0]  d,
	output [width-1 : 0]  q
);

	logic  [width-1 : 0] q_0;
	logic  [width-1 : 0] q_1;
	logic  [width-1 : 0] q_2;


	always_ff @(posedge clk or negedge rst_n) begin 
		if(~rst_n) begin
			q_0 <= '0;
			q_1 <= '0;
			q_2 <= '0;
		end else begin
			q_0 <= d;
			q_1 <= q_0;
			q_2 <= q_1;
		end
	end

	assign q = ~q_2&q_1;


endmodule

module sync 
#(
	parameter int width = 1
)
(
	input                 clk,    // Clock
	input                 rst_n,  // Asynchronous reset active low
	input  [width-1 : 0]  d,
	output [width-1 : 0]  q
);

	logic  [width-1 : 0] q_0;
	logic  [width-1 : 0] q_1;
	logic  [width-1 : 0] q_2;


	always_ff @(posedge clk or negedge rst_n) begin 
		if(~rst_n) begin
			q_0 <= '0;
			q_1 <= '0;
			q_2 <= '0;
		end else begin
			q_0 <= d;
			q_1 <= q_0;
			q_2 <= q_1;
		end
	end

	assign q = q_2;


endmodule