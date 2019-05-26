library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ex2 IS
	GENERIC(
        NUMDISPLAYS: integer := 4;
        BITS_NUM: integer := 4; -- pi
		  NUM_MEMORY: integer := 3;  -- numero limite para tamanho da pilha => 3+1
        CMD_DEBOUNCE_T_MS: integer := 700;
        FCLK: integer := 50e6
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
				time_ms : integer := 100;
				freq_clk: integer := 50e6
		);
		PORT(
  		  button : in std_logic;
		  clk : in std_logic;
		  debounced_out : out std_logic
		);
    END COMPONENT;
-------------------------------------------------------------------------------------
type memory is array(0 to NUM_MEMORY) of integer; -- 0 ~ 1023
signal rpnStack: memory;

signal commandAcquired: std_logic;
signal command: std_logic_vector(2 downto 0);
signal command_old: std_logic_vector(2 downto 0);

signal op_result: integer;

constant CMD_DEBOUNCE_COUNT_MAX: integer := CMD_DEBOUNCE_T_MS * FCLK / 1e3;
--------------------------------------------------------------------------------------
BEGIN
	debounce_operation_2 : debounce port map(button => operation(2), clk => clk, debounced_out => command(2));
	debounce_operation_1 : debounce port map(button => operation(1), clk => clk, debounced_out => command(1));
	debounce_operation_0 : debounce port map(button => operation(0), clk => clk, debounced_out => command(0));

    PROCESS (clk)   -- cuida do debounce de comando
    variable counter: integer := 0;
    variable flag: std_logic := 0;
	BEGIN
        IF counter < CMD_DEBOUNCE_COUNT_MAX THEN
            counter := counter + 1;
				IF flag = '0' THEN
					command_old <= "000";
				END IF;
        ELSE
            counter := 0;
            -- executa algum comando nesse ponto
            IF command_old = command
					commandAcquired <= '1';
					flag := '0';
				ELSE
					command_old <= command;
					flag := '1';
				END IF;
            --
        END IF;
    END PROCESS;

    PROCESS (commandAcquired) --executa a operação registrada em commmand
    BEGIN
        IF commandAcquired'event and commandAcquired = '1' THEN
            IF command = "011" THEN -- enter
                -- shifta todos valores em rpnStack e entao adiciona o number ao rpnStack(0)
					 gen1: for i in NUM_MEMORY to 1 generate
							rpnStack(i) <= rpnStack(i-1);
					 end generate;
					 rpnStack(0) <= number;
					 --
            ELSIF command = "001" THEN -- clear memory
                -- escreve "0" em todos valores de rpnStack
					 -- nao seria melhor escolher um valor diferente de 0? (um valor que indique "vazio")
					 gen2: for i in 0 to NUM_MEMORY generate
							rpnStack(i) <= 0;
					 end generate;
					 --
            ELSE
                IF command = "110" THEN -- soma
                    op_result <= rpnStack(1) + rpnStack(0);
                ELSIF command = "101" THEN -- subtracao
                    op_result <= rpnStack(1) - rpnStack(0); --verificar se valor eh negativo?
                ELSIF command = "100" THEN -- multiplicacao
                    op_result <= rpnStack(1) * rpnStack(0);
                ELSIF command = "010" THEN -- divisao
                    op_result <= rpnStack(1) / rpnStack(0) when rpnStack(0) /= 0 else
                                0; -- caso indeterminado, mostre um valor 0 (ou o maior possivel?) --Tanto faz ;)
                END IF;

                -- realiza shift da memoria, com generate
					 -- acho que vai dar erro aqui, pois as outras opcoes nao foram verificadas...
					 gen3: for i in 2 to NUM_MEMORY-1 generate
							rpnStack(i-1) <= rpnStack(i);
					 end generate;
					 rpnStack(NUM_MEMORY) <= 0;
					 rpnStack(0) <= op_result;
                --
            END IF;
        END IF;
    END PROCESS;





    generate_ssd: for i in 1 to NUMDISPLAYS generate
    hex(i-1) <= resultado(4*i-1 downto 4*(i-1));
    ssd_saida(7*i-1 downto 7*(i-1)) <= 	"1000000" WHEN hex(i-1) = "0000" ELSE
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
"# logrep-lab6-Du-" 
