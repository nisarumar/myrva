--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:00:19 05/17/2024
-- Design Name:   
-- Module Name:   /home/umar/code/riscv/my_riscv/myrva/tb_myrva_core.vhd
-- Project Name:  myrva
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: myrva_core
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
USE ieee.numeric_std.ALL;
 
ENTITY tb_myrva_core IS
END tb_myrva_core;
 
ARCHITECTURE behavior OF tb_myrva_core IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT myrva_core
    PORT(
         i_clk : IN  std_logic;
         i_nrst : IN  std_logic;
         i_mem_req_rdy : IN  std_logic;
         i_mem_data_valid : IN  std_logic;
         i_mem_addr : IN  std_logic_vector(31 downto 0);
         i_mem_data : IN  std_logic_vector(31 downto 0);
         o_mem_addr_valid : OUT  std_logic;
         o_mem_addr : OUT  std_logic_vector(31 downto 0);
         o_mem_resp_rdy : OUT  std_logic;
         i_flush_pipeline : IN  std_logic;
         i_mem_rdy : IN  std_logic;
         o_pc : OUT  std_logic_vector(31 downto 0);
         o_memop_load : OUT  std_logic;
         o_memop_store : OUT  std_logic;
         o_memop_size : OUT  std_logic_vector(1 downto 0);
         o_memop_addr : OUT  std_logic_vector(31 downto 0);
         o_memop_rd : OUT  std_logic_vector(5 downto 0);
         o_memop_wdata : OUT  std_logic_vector(31 downto 0);
         o_memop_sign_ext : OUT  std_logic;
         o_valid : OUT  std_logic;
         o_instr : OUT  std_logic_vector(31 downto 0);
         o_exception : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nrst : std_logic := '0';
   signal i_mem_req_rdy : std_logic := '0';
   signal i_mem_data_valid : std_logic := '0';
   signal i_mem_addr : std_logic_vector(31 downto 0) := (others => '0');
   signal i_mem_data : std_logic_vector(31 downto 0) := (others => '0');
   signal i_flush_pipeline : std_logic := '0';
   signal i_mem_rdy : std_logic := '0';

 	--Outputs
   signal o_mem_addr_valid : std_logic;
   signal o_mem_addr : std_logic_vector(31 downto 0);
   signal o_mem_resp_rdy : std_logic;
   signal o_pc : std_logic_vector(31 downto 0);
   signal o_memop_load : std_logic;
   signal o_memop_store : std_logic;
   signal o_memop_size : std_logic_vector(1 downto 0);
   signal o_memop_addr : std_logic_vector(31 downto 0);
   signal o_memop_rd : std_logic_vector(5 downto 0);
   signal o_memop_wdata : std_logic_vector(31 downto 0);
   signal o_memop_sign_ext : std_logic;
   signal o_valid : std_logic;
   signal o_instr : std_logic_vector(31 downto 0);
   signal o_exception : std_logic;

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
	
	type cache_type is array (0 to 32) of std_logic_vector(31 downto 0); --block
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: myrva_core PORT MAP (
          i_clk => i_clk,
          i_nrst => i_nrst,
          i_mem_req_rdy => i_mem_req_rdy,
          i_mem_data_valid => i_mem_data_valid,
          i_mem_addr => i_mem_addr,
          i_mem_data => i_mem_data,
          o_mem_addr_valid => o_mem_addr_valid,
          o_mem_addr => o_mem_addr,
          o_mem_resp_rdy => o_mem_resp_rdy,
          i_flush_pipeline => i_flush_pipeline,
          i_mem_rdy => i_mem_rdy,
          o_pc => o_pc,
          o_memop_load => o_memop_load,
          o_memop_store => o_memop_store,
          o_memop_size => o_memop_size,
          o_memop_addr => o_memop_addr,
          o_memop_rd => o_memop_rd,
          o_memop_wdata => o_memop_wdata,
          o_memop_sign_ext => o_memop_sign_ext,
          o_valid => o_valid,
          o_instr => o_instr,
          o_exception => o_exception
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
		variable icache_mem : cache_type;
	
   begin		
		  --insertion sort--
		icache_mem(0 to 18) := ( 0 => x"00450693", 1 => x"00100713", 2 => x"00b76463", 3 => x"00008067",
										4 => x"0006a803", 5 => x"00068613", 6 => x"00070793", 7 => x"ffc62883",
										8 => x"01185a63", 9 => x"01162023", 10 => x"fff78793", 11 => x"ffc60613",
										12 => x"fe0796e3",13 => x"00279793",14 => x"00f507b3",15 => x"0107a023", 
										16 => x"00170713",17 => x"00468693",18 => x"fc1ff06f" );
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		i_nrst <= '1';
		i_mem_req_rdy <= '1';
		i_mem_data_valid <= '0';
		i_mem_addr <= (others => '0');
		i_flush_pipeline <= '0';
		i_mem_rdy <= '1';
		
		
		wait for i_clk_period*10;
		i_mem_addr <= o_mem_addr;
		i_mem_data <= icache_mem(to_integer(unsigned(o_mem_addr)/ 4));
		i_mem_data_valid <= '1';
		loop
			wait for i_clk_period/2;
			i_mem_data_valid <= '0';
			wait for i_clk_period/2;
			i_mem_addr <= o_mem_addr;
			i_mem_data <= icache_mem(to_integer(unsigned(o_mem_addr) / 4));
			i_mem_data_valid <= '1';
		end loop;


      -- insert stimulus here 

      wait;
   end process;

END;
