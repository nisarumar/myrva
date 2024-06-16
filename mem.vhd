----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:38:49 05/21/2024 
-- Design Name: 
-- Module Name:    mem - arch_mem 
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
use IEEE.STD_LOGIC_MISC.ALL;
library commonlib;
use commonlib.cfg_data.all;
--use commonlib.types_common.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mem is
 port (
 
 	i_clk 				: in std_logic;
	i_nrst				: in std_logic;
 
		-- in from exec
	i_memop_load		: in std_logic;
	i_memop_store		: in std_logic;
	i_memop_size		: in std_logic_vector(1 downto 0);
	i_memop_addr		: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	i_memop_rd			: in std_logic_vector(5 downto 0);
	i_memop_wdata		: in std_logic_vector(RISCV_ARCH-1 downto 0);
	i_memop_sign_ext  : in std_logic;
	i_e_valid			: in std_logic;
	
	-- output to exection
	o_mem_rdy			: out std_logic;
	
	--output to reg
	o_wr_en				: out std_logic;
	o_rd_addr			: out std_logic_vector(5 downto 0);
	o_rd					: out std_logic_vector(RISCV_ARCH downto 0);
	--input
	i_wrb_rdy			: in std_logic; --write back ready
	
	--memory interface
	
	--input
	i_mem_req_rdy		: in std_logic;
	i_mem_data_valid	: in std_logic;
	i_mem_data_addr	: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	i_mem_data			: in std_logic_vector(63 downto 0);
	
	--output - control
	o_mem_valid			: out std_logic;
	o_mem_write			: out std_logic;
	--o_mem_rsp_rdy		: out std_logic;
	
	--output - data
	o_mem_addr			: out std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	o_mem_data			: out std_logic_vector(63 downto 0);
	o_mem_strb			: out std_logic_vector(7 downto 0)
	
 );
end mem;

architecture arch_mem of mem is

	component queue is
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
	end component;
	
	constant QUEUE_WIDTH : integer := 64 --INPUT DATA
												+ 8 --Stobes
--												+ RISCV_ARCH --i_memop_wdata
												+ 6	--i_memop_rd_addr
--												+ 32 --instruction
--												+ CFG_CPU_ADDR_BITS --i_pc
												+ 2 --i_memop_size
												+ 1 -- sign_ext
												+ 1 -- store
												+ CFG_CPU_ADDR_BITS --i_memop_addr;
												;
	

	signal q_wr_en 	: std_logic;
	signal q_rd_en 	: std_logic;
	signal q_i_data 	: std_logic_vector(QUEUE_WIDTH-1 downto 0);
	signal q_o_data	: std_logic_vector(QUEUE_WIDTH-1 downto 0);
	signal q_full  	: std_logic;
	signal q_nempty 	: std_logic;

	constant state_idle 		  		: std_logic_vector(1 downto 0) := "00";
	constant state_wait_resp 		: std_logic_vector(1 downto 0) := "01";
	constant state_wait_req_acc 	: std_logic_vector(1 downto 0) := "10";
	constant state_hold				: std_logic_vector(1 downto 0) := "11";
	
	type RegisterType is record
		state 		: std_logic_vector(1 downto 0);
		memop_addr	: std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
		mem_wr		: std_logic;
		mem_sign_ext	: std_logic;
		mem_size			: std_logic_vector (1 downto 0);
		mem_rd_addr		: std_logic_vector (5 downto 0);
		mem_wr_en		: std_logic;
		mem_wr_data		: std_logic_vector (63 downto 0);
		mem_wr_strb		: std_logic_vector (7 downto 0);
		mem_wr_hold		: std_logic_vector (RISCV_ARCH downto 0);
		
	end record;
	
	
	constant R_RESET : RegisterType := (
		state_idle,
		(others => '0'),
		'0', '0',
		(others => '0'),
		(others => '0'),
		'0',
		(others => '0'),
		(others => '0'),
		(others => '0')
	);
	
	signal r, rin : RegisterType;

begin

q0: queue generic map (
		q_depth_bits => 2,
		q_width_bits => QUEUE_WIDTH
	) port map (
		i_clk => i_clk,
		i_nrst => i_nrst,
		i_wr_en => q_wr_en,
		i_rd_en => q_rd_en,
		i_data => q_i_data,
		o_data => q_o_data,
		o_q_full => q_full,
		o_q_nempty => q_nempty
	);

	comb: process(i_nrst, i_memop_load, i_memop_store, i_memop_size, i_memop_addr, i_memop_rd, i_memop_wdata,
				  i_memop_sign_ext, i_e_valid, i_wrb_rdy, i_mem_req_rdy, i_mem_data_valid, i_mem_data_addr, 
				  i_mem_data, q_o_data, q_full, q_nempty, r)
			variable v : RegisterType;
			variable curr_data 	 : std_logic_vector(63 downto 0);
			variable curr_strb	 : std_logic_vector(7 downto 0);
			variable mem_wdata	 : std_logic_vector(63 downto 0);
			variable mem_wrstrb	 : std_logic_vector(7 downto 0);
			variable rd_data		 : std_logic_vector(RISCV_ARCH-1 downto 0);
			variable rd_addr		 : std_logic_vector(5 downto 0);
			variable pc				 : std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
			variable instr			 : std_logic_vector(31 downto 0);
			variable mem_size		 : std_logic_vector(1 downto 0);
			variable mem_write	 : std_logic;
			variable mem_sign_ext : std_logic;
			variable mem_addr		 : std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
			constant zero64		 : std_logic_vector(63 downto 0) := (others => '0');
			variable mem_shift	 : std_logic_vector(63 downto 0);
			variable mem_signed 	 : std_logic_vector(63 downto 0);
			variable mem_usigned	 : std_logic_vector(63 downto 0);
			variable c_rd_data	 : std_logic_vector(RISCV_ARCH-1 downto 0);
			variable c_q_rd_en	 : std_logic;
			variable c_mem_valid  : std_logic;
			variable c_o_wr_en	 : std_logic;
			variable c_o_rd_addr	 : std_logic_vector(5 downto 0);
			variable c_o_rd		 : std_logic_vector (RISCV_ARCH downto 0);
			variable c_o_mem_rdy  : std_logic;
	
	begin
		
		
		v := r;
		curr_data := (others => '0');
		curr_strb := (others => '0');
		mem_shift := (others => '0');
		mem_signed := (others => '0');
		mem_usigned := (others => '0');
		c_rd_data := (others => '0');
		c_q_rd_en := '0';
		c_mem_valid := '0';
		
		c_o_wr_en := '0';
		c_o_rd_addr := (others => '0');
		c_o_rd	:= (others => '0');
		
		case i_memop_size is
			when MEMOP_1B => 
				curr_strb := X"01";
				curr_data := i_memop_wdata(7 downto 0) & i_memop_wdata(7 downto 0)
							  & i_memop_wdata(7 downto 0) & i_memop_wdata(7 downto 0)
							  & i_memop_wdata(7 downto 0) & i_memop_wdata(7 downto 0)
							  & i_memop_wdata(7 downto 0) & i_memop_wdata(7 downto 0);
							  
				curr_strb := std_logic_vector(shift_left(unsigned(curr_strb), to_integer(unsigned(i_memop_addr(2 downto 0)))));

			when MEMOP_2B =>
				curr_strb := X"03";
				curr_data := i_memop_wdata(15 downto 0) & i_memop_wdata(15 downto 0)
							 &  i_memop_wdata(15 downto 0) & i_memop_wdata(15 downto 0);
				curr_strb := std_logic_vector(shift_left(unsigned(curr_strb), to_integer(unsigned(i_memop_addr(2 downto 1) & '0'))));
			when others => --for now 32 bit architecture
				curr_strb := X"0F";
				curr_data := i_memop_wdata(31 downto 0) & i_memop_wdata(31 downto 0);
				curr_strb := std_logic_vector(shift_left(unsigned(curr_strb), to_integer(unsigned(i_memop_addr(2 downto 2) & "00"))));
		end case;
		
		q_i_data <= curr_data & curr_strb --& i_memop_wdata 
						& i_memop_rd --& i_instr & i_pc 
						& i_memop_size 
						& i_memop_sign_ext & i_memop_store & i_memop_addr;
						
		q_wr_en <= i_e_valid and (i_memop_load or i_memop_store);
		
		
		mem_wdata 	:= q_o_data (64 + CFG_CPU_ADDR_BITS + 18 -1 downto 
												CFG_CPU_ADDR_BITS + 18 );
									 
		mem_wrstrb 	:= q_o_data(CFG_CPU_ADDR_BITS + 18 -1 downto
												CFG_CPU_ADDR_BITS + 10 );
										
		--rd_data		:= q_o_data(RISCV_ARCH + 2*CFG_CPU_ADDR_BITS + 42 -1  downto
		--								 2*CFG_CPU_ADDR_BITS + 42);
								
		rd_addr 		:= q_o_data (CFG_CPU_ADDR_BITS + 10 -1 downto
												CFG_CPU_ADDR_BITS + 4);
										
		--instr	 		:= q_o_data(2*CFG_CPU_ADDR_BITS + 36-1 downto
		--							 2*CFG_CPU_ADDR_BITS + 4);
									 
	   --pc				:= q_o_data(2*CFG_CPU_ADDR_BITS + 4 -1 downto
		--											CFG_CPU_ADDR_BITS	+ 4);
													
		mem_size 	:= q_o_data(CFG_CPU_ADDR_BITS + 4 -1 downto
										 CFG_CPU_ADDR_BITS + 2 );
										 
		mem_sign_ext := q_o_data(CFG_CPU_ADDR_BITS + 1);
										 
		mem_write	:= q_o_data( CFG_CPU_ADDR_BITS);
										 
		mem_addr		:= q_o_data(CFG_CPU_ADDR_BITS -1 downto 0);
		
		
		case r.memop_addr(1 downto 0) is
		when "01" => mem_shift:= zero64(7 downto 0) & i_mem_data(63 downto 8);
		when "10" => mem_shift:= zero64(15 downto 0) & i_mem_data(63 downto 16);
		when "11" => mem_shift:= zero64(23 downto 0) & i_mem_data(63 downto 24);
		when others => mem_shift := i_mem_data;
		end case;
		
		case r.mem_size is
		when MEMOP_1B =>
			mem_usigned (7 downto 0) := mem_shift(7 downto 0);
			mem_signed (7 downto 0)	:= mem_shift(7 downto 0);
			mem_signed (63 downto 8) := (others => mem_shift(7));
		when MEMOP_2B =>
			mem_usigned (15 downto 0) := mem_shift(15 downto 0);
			mem_signed (15 downto 0)	:= mem_shift(15 downto 0);
			mem_signed (63 downto 16) := (others => mem_shift(15));
		when others =>
			mem_usigned (31 downto 0) := mem_shift(31 downto 0);
			mem_signed (31 downto 0)	:= mem_shift(31 downto 0);
			mem_signed (63 downto 32) := (others => mem_shift(31));
		end case;
		
		
		if r.mem_wr = '0' then
			if r.mem_sign_ext = '1' then
				c_rd_data := mem_signed (RISCV_ARCH-1 downto 0);
			else
				c_rd_data := mem_usigned(RISCV_ARCH-1 downto 0);
			end if;
		else
			c_rd_data := (others => '0');
		end if;
		
		case r.state is
			when state_idle =>
				c_q_rd_en := '1';
				if q_nempty = '1' then
					c_mem_valid := '1';
					v.mem_rd_addr := rd_addr;
					v.mem_sign_ext := mem_sign_ext;
					v.mem_wr := mem_write;
					v.mem_size := mem_size;
					v.memop_addr := mem_addr;
					v.mem_wr_data := mem_wdata;
					v.mem_wr_strb	:= mem_wrstrb;
					v.mem_wr_en		:= or_reduce(rd_addr);
					if i_mem_req_rdy = '1' then
						v.state := state_wait_resp;
					else
						v.state := state_wait_req_acc;
					end if;
				end if;
				
			when state_wait_resp =>
				if i_mem_data_valid = '0' then
				else
					
					c_o_wr_en := r.mem_wr_en;
					c_o_rd_addr	:= r.mem_rd_addr;
					c_o_rd		:= c_rd_data & '0';
					
					c_q_rd_en := '1';
					if r.mem_wr_en = '1' and i_wrb_rdy = '0' then
						c_q_rd_en := '0';
						v.state := state_hold;
						v.mem_wr_hold := c_rd_data & '0';
					elsif q_nempty = '1' then
						c_mem_valid := '1';
						v.mem_rd_addr := rd_addr;
						v.mem_sign_ext := mem_sign_ext;
						v.mem_wr := mem_write;
						v.mem_size := mem_size;
						v.memop_addr := mem_addr;
						v.mem_wr_data := mem_wdata;
						v.mem_wr_strb	:= mem_wrstrb;
						v.mem_wr_en		:= or_reduce(rd_addr);
						if i_mem_req_rdy = '1' then
							v.state := state_wait_resp;
						else
							v.state := state_wait_req_acc;
						end if;
					else
						v.state := state_idle;
					end if;
				end if;
			when state_wait_req_acc =>
				c_mem_valid := '1';
				mem_write := r.mem_wr;
				mem_size  := r.mem_size;
				mem_addr  := r.memop_addr;
				mem_wdata := r.mem_wr_data;
				mem_wrstrb := r.mem_wr_strb;
				if i_mem_req_rdy = '1' then
					v.state := state_wait_resp;
				end if;
				
			when state_hold =>
				c_o_wr_en := r.mem_wr_en;
				c_o_rd_addr	:= r.mem_rd_addr;
				c_o_rd		:= r.mem_wr_hold;
				if i_wrb_rdy = '1' then
					c_q_rd_en := '1';
					if q_nempty = '1' then
						c_mem_valid := '1';
						v.mem_rd_addr := rd_addr;
						v.mem_sign_ext := mem_sign_ext;
						v.mem_wr := mem_write;
						v.mem_size := mem_size;
						v.memop_addr := mem_addr;
						v.mem_wr_data := mem_wdata;
						v.mem_wr_strb	:= mem_wrstrb;
						v.mem_wr_en		:= or_reduce(rd_addr);
						if i_mem_req_rdy = '1' then
							v.state := state_wait_resp;
						else
							v.state := state_wait_req_acc;
						end if;
					else
						v.state := state_idle;
					end if;
				end if;
			when others =>
		end case;
		
		c_o_mem_rdy := '1';
		
		if q_full = '1' then
			c_o_mem_rdy := '0';
		end if;
		
		if i_nrst = '0' then
			v := R_RESET;
		end if;
		
		o_mem_valid	 <= c_mem_valid;
		o_mem_write	 <= mem_write;
		
		o_mem_addr	<= mem_addr;
		o_mem_data	<= mem_wdata;
		o_mem_strb	<= mem_wrstrb;
		
		o_wr_en	<= c_o_wr_en;
		o_rd_addr <= c_o_rd_addr;
		o_rd	<= c_o_rd;
		
		q_rd_en <= c_q_rd_en;
		
		o_mem_rdy <= c_o_mem_rdy;
		
		rin <= v;
		
	end process;
	
	regs: procesS(i_clk, i_nrst)
	begin
		if i_nrst ='0' then
			r <= R_RESET;
		elsif rising_edge(i_clk) then
			r <= rin;
		end if;
	end process;
end arch_mem;

