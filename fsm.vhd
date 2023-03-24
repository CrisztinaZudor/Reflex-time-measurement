library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fsm is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0);
           an : out std_logic_vector (3 downto 0);
           seg : out std_logic_vector (0 to 6);
           btn : in std_logic_vector (1 downto 0);
           dp : out std_logic
           );
end fsm;

architecture Behavioral of fsm is
   
type states is (idle, get_rnd, led_on, save_ta, led_off, save_tb, afisaj_on, afisaj_off, verif_sw0);
 
signal current_state, next_state : states;
signal count : integer range 0 to 6;
signal i : integer range 1 to 5;    
signal rnd : STD_LOGIC_VECTOR (3 downto 0);
signal tc : STD_LOGIC_VECTOR (15 downto 0);
signal en_cnt : std_logic;
signal inc1sec : std_logic;
signal dp_iin : STD_LOGIC_VECTOR (3 downto 0):="1111";

component driver7seg is
    Port ( clk : in STD_LOGIC; --100MHz board clock input
           Din : in STD_LOGIC_VECTOR (15 downto 0); --16 bit binary data for 4 displays
           an : out STD_LOGIC_VECTOR (3 downto 0); --anode outputs selecting individual displays 3 to 0
           seg : out STD_LOGIC_VECTOR (0 to 6); -- cathode outputs for selecting LED-s in each display
           dp_in : in STD_LOGIC_VECTOR (3 downto 0); --decimal point input values
           dp_out : out STD_LOGIC; --selected decimal point sent to cathodes
           rst : in STD_LOGIC); --global reset
end component driver7seg;
component DeBounce is
    port(   Clock : in std_logic;
            Reset : in std_logic;
            button_in : in std_logic;
            pulse_out : out std_logic
        );
end component DeBounce;
component ceas is
    Port ( CLK100MHZ : in STD_LOGIC;
           btnL : in STD_LOGIC;
           btnR : in STD_LOGIC;
           btnC : in STD_LOGIC;
           seg : out STD_LOGIC_VECTOR (0 to 6);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           dp : out STD_LOGIC);
end component ceas;

    type ms is record
        dig1 : integer range 0 to 9;
        dig2 : integer range 0 to 9;
    end record;
    type ds is record
        dig1 : integer range 0 to 9;
        dig2 : integer range 0 to 9;
    end record;
    type timp is record 
        ms:ms;
        ds:ds;         
    end record;
    signal t, ta, tb,tmax,tcc : timp := ((0,0),(0,0)) ;  
    signal tmin:timp:=((9,9),(9,9));
    signal inc_ms : std_logic :=  '0';
    signal btnLd, btnRd : std_logic;

begin
deb1 : debounce port map (clock => clk, Reset => '0', button_in => btn(0), pulse_out => btnLd);
deb2 : debounce port map (clock => clk, Reset => '0', button_in => btn(1), pulse_out => btnRd);
u : driver7seg port map (clk => clk,
                         Din => tc,
                         an => an,
                         seg => seg,
                         dp_in => dp_iin,--afisseg
                         dp_out => dp,
                         rst => rst);

--ceas
msck : process (clk)
variable j : integer :=0;
begin
    if rising_edge(clk) then
       if j = 100000 then
           j:=0;
           inc_ms <= '1';
       else 
           j := j+ 1;
           inc_ms <= '0';
       end if;
    end if;
end process;

secck : process(clk, rst)
variable j : integer := 0;
begin
  if rst = '1' then
    j := 0;
    inc1sec <= '0';
  elsif rising_edge(clk) then
    if en_cnt = '1' then  
      if j = 10**8 - 1 then
        j := 1;
        inc1sec <= '1';
      else
        j := j + 1;
        inc1sec <= '0';
      end if;
    end if;        
  end if;  
end process;

ceasms : process (clk)
begin
    if rising_edge(clk) then
        if inc_ms = '1' then
            if t.ms.dig1 = 9 then
               t.ms.dig1 <= 0;
               if t.ms.dig2 = 9 then
                  t.ms.dig2 <= 0;
                  if t.ds.dig1 = 9 then
                     t.ds.dig1 <= 0;
                     if t.ds.dig2 = 9 then
                        t.ds.dig2 <= 0;
                        else 
                            t.ds.dig2 <= t.ds.dig2 + 1;
                        end if;
                     else
                        t.ds.dig1 <= t.ds.dig1 + 1;
                     end if;
                  else
                     t.ms.dig2 <= t.ms.dig2 + 1;   
                  end if;
                 else
                     t.ms.dig1 <= t.ms.dig1 + 1;   
            end if;
            end if;
            end if;
end process;

rstprocc : process (clk, rst)
begin
  if rst = '1' then
    current_state <= idle;
  elsif rising_edge(clk) then
    current_state <= next_state;
  end if;    
end process;
        
csns : process (current_state, sw, i,btnLd,count)
begin
  case current_state is
    when idle => next_state <= get_rnd;
    when get_rnd => next_state <= led_on;
    when led_on => next_state <=save_ta;
    when save_ta => if btnLd = '1' then
                     next_state <= led_off;
                  else
                     next_state <= save_ta;
                  end if;
    when led_off => next_state <=save_tb;
    when save_tb => next_state <= afisaj_on;
    when afisaj_on => next_state <= afisaj_off;
    when afisaj_off => if count=5 then
                     next_state <= verif_sw0;
                  else
                     next_state <=get_rnd;
                  end if;
    when others => next_state <= idle;
  end case;                                            
end process;


--random number generator
lfsr: process (clk, rst)
variable shiftreg : std_logic_vector(15 downto 0) := x"ABCD";
variable firstbit : std_logic;
begin
  if rst = '1' then
    shiftreg := x"ABCD";
    rnd <= x"D";
  elsif rising_edge(clk) then
    firstbit := shiftreg(1) xnor  shiftreg(0);
    shiftreg := firstbit & shiftreg(15 downto 1);
    rnd <= shiftreg(3 downto 0);   
  end if;
end process;

generate_i: process (clk, rst)
variable k : integer := 0;
begin
  if rst = '1' then
     i <= 1;
  elsif rising_edge(clk) then
     if current_state = get_rnd then
        if k=0 then
        i <= to_integer(unsigned(rnd));
        k:=1;
        elsif i>1 then
        en_cnt <='1';
        if inc1sec='1'then
        i<=i-1;
        end if;
     end if;
  end if;
  end if;
end process;

-- LED display
generate_led: process (clk, rst)
begin
  if rst = '1' then
  count<=0;
    led <= (others => '0');
  elsif rising_edge(clk) then
    if current_state = led_on then
       led(0) <= '1';
    elsif current_state = led_off then
       led(0) <= '0';
       count <= count+1;
    end if;
  end if;
end process; 
    
-- citim timpul
generate_timp:process(clk, rst)
begin
    if rst = '1' then
    ta <= ((0,0),(0,0)) ;
    tb <= ((0,0),(0,0)) ;
  elsif rising_edge(clk) then
    if current_state = led_on then
      ta <= t;
    elsif current_state <= save_tb then
      tb <= t;
      
      ------- pentru tb.ms1---------
      if  tb.ms.dig1 < ta.ms.dig1 then
        if tb.ms.dig2=0 then
            if tb.ds.dig1=0 then
                tcc.ms.dig1 <= tb.ms.dig1 + 10 - ta.ms.dig1;
                tb.ds.dig1<=9;
                tb.ds.dig2<=9;
                tb.ds.dig2 <= tb.ds.dig2-1;
                else --if tb.ds.dig1>0 then
                tb.ds.dig1 <= tb.ds.dig1-1;
                tb.ms.dig2 <= 9;
                tcc.ms.dig1 <= tb.ms.dig1 +10 -ta.ms.dig1;
             end if;
                else
                tb.ms.dig2 <= tb.ms.dig2-1;
                tcc.ms.dig1 <= tb.ms.dig1 + 10 -ta.ms.dig1;
         end if;
                else
                tcc.ms.dig1 <= tb.ms.dig1 - ta.ms.dig1;
    end if;
    
     ------- pentru tb.ms2---------
    if  tb.ms.dig2 < ta.ms.dig2 then
            if tb.ds.dig1=0 then
                tcc.ms.dig2 <= tb.ms.dig2 + 10 - ta.ms.dig2;
                tb.ds.dig1<=9;
                tb.ds.dig2 <= tb.ds.dig2-1;
                else 
                tb.ds.dig1 <= tb.ds.dig1-1;
                tcc.ms.dig2 <= tb.ms.dig2 +10 -ta.ms.dig2;
             end if;
                else
                tcc.ms.dig2 <= tb.ms.dig2 + 10 -ta.ms.dig2;
    end if;
    
     ------- pentru tb.ds1---------
     if  tb.ds.dig1 < ta.ds.dig1 then
                tb.ds.dig2 <= tb.ds.dig2-1;
                tcc.ds.dig1 <= tb.ds.dig1 +10 -ta.ds.dig1;
             end if;
                else
                 tcc.ds.dig1 <= tb.ds.dig1 +10 -ta.ds.dig1;
    end if;
    
     ------- pentru tb.d2---------
    tcc.ds.dig2 <= tb.ds.dig2 +10 -ta.ds.dig2;

    
    
                
      tc <= std_logic_vector(to_unsigned(tcc.ds.dig2,4)) &
             std_logic_vector(to_unsigned(tcc.ds.dig1,4)) &
             std_logic_vector(to_unsigned(tcc.ms.dig2,4)) &
             std_logic_vector(to_unsigned(tcc.ms.dig1,4));
     
             
       --tmmin----     
     if tcc.ds.dig2 < tmin.ds.dig2 then
     tmin.ds.dig2<=tcc.ds.dig2;
     tmin.ds.dig1<=tcc.ds.dig1;
     tmin.ms.dig2<=tcc.ms.dig2;
     tmin.ms.dig1<=tcc.ms.dig1;
     elsif tcc.ds.dig2=tmin.ds.dig2 and tcc.ds.dig1 < tmin.ds.dig1 then
     tmin.ds.dig2<=tcc.ds.dig2;
     tmin.ds.dig1<=tcc.ds.dig1;
     tmin.ms.dig2<=tcc.ms.dig2;
     tmin.ms.dig1<=tcc.ms.dig1;
     elsif tcc.ds.dig1=tmin.ds.dig1 and tcc.ms.dig2 < tmin.ms.dig2 then
     tmin.ds.dig2<=tcc.ds.dig2;
     tmin.ds.dig1<=tcc.ds.dig1;
     tmin.ms.dig2<=tcc.ms.dig2;
     tmin.ms.dig1<=tcc.ms.dig1;     
     elsif tcc.ms.dig2=tmin.ms.dig2 and tcc.ms.dig1 < tmin.ms.dig1 then
     tmin.ds.dig2<=tcc.ds.dig2;
     tmin.ds.dig1<=tcc.ds.dig1;
     tmin.ms.dig2<=tcc.ms.dig2;
     tmin.ms.dig1<=tcc.ms.dig1;
     end if;    
   
      
     ---tmax-------
     if tcc.ds.dig2 > tmax.ds.dig2 then
     tmax.ds.dig2<=tcc.ds.dig2;
     tmax.ds.dig1<=tcc.ds.dig1;
     tmax.ms.dig2<=tcc.ms.dig2;
     tmax.ms.dig1<=tcc.ms.dig1;
     elsif tcc.ds.dig2=tmax.ds.dig2 and tcc.ds.dig1 > tmax.ds.dig1 then
     tmax.ds.dig2<=tcc.ds.dig2;
     tmax.ds.dig1<=tcc.ds.dig1;
     tmax.ms.dig2<=tcc.ms.dig2;
     tmax.ms.dig1<=tcc.ms.dig1;
     elsif tcc.ds.dig1=tmax.ds.dig1 and tcc.ms.dig2 > tmax.ms.dig2 then
     tmax.ds.dig2<=tcc.ds.dig2;
     tmax.ds.dig1<=tcc.ds.dig1;
     tmax.ms.dig2<=tcc.ms.dig2;
     tmax.ms.dig1<=tcc.ms.dig1;     
     elsif tcc.ms.dig2=tmax.ms.dig2 and tcc.ms.dig1 > tmax.ms.dig1 then
     tmax.ds.dig2<=tcc.ds.dig2;
     tmax.ds.dig1<=tcc.ds.dig1;
     tmax.ms.dig2<=tcc.ms.dig2;
     tmax.ms.dig1<=tcc.ms.dig1;
     elsif current_state = verif_sw0 then
       if sw(0)= '0' then
       --asistmin
        tc <= std_logic_vector(to_unsigned(tmin.ds.dig2,4)) &
             std_logic_vector(to_unsigned(tmin.ds.dig1,4)) &
             std_logic_vector(to_unsigned(tmin.ms.dig2,4)) &
             std_logic_vector(to_unsigned(tmin.ms.dig1,4));
          
            
      
       end if;
    elsif current_state = verif_sw0 then
        if sw(0)= '1' then
       --afis Tmax
        tc <= std_logic_vector(to_unsigned(tmax.ds.dig2,4)) &
             std_logic_vector(to_unsigned(tmax.ds.dig1,4)) &
             std_logic_vector(to_unsigned(tmax.ms.dig2,4)) &
             std_logic_vector(to_unsigned(tmax.ms.dig1,4));
             
    end if; 
end if;
end if;
end process;    
    
    
-- SSD display       
--generate_timp: process (clk, rst)
--  variable mii1, sute1, zeci1, unitati1,mii2, sute2, zeci2,unitati2: integer range 0 to 9 := 0;
--begin
--  if rst = '1' then
--    tc <= (others => '0');
--    mii1 := 0;
--    sute1 := 0;
--    zeci1 := 0;
--    unitati1 := 0;
--    mii2 := 0;
--    sute2 := 0;
--    zeci2 := 0;
--    unitati2 := 0;
--  elsif rising_edge(clk) then
--    if current_state = led_on then
--     ta <= ((0,0),(0,0)) ;
--    end if;
--     if current_state = save_tb then
--    --luamtimp
--       mii2 := 0;
--    sute2 := 0;
--    zeci2 := 0;
--    unitati2 := 0;
--    end if;
--        mii1 := mii2-mii1;
--    sute1 := sute2-sute1;
--    zeci1 := zeci2-zeci1;
--    unitati1 := unitati2-unitati1;
--    tc <= std_logic_vector(to_unsigned(mii1,4)) &
--             std_logic_vector(to_unsigned(sute1,4)) &
--             std_logic_vector(to_unsigned(zeci1,4)) &
--             std_logic_vector(to_unsigned(unitati1,4));
             
--             end if;
--end process;

waitafison: process (clk, rst)
variable kk : integer := 0;
variable kkk : integer := 0;
begin
  if rst = '1' then
     kk := 0;
  elsif rising_edge(clk) then
     if current_state <= afisaj_on then
        if kk=0 then
        kkk:=2;
        kk:=1;
        elsif kkk>0 then
        en_cnt <='1';
        if inc1sec='1'then
        kkk:=kkk-1;
        end if;
        
        
     end if;
  end if;
  end if;
end process;

     dp_iin  <=  "0000"  when current_state = save_tb else  "1111";-- when   others;
   --  dp_iin<="1111"when current_state = save_tb



generate_final: process (clk, rst)
begin
  if rst = '1' then
  elsif rising_edge(clk) then
    
  end if;
end process; 
end Behavioral;
