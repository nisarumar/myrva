--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:09:29 05/23/2024
-- Design Name:   
-- Module Name:   /home/umar/code/riscv/my_riscv/myrva/tb_mem.vhd
-- Project Name:  myrva
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mem
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
use commonlib.cfg_data.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_mem IS
END tb_mem;
 
ARCHITECTURE behavior OF tb_mem IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mem
    PORT(
         i_clk : IN  std_logic;
         i_nrst : IN  std_logic;
         i_memop_load : IN  std_logic;
         i_memop_store : IN  std_logic;
         i_memop_size : IN  std_logic_vector(1 downto 0);
         i_memop_addr : IN  std_logic_vector(31 downto 0);
         i_memop_rd : IN  std_logic_vector(5 downto 0);
         i_memop_wdata : IN  std_logic_vector(31 downto 0);
         i_memop_sign_ext : IN  std_logic;
         i_e_valid : IN  std_logic;
         o_mem_rdy : OUT  std_logic;
         o_wr_en : OUT  std_logic;
         o_rd_addr : OUT  std_logic_vector(5 downto 0);
         o_rd : OUT  std_logic_vector(32 downto 0);
         i_wrb_rdy : IN  std_logic;
         i_mem_req_rdy : IN  std_logic;
         i_mem_data_valid : IN  std_logic;
         i_mem_data_addr : IN  std_logic_vector(31 downto 0);
         i_mem_data : IN  std_logic_vector(63 downto 0);
         o_mem_valid : OUT  std_logic;
         o_mem_write : OUT  std_logic;
         o_mem_addr : OUT  std_logic_vector(31 downto 0);
         o_mem_data : OUT  std_logic_vector(63 downto 0);
         o_mem_strb : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nrst : std_logic := '0';
   signal i_memop_load : std_logic := '0';
   signal i_memop_store : std_logic := '0';
   signal i_memop_size : std_logic_vector(1 downto 0) := (others => '0');
   signal i_memop_addr : std_logic_vector(31 downto 0) := (others => '0');
   signal i_memop_rd : std_logic_vector(5 downto 0) := (others => '0');
   signal i_memop_wdata : std_logic_vector(31 downto 0) := (others => '0');
   signal i_memop_sign_ext : std_logic := '0';
   signal i_e_valid : std_logic := '0';
   signal i_wrb_rdy : std_logic := '0';
   signal i_mem_req_rdy : std_logic := '0';
   signal i_mem_data_valid : std_logic := '0';
   signal i_mem_data_addr : std_logic_vector(31 downto 0) := (others => '0');
   signal i_mem_data : std_logic_vector(63 downto 0) := (others => '0');

 	--Outputs
   signal o_mem_rdy : std_logic;
   signal o_wr_en : std_logic;
   signal o_rd_addr : std_logic_vector(5 downto 0);
   signal o_rd : std_logic_vector(32 downto 0);
   signal o_mem_valid : std_logic;
   signal o_mem_write : std_logic;
   signal o_mem_addr : std_logic_vector(31 downto 0);
   signal o_mem_data : std_logic_vector(63 downto 0);
   signal o_mem_strb : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mem PORT MAP (
          i_clk => i_clk,
          i_nrst => i_nrst,
          i_memop_load => i_memop_load,
          i_memop_store => i_memop_store,
          i_memop_size => i_memop_size,
          i_memop_addr => i_memop_addr,
          i_memop_rd => i_memop_rd,
          i_memop_wdata => i_memop_wdata,
          i_memop_sign_ext => i_memop_sign_ext,
          i_e_valid => i_e_valid,
          o_mem_rdy => o_mem_rdy,
          o_wr_en => o_wr_en,
          o_rd_addr => o_rd_addr,
          o_rd => o_rd,
          i_wrb_rdy => i_wrb_rdy,
          i_mem_req_rdy => i_mem_req_rdy,
          i_mem_data_valid => i_mem_data_valid,
          i_mem_data_addr => i_mem_data_addr,
          i_mem_data => i_mem_data,
          o_mem_valid => o_mem_valid,
          o_mem_write => o_mem_write,
          o_mem_addr => o_mem_addr,
          o_mem_data => o_mem_data,
          o_mem_strb => o_mem_strb
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

check_strobe : for i in 0 to 8 loop
		i_memop_load <= '1';
		i_memop_size <= MEMOP_4B;
		--i_mem_data_valid <= '0';
		i_e_valid <= '1';
		i_memop_addr <= X"DEADBEE" & std_logic_vector(to_unsigned(i,4));
		i_memop_rd <= "00" & X"A";
		i_memop_sign_ext <= '0';
		wait for i_clk_period/2;
		i_e_valid <= '0';
		i_mem_req_rdy <= '1';
		i_mem_data_valid <= '1';
		i_mem_data <= X"00000000DEADBEEF";
		i_wrb_rdy <= '1';
		
		wait for i_clk_period/2;
		end loop;
      -- insert stimulus here 

      wait;
   end process;

END;
