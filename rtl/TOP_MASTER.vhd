
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity TOP_MASTER is
    generic (
            C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
            C_FREQ_SCL   : integer := 125000        -- 125 KHz en SCL                            
    );
    Port ( 
            clk     : in std_logic;
            reset   : in std_logic;
            ON_OFF  : in std_logic;
            WRITE   : in std_logic; -- I2C write command
            READ    : in std_logic; -- I2C read command   
            OPERATION   : in std_logic;  -- '0' = I2C, '1' = PMBUS              
            ADDRESS      : in std_logic_vector(6 downto 0);
            DATA_INPUT  : in std_logic_vector(7 downto 0); -- Aquí hay que ajustar la longitud del vector (MÚLTIPLE DE 8 - 1 down to 0)
            DATA_OUTPUT : out std_logic_vector(7 downto 0); -- Aquí hay que ajustar la longitud del vector (MÚLTIPLE DE 8 - 1 down to 0)                  
            SDA     : inout std_logic;
            SCL     : out std_logic
    );
end TOP_MASTER;

architecture Behavioral of TOP_MASTER is

    signal overflow, stop_count, stop_scl, sipo, piso, ack_s, stop_sda, zero_sda, reading, condition, START, R_W, DONE     : std_logic;
    signal div      : std_logic_vector(1 downto 0);
    signal DATA_IN, DATA_READ  : std_logic_vector(7 downto 0);
    signal BYTES_W, BYTES_R : std_logic_vector(3 downto 0);

begin

    OPERATION_CHOOSE : entity work.operation
        port map(
            clk         => clk,
            reset       => reset,
            ON_OFF      => ON_OFF,
            stop_count  => stop_count,
            stop_scl    => stop_scl,
            WRITE       => WRITE,
            READ        => READ,
            OPERATION   => OPERATION,
            ack_s       => ack_s,
            DONE        => DONE,
            div         => div,
            overflow    => overflow,
            DATA_INPUT  => DATA_INPUT,
            DATA_OUTPUT => DATA_OUTPUT,
            DATA_IN     => DATA_IN,
            DATA_READ   => DATA_READ,
            BYTES_W     => BYTES_W,
            BYTES_R     => BYTES_R,
            R_W         => R_W,
            START       => START
        );

    CONTADOR_125KHz_2 : entity work.I2C_counter
        generic map(
                    C_FREQ_SYS  => C_FREQ_SYS,
                    C_FREQ_SCL  => C_FREQ_SCL
        )
        port map(
            clk         => clk,
            reset       => reset,
            stop        => stop_scl, 
            stop_count  => stop_count,
            condition   => condition,   
            DONE        => DONE,  
            overflow    => overflow,
            SCL         => SCL,
            div         => div
        );


    FSM_2 : entity work.I2C_state(Behavioral)
        port map(
            clk         => clk,
            reset       => reset, 
            START       => START,  
            R_W         => R_W,  
            div         => div, 
            overflow    => overflow,
            SDA         => SDA,
            DONE        => DONE,
            stop_count  => stop_count,
            stop_scl    => stop_scl,
            sipo        => sipo,
            piso        => piso,
            ack_s       => ack_s,
            stop_sda    => stop_sda,
            zero_sda    => zero_sda,
            reading     => reading,
            condition   => condition,
            BYTES_W     => BYTES_W,
            BYTES_R     => BYTES_R            
        );

    SDA_GEN_2 : entity work.I2C_datasda(Behavioral)
    port map(
        clk         => clk,
        reset       => reset,
        overflow    => overflow, 
        R_W         => R_W,  
        DONE        => DONE,       
        sipo        => sipo,
        piso        => piso,
        ack_s       => ack_s,
        stop_sda    => stop_sda,
        zero_sda    => zero_sda,
        reading     => reading,
        DATA_IN     => DATA_IN,
        ADDRESS     => ADDRESS,
        SDA         => SDA,
        div         => div,
        DATA_READ   => DATA_READ
    );    

end Behavioral;
