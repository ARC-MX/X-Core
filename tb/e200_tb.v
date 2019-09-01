
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/04/04 17:18:09
// Design Name: 
// Module Name: e200_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module e200_tb(

    );
    
     reg clk;
     reg rst_n; 
   
     wire led_0;
     wire led_1;
     wire led_2;
     wire led_3;
   
     // RGB LEDs, 3 pins each
      wire led0_r;
      wire led0_g;
      wire led0_b;
      wire led1_r;
      wire led1_g;
      wire led1_b;
      wire led2_r;
      wire led2_g;
      wire led2_b;
      wire ck_miso;
      wire ck_mosi;
      wire ck_ss;
      wire ck_sck;
      	wire  jtag_tdi, jtag_tdo, jtag_tms;
      wire qspi_cs;
      wire qspi_sck;
      wire [3:0] qspi_dq;
      wire btn_2;
      reg btn_1_r;
	  wire btn_1 = btn_1_r;
	  
      reg btn_reg;
    assign btn_2 = btn_reg;

   system u_system(
        .CLK100MHZ(clk),
        .ck_rst(rst_n),
      
        .led_0(led_0),
        .led_1(led_1),
        .led_2(led_2),
        .led_3(led_3),
        
          // RGB LEDs, 3 pins each
         .led0_r(led_r),
         .led0_g(led0_g),
         .led0_b(led0_b),
         .led1_r(led1_r),
         .led1_g(led1_g),
         .led1_b(led1_b),
         .led2_r(led2_r),
         .led2_g(led2_g),
         .led2_b(led2_b),
         
         .ck_miso(ck_miso),
         .ck_mosi(ck_misi),
         .ck_ss(ck_ss),
         .ck_sck(ck_sck),
          .jtag_tdo(jtag_tdo),
         .jtag_clk(jtag_clk),
         .jtag_tdi(jtag_tdi),
         .jtag_tms(jtag_tms),
         .qspi_cs(qspi_cs),
         .qspi_sck(qspi_sck),
         .qspi_dq(qspi_dq),
         .btn_2(btn_2),
         .btn_1(btn_1)

         

   );
   
   
	wrdata debug_wrdata(  
        .reset       (rst_n1),
        .clk         (jtag_clk),
        .tdi         (jtag_tdi),
        .tdo         (jtag_tdo),
        .tms         (jtag_tms),
        .ram_data_out( )
        );
	
 initial begin
            clk = 1;
            rst_n =0;
            btn_reg = 1;
           btn_1_r = 1;
            #801 rst_n = 1;
            // #300000000 btn_reg = 0;
            // #5000 btn_reg = 1;
            
			// #1000000
			// btn_reg = 0;
			// #5000 btn_reg = 1;
            // #300000000 
			// btn_reg = 0;
			// #5000 btn_reg = 1;
			
			#1000000000 $stop;
                                    
                        
        
 end
        
 always # 10 clk = ~clk;   
 
    
endmodule
