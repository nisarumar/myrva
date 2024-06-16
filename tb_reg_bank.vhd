--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:09:02 05/11/2024
-- Design Name:   
-- Module Name:   /home/umar/code/riscv/my_riscv/myrva/tb_reg_bank.vhd
-- Project Name:  myrva
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: reg_bank
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_reg_bank IS
END tb_reg_bank;
 
ARCHITECTURE behavior OF tb_reg_bank IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT reg_bank
    PORT(
         i_clk : IN  std_logic;
         i_nrst : IN  std_logic;
         i_rs1Addr : IN  std_logic_vector(5 downto 0);
         i_rs2Addr : IN  std_logic_vector(5 downto 0);
         i_rdAddr : IN  std_logic_vector(5 downto 0);
         i_rd : IN  std_logic_vector(64 downto 0);
         i_wr_en : IN  std_logic;
         o_rs1 : OUT  std_logic_vector(64 downto 0);
         o_rs2 : OUT  std_logic_vector(64 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nrst : std_logic := '0';
   signal i_rs1Addr : std_logic_vector(5 downto 0) := (others => '0');
   signal i_rs2Addr : std_logic_vector(5 downto 0) := (others => '0');
   signal i_rdAddr : std_logic_vector(5 downto 0) := (others => '0');
   signal i_rd : std_logic_vector(64 downto 0) := (others => '0');
   signal i_wr_en : std_logic := '0';

 	--Outputs
   signal o_rs1 : std_logic_vector(64 downto 0);
   signal o_rs2 : std_logic_vector(64 downto 0);

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: reg_bank PORT MAP (
          i_clk => i_clk,
          i_nrst => i_nrst,
          i_rs1Addr => i_rs1Addr,
          i_rs2Addr => i_rs2Addr,
          i_rdAddr => i_rdAddr,
          i_rd => i_rd,
          i_wr_en => i_wr_en,
          o_rs1 => o_rs1,
          o_rs2 => o_rs2
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

      wait for i_clk_period*10;
		
		i_nrst <= '1';
		i_rs1Addr <= "000000";
		i_rs2Addr <= "000000";
		i_rdAddr <= "000000";
		i_rd	<= X"0000000000000000"&'0';

      -- insert stimulus here 
		
		wait for i_clk_period;
		i_wr_en <= '1';
		i_rdAddr <= "000011";
		i_rd	<= '0' & X"000000000000DEAD";
		wait for i_clk_period/2;
		i_wr_en <= '0';
		i_rs1Addr <= "000011";
		i_rs2Addr <= "000100";
		wait for i_clk_period/2;

      wait;
   end process;

END;
