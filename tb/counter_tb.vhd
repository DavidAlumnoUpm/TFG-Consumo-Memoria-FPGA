
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity counter_tb is

    generic (
                C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
                C_FREQ_MAX   : integer := 100000;       -- 100 KHz
                C_CNT_BITS   : integer := 11;           -- 2^11 >= 125000000 / 100000
                C_RST_POL    : std_logic := '1'         -- Reset poling
    );

end counter_tb;

architecture Behavioral of counter_tb is

    constant CLK_PERIOD : time := 8 ns; -- 125 MHz
    signal clk, reset, clr, enable, overflow, stop, continue : std_logic; 
    signal div          : std_logic_vector(1 downto 0);
    
begin

    uut : entity work.counter(Behavioral)
        generic map(
            C_FREQ_SYS  => C_FREQ_SYS,
            C_FREQ_MAX  => C_FREQ_MAX,
            C_CNT_BITS  => C_CNT_BITS,
            C_RST_POL   => C_RST_POL
        )
        port map(
            -- Inputs
            clk         => clk,
            reset       => reset,
            clr         => clr,
            enable      => enable,   
            stop        => stop,  
            continue    => continue,     
            -- Outputs
            overflow    => overflow,
            div         => div
        );
        
    clk_stimuli : process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;
    
    uut_stimuli : process
    begin
        -- Initial reset
        reset <= C_RST_POL;
        clr <= '0';
        stop <= '0';
        enable <= '0';
        continue <= '0';
        wait for CLK_PERIOD/64; -- Introduce real clock conditions
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        reset <= not C_RST_POL;
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        
        -- Check free running
        enable <= '1';
        wait for 3*(C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;

        -- Check synchronous reset
        clr <= '1';
        wait for CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX)*5;
        clr <= '0';
        continue <= '1';
        wait for 7*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);

        -- Check enable
        enable <= '0';
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        enable <= '1';
        wait for 9*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX/4);
        enable <= '0';
        wait for 7*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        enable <= '1';
        wait for 10*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX/4);
        enable <= '0';
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        enable <= '1';
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        
        -- Check stop signal
        stop <= '1';
        wait for 9*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX/4);
        stop <= '0';

        -- End of stimuli
        wait;
        
    end process;

end Behavioral;