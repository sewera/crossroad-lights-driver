-- (C) 2019 Blazej Sewera
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY swiatla IS
  generic(n: integer := 2);
  port(reset, clk, czujnik: in std_logic;
       auta, piesi: out std_logic_vector(2 downto 0));
END ENTITY swiatla;

ARCHITECTURE func OF swiatla IS
   type stany is (idle, wait1, yellow1, go, yellow2, drive);
   signal state, next_state: stany;
   signal licznik, licznik_max: integer range 0 to 12*n; 
   signal load: std_logic;  -- ustawia licznik w okreslony stan
BEGIN

  fsm_synchr: process(clk, reset, next_state)
  begin
    if (rising_edge(clk)) then  -- synchronicznie
      if (reset = '0') then  -- jesli reset=0, przeprowadzamy normalne operacje
        state <= next_state;
      else  -- trzeba pamietac, ze do kazdego ifa niezegarowego musi byc else, inaczej robi sie latch
      -- tutaj reset=1, wiec zerujemy synchronicznie (to jest nadal w 'if (rising_edge(clk))')
        state <= idle;
      end if;
    end if;

  end process;
  
  fsm_komb: process(state, licznik, czujnik)
  begin
    
    -- nie mozna tutaj ustawiac licznika, bo go tutaj odczytujemy
    -- jesli w jednym procesie odczytujemy i zapisujemy, robi sie (chyba) zwarcie

    -- wartosci domyslne
    -- zmieniamy je tylko jak potrzeba,
    -- ale trzeba zadeklarowac je przed casem,
    -- bo inaczej robia sie zatrzaski (latch)
    load <= '0';
    licznik_max <= 12*n;  -- tutaj mozna ustawic dowolna wartosc,
                          -- bo z load=0 nic sie nie zaladuje do licznika
                          -- jednak najlepiej ustawic duzo, zeby nie dopuscic
                          -- do licznik=-1
    
    case state is              -- najpierw wykrywam stan, bo priorytetem jest ustawienie koloru swiatla
    when idle =>
      auta <= "100";  -- 100 zielone
      piesi <= "001";  -- 001 czerwone
      if (czujnik = '1') then  -- potem wykrywam cala reszte, tutaj czujnik wykrywamy tylko w stanie idle
        next_state <= wait1;
        load <= '1';           -- ustawiamy load=1 zeby licznik zaladowal licznik_max
        licznik_max <= 2*n;    -- ustawiamy licznik_max na wartosc *nastepnego* stanu
      else                     -- jesli czujnik nie wykryje czlowieka:
        next_state <= idle;    -- powracam do stanu idle
        load <= '1';           -- wczytuje do licznika wartosc, zeby zapobiec licznik=-1
        licznik_max <= 12*n;   -- ustawiam duza wartosc zeby zapobiec licznik=-1
      end if;
    when wait1 =>
      auta <= "100";
      piesi <= "001";
      if (licznik = 0) then
        next_state <= yellow1;
        load <= '1';
        licznik_max <= n;
      else
        next_state <= wait1;
      end if;
    when yellow1 =>
      auta <= "010";  -- 010 zolte
      piesi <= "010";
      if (licznik = 0) then
        next_state <= go;
        load <= '1';
        licznik_max <= 4*n;
      else
        next_state <= yellow1;
      end if;
    when go =>
      auta <= "001";
      piesi <= "100";
      if (licznik = 0) then
        next_state <= yellow2;
        load <= '1';
        licznik_max <= n;
      else
        next_state <= go;
      end if;
    when yellow2 =>
      auta <= "010";
      piesi <= "010";
      if (licznik = 0) then
        next_state <= drive;
        load <= '1';
        licznik_max <= 12*n;
      else
        next_state <= yellow2;
      end if;
    when drive =>
      auta <= "100";
      piesi <= "001";
      if (licznik = 0) then
        next_state <= idle;
        load <= '1';
        licznik_max <= 12*n;
      else
        next_state <= drive;
      end if;
    end case;
  end process;
  
  liczenie: process(clk, reset, load, licznik_max)
  begin
    if (rising_edge(clk)) then  -- synchronicznie
      if (reset = '0') then        -- jesli nie resetuje: normalne operacje
        if (load = '1') then       -- jesli jest ustawiona flaga wczytywania:
          licznik <= licznik_max;  -- wczytuje do licznika
        else                       -- jesli nie wczytuje licznik=licznik_max:
          licznik <= licznik - 1;  -- dekrementacja licznika
        end if;
      else                         -- jesli resetuje:
        licznik <= 12*n;           -- ustawiam licznik na duza wartosc
      end if;
    end if;
  end process;  
  
END ARCHITECTURE func;
