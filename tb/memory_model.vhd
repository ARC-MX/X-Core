--Memory model
-- file: memory_model.vhd
-- 
-- (c) Copyright 2008 - 2013 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- This is a self-desigined Memory model for AXI FULL and AXI LITE support memories to act as slave
-- for AXI QSPI in Example design
--
------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.all;
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_misc.all;
	
   
entity memory_model is
 generic
  (
    C_FIFO_DEPTH          : integer              := 256;-- allowed 0,16,256.
	C_SPI_MODE            : integer range 0 to 2 := 0; -- used for differentiating
                                                             -- Standard, Dual or Quad mode
                                                             -- in Ports as well as internal
                                                             -- functionality
	C_DATA_WIDTH          : integer               := 8       -- allowed 8,32.
    );
 port
  (
    MODEL_CLK            : in  std_logic;
    MODEL_RESET          : in  std_logic;
	
    -------------------------------
       --*SPI port interface      * --
       -------------------------------
       Core_Clk             : in std_logic;
       Chip_Selectn         : in std_logic;
       -------------------------------
       io0_i          : in std_logic;  -- MOSI signal in standard SPI
       io0_o          : out std_logic;
       io0_t          : out std_logic;
       -------------------------------
       io1_i          : in std_logic;  -- MISO signal in standard SPI
       io1_o          : out std_logic;
       io1_t          : out std_logic;
       -----------------
       -- quad mode pins
       -----------------
       io2_i          : in std_logic;
       io2_o          : out std_logic;
       io2_t          : out std_logic;
       ---------------
       io3_i          : in std_logic;
       io3_o          : out std_logic;
       io3_t          : out std_logic
       ---------------------------------

);
end memory_model;


architecture imp of memory_model is

--------------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
--------------------------------------------------------------------------------------
function log2(x : natural) return integer is
  variable i  : integer := 0; 
  variable val: integer := 1;
begin 
  if x = 0 then return 0;
  else
    for j in 0 to 29 loop -- for loop for XST 
      if val >= x then null; 
      else
        i := i+1;
        val := val*2;
      end if;
    end loop;
  -- Fix per CR520627  XST was ignoring this anyway and printing a  
  -- Warning in SRP file. This will get rid of the warning and not
  -- impact simulation.  
  -- synthesis translate_off
    assert val >= x
      report "Function log2 received argument larger" &
             " than its capability of 2^30. "
      severity failure;
  -- synthesis translate_on
    return i;
  end if;  
end function log2; 



constant RESET_ACTIVE     : std_logic := '0';
constant CMD_WR_EN        : std_logic_vector(7 downto 0):= X"06";
constant CMD_PAGE_PRGM    : std_logic_vector(7 downto 0):= X"02";
constant CMD_STD_READ     : std_logic_vector(7 downto 0):= X"03";
constant CMD_DUAL_READ    : std_logic_vector(7 downto 0):= X"3B";
constant CMD_QUAD_READ    : std_logic_vector(7 downto 0):= X"6B";
constant CMD_STATUS_WRITE    : std_logic_vector(7 downto 0):= X"01";
constant ADDR_WIDTH  : INTEGER   := log2(C_FIFO_DEPTH);


signal rising                           : std_logic := '0';
signal falling                          : std_logic := '0';
signal SCK_D                          : std_logic := '0';

signal Serial_Dout_0                          : std_logic := '0';
signal Serial_Dout_1                          : std_logic := '0';
signal Serial_Dout_2                          : std_logic := '0';
signal Serial_Dout_3                          : std_logic := '0';
signal Serial_Dout_1_std                      : std_logic := '0';

signal FIFO_WR_EN                            : std_logic := '0';
signal FIFO_RD_EN                            : std_logic := '0';
signal dummy_wait_d1                            : std_logic := '0';
signal dummy_wait_d2                            : std_logic := '0';
signal dummy_wait_d3                            : std_logic := '0';
signal dummy_wait_d4                            : std_logic := '0';
signal dummy_wait                            : std_logic := '0';
signal dummy_wait_std                            : std_logic := '0';

signal FIFO_RD_EN_d                          : std_logic := '0';
signal Count_Pulse                          : std_logic := '0';
signal Count_Pulse_d                          : std_logic := '0';
signal signal_WE                            : std_logic := '0';
signal Count_data_EN                          : std_logic := '0';

signal Read_Addr_Int,Write_Addr_Int,Count_data_width_Int   : INTEGER := 0;

signal Cnt_8_Clk                            : std_logic_vector(2 downto 0):=(others => '1');
signal Addr_Cnt                             : std_logic_vector(2 downto 0):=(others => '1');
signal Read_Addr                            : std_logic_vector(3 downto 0):=(others => '1');
signal Write_Addr                           : std_logic_vector(3 downto 0):=(others => '1');


signal Instruction_Buffer                 : std_logic_vector(7 downto 0):=(others => '0');
signal Instruction_Buffer_d                 : std_logic_vector(7 downto 0):=(others => '0');


signal Rx_Shift_Reg                       : std_logic_vector
                                                            (0 to C_DATA_WIDTH-1):=(others => '0');
signal Input_Buffer                       : std_logic_vector
                                                            (0 to C_DATA_WIDTH-1):=(others => '0');	
signal FIFO_Input                         : std_logic_vector
                                                            (0 to C_DATA_WIDTH-1):=(others => '0');	
signal Data_To_Rx_FIFO                    : std_logic_vector
                                                            (0 to C_DATA_WIDTH-1):=(others => '0');	
signal Data_From_Rx_FIFO                  : std_logic_vector
                                                            (0 to C_DATA_WIDTH-1):=(others => '0');	
signal Transmit_Data                      : std_logic_vector
                                                            (0 to C_DATA_WIDTH-1):=(others => '0');	

signal Transmit_Data_1                   : std_logic_vector(0 to C_DATA_WIDTH-1):=(others => '1');
signal Transmit_Data_2                   : std_logic_vector(0 to 31):=X"FFFFFFFF";



															
type STATE_TYPE is
                  (IDLE,       -- decode command can be combined here later
                   INSTRUCTION_DECODE,
                   WAIT_ADDRESS_READ,
				   PAGE_PROGRAM,
				   WAIT_DUMMY_CYCLES,
                   READ_DATA 
                   );
TYPE mem_array IS ARRAY (15 DOWNTO 0) OF STD_LOGIC_VECTOR(C_DATA_WIDTH - 1 DOWNTO 0);
SIGNAL ram : mem_array;
signal spi_cntrl_ps: STATE_TYPE;
signal spi_cntrl_ns: STATE_TYPE;



begin

Rising_falling_process: process(MODEL_CLK)is
-----
begin
-----
    if(MODEL_CLK'event and MODEL_CLK = '1') then
        if(MODEL_RESET = RESET_ACTIVE) then
            SCK_D  <= '0';
        else
            SCK_D <= Core_Clk;
        end if;
    end if;
end process Rising_falling_process;

rising <= Core_Clk and (not(SCK_D));
falling <= SCK_D and (not(Core_Clk));

PS_TO_NS_PROCESS: process(MODEL_CLK)is
-----
begin
-----
    if(MODEL_CLK'event and MODEL_CLK = '1') then
        if(MODEL_RESET = RESET_ACTIVE) then
            spi_cntrl_ps <= IDLE;
        else
            spi_cntrl_ps <= spi_cntrl_ns;
        end if;
    end if;
end process PS_TO_NS_PROCESS;

COUNTER_8_Cycles_Pos_PROCESS : process(MODEL_CLK)is
begin
-----
      if(MODEL_CLK'event and MODEL_CLK = '1') then --1
          if(MODEL_RESET = RESET_ACTIVE) then
              Cnt_8_Clk <= (others => '1');
          elsif (Chip_Selectn = '1') then
              Cnt_8_Clk <= (others => '1');
              elsif(rising = '1') then
              Cnt_8_Clk <= Cnt_8_Clk + 1;
              end if;
        end if;
end process COUNTER_8_Cycles_Pos_PROCESS;

Count_Pulse <= Cnt_8_Clk(0) and Cnt_8_Clk(1) and Cnt_8_Clk(2);
--and_reduce(Cnt_8_Clk);

Count_d_PROCESS : process(MODEL_CLK)is
begin
-----
      if(MODEL_CLK'event and MODEL_CLK = '1') then --1
          if(MODEL_RESET = RESET_ACTIVE) then
			  Count_Pulse_d <= '0';
          elsif (Chip_Selectn = '1') then
			  Count_Pulse_d <= '0';
          else
			  Count_Pulse_d <= Count_Pulse;
         end if;
        end if;
end process Count_d_PROCESS;


Address_Count_PROCESS : process(MODEL_CLK)is
begin
-----
      if(MODEL_CLK'event and MODEL_CLK = '1') then --1
          if(MODEL_RESET = RESET_ACTIVE) then
              Addr_Cnt <= (others => '1');
         -- elsif ((Count_Pulse = '1') and (spi_cntrl_ps = WAIT_ADDRESS_READ))then
          elsif (spi_cntrl_ps = WAIT_ADDRESS_READ)then
		      if ((Count_Pulse = '1') and (falling = '1')) then
                  Addr_Cnt <= Addr_Cnt + 1;
			  end if;
		  else
              Addr_Cnt <= (others => '1');
              end if;
		  
        end if;
end process Address_Count_PROCESS;



CAPTURE_INPUT_DATA : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
          if (MODEL_RESET = RESET_ACTIVE)then
                  Rx_Shift_Reg <= (others => '0');
          elsif( (Chip_Selectn = '0' ) and (rising = '1'))then
                  Rx_Shift_Reg <= Rx_Shift_Reg
                                         (1 to (C_DATA_WIDTH-1)) & io0_i ; --MISO_I
          else
                  Rx_Shift_Reg <= Rx_Shift_Reg;
          end if;
      end if;
  end process CAPTURE_INPUT_DATA;

CAPTURE_INPUT_BUFFER : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
          if (MODEL_RESET = RESET_ACTIVE)then
                  Input_Buffer <= (others => '0');
          elsif(( Count_Pulse = '1' ) and (Count_Pulse_d = '0'))then
                  Input_Buffer       <= Rx_Shift_Reg;
				  Instruction_Buffer <= Rx_Shift_Reg((C_DATA_WIDTH-8) to (C_DATA_WIDTH-1));
          else
             Input_Buffer       <= Input_Buffer;
			 Instruction_Buffer <= Instruction_Buffer;
          end if;
      end if;
  end process CAPTURE_INPUT_BUFFER;
  
  
SPI_STATE_MACHINE_P: process(MODEL_CLK)
begin
     --if (Chip_Selectn = '0') then
     if(MODEL_CLK'event and MODEL_CLK = '1') then   --1

     --------------------------
     case spi_cntrl_ns is
     --------------------------
     when IDLE               => if(Chip_Selectn = '0') then
                                    spi_cntrl_ns <= INSTRUCTION_DECODE;
                                else
                                    spi_cntrl_ns <= IDLE;
                                end if;
								  io0_t <= '1';
								  io1_t <= '0';
								  io2_t <= '0';
								  io3_t <= '0';
								
                                -------------------------------------
     when INSTRUCTION_DECODE => if(Chip_Selectn = '0') then
	                                if (Count_Pulse_d = '1') then
                                 	  if (Instruction_Buffer = CMD_WR_EN) then
	                                      signal_WE <= '1';
										  spi_cntrl_ns <= INSTRUCTION_DECODE; 
									  elsif ((Instruction_Buffer = CMD_PAGE_PRGM) and (signal_WE = '1'))then
								          Instruction_Buffer_d <= Instruction_Buffer; 
									      spi_cntrl_ns <= WAIT_ADDRESS_READ;
										  signal_WE <= signal_WE;
									  elsif((Instruction_Buffer = CMD_STD_READ) or (Instruction_Buffer = CMD_DUAL_READ) or (Instruction_Buffer = CMD_QUAD_READ))then
								          Instruction_Buffer_d <= Instruction_Buffer; 
									      spi_cntrl_ns <= WAIT_ADDRESS_READ;
	                                      signal_WE <= '0';
									  else
                                          spi_cntrl_ns <= INSTRUCTION_DECODE;
	                                      Instruction_Buffer_d <= X"00";
										  signal_WE <= signal_WE;
                                      end if;
									else 
                                       spi_cntrl_ns <= INSTRUCTION_DECODE;
	                                   Instruction_Buffer_d <= X"00";
										  signal_WE <= signal_WE;
	                                end if;
								else
                                       spi_cntrl_ns <= IDLE;
	                                   Instruction_Buffer_d <= X"00";
										  signal_WE <= signal_WE;
							    end if;
								  io0_t <= '1';
								  io1_t <= '0';
								  io2_t <= '0';
								  io3_t <= '0';

                                -------------------------------------
     when WAIT_ADDRESS_READ =>   if((Addr_Cnt = "010") and (Count_Pulse = '1'))then
	                                if (Instruction_Buffer_d = CMD_PAGE_PRGM) then
                                       spi_cntrl_ns <= PAGE_PROGRAM;
									elsif (Instruction_Buffer_d = CMD_STD_READ) then
									   spi_cntrl_ns <= READ_DATA;
									elsif ((Instruction_Buffer_d = CMD_DUAL_READ) or (Instruction_Buffer_d = CMD_QUAD_READ))then
									--elsif ((Instruction_Buffer_d = CMD_DUAL_READ || CMD_QUAD_READ))then
									   spi_cntrl_ns <= WAIT_DUMMY_CYCLES;
									else
                                       spi_cntrl_ns <= IDLE;
	                                   --signal_WE <= '0';
                                    end if;
                                  else  
                                       spi_cntrl_ns <= WAIT_ADDRESS_READ;
                                 end if;
								  io0_t <= '1';
								  io1_t <= '0';
								  io2_t <= '0';
								  io3_t <= '0';
     when PAGE_PROGRAM =>   if (Chip_Selectn = '1')then
									   spi_cntrl_ns <= IDLE;
							else 
							           spi_cntrl_ns <= PAGE_PROGRAM;
							end if;
								  io0_t <= '1';
								  io1_t <= '0';
								  io2_t <= '0';
								  io3_t <= '0';
     when WAIT_DUMMY_CYCLES =>   
                              if (Count_Pulse = '1')then
									   spi_cntrl_ns <= READ_DATA;
							  else 
							           spi_cntrl_ns <= WAIT_DUMMY_CYCLES;
							  end if;	
								  io0_t <= '0';
								  io1_t <= '0';
								  io2_t <= '0';
								  io3_t <= '0';

     when READ_DATA =>    if (Chip_Selectn = '1')then
									   spi_cntrl_ns <= IDLE;
							else 
							           spi_cntrl_ns <= READ_DATA;
							end if;   
								  io0_t <= '0';
								  io1_t <= '0';
								  io2_t <= '0';
								  io3_t <= '0';
                                -------------------------------------

     when others             => spi_cntrl_ns <= IDLE;
								  io0_t <= '1';
								  io1_t <= '0';
								  io2_t <= '0';
								  io3_t <= '0';
                                -------------------------------------
     end case;
    end if;
	--else
	 -- spi_cntrl_ns <= IDLE;
	--end if;  
     --------------------------
end process SPI_STATE_MACHINE_P;

  
FIFO_WRITE_PROCESS  : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2 --changed from 0
          if (MODEL_RESET = RESET_ACTIVE) then
                  FIFO_Input       <= (others => '0');
                  FIFO_WR_EN       <= '0';
				  Data_To_Rx_FIFO  <= (others => '0'); 
				  Write_Addr       <= (others => '1');
		    elsif ((Chip_Selectn = '1') and (rising = '1'))	then
                  FIFO_Input       <= (others => '0');
                  FIFO_WR_EN       <= '0';
				  Data_To_Rx_FIFO  <= (others => '0'); 
				  Write_Addr       <= (others => '1');
          elsif(( Cnt_8_Clk = "110" ) and (spi_cntrl_ns = PAGE_PROGRAM)  and (rising = '1'))then
                  FIFO_Input       <= Rx_Shift_Reg;
                  FIFO_WR_EN       <= '1';
                  Write_Addr       <= Write_Addr + 1;
          else
                  FIFO_Input       <= FIFO_Input;
                  FIFO_WR_EN       <= '0';
				   
          end if;
      end if;
  end process FIFO_WRITE_PROCESS;

  FIFO_WRITE_data_PROCESS  : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
          if (MODEL_RESET = RESET_ACTIVE) then
				  ram              <= (others => (others => '0'));
          elsif(FIFO_WR_EN = '1') then
				  ram(Write_Addr_Int)  <= Rx_Shift_Reg; 
          end if;
      end if;
  end process FIFO_WRITE_data_PROCESS;

  
  Write_Addr_Int <= CONV_INTEGER(Write_Addr);
  
Quad_Read_GENERATE : if (C_SPI_MODE = 2) generate

FIFO_READ_EN_PROCESS : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
          if ((MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1'))then
                  FIFO_RD_EN       <= '0';
          elsif((spi_cntrl_ns = READ_DATA) or (spi_cntrl_ns =WAIT_DUMMY_CYCLES)) then
          if (falling = '1') then
                        FIFO_RD_EN <= Cnt_8_Clk(0) ;
         end if;
         end if;
      end if;
  end process FIFO_READ_EN_PROCESS;
 
READ_PROCESS : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
          if ((MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1'))then
                  Read_Addr       <= (others => '1');
				  Data_From_Rx_FIFO       <= (others => '0');
          elsif ((FIFO_RD_EN = '1') and (falling = '1')) then
		          Read_Addr       <= Read_Addr + 1;
		          Data_From_Rx_FIFO  <= ram(Read_Addr_Int) ;
		  end if;
      end if;
  end process READ_PROCESS;
  
 Read_Addr_Int <= CONV_INTEGER(Read_Addr);
  
REGISTER_SHIFT_PROCESS : process(MODEL_CLK)is
begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then 
	 if (MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1')then
	            Transmit_Data <= (others => '0');
          elsif ((FIFO_RD_EN = '1') and (falling = '1'))then
                  Transmit_Data       <= Data_From_Rx_FIFO;
          elsif (falling = '1')then
                  Transmit_Data <= Transmit_Data(4 to (C_DATA_WIDTH-1)) & "0000";
	 
	end if;
  end if;
  end process REGISTER_SHIFT_PROCESS;
end generate Quad_Read_GENERATE ;
   

Dual_Read_GENERATE : if (C_SPI_MODE = 1) generate
FIFO_READ_EN_PROCESS : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
          if ((MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1'))then
                  FIFO_RD_EN       <= '0';
          elsif((spi_cntrl_ns = READ_DATA) or (spi_cntrl_ns =WAIT_DUMMY_CYCLES) or (dummy_wait_d4 = '1'))then
          if (falling = '1') then
                  FIFO_RD_EN <= Cnt_8_Clk(0) and (not(Cnt_8_Clk(1)));--not(Cnt_8_Clk(0) or Cnt_8_Clk(1));
         end if;
         end if;
      end if;
  end process FIFO_READ_EN_PROCESS;
 

 
READ_PROCESS : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
          if ((MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1'))then
                  Read_Addr       <= (others => '1');
				  Data_From_Rx_FIFO       <= (others => '0');
          elsif ((FIFO_RD_EN = '1') and (falling = '1')) then
		          Read_Addr       <= Read_Addr + 1;
		          Data_From_Rx_FIFO  <= ram(Read_Addr_Int) ;
		  end if;
      end if;
  end process READ_PROCESS;
  
 Read_Addr_Int <= CONV_INTEGER(Read_Addr);
  
REGISTER_SHIFT_PROCESS : process(MODEL_CLK)is
begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then 
	 if (MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1')then
	            Transmit_Data <= (others => '0');
          elsif ((FIFO_RD_EN = '1') and (falling = '1'))then
                  Transmit_Data       <= Data_From_Rx_FIFO;
          elsif (falling = '1') then
                  Transmit_Data <= Transmit_Data(2 to (C_DATA_WIDTH-1)) & "00";
	end if;
  end if;
  end process REGISTER_SHIFT_PROCESS;
  
  
end generate Dual_Read_GENERATE ;
   
   
STD_Read_Process : if (C_SPI_MODE = 0) generate
FIFO_READ_EN_PROCESS : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
          if ((MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1'))then
                  FIFO_RD_EN       <= '0';
          elsif ((spi_cntrl_ns = READ_DATA) or (dummy_wait_std = '1')) then
            if (falling = '1') then
                  FIFO_RD_EN <= Cnt_8_Clk(2) and (not(Cnt_8_Clk(1))) and Cnt_8_Clk(0) ;
           end if;
         end if;
      end if;
  end process FIFO_READ_EN_PROCESS;
 

 
READ_PROCESS : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then 
          if ((MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1'))then
                  Read_Addr       <= (others => '1');
				  Data_From_Rx_FIFO       <= (others => '0');
          elsif ((FIFO_RD_EN = '1') and (falling = '1')) then
		          Read_Addr       <= Read_Addr + 1;
		          Data_From_Rx_FIFO  <= ram(Read_Addr_Int) ;
		  end if;
      end if;
  end process READ_PROCESS;
  
 Read_Addr_Int <= CONV_INTEGER(Read_Addr);
  
REGISTER_SHIFT_PROCESS : process(MODEL_CLK)is
begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then 
	 if (MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1')then
	            Transmit_Data <= (others => '0');
          elsif ((FIFO_RD_EN = '1') and (falling = '1'))then
                  Transmit_Data       <= Data_From_Rx_FIFO;
          elsif (falling = '1') then 
                   Transmit_Data <= Transmit_Data(1 to (C_DATA_WIDTH-1)) & '0';
	end if;
   end if;
  end process REGISTER_SHIFT_PROCESS;
end generate STD_Read_Process ;

   
FIFO_READ_PROCESS: process(MODEL_CLK) is
  -----
  begin
  -----
      if(MODEL_CLK'event and MODEL_CLK = '1') then
          if((MODEL_RESET = RESET_ACTIVE)or (Chip_Selectn = '1')) then
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          elsif (falling = '1') then 
              --if(spi_cntrl_ns = READ_DATA)then
                      --Shift_Reg   <= Transmit_Data;-- loading trasmit data in SR
                      if(C_SPI_MODE = 0) then    -- standard mode
                        Serial_Dout_1 <= Transmit_Data(0);
                      elsif(C_SPI_MODE = 1) then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(C_SPI_MODE = 2) then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
			 -- end if;
		  end if;
	  end if;
end process FIFO_READ_PROCESS;


					  
  REGISTER_SHIFT_16_PROCESS : process(MODEL_CLK)is
  begin
    if(MODEL_CLK'event and MODEL_CLK = '1') then 
	 if (MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1')then
	               Transmit_Data_1 <= Transmit_Data_2(0 to (C_DATA_WIDTH-1));
          elsif (falling = '1') then 
                   Transmit_Data_1 <= Transmit_Data_1(1 to (C_DATA_WIDTH-1)) & '0';
                   Serial_Dout_1_std <= Transmit_Data_1(0);
	end if;
   end if;
  end process REGISTER_SHIFT_16_PROCESS;

	
	io0_o <= Serial_Dout_0;
	io1_o <= Serial_Dout_1_std when ((C_DATA_WIDTH = 16) or (C_DATA_WIDTH = 32) or (C_FIFO_DEPTH = 0))  ELSE
                  Serial_Dout_1; 
	io2_o <= Serial_Dout_2;
	io3_o <= Serial_Dout_3;

 dummy_wait <= '1' when ((spi_cntrl_ns = WAIT_ADDRESS_READ) and  (signal_WE = '0') and (Addr_Cnt = "10"))  ELSE
                  '0'; 
	
	
	
  DUMMY_WAIT_PROCESS : process(MODEL_CLK)is
    begin
     if(MODEL_CLK'event and MODEL_CLK = '1') then --SPIXfer_done_int_pulse_d2
           if ((MODEL_RESET = RESET_ACTIVE) or (Chip_Selectn = '1'))then
                    dummy_wait_d1       <= '0';
                    dummy_wait_d2       <= '0';
                    dummy_wait_d3       <= '0';
                    dummy_wait_d4       <= '0';
          elsif (falling = '1') then 
                    dummy_wait_d1       <= dummy_wait;
                    dummy_wait_d2       <= dummy_wait_d1;
                    dummy_wait_d3       <= dummy_wait_d2;
                    dummy_wait_d4       <= dummy_wait_d3;
           end if;
        end if;
    end process DUMMY_WAIT_PROCESS;
	
end imp;
