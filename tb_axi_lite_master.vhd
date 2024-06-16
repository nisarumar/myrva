--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:01:31 06/04/2024
-- Design Name:   
-- Module Name:   /home/umar/code/riscv/my_riscv/myrva/tb_axi_lite_master.vhd
-- Project Name:  myrva
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: axi_lite_master
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
USE ieee.numeric_std.ALL;
 
ENTITY tb_axi_lite_master IS
END tb_axi_lite_master;
 
ARCHITECTURE behavior OF tb_axi_lite_master IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT axi_lite_master
    PORT(
         i_clk : IN  std_logic;
         i_nrst : IN  std_logic;
         i_mst : IN  axi4_lite_master_in_type;
         o_mst : OUT  axi4_lite_master_out_type;
         o_req_rdy : OUT  std_logic;
         o_data_valid : OUT  std_logic;
         o_mem_data : OUT  std_logic_vector(31 downto 0);
         i_valid : IN  std_logic;
         i_we : IN  std_logic;
         i_mem_addr : IN  std_logic_vector(31 downto 0);
         i_mem_data : IN  std_logic_vector(31 downto 0);
         i_mem_strb : IN  std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nrst : std_logic := '0';
   signal i_mst : axi4_lite_master_in_type := axi4_lite_master_in_none;
   signal i_valid : std_logic := '0';
   signal i_we : std_logic := '0';
   signal i_mem_addr : std_logic_vector(31 downto 0) := (others => '0');
   signal i_mem_data : std_logic_vector(31 downto 0) := (others => '0');
   signal i_mem_strb : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal o_mst : axi4_lite_master_out_type;
   signal o_req_rdy : std_logic;
   signal o_data_valid : std_logic;
   signal o_mem_data : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: axi_lite_master PORT MAP (
          i_clk => i_clk,
          i_nrst => i_nrst,
          i_mst => i_mst,
          o_mst => o_mst,
          o_req_rdy => o_req_rdy,
          o_data_valid => o_data_valid,
          o_mem_data => o_mem_data,
          i_valid => i_valid,
          i_we => i_we,
          i_mem_addr => i_mem_addr,
          i_mem_data => i_mem_data,
          i_mem_strb => i_mem_strb
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

      wait for i_clk_period*10;
		
		i_mem_addr <= X"DEADBEEF";
		i_valid <= '1';
		
		for i in 0 to 5 loop
		wait for i_clk_period;
		i_mst.M_AXI_ARREADY <= '1';
		i_mem_addr <= X"FACECAF" & std_logic_vector(to_unsigned(i,4));
		end loop;
		
		wait for i_clk_period;
		i_valid <= '0';
		wait for i_clk_period;
		
		i_mst.M_AXI_ARREADY <= '0';
		
		wait for i_clk_period;
		i_mst.M_AXI_RVALID <= '1';
		wait for i_clk_period*5;
		i_valid <= '1';
		i_we <= '1';
		wait for i_clk_period*2;
		i_mst.M_AXI_RVALID <= '0';
		i_mst.M_AXI_AWREADY <= '1';
      -- insert stimulus here 

      wait;
   end process;

END;
