
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.numeric_std.all;

entity test is
    port( clk_slow      : in std_logic;                             -- 1 Hz Clock
          inp           : in std_logic_vector(4 downto 0);
          clk           : in  std_logic;                            -- 50 Mhz Clock
          rst           : in  std_logic;
          lcd_rw        : out std_logic;                            --read & write control
          lcd_en        : out std_logic;                            --enable control
          lcd_rs        : out std_logic;                            --data or command control
          lcd1          : out std_logic_vector(7 downto 0);         --see pin planning in krypton manual 
          b11           : out std_logic;
          b12           : out std_logic;
          detect        : out std_logic                             --To be mapped to LED 4
          );
end entity; 

architecture behave of test is

--  LCD Interfacing signals
    signal erase        : std_logic := '0';                  
    signal put_char     : std_logic := '1';
    signal write_data   : std_logic_vector(7 downto 0)  := "00000000";
    signal write_row    : std_logic_vector( 0 downto 0) := "0";
    signal write_column : std_logic_vector(3 downto 0) := "0000";
    signal ack          : std_logic;
    signal i            : integer := 0;
    
-- covid_det signals
    signal ascii_value  : std_logic_vector(39 downto 0);

-- Clock signal for LCD module  
    signal lcd_clk      : std_logic := '0';

-- Component Declaration
    component cov_detect is
    port(   inp:in std_logic_vector(4 downto 0);
            reset,clock:in std_logic;
            outp: out std_logic;
            out_ascii: out std_logic_vector(39 downto 0));
    end component;

    component lcd_controller is
    port (  clk    : in std_logic;                          --clock i/p
            rst    : in std_logic;                          -- reset
            erase : in std_logic;                           --- clear position
            put_char : in std_logic;
            write_data : in std_logic_vector(7 downto 0) ;
            write_row : in std_logic_vector(0 downto 0);
            write_column : in std_logic_vector(3 downto 0);
            ack : out std_logic;
            lcd_rw : out std_logic;                         --read & write control
            lcd_en : out std_logic;                         --enable control
            lcd_rs : out std_logic;                         --data or command control
            lcd1  : out std_logic_vector(7 downto 0);
            b11 : out std_logic;
            b12 : out std_logic);     --data line
    end component lcd_controller;

begin
        
    -------------------------------------------------------------------------------------
    --- CLOCK divider circuit
    process(clk)--50Mhz/200000 = 250Hz
        variable div_clk: integer := 0;
    begin
        if rising_edge(clk) then
            div_clk := div_clk + 1;
            if div_clk = 100000 then
                lcd_clk <= '1';
            elsif div_clk = 200000 then
                lcd_clk <= '0';
                div_clk := 0;
            end if;
        end if; 
    end process;

    covid_det_instance : cov_detect port map(
                    inp         => inp,
                    reset       => rst,
                    clock       => clk_slow,
                    outp        => detect,
                    out_ascii   => ascii_value);

    
    lcd_instance : lcd_controller port map (
                    clk             => lcd_clk, 
                    rst             => rst, 
                    erase           => erase ,
                    put_char        => put_char ,
                    write_data      => write_data,
                    write_row       => write_row,
                    write_column    => write_column ,
                    ack             => ack, 
                    lcd_rw          => lcd_rw,
                    lcd_en          => lcd_en,
                    lcd_rs          => lcd_rs,
                    lcd1            => lcd1,
                    b11             => b11,
                    b12             => b12);

    
    process(ack,rst,lcd_clk)
    begin

        if (rising_edge(lcd_clk)) then
        
            -- If reset, then put 1st char in 1st row, 1st column.  
            if (rst = '1') then
                erase <= '0';
                write_row <= "0";
                write_column <= "0000";
                write_data <= "00111110"; -- Denotes > character
                put_char <= '1';
            end if;

            --Put next character only after you have recieve acknowledgment
            --Sequence Position
            --  Column Number       Character
            --      6                   c
            --      7                   o
            --      8                   v
            --      9                   i
            --      10                  d
            if(ack = '1') then 

                if ( i = 0 ) then
                    i <=  i + 1;
                    put_char <= '1';
                    write_column <= "0110";
                    write_row <= "0";
                    write_data <= ascii_value(39 downto 32);
                elsif (i = 1) then
                    i <=  i + 1;
                    put_char <= '1';
                    write_column <= "0111";
                    write_row <= "0";
                    write_data <= ascii_value(31 downto 24);
                elsif (i = 2) then
                    i <=  i + 1;
                    put_char <= '1';
                    write_column <= "1000";
                    write_row <= "0";
                    write_data <= ascii_value(23 downto 16);
                elsif (i = 3) then
                    i <=  i + 1;
                    put_char <= '1';
                    write_column <= "1001";
                    write_row <= "0";
                    write_data <= ascii_value(15 downto 8);
                elsif (i = 4) then
                    i <=  0;
                    put_char <= '1';
                    write_column <= "1010";
                    write_row <= "0";
                    write_data <= ascii_value(7 downto 0);
                end if;
            end if;
        end if;
    end process;

end behave;
