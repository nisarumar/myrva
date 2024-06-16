--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
library commonlib;
use commonlib.types_common.all;

package types_axi_lite is

	constant CFG_AXI_ADDR_BITS 	: integer := 32;
	constant CFG_AXI_DATA_BITS		: integer := 32;
	constant CFG_AXI_DATA_BYTES	: integer := CFG_AXI_DATA_BITS/8;
	constant CFG_AXI_ADDR_OFFSET  : integer := log2(CFG_AXI_ADDR_BITS/8);
	constant inferred    			: integer := 0;
	
type axi4_lite_master_in_type is record
  --! Write Address channel.
  M_AXI_AWREADY : std_logic;
  --! Write Data channel.
  M_AXI_WREADY : std_logic;
  --! Write Response channel:
  M_AXI_BVAILD : std_logic;
  M_AXI_BRESP : std_logic_vector(1 downto 0);
  --! Read Address Channel
  M_AXI_ARREADY : std_logic;
  --! Read valid.
  M_AXI_RVALID : std_logic;
  --! @brief Read response. 
  --! @details This signal indicates the status of the read transfer. 
  --!  The responses are:
  --!      0b00 OKAY - Normal access success. Indicates that a normal access has
  --!                  been successful. Can also indicate an exclusive access
  --!                  has failed.
  --!      0b01 EXOKAY - Exclusive access okay. Indicates that either the read or
  --!                  write portion of an exclusive access has been successful.
  --!      0b10 SLVERR - Slave error. Used when the access has reached the slave 
  --!                  successfully, but the slave wishes to return an error
  --!                  condition to the originating master.
  --!      0b11 DECERR - Decode error. Generated, typically by an interconnect 
  --!                  component, to indicate that there is no slave at the
  --!                  transaction address.
  M_AXI_RRESP : std_logic_vector(1 downto 0);
  --! Read data
  M_AXI_RDATA: std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
end record;

constant axi4_lite_master_in_none : axi4_lite_master_in_type := (
	'0',
	'0',
	'0',
	(others => '0'),
	'0',
	'0',
	(others => '0'),
	(others => '0')
);


--! @brief Master device output signals
type axi4_lite_master_out_type is record
  --! Write Address channel:
  M_AXI_AWVALID : std_logic;
  M_AXI_AWADRR	 : std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
  M_AXI_AWPROT	 : std_logic_vector (2 downto 0);
  --! write data channel
  M_AXI_WVALID : std_logic;
  --! Write channel data value
  M_AXI_WDATA  : std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
  --! Write Data channel strob signals selecting certain bytes.
  M_AXI_WSTRB  : std_logic_vector(CFG_AXI_DATA_BITS/8-1 downto 0);
  
  --! Write Response channel accepted by master.
  M_AXI_BREADY : std_logic;
  
  --! Read Address Channel data valid.
  M_AXI_ARVALID : std_logic;
  --! Read Address channel
  M_AXI_ARADDR	: std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
  M_AXI_ARPROT	: std_logic;
  
  --! Read RESP channel:
  M_AXI_RREADY : std_logic;
end record;

constant axi4_lite_master_out_none : axi4_lite_master_out_type := (
	'0',
	(others => '0'),
	(others => '0'),
	'0',
	(others => '0'),
	(others => '0'),
	'0',
	'0',
	(others => '0'),
	'0',
	'0'
);

type aix4_lite_slave_in_type is record
	
	--write address channel input
	S_AXI_AWVALID	: std_logic;
	S_AXI_AWADDR	: std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
	S_AXI_AWPROT	: std_logic_vector(2 downto 0);
	--write data channel input
	S_AXI_WVALID	: std_logic;
	S_AXI_WDATA		: std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
	S_AXI_WSTRB		: std_logic_vector(CFG_AXI_DATA_BITS/8-1 downto 0);
	--write resp channel input
	S_AXI_BREADY		: std_logic;
	--read address channel input
	S_AXI_ARVALID	: std_logic;
	S_AXI_ARADDR	: std_logic_vector(CFG_AXI_ADDR_BITS-1 downto 0);
	S_AXI_ARPROT	: std_logic;
	--read resp channel input
	S_AXI_RREADY	: std_logic;
	
end record;

constant aix4_lite_slave_in_none : aix4_lite_slave_in_type := (
	'0',
	(others => '0'),
	(others => '0'),
	
	'0',
	(others => '0'),
	(others => '0'),
	
	'0',
	
	'0',
	(others => '0'),
	'0',
	
	'0'
);

type axi4_lite_slave_out_type is record
	
	--write address channel output
	S_AXI_AWREADY	: std_logic;
	--write data channel output
	S_AXI_WREADY	: std_logic;
	--write data resp channel output
	S_AXI_BVALID	: std_logic;
	S_AXI_BRESP		: std_logic_vector(1 downto 0);
	--read addr channel
	S_AXI_ARREADY	: std_logic;
	--read resp channel
	S_AXI_RVALID	: std_logic;
	S_AXI_RDATA		: std_logic_vector(CFG_AXI_DATA_BITS-1 downto 0);
	S_AXI_RRESP		: std_logic_vector(1 downto 0);
	
end record;

constant axi4_lite_slave_out_none : axi4_lite_slave_out_type := (
	'0',
	
	'0',
	
	'0',
	(others => '0'),
	
	'0',
	
	'0',
	(others => '0'),
	(others => '0')
);

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--

end types_axi_lite;

package body types_axi_lite is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end types_axi_lite;
