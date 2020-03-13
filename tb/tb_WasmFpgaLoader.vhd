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

    signal ModuleArea_Adr : std_logic_vector(23 downto 0);
    signal ModuleArea_Sel : std_logic_vector(3 downto 0);
    signal ModuleArea_We : std_logic;
    signal ModuleArea_Stb : std_logic;
    signal ModuleArea_DatOut : std_logic_vector(31 downto 0);
    signal ModuleArea_DatIn: std_logic_vector(31 downto 0);
    signal ModuleArea_Ack : std_logic;
    signal ModuleArea_Cyc : std_logic_vector(0 downto 0);

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

    WbRam_i : WbRam
        port map ( 
            Clk => Clk100M,
            nRst => nRst,
            Adr => ModuleArea_Adr,
            Sel => ModuleArea_Sel,
            DatIn => ModuleArea_DatIn,
            We => ModuleArea_We,
            Stb => ModuleArea_Stb,
            Cyc => ModuleArea_Cyc,
            DatOut => ModuleArea_DatOut,
            Ack => ModuleArea_Ack
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
            Memory_Adr => ModuleArea_Adr,
            Memory_Sel => ModuleArea_Sel,
            Memory_We => ModuleArea_We,
            Memory_Stb => ModuleArea_Stb,
            Memory_DatOut => ModuleArea_DatIn,
            Memory_DatIn => ModuleArea_DatOut,
            Memory_Ack => ModuleArea_Ack,
            Memory_Cyc => ModuleArea_Cyc
       );

end;
