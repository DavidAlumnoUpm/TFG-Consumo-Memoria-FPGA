library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity tb_I2C_master is
    generic ( 
                C_CNT_BITS      : natural := 8;                                     -- Counter resolution
                C_CNT_MAX       : natural := 200;                                   -- Maximum count
                C_RSTPOL        : std_logic := '1';                                 -- Reset poling
                DEVICE          : std_logic_vector(7 downto 0) := "01000010"        -- DIRECCI?N DEL DISPOSITIVO 
    );
end tb_I2C_master;

architecture Behavioral of tb_I2C_master is

     constant CLK_PERIOD : time := 8 ns; -- 125 MHz
     signal clk, reset, clr, enable, SDA_IN, SDA_OUT, SCL, NACK, STOP_ACK, OPERA, READ, WRITE : std_logic;
     signal ADDRESS, DATA_IN, DATA_OUT : std_logic_vector(7 downto 0);
     
begin

    uut: entity work.I2C_master(Behavioral)
        generic map(
                        C_CNT_BITS  => C_CNT_BITS,
                        C_CNT_MAX   => C_CNT_MAX,
                        C_RSTPOL    => C_RSTPOL,
                        DEVICE      => DEVICE
        )
        port map(
                        clk         => clk,
                        reset       => reset,
                        clr         => clr,
                        enable      => enable,
                        SDA_IN      => SDA_IN,
                        SDA_OUT     => SDA_OUT,
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
    -- Señales iniciales para causar estado de reset
        reset <= '1';
        OPERA <= '0';
        SDA_IN <= '0'; -- Hasta la operación de LECTURA se deja a '0' la señal de entrada del SDA
        clr <= '0';
        enable <= '0';
        ADDRESS <= "00000010"; -- Se introducen los bits correspondientes a la dirección de memoria del dispositivo
        DATA_IN <= "00000101"; -- Se introducen los bits correspondientes a transmitir en una potencial operación de ESCRITURA
        STOP_ACK <= '0';
        READ <= '0';
        WRITE <= '0';
        wait for 100 ns;
    -- Se permite que la parte secuencial trabaje y se introduce el tipo de operación (ESCRITURA)
        WRITE <= '1';
        reset <= '0';
        enable <= '1';
        wait for 2000 ns;
    -- Se introduce la orden de empezar la operación de ESCRITURA (OPERA funciona a modo de botón)
        OPERA <= '1';
        wait for 2000 ns; -- Se registra la orden (en una señal intermedia flanco_opera)
        OPERA <= '0';
        wait for 400 us; -- Se realiza la operación de ESCRITURA y al terminar se vuelve a un estado IDLE (libre para comunicar)
        ADDRESS <= "10011111";
        DATA_IN <= "00101010";
        OPERA <= '1'; -- Se introduce la orden de empezar la operación (sigue siendo ESCRITURA)
        wait for 2000 ns; -- Se registra la orden (en una señal intermedia flanco_opera)
        OPERA <= '0';
        wait for 400 us;
        OPERA <= '1'; -- Se introduce la orden de empezar la operación
        WRITE <= '0'; -- Se quita la orden de operación de ESCRITURA
        SDA_IN <= '0';
        wait for 2000 ns; -- Se registra la orden (en una señal intermedia flanco_opera)
        READ <= '1'; -- Se introduce la orden de operación de LECTURA (y se inicia la operación al estar flanco_opera = '1')
        OPERA <= '0';
        wait for 90 us;
        -- Se procede a simular que el dispositivo esclavo envía al maestro el byte de datos "10101010"
        SDA_IN <= '1';
        wait for 4800 ns; -- 4800 = 3 ciclos de SCL x 200 del contador x 8ns
        SDA_IN <= '0';
        wait for 4800 ns;
        SDA_IN <= '1';
        wait for 4800 ns;
        SDA_IN <= '0';
        wait for 4800 ns;
        SDA_IN <= '1';
        wait for 4800 ns;
        SDA_IN <= '0';
        wait for 4800 ns;
        SDA_IN <= '1';
        wait for 4800 ns;
        SDA_IN <= '0';
        wait for 100 us;
        -- Se procede a simular una operación de ESCRITURA interrumpida por una señal de reset asíncrono
        WRITE <= '1';
        READ <= '0';
        wait for 4800 ns;
        OPERA <= '1';
        wait for 10 us;
        OPERA <= '0';
        wait for 70 us;
        reset <= '1';
        wait for 20 us;
        reset <= '0';
        wait for 10 us;
        -- Se procede a simular una operación de LECTURA interrumpida por una señal de reset síncrono
        WRITE <= '0';
        READ <= '1';
        wait for 4800 ns;
        OPERA <= '1';
        wait for 10 us;
        OPERA <= '0';
        wait for 70 us;
        clr <= '1';
        wait for 20 us;
        clr <= '0';
        wait for 10 us;
        -- Se procede a simular una operación de ESCRITURA interrumpida por una señal de ACKNOWLEDGE (ACK = '1') que transmite el esclavo
        WRITE <= '1';
        READ <= '0';
        wait for 4800 ns;
        OPERA <= '1';
        wait for 4800 ns;
        OPERA <= '0';
        wait for 4800*7 ns;
        SDA_IN <= '1';
        wait for 4800*2 ns;
        SDA_IN <= '0';
        wait for 10 us;
        -- Se procede a simular una operación de LECTURA interrumpida por una señal de ACKNOWLEDGE que transmite el maestro (STOP_ACK = '1')
        WRITE <= '0';
        READ <= '1';
        STOP_ACK <= '1';
        wait for 4800 ns;
        OPERA <= '1';
        wait for 10 us;
        OPERA <= '0';
        wait;
    end process;

end Behavioral;