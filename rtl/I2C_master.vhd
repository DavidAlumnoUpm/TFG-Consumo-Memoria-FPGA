
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2C_master is
    generic (
            C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
            C_FREQ_MAX   : integer := 125000;       -- 125 KHz en SCL   
            ADDRESS      : std_logic_vector(6 downto 0) := "1010101";
            DATA        : std_logic_vector(7 downto 0) := "11001010"
            
    );
    Port ( 
            clk     : in std_logic;
            reset   : in std_logic;
            START   : in std_logic;     
            R_W     : in std_logic; 
            DONE    : out std_logic;
            SDA     : inout std_logic;
            SCL     : out std_logic;
            data_r    : out std_logic_vector(7 downto 0)        
    );
end I2C_master;

architecture Behavioral of I2C_master is

    signal overflow, stop_count, stop_scl, sipo, piso, ack_s, stop_sda, zero_sda, reading     : std_logic;
    signal div      : std_logic_vector(1 downto 0);

begin

    CONTADOR_125KHz : entity work.I2C_counter
        generic map(
                    C_FREQ_SYS  => C_FREQ_SYS,
                    C_FREQ_MAX  => C_FREQ_MAX
        )
        port map(
            clk         => clk,
            reset       => reset,
            stop        => stop_scl, 
            stop_count  => stop_count,     
            overflow    => overflow,
            SCL         => SCL,
            div         => div
        );


    FSM : entity work.I2C_state(Behavioral)
        port map(
            clk         => clk,
            reset       => reset, 
            START       => START,  
            R_W         => R_W,  
            div         => div, 
            overflow    => overflow,
            DONE        => DONE,
            stop_count  => stop_count,
            stop_scl    => stop_scl,
            sipo        => sipo,
            piso        => piso,
            ack_s       => ack_s,
            stop_sda    => stop_sda,
            zero_sda    => zero_sda,
            reading     => reading
        );

    SDA_GEN : entity work.I2C_datasda(Behavioral)
    generic map(
        ADDRESS     => ADDRESS,
        DATA        => DATA
    )
    port map(
        clk         => clk,
        reset       => reset,
        overflow    => overflow, 
        R_W         => R_W,     
        sipo        => sipo,
        piso        => piso,
        ack_s       => ack_s,
        stop_sda    => stop_sda,
        zero_sda    => zero_sda,
        reading     => reading,
        SDA         => SDA,
        div         => div,
        data_r      => data_r
    );

end Behavioral;
