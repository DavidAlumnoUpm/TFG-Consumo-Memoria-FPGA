
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2C_master is
    generic (
            C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
            C_FREQ_MAX   : integer := 125000;       -- 125 KHz en SCL   
            C_CNT_BITS   : integer := 8;            -- 2^8 >= 125000000 / 125000 / 4   
            DEVICE      : std_logic_vector(6 downto 0) := "1010101";
            ADDRESS     : std_logic_vector(7 downto 0) := "10101010";
            DATA        : std_logic_vector(7 downto 0) := "11001010"
            
    );
    Port ( 
            clk     : in std_logic;
            reset   : in std_logic;
            clr     : in std_logic;     
            enable  : in std_logic;
            ON_OFF  : in std_logic;
            R_W     : in std_logic; 
            ACK     : in std_logic;
            SDA     : inout std_logic;
            SCL     : inout std_logic;
            data_out    : out std_logic_vector(7 downto 0)        
    );
end I2C_master;

architecture Behavioral of I2C_master is

    signal overflow, stop_count, stop_scl     : std_logic;
    signal div      : std_logic_vector(1 downto 0);

begin

    CONTADOR_125KHz : entity work.I2C_counter
        generic map(
                    C_FREQ_SYS  => C_FREQ_SYS,
                    C_FREQ_MAX  => C_FREQ_MAX,
                    C_CNT_BITS  => C_CNT_BITS
        )
        port map(
                    clk         => clk,
                    reset       => reset,
                    clr         => clr,
                    stop        => stop_scl,
                    stop_count  => stop_count,
                    enable      => enable,
                    overflow    => overflow,
                    SCL         => SCL,
                    div         => div
        );


    FSM : entity work.I2C_state
        generic map(
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
                    SCL         => SCL,
                    overflow    => overflow,
                    div         => div,
                    ACK         => ACK,
                    SDA         => SDA,
                    stop_count  => stop_count,
                    stop_scl    => stop_scl,
                    data_out    => data_out
        );

end Behavioral;
