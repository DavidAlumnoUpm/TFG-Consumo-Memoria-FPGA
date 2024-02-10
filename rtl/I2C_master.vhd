library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity I2C_master is
    generic (
            C_CNT_BITS      : natural := 8;                                     -- Counter resolution
            C_CNT_MAX       : natural := 200;           
            C_OV            : boolean := true;                                 -- Maximum count
            C_RSTPOL        : std_logic := '1';                                 -- Reset poling
            DEVICE          : std_logic_vector(7 downto 0) := "00000000"        -- DIRECCIÓN DEL DISPOSITIVO 
    );
    Port ( 
            clk         : in std_logic;
            reset       : in std_logic;
            clr         : in std_logic;
            enable      : in std_logic;
            SDA_IN      : in std_logic;
            SDA_OUT     : out std_logic;
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


    signal clk_filtrado     : std_logic;
    signal sda_in_q         : std_logic;
    signal sda_in_qq        : std_logic;
    type estado is (IDLE, START, SENDBIT, SENDUP, SENDDOWN, ACK, ACKUP, ACKDOWN, WRITE1, PRESTOP, STOP, READ1,
                        RECBIT, RECUP, RECDOWN, SENDACK, SENDACKUP, SENDACKDOWN);
    signal maquina          : estado;
    signal nuevo_estado     : estado;
    signal aux              : std_logic_vector(7 downto 0); -- Toma las se?ales a copiar en SDA_OUT
    signal count            : unsigned(3 downto 0); -- Cuenta hasta 8
    signal ack_value        : std_logic;
    signal stop_ack_q       : std_logic;
    signal opera_q, opera_qq: std_logic;
    signal flanco_opera     : std_logic;
    signal addr             : std_logic;
    signal dat              : std_logic;
    
    -- Señales del contador
    signal counter_std      : std_logic_vector((C_CNT_BITS - 1) downto 0);    

begin

    clk_filt :  entity work.counter(Behavioral)
        generic map(
            C_CNT_BITS  => C_CNT_BITS,
            C_CNT_MAX   => C_CNT_MAX,
            C_OV        => C_OV,
            C_RSTPOL    => C_RSTPOL
        )
        port map(
            -- Inputs
            clk         => clk,
            reset       => reset,
            clr         => clr,
            enable      => enable,          
            -- Outputs
            overflow    => clk_filtrado,
            count       => counter_std
        );
    

    
    -- Registro para guardar el valor de SDA_IN
    process(clk,reset)
    begin
        if reset = '1' then
            sda_in_q <= '0';
            sda_in_qq <= '0';
            stop_ack_q <= '0';
            opera_q <= '0';
            opera_qq <= '0';
        elsif clk'event and clk = '1' then
            if clr = '1' then
                sda_in_q <= '0';
                sda_in_qq <= '0';
                stop_ack_q <= '0';
                opera_q <= '0';
                opera_qq <= '0';
            elsif enable = '1' then
                sda_in_q <= SDA_IN;
                sda_in_qq <= sda_in_q;
                stop_ack_q <= STOP_ACK;
                opera_q <= OPERA;
                opera_qq <= opera_q;
            end if;
        end if;
    end process;
    
    process(clk,reset)
    begin
        if reset = '1' then
            flanco_opera <= '0';
        elsif clk'event and clk = '1' then
            if clr = '1' or maquina = STOP then
                flanco_opera <= '0';
            elsif enable = '1' then
                if opera_q = '1' and opera_qq = '0' then
                    flanco_opera <= not flanco_opera;
                else 
                    flanco_opera <= flanco_opera;
                end if;
            end if;
        end if;
    end process;
    
    
    -- M?quina de estados
    process(clk,reset)
    begin
        if reset = '1' then
            maquina <= IDLE;
            aux <= (others => '0');
            count <= "0000";
            SCL <= '1';
            SDA_OUT <= '1';
            NACK <= '0';
            DATA_OUT <= (others => '0');
            addr <= '0';
            dat <= '0';
            nuevo_estado <= IDLE;
        elsif clk'event and clk = '1' then
            if clr = '1' then
                maquina <= IDLE;
                aux <= (others => '0');
                count <= "0000";
                SCL <= '1';
                SDA_OUT <= '1';
                NACK <= '0';
                DATA_OUT <= (others => '0');
                addr <= '0';
                dat <= '0';
                nuevo_estado <= IDLE;
            elsif enable = '1' then
                if maquina = IDLE then
                    SCL <= '1';
                    SDA_OUT <= '1';
                    NACK <= '0';
                    DATA_OUT <= (others => '1');
                    count <= "0000";
                    addr <= '0';
                    dat <= '0';
                        if (clk_filtrado = '1' and (WRITE = '1' or READ = '1') and (flanco_opera = '1') and(not(nuevo_estado = STOP))) then
                            maquina <= START;
                        end if;
                        if (nuevo_estado = STOP and flanco_opera = '1') then
                            nuevo_estado <= IDLE;
                        end if;
                elsif maquina <= START then
                    SCL <= '1';
                    SDA_OUT <= '0'; --CONDICI?N DE INICIO
                    NACK <= '0';
                    if clk_filtrado = '1' then
                        count <= "0000";
                        SCL <= '0';
                        aux(7 downto 1) <= DEVICE(6 downto 0);
                        if WRITE = '1' then
                            nuevo_estado <= WRITE1;
                            aux(0) <= '0';
                        elsif READ = '1' then
                            nuevo_estado <= READ1;
                            aux(0) <= '1';
                        end if;
                        maquina <= SENDBIT;
                    end if;
                elsif maquina = SENDBIT then
                    if clk_filtrado = '1' then
                        SCL <= '0';
                        SDA_OUT <= aux(7);
                        aux(7 downto 1) <= aux(6 downto 0);
                        count <= count + 1;
                        NACK <= '0';
                        maquina <= SENDUP;
                    end if;
                elsif maquina = SENDUP then
                    if clk_filtrado = '1' then
                        SCL <= '1';
                        NACK <= '0';
                        maquina <= SENDDOWN;
                    end if;
                elsif maquina = SENDDOWN then
                    if clk_filtrado = '1' then
                        SCL <= '0';
                        NACK <= '0';
                        if count(3) = '1' then
                            maquina <= ACK;
                        else
                            maquina <= SENDBIT;
                        end if;
                    end if;
                elsif maquina = ACK then
                    if clk_filtrado = '1' then
                        NACK <= '0';
                        SCL <= '0';
                        SDA_OUT <= '1';
                        maquina <= ACKUP;
                    end if;
                elsif maquina = ACKUP then
                    if clk_filtrado = '1' then
                        NACK <= '0';
                        SCL <= '1';
                        if sda_in_qq = '1' then
                            ack_value <= '1';
                        else
                            ack_value <= '0';
                        end if;
                        maquina <= ACKDOWN;
                    end if;
                elsif maquina = ACKDOWN then
                    if clk_filtrado = '1' then
                        NACK <= '0';
                        SCL <= '0';
                        maquina <= nuevo_estado;
                    end if;
                elsif maquina = WRITE1 then
                    if ack_value = '1' then
                        NACK <= '1';
                        SCL <= '0';
                        if clk_filtrado = '1' then
                            ack_value <= '0';
                            SDA_OUT <= '0';
                            maquina <= PRESTOP;
                        end if;
                    else
                        if WRITE = '1' then
                            if addr = '1' and dat = '0' then
                                aux <= DATA_IN;
                                count <= "0000";
                                maquina <= SENDBIT;
                                dat <= '1';
                            elsif addr = '0' then
                                aux <= ADDRESS;
                                count <= "0000";
                                maquina <= SENDBIT;
                                addr <= '1';
                            else
                                count <= "0000";
                                maquina <= PRESTOP;
                            end if;
                        elsif READ = '1' then
                            SDA_OUT <= '1';
                            SCL <= '0';
                            if clk_filtrado = '1' then
                                maquina <= IDLE;  
                            end if;
                        else
                            SCL <= '0';
                            if clk_filtrado = '1' then
                                SDA_OUT <= '0';
                                maquina <= PRESTOP;
                            end if;
                        end if;
                    end if;
                elsif maquina = READ1 then
                    if ack_value = '1' then
                        NACK <= '1';
                        SCL <= '0';
                        if clk_filtrado = '1' then
                            ack_value <= '0';
                            SDA_OUT <= '0';
                            maquina <= PRESTOP;
                        end if;
                    else
                        if READ = '1' then
                            if addr = '1' and dat = '0' then
                                count <= "0000";
                                aux <= (others => '0');
                                maquina <= RECBIT;
                                dat <= '1';
                            elsif addr = '0' then
                                count <= "0000";
                                aux <= ADDRESS;
                                maquina <= SENDBIT;
                                addr <= '1';
                            else
                                count <= "0000";
                                maquina <= PRESTOP;
                            end if;
                        elsif WRITE = '1' then
                            SDA_OUT <= '1';
                            SCL <= '0';
                            if clk_filtrado = '1' then
                                maquina <= IDLE;  
                            end if;
                        else
                            SCL <= '0';
                            if clk_filtrado = '1' then
                                SDA_OUT <= '0';
                                maquina <= PRESTOP;
                            end if;
                        end if;
                    end if;
                elsif maquina = RECBIT then
                    if clk_filtrado = '1' then
                        SDA_OUT <= '1';
                        SCL <= '0';
                        NACK <= '0';
                        count <= count + 1;
                        maquina <= RECUP;
                    end if;
                elsif maquina = RECUP then
                    if clk_filtrado = '1' then
                        SCL <= '1';
                        NACK <= '0';
                        aux(7 downto 1) <= aux(6 downto 0);
                        aux(0) <= sda_in_qq;
                        maquina <= RECDOWN;
                    end if;
                elsif maquina = RECDOWN then
                    if clk_filtrado = '1' then
                        SCL <= '0';
                        NACK <= '0';
                        if count(3) = '1' then
                            maquina <= SENDACK;
                        else
                            maquina <= RECBIT;
                        end if;
                    end if;
                elsif maquina = SENDACK then
                    if clk_filtrado = '1' then
                        SCL <= '0';
                        if stop_ack_q = '1' then
                            SDA_OUT <= '1';
                        else
                            SDA_OUT <= '0';
                        end if;
                        DATA_OUT <= aux;
                        maquina <= SENDACKUP;
                    end if;
                elsif maquina = SENDACKUP then
                    if clk_filtrado = '1' then
                        SCL <= '1';
                        NACK <= '0';
                        maquina <= SENDACKDOWN;
                    end if;
                elsif maquina = SENDACKDOWN then
                    if clk_filtrado = '1' then
                        NACK <= '0';
                        SCL <= '0';
                        if stop_ack_q = '1'or sda_in_qq = '1' then
                            maquina <= PRESTOP;
                        else
                            maquina <= READ1;
                        end if;
                    end if;
                elsif maquina = PRESTOP then
                    if clk_filtrado = '1' then
                        NACK <= '0';
                        SCL <= '1';
                        SDA_OUT <= '0';
                        maquina <= STOP;
                    end if;
                elsif maquina = STOP then
                    if clk_filtrado = '1' then
                        NACK <= '0';
                        SCL <= '1';
                        SDA_OUT <= '1';
                        maquina <= IDLE;
                        nuevo_estado <= STOP;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;