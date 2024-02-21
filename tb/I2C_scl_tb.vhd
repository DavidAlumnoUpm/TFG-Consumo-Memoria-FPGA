

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity I2C_scl_tb is
end I2C_scl_tb;

architecture Behavioral of I2C_scl_tb is

    constant CLK_PERIOD : time := 8 ns; -- 125 MHz
    signal clk, reset, clr, enable, overflow, stop, scl : std_logic;
    signal div          : std_logic_vector(1 downto 0);
    constant C_FREQ_SYS : integer := 125000000; -- 125 MHz
    constant C_FREQ_MAX : integer := 100000; -- 100 KHz

begin

    uut : entity work.I2C_scl(Behavioral)
    port map(
        -- Inputs
        clk         => clk,
        reset       => reset,
        clr         => clr,
        enable      => enable,        
        overflow    => overflow,   
        stop        => stop,  
        div         => div,     
        -- Outputs
        scl         => scl
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
        reset <= '1';
        clr <= '0';
        stop <= '0';
        enable <= '0';
        overflow <= '0';
        div <= "00";
        wait for CLK_PERIOD/64; -- Introduce real clock conditions
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        reset <= '0';
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        
        -- Check normal running
        enable <= '1';
        wait for 3*(C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "01";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0'; 
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "10";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0'; 
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "11";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';   
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "00";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';   
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "01";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "10";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';  
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "11";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "00";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';        
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "01";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0'; 
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;                     

        -- Check synchronous reset
        clr <= '1';
        wait for CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX)*5;
        clr <= '0';
        wait for 7*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        
        div <= "00";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "01";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0'; 
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "10";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0'; 
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "11";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';   
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "00";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';   
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "01";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';
        
        -- Check enable
        enable <= '0';
        wait for 9*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX/4);
        enable <= '1';
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        div <= "10";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';  
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "11";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';
        
        -- Check enable
        enable <= '0';
        wait for 9*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX/4);
        enable <= '1';
        wait for 5*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX);
        div <= "00";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0';        
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;
        div <= "01";
        overflow <= '1';
        wait for CLK_PERIOD;
        overflow <= '0'; 
        wait for (C_FREQ_SYS/C_FREQ_MAX)*CLK_PERIOD;      
        
        -- Check stop signal
        stop <= '1';
        wait for 9*CLK_PERIOD*(C_FREQ_SYS/C_FREQ_MAX/4);
        stop <= '0';

        -- End of stimuli
        wait;
        
    end process;

end Behavioral;
