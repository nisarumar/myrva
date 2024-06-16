--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:35:49 05/16/2024
-- Design Name:   
-- Module Name:   /home/umar/code/riscv/my_riscv/myrva/tb_decode.vhd
-- Project Name:  myrva
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: decode
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
use commonlib.types_common.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_decode IS
END tb_decode;
 
ARCHITECTURE behavior OF tb_decode IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT decode
    PORT(
         i_clk : IN  std_logic;
         i_nrst : IN  std_logic;
         i_hold : IN  std_logic;
         i_valid : IN  std_logic;
         i_pc : IN  std_logic_vector(31 downto 0);
         i_instr : IN  std_logic_vector(31 downto 0);
         o_rs1 : OUT  std_logic_vector(5 downto 0);
         o_rs2 : OUT  std_logic_vector(5 downto 0);
         o_rd : OUT  std_logic_vector(5 downto 0);
         o_imm : OUT  std_logic_vector(31 downto 0);
         i_e_rdy : IN  std_logic;
         i_flush_pipeline : IN  std_logic;
         o_valid : OUT  std_logic;
         o_pc : OUT  std_logic_vector(31 downto 0);
         o_instr : OUT  std_logic_vector(31 downto 0);
         o_memop_store : OUT  std_logic;
         o_memop_load : OUT  std_logic;
         o_memop_sign_ext : OUT  std_logic;
         o_memop_size : OUT  std_logic_vector(1 downto 0);
         o_isa_type : OUT  std_logic_vector(5 downto 0);
         o_instr_vec : OUT  std_logic_vector(96 downto 0);
         o_exception : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nrst : std_logic := '0';
   signal i_hold : std_logic := '0';
   signal i_valid : std_logic := '0';
   signal i_pc : std_logic_vector(31 downto 0) := (others => '0');
   signal i_instr : std_logic_vector(31 downto 0) := (others => '0');
   signal i_e_rdy : std_logic := '0';
   signal i_flush_pipeline : std_logic := '0';

 	--Outputs
   signal o_rs1 : std_logic_vector(5 downto 0);
   signal o_rs2 : std_logic_vector(5 downto 0);
   signal o_rd : std_logic_vector(5 downto 0);
   signal o_imm : std_logic_vector(31 downto 0);
   signal o_valid : std_logic;
   signal o_pc : std_logic_vector(31 downto 0);
   signal o_instr : std_logic_vector(31 downto 0);
   signal o_memop_store : std_logic;
   signal o_memop_load : std_logic;
   signal o_memop_sign_ext : std_logic;
   signal o_memop_size : std_logic_vector(1 downto 0);
   signal o_isa_type : std_logic_vector(5 downto 0);
   signal o_instr_vec : std_logic_vector(96 downto 0);
   signal o_exception : std_logic;
	
	type cache_type is array (0 to 32) of std_logic_vector(31 downto 0); --block

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: decode PORT MAP (
          i_clk => i_clk,
          i_nrst => i_nrst,
          i_hold => i_hold,
          i_valid => i_valid,
          i_pc => i_pc,
          i_instr => i_instr,
          o_rs1 => o_rs1,
          o_rs2 => o_rs2,
          o_rd => o_rd,
          o_imm => o_imm,
          i_e_rdy => i_e_rdy,
          i_flush_pipeline => i_flush_pipeline,
          o_valid => o_valid,
          o_pc => o_pc,
          o_instr => o_instr,
          o_memop_store => o_memop_store,
          o_memop_load => o_memop_load,
          o_memop_sign_ext => o_memop_sign_ext,
          o_memop_size => o_memop_size,
          o_isa_type => o_isa_type,
          o_instr_vec => o_instr_vec,
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
		variable count : integer := 0;
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
          i_hold <= '0';
          i_valid <= '0';
          i_pc <= (others => '0');
          i_instr <= (others => '0');
          i_e_rdy <= '1';
          i_flush_pipeline <= '0';
			 
      wait for i_clk_period*10;
		
		loop
		
		i_instr <= icache_mem(count);
		i_valid <= '1';
		if count < 18 then
			count := count + 1;
		end if;
		wait for i_clk_period/2;
			i_valid <= '0';
			i_pc <= std_logic_vector(to_unsigned(count * 4, i_pc'length));
		wait for i_clk_period/2;
		end loop;

      -- insert stimulus here 

      wait;
   end process;

END;
