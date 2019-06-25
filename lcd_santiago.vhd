----------------------------------------------------------------------------------
-- Company: Universidad de Sevilla
-- Engineer: Santiago Fernández Scagliusi
-- 
-- Create Date:    11:15:32 03/19/2019 
-- Design Name:
-- Module Name:    lcd_santiago - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

entity lcd_santiago is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           init : in  STD_LOGIC;	
           e : out  STD_LOGIC;
           rs : out  STD_LOGIC;
           rw : out  STD_LOGIC;
           db : out  STD_LOGIC_VECTOR (7 downto 0));
end lcd_santiago;

architecture Behavioral of lcd_santiago is
	type tipo_estado is (inicio, escritura, enable);
	signal estado, prox_estado: tipo_estado;
	signal thresh: std_logic;
	signal e_ok: std_logic := '0';				-- Flag de enable
	signal cambio_linea: std_logic := '0';		-- Se activará cuando haya que cambiar de linea
	signal linea1_fin : std_logic := '0';		-- Se activará cuando se haya escrito el último carácter de la línea 1
	signal linea2_fin : std_logic := '0';		-- Se activará cuando se haya escrito el último carácter de la línea 2
	signal inicio_fin : std_logic := '0';		-- Se activará cuando se hayan hecho todas las instrucciones de inicialización
   signal cont_inicio: unsigned(15 downto 0)  := "0000000000000000";		-- Contador para el estado de inicio
   signal i: integer range 0 to 15 := 0;	-- Índice para recorrer vector de línea 1
	signal cuenta: unsigned(6 downto 0) := "0000000";  -- Contará de 100 en 100, para "ralentizar" el reloj a 1 us
	signal wait_escritura : unsigned(5 downto 0):= "000000";		-- Contador para el estado de escritura
	signal datos: std_logic_vector(9 downto 0);		-- Contendrá los valores a enviar al LCD (se enviarán de forma concurrente)
	type vector_ascii is array(0 to 15) of std_logic_vector(7 downto 0);
   constant nombre: vector_ascii := (x"53",	-- S
	                                  x"61",	-- a
												 x"6e",	-- n
											    x"74",	-- t
											    x"69",	-- i
											    x"61",	-- a
											    x"67",	-- g
											    x"6F",	-- o
											    x"20",	-- (espacio)
											    x"20",	-- (espacio)
											    x"20",	-- (espacio)
												 x"20",	-- (espacio)
											    x"20",	-- (espacio)
											    x"20",	-- (espacio)
											    x"20",	-- (espacio)
											    x"20");	-- (espacio)
												 
	constant apellidos: vector_ascii := (x"46",	-- F
	                                     x"64",	-- d
												    x"65",	-- e
												    x"7a",	-- z
												    x"20",	-- (espacio)
													 x"53",	-- S
													 x"63",	-- c
													 x"61",	-- a
													 x"67",	-- g
													 x"6c",	-- l
													 x"69",	-- i
													 x"75",	-- u
													 x"73",	-- s
													 x"69",	-- i
													 x"20",	-- (espacio)
													 x"20"); -- (espacio)

begin

   P_clk:process(clk, reset)							-- Proceso dedicado a ralentizar el tiempo de reloj a 1 us
   begin
      if (reset = '1') then
         cuenta <= (others => '0');
      elsif rising_edge(clk) then
		   if cuenta < 100 then               		-- Ha pasado ya 1 us?                
            cuenta <= cuenta + 1;			  		-- ... No. Incrementar cuenta.
         else
            cuenta <= (others => '0');      		-- ... Sí. Reiniciar cuenta.
         end if;
      end if;
   end process P_clk;
	
	thresh <= '1' when cuenta = 0 else '0';		-- Se activará cada microsegundo
   --thresh <= '1';										-- Descomentar para simular más rápido
   
   P_principal: process(clk, reset)					-- Proceso principal
   begin
      if reset = '1' then								-- Inicialización de señales
         prox_estado <= inicio;
         cont_inicio <= (others => '0');
			e_ok <= '0';
			wait_escritura <= (others => '0');
			i <= 0;
			linea1_fin <= '0';
			linea2_fin <= '0';
			inicio_fin <= '0';
         cambio_linea <= '0';
      elsif rising_edge(clk) then
         if thresh = '1' then
            
            case estado is
               
               when inicio =>
					
					   if inicio_fin = '0' then						-- Inicialización finalizada?
					      cont_inicio <= cont_inicio + 1;			-- ... No. Incrementar contador
						else null;											-- ... Sí. No incrementar más para evitar desbordamiento
						end if;
						
                  if (cont_inicio < 20000) then					-- Espera inicial de 20 ms
                     null;
                  elsif (cont_inicio = 20000) then  			-- Function Set
                     datos <= "0000111000";     				----- Config LCD: 8 bits, 2 lineas y 5x8 puntos
                     prox_estado <= enable;						----- Envía instrucción. Espera 39 us
                  elsif (cont_inicio = 20041) then  			-- Display ON
                     datos <= "0000001100";     				----- D=1, C=0, B=0
                     prox_estado <= enable;						----- Envía instrucción. Espera 39 us
                  elsif (cont_inicio = 20082) then  			-- Clear Display
                     datos <= "0000000001";						----- Escribe 20H en DDRAM y se sitúa en dirección 00H		
                     prox_estado <= enable;						----- Envia instrucción. Espera 1,53 ms
					   elsif (cont_inicio >= 21614) then			-- Inicialización finalizada
						   prox_estado <= escritura;					----- Cambia a estado escritura
							inicio_fin <= '1';							----- Activa bandera de fin de inicio
						else null;
                  end if;
               
               when escritura =>
							if linea2_fin = '0' then									-- Escritura finalizada?
								if wait_escritura < 42 then								-- ... No. Y han pasado ya 43 us?
									wait_escritura <= wait_escritura + 1;					-- ... No. Incrementar cuenta
								else																	-- ... Sí. Momento de escribir
									if (cambio_linea = '1') then									-- Momento de cambiar de línea?
										cambio_linea <= '0';												-- ... Sí. Limpia flag de cambio de línea
										datos <= "0011000000";											-- Set DDRAM Address a C0
										
									elsif (linea1_fin = '0') then									-- ... No. Y línea 1 finalizada?
										datos <= "10" & nombre(i);										-- ... No. Entonces escribir carácter i de nombre

										if i < 15 then														-- Vector recorrido completamente?
											i <= i + 1;														-- ... No. Incrementar índice
										else
											i <= 0;															-- ... Sí. Reiniciar índice
											linea1_fin <= '1';											--     Activar flag de fin de línea 1
											cambio_linea <= '1';											--     y flag de cambio de línea
										end if;
										
									elsif (linea1_fin = '1' and linea2_fin = '0') then		-- ... No. Y línea 2 finalizada?
										datos <= "10" & apellidos(i);									-- ... No. Entonces escribir carácter i de apellidos
										
										if i < 15 then														-- Vector recorrido completamente?
											i <= i + 1;														-- ... No. Incrementar índice
										else
											linea2_fin <= '1';											-- ... Sí. Activar flag de fin de línea 2
										end if;
									
									end if;
									
									prox_estado <= enable;										-- Enviar instrucción
									wait_escritura <= (others => '0');						-- Reinicia espera de escritura
								end if;
							else null;														-- Escritura finalizada. No hacer nada más
							end if;
                  
               when enable =>								-- Estado de envio de instrucciones
                  if e_ok = '0' then						-- Entra por primera vez?
                     e_ok <= '1';								-- ... Sí. Activa enable
							prox_estado <= enable;					-- 	 Volverá a estado enable pero habiendo esperado 1 us necesario (un ciclo de cuenta)
                  else
                     e_ok <= '0';								-- ... No. Limpia bandera para el próximo envio de instrucciones
					      if (inicio_fin = '0') then					-- ¿Todavía inicializando?
					         prox_estado <= inicio;						-- ... Si. Ir a estado inicio
                     else
						      prox_estado <= escritura;					-- ... No. Ir a estado escritura
                     end if;
                  end if;
						
            end case;
         end if;
      end if;
   end process P_principal;
	
	e <= e_ok;							-- Instrucciones concurrentes para envío de datos al LCD
	rs <= datos(9);
	rw <= datos(8);
	db <= datos(7 downto 0);
   estado <= prox_estado;			-- Actualización de estado

end Behavioral;
