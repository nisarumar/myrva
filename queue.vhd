--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--library commonlib;
--use commonlib.types_common.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity queue is
	generic (
		q_depth_bits 	: integer := 2;
		q_width_bits	: integer := 32
	);
	port(
			i_clk			: in std_logic;
			i_nrst		: in std_logic;
			
			i_wr_en		: in std_logic;
			i_rd_en 		: in stD_logic;
			
			i_data 		: in std_logic_vector(q_width_bits-1 downto 0);
			o_data 		: out std_logic_vector(q_width_bits-1 downto 0);
			
			o_q_full		: out std_logic;
			o_q_nempty	: out std_logic
			
			);
end queue;

architecture archQ of queue is
	constant q_depth 	: integer := 2**q_depth_bits;
	constant q_full	: std_logic_vector(q_depth_bits downto 0) := std_logic_vector(to_unsigned(q_depth, q_depth_bits+1));
	
	type MemoryType is array (0 to q_depth-1) of std_logic_vector(q_width_bits-1 downto 0);
	
	type RegisterType is record
		mem		 : MemoryType;
		fill_level : std_logic_vector(q_depth_bits downto 0);
		wr_indx	 : std_logic_vector (q_depth_bits downto 0);
		rd_indx	 : std_logic_vector (q_depth_bits downto 0);
		q_full	 : std_logic;
		q_nempty	 : std_logic;
	end record;
	
	constant zero : std_logic_vector(q_depth_bits downto 0) := (others => '0');
	
	signal rin, r : RegisterType;

begin

	comb : process(i_nrst, i_wr_en, i_rd_en, i_data, r)
		variable v : RegisterType;
	begin
		v := r;
		
		if (i_wr_en = '1' and r.q_full ='0') then
			if (r.wr_indx = std_logic_vector(unsigned(q_full)-1)) then
				v.wr_indx := zero;
			else
				v.wr_indx := std_logic_vector(unsigned(r.wr_indx)+1);
			end if;
			v.fill_level := std_logic_vector(unsigned(v.fill_level)+1);
		end if;
		
		if (i_rd_en = '1' and r.q_nempty ='1') then
			if (r.rd_indx = std_logic_vector(unsigned(q_full)-1)) then
				v.rd_indx := zero;
			else
				v.rd_indx := std_logic_vector(unsigned(r.rd_indx)+1);
			end if;
			v.fill_level := std_logic_vector(unsigned(v.fill_level)-1);
		end if;
		
		if (v.fill_level = std_logic_vector(unsigned(q_full)-1)) then
			v.q_full := '1';
		else
			v.q_full := '0';
		end if;
		
		if (v.fill_level = zero) then
			v.q_nempty := '0';
		else
			v.q_nempty := '1';
		end if;
		
		if i_nrst = '0' then
			v.fill_level := (others => '0');
			v.wr_indx	:= (others => '0');
			v.rd_indx	:= (others => '0');
			v.q_full := '0';	
			v.q_nempty := '0';
			for i in 0 to q_depth-1 loop
				v.mem(i) := (others => '0');
			end loop;
		end if;

		if (i_wr_en = '1' and r.q_full = '0') then
			v.mem(to_integer(unsigned(r.wr_indx))) := i_data; --overwrites data
		end if;

		o_data <= r.mem(to_integer(unsigned(r.rd_indx)));
		
		o_q_full <= r.q_full;
		o_q_nempty <= r.q_nempty;
		
		rin <= v;
	end process;
	
	regs: process (i_clk, i_nrst)
	begin
		if i_nrst = '0' then
			r.fill_level <= (others => '0');
			r.wr_indx	<= (others => '0');
			r.rd_indx	<= (others => '0');
			r.q_full <= '0';	
			r.q_nempty <= '0';
			for i in 0 to q_depth-1 loop
				r.mem(i) <= (others => '0');
			end loop;
		elsif rising_edge(i_clk) then
			r <= rin;
		end if;
	end process;

end archQ;
