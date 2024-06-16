----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:44:16 05/09/2024 
-- Design Name: 
-- Module Name:    fetch - Behavioral 
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
library commonlib;
use commonlib.cfg_data.all;
use commonlib.types_common.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fetch is
	port(
		i_clk					: in std_logic;
		i_nrst				: in std_logic;
		i_pipeline_hold	: in std_logic;
		i_mem_req_rdy		: in std_logic;	-- memory is able to accepts request
		i_mem_data_valid	: in std_logic;	-- memory output is valid
		i_mem_addr			: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
		i_mem_data			: in std_logic_vector(31 downto 0);
		i_flush_pipeline	: in std_logic;
		i_e_npc				: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0); --decoded npc from execution stage
		i_br_pr_dis			: in std_logic; --disable branch prediction
		
		o_mem_addr_valid	: out std_logic; --requested address is valid
		o_mem_addr			: out std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0); -- requested memory addr
		o_mem_resp_rdy		: out std_logic;	
		o_hold				: out std_logic; -- hold pipeline
		o_instr				: out std_logic_vector(31 downto 0); -- riscv instruction 32 bit
		o_pc					: out std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
		o_valid				: out std_logic	--output of fetch is valid
	);
end fetch;

architecture arch_InstrFetch of fetch is
  
  type pc_hist_type is array (0 to 1) of std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
  
  constant pc_hist_none : std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0) := ( (others => '1') );
  
	type RegistersType is record
		resp_valid 	: std_logic;
		wait_resp	: std_logic;
		resp_addr	: std_logic_vector (CFG_CPU_ADDR_BITS-1 downto 0);
		resp_data 	: std_logic_vector(31 downto 0);
		pc_hist		: pc_hist_type;
		nxt_pc		: std_logic_vector(31 downto 0);
	end record;
	
	constant R_RESET : RegistersType := (
	'0','0',
	(others => '0'), (others => '0'),
	(others => pc_hist_none), (others=>'0')
	);


	signal r, rin: RegistersType;
begin
	comb: process (i_nrst, i_pipeline_hold, i_mem_req_rdy, i_mem_data_valid, i_mem_addr, i_mem_data, i_flush_pipeline, i_e_npc, i_br_pr_dis, r)
		variable v: RegistersType;
		variable can_mk_rq : std_logic; -- can make request?
		variable hold_pipe : std_logic; -- hold the pipeline!
		variable gib_npc : std_logic; --do I want next pc?
		variable curr_pc : std_logic_vector (CFG_CPU_ADDR_BITS-1 downto 0); --current pc for decode unit
		variable curr_instr : std_logic_vector(31 downto 0);
		variable tmp_instr : std_logic_vector(31 downto 0);
		variable curr_valid : std_logic;
		variable nxt_pc : std_logic_vector (CFG_CPU_ADDR_BITS-1 downto 0); --current pc for decode unit
		variable jal_off	: std_logic_vector (CFG_CPU_ADDR_BITS-1 downto 0);
		variable branch_off : std_logic_vector (CFG_CPU_ADDR_BITS-1 downto 0);
	begin
		v := r;
		can_mk_rq := not i_pipeline_hold and not (r.wait_resp and not i_mem_data_valid); --can make request if 1- pipeline hold is not asserted if not, 2a- we 'were' not waiting for response, if we are,  2b- the data has just became available.
		hold_pipe 	:= not (r.wait_resp and i_mem_data_valid); --hold the pipeline! if we are not waiting for response of previous request or we are, but data has not become available;
		gib_npc := i_mem_req_rdy and can_mk_rq; -- I want next pc, if memory is ready to accept request and I can make new request
		
		if gib_npc = '1' then
			v.wait_resp := '1'; --if I want next pc then I should wait for the response;
		elsif i_mem_data_valid = '1' and i_pipeline_hold = '0' then
			v.wait_resp := '0'; -- if I don't want next pc for some reason (mem not ready?) and the current request is fulfilled then I don't have to wait for anything
		end if;
		
		tmp_instr := i_mem_data;
		jal_off(CFG_CPU_ADDR_BITS-1 downto 20) := (others => tmp_instr(31)); --sign extend
		jal_off(19 downto 12) := tmp_instr(19 downto 12);
		jal_off(11) := tmp_instr(20);
		jal_off(10 downto 1) := tmp_instr(30 downto 21);
		jal_off(0) := '0';
		
		if tmp_instr(31) = '1' then
			branch_off(CFG_CPU_ADDR_BITS-1 downto 12) := (others => '1');
		else
			branch_off(CFG_CPU_ADDR_BITS-1 downto 12) := (others => '0');
		end if;
		
		branch_off(11) := tmp_instr(7);
		branch_off(10 downto 5) := tmp_instr(30 downto 25);
		branch_off(4 downto 1) := tmp_instr(11 downto 8);
		branch_off(0) := '0';
		
		if i_mem_data_valid = '1' and r.wait_resp = '1' and i_pipeline_hold = '0' then -- if data is valid to the previous request we did then please latch the current results for the decode stage
			v.resp_valid := '1';
			v.resp_addr := i_mem_addr;
			v.resp_data := i_mem_data;
			v.pc_hist(0) := r.resp_addr;
			v.pc_hist(1) := r.pc_hist(0);
			if (tmp_instr(6 downto 0) = "1100011") and (tmp_instr(31) = '1') then --calculate the offset as soon as we get the instruction from Icache
				v.nxt_pc := v.resp_addr + branch_off;
			elsif tmp_instr(6 downto 0) = "1101111" then
				v.nxt_pc := std_logic_vector(signed(v.resp_addr) + signed(jal_off));
			else
				v.nxt_pc := std_logic_vector(unsigned(v.resp_addr) + 4); --opcode size of 4 bytes
			end if;
			
		end if;
		
		
		if gib_npc = '1' and i_br_pr_dis = '0' then
			if v.resp_valid = '1' then
				nxt_pc := v.nxt_pc;
			else
				nxt_pc := r.nxt_pc;
			end if;
		elsif gib_npc = '1' then --branch miss happened; all the instruction in the pipeline will be "noped", ask for execution stage's decoded next pc
			nxt_pc := i_e_npc;
		end if;
		
		if i_flush_pipeline = '1' then
			v.resp_addr := (others => '1'); --if we were here becuase of flush_pipeline then discard the addrs and set all 1
		end if;
		
		curr_pc := r.resp_addr; 
		curr_instr := r.resp_data; --assign the values which were latched in the last cycle.
		curr_valid := r.resp_valid and -- last latched valid value;
							not (i_pipeline_hold or hold_pipe); -- current circumstances
							
		if i_nrst = '0' then -- if we are here because reset was asserted, latch every thing to the intial values
			v := R_RESET;
		end if;
		
		--finally assign current values to the output;
		
		o_mem_addr_valid <= can_mk_rq; --can make new requests so let the memory know
		o_mem_addr <= nxt_pc; --next pc;
		o_valid <= curr_valid; -- currend output to decode is valid
		o_pc <= curr_pc; -- to decode
		o_instr <= curr_instr;
		o_mem_resp_rdy <= r.wait_resp and not i_pipeline_hold;
		o_hold <= hold_pipe;
		
		rin <= v;
		
	end process;

	regs: process(i_clk, i_nrst)
	begin
		if i_nrst = '0' then
			r <= R_RESET;
		elsif rising_edge(i_clk) then
			r <= rin;
		end if;
	end process;

end arch_InstrFetch;

