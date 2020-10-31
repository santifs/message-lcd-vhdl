-- ROHIT D H
-- 4CB18EC055
-- Canara Engineering College
-- Assignment -- clock pulse usage


-- IEEE standard
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


-- lcd entity
entity lcd is

	port ( 	clk : in std_logic; 									-- clock
				lcd_rw : out std_logic; 							-- read & write 
				lcd_e : out std_logic;   							-- enable
				lcd_rs : out std_logic;  							-- register select for command
				data : out std_logic_vector(7 downto 0)		-- data lines
			);

end lcd;


 
-- Behavioral modeling
architecture Behavioral of lcd is
 -- 16 + 5
constant N: integer :=21;
type arr is array (1 to N) of std_logic_vector(7 downto 0);

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Commands:

-- d7 msb                    d0 lsb
------------------------------------------------------------------------------------------|
-- 1) Function Set:																								|
------------------------------------------------------------------------------------------| 
--					d7 d6 d5 d4 d3 d2 d1 d0																		|
--		syntax: 	0 	0	1	DL	N	F	X	X   	-- 8 bits 													|
--				:  0  0  1  1  1  0  0  0		-- ascii equivalent = 38								|
--																-- format					1     /   0			|
--																							------------			|
--								8-bit,				-- DL : interface data is 		8 		/   4 bits 	|
--									2 Line 			-- N	: number of lines is 	2 		/   1			|
--										5x8 Dots		-- F  : font size is 			5x11 	/   5x8		|
--																														|
------------------------------------------------------------------------------------------|


------------------------------------------------------------------------------------------------------------------|
-- 2) Diaplay ON/OFF:																															|
------------------------------------------------------------------------------------------------------------------| 
--					d7 d6 d5 d4 d3 d2 d1 d0																										|
--		syntax: 	0 	0	0	0	1	D	C	B   	-- 8 bits 																					|
--				:  0  0  0  0  1  1  0  0		-- ascii equivalent = 0C																|
--																-- format					1    				/   0								|
--																								--------------------------------------		|
--										entire 																										|
--										display ON 				 	-- D  : 		display ON				/ display OFF					|
--											cursor OFF 				-- C	:  	cursor ON 				/   cursor OFF					|
--												cursor pos OFF		-- B  : 		cursor position ON  	/   cursor position OFF 	|
--																																						|
------------------------------------------------------------------------------------------------------------------|



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
-- 3) Entry Mode:																																																				|
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------| 
--					d7 d6 d5 d4 d3 d2 d1 d0																																													|
--		syntax: 	0 	0	0	0	0	1	I/D	S   	-- 8 bits 																																							|
--				:  0  0  0  0  0  1  1     0		-- ascii equivalent = 06																																		|
--																-- format																						1    				/   		0								|
--																																				---------------------------------------------------------------|
--											Increment cursor position,		-- I/D 	: cursor move direction 				Increment cursor position 		/   Decrement cursor position 	|
--								 					No display shift 			-- S		: display shift 	 										Display shift 		/   No display shift					|
--																																																									|
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|



------------------------------------------------------------------------------------------|
-- 4) Display Clear/ Not clear Command:																	|																	
------------------------------------------------------------------------------------------| 
--					d7 d6 d5 d4 d3 d2 d1 d0																		|
--		syntax: 	0 	0	0	0	0	0	0	1   	-- 8 bits 													|
--				:  0  0  0  0  0  0  0  1		-- ascii equivalent = 01								|
--																-- format			1     /   0					|
--																					---------------				|
--												clear display					clear /  not clear			|
--																														|
------------------------------------------------------------------------------------------|



---------------------------------------------------------------------------------------------------------------|
-- 5)  Place Curser 																															|																	
---------------------------------------------------------------------------------------------------------------| 
--					d7 d6 d5 d4 d3 d2 d1 d0																									|
--		syntax: 	   	-- 8 bits 																											|
--				:  1  1  0  0  0  0  0  0		-- ascii equivalent = C0	 	Force cursor to beginning to 2nd line	|		
--				:  1  0  0  0  0  0  0  0		-- ascii equivalent = 80		Force cursor to beginning to 1nd line	|
---------------------------------------------------------------------------------------------------------------|


------------------------------------------------------------------------ give command + data ---------------------------------------------------------------------------------------------

constant datas : arr := (X"38",X"0c",X"06",X"01",X"C0",		x"41",  x"42",  x"43",  x"20",  x"43",  x"4F",  x"4E",  x"4E",  x"2E",  x"20",  x"46",  x"50",  x"47",  x"41",
																				x"20",  x"2E" );
								-- COMMANDS												-- DATA



------------------------------------------------------------------------ Here we go to start -----------------------------------------------------------------------------------------------
begin
-- we are writing to lcd
	lcd_rw <= '0'; 					-- syntax  0 = lcd write; 1 = lcd read


	process(clk)						-- we need clk pulses

-- i = 0; j = 1
		variable i : integer := 0;     
		variable j : integer := 1;


		begin
--									 -----		  -----
--									|	1	|		 |	 1  |
--									|		|		 |		 |		
-- clock pulses 		------		 ------		  ------
------------------------------------------------------------------------

-- EN -> Enable
-- 		EN = high to low ( Logic '1' delay Logic '0' ) for use LCD module .

------------------------------------------------------------------------

			if clk'event and clk = '1' then
				if i <= 12000000 then
					i := i + 1;
					lcd_e <= '1';											-- en  = 1                    
					data <= datas(j)(7 downto 0);
				elsif i > 12000000 and i < 24000000 then
					i := i + 1;
					lcd_e <= '0';											-- en  = 0
				elsif i = 24000000 then
					j := j + 1;
					i := 0;
				end if;
------------------------------------------------------------------------

-- Rs -> Register select
--			Rs = 1 means data register is selected.
--			Rs = 0 means command register is selected.

------------------------------------------------------------------------

-- RW -> Read/Write
--			RW = 1 mean reading from LCD module.
--			RW = 0 mean writing to LCD module.

------------------------------------------------------------------------

				if j <= 5 then
					lcd_rs <= '0'; --command register selected		-- RS = '0'  RW = '0'  En= '1'   to access the instruction register for command
				elsif j > 5 then
					lcd_rs <= '1'; --data register selected
				end if;

				if j = 22 then --repeated display of data
					j := 5;
				end if;
			end if;
		
	end process;


end Behavioral;


