
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_TOP_MASTER is
    generic (
        C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
        C_FREQ_SCL   : integer := 125000        -- 125 KHz en SCL                            
    );
end tb_TOP_MASTER;

architecture Behavioral of tb_TOP_MASTER is

    constant CLK_PERIOD : time := (1000000000/C_FREQ_SYS)* 1ns; -- 125 MHz
    constant SCL_PERIOD : time := (1000000/C_FREQ_SCL)* 1us; -- 125 MHz
    signal clk, reset, ON_OFF, SDA, SCL  : std_logic;
    signal WRITE        : std_logic := '1';
    signal READ         : std_logic := '1';
    signal OPERATION    : std_logic := '0';
    signal DATA_SLAVE   : std_logic_vector(7 downto 0) := x"35";
    signal DATA_OUTPUT  : std_logic_vector(7 downto 0);
    signal DATA_INPUT   : std_logic_vector(7 downto 0) := x"5d";
    signal ADDRESS      : std_logic_vector(6 downto 0) := "1010101";

begin

    TOP_MASTER: entity work.TOP_MASTER
    generic map(
            C_FREQ_SYS      => C_FREQ_SYS,
            C_FREQ_SCL      => C_FREQ_SCL
    )
    port map(
            clk             => clk,
            reset           => reset,
            ON_OFF          => ON_OFF,
            WRITE           => WRITE,
            READ            => READ,
            OPERATION       => OPERATION,
            ADDRESS         => ADDRESS,
            DATA_INPUT      => DATA_INPUT,
            DATA_OUTPUT     => DATA_OUTPUT,
            SDA             => SDA,
            SCL             => SCL
    );
    
    clk_stimuli : process
        begin
            clk <= '1';
            wait for CLK_PERIOD/2;
            clk <= '0';
            wait for CLK_PERIOD/2;
        end process;
        
    MASTER_stimuli : process
        begin
            reset <= '1';
            SDA <= 'Z';
            ON_OFF <= '0';
            wait for SCL_PERIOD/8;
            
            reset <= '0';
            
            wait for SCL_PERIOD/8;
            ON_OFF <= '1';
            wait for CLK_PERIOD + CLK_PERIOD/4;
            ON_OFF <= '0';           
            
            wait for 29*SCL_PERIOD + 5*SCL_PERIOD/4;
            for i in 0 to 6 loop
                SDA <= DATA_SLAVE(7 - i);
                wait for SCL_PERIOD;
            end loop;
            
            SDA <= DATA_SLAVE(0);
            wait for SCL_PERIOD;
            SDA <= 'Z';   
            wait for SCL_PERIOD;
                        
            wait;
           
        end process;    

end Behavioral;
