library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity tb_I2C_master is
    generic ( 
                C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
                C_FREQ_MAX   : integer := 100000;       -- 100 KHz
                C_CNT_BITS   : integer := 11;           -- 2^11 >= 125000000 / 100000
                C_RST_POL    : std_logic := '1';         -- Reset poling                               -- Reset poling
                DEVICE          : std_logic_vector(7 downto 0) := "01000010"        -- DIRECCI?N DEL DISPOSITIVO 
    );
end tb_I2C_master;

architecture Behavioral of tb_I2C_master is

     constant CLK_PERIOD : time := 8 ns; -- 125 MHz
     signal clk, reset, clr, enable, SDA, SCL, NACK, STOP_ACK, OPERA, READ, WRITE : std_logic;
     signal ADDRESS, DATA_IN, DATA_OUT : std_logic_vector(7 downto 0);
     
begin

    uut: entity work.I2C_master(Behavioral)
        generic map(
                        C_FREQ_SYS  => C_FREQ_SYS,
                        C_FREQ_MAX  => C_FREQ_MAX,
                        C_CNT_BITS  => C_CNT_BITS,
                        C_RST_POL   => C_RST_POL,
                        DEVICE      => DEVICE
        )
        port map(
                        clk         => clk,
                        reset       => reset,
                        clr         => clr,
                        enable      => enable,
                        SDA         => SDA,
                        SCL         => SCL,
                        ADDRESS     => ADDRESS,
                        DATA_IN     => DATA_IN,
                        DATA_OUT    => DATA_OUT,
                        NACK        => NACK,
                        STOP_ACK    => STOP_ACK,
                        READ        => READ,
                        OPERA       => OPERA,
                        WRITE       => WRITE
        );
        
    clk_stimuli : process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;
            
    uut_stimuli: process
    begin
        
        -- Señales de inicio
        reset <= '1';
        clr <= '0';
        enable <= '0';
        SDA <= 'Z';
        ADDRESS <= "00110101";
        DATA_IN <= "10110100";
        STOP_ACK <= '0';
        READ <= '0';
        OPERA <= '0';
        WRITE <= '0';
        
        -- Puesta en marcha
        wait for 1 us;
        reset <= '0';
        wait for 1 us;
        enable <= '1';
        WRITE <= '1';
        wait for 1 us;
        OPERA <= '1';
        wait for 1 us;
        OPERA <= '0';
        
        -- Operación de Escritura
        wait for 83 us;
        SDA <= '0';
        wait for 10 us;
        SDA <= 'Z';
        wait for 80 us;
        SDA <= '0';
        wait for 10 us;
        SDA <= 'Z';
        wait for 80 us;
        SDA <= '0';
        wait for 10 us;
        SDA <= 'Z';
        
        -- Operación de Lectura
        wait for 10 us;
        WRITE <= '0';
        READ <= '1';
        wait for 10 us;
        OPERA <= '1';
        wait for 5 us;
        OPERA <= '0';
        wait for 78 us;
        SDA <= '0';
        wait for 10 us;
        SDA <= 'Z';
        wait for 80 us;
        SDA <= '0';
        wait for 10 us;
        -- Lectura 8 bits
        SDA <= '1';
        wait for 10 us;
        SDA <= '0';  
        wait for 10 us;
        SDA <= '1';
        wait for 10 us;
        SDA <= '0';  
        wait for 10 us;
        SDA <= '1';
        wait for 10 us;
        SDA <= '0';  
        wait for 10 us;
        SDA <= '1';
        wait for 10 us;
        SDA <= '0';  
        wait for 10 us;                              
        SDA <= 'Z';        
        
        wait;
    end process;

end Behavioral;