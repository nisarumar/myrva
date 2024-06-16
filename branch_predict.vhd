----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:12:05 05/10/2024 
-- Design Name: 
-- Module Name:    branch_predict - archBranchPredict 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity branch_predict is

port (
	i_clk 				: in std_logic;
	i_nrst				: in std_logic;
	i_gib_pc				: in std_logic;
	i_resp_mem_valid	: in std_logic;
	i_resp_mem_addr	: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	i_resp_mem_data	: in std_logic_vector(31 downto 0);
	i_e_npc				: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	o_npc_predict		: out std_logic_vector(CFG_CPUT_ADDR_BITS-1 downto 0)
);
end branch_predict;

architecture archBranchPredict of branch_predict is
  type HistoryType is record
      pc : std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
  end record;
  
  constant history_none : HistoryType := (
    (others => '1')
  );

  type HistoryVector is array (0 to 2) of HistoryType;

  type RegistersType is record
      h : HistoryVector;
      wait_resp : std_logic;
  end record;
  
  
  constant R_RESET : RegistersType := (
      (others => history_none), '0'
  );
  
  signal r, rin : RegistersType;

begin

	comb: process (i_nrst, i_gib_pc, i_resp_mem_valid, i_resp_mem_addr, i_resp_mem_data, i_e_npc, r)
	variable temp_pc : std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	variable last_pc : std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	variable jal_off  : std_logic_vector(CFG_CPU_ADDR_BITS-1  downto 0);
	variable jal_addr  : std_logic_vector(CFG_CPU_ADDR_BITS-1  downto 0);
	begin
		
		last_pc := r.h(0).pc;
		temp_pc := i_resp_mem_addr;
		-- uncoditional jump	
		jal_off(CFG_CPU_ADDR_BITS-1 downto 20) := (others => temp_pc(31)); --sign extend
		jal_off(19 downto 12) := temp_pc(19 downto 12);
		jal_off(11) := temp_pc(20);
		jal_off(10 downto 1) := temp_pc(30 downto 21);
		jal_off(0) := '0';
		jal_addr := last_pc + vb_jal_off;
		
		-- conditional jump
	end process;
	
	
end archBranchPredict;

