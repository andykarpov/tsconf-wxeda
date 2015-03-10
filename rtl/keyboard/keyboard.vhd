-------------------------------------------------------------------[07.09.2014]
-- KEYBOARD CONTROLLER USB HID scan to Spectrum matrix conversion
-------------------------------------------------------------------------------
-- V0.1 	05.10.2011	первая версия
-- V0.2		16.03.2014	измененмия в key_f (активная клавиша теперь устанавливается в '1')
-- V1.0		24.07.2014	доработан под USB HID Keyboard
-- V1.1		28.07.2014	добавлены спец клавиши
-- V1.2		31.07.2014	добавлен транслятор в сканкод PS/2
-- V1.3		07.09.2014	изменение в назначениях и спец клавишах

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity keyboard is
port (
	CLK		: in std_logic;
	RESET		: in std_logic;
	A		: in std_logic_vector(7 downto 0);
	KEYB		: out std_logic_vector(4 downto 0);
	KEYF		: out std_logic_vector(4 downto 0);
	KEYJOY		: out std_logic_vector(4 downto 0);
	SCANCODE	: out std_logic_vector(7 downto 0);
	RX		: in std_logic);
end keyboard;

architecture rtl of keyboard is
-- Interface to RX block
signal keyb_data	: std_logic_vector(7 downto 0);

-- Internal signals
type key_matrix is array (11 downto 0) of std_logic_vector(4 downto 0);
signal keys		: key_matrix;
signal row0, row1, row2, row3, row4, row5, row6, row7 : std_logic_vector(4 downto 0);
signal scan		: std_logic_vector(7 downto 0);

begin

	inst_rx : entity work.receiver
	port map (
		CLK      => CLK,
		nRESET   => not RESET,
		RX       => RX,
		DATA     => keyb_data
		);

	-- Output addressed row to ULA
	row0 <= keys(0) when A(0) = '0' else (others => '1');
	row1 <= keys(1) when A(1) = '0' else (others => '1');
	row2 <= keys(2) when A(2) = '0' else (others => '1');
	row3 <= keys(3) when A(3) = '0' else (others => '1');
	row4 <= keys(4) when A(4) = '0' else (others => '1');
	row5 <= keys(5) when A(5) = '0' else (others => '1');
	row6 <= keys(6) when A(6) = '0' else (others => '1');
	row7 <= keys(7) when A(7) = '0' else (others => '1');
	KEYB <= row0 and row1 and row2 and row3 and row4 and row5 and row6 and row7;

	KEYJOY 		<= keys(8);
	KEYF 		<= keys(9);
	SCANCODE	<= scan;

	process (RESET, CLK, keyb_data)
	begin
		if RESET = '1' then
			keys(0) <= (others => '1');
			keys(1) <= (others => '1');
			keys(2) <= (others => '1');
			keys(3) <= (others => '1');
			keys(4) <= (others => '1');
			keys(5) <= (others => '1');
			keys(6) <= (others => '1');
			keys(7) <= (others => '1');
			keys(8) <= (others => '0');
			keys(9) <= (others => '0');
			scan <= (others => '0');
			
		elsif CLK'event and CLK = '1' then
			case keyb_data is
				when X"02" =>
					keys(0) <= (others => '1');
					keys(1) <= (others => '1');
					keys(2) <= (others => '1');
					keys(3) <= (others => '1');
					keys(4) <= (others => '1');
					keys(5) <= (others => '1');
					keys(6) <= (others => '1');
					keys(7) <= (others => '1');
					keys(8) <= (others => '0');
					keys(9) <= (others => '0');
					scan <= x"FF";


				when X"e1" => keys(0)(0) <= '0'; -- Left shift (CAPS SHIFT)
					scan <= x"12";
				when X"e5" => keys(7)(1) <= '0'; -- Right shift (SYMB SHIFT)
					scan <= x"59";
				when X"1d" => keys(0)(1) <= '0'; -- Z
					scan <= x"1a";
				when X"1b" => keys(0)(2) <= '0'; -- X
					scan <= x"22";
				when X"06" => keys(0)(3) <= '0'; -- C
					scan <= x"21";
				when X"19" => keys(0)(4) <= '0'; -- V
					scan <= x"2a";
				--
				when X"04" => keys(1)(0) <= '0'; -- A
					scan <= x"1c";
				when X"16" => keys(1)(1) <= '0'; -- S
					scan <= x"1b";
				when X"07" => keys(1)(2) <= '0'; -- D
					scan <= x"23";
				when X"09" => keys(1)(3) <= '0'; -- F
					scan <= x"2b";
				when X"0a" => keys(1)(4) <= '0'; -- G
					scan <= x"34";
				--
				when X"14" => keys(2)(0) <= '0'; -- Q
					scan <= x"15";
				when X"1a" => keys(2)(1) <= '0'; -- W
					scan <= x"1d";
				when X"08" => keys(2)(2) <= '0'; -- E
					scan <= x"24";
				when X"15" => keys(2)(3) <= '0'; -- R
					scan <= x"2d";
				when X"17" => keys(2)(4) <= '0'; -- T
					scan <= x"2c";
				--
				when X"1e" => keys(3)(0) <= '0'; -- 1
					scan <= x"16";
				when X"1f" => keys(3)(1) <= '0'; -- 2
					scan <= x"1e";
				when X"20" => keys(3)(2) <= '0'; -- 3
					scan <= x"26";
				when X"21" => keys(3)(3) <= '0'; -- 4
					scan <= x"25";
				when X"22" => keys(3)(4) <= '0'; -- 5
					scan <= x"2e";
				--
				when X"27" => keys(4)(0) <= '0'; -- 0
					scan <= x"45";
				when X"26" => keys(4)(1) <= '0'; -- 9
					scan <= x"46";
				when X"25" => keys(4)(2) <= '0'; -- 8
					scan <= x"3e";
				when X"24" => keys(4)(3) <= '0'; -- 7
					scan <= x"3d";
				when X"23" => keys(4)(4) <= '0'; -- 6
					scan <= x"36";
				--
				when X"13" => keys(5)(0) <= '0'; -- P
					scan <= x"4d";
				when X"12" => keys(5)(1) <= '0'; -- O
					scan <= x"44";
				when X"0c" => keys(5)(2) <= '0'; -- I
					scan <= x"43";
				when X"18" => keys(5)(3) <= '0'; -- U
					scan <= x"3c";
				when X"1c" => keys(5)(4) <= '0'; -- Y
					scan <= x"35";
				--
				when X"28" => keys(6)(0) <= '0'; -- ENTER
					scan <= x"5a";
				when X"0f" => keys(6)(1) <= '0'; -- L
					scan <= x"4b";
				when X"0e" => keys(6)(2) <= '0'; -- K
					scan <= x"42";
				when X"0d" => keys(6)(3) <= '0'; -- J
					scan <= x"3b";
				when X"0b" => keys(6)(4) <= '0'; -- H
					scan <= x"33";
				--
				when X"2c" => keys(7)(0) <= '0'; -- SPACE
					scan <= x"29";
				when X"e4" => scan <= x"14"; -- CTRL (Symbol Shift)
					
				when X"10" => keys(7)(2) <= '0'; -- M
					scan <= x"3a";
				when X"11" => keys(7)(3) <= '0'; -- N
					scan <= x"31";
				when X"05" => keys(7)(4) <= '0'; -- B
					scan <= x"32";

				-- Cursor keys
				when X"50" => keys(0)(0) <= '0'; -- Left (CAPS 5)
					keys(3)(4) <= '0';
					scan <= x"6b";
				when X"51" => keys(0)(0) <= '0'; -- Down (CAPS 6)
					keys(4)(4) <= '0';
					scan <= x"72";
				when X"52" => keys(0)(0) <= '0'; -- Up (CAPS 7)
					keys(4)(3) <= '0';
					scan <= x"75";
				when X"4f" => keys(0)(0) <= '0'; -- Right (CAPS 8)
					keys(4)(2) <= '0';
					scan <= x"74";

				-- Other special keys sent to the ULA as key combinations
				when X"2a" => keys(0)(0) <= '0'; -- Backspace (CAPS 0)
					keys(4)(0) <= '0';
					scan <= x"66";
				when X"39" => keys(0)(0) <= '0'; -- Caps lock (CAPS 2)
					keys(3)(1) <= '0';
					scan <= x"58";
				when X"2b" => keys(0)(0) <= '0'; -- Tab (CAPS SPACE)
					keys(7)(0) <= '0';
					scan <= x"0d";
				when X"37" => keys(7)(2) <= '0'; -- .
					keys(7)(1) <= '0';
					scan <= x"49";
				when X"2d" => keys(6)(3) <= '0'; -- -
					keys(7)(1) <= '0';
					scan <= x"4e";
				when X"35" => keys(3)(0) <= '0'; -- ` (EDIT)
					keys(0)(0) <= '0';
					scan <= x"0e";
				when X"36" => keys(7)(3) <= '0'; -- ,
					keys(7)(1) <= '0';
					scan <= x"41";
				when X"33" => keys(5)(1) <= '0'; -- ;
					keys(7)(1) <= '0';
					scan <= x"4c";
				when X"34" => keys(5)(0) <= '0'; -- "
					keys(7)(1) <= '0';
					scan <= x"52";
				when X"31" => keys(0)(1) <= '0'; -- :
					keys(7)(1) <= '0';
					scan <= x"5d";
				when X"2e" => keys(6)(1) <= '0'; -- =
					keys(7)(1) <= '0';
					scan <= x"55";
				when X"2f" => keys(4)(2) <= '0'; -- (
					keys(7)(1) <= '0';
					scan <= x"54";
				when X"30" => keys(4)(1) <= '0'; -- )
					keys(7)(1) <= '0';
					scan <= x"5b";
				when X"38" => keys(0)(3) <= '0'; -- ?
					keys(7)(1) <= '0';
					scan <= x"4a";
				--------------------------------------------
				-- Kempston keys
				when X"5e" => keys(8)(0) <= '1'; -- [6] (Right)
				when X"5c" => keys(8)(1) <= '1'; -- [4] (Left)
				when X"5d" => keys(8)(2) <= '1'; -- [5] (Down)
				when X"60" => keys(8)(3) <= '1'; -- [8] (Up)
				when X"e0" => keys(8)(4) <= '1'; -- Left Control (Fire)
		
				-- Soft keys
				when X"3a" => scan <= x"05"; -- F1
				when X"3b" => scan <= x"06"; -- F2
				when X"3c" => scan <= x"04"; -- F3
				when X"3d" => scan <= x"0c"; -- F4
				when X"3e" => scan <= x"03"; -- F5
				when X"3f" => scan <= x"0b"; -- F6
				when X"40" => scan <= x"83"; -- F7
				when X"41" => scan <= x"0a"; -- F8
				when X"42" => scan <= x"01"; -- F9
				when X"43" => scan <= x"09"; -- F10
				when X"44" => scan <= x"78"; -- F11
					keys(9)(1) <= '1';
				when X"45" => scan <= x"07"; -- F12
					keys(9)(0) <= '1';
					
				-- Hardware keys
				when X"46" => scan <= x"7c";	-- PrtScr
					keys(9)(2) <= '1';
				when X"47" => scan <= x"7e";	-- Scroll Lock
					keys(9)(3) <= '1';
				when X"48" => scan <= x"77";	-- Pause
					keys(9)(4) <= '1';
				when X"65" => scan <= x"2f";	-- WinMenu
				when X"e7" => scan <= x"27";	-- Right GUI
				when X"29" => scan <= x"76";	-- Esc
				when X"49" => scan <= x"70";	-- Insert
				when X"4a" => scan <= x"6c";	-- Home
				when X"4b" => scan <= x"7d";	-- Page Up
				when X"4c" => scan <= x"71";	-- Delete
				when X"4d" => scan <= x"69";	-- End
				when X"4e" => scan <= x"7a";	-- Page Down
								
				when others => null;
			end case;
		end if;
	end process;

end architecture;
