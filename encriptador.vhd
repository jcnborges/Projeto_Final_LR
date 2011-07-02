LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY encriptador IS

PORT (enable : IN BIT;
		plan_text : IN BIT_VECTOR(63 DOWNTO 0);
		key : IN BIT_VECTOR(63 DOWNTO 0);
		cipher_text : OUT BIT_VECTOR(63 DOWNTO 0));
END encriptador;

ARCHITECTURE encriptar OF encriptador IS

TYPE t_512_integer_vector IS ARRAY (0 TO 511) OF INTEGER;
TYPE t_64_integer_vector IS ARRAY (0 TO 63) OF INTEGER;
TYPE t_56_integer_vector IS ARRAY (0 TO 55) OF INTEGER;
TYPE t_48_integer_vector IS ARRAY (0 TO 47) OF INTEGER;
TYPE t_32_integer_vector IS ARRAY (0 TO 31) OF INTEGER;
TYPE t_16_integer_vector IS ARRAY (0 TO 15) OF INTEGER;

CONSTANT initial_permutation_map : t_64_integer_vector :=
(	57,49,41,33,25,17,09,01,59,51,43,35,27,19,11,03,
	61,53,45,37,29,21,12,07,63,55,47,39,31,23,15,07,
	56,48,30,32,24,16,08,00,58,50,42,34,26,18,10,02,
	60,52,44,36,28,20,12,04,62,54,46,38,30,22,14,06	);		

CONSTANT final_permutation_map : t_64_integer_vector :=
(	39,07,47,15,55,23,63,31,38,06,46,14,54,22,62,30,
	37,05,45,13,53,21,61,29,36,04,44,12,52,20,60,28,
	35,03,43,11,51,19,59,27,34,02,42,10,50,18,58,26,
	33,01,41,09,49,17,57,25,32,00,40,08,48,16,56,24	);	

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

CONSTANT expansion_permutation_map: t_48_integer_vector :=
(	31,00,01,02,03,04,03,04,05,06,07,08,
	07,08,09,10,11,12,11,12,13,14,15,16,
	15,16,17,18,19,20,19,20,21,22,23,24,
	23,24,25,26,27,28,27,28,29,30,31,00	);
	
CONSTANT shift_key_map : t_16_integer_vector :=
( 1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1 );	

------------------------------ Tabelas S-box -------------------------------
CONSTANT sbox : t_512_integer_vector :=
(	-- SBOX 1
	14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7,
	0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8,
	4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0,
	15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13,
	
	-- SBOX 2
	15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10,
	3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5,
	0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15,
	13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9,

    -- SBOX 3
	10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8,
	13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1,
	13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7,
	1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12,	
	
	-- SBOX 4
	7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15,
	13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9,
	10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4,
	3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14,	
	
	-- SBOX 5
	2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9,
	14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6,
	4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14,
	11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3,	
	
	-- SBOX 6	
	12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11,
	10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8,
	9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6,
	4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13,	
	
	-- SBOX 7
	4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1,
	13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6,
	1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2,
	6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12,	
	
	-- SBOX 8
	13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7,
	1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2,
	7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8,
	2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11	);
-----------------------------------------------------------------------------

CONSTANT pbox_permutation_map : t_32_integer_vector :=
(	15,06,19,20,28,11,27,16,00,14,22,25,04,17,30,09,
	01,07,23,13,31,26,02,08,18,12,29,05,21,10,03,24	);

BEGIN PROCESS (enable)

VARIABLE aux0 : BIT_VECTOR(63 DOWNTO 0); -- plain text permutado
VARIABLE aux0_0 : BIT_VECTOR(63 DOWNTO 0); -- cipher text
VARIABLE aux1 : BIT_VECTOR(55 DOWNTO 0); -- chave reduzida para 56 bits
VARIABLE aux2 : BIT_VECTOR(55 DOWNTO 0); -- junção das metades da chave de 56 bits
VARIABLE aux3 : BIT_VECTOR(47 DOWNTO 0); -- chave reduzida Ki, ou seja, chave da rodada número i
VARIABLE aux4: BIT_VECTOR(47 DOWNTO 0); -- metade direita do texto plano expandida
VARIABLE aux5: BIT_VECTOR(47 DOWNTO 0); -- chave Ki xor metade direita do texto plano expandida
VARIABLE aux6: BIT_VECTOR(5 DOWNTO 0); -- entrada de 6 bits para S-box
VARIABLE aux7: BIT_VECTOR(31 DOWNTO 0); -- saída da S-box e auxiliar para salvar o right anterior
VARIABLE aux8: BIT_VECTOR(31 DOWNTO 0); -- saída da P-box
VARIABLE data_right : BIT_VECTOR(31 DOWNTO 0); -- metade direita do texto plano
VARIABLE data_left : BIT_VECTOR(31 DOWNTO 0); -- metade esquerda do texto plano
VARIABLE key_left : BIT_VECTOR(27 DOWNTO 0); -- metade esquerda da chave de 56 bits
VARIABLE key_right : BIT_VECTOR(27 DOWNTO 0); -- metade direita da chave de 56 bits
VARIABLE b_linha : BIT_VECTOR(1 DOWNTO 0); -- vetor de 2 bits que representa a linha da sbox
VARIABLE b_coluna : BIT_VECTOR(3 DOWNTO 0); -- vetor de 4 bits que representa a coluna da sbox
VARIABLE b_saida : BIT_VECTOR( 3 DOWNTO 0); -- saida de 4 bits da sbox
VARIABLE c0 : INTEGER; -- contador de uso geral
VARIABLE aux : INTEGER; -- variavel inteira de uso geral
VARIABLE linha : INTEGER; -- linha da S-box
VARIABLE coluna : INTEGER; -- coluna da S-box

BEGIN

	-- Permutacao Inicial --
	
	FOR i IN 0 TO 63 LOOP
		aux0(i) := plan_text(initial_permutation_map(i));
	END LOOP;

	-- Copia as duas metades do texto plano --
	FOR i IN 0 TO 31 LOOP
		data_left(i) := aux0(i);
		data_right(i) := aux0(i + 32);
	END LOOP;
	
	FOR round IN 0 TO 15 LOOP
	
	---------------------------- Transformação da chave ----------------------------
	
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
		key_left := key_left SRL(shift_key_map(round));
		key_right := key_right SRL(shift_key_map(round));
		
		-- União das metadas --
		FOR i IN 0 TO 27 LOOP
			aux2(i) := key_left(i);
			aux2(i + 28) := key_right(i);
		END LOOP;
		
		-- Permutação compressiva --
		FOR i IN 0 TO 47 LOOP
			aux3(i) := aux2(key_compression_permutation_map(i));
		END LOOP;
	
	---------------------------- Fim da Transformação da chave ------------------------
	
		-- Permutação expansiva --
		FOR i IN 0 TO 47 LOOP
			aux4(i) := data_right(expansion_permutation_map(i));
		END LOOP;
		
		-- Xor --
		aux5 := aux3 xor aux4;
	
		-- Substituição por S-box --
		FOR i IN 0 TO 7 LOOP
			aux6(0) := aux5(6 * i);
			aux6(1) := aux5(6 * i + 1);
			aux6(2) := aux5(6 * i + 2);
			aux6(3) := aux5(6 * i + 3);
			aux6(4) := aux5(6 * i + 4);
			aux6(5) := aux5(6 * i + 5);
			b_linha(0) := aux6(0);
			b_linha(1) := aux6(5);
			b_coluna(0) := aux6(1);
			b_coluna(1) := aux6(2);
			b_coluna(2) := aux6(3);
			b_coluna(3) := aux6(4);
			linha := conv_integer(to_stdlogicvector(b_linha));
			coluna := conv_integer(to_stdlogicvector(b_coluna));
			-- 64 * i + 16 * linha + coluna --
			aux := sbox(64 * i + 16 * linha + coluna);
			b_saida := to_bitvector(conv_std_logic_vector(aux, 4));
			aux7(4 * i) := b_saida(0);
			aux7(4 * i + 1) := b_saida(1);
			aux7(4 * i + 2) := b_saida(2);
			aux7(4 * i + 3) := b_saida(3);
		END LOOP;
	
		-- Permutação por P-box --
		FOR i IN 0 TO 31 LOOP
			aux8(i) := aux7(pbox_permutation_map(i));			
		END LOOP;
		
		-- Xor final --
		aux7 := data_right;
		data_right := data_left xor aux8;
		data_left := aux7;
	
	END LOOP;
	
	-- Permutação final
	FOR i IN 0 TO 31 LOOP
		aux0(i) := data_left(i);
		aux0(i + 32) := data_right(i);
	END LOOP;
	
	FOR i IN 0 TO 63 LOOP
		aux0_0(i) := aux0(final_permutation_map(i));
	END LOOP;
	
	cipher_text <= aux0_0;
	
END PROCESS;	
END	encriptar;			
		