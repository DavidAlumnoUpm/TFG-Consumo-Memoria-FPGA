
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity I2C_scl is
  Port ( 
            clk             : in std_logic;
            reset           : in std_logic;
            clr             : in std_logic;
            enable          : in std_logic;
            overflow        : in std_logic;
            stop            : in std_logic;
            div             : in std_logic_vector(1 downto 0);
            scl             : out std_logic     
                 
  );
end I2C_scl;

architecture Behavioral of I2C_scl is

begin

    process(clk,reset)
    begin
        if reset = '1' then
            scl <= '1';
        elsif clk'event and clk = '1' then
            if clr = '1' or stop = '1' then
                scl <= '1';
            elsif enable = '1' then
                if overflow = '1' then
                    if stop = '1' then
                        scl <= '1';
                    elsif div(1) = '0' then
                        scl <= '0';
                    else
                        scl <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
