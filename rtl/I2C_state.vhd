library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- FSM
-- 000 - IDLE
-- 001 - START
-- 010 - DEVICE
-- 011 - ADDRESS
-- 100 - SEND
-- 101 - RECEIVE
-- 110 - PRESTOP
-- 111 - STOP

entity I2C_state is
    generic(
            DEVICE      : std_logic_vector(6 downto 0) := "1010101";
            ADDRESS     : std_logic_vector(7 downto 0) := "10101010";
            DATA        : std_logic_vector(7 downto 0) := "11001010"
    );
    Port ( 
            clk         : in std_logic;
            reset       : in std_logic;
            clr         : in std_logic;
            enable      : in std_logic;
            ON_OFF      : in std_logic; -- ON = '1', OFF = '0'
            R_W         : in std_logic; -- WRITE = '0', READ = '1'
            SCL         : in std_logic;
            overflow    : in std_logic;
            div         : in std_logic_vector(1 downto 0);
            ACK         : in std_logic;
            SDA         : inout std_logic;
            stop_count  : out std_logic;
            stop_scl    : out std_logic;
            data_out    : out std_logic_vector(7 downto 0)           
    );
end I2C_state;

architecture Behavioral of I2C_state is

    signal FSM  : std_logic_vector(2 downto 0);
    signal on_off_aux, flanco, final_scl, stop_scl_aux, stop_count_aux, sda_out, reading, save, count, ack_aux, flanco_ack, 
    apaga_ack, clr_emergencia, clr_total  : std_logic;
    signal cont : unsigned (3 downto 0);
    signal aux, aux_multiplexor, data_aux  : std_logic_vector(7 downto 0);
    

begin
    
    -- FLANCO ON_OFF y ACK (BIESTABLE D)
    process(clk,reset)
    begin
        if reset = '1' then
            on_off_aux <= '0';
            ack_aux <= '0';
        elsif clk'event and clk = '1' then
            if clr = '1' then
                on_off_aux <= '0';
                ack_aux <= '0';
            elsif enable = '1' then
                on_off_aux <= ON_OFF;
                ack_aux <= ACK;
            end if;
        end if;
    end process;
    
    -- BIESTABLE T para señal de apaga_ack
    process(clk,reset)
    begin
        if reset = '1' then
            apaga_ack <= '0';
        elsif clk'event and clk = '1' then
            if clr = '1' then
                apaga_ack <= '0';
            elsif enable = '1' then
                if flanco_ack = '1' then
                    apaga_ack <= not apaga_ack;
                end if;
            end if;
        end if;
    end process;    

    --FSM
    process(clk,reset)
    begin
        if reset = '1' then
            FSM <= "000";
            stop_count_aux <= '1';
            stop_scl_aux <= '1';
        elsif clk'event and clk = '1' then
            if clr_total = '1' then
                FSM <= "000";
                stop_count_aux <= '1';
                stop_scl_aux <= '1';   
            elsif enable = '1' then
                if FSM = "000" then
                    stop_count_aux <= '1';
                    stop_scl_aux <= '1';
                    if flanco = '1' then
                        FSM <= "001";
                    end if;
                elsif FSM = "001" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1';  
                    if final_scl = '1' then
                        FSM <= "010";
                    end if;
                elsif FSM = "010" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    if final_scl = '1' then
                            if cont = "1000" then
                                FSM <= "011";

                            end if;
                    end if;  
                elsif FSM = "011" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    if final_scl = '1' then
                        if cont = "1000" then
                                if R_W = '1' then
                                    FSM <= "101";
                                else
                                    FSM <= "100";
                                end if;
                        end if;
                   end if;     
                 elsif FSM = "101" or FSM = "100" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    if final_scl = '1' then
                        if cont = "1000" then
                                FSM <= "110";
                        end if;    
                    end if; 
                elsif FSM = "110" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1'; 
                    if final_scl = '1' then
                        FSM <= "111";
                    end if; 
                elsif FSM = "111" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1'; 
                    if final_scl = '1' then
                        FSM <= "000";
                    end if;                                                                                            
                end if;             
            end if;
        end if;
    end process;
    
    -- CONTADOR 0 A 8
    process(clk,reset)
    begin
        if reset = '1' then
            cont <= (others => '0');
        elsif clk'event and clk = '1' then
            if clr = '1' then
                cont <= (others => '0');
            elsif enable = '1' then
                if count = '1' then
                    if cont = "1000" then
                        cont <= (others => '0');
                    else
                        cont <= cont + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- SELECTOR
    with FSM select
        aux_multiplexor     <=  DEVICE&R_W when "001",
                                ADDRESS when "010",
                                DATA when "011",
                                "00000000" when others;
                                
    -- REGISTRO DE DESPLAZAMIENTO PARA LECTURA
    process(clk,reset)
    begin
        if reset = '1' then
            data_aux <= (others => '0');
        elsif clk'event and clk = '1' then
            if clr = '1' then
                data_aux <= (others => '0');
            elsif enable = '1' then
                if FSM /= "101" then
                    data_aux <= (others => '0');
                elsif cont /= "1000" then
                    if count = '1' and cont /= "0111" then
                        data_aux <= data_aux(6 downto 0)&data_aux(7);
                    elsif save = '1' then
                        data_aux(0) <= SDA;
                    end if;
                else
                    data_aux <= data_aux;
                end if;
            end if;
        end if;
    end process;
    
    -- SDA_OUT
    process(clk,reset)
    begin
        if reset = '1' then
            sda_out <= '1';
        elsif clk'event and clk = '1' then
            if clr = '1' then
                sda_out <= '1';
            elsif enable = '1' then
                if FSM = "000" or FSM = "111" then
                    sda_out <= '1';
                elsif FSM = "001" or FSM = "110" then
                    sda_out <= '0';
                elsif save = '1' then
                    sda_out <= aux(7);     
                end if;
            end if;
        end if;
    end process;    
    
    -- REGISTRO DE DESPLAZAMIENTO PARA ESCRITURA
    process(clk,reset)
    begin
        if reset = '1' then
            aux <= aux_multiplexor;
        elsif clk'event and clk = '1' then
            if clr = '1' then
                aux <= aux_multiplexor;
            elsif enable = '1' then
                if count = '1' then
                    if (cont = "1000") then
                        aux <= aux_multiplexor;
                    else
                        aux <= aux(6 downto 0) & '0';
                    end if;
                elsif (FSM = "001" and save = '1') then
                    aux <= aux_multiplexor;
                end if;
            end if;
        end if;
    end process;
    
    data_out <= data_aux;
    count <= final_scl and (not stop_scl_aux);
    final_scl <= '1' when (overflow = '1' and div = "11") else '0';
    flanco <= '1' when (ON_OFF = '1' and on_off_aux = '0') else '0';
    flanco_ack <= '1' when (ACK = '1' and ack_aux = '0') else '0';
    stop_scl <= stop_scl_aux;
    stop_count <= stop_count_aux;
    reading <= '1' when (cont = "1000" and (FSM = "010" or FSM = "011" or FSM = "100")) or (cont /= "1000" and FSM = "101") else '0';
    save <= '1' when (overflow = '1' and div = "00") else '0';
    SDA <= 'Z' when reading = '1' else sda_out;
    clr_emergencia <=   '1' when (apaga_ack = '1' and FSM = "101" and cont = "1000" and final_scl = '1') or (SDA = '1' and (FSM = "100" or 
                        FSM = "011" or FSM = "010")  and cont = "1000" and final_scl = '1') else '0';
    clr_total <= clr or clr_emergencia;
    
end Behavioral;

