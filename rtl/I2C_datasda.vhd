library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2C_datasda is
    generic(
        ADDRESS     : std_logic_vector(6 downto 0) := "1010101";
        DATA        : std_logic_vector(15 downto 0) := "1100101011110000";
        N_BITS_W    : integer := 23; -- Ajuste para escritura de 24 bits (8 + 16)
        N_BITS_R    : integer := 31  -- Ajuste para lectura de 32 bits (0 + 32)
    );
    Port ( 
            clk         : in std_logic;
            reset       : in std_logic; 
            overflow    : in std_logic;
            div         : in std_logic_vector(1 downto 0);                
            sipo        : in std_logic;
            piso        : in std_logic;
            ack_s       : in std_logic;
            R_W         : in std_logic;
            DONE        : in std_logic;
            stop_sda    : in std_logic;
            zero_sda    : in std_logic;
            reading     : in std_logic;
            SDA         : inout std_logic;
            STOP_ack    : out std_logic;
            data_r      : out std_logic_vector(N_BITS_R downto 0)       
    );
end I2C_datasda;

architecture Behavioral of I2C_datasda is
    
    signal save, final_scl, sda_out, stop  : std_logic;
    signal aux  : std_logic_vector(N_BITS_W downto 0);
    signal data_out : std_logic_vector(N_BITS_R downto 0);
    
begin

    -- REGISTROS CON DESPLAZAMIENTO (PISO, SIPO) Y CONTROL DEL SDA EN ACK
    process(clk,reset)
    begin
        if reset = '1' then
            aux <= ADDRESS & R_W & DATA;
            data_out <= (others => '0');
            stop <= '0';
        elsif clk'event and clk = '1' then
            if final_scl = '1' then
                if piso = '1' then
                    if ack_s = '1' then
                        if DONE = '1' then
                            aux(N_BITS_W) <= '1';
                        else
                            aux(N_BITS_W) <= '0';
                        end if;    
                    else
                        -- PARTE PISO
                        aux <= aux(N_BITS_W -1 downto 0) & aux(N_BITS_W);
                    end if;
                end if;
                if sipo = '1' then
                    if ack_s = '1' then
                        stop <= SDA;
                    else
                        -- PARTE SIPO
                        data_out <= data_out(N_BITS_R - 1 downto 0) & SDA;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- SDA
    process(clk,reset)
    begin
        if reset = '1' then
            sda_out <= '1';
        elsif clk'event and clk = '1' then
            if save = '1' then
                if ack_s = '1' then
                    if DONE = '1' then
                        sda_out <= '1';
                    else
                        sda_out <= '0';
                    end if;
                elsif stop_sda = '1' then
                    sda_out <= '1';
                elsif zero_sda = '1' then
                    sda_out <= '0';
                else
                    sda_out <= aux(N_BITS_W);
                end if;
            end if;
        end if;
    end process;
    
    STOP_ack <= '1' when ack_s = '1' and SDA = '1' else '0';
    data_r <= data_out;
    SDA <= 'Z' when reading = '1' else sda_out;
    save <= '1' when (overflow = '1' and div = "00") else '0';
    final_scl <= '1' when (overflow = '1' and div = "11") else '0';

end Behavioral;
