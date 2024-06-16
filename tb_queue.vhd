--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:31:25 05/20/2024
-- Design Name:   
-- Module Name:   /home/umar/code/riscv/my_riscv/myrva/tb_queue.vhd
-- Project Name:  myrva
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: queue
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_queue IS
END tb_queue;
 
ARCHITECTURE behavior OF tb_queue IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT queue
	 	generic (
		q_depth_bits 	: integer := 2;
		q_width_bits	: integer := 32
	);
    PORT(
         i_clk : IN  std_logic;
         i_nrst : IN  std_logic;
         i_wr_en : IN  std_logic;
         i_rd_en : IN  std_logic;
         i_data : IN  std_logic_vector(31 downto 0);
         o_data : OUT  std_logic_vector(31 downto 0);
         o_q_full : OUT  std_logic;
         o_q_nempty : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nrst : std_logic := '0';
   signal i_wr_en : std_logic := '0';
   signal i_rd_en : std_logic := '0';
   signal i_data : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal o_data : std_logic_vector(31 downto 0);
   signal o_q_full : std_logic;
   signal o_q_nempty : std_logic;

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
		type cache_type is array (0 to 32) of std_logic_vector(31 downto 0); --block

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: queue generic map (
			q_depth_bits => 2
	)
		PORT MAP (
          i_clk => i_clk,
          i_nrst => i_nrst,
          i_wr_en => i_wr_en,
          i_rd_en => i_rd_en,
          i_data => i_data,
          o_data => o_data,
          o_q_full => o_q_full,
          o_q_nempty => o_q_nempty
        );

   -- Clock process definitions
   i_clk_process :process
   begin
		i_clk <= '0';
		wait for i_clk_period/2;
		i_clk <= '1';
		wait for i_clk_period/2;
   end process;

	read_proc: process
	begin
	      wait for 100 ns;	
			i_rd_en <= '0';
			wait for i_clk_period*10;
			
			loop
				wait for i_clk_period;
				i_rd_en <= '1';
				wait for i_clk_period/2;
				i_rd_en <= '0';
				wait for i_clk_period/2;
			end loop;
			
			wait;
	end process;

   -- Stimulus process
   stim_proc: process
		variable icache_mem : cache_type;
		variable count : integer := 0;
   begin
			  --insertion sort--
		icache_mem(0 to 18) := ( 0 => x"00450693", 1 => x"00100713", 2 => x"00b76463", 3 => x"00008067",
										4 => x"0006a803", 5 => x"00068613", 6 => x"00070793", 7 => x"ffc62883",
										8 => x"01185a63", 9 => x"01162023", 10 => x"fff78793", 11 => x"ffc60613",
										12 => x"fe0796e3",13 => x"00279793",14 => x"00f507b3",15 => x"0107a023", 
										16 => x"00170713",17 => x"00468693",18 => x"fc1ff06f" );
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		i_nrst <= '1';
		i_wr_en <= '0';
		i_data <= (others => '0');
      wait for i_clk_period*10;
		
		for i in 0 to 3 loop
			i_data <= icache_mem(count);
			i_wr_en <= '1';
			wait for i_clk_period/2;
			i_wr_en <= '0';
			if (o_q_full = '0') then
				count := count + 1;
			end if;
			wait for i_clk_period/2;
			wait for i_clk_period;
		end loop;
		
		 for i in 4 to 7 loop
			i_data <= icache_mem(count);
			i_wr_en <= '1';
			wait for i_clk_period/2;
			i_wr_en <= '0';
			if (o_q_full = '0') then
				count := count + 1;
			end if;
			wait for i_clk_period/2;
			wait for i_clk_period;
		end loop;
		
		
      -- insert stimulus here 

      wait;
   end process;

END;
