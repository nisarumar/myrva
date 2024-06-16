----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:35:46 05/11/2024 
-- Design Name: 
-- Module Name:    execute - archExecute 
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
use IEEE.std_logic_misc.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity execute is
port (
	i_clk 				: in std_logic;
	i_nrst				: in std_logic;
	i_rs1_addr			: in std_logic_vector(5 downto 0);
	i_rs1					: in std_logic_vector(RISCV_ARCH downto 0);
	i_rs2_addr			: in std_logic_vector(5 downto 0);
	i_rs2					: in std_logic_vector(RISCV_ARCH downto 0);
	i_rd_addr			: in std_logic_vector(5 downto 0);
	i_imm					: in std_logic_vector(RISCV_ARCH-1 downto 0);
	i_valid				: in std_logic;
	i_pc					: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	i_instr			   : in std_logic_vector(31 downto 0);
   i_memop_store 		: in std_logic;                       
   i_memop_load 		: in std_logic;                         
   i_memop_sign_ext 	: in std_logic;                        -- Load memory value with sign extending
   i_memop_size 		: in std_logic_vector(1 downto 0);         -- Memory transaction size
   i_isa_type 			: in std_logic_vector(ISA_Total-1 downto 0); -- Instruction format accordingly with ISA
   i_instr_vec 		: in std_logic_vector(Instr_Total-1 downto 0); -- One bit per decoded instruction bus
   i_exception 		: in std_logic;                             -- Unimplemented instruction
	
	i_mem_rdy			: in std_logic;
	
	--output to reg_bank
	o_wr_en				: out std_logic;
	o_rd_addr			: out std_logic_vector (5 downto 0);
	o_rd_data			: out std_logic_vector(RISCV_ARCH downto 0);
	
	-- output to mem
	o_pc					: out std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	o_memop_load		: out std_logic;
	o_memop_store		: out std_logic;
	o_memop_size		: out std_logic_vector(1 downto 0);
	o_memop_addr		: out std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	o_memop_rd			: out std_logic_vector(5 downto 0);
	o_memop_wdata		: out std_logic_vector(RISCV_ARCH-1 downto 0);
	o_memop_sign_ext  : out std_logic;
	o_valid				: out std_logic;
	o_instr				: out std_logic_vector(31 downto 0);
	
	-- output to fetch
	o_d_npc				: out std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	o_br_pred_dis		: out std_logic;
	
	o_d_rdy				: out std_logic

);
end execute;

architecture archExecute of execute is

	type RegistersType is record
		npc 				: std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
		valid				: std_logic;
		pc					: std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
		memop_load		: std_logic;
		memop_store		: std_logic;
		memop_rd			: std_logic_vector(5 downto 0);
		memop_sign_ext	: std_logic;
		memop_size		: std_logic_vector (1 downto 0);
		memop_wdata		: std_logic_vector (RISCV_ARCH-1 downto 0);
		memop_addr		: std_logic_vector (CFG_CPU_ADDR_BITS-1 downto 0);
		instr				: std_logic_vector (31 downto 0);
	end record;
	
	constant R_RESET : RegistersType := (
	CFG_NMI_RESET_VECTOR, --npc
	'0', --valid
	(others => '0'), '0','0', --pc, memop_load, memop_store
	(others => '0'), '0', (others => '0'), --memop-rd, memop_sign_ext, memop_size
	(others => '0'), (others => '0'), (others => '0') --memop_wdata, --memop_addr, instr
	);
	
	constant zero	 		: std_logic_vector(RISCV_ARCH-1 downto 0) := (others => '0');
	signal wb_shifter_a1 : std_logic_vector(RISCV_ARCH-1 downto 0);
	signal wb_shifter_a2	: std_logic_vector(5 downto 0);
	signal wb_sll			: std_logic_vector(RISCV_ARCH-1 downto 0);
	signal wb_srl			: std_logic_vector(RISCV_ARCH-1 downto 0);
	signal wb_sra			: std_logic_vector(RISCV_ARCH-1 downto 0);
	
	signal r, rin : RegistersType;
	
	component Shifter is
	port (
		i_a1 : in std_logic_vector(RISCV_ARCH-1 downto 0);     -- Operand 1
		i_a2 : in std_logic_vector(5 downto 0);                -- Shift bits number
		o_sll : out std_logic_vector(RISCV_ARCH-1 downto 0);   -- Logical shift left 64-bits operand
		o_srl : out std_logic_vector(RISCV_ARCH-1 downto 0);   -- Logical shift 64 bits
		o_sra : out std_logic_vector(RISCV_ARCH-1 downto 0)   -- Arith. shift 64 bits
	);
	end component;
	
begin
	sh0: Shifter port map (
		i_a1 => wb_shifter_a1,
		i_a2 => wb_shifter_a2,
		o_sll => wb_sll,
		o_srl	=> wb_srl,
		o_sra => wb_sra
	);

	comb: process(i_nrst, i_rs1, i_rs2, i_imm, i_isa_type, i_memop_load, i_memop_store, i_pc, i_mem_rdy, 
						wb_sll, wb_srl, wb_sra, i_instr_vec)
	
		variable v 				: RegistersType;
		variable operand1		: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable operand2		: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable curr_rs1		: std_logic_vector(RISCV_ARCH downto 0);
		variable curr_rs2		: std_logic_vector(RISCV_ARCH downto 0);
		variable curr_imm		: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable offset 		: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable hold			: std_logic;
		variable valid			: std_logic;
		variable br_pred_dis	: std_logic;
		variable npc 			: std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
		variable memop_addr 	: std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
		variable sum			: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable sub			: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable or_r			: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable and_r			: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable xor_r			: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable less			: std_logic;
		variable gr_equal		: std_logic;
		variable branch		: std_logic; --conditional branch 
		variable instr_vec 	: std_logic_vector(Instr_Total-1 downto 0); -- One bit per decoded instruction bus
		variable res			: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable wr_en			: std_logic;
		variable hazard		: std_logic;
		
	begin
	
		v := r;
	
		curr_rs1 	:= i_rs1;
		curr_rs2		:= i_rs2;
		curr_imm		:= i_imm;
		operand1 	:= (others => '0');
		operand2 	:= (others => '0');
		instr_vec	:= i_instr_vec;
		wr_en			:= '0';
	
	
		-- decides on operand; 
		if i_isa_type(ISA_R_type) = '1' then
			operand1 := curr_rs1(RISCV_ARCH downto 1);
			operand2 := curr_rs2(RISCV_ARCH downto 1);
		elsif i_isa_type(ISA_I_type) = '1' then
			operand1 := curr_rs1(RISCV_ARCH downto 1);
			operand2 := curr_imm;
		elsif i_isa_type(ISA_SB_type) = '1' then
			operand1 := curr_rs1(RISCV_ARCH downto 1);
			operand2 := curr_rs2(RISCV_ARCH downto 1);
			offset := curr_imm;
		elsif i_isa_type(ISA_UJ_type) = '1' then
			operand1(CFG_CPU_ADDR_BITS-1 downto 0) := i_pc;
			offset := curr_imm;
		elsif i_isa_type(ISA_U_type) = '1' then
			operand1(CFG_CPU_ADDR_BITS-1 downto 0) := i_pc;
			operand2 := curr_imm;
		elsif i_isa_type(ISA_S_type) = '1' then
			operand1 := curr_rs1(RISCV_ARCH downto 1);
			operand2 := curr_rs2(RISCV_ARCH downto 1);
			offset := curr_imm;
		end if;
		
		hold := (curr_rs1(0) and curr_rs2(0)) or (not i_mem_rdy and (i_memop_load or i_memop_store));
		
		br_pred_dis := '0';
		
		if i_pc = r.npc and i_valid = '1' and hold = '0' then   --if previous decoded instruction matches current instruction then proceed.
			br_pred_dis := '0'; 
			valid := '1';
		elsif i_valid ='1' and hold ='0' then
			br_pred_dis := '1';
			valid := '0';
		else
			br_pred_dis := '0'; -- @todo: this approach will delay the pipeline by 1 clock cycle, need the branch prediction disable logic within the branch prediction module
			valid := '0';
		end if;
		
		--formulate memory address based on load and store intstruction definition
		if i_memop_load = '1' then
			--Loads four bytes from memory at address x[rs1] + sign-extend(offset) and writes them to x[rd]. operand2 in this case is i_imm
			memop_addr := operand1(CFG_CPU_ADDR_BITS-1 downto 0) + operand2(CFG_CPU_ADDR_BITS-1 downto 0);
		elsif i_memop_store = '1' then
			-- Stores the four least-significant bytes in register x[rs2] to memory at address x[rs1] + sign-extend(offset).
        memop_addr := operand1(CFG_CPU_ADDR_BITS-1 downto 0) + offset(CFG_CPU_ADDR_BITS-1 downto 0);
		else
		  memop_addr := (others => '0');
		end if;
		
		
		sum := operand1 + operand2;
		sub := operand1 - operand2;
		and_r := operand1 and operand2;
		or_r := operand1 or operand2;
		xor_r := operand1 xor operand2;
    
		wb_shifter_a1 <= operand1;
		wb_shifter_a2 <= operand2(5 downto 0);

		
		if UNSIGNED(operand1) < UNSIGNED(operand2) then
			less := '1';
		else
			less := '0';
		end if;
		if UNSIGNED(operand1) >= UNSIGNED(operand2) then
			gr_equal := '1';
		else
			gr_equal := '0';
		end if;
		
		
		branch := '0';
		
		if ( ( (instr_vec(Instr_BEQ) ='1') and (sub = zero) ) or --Branch if Equal and subtraction is zero;
			  ( (instr_vec(Instr_BGE) = '1') and (sub(RISCV_ARCH-1) = '0') ) or -- Branch if greater or equal = sub is not negative;
			  ( (instr_vec(Instr_BGEU) = '1') and (gr_equal = '1') ) or
			  ( (instr_vec(Instr_BLT) = '1') and (sub(RISCV_ARCH-1) = '1') ) or 
			  ( (instr_vec(Instr_BLTU) = '1') and (less = '1')     ) or 
			  ( (instr_vec(Instr_BNE) = '1') and (sub /= zero) )   ) then
			  
				branch := '1';
				
		end if;
		
		if branch = '1' then
			npc := i_pc + offset(CFG_CPU_ADDR_BITS-1 downto 0);
		elsif instr_vec(Instr_JAL) = '1' then
			npc := operand1(CFG_CPU_ADDR_BITS-1 downto 0) + offset(CFG_CPU_ADDR_BITS-1 downto 0);
		elsif instr_vec(Instr_JALR) = '1' then
			npc := operand1(CFG_CPU_ADDR_BITS-1 downto 0) + operand2(CFG_CPU_ADDR_BITS-1 downto 0);
		else
			npc := i_pc + 4;
		end if;
		
		res := (others => '0');
		
		if i_memop_load = '1' then
			res := (others => '0');
		elsif i_memop_store = '1' then 
			res := operand2;
		elsif instr_vec(Instr_JAL) = '1' then
			res(CFG_CPU_ADDR_BITS-1 downto 0) := npc;
		elsif instr_vec(Instr_JALR) = '1' then
			res(CFG_CPU_ADDR_BITS-1 downto 0) := npc;
		elsif (instr_vec(Instr_ADD) or instr_vec(Instr_ADDI) or instr_vec(Instr_AUIPC)) = '1' then
			res := sum;
		elsif (instr_vec(Instr_SUB) = '1' ) then
			res := sub;
		elsif ( instr_vec(Instr_SLL) or instr_vec(Instr_SLLI) ) = '1' then
			res := wb_sll;
		elsif ( instr_vec(Instr_SRL) or instr_vec(Instr_SRLI) ) = '1' then
			res := wb_srl;
		elsif ( instr_vec(Instr_SRA) or instr_vec(Instr_SRAI) ) = '1' then
			res := wb_sra;
		elsif ( instr_vec(Instr_AND) or instr_vec(Instr_ANDI) ) = '1' then
			res := and_r;
		elsif ( instr_vec(Instr_OR) or instr_vec(Instr_ORI) ) = '1' then
			res := or_r;
		elsif ( instr_vec(Instr_XOR) or instr_vec(Instr_XOR) ) = '1' then
			res := xor_r;
		elsif ( instr_vec(Instr_SLT) or instr_vec(Instr_SLTI) ) = '1' then
			res(RISCV_ARCH-1 downto 1) := (others => '0');
			res(0) := sub(RISCV_ARCH-1);
		elsif ( instr_vec(Instr_SLTU) or instr_vec(Instr_SLTIU) ) = '1' then
			res(RISCV_ARCH-1 downto 1) := (others => '0');
			res(0) := less;
		elsif ( instr_vec(Instr_LUI) = '1' ) then
			res := operand2;	
		end if;
		
		
		hazard := '0';
		
		if valid = '1' then --output to mem in next cycle
			v.valid 			:= '1';
			v.pc 				:= i_pc;
			v.npc 			:= npc;
			v.instr			:= i_instr;
			v.memop_load	:= i_memop_load;
			v.memop_store	:= i_memop_store;
			v.memop_size	:= i_memop_size;
			v.memop_addr	:= memop_addr;
			v.memop_wdata	:= res;
			v.memop_rd		:= i_rd_addr;
			v.memop_sign_ext := i_memop_sign_ext;
			wr_en		:= or_reduce(i_rd_addr); --immediately write_back value to circumvent data hazards
			hazard	:= i_memop_load; --for memory load operation, data not immediately available, so raise hazard bit for next cycle
		end if;
		
		if i_nrst = '0' then
			v := R_RESET;
		end if;
		
		o_d_npc <= r.npc; --feedback to fetch
		o_br_pred_dis <= br_pred_dis; --feedback to fetch
		o_d_rdy <= not hold; --to decode
		o_rd_addr <= i_rd_addr; -- to reg_bank
		o_rd_data <= res & hazard; --reg bits are 1 bit more than RISCV_ARCH
		o_wr_en	<= wr_en;
		
		o_valid <= r.valid;
		o_memop_sign_ext <= r.memop_sign_ext;
		o_memop_load <= r.memop_load;
		o_memop_store <= r.memop_store;
		o_memop_size <= r.memop_size;
		o_memop_addr <= r.memop_addr;
		o_memop_wdata <= r.memop_wdata;
		o_memop_rd <= r.memop_rd;
		o_pc <= r.pc;
		o_instr <= r.instr;
		
		rin <= v;
		
	end process;
	
	regs: process (i_clk, i_nrst)
	begin
		if i_nrst = '0' then
			r <= R_RESET;
		elsif rising_edge(i_clk) then
			r <= rin;
		end if;
	end process;
	

end archExecute;

