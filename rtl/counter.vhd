
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity counter is

    generic (
        C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
        C_FREQ_MAX   : integer := 100000;       -- 100 KHz
        C_CNT_BITS   : integer := 11;           -- 2^11 >= 125000000 / 100000
        C_RST_POL    : std_logic := '1'         -- Reset poling
    );
    port (
        -- Inputs
        clk             : in std_logic;
        reset           : in std_logic;
        clr             : in std_logic;
        enable          : in std_logic;
        stop            : in std_logic;
        continue        : in std_logic;
        -- Output
        overflow        : out std_logic;
        div             : out std_logic_vector(1 downto 0)
    );

end entity counter;

architecture Behavioral of counter is

    constant MAX_CNT    : integer := (C_FREQ_SYS/C_FREQ_MAX)/4;     -- 100 KHz I2C divider
    signal cnt          : integer range (C_FREQ_SYS/C_FREQ_MAX) - 1 downto 0;

begin

    freq_div : process(clk, reset)
    begin
        if reset = C_RST_POL then
            cnt <= 0;
        elsif clk'event and clk = '1' then
            if clr = '1' or stop = '1' then
                cnt <= 0;
            elsif enable = '1' then
                if continue = '1' then
                    if (cnt = 4*MAX_CNT - 1) then
                        cnt <= 0;
                    else
                        cnt <= cnt + 1;
                    end if;
                else
                    if (cnt = MAX_CNT - 1) then
                        cnt <= 0;
                    else
                        cnt <= cnt + 1;
                end if;                    
                end if;               
            end if;
        end if;
    end process;

    overflow <= '1' when ((cnt = MAX_CNT - 1) or (cnt = 2*MAX_CNT - 1) or (cnt = 3*MAX_CNT - 1) or (cnt = 4*MAX_CNT - 1)) else '0';
    
    div <=  "00" when cnt <= MAX_CNT - 1 else
            "01" when (cnt <= 2*MAX_CNT - 1)and(cnt > MAX_CNT - 1 ) else
            "10" when (cnt <= 3*MAX_CNT - 1)and(cnt > 2*MAX_CNT - 1 ) else
            "11";
        
     

end Behavioral;