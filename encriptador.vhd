LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY encriptador IS

PORT (enable : IN BIT;
		plan_text : IN BIT_VECTOR(63 DOWNTO 0);
		key : IN BIT_VECTOR(63 DOWNTO 0);
		cipher_text : OUT BIT_VECTOR(63 DOWNTO 0));
END encriptador;

ARCHITECTURE encriptar OF encriptador IS

TYPE t_64_integer_vector IS ARRAY (0 TO 63) OF INTEGER;
TYPE t_56_integer_vector IS ARRAY (0 TO 55) OF INTEGER;
TYPE t_48_integer_vector IS ARRAY (0 TO 47) OF INTEGER;
TYPE t_16_integer_vector IS ARRAY (0 TO 15) OF INTEGER;

CONSTANT initial_permutation_map : t_64_integer_vector :=
(	57,49,41,33,25,17,09,01,59,51,43,35,27,19,11,03,
	61,53,45,37,29,21,12,07,63,55,47,39,31,23,15,07,
	56,48,30,32,24,16,08,00,58,50,42,34,26,18,10,02,
	60,52,44,36,28,20,12,04,62,54,46,38,30,22,14,06	);		

CONSTANT final_permutation_map : t_64_integer_vector :=
(	39,7,47,15,55,23,63,31,38,6,46,14,54,22,62,30,
	37,5,45,13,53,21,61,29,36,4,44,12,52,20,60,28,
	35,3,43,11,51,19,59,27,34,2,42,10,50,18,58,26,
	33,1,41,9,49,17,57,25,32,0,40,8,48,16,56,24	);	

CONSTANT key_permutation_map : t_56_integer_vector :=
(	56,48,40,32,24,16,08,00,57,49,41,33,25,17, 
	09,01,58,50,42,34,26,18,10,02,59,51,43,35,
	62,54,46,38,30,22,14,06,61,53,45,37,29,21,
	13,05,60,52,44,36,28,20,12,04,27,19,11,03	);	
	
CONSTANT key_compression_permutation_map : t_48_integer_vector :=
(	13,16,10,23,00,04,02,27,14,05,20,09,
	22,18,11,03,25,07,15,06,26,19,12,01,
	40,51,30,36,46,54,29,39,50,44,32,47,
	43,48,38,55,33,52,45,41,49,35,28,31	);
	
CONSTANT shift_key_map : t_16_integer_vector :=
( 1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1 );	

BEGIN PROCESS (enable)

VARIABLE aux0 : BIT_VECTOR(63 DOWNTO 0); -- plain text permutado
VARIABLE aux1 : BIT_VECTOR(55 DOWNTO 0); -- chave reduzida para 56 bits
VARIABLE aux2 : BIT_VECTOR(55 DOWNTO 0); -- junção das metades da chave de 56 bits
VARIABLE aux3 : BIT_VECTOR(48 DOWNTO 0); -- chave reduzida Ki, ou seja, chave da rodada número i
VARIABLE key_left : BIT_VECTOR(27 DOWNTO 0); -- metade esquerda da chave de 56 bits
VARIABLE key_right : BIT_VECTOR(27 DOWNTO 0); -- metade direita da chave de 56 bits
VARIABLE c0 : INTEGER; -- contador de uso geral

BEGIN

	-- Permutacao Inicial --
	
	FOR i IN initial_permutation_map'RANGE LOOP
		aux0(i) := plan_text(initial_permutation_map(i));
	END LOOP;
	
	-- Transformação da chave --
	
	-- Primeira permutação --
	c0 := 0;
	FOR i IN 0 TO 55 LOOP
		aux1(i) := key(key_permutation_map(i));
	END LOOP;
	
	-- Copia duas metades da chave de 56 bits
	FOR i IN 0 TO 27 LOOP
		key_left(i) := aux1(i);
		key_right(i) := aux1(i + 28);
	END LOOP;
	
	-- Deslocamento das duas metades --
	-- Responsavel: Castanhel --
	
	-- União das metadas --
	FOR i IN 0 TO 27 LOOP
		aux2(i) := key_left(i);
		aux2(i + 28) := key_right(i);
	END LOOP;
	
	-- Permutação compressiva --
	FOR i IN 0 TO 47 LOOP
		aux3(i) := aux2(key_compression_permutation_map(i));
	END LOOP;
	
	-- Fim da Transformação da chave --
	
	-- Permutação expansiva --
	
	cipher_text <= plan_text;
	
END PROCESS;	
END	encriptar;			
		