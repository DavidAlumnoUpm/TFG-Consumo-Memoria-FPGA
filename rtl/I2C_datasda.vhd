library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2C_datasda is
    generic( 
        BYTES_W     : integer := 2;
        BYTES_R     : integer := 4
 -- Ajuste para escritura de 24 bits (8 + 16)
-- Ajuste para lectura de 32 bits (0 + 32)
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
            ADDRESS     : in std_logic_vector(6 downto 0);
            DATA_IN     : in std_logic_vector(8*BYTES_W - 1 downto 0);
            SDA         : inout std_logic;
            DATA_READ   : out std_logic_vector(8*BYTES_R - 1 downto 0)       
    );
end I2C_datasda;

architecture Behavioral of I2C_datasda is
    
    signal save, final_scl, sda_out  : std_logic;
    signal aux  : std_logic_vector(8*BYTES_W + 7 downto 0);
    signal data_out : std_logic_vector(8*BYTES_R - 1 downto 0);
    
begin

    -- REGISTROS CON DESPLAZAMIENTO (PISO, SIPO) Y CONTROL DEL SDA EN ACK
    process(clk,reset)
    begin
        if reset = '1' then
            aux <= ADDRESS & R_W & DATA_IN;
            data_out <= (others => '0');
        elsif clk'event and clk = '1' then
            if stop_sda = '1' then
                aux <= ADDRESS & R_W & DATA_IN;
            end if;
            if final_scl = '1' then
                if piso = '1' then
                    if ack_s = '1' then
                        if DONE = '1' then
                            aux(8*BYTES_W + 7) <= '1';
                        else
                            aux(8*BYTES_W + 7) <= '0';
                        end if;    
                    else
                        -- PARTE PISO
                        aux <= aux(8*BYTES_W + 6 downto 0) & aux(8*BYTES_W + 7);
                    end if;
                end if;
                if sipo = '1' then
                    if ack_s = '1' then
                    else
                        -- PARTE SIPO
                        data_out <= data_out(8*BYTES_R - 2 downto 0) & SDA;
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
                    sda_out <= aux(8*BYTES_W + 7);
                end if;           
            end if;
        end if;
    end process;
    
    DATA_READ <= data_out;
    SDA <= 'Z' when reading = '1' else sda_out;
    save <= '1' when (overflow = '1' and div = "00") else '0';
    final_scl <= '1' when (overflow = '1' and div = "11") else '0';

end Behavioral;
