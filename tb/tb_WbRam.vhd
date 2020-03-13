library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity WbRam is
    port ( 
        Clk : in std_logic;
        nRst : in std_logic;
        Adr : in std_logic_vector(23 downto 0);
        Sel : in std_logic_vector(3 downto 0);
        DatIn : in std_logic_vector(31 downto 0); 
        We : in std_logic;
        Stb : in std_logic; 
        Cyc : in std_logic_vector(0 downto 0);
        DatOut : out std_logic_vector(31 downto 0);
        Ack : out std_logic
    );
end entity WbRam;

architecture WbRamArchitecture of WbRam is

  component WasmFpgaTestBenchRam is
    port ( 
      clka : in std_logic;
      ena : in std_logic;
      wea : in std_logic_vector( 0 to 0 );
      addra : in std_logic_vector( 9 downto 0 );
      dina : in std_logic_vector( 31 downto 0 );
      douta : out std_logic_vector(31 downto 0);
      clkb : in std_logic;
      enb : in std_logic;
      web : in std_logic_vector(0 to 0);
      addrb : in std_logic_vector(9 downto 0);
      dinb : in std_logic_vector(31 downto 0);
      doutb : out std_logic_vector(31 downto 0)
    );
  end component;

  signal Rst : std_logic;
  signal ReadEnable : std_logic;
  signal ReadData : std_logic_vector(31 downto 0);
  signal ReadAddress : std_logic_vector(9 downto 0);
  signal ReadState : unsigned(1 downto 0);

  constant ReadStateIdle0 : natural := 0;
  constant ReadStateRead0 : natural := 1;
  constant ReadStateRead1 : natural := 2;

 begin

  Rst <= not nRst;

  process (Clk, Rst) is
  begin
    if (Rst = '1') then
      Ack <= '0';
      DatOut <= (others => '0');
      ReadEnable <= '0';
      ReadAddress <= (others => '0');
      ReadState <= (others => '0');
    elsif rising_edge(Clk) then
      if(ReadState = ReadStateIdle0) then
        Ack <= '0';
        ReadEnable <= '0';
        if (Cyc = "1" and We = '0') then
            ReadEnable <= '1';
            ReadAddress <= Adr(9 downto 0);
            ReadState <= to_unsigned(ReadStateRead0, ReadState'LENGTH);
        end if;
      elsif(ReadState = ReadStateRead0) then
        ReadState <= to_unsigned(ReadStateRead1, ReadState'LENGTH);
      elsif(ReadState = ReadStateRead1) then
        DatOut <= ReadData;
        Ack <= '1';
        ReadState <= to_unsigned(ReadStateIdle0, ReadState'LENGTH);
      end if;
    end if;
  end process;

  WasmFpgaTestBenchRam_i : WasmFpgaTestBenchRam
    port map ( 
      clka => Clk,
      ena => ReadEnable,
      wea => "0",
      addra => ReadAddress,
      dina => (others => '0'),
      douta => ReadData,
      clkb => Clk,
      enb => '0',
      web => "0",
      addrb => (others => '0'),
      dinb => (others => '0'),
      doutb => open
    );

end;
