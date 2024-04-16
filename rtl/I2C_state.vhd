library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- FSM
-- 0000 - IDLE
-- 0001 - START
-- 0010 - ADDRESS
-- 0011 - ADDRESS_ACK
-- 0100 - SEND
-- 0101 - RECEIVE
-- 0110 - DATA_ACK
-- 0111 - PRESTOP
-- 1000 - STOP

entity I2C_state is
    Port ( 
            clk         : in std_logic;
            reset       : in std_logic;
            START       : in std_logic; -- ON = '1', OFF = '0'
            R_W         : in std_logic; -- WRITE = '0', READ = '1'
            overflow    : in std_logic;
            div         : in std_logic_vector(1 downto 0);
            SDA         : in std_logic;
            DONE        : out std_logic;
            stop_count  : out std_logic;
            stop_scl    : out std_logic;
            sipo        : out std_logic;
            piso        : out std_logic;
            ack_s       : out std_logic;
            stop_sda    : out std_logic;
            zero_sda    : out std_logic;
            reading     : out std_logic;
            condition   : out std_logic;
            BYTES_W     : in std_logic_vector(3 downto 0);
            BYTES_R     : in std_logic_vector(3 downto 0)    
    );
end I2C_state;

architecture Behavioral of I2C_state is

    signal FSM  : std_logic_vector(3 downto 0);
    signal final_scl, stop_scl_aux, stop_count_aux, save, final_count, s_ack  : std_logic;
    signal cont : unsigned (2 downto 0);
    signal byte_w   : integer range 0 to to_integer(unsigned(BYTES_W));
    signal byte_r   : integer range 0 to to_integer(unsigned(BYTES_R));
    
begin

    --FSM
    process(clk,reset)
    begin
        if reset = '1' then
            FSM <= "0000";
            stop_count_aux <= '1';
            stop_scl_aux <= '1';
            sipo        <= '0';
            piso        <= '0';
            s_ack       <= '0';
            stop_sda    <= '1';
            zero_sda    <= '0';
            byte_w      <= 0;
            byte_r      <= 0;
            cont <= (others => '0');
            DONE <= '1';
            condition <= '0';
        elsif clk'event and clk = '1' then
                if FSM = "0000" then
                    stop_count_aux <= '1';
                    stop_scl_aux <= '1';
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '1';
                    zero_sda    <= '0';
                    byte_w      <= 0;
                    byte_r      <= 0; 
                    cont <= (others => '0');
                    DONE <= '0';   
                    condition <= '0';                
                    if START = '1' then
                        FSM <= "0001";
                    end if;
                elsif FSM = "0001" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1';  
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '1';
                    cont <= (others => '0');
                    DONE <= '0';
                    condition <= '1';
                    if (overflow = '1' and div = "01") then
                        FSM <= "0010";
                    end if;
                elsif FSM = "0010" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    sipo        <= '0';
                    piso        <= '1';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '0';
                    DONE <= '0';
                    condition <= '0';
                    if final_scl = '1' then
                        if cont = "111" then
                            FSM <= "0011";
                        else
                            cont <= cont + 1;
                        end if;
                    end if;  
                elsif FSM = "0011" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    sipo        <= '1';
                    piso        <= '0';
                    s_ack       <= '1';
                    stop_sda    <= '0';
                    zero_sda    <= '0'; 
                    cont <= (others => '0');
                    DONE <= '0';        
                    condition <= '0';           
                    if final_scl = '1' then
                        if SDA = '1' then
                            FSM <= "0111";
                        elsif R_W = '1' then
                            FSM <= "0101";
                        elsif R_W = '0' then
                            FSM <= "0100";
                        end if;
                   end if;     
                 elsif FSM = "0100" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    sipo        <= '0';
                    piso        <= '1';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '0'; 
                    DONE <= '0';       
                    condition <= '0';            
                    if final_scl = '1' then
                        if cont = "111" then
                            byte_w      <= byte_w + 1;
                            FSM <= "0110"; 
                        else
                            cont <= cont + 1;    
                        end if;  
                    end if; 
                elsif FSM = "0101" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0';
                    sipo        <= '1';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '0';  
                    DONE <= '0';     
                    condition <= '0';           
                    if final_scl = '1' then
                        if cont = "111" then
                            byte_r      <= byte_r + 1;
                            FSM <= "0110";
                        else
                            cont <= cont + 1;  
                        end if; 
                    end if;                    
                elsif FSM = "0110" then
                    stop_count_aux <= '0';                    
                    stop_sda    <= '0';
                    zero_sda    <= '0';
                    cont <= (others => '0');
                    condition <= '0';
                    if R_W = '0' then 
                        sipo        <= '1';
                        piso        <= '0';
                        if byte_w = to_integer(unsigned(BYTES_W)) then
                            DONE <= '1';
                        else
                            DONE <= '0';
                        end if;
                    else
                        sipo        <= '0';
                        piso        <= '1';
                        if byte_r = to_integer(unsigned(BYTES_R)) then
                            DONE <= '1';
                        else
                            DONE <= '0';
                        end if;                                             
                    end if;
                    s_ack       <= '1';
                    if final_scl = '1' then
                        if SDA = '1' then
                            FSM <= "0111";
                            stop_scl_aux <= '1';
                        elsif R_W = '0' and byte_w < to_integer(unsigned(BYTES_W)) then
                            FSM <= "0100";
                        elsif R_W = '1' and byte_r < to_integer(unsigned(BYTES_R)) then
                            FSM <= "0111";
                        else
                            byte_w <= 0;
                            byte_r <= 0;
                            FSM <= "0111";
                            stop_scl_aux <= '1';
                        end if;
                    else
                        stop_scl_aux <= '0';
                    end if; 
                elsif FSM = "0111" then    
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '1';
                    cont <= (others => '0');
                    DONE <= '1';
                    condition <= '1';
                    if (overflow = '1' and div = "01") then
                        FSM <= "1000";
                    end if;                   
                elsif FSM = "1000" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1'; 
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '1';
                    cont <= (others => '0');
                    DONE <= '1';
                    condition <= '1';
                    if (overflow = '1' and div = "01") then
                        FSM <= "1001";
                    end if;                                                                                             
                elsif FSM = "1001" then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1'; 
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '1';
                    zero_sda    <= '0';
                    cont <= (others => '0');
                    DONE <= '1';
                    condition <= '0';
                    if final_scl = '1' then
                        FSM <= "0000";
                    end if;                                                                                            
                end if;                            
            end if;
    end process;

    
    ack_s <= s_ack;
    final_count <= '1' when (final_scl = '1' and  stop_scl_aux = '1') and cont = "111" else '0';
    final_scl <= '1' when (overflow = '1' and div = "11") else '0';
    stop_scl <= stop_scl_aux;
    stop_count <= stop_count_aux;
    reading <= '1' when (FSM = "0011" or (FSM = "0110" and R_W = '0')) or (R_W = '1' and FSM = "0101") else '0';
    save <= '1' when (overflow = '1' and div = "00") else '0';
--DONE <= '1' when (FSM = "0000") else '0';
    
end Behavioral;

