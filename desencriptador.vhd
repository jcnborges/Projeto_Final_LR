LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY desencriptador IS
PORT (cipher_text : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		key : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		plan_text : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
END desencriptador;
ARCHITECTURE desencriptar OF desencriptador IS
BEGIN
	plan_text <= cipher_text;
END desencriptar;	
