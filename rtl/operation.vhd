library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity operation is
  Port ( 
        clk         : in std_logic;
        reset       : in std_logic; 
        ON_OFF      : in std_logic;  
        stop_count  : in std_logic;
        stop_scl    : in std_logic;   
        WRITE   : in std_logic; -- I2C write command
        READ    : in std_logic; -- I2C read command
        OPERATION   : in std_logic;  -- '0' = I2C, '1' = PMBUS 
        ack_s   : in std_logic;
        DONE    : in std_logic;
        div     : in std_logic_vector(1 downto 0);
        overflow: in std_logic;
        DATA_INPUT  : in std_logic_vector(7 downto 0); -- Aquí hay que ajustar la longitud del vector (MÚLTIPLE DE 8 - 1 down to 0)
        DATA_OUTPUT : out std_logic_vector(7 downto 0); -- Aquí hay que ajustar la longitud del vector (MÚLTIPLE DE 8 - 1 down to 0)
        DATA_IN     : out std_logic_vector(7 downto 0);
        DATA_READ   : in std_logic_vector(7 downto 0);
        BYTES_W     : out std_logic_vector(3 downto 0);
        BYTES_R     : out std_logic_vector(3 downto 0);
        R_W         : out std_logic;
        START       : out std_logic       
  );
end operation;

architecture Behavioral of operation is

    constant length_in  :   integer := DATA_INPUT'LENGTH/8;    
    constant length_out :   integer := DATA_OUTPUT'LENGTH/8;
    signal  cont, count        :   integer range 15 downto 0;
    signal  cont_restart       :   std_logic;
    signal  save, restart, R_W_aux :          std_logic;

begin

-- INTERRUPTOR PARA ENCENDER O APAGAR
    process(clk, reset)
    begin
        if reset = '1' then
            START <= '0';
        elsif clk'event and clk = '1' then
            if stop_count = '1' and stop_scl = '1' then
                if ON_OFF = '1' then
                    START <= '1';
                elsif restart = '1' then
                    START <= '1';
                else
                    START <= '0';
                end if;
            else
                START <= '0';
            end if;
        end if;
    end process;

-- Proceso para definir operación
    process(clk,reset)
    begin
        if reset = '1' then
            DATA_IN <= (others => '0');
            cont <= 0;
            count <= 0;
            restart <= '0';
            cont_restart <= '0';
            DATA_OUTPUT <= (others => '0');
        elsif clk'event and clk = '1' then
            if OPERATION = '0' then
                if save = '1' then
                    if DONE = '1' then
                        if WRITE = '1' and READ = '1' and cont_restart = '0' then
                            restart <= '1';
                            cont_restart <= '1';
                        end if;
                    else
                        restart <= '0';
                    end if;               
                    if ack_s = '1' then
                        if R_W_aux = '0' then
                            if length_in > 1 then
                                DATA_IN <= DATA_INPUT(DATA_INPUT'LENGTH - 8*cont - 1 downto DATA_INPUT'LENGTH - 8*cont - 9);
                                cont <= cont + 1;
                            else
                                DATA_IN <= DATA_INPUT(7 downto 0);
                            end if;
                        else
                            if length_out > 1 then
                                DATA_OUTPUT(DATA_OUTPUT'LENGTH - 8*cont - 1 downto DATA_OUTPUT'LENGTH - 8*cont - 9) <= DATA_READ;
                            else
                                 DATA_OUTPUT <= DATA_READ;   
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

-- Proceso para definir modo ESCRITURA / LECTURA    
    process(clk,reset)
    begin
        if reset = '1' then
            if WRITE = '1' then      
                R_W_aux <= '0';
            else
                R_W_aux <= '1';
            end if;
        elsif clk'event and clk = '1' then
            
            if ack_s = '1' and DONE = '1' and overflow = '1' and div = "11" then
                if READ = '1' then
                    R_W_aux <= '1';
                end if;
            end if;
        end if;
    end process;

    save <= '1' when (overflow = '1' and div = "00") else '0';
    BYTES_W <= std_logic_vector(to_unsigned(length_in,4));
    BYTES_R <= std_logic_vector(to_unsigned(length_out,4));
    R_W <= R_W_aux;

end Behavioral;
