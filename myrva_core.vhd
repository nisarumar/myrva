----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:48:01 05/16/2024 
-- Design Name: 
-- Module Name:    core - archCore 
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

entity myrva_core is

port (
	i_clk					: in std_logic;
	i_nrst				: in std_logic;

--- Icache input to fetch
	i_mem_req_rdy		: in std_logic;	-- memory is able to accepts request
	i_mem_data_valid	: in std_logic;	-- memory output is valid
	i_mem_addr			: in std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	i_mem_data			: in std_logic_vector(31 downto 0);
   -- output to Icache
	o_mem_addr_valid	: out std_logic; --requested address is valid
	o_mem_addr			: out std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0); -- requested memory addr
	o_mem_resp_rdy		: out std_logic;	

	i_flush_pipeline	: in std_logic;
	i_mem_rdy			: in std_logic;
	
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
	

	
	o_exception			: out std_logic
	);
	
end myrva_core;

architecture archCore of myrva_core is

component fetch is
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
	
end component;

component decode is
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
end component;

component execute is
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
end component;

component reg_bank is
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

end component;

type FetchType is record
		hold				: std_logic; -- hold pipeline
		instr				: std_logic_vector(31 downto 0); -- riscv instruction 32 bit
		pc					: std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
		valid				: std_logic;	--output of fetch is valid
end record;

type DecodeType is record
	rs1					: std_logic_vector(5 downto 0);
	rs2					: std_logic_vector(5 downto 0);
	rd						: std_logic_vector(5 downto 0);
	imm					: std_logic_vector(RISCV_ARCH-1 downto 0);
	valid					: std_logic;
	pc						: std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	instr			   	: std_logic_vector(31 downto 0);
   memop_store 		: std_logic;                       
   memop_load 			: std_logic;                         
   memop_sign_ext 	: std_logic;                        -- Load memory value with sign extending
   memop_size 			: std_logic_vector(1 downto 0);         -- Memory transaction size
   isa_type 			: std_logic_vector(ISA_Total-1 downto 0); -- Instruction format accordingly with ISA
   instr_vec 			: std_logic_vector(Instr_Total-1 downto 0); -- One bit per decoded instruction bus
   exception 			: std_logic;                           -- Unimplemented instruction
end record;


type ExecuteType is record
	--output to reg_bank
	wr_en				: std_logic;
	rd_addr			: std_logic_vector (5 downto 0);
	rd_data			: std_logic_vector(RISCV_ARCH downto 0);
	
		-- output to fetch
	npc				: std_logic_vector(CFG_CPU_ADDR_BITS-1 downto 0);
	br_pred_dis		: std_logic;
	
	--output to decode
	rdy				: std_logic;

end record;

type RegsType is record
	
	rs1			: std_logic_vector(RISCV_ARCH downto 0);
	rs2			: std_logic_vector(RISCV_ARCH downto 0);

end record;

type Pipelinetype is record
	f : FetchType;
	d : DecodeType;
	e : ExecuteType;
end record;

signal reg: RegsType;
signal w : PipelineType;
signal pipeline_hold : std_logic;
signal fetch_pipeline_hold : std_logic;

begin

	pipeline_hold <= w.f.hold or not w.e.rdy;
	fetch_pipeline_hold <= not w.e.rdy;

	f0: fetch port map (
		i_clk	=> i_clk,
		i_nrst => i_nrst,
		i_pipeline_hold => fetch_pipeline_hold,
		i_mem_req_rdy	=> i_mem_req_rdy,
		i_mem_data_valid => i_mem_data_valid,
		i_mem_addr	=> i_mem_addr,
		i_mem_data	=> i_mem_data,
		i_flush_pipeline => i_flush_pipeline,
		i_e_npc	=> w.e.npc,
		i_br_pr_dis	=> w.e.br_pred_dis,
		
		o_mem_addr_valid => o_mem_addr_valid,
		o_mem_addr	=> o_mem_addr,
		o_mem_resp_rdy	=> o_mem_resp_rdy,
		o_hold => w.f.hold,
		o_instr => w.f.instr,
		o_pc	=> w.f.pc,
		o_valid => w.f.valid
	);

	dec0 :decode port map (
	i_clk	=> i_clk,
	i_nrst => i_nrst,
	i_hold => pipeline_hold,
	i_valid => w.f.valid,
	i_pc	=> w.f.pc,
	i_instr => w.f.instr,
	
	o_rs1	=> w.d.rs1,
	o_rs2	=> w.d.rs2,
	o_rd	=> w.d.rd,
	o_imm	=> w.d.imm,
	i_e_rdy => w.e.rdy,
	i_flush_pipeline => i_flush_pipeline,
	
	o_valid	=> w.d.valid,
	o_pc		=> w.d.pc,
	o_instr	=> w.d.instr,
   o_memop_store => w.d.memop_store,
   o_memop_load => w.d.memop_load,                         
   o_memop_sign_ext => w.d.memop_sign_ext,
   o_memop_size 	=> w.d.memop_size,
   o_isa_type 	=> w.d.isa_type,
   o_instr_vec => w.d.instr_vec,
   o_exception => w.d.exception
	);
	
	reg0: reg_bank port map(
		i_clk	=> i_clk,
		i_nrst => i_nrst,
		i_rs1Addr => w.d.rs1,
		i_rs2Addr => w.d.rs2,
		i_rdAddr => w.e.rd_addr,
		i_rd	=> w.e.rd_data,
		i_wr_en => w.e.wr_en,
		o_rs1	=> reg.rs1,
		o_rs2	=> reg.rs2
	);
	
	exec0: execute port map (
	
	i_clk => i_clk,
	i_nrst => i_nrst,
	i_rs1_addr	=> w.d.rs1,
	i_rs1	=> reg.rs1,
	i_rs2_addr => w.d.rs2,
	i_rs2	=> reg.rs2,
	i_rd_addr => w.d.rd,
	i_imm	=> w.d.imm,
	i_valid => w.d.valid,
	i_pc	=> w.d.pc,
	i_instr => w.d.instr,
   i_memop_store => w.d.memop_store,
   i_memop_load => w.d.memop_load,
   i_memop_sign_ext => w.d.memop_sign_ext,
   i_memop_size => w.d.memop_size,
   i_isa_type 	=> w.d.isa_type,
   i_instr_vec => w.d.instr_vec,
   i_exception => w.d.exception,
	
	i_mem_rdy => i_mem_rdy,
	
	--output to reg_bank
	o_wr_en	=> w.e.wr_en,
	o_rd_addr => w.e.rd_addr,
	o_rd_data	=> w.e.rd_data,
	
	-- output to mem
	o_pc		=> o_pc,
	o_memop_load => o_memop_load,
	o_memop_store	=> o_memop_store,
	o_memop_size => o_memop_size,
	o_memop_addr => o_memop_addr,
	o_memop_rd	=> o_memop_rd,
	o_memop_wdata	=> o_memop_wdata,
	o_memop_sign_ext => o_memop_sign_ext,
	o_valid	=> o_valid,
	o_instr	=> o_instr,
	
	-- output to fetch
	o_d_npc		=> w.e.npc,
	o_br_pred_dis	=> w.e.br_pred_dis,
	
	o_d_rdy	=> w.e.rdy
	);


end archCore;

