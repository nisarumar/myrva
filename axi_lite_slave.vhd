----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:59:54 05/26/2024 
-- Design Name: 
-- Module Name:    axi_lite_slave - arch_axi_slave 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axi_lite_slave is

		port(
		i_clk   : in std_logic;
		i_nrst  : in std_logic;
		
		i_slv	  : in aix4_lite_slave_in_type;
		o_slv	  : out axi4_lite_slave_out_type;
		
		i_rdy	  : in std_logic;
		i_rdata : in std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
		
		o_wr_addr	: out std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
		o_wr_strb	: out std_logic_vector(CFG_AXI_DATA_BITS/8-1 downto 0);
		o_wdata		: out std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
		o_wr_en		: out std_logic;
		
		o_rd_addr	: out std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0)
	);

end axi_lite_slave;

architecture arch_axi_slave of axi_lite_slave is

	type RegisterType is record
		axil_await_rd_resp 	: std_logic;
		axil_await_wr_resp	: std_logic;
		axil_bvalid				: std_logic;
		axil_rvalid				: std_logic;
		axil_arready			: std_logic;
		axil_arvalid			: std_logic;
		axil_awready			: std_logic;
		axil_awvalid			: std_logic;
		axil_wready				: std_logic;
		axil_wvalid				: std_logic;
		rd_addr					: std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
		rd_en						: std_logic;
		wr_en						: std_logic;
		wr_addr					: std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
		wr_data					: std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
		wr_strb					: std_logic_vector(CFG_AXI_DATA_BITS/8-1 downto 0);
		rd_data					: std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
	end record;
	
	constant R_RESET : RegisterType := (
		'0', '0', '0', '0', '0', '0', '0', '0','0','0',
		(others=>'0'), '0', '0',
		(others=>'0'), (others => '0'), (others => '0'),
		(others => '0')
	);
	
	signal r, rin : RegisterType;

begin

comb : process(i_nrst, i_slv, i_rdy, i_rdata, r)
	variable curr_axil_awready : std_logic;
	variable curr_axil_awvalid	: std_logic;
	variable curr_axil_wready	: std_logic;
	variable curr_axil_wvalid	: std_logic;
	variable next_wready			: std_logic;
	variable wr_en					: std_logic;
	variable next_rready			: std_logic;
	variable curr_axil_rdready : std_logic;
	variable curr_axil_bvalid	: std_logic;
	variable curr_axil_rvalid 	: std_logic;
	variable curr_axil_arvalid : std_logic;
	variable curr_wr_addr	   : std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
	variable curr_rd_addr	   : std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
	variable curr_wr_data		: std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
	variable curr_wr_strb		: std_logic_vector(CFG_AXI_DATA_BITS/8-1 downto 0);
	variable curr_rd_data		: std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
	variable v : RegisterType;
begin

	v := r;
	curr_axil_awready := '0';
	curr_axil_awvalid	:= '0';
	curr_axil_wready	:= '0';
	curr_axil_wvalid	:= '0';
	next_wready			:= '0';
	wr_en					:= '0';
	curr_axil_arvalid  := '0';
	
	curr_wr_addr := (others => '0');
	curr_wr_data := (others => '0');
	curr_wr_strb := (others => '0');
	curr_rd_addr := (others => '0');
	curr_rd_data := (others => '0');
	
	if (r.axil_awready = '1') then
		if (i_slv.S_AXI_AWVALID = '1') then
			curr_wr_addr := i_slv.S_AXI_AWADDR;
			curr_axil_awvalid := '1';
		end if;
	else
			curr_wr_addr := r.wr_addr;
			curr_axil_awvalid := r.axil_awvalid;
	end if;
	
	if (r.axil_wready = '1') then
		if (i_slv.S_AXI_WVALID = '1') then
			curr_wr_data	:= i_slv.S_AXI_WDATA;
			curr_wr_strb	:= i_slv.S_AXI_WSTRB;
			curr_axil_wvalid := '1';
		end if;
	else
		curr_wr_data := r.wr_data;
		curr_wr_strb := r.wr_strb;
		curr_axil_wvalid	:= r.axil_wvalid;
	end if;
	
	next_wready	:= (curr_axil_wvalid and curr_axil_awvalid) and (not r.axil_bvalid or i_slv.S_AXI_BREADY);
	
	if (next_wready = '1') then
		wr_en := '1';
		v.axil_awready := '1';
		v.axil_wready	:= '1';
		v.axil_bvalid 	:= '1';
	else
		v.axil_awready := not curr_axil_awvalid;
		v.axil_wready	:= not curr_axil_wvalid;
		v.axil_bvalid 	:= r.axil_bvalid and not i_slv.S_AXI_BREADY;
	end if;
	
	v.axil_wvalid := curr_axil_wvalid;
	v.axil_awvalid := curr_axil_awvalid;
	v.wr_addr	:= curr_wr_addr;
	v.wr_data	:= curr_wr_data;
	v.wr_strb	:= curr_wr_strb;
	
	if (r.axil_arready = '1') then
		if (i_slv.S_AXI_ARVALID = '1') then
			curr_axil_arvalid := '1';
			curr_rd_addr := i_slv.S_AXI_ARADDR;
		end if;
	else
		curr_rd_addr := r.rd_addr;
		curr_axil_arvalid := r.axil_arvalid;
	end if;
	
	next_rready := curr_axil_arvalid and (not r.axil_rvalid or i_slv.S_AXI_RREADY);
	
	if (next_rready = '1' and i_rdy = '1') then
		v.axil_arready := '1';
		v.axil_rvalid := '1';
	else
		v.axil_arready := not curr_axil_arvalid;
		v.axil_rvalid := r.axil_rvalid and not i_slv.S_AXI_RREADY;
	end if;
	
	v.axil_arvalid := curr_axil_arvalid;
	v.rd_addr := curr_rd_addr;
	
	o_slv.S_AXI_RVALID <= r.axil_rvalid;
	o_slv.S_AXI_RDATA  <= i_rdata; --expectation is to have synchronous output from the register
	o_slv.S_AXI_ARREADY <= r.axil_arready;
	o_rd_addr <= curr_rd_addr;
	
	o_wr_en <= wr_en;
	o_wr_addr <= curr_wr_addr;
	o_wr_strb <= curr_wr_strb;
	o_wdata <= curr_wr_data;
	o_slv.S_AXI_BVALID <= r.axil_bvalid;
	o_slv.S_AXI_AWREADY <= r.axil_awready;
	o_slv.S_AXI_WREADY <= r.axil_wready;
	
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

end arch_axi_slave;

