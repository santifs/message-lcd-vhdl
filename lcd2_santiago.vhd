----------------------------------------------------------------------------------
-- Company: 	Universidad de Sevilla
-- Engineer: 	Santiago Fernández Scagliusi
-- 
-- Create Date:    02:01:44 04/22/2019 
-- Design Name: 	 Diseño 2 LCD. Mensajes personalizados
-- Module Name:    lcd2_santiago - Behavioral 
-- Project Name: 	 Trabajo 1. Escritura en LCD
-- Target Devices: Nexys 4
-- Tool versions:  ISE P.20131013
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

entity lcd2_santiago is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           init : in  STD_LOGIC;
           m1 : in STD_LOGIC;
           m2 : in STD_LOGIC;			  
           e : out  STD_LOGIC;
           rs : out  STD_LOGIC;
           rw : out  STD_LOGIC;
           db : out  STD_LOGIC_VECTOR (7 downto 0));
end lcd2_santiago;

architecture Behavioral of lcd2_santiago is
	type tipo_estado is (inicio, escritura, enable);
	signal estado, prox_estado: tipo_estado;
	signal thresh: std_logic;
	signal e_ok: std_logic := '0';				-- Flag de enable
   signal flag_m1: std_logic := '0';			-- Flag de pulsador m1
   signal flag_m2: std_logic := '0';			-- Flag de pulsador m2
	signal cambio_linea: std_logic := '0';		-- Se activará cuando haya que cambiar de linea
	signal linea1_fin : std_logic := '0';		-- Se activará cuando se haya escrito el último carácter de la línea 1
	signal linea2_fin : std_logic := '0';		-- Se activará cuando se haya escrito el último carácter de la línea 2
	signal inicio_fin : std_logic := '0';		-- Se activará cuando se hayan hecho todas las instrucciones de inicialización
   signal cont_inicio: unsigned(15 downto 0)  := "0000000000000000";		-- Contador para el estado de inicio
   signal i_1: integer range 0 to 15 := 0;	-- Índice para recorrer vector de línea 1
	signal i_2: integer range 0 to 15 := 0;	-- Índice para recorrer vector de línea 2
	signal cuenta: unsigned(6 downto 0) := "0000000";  -- Contará de 100 en 100, para "ralentizar" el reloj a 1 us
	signal wait_escritura : unsigned(5 downto 0):= "000000";		-- Contador para el estado de escritura
	signal datos: std_logic_vector(9 downto 0);		-- Contendrá los valores a enviar al LCD (se enviarán de forma concurrente)
	type vector_ascii is array(0 to 15) of std_logic_vector(7 downto 0);
   constant nombre: vector_ascii := (x"53", x"61", x"6e", x"74", x"69", x"61", x"67", x"6F", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20");  -- "Santiago" en hexadecimal (se rellena con espacios)
	constant apellidos: vector_ascii := (x"46", x"64", x"65", x"7a", x"20", x"53", x"63", x"61", x"67", x"6c", x"69", x"75", x"73", x"69", x"20", x"20"); -- "Fdez Scagliusi" en hex
	constant msj1: vector_ascii := (x"49", x"6e", x"67", x"20", x"45", x"6c", x"65", x"63", x"74", x"72", x"6f", x"6e", x"69", x"63", x"61", x"20");  -- "Ing. Electronica" en hex
	constant msj2: vector_ascii := (x"55", x"6e", x"69", x"20", x"53", x"65", x"76", x"69", x"6c", x"6c", x"61", x"20", x"20", x"20", x"20", x"20");  -- "Uni Sevilla" en hex

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
			i_1 <= 0;
			i_2 <= 0;
         flag_m1 <= '0';
			flag_m2 <= '0';
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

                  if (((m1 = '1' and m2 = '0') or (m1 = '0' and m2 = '1')) and (flag_m1 = '0' and flag_m2 = '0')) then	-- m1 o m2 pulsados? Analiza también flag para entrar 1 sola vez
						
							if m1 = '1' then								-- Activa flag correspondiente para comenzar a escribir...
								flag_m1 <= '1';							-- ... en cuanto se pulsa, sin esperar a que se suelte
							elsif m2 = '1' then
								flag_m2 <= '1';
							end if;
							
							datos <= "0010000000";						-- Dirección de escritura = 00 en hex
                     wait_escritura <= (others => '0');		-- Reinicia contador de escritura
                     i_1 <= 0;										-- Reinicia índices de vectores
							i_2 <= 0;
                     prox_estado <= enable;						-- Envía instrucción
                  else null;							      	-- Ninguno o los dos pulsadores activados a la vez?
                  end if;											-- No hacer nada. Esperar pulsación
                  
                  if (flag_m1 = '1' or flag_m2 = '1') then						-- Bandera activada?
						
							if wait_escritura < 42 then									-- Han pasado ya 43 us?
								wait_escritura <= wait_escritura + 1;					-- ... No. Incrementar cuenta
							else																	-- ... Sí. Momento de escribir
								if (cambio_linea = '1') then									-- Momento de cambiar de línea?
									cambio_linea <= '0';												-- ... Sí. Limpia flag de cambio de línea
									datos <= "0011000000";											-- Set DDRAM Address a C0
									
								elsif (linea1_fin = '0') then									-- ... No. Y línea 1 finalizada?
									if (flag_m1 = '1') then											-- ... No. Entonces escribir carácter i de línea 1...
										datos <= "10" & nombre(i_1);									-- de nombre
									elsif (flag_m2 = '1') then
										datos <= "10" & msj1(i_1);										-- de mensaje personalizado
									else null;
									end if;
									
									if i_1 < 15 then													-- Vector recorrido completamente?
										i_1 <= i_1 + 1;													-- ... No. Incrementar índice
									else
										linea1_fin <= '1';												-- ... Sí. Activar flag de fin de línea 1
										cambio_linea <= '1';												--     y flag de cambio de línea
									end if;
									
								elsif (linea1_fin = '1' and linea2_fin = '0') then		-- ... No. Y línea 2 finalizada?
									if (flag_m1 = '1') then											-- ... No. Entonces escribir carácter i de línea 2...
										datos <= "10" & apellidos(i_2);								-- de apellido
									elsif (flag_m2 = '1') then
										datos <= "10" & msj2(i_2);										-- de mensaje personalizado
									else null;
									end if;
									
									if i_2 < 15 then
										i_2 <= i_2 + 1;
									else
										linea2_fin <= '1';
									end if;
								
								end if;
								
								if (linea1_fin = '1' and linea2_fin = '1') then			-- Líneas 1 y 2 finalizadas?
									flag_m1 <= '0';													-- ... Sí. Reinicia flags
									flag_m2 <= '0';
									linea1_fin <= '0';
									linea2_fin <= '0';
									prox_estado <= escritura;										-- Se volverá al estado escritura para esperar 43 us necesarios para el último carácter
								else
									prox_estado <= enable;			
								end if;
								
								wait_escritura <= (others => '0');							-- Reinicia espera de escritura
							end if;

                  else null;
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