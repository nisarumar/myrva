----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:39:19 06/01/2024 
-- Design Name: 
-- Module Name:    axi_lite_master - arch_axi_master 
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
use commonlib.types_axi_lite.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axi_lite_master is
	PORT (
		i_clk 			: in std_logic;
		i_nrst			: in std_logic;
		
		i_mst 			: in axi4_lite_master_in_type;
		o_mst				: out axi4_lite_master_out_type;
		
		o_req_rdy		: out std_logic;
		o_data_valid	: out std_logic;
		o_mem_data		: out std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0); --rd_data
		
		
		i_valid			: in std_logic;
		i_we				: in std_logic;
	
		--output - data
		i_mem_addr			: in std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
		i_mem_data			: in std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
		i_mem_strb			: in std_logic_vector(CFG_AXI_DATA_BITS/8-1  downto 0)
		
	);
end axi_lite_master;

architecture arch_axi_master of axi_lite_master is
	constant FIFO_BITS 	: integer := 3;
	constant FIFO_LEN 	: integer := 2**FIFO_BITS;
	constant FIFO_FULL	: std_logic_vector(FIFO_BITS-1 downto 0) := std_logic_vector(to_unsigned(FIFO_LEN-1, FIFO_BITS));
	constant FIFO_AFULL	: std_logic_vector(FIFO_BITS-1 downto 0) := std_logic_vector(to_unsigned(FIFO_LEN-2, FIFO_BITS));

type RegisterType is record
	axi_awvalid : std_logic;
	axi_wvalid  : std_logic;
	axi_arvalid	: std_logic;
	ready			: std_logic;
	count			: std_logic_vector(FIFO_BITS-1 downto 0);
	--nearEmpty	: std_logic;
	nearFull		: std_logic;
	full			: std_logic;
	nempty			: std_logic;
	wr_en			: std_logic;
	mem_addr		: std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
	mem_data		: std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
	mem_strb		: std_logic_vector(CFG_AXI_DATA_BITS/8-1 downto 0);
end record;

constant R_RESET : RegisterType := (
	'0', '0', '0', '0',
	(others => '0'),
	'0',
	'0',
	'0',
	'0',
	(others =>'0'),
	(others => '0'),
	(others => '0')
);
	signal r, rin : RegisterType;

begin

comb : process(i_nrst, i_valid, i_we, i_mst, i_mem_addr, i_mem_data, i_mem_strb, r)
	variable v 						: RegisterType;
	variable curr_stall 			: std_logic;
	--variable curr_awvalid		: std_logic;
	--variable curr_wvalid			: std_logic;
	--variable curr_arvalid		: std_logic;
	variable count_ind			: std_logic_vector(1 downto 0);
	variable curr_valid			: std_logic;
	
	begin
	
	v := r;
	curr_stall 	:= '0';
	--curr_awvalid := '0';
	--curr_valid 	:= '0';
	--count_ind := (others => '0');
	
	if ( r.nearFull = '1' or (r.wr_en = not i_we and r.nempty = '1')) then --avoid counter overflow, 
			curr_stall := '1';
	elsif (r.axi_wvalid = '1' and i_mst.M_AXI_WREADY = '0') then  -- stall the input if in the previous cycle wvalid was high but AWREADY has not come up yet
			curr_stall := '1';
	elsif (r.axi_awvalid = '1' and i_mst.M_AXI_AWREADY = '0') then
			curr_stall := '1';
	elsif (r.axi_arvalid = '1' and i_mst.M_AXI_ARREADY = '0') then
			curr_stall := '1';
	end if;
	
	v.ready := not curr_stall;
	
	if ( curr_stall = '0' and i_valid = '1' ) then -- we should accept the input if we were ready
		v.mem_data := i_mem_data;
		v.mem_addr := i_mem_addr;
		v.mem_strb := i_mem_strb;
		v.wr_en 	  := i_we;
		if (i_we = '1') then
			v.axi_awvalid := '1';
			v.axi_wvalid := '1';
		else
			v.axi_arvalid := '1';
		end if;
	else -- if there was a stall or simply no valid input then based AXI_*READY signals; put down the valid signals
			v.axi_awvalid := not i_mst.M_AXI_AWREADY and r.axi_awvalid;
			v.axi_wvalid  := not i_mst.M_AXI_WREADY and r.axi_wvalid;
			v.axi_arvalid := not i_mst.M_AXI_ARREADY and r.axi_arvalid;
	end if;
	
		
	curr_valid := i_mst.M_AXI_RVALID or i_mst.M_AXI_BVAILD;
	
	count_ind := (i_valid and not curr_stall) & curr_valid;
	
	case count_ind is
		when "10" => 
				v.count := std_logic_vector(unsigned(r.count)+1);
				v.nearFull := and_reduce(r.count(FIFO_BITS-1 downto 1));
				v.full := and_reduce(r.count(FIFO_BITS-1 downto 0));
				v.nempty := or_reduce(r.count(FIFO_BITS-1 downto 0));
		when "01" => 
				v.count := std_logic_vector(unsigned(r.count)-1);
				v.full := '0';
				v.nearFull := r.full;
				v.nempty := or_reduce(r.count(FIFO_BITS-1 downto 1));
		when others => v.count := r.count;
				v.full := and_reduce(r.count(FIFO_BITS-1 downto 0));
	end case;
	
	
	if (i_nrst = '0') then
		v := R_RESET;
	end if;
	
	o_req_rdy <= v.ready;
	o_mem_data <= i_mst.M_AXI_RDATA;
	o_data_valid <= curr_valid;
	
	o_mst.M_AXI_AWVALID <= r.axi_awvalid;
	o_mst.M_AXI_WVALID	<= r.axi_wvalid;
	o_mst.M_AXI_ARVALID <= r.axi_arvalid;
	o_mst.M_AXI_WDATA <= r.mem_data;
	o_mst.M_AXI_ARADDR <= r.mem_addr;
	o_mst.M_AXI_AWADRR <= r.mem_addr;
	o_mst.M_AXI_WDATA <= r.mem_data;
	o_mst.M_AXI_WSTRB <= r.mem_strb;
	o_mst.M_AXI_BREADY	<= '1';
	o_mst.M_AXI_RREADY <= '1';
	
	rin <= v;
	end process;

regs: process (i_nrst, i_clk)
	begin
	
	if i_nrst = '0' then
		r <= R_RESET;
	elsif rising_edge(i_clk) then
		r <= rin;
	end if;
	
	end process;

end arch_axi_master;

