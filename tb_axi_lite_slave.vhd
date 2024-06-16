--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:01:15 05/28/2024
-- Design Name:   
-- Module Name:   /home/umar/code/riscv/my_riscv/myrva/tb_axi_lite_slave.vhd
-- Project Name:  myrva
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: axi_lite_slave
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
library commonlib;
use commonlib.types_axi_lite.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_axi_lite_slave IS
END tb_axi_lite_slave;
 
ARCHITECTURE behavior OF tb_axi_lite_slave IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT axi_lite_slave
    PORT(
         i_clk : IN  std_logic;
         i_nrst : IN  std_logic;
         i_slv : IN  aix4_lite_slave_in_type;
         o_slv : OUT  axi4_lite_slave_out_type;
         i_rdy : IN  std_logic;
         i_rdata : IN  std_logic_vector(31 downto 0);
			o_wr_addr	: out std_logic_vector(31 downto 0);
			o_wr_strb	: out std_logic_vector(3 downto 0);
			o_wdata		: out std_logic_vector(31 downto 0);
			o_wr_en		: out std_logic;
			o_rd_addr	: out std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nrst : std_logic := '0';
   signal i_slv : aix4_lite_slave_in_type := aix4_lite_slave_in_none;
   signal i_rdy : std_logic := '0';
   signal i_rdata : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal o_slv : axi4_lite_slave_out_type;
	signal o_wr_addr	: std_logic_vector(31 downto 0);
	signal o_wr_strb	: std_logic_vector(3 downto 0);
	signal o_wr_en		: std_logic;
	signal o_wdata		: std_logic_vector(31 downto 0);
	signal o_rd_addr	: std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: axi_lite_slave PORT MAP (
          i_clk => i_clk,
          i_nrst => i_nrst,
          i_slv => i_slv,
          o_slv => o_slv,
          i_rdy => i_rdy,
          i_rdata => i_rdata,
			 o_wr_addr => o_wr_addr,
			o_wr_strb => o_wr_strb,
			o_wdata => o_wdata,
			o_wr_en => o_wr_en,
			o_rd_addr => o_rd_addr
        );

   -- Clock process definitions
   i_clk_process :process
   begin
		i_clk <= '0';
		wait for i_clk_period/2;
		i_clk <= '1';
		wait for i_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		i_nrst <= '1';
		i_rdy <= '1';
      wait for i_clk_period*10;
		wait for i_clk_period;
		i_slv.S_AXI_AWADDR <= X"DEADBEEF"; -- A0
		i_slv.S_AXI_AWVALID <= '1';
		i_slv. S_AXI_BREADY <= '1';
		wait for i_clk_period;
		i_slv.S_AXI_AWADDR <= X"BEEFDEAD"; --A1
		i_slv.S_AXI_WDATA <=  X"DEADBEEF";--D0
		i_slv.S_AXI_WVALID <= '1';
		wait for i_clk_period;
		i_slv.S_AXI_WDATA <=  X"BEEFDEAD"; --D1
		wait for i_clk_period;
		i_slv. S_AXI_BREADY <= '0';
		i_slv.S_AXI_AWADDR <= X"DEEFBEAD"; --A2
		i_slv.S_AXI_WDATA <=  X"DEEFBEAD"; --D2
		wait for i_clk_period;
		i_slv.S_AXI_AWADDR <= X"FACEFACE"; --A3
		i_slv.S_AXI_WDATA <=  X"FACEFACE"; --D3
		wait for i_clk_period*2;
		i_slv. S_AXI_BREADY <= '1';
		wait for i_clk_period*2;
		i_slv.S_AXI_AWVALID <= '0';
		i_slv.S_AXI_WVALID <= '0';
      -- insert stimulus here 
		--read test;
		i_slv.S_AXI_ARVALID <= '1';
		i_slv.S_AXI_ARADDR <= X"DEADFEED"; --A0
		i_slv.S_AXI_RREADY <= '1';
		wait for i_clk_period;
		i_slv.S_AXI_RREADY <= '0';
		i_slv.S_AXI_ARADDR <= X"FEEDDEAD"; --A1
		wait for i_clk_period;
		i_slv.S_AXI_ARADDR <= X"BEADCEED"; --A2
		wait for i_clk_period;
		i_slv.S_AXI_ARADDR <= X"FACEFACE"; -- A3
		wait for i_clk_period*2;
		i_slv.S_AXI_RREADY <= '1';
		wait for i_clk_period*2;
		i_slv.S_AXI_ARVALID <= '0';
		
		
      wait;
   end process;

END;
