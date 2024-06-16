----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:39:56 05/11/2024 
-- Design Name: 
-- Module Name:    reg_bank - archRegBank 
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
use IEEE.NUMERIC_STD.ALL;
library commonlib;
use commonlib.cfg_data.all;
use ieee.std_logic_misc.all; 
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reg_bank is
port (

	i_clk			: in std_logic;
	i_nrst		: in std_logic;
	i_rs1Addr	: in std_logic_vector(5 downto 0);
	i_rs2Addr	: in std_logic_vector(5 downto 0);
	i_rdAddr		: in std_logic_vector(5 downto 0);
	i_rd			: in std_logic_vector(RISCV_ARCH downto 0);
	i_wr_en		: in std_logic;
	
	o_rs1			: out std_logic_vector(RISCV_ARCH downto 0);
	o_rs2			: out std_logic_vector(RISCV_ARCH downto 0)
);

end reg_bank;

architecture archRegBank of reg_bank is

  constant REG_MSB : integer := 4;
  constant REGS_TOTAL : integer := 2**(REG_MSB + 1);
  
  constant init_val : std_logic_vector(RISCV_ARCH-1 downto 0) := X"00000004";

  type reg_score_type is record
    val : std_logic_vector(RISCV_ARCH downto 0);
  end record;

  type MemoryType is array (0 to REGS_TOTAL-1) of reg_score_type;

  type RegistersType is record
      mem : MemoryType;
  end record;

  signal r, rin : RegistersType;

begin

	comb: process (i_rs1Addr, i_rs2Addr, i_rdAddr, i_nrst, i_rd, i_wr_en, r)
		variable v: RegistersType;
	begin
		
		for i in 0 to REGS_TOTAL-1 loop
			v.mem(i).val := r.mem(i).val;
		end loop;
		
		if i_wr_en = '1' and or_reduce(i_rdAddr(REG_MSB downto 0)) = '1' then
			v.mem(to_integer(unsigned(i_rdAddr))).val := i_rd;
		end if;
		
		if i_nrst = '0' then
			for i in 0 to REGS_TOTAL-1 loop
				v.mem(i).val := '0'& init_val;
			end loop;
		end if;
		
		o_rs1 <= r.mem(to_integer(unsigned(i_rs1Addr(REG_MSB downto 0)))).val;
		o_rs2 <= r.mem(to_integer(unsigned(i_rs2Addr(REG_MSB downto 0)))).val;
		
		rin <= v;
	end process;


regs: process (i_nrst, i_clk)
	begin
		if i_nrst = '0' then
			r.mem(0).val <= (others => '0');
			for i in 1 to REGS_TOTAL-1 loop
				r.mem(i).val <= '0'& init_val;
			end loop;
		elsif rising_edge(i_clk) then
			for i in 0 to REGS_TOTAL-1 loop
				r.mem(i).val <= rin.mem(i).val;
			end loop;
		end if;
	end process;

end archRegBank;

