--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:33:37 05/09/2024
-- Design Name:   
-- Module Name:   /home/umar/code/riscv/my_riscv/myrva/tb_fetch.vhd
-- Project Name:  myrva
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fetch
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
--use IEEE.std_logic_arith.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_fetch IS
END tb_fetch;
 
ARCHITECTURE behavior OF tb_fetch IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT fetch
    PORT(
		i_clk					: in std_logic;
		i_nrst				: in std_logic;
		i_pipeline_hold	: in std_logic;
		i_mem_req_rdy		: in std_logic;	-- memory is able to accepts request
		i_mem_data_valid	: in std_logic;	-- memory output is valid
		i_mem_addr			: in std_logic_vector(31 downto 0);
		i_mem_data			: in std_logic_vector(31 downto 0);
		i_flush_pipeline	: in std_logic;
		i_e_npc				: in std_logic_vector(31 downto 0); --decoded npc from execution stage
		i_br_pr_dis			: in std_logic; --disable branch prediction
		
		o_mem_addr_valid	: out std_logic; --requested address is valid
		o_mem_addr			: out std_logic_vector(31 downto 0); -- requested memory addr
		o_mem_resp_rdy		: out std_logic;	
		o_hold				: out std_logic; -- hold pipeline
		o_instr				: out std_logic_vector(31 downto 0); -- riscv instruction 32 bit
		o_pc					: out std_logic_vector(31 downto 0);
		o_valid				: out std_logic	--output of fetch is valid
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nrst : std_logic := '0';
   signal i_pipeline_hold : std_logic := '0';
   signal i_mem_req_rdy : std_logic := '0';
   signal i_mem_data_valid : std_logic := '0';
   signal i_mem_addr : std_logic_vector(31 downto 0) := (others => '0');
   signal i_mem_data : std_logic_vector(31 downto 0) := (others => '0');
   signal i_flush_pipeline : std_logic := '0';

 	--Outputs
   signal o_mem_addr_valid : std_logic;
   signal o_mem_addr : std_logic_vector(31 downto 0);
   signal o_mem_resp_rdy : std_logic;
   signal o_hold : std_logic;
   signal o_instr : std_logic_vector(31 downto 0);
   signal o_pc : std_logic_vector(31 downto 0);
   signal o_valid : std_logic;
	
	signal i_e_npc				: std_logic_vector(31 downto 0); --decoded npc from execution stage
	signal i_br_pr_dis			: std_logic; --disable branch prediction
		
	
	--intermediates
	type cache_type is array (0 to 32) of std_logic_vector(31 downto 0); --block

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: fetch PORT MAP (
          i_clk => i_clk,
          i_nrst => i_nrst,
          i_pipeline_hold => i_pipeline_hold,
          i_mem_req_rdy => i_mem_req_rdy,
          i_mem_data_valid => i_mem_data_valid,
          i_mem_addr => i_mem_addr,
          i_mem_data => i_mem_data,
          i_flush_pipeline => i_flush_pipeline,
			 i_e_npc => i_e_npc,
			 i_br_pr_dis => i_br_pr_dis,
          o_mem_addr_valid => o_mem_addr_valid,
          o_mem_addr => o_mem_addr,
          o_mem_resp_rdy => o_mem_resp_rdy,
          o_hold => o_hold,
          o_instr => o_instr,
          o_pc => o_pc,
          o_valid => o_valid
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
	stim_proc1: process
	begin
		wait for 4*i_clk_period;
		i_pipeline_hold <= '1';
		wait for 4*i_clk_period;
		i_pipeline_hold <= '0';
	end process;
	
--	   -- Stimulus process
--	stim_proc2: process
--	begin
--		wait for 16*i_clk_period;
--		i_mem_data_valid <= '1';
--		wait for 16*i_clk_period;
--		i_mem_data_valid <= '0';
--	end process;
	
   stim_proc: process
	variable icache_mem : cache_type;
	variable count : integer := 0;
	variable old_pc : std_logic_vector (31 downto 0) := (others => '1');
	variable sig : std_logic := '0';
   begin		
     
	  --insertion sort--
		icache_mem(0 to 18) := ( 0 => x"00450693", 1 => x"00100713", 2 => x"00b76463", 3 => x"00008067",
										4 => x"0006a803", 5 => x"00068613", 6 => x"00070793", 7 => x"ffc62883",
										8 => x"01185a63", 9 => x"01162023", 10 => x"fff78793", 11 => x"ffc60613",
										12 => x"fe0796e3",13 => x"00279793",14 => x"00f507b3",15 => x"0107a023", 
										16 => x"00170713",17 => x"00468693",18 => x"fc1ff06f" );
		-- hold reset state for 100 ns. -- 
		wait for 100 ns;
		i_nrst <= '1';
		i_mem_req_rdy <= '1';
		i_mem_data_valid <= '0';
		i_br_pr_dis <= '0';
		i_mem_addr <= (others => '0');
		i_e_npc <= (others => '1');
		
		wait until rising_edge(i_clk);
      wait for i_clk_period*10;
		i_mem_addr <= o_mem_addr;
		i_mem_data <= icache_mem(to_integer(unsigned(o_mem_addr)/ 4));
		i_mem_data_valid <= '1';
		loop
		wait for i_clk_period/2;
		wait for i_clk_period/2;
		i_mem_addr <= o_mem_addr;
		i_mem_data <= icache_mem(to_integer(unsigned(o_mem_addr) / 4));
		wait for i_clk_period/2;
		wait for i_clk_period/2;
		end loop;
      -- insert stimulus here 

      wait;
   end process;

END;
