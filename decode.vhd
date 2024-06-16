----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:43:07 05/10/2024 
-- Design Name: 
-- Module Name:    decode - archDecode 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decode is
 port (
	i_clk					: in std_logic;
	i_nrst				: in std_logic;
	i_hold 				: in std_logic;
	i_valid				: in std_logic;
	i_pc					: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	i_instr 				: in std_logic_vector(31 downto 0);
	
	o_rs1					: out std_logic_vector(5 downto 0);
	o_rs2					: out std_logic_vector(5 downto 0);
	o_rd					: out std_logic_vector(5 downto 0);
	o_imm					: out std_logic_vector(RISCV_ARCH-1 downto 0);
	i_e_rdy				: in std_logic;
	i_flush_pipeline	: in std_logic;
	
	o_valid				: out std_logic;
	o_pc					: out std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	o_instr			   : out std_logic_vector(31 downto 0);
   o_memop_store 		: out std_logic;                       
   o_memop_load 		: out std_logic;                         
   o_memop_sign_ext 	: out std_logic;                        -- Load memory value with sign extending
   o_memop_size 		: out std_logic_vector(1 downto 0);         -- Memory transaction size
   o_isa_type 			: out std_logic_vector(ISA_Total-1 downto 0); -- Instruction format accordingly with ISA
   o_instr_vec 		: out std_logic_vector(Instr_Total-1 downto 0); -- One bit per decoded instruction bus
   o_exception 		: out std_logic                             -- Unimplemented instruction
 );
end decode;

architecture archDecode of decode is
-- LB, LH, LW, LD, LBU, LHU, LWU
  constant OPCODE_LB     : std_logic_vector(4 downto 0) := "00000";
  -- FENCE, FENCE_I
  constant OPCODE_FENCE  : std_logic_vector(4 downto 0) := "00011";
  --  ADDI, ANDI, ORI, SLLI, SLTI, SLTIU, SRAI, SRLI, XORI
  constant OPCODE_ADDI   : std_logic_vector(4 downto 0) := "00100";
  -- AUIPC
  constant OPCODE_AUIPC  : std_logic_vector(4 downto 0) := "00101";
  -- ADDIW, SLLIW, SRAIW, SRLIW
  constant OPCODE_ADDIW  : std_logic_vector(4 downto 0) := "00110";
  -- SB, SH, SW, SD
  constant OPCODE_SB     : std_logic_vector(4 downto 0) := "01000";
  -- FSD
  constant OPCODE_FPU_SD : std_logic_vector(4 downto 0) := "01001";
  -- ADD, AND, OR, SLT, SLTU, SLL, SRA, SRL, SUB, XOR, DIV, DIVU, MUL, REM, REMU
  constant OPCODE_ADD    : std_logic_vector(4 downto 0) := "01100";
  -- LUI
  constant OPCODE_LUI    : std_logic_vector(4 downto 0) := "01101";
  -- ADDW, SLLW, SRAW, SRLW, SUBW, DIVW, DIVUW, MULW, REMW, REMUW
  constant OPCODE_ADDW   : std_logic_vector(4 downto 0) := "01110";
  -- BEQ, BNE, BLT, BGE, BLTU, BGEU
  constant OPCODE_BEQ    : std_logic_vector(4 downto 0) := "11000";
  -- JALR
  constant OPCODE_JALR   : std_logic_vector(4 downto 0) := "11001";
  -- JAL
  constant OPCODE_JAL    : std_logic_vector(4 downto 0) := "11011";
  
  constant INSTR_NONE : std_logic_vector(Instr_Total-1 downto 0) := (others => '0');

  type RegistersType is record
      valid : std_logic;
      pc : std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
      isa_type : std_logic_vector(ISA_Total-1 downto 0);
      instr_vec : std_logic_vector(Instr_Total-1 downto 0);
      instr : std_logic_vector(31 downto 0);
      memop_store : std_logic;
      memop_load : std_logic;
      memop_sign_ext : std_logic;
      memop_size : std_logic_vector(1 downto 0);
      unsigned_op : std_logic;
      instr_unimplemented : std_logic;
      rs1 : std_logic_vector(5 downto 0);
      rs2 : std_logic_vector(5 downto 0);
      rd : std_logic_vector(5 downto 0);
      imm : std_logic_vector(RISCV_ARCH-1 downto 0);
  end record;
  
    constant R_RESET : RegistersType := (
    '0', (others => '0'), (others => '0'),   -- valid, pc, isa_type
    (others => '0'), (others => '0'), '0',   -- instr_vec, instr, memop_store
    '0', '0', "00",                          -- memop_load, memop_sign_ext, memop_size
    '0',				                          	-- unsigned_op
    '0',                                     -- instr_unimpl
     (others => '0'),                        -- rs1
     (others => '0'),                        -- rs2
     (others => '0'),                        -- rd
     (others => '0')                        	-- imm
  );

  signal r, rin : RegistersType;
  
begin

	comb : process (i_nrst, i_hold, i_valid, i_pc, i_instr, i_e_rdy, i_flush_pipeline, r)
		variable v: RegistersType;
		variable curr_instr 		: std_logic_vector(31 downto 0);
		variable curr_opcode1 	: std_logic_vector(4 downto 0);
		variable curr_opcode2 	: std_logic_vector(2 downto 0);
		variable curr_isa_type 	: std_logic_vector(ISA_Total-1 downto 0);
		variable instr_decode 	: std_logic_vector(Instr_Total-1 downto 0);
		variable curr_rs1			: std_logic_vector(5 downto 0);
		variable curr_rs2			: std_logic_vector(5 downto 0);
		variable curr_rd			: std_logic_vector(5 downto 0);
		variable curr_imm			: std_logic_vector(RISCV_ARCH-1 downto 0);
		variable curr_error 		: std_logic;
		variable curr_valid		: std_logic;
	begin
		v := r;
		curr_instr := i_instr;
		curr_opcode1 := curr_instr(6 downto 2);
		curr_opcode2 := curr_instr(14 downto 12);
		instr_decode := (others => '0');
		curr_isa_type := (others => '0');
		curr_rs1		  := (others => '0');
		curr_rs2 	  := (others => '0');
		curr_rd		  := (others => '0');
		curr_imm		  := (others => '0');
		curr_error	  := '0';
		
		case curr_opcode1 is
		
			when OPCODE_ADD =>
				curr_isa_type(ISA_R_TYPE) := '1';
				curr_rs1 := '0' & curr_instr(19 downto 15);
            curr_rs2 := '0' & curr_instr(24 downto 20);
            curr_rd	 := '0' & curr_instr(11 downto 7);
				case curr_opcode2 is
            when "000" =>
                if curr_instr(31 downto 25) = "0000000" then
                    instr_decode(Instr_ADD) := '1';
                elsif curr_instr(31 downto 25) = "0100000" then
                    instr_decode(Instr_SUB) := '1';
                else
                    curr_error := '1';
                end if;
            when "001" =>
                if curr_instr(31 downto 25) = "0000000" then
                    instr_decode(Instr_SLL) := '1';
                else 
                    curr_error := '1';
                end if;
            when "010" =>
                if curr_instr(31 downto 25) = "0000000" then
                    instr_decode(Instr_SLT) := '1';
                else 
                    curr_error := '1';
                end if;
				when "011" =>
                if curr_instr(31 downto 25) = "0000000" then
                    instr_decode(Instr_SLTU) := '1';
                else 
                    curr_error := '1';
                end if;
            when "100" =>
                if curr_instr(31 downto 25) = "0000000" then
                    instr_decode(Instr_XOR) := '1';
                else 
                    curr_error := '1';
                end if;
            when "101" =>
                if curr_instr(31 downto 25) = "0000000" then
                    instr_decode(Instr_SRL) := '1';
                elsif curr_instr(31 downto 25) = "0100000" then
                    instr_decode(Instr_SRA) := '1';
                else
                    curr_error := '1';
                end if;
            when "110" =>
                if curr_instr(31 downto 25) = "0000000" then
                    instr_decode(Instr_OR) := '1';
                else
                    curr_error := '1';
                end if;
            when "111" =>
                if curr_instr(31 downto 25) = "0000000" then
                    instr_decode(Instr_AND) := '1';
                else
                    curr_error := '1';
                end if;
            when others =>
                curr_error := '1';
         end case;
				
			when OPCODE_ADDI =>
				
            curr_isa_type(ISA_I_type) := '1';
            curr_rs1 := '0' & curr_instr(19 downto 15);
            curr_rd := '0' & curr_instr(11 downto 7);             -- rd
            curr_imm(11 downto 0) := curr_instr(31 downto 20);
            curr_imm(RISCV_ARCH-1 downto 12) := (others => curr_instr(31));
				
            case curr_opcode2 is
            when "000" =>
                instr_decode(Instr_ADDI) := '1';
            when "001" =>
                instr_decode(Instr_SLLI) := '1';
            when "010" =>
                instr_decode(Instr_SLTI) := '1';
            when "011" =>
                instr_decode(Instr_SLTIU) := '1';
            when "100" =>
                instr_decode(Instr_XORI) := '1';
            when "101" =>
                if curr_instr(31 downto 26) = "000000" then
                    instr_decode(Instr_SRLI) := '1';
                elsif curr_instr(31 downto 26) = "010000" then
                    instr_decode(Instr_SRAI) := '1';
                else
                    curr_error := '1';
                end if;
            when "110" =>
                instr_decode(Instr_ORI) := '1';
            when "111" =>
                instr_decode(Instr_ANDI) := '1';
            when others =>
                curr_error := '1';
            end case;
			
			when OPCODE_AUIPC =>
            curr_isa_type(ISA_U_type) := '1';
            instr_decode(Instr_AUIPC) := '1';
            curr_rd := '0' & curr_instr(11 downto 7);             -- rd
            curr_imm(31 downto 12) := curr_instr(31 downto 12);
				
			when OPCODE_BEQ =>
            curr_isa_type(ISA_SB_type) := '1';
            curr_rs1 := '0' & curr_instr(19 downto 15);
            curr_rs2 := '0' & curr_instr(24 downto 20);
            curr_imm(11 downto 1) := curr_instr(7) & curr_instr(30 downto 25) & curr_instr(11 downto 8);
            curr_imm(RISCV_ARCH-1 downto 12) := (others => curr_instr(31));
				
            case curr_opcode2 is
            when "000" =>
                instr_decode(Instr_BEQ) := '1';
            when "001" =>
                instr_decode(Instr_BNE) := '1';
            when "100" =>
                instr_decode(Instr_BLT) := '1';
            when "101" =>
                instr_decode(Instr_BGE) := '1';
            when "110" =>
                instr_decode(Instr_BLTU) := '1';
            when "111" =>
                instr_decode(Instr_BGEU) := '1';
            when others =>
                curr_error := '1';
            end case;			
				
			when OPCODE_JAL =>
            curr_isa_type(ISA_UJ_type) := '1';
            instr_decode(Instr_JAL) := '1';
            curr_rd := '0' & curr_instr(11 downto 7);             -- rd
            curr_imm(19 downto 1) := curr_instr(19 downto 12) & curr_instr(20) & curr_instr(30 downto 21);
            curr_imm(RISCV_ARCH-1 downto 20) := (others => curr_instr(31));
				
			when OPCODE_JALR =>
            curr_isa_type(ISA_I_type) := '1';
            curr_rs1 := '0' & curr_instr(19 downto 15);
            curr_rd := '0' & curr_instr(11 downto 7);             -- rd
            curr_imm(11 downto 0) := curr_instr(31 downto 20);
            curr_imm(RISCV_ARCH-1 downto 12) := (others => curr_instr(31));
				
            case curr_opcode2 is
            when "000" =>
                instr_decode(Instr_JALR) := '1';
            when others =>
                curr_error := '1';
            end case;
				
			when OPCODE_LB =>
            curr_isa_type(ISA_I_type) := '1';
            curr_rs1 := '0' & curr_instr(19 downto 15);
            curr_rd 	:= '0' & curr_instr(11 downto 7);             -- rd
            curr_imm(11 downto 0) := curr_instr(31 downto 20);
            curr_imm(RISCV_ARCH-1 downto 12) := (others => curr_instr(31));
				
            case curr_opcode2 is
            when "000" =>
                instr_decode(Instr_LB) := '1';
            when "001" =>
                instr_decode(Instr_LH) := '1';
            when "010" =>
                instr_decode(Instr_LW) := '1';
            when "100" =>
                instr_decode(Instr_LBU) := '1';
            when "101" =>
                instr_decode(Instr_LHU) := '1';
            when others =>
                curr_error := '1';
            end case;
			
			when OPCODE_LUI =>
            curr_isa_type(ISA_U_type) := '1';
            instr_decode(Instr_LUI) := '1';
            curr_rd := '0' & curr_instr(11 downto 7);             -- rd
            curr_imm(31 downto 12) := curr_instr(31 downto 12);
				
			when OPCODE_SB =>
            curr_isa_type(ISA_S_type) := '1';
            curr_rs1 := '0' & curr_instr(19 downto 15);
            curr_rs2 := '0' & curr_instr(24 downto 20);
            curr_imm(11 downto 0) := curr_instr(31 downto 25) & curr_instr(11 downto 7);
            curr_imm(RISCV_ARCH-1 downto 12) := (others => curr_instr(31));
            case curr_opcode2 is
            when "000" =>
                instr_decode(Instr_SB) := '1';
            when "001" =>
					 instr_decode(Instr_SH) := '1';
            when "010" =>
                instr_decode(Instr_SW) := '1';
            when others =>
                curr_error := '1';
            end case;
         
			when others =>
				curr_error := '1';
				
			end case;
			
	if i_flush_pipeline = '1' then
		v.pc := (others => '1');
		v.valid := '0';
	elsif i_e_rdy = '1' and i_valid = '1' then
		  v.valid := '1';
        v.pc := i_pc;
        v.instr := i_instr;
        v.isa_type := curr_isa_type;
        v.instr_vec := instr_decode;
		  
        v.memop_store := instr_decode(Instr_SW) or instr_decode(Instr_SH) or instr_decode(Instr_SB);
        v.memop_load := instr_decode(Instr_LW) or instr_decode(Instr_LH) or instr_decode(Instr_LB)
							 or instr_decode(Instr_LHU) or instr_decode(Instr_LBU);
							
        v.memop_sign_ext := instr_decode(Instr_LW)	or instr_decode(Instr_LH) or instr_decode(Instr_LB);
										

        if (instr_decode(Instr_LW) or instr_decode(Instr_LWU) or instr_decode(Instr_SW)) = '1' then
            v.memop_size := MEMOP_4B;
        elsif (instr_decode(Instr_LH) or instr_decode(Instr_LHU) or instr_decode(Instr_SH)) = '1' then
            v.memop_size := MEMOP_2B;
        else
            v.memop_size := MEMOP_1B;
        end if;

        v.instr_unimplemented := curr_error;
        v.rs1 := curr_rs1;
        v.rs2 := curr_rs2;
        v.rd := curr_rd;
        v.imm := curr_imm;
		  
	elsif i_hold = '1' then
		v.valid := '0';
	end if;
	
	curr_valid := r.valid;
	
	if i_nrst = '0' then
        v := R_RESET;
    end if;
		
	o_valid <= curr_valid;
	o_pc <= r.pc;
	o_instr <= r.instr;
   o_memop_load <= r.memop_load;
   o_memop_store <= r.memop_store;
   o_memop_sign_ext <= r.memop_sign_ext;
   o_memop_size <= r.memop_size;
   o_isa_type <= r.isa_type;
   o_instr_vec <= r.instr_vec;
   o_exception <= r.instr_unimplemented;
   o_rs1 <= r.rs1;
   o_rs2 <= r.rs2;
   o_rd <= r.rd;
   o_imm <= r.imm;
    
   rin <= v;
		
	end process;
	
	  -- registers:
 regs : process(i_clk, i_nrst)
  begin 
     if i_nrst = '0' then
        r <= R_RESET;
     elsif rising_edge(i_clk) then 
        r <= rin;
     end if; 
  end process;

end archDecode;

