library IEEE;
use IEEE.STD_LOGIC_1164.all;

use IEEE.NUMERIC_STD.all;

library work;
use work.tb_types.all;

entity tb_WasmFpgaLoader is
    generic (
        stimulus_path : string := "../../../../../simstm/";
        stimulus_file : string := "WasmFpgaLoader.stm"
    );
end;

architecture behavioural of tb_WasmFpgaLoader is

    constant CLK100M_PERIOD : time := 10 ns;

    signal Clk100M : std_logic := '0';
    signal Rst : std_logic := '1';
    signal nRst : std_logic := '0';

    signal WasmFpgaLoader_FileIO : T_WasmFpgaLoader_FileIO;
    signal FileIO_WasmFpgaLoader : T_FileIO_WasmFpgaLoader;

    signal Store_Adr : std_logic_vector(23 downto 0);
    signal Store_Sel : std_logic_vector(3 downto 0);
    signal Store_We : std_logic;
    signal Store_Stb : std_logic;
    signal Store_DatOut : std_logic_vector(31 downto 0);
    signal Store_DatIn: std_logic_vector(31 downto 0);
    signal Store_Ack : std_logic;
    signal Store_Cyc : std_logic_vector(0 downto 0);

    signal ModuleMemory_Adr : std_logic_vector(23 downto 0);
    signal ModuleMemory_Sel : std_logic_vector(3 downto 0);
    signal ModuleMemory_We : std_logic;
    signal ModuleMemory_Stb : std_logic;
    signal ModuleMemory_DatOut : std_logic_vector(31 downto 0);
    signal ModuleMemory_DatIn: std_logic_vector(31 downto 0);
    signal ModuleMemory_Ack : std_logic;
    signal ModuleMemory_Cyc : std_logic_vector(0 downto 0);

    signal StoreMemory_Adr : std_logic_vector(23 downto 0);
    signal StoreMemory_Sel : std_logic_vector(3 downto 0);
    signal StoreMemory_We : std_logic;
    signal StoreMemory_Stb : std_logic;
    signal StoreMemory_DatOut : std_logic_vector(31 downto 0);
    signal StoreMemory_DatIn: std_logic_vector(31 downto 0);
    signal StoreMemory_Ack : std_logic;
    signal StoreMemory_Cyc : std_logic_vector(0 downto 0);

    component WbRam is
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
    end component;

    component tb_FileIO is
        generic (
            stimulus_path: in string;
            stimulus_file: in string
        );
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            WasmFpgaLoader_FileIO : in T_WasmFpgaLoader_FileIO;
            FileIO_WasmFpgaLoader : out T_FileIO_WasmFpgaLoader
        );
    end component;

    component WasmFpgaLoader
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
        Ack : out std_logic;
        Memory_Adr : out std_logic_vector(23 downto 0);
        Memory_Sel : out std_logic_vector(3 downto 0);
        Memory_We : out std_logic;
        Memory_Stb : out std_logic;
        Memory_DatOut : out std_logic_vector(31 downto 0);
        Memory_DatIn: in std_logic_vector(31 downto 0);
        Memory_Ack : in std_logic;
        Memory_Cyc : out std_logic_vector(0 downto 0);
        Store_Adr : out std_logic_vector(23 downto 0);
        Store_Sel : out std_logic_vector(3 downto 0);
        Store_We : out std_logic;
        Store_Stb : out std_logic;
        Store_DatOut : out std_logic_vector(31 downto 0);
        Store_DatIn: in std_logic_vector(31 downto 0);
        Store_Ack : in std_logic;
        Store_Cyc : out std_logic_vector(0 downto 0);
        Loaded : out std_logic
      );
    end component;

    component WasmFpgaStore is
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
        Ack : out std_logic;
        Memory_Adr : out std_logic_vector(23 downto 0);
        Memory_Sel : out std_logic_vector(3 downto 0);
        Memory_We : out std_logic;
        Memory_Stb : out std_logic;
        Memory_DatOut : out std_logic_vector(31 downto 0);
        Memory_DatIn: in std_logic_vector(31 downto 0);
        Memory_Ack : in std_logic;
        Memory_Cyc : out std_logic_vector(0 downto 0)
    );
    end component;

begin

    nRst <= not Rst;

    Clk100MGen : process is
    begin
        Clk100M <= not Clk100M;
        wait for CLK100M_PERIOD / 2;
    end process;

    RstGen : process is
    begin
        Rst <= '1';
        wait for 100ns;
        Rst <= '0';
        wait;
    end process;

    tb_FileIO_i : tb_FileIO
        generic map (
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file
        )
        port map (
            Clk => Clk100M,
            Rst => Rst,
            WasmFpgaLoader_FileIO => WasmFpgaLoader_FileIO,
            FileIO_WasmFpgaLoader => FileIO_WasmFpgaLoader
        );

    ModuleMemory_i : WbRam
        port map (
            Clk => Clk100M,
            nRst => nRst,
            Adr => ModuleMemory_Adr,
            Sel => ModuleMemory_Sel,
            DatIn => ModuleMemory_DatIn,
            We => ModuleMemory_We,
            Stb => ModuleMemory_Stb,
            Cyc => ModuleMemory_Cyc,
            DatOut => ModuleMemory_DatOut,
            Ack => ModuleMemory_Ack
        );

    StoreMemory_i : WbRam
        port map (
            Clk => Clk100M,
            nRst => nRst,
            Adr => StoreMemory_Adr,
            Sel => StoreMemory_Sel,
            DatIn => StoreMemory_DatIn,
            We => StoreMemory_We,
            Stb => StoreMemory_Stb,
            Cyc => StoreMemory_Cyc,
            DatOut => StoreMemory_DatOut,
            Ack => StoreMemory_Ack
        );

    WasmFpgaLoader_i : WasmFpgaLoader
        port map (
            Clk => Clk100M,
            nRst => nRst,
            Adr => FileIO_WasmFpgaLoader.Adr,
            Sel => FileIO_WasmFpgaLoader.Sel,
            DatIn => FileIO_WasmFpgaLoader.DatIn,
            We => FileIO_WasmFpgaLoader.We,
            Stb => FileIO_WasmFpgaLoader.Stb,
            Cyc => FileIO_WasmFpgaLoader.Cyc,
            DatOut => WasmFpgaLoader_FileIO.DatOut,
            Ack => WasmFpgaLoader_FileIO.Ack,
            Memory_Adr => ModuleMemory_Adr,
            Memory_Sel => ModuleMemory_Sel,
            Memory_We => ModuleMemory_We,
            Memory_Stb => ModuleMemory_Stb,
            Memory_DatOut => ModuleMemory_DatIn,
            Memory_DatIn => ModuleMemory_DatOut,
            Memory_Ack => ModuleMemory_Ack,
            Memory_Cyc => ModuleMemory_Cyc,
            Store_Adr => Store_Adr,
            Store_Sel => Store_Sel,
            Store_We => Store_We,
            Store_Stb => Store_Stb,
            Store_DatOut => Store_DatIn,
            Store_DatIn => Store_DatOut,
            Store_Ack => Store_Ack,
            Store_Cyc => Store_Cyc,
            Loaded => WasmFpgaLoader_FileIO.Loaded
       );

    WasmFpgaStore_i : WasmFpgaStore
      port map (
        Clk => Clk100M,
        nRst => nRst,
        Adr => Store_Adr,
        Sel => Store_Sel,
        DatIn => Store_DatIn,
        We => Store_We,
        Stb => Store_Stb,
        Cyc => Store_Cyc,
        DatOut => Store_DatOut,
        Ack => Store_Ack,
        Memory_Adr => StoreMemory_Adr,
        Memory_Sel => StoreMemory_Sel,
        Memory_We => StoreMemory_We,
        Memory_Stb => StoreMemory_Stb,
        Memory_DatOut => StoreMemory_DatIn,
        Memory_DatIn => StoreMemory_DatOut,
        Memory_Ack => StoreMemory_Ack,
        Memory_Cyc => StoreMemory_Cyc
      );

end;
