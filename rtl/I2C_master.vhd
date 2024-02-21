library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity I2C_master is
    generic (
                C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
                C_FREQ_MAX   : integer := 100000;       -- 100 KHz
                C_CNT_BITS   : integer := 11;           -- 2^11 >= 125000000 / 100000
                C_RST_POL    : std_logic := '1';         -- Reset poling
                DEVICE       : std_logic_vector(7 downto 0) := "00000000"        -- DIRECCIÓN DEL DISPOSITIVO 
    );
    Port ( 
            clk         : in std_logic;
            reset       : in std_logic;
            clr         : in std_logic;
            enable      : in std_logic;
            SDA         : inout std_logic;
            SCL         : out std_logic;
            ADDRESS     : in std_logic_vector(7 downto 0);    -- DIRECCI?N DE MEMORIA 
            DATA_IN     : in std_logic_vector(7 downto 0);    -- VECTOR DE DATOS (ENTRADA)
            DATA_OUT    : out std_logic_vector(7 downto 0);   -- VECTOR DE DATOS (SALIDA)
            NACK		: out std_logic;
            STOP_ACK    : in std_logic;
            OPERA       : in std_logic;     -- Se pone a 1 (desde fuera) cuando se quiere realizar una operación de LECTURA o ESCRITURA
            READ        : in std_logic;     -- Se pone a 1 (desde fuera) para indicar operación de ESCRITURA
            WRITE       : in std_logic      -- Se pone a 1 (desde fuera) para indicar operación de LECTURA
    );
end I2C_master;

architecture Behavioral of I2C_master is

        signal stop, continue, overflow, stop_div   : std_logic;
        signal div                                  : std_logic_vector(1 downto 0);

begin

    counter_div : entity work.counter(Behavioral)
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

    SCL_out : entity work.I2C_scl(Behavioral)
    port map(
        -- Inputs
        clk         => clk,
        reset       => reset,
        clr         => clr,
        enable      => enable,        
        overflow    => overflow,   
        stop        => stop_div,  
        div         => div,     
        -- Outputs
        scl         => scl
    );
    
    state_machine: entity work.I2C_state(Behavioral)
            generic map(
                    DEVICE      => DEVICE
            )
            port map(
                    clk         => clk,
                    reset       => reset,
                    clr         => clr,
                    enable      => enable,
                    SDA         => SDA,
                    ADDRESS     => ADDRESS,
                    DATA_IN     => DATA_IN,
                    DATA_OUT    => DATA_OUT,
                    NACK        => NACK,
                    STOP_ACK    => STOP_ACK,
                    READ        => READ,
                    OPERA       => OPERA,
                    WRITE       => WRITE,
                    overflow    => overflow,
                    div         => div,
                    continue    => continue,
                    stop_div    => stop_div
            );    

end Behavioral;