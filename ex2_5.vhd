library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ex2 IS
	GENERIC(
        NUMDISPLAYS: integer := 4;
        BITS_NUM: integer := 4; -- pi
		  NUM_MEMORY: integer := 4;  -- numero limite para tamanho da pilha
        CMD_DEBOUNCE_T_MS: integer := 7; --700;
        FCLK: integer := 100 ---50e6
	);
	PORT(
        clk: in std_logic;
        operation: in std_logic_vector(2 downto 0);
        number: in std_logic_vector(BITS_NUM - 1 downto 0);
		  ssd_saida: out std_logic_vector (NUMDISPLAYS*7 - 1 downto 0)
	);
END ENTITY;

ARCHITECTURE arch OF ex2 IS
	COMPONENT debounce IS
		GENERIC(
				time_ms : integer := 3; ---100;
				freq_clk: integer := 100--- 50e6
		);
		PORT(
  		  button : in std_logic;
		  clk : in std_logic;
		  debounced_out : out std_logic
		);
    END COMPONENT;
-------------------------------------------------------------------------------------
type memory is array(0 to NUM_MEMORY - 1) of integer;
signal rpn_stack: memory;

signal command: std_logic_vector(2 downto 0);

signal number_dbc: std_logic_vector(BITS_NUM - 1 downto 0);
signal op_result: integer;

signal resultado: std_logic_vector(NUMDISPLAYS*7 - 1 downto 0); -- Adicionado para converter o integer
type hexa is array (NUMDISPLAYS-1 downto 0) of std_logic_vector(3 downto 0);
signal hex: hexa;

constant CMD_DEBOUNCE_COUNT_MAX: integer := CMD_DEBOUNCE_T_MS * FCLK / 1e3;
--------------------------------------------------------------------------------------
BEGIN
	debounce_operation_2 : debounce port map(button => operation(2), clk => clk, debounced_out => command(2));
	debounce_operation_1 : debounce port map(button => operation(1), clk => clk, debounced_out => command(1));
	debounce_operation_0 : debounce port map(button => operation(0), clk => clk, debounced_out => command(0));

    number_dbc_gen: for i in 0 to BITS_NUM - 1 generate
        number_dbc_X: debounce port map(button => number(i), clk => clk, debounced_out => number_dbc(i));
    end generate;

	PROCESS (clk)   -- cuida do debounce de comando
		variable counter: integer := 0;
		variable stack_top: integer := 0;
		BEGIN
			IF command /= "111" and command /= "000" THEN
				IF counter < CMD_DEBOUNCE_COUNT_MAX THEN
					counter := counter + 1;
				ELSE
					counter := 0;
					IF command = "011" THEN -- enter
						IF stack_top < NUM_MEMORY - 1 THEN
							IF stack_top /= 0 THEN
								for i in NUM_MEMORY-1 to 1 loop -- shifta todos valores em rpn_stack e entao adiciona o number ao rpn_stack(0)
									rpn_stack(i) <= rpn_stack(i-1);
								end loop;
							END IF;
						rpn_stack(0) <= to_integer(unsigned(number_dbc));
						stack_top := stack_top + 1;
						END IF;
					ELSIF command = "001" THEN -- clear memory
						-- escreve "0" em todos valores de rpn_stack
						for i in 0 to NUM_MEMORY - 1 loop
						rpn_stack(i) <= 0;
						end loop;
						stack_top := 0; -- para que operações só possam ser realizadas após dois numeros adicionados.
					ELSIF stack_top > 1 and command = "110" and command = "101" and command = "100" and command = "010" THEN
						IF command = "110" THEN -- soma
							op_result <= rpn_stack(1) + rpn_stack(0);
						ELSIF command = "101" THEN -- subtracao
							op_result <= rpn_stack(1) - rpn_stack(0); --verificar se valor eh negativo?
						ELSIF command = "100" THEN -- multiplicacao
							op_result <= rpn_stack(1) * rpn_stack(0);
						ELSIF command = "010" THEN -- divisao
							IF rpn_stack(0) = 0 THEN
								op_result <= 0;
							ElSE
								op_result <= (rpn_stack(1) / rpn_stack(0));
							END IF;
						END IF;

						-- realiza shift da memoria, com generate
						for i in 2 to NUM_MEMORY - 1 loop -- Du: Não seria só "NUM_MEMORY - 1" no lugar do "NUM_MEMORY - 1 -1"
						rpn_stack(i-1) <= rpn_stack(i);
						end loop;
						rpn_stack(NUM_MEMORY - 1) <= 0;
						rpn_stack(0) <= op_result;
						stack_top := stack_top - 1;
					END IF;
				END IF;
			ELSE
				counter := 0;
			END IF;
	END PROCESS;

    -- falta enviar rpn_stack(0) para resultado e mostrar nos displays. ------
    resultado <= std_logic_vector(to_unsigned(rpn_stack(0),NUMDISPLAYS*7)); -- Add
    
    generate_ssd: for i in 1 to NUMDISPLAYS generate
    hex(i-1) <= resultado(4*i-1 downto 4*(i-1));
    ssd_saida(7*i-1 downto 7*(i-1)) <= 	  "1000000" WHEN hex(i-1) = "0000" ELSE
                                            "1111001" WHEN hex(i-1) = "0001" ELSE
                                            "0100100" WHEN hex(i-1) = "0010" ELSE
                                            "0110000" WHEN hex(i-1) = "0011" ELSE
                                            "0011001" WHEN hex(i-1) = "0100" ELSE
                                            "0010010" WHEN hex(i-1) = "0101" ELSE
                                            "0000010" WHEN hex(i-1) = "0110" ELSE
                                            "1111000" WHEN hex(i-1) = "0111" ELSE
                                            "0000000" WHEN hex(i-1) = "1000" ELSE
                                            "0010000" WHEN hex(i-1) = "1001" ELSE
                                            "0001000" WHEN hex(i-1) = "1010" ELSE
                                            "0000011" WHEN hex(i-1) = "1011" ELSE
                                            "1000110" WHEN hex(i-1) = "1100" ELSE
                                            "0100001" WHEN hex(i-1) = "1101" ELSE
                                            "0000110" WHEN hex(i-1) = "1110" ELSE
                                            "0001110" WHEN hex(i-1) = "1111" ELSE
                                            "1100100";

end generate generate_ssd;

END ARCHITECTURE;
