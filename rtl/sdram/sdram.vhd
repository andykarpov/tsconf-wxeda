-------------------------------------------------------------------[03.08.2014]
-- SDRAM Controller
-------------------------------------------------------------------------------
-- V1.0		03.08.2014	Initial release

-- CLK		= 84 MHz	= 11.9 ns
-- WR/RD	= 5T		= 59.5 ns  
-- RFSH		= 6T		= 71.4 ns

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sdram is
	port(
		CLK			: in std_logic;
		clk_28MHz		: in std_logic;
		c0 			: in std_logic;
		c1 			: in std_logic;
		c2 			: in std_logic;
		c3 			: in std_logic;
		curr_cpu		: in std_logic;
		-- Memory port
		loader			: in std_logic;
		bsel  			: in std_logic_vector(1 downto 0); -- Active HI
		A			: in std_logic_vector(23 downto 0);
		DI			: in std_logic_vector(15 downto 0);
		DO			: out std_logic_vector(15 downto 0);
		DO_cpu	   		: out std_logic_vector(15 downto 0);
		dram_stb		: out std_logic;
		---------------------------- 
		REQ	 		: in std_logic;
		RNW			: in std_logic;
		RFSH			: in std_logic;  --< REFRESH command NOT USED
		RFSHREQ			: out std_logic; --> request for refresh 
		IDLE			: out std_logic; --> 
		-- SDRAM Pin
		CK			: out std_logic;
		CKE			: out std_logic;
		RAS_n			: out std_logic;
		CAS_n			: out std_logic;
		WE_n			: out std_logic;
		BA1			: out std_logic;
		BA0			: out std_logic;
		MA			: out std_logic_vector(12 downto 0);
		DQ			: inout std_logic_vector(15 downto 0);
		DQML        		: out std_logic;
		DQMH        		: out std_logic;
		--
		TST		   : out std_logic_vector(3 downto 0)
		);
end sdram;

architecture rtl of sdram is
	signal state 		: unsigned(4 downto 0) := "00000";
	signal addr_in 	: std_logic_vector(23 downto 0);
	signal address 	: std_logic_vector(23 downto 0);
	signal bsel_int 	: std_logic_vector(1 downto 0);
	signal rfsh_cnt 	: unsigned(9 downto 0) := "0000000000";
	signal rfsh_req	: std_logic := '0';
	signal data_reg	: std_logic_vector(15 downto 0);
	signal cpu_reg		: std_logic_vector(15 downto 0);
	signal data_in	   : std_logic_vector(15 downto 0);
	signal idle1		: std_logic;
	signal st_rfsh		: std_logic;
	signal req_dis		: std_logic;
	------------------------------
	signal WR_in		: std_logic;
	signal WR_in1		: std_logic;
--	signal WR_r		   : std_logic;
	signal RD_in		: std_logic;
	signal RD_in1		: std_logic;
--	signal RD_r		   : std_logic;
	signal REQ_in		: std_logic;
	signal RNW_in		: std_logic;
	signal rd_op		: std_logic;
	signal RFSH_in		: std_logic;
	-- SD-RAM control signals
	signal sdr_cmd		: std_logic_vector(2 downto 0);
	signal sdr_ba0		: std_logic;
	signal sdr_ba1		: std_logic;
	signal sdr_dqml   : std_logic;
	signal sdr_dqmh   : std_logic;
	signal sdr_a		: std_logic_vector(12 downto 0);
	signal sdr_dq		: std_logic_vector(15 downto 0);

	constant SdrCmd_xx 	: std_logic_vector(2 downto 0) := "111"; -- no operation
	constant SdrCmd_ac 	: std_logic_vector(2 downto 0) := "011"; -- activate
	constant SdrCmd_rd 	: std_logic_vector(2 downto 0) := "101"; -- read
	constant SdrCmd_wr 	: std_logic_vector(2 downto 0) := "100"; -- write		
	constant SdrCmd_pr 	: std_logic_vector(2 downto 0) := "010"; -- precharge all
	constant SdrCmd_re 	: std_logic_vector(2 downto 0) := "001"; -- refresh
	constant SdrCmd_ms 	: std_logic_vector(2 downto 0) := "000"; -- mode regiser set

-- Init-------------------------------------------------------------------		Idle		Read-------		Write------		Refresh-------
-- 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12	13 14 15 16	17		18			19 1A 16 17		1B 1C 16 17		13 14 15 16 17
-- pr xx xx re xx xx xx xx xx xx re xx xx xx xx xx xx ms xx xx xx xx xx	xx		xx/ac/re	xx rd xx xx		xx wr xx xx		xx xx xx xx xx

begin

   TST(0) <= WR_in;       --idle1; --RD_in;
	TST(1) <= data_in(0);  --idle1; --
	TST(2) <= idle1;  --
	TST(3) <= st_rfsh;
	
	process (clk_28MHz, c3, DI, A, c0)
	begin 
		if rising_edge (clk_28MHz) and (c3 = '1') then --next_cycle
			if (REQ = '1' and RNW = '1') 	then 
				RD_in 	<= '1';
			elsif (REQ = '1' and RNW = '0') then
				WR_in   <= '1';
			else
				RFSH_in 	<= '1';
			end if;
		end if;
			data_in <= DI;
			addr_in <= A;
		if rising_edge (clk_28MHz) and (c0 = '1') then --NOT WORK
			RD_in 	<= '0';
			WR_in 	<= '0';
			RFSH_in 	<= '0';
		end if;
	end process;
	
	process (CLK)
	begin
		if CLK'event and CLK = '0' then
			---------------------------------------------------------				
			case state is
				-- Init
				when "00000" =>						-- s00
					sdr_cmd <= SdrCmd_pr;			-- PRECHARGE
					sdr_a <= "1111111111111";
					sdr_ba1 <= '0';
					sdr_ba0 <= '0';
					sdr_dqml <= '1';
					sdr_dqmh <= '1';
					state <= state + 1;
				when "00011" | "01010" =>			-- s03 s0A
					sdr_cmd <= SdrCmd_re;			-- REFRESH
					state <= state + 1;
				when "10001" =>						-- s11
					sdr_cmd <= SdrCmd_ms;			-- LOAD MODE REGISTER
					sdr_a <= "000" & "1" & "00" & "010" & "0" & "000";				
					state <= state + 1;

				-- Idle		
				when "11000" =>						-- s18				
					sdr_dq <= (others => 'Z');
					if RD_in = '1' then
						idle1 <= '0';
						bsel_int <= bsel;  
						address <= addr_in;        -- LOCK ADDR
						sdr_cmd <= SdrCmd_ac;		-- ACTIVE
						sdr_ba1 <= addr_in(10);          -- A(11)
						sdr_ba0 <= addr_in(9);           -- A(10)
						sdr_a <= addr_in(23 downto 11);	-- RAW_ADDR(12..0) 				 
						state <= "11001";			   -- s19 Read = when "11010"
					elsif WR_in = '1' and (loader = '1' or addr_in(23) = '0') then --Rising UP
						idle1   <= '0';
						rd_op   <= '0';
						bsel_int <= bsel;
						address <= addr_in;
						sdr_cmd <= SdrCmd_ac;		-- ACTIVE
						sdr_ba1 <= addr_in(10);
						sdr_ba0 <= addr_in(9);
						sdr_a <= addr_in(23 downto 11);
						state <= "11011";			   -- s1B Write
					elsif RFSH_in = '1' then
						idle1   <= '0';
						rd_op   <= '0';
						st_rfsh <= '1';
						rfsh_req <= '0';
						sdr_cmd <= SdrCmd_re;	-- REFRESH
						state <= "10011";			-- s13
					else
						sdr_cmd <= SdrCmd_xx;	-- NOP
					   idle1   <= '1';
						rd_op   <= '0';
						st_rfsh <= '0';
					end if;

				-- A24 A23 A22 A21 A20 A19 A18 A17 A16 A15 A14 A13 A12 A11 A10 A9 A8 A7 A6 A5 A4 A3 A2 A1 A0
				-- -----------------------ROW------------------------- BA1 BA0 -----------COLUMN------------		
				-- Single read - with auto precharge
				when "11010" =>						-- s1A
					sdr_cmd <= SdrCmd_rd;			-- READ (A10 = 1 enable auto precharge; A9..0 = column)
					sdr_a <= "0010" & address(8 downto 0);
					sdr_dqml <= '0';
					sdr_dqmh <= '0';
					state <= "10110";				-- s16
					rd_op <= '1';
				-- Single write - with auto precharge
				when "11100" =>						-- s1C
					sdr_cmd <= SdrCmd_wr;			-- WRITE (A10 = 1 enable auto precharge; A9..0 = column)
					sdr_a <= "0010" & address(8 downto 0); 
					sdr_dqml <= not bsel_int(0);
					sdr_dqmh <= not bsel_int(1);	
					sdr_dq <= data_in;
					state <= "10110";				-- s16
					
				when others =>
					sdr_dq <= (others => 'Z');
					sdr_cmd <= SdrCmd_xx;			-- NOP
					state <= state + 1;
			end case;

			-- Providing a distributed AUTO REFRESH command every 7.81us
			if rfsh_cnt = "1010010001" then	-- (84MHz * 1000 * 64 / 8192) = 657 %10 1001 0001
				rfsh_cnt <= (others => '0');
				rfsh_req <= '1';
			else
				rfsh_cnt <= rfsh_cnt + 1;
			end if;
			
		end if;
	end process;
	
	process (CLK, rd_op)
	begin --------------CLK = '0'------OK------------
		if CLK'event and CLK = '1' and rd_op = '1' then ---idle1 = '0' then
			if state = "11000" then				-- s18
				data_reg <= DQ;
				if curr_cpu = '1' then
					cpu_reg <= DQ;
				end if;
			end if;
		end if;
	end process;
	
	IDLE	<= idle1;
	DO 	<= data_reg;
	DO_cpu  <= cpu_reg;
	RFSHREQ	<= rfsh_req;
	CK 	<= CLK;
	CKE 	<= '1';
	RAS_n 	<= sdr_cmd(2);
	CAS_n 	<= sdr_cmd(1);
	WE_n 	<= sdr_cmd(0);
	DQML 	<= sdr_dqml;
	DQMH 	<= sdr_dqmh;
	BA1 	<= sdr_ba1;
	BA0 	<= sdr_ba0;
	MA 	<= sdr_a;
	DQ 	<= sdr_dq;
	dram_stb <= rd_op;

end rtl;