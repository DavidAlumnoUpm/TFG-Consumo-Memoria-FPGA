
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_I2C_master is
        generic (
                    C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
                    C_FREQ_MAX   : integer := 125000;       -- 125 KHz en SCL   
                    C_CNT_BITS   : integer := 8;            -- 2^8 >= 125000000 / 125000 / 4   
                    DEVICE      : std_logic_vector(6 downto 0) := "1010101";
                    ADDRESS     : std_logic_vector(7 downto 0) := "10101010";
                    DATA        : std_logic_vector(7 downto 0) := "11001010"        
        );
end tb_I2C_master;

architecture Behavioral of tb_I2C_master is

    constant CLK_PERIOD : time := 8 ns; -- 125 MHz
    signal clk, reset, clr, enable, ON_OFF, R_W, ACK, SDA, SCL     : std_logic;
    signal data_out     : std_logic_vector(7 downto 0);

begin

    I2C_master : entity work.I2C_master
        generic map(
                    C_FREQ_SYS  => C_FREQ_SYS,
                    C_FREQ_MAX  => C_FREQ_MAX,
                    C_CNT_BITS  => C_CNT_BITS,
                    DEVICE      => DEVICE,
                    ADDRESS     => ADDRESS,
                    DATA        => DATA
        )
        port map(
                    clk         => clk,
                    reset       => reset,
                    clr         => clr,
                    enable      => enable,
                    ON_OFF      => ON_OFF,
                    R_W         => R_W,
                    ACK         => ACK,
                    SDA         => SDA,
                    SCL         => SCL,
                    data_out    => data_out
        );
        
    clk_stimuli : process
        begin
            clk <= '1';
            wait for CLK_PERIOD/2;
            clk <= '0';
            wait for CLK_PERIOD/2;
        end process;
    
    I2C_stimuli : process
        begin
            reset <= '1';
            clr <= '0';
            enable <= '0';
            ON_OFF <= '0';
            R_W <= '0';
            ACK <= '0';
            SDA <= 'Z';
            wait for 1 us;
            
            reset <= '0';
            enable <= '1';
            wait for 10 ns;
            
            ON_OFF <= '1';
            wait for 10 ns;
            ON_OFF <= '0';
            
            wait for 250 us;
            R_W <= '1';
            wait for 1 us;
            ON_OFF <= '1';
            wait for 10 ns;
            ON_OFF <= '0';
            wait for 154 us;      
            SDA <= '1';
            wait for 8 us;
            SDA <= '1';
            wait for 8 us;
            SDA <= '1';
            wait for 8 us;
            SDA <= '1';
            wait for 8 us;
            SDA <= '0';
            wait for 8 us;
            SDA <= '0';
            wait for 8 us;
            SDA <= '0';
            wait for 8 us;
            SDA <= '0';
            wait for 8 us;
            SDA <= 'Z';             
            wait;
    end process;        

end Behavioral;
