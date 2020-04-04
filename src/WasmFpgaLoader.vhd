library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.WasmFpgaStoreWshBn_Package.all;

entity WasmFpgaLoader is
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
        Store_DatIn : in std_logic_vector(31 downto 0);
        Store_Ack : in std_logic;
        Store_Cyc : out std_logic_vector(0 downto 0);
        Loaded : out std_logic
    );
end entity WasmFpgaLoader;

architecture WasmFpgaLoaderArchitecture of WasmFpgaLoader is

  component LoaderBlk_WasmFpgaLoader is
      port (
        Clk : in std_logic;
        Rst : in std_logic;
        Adr : in std_logic_vector(23 downto 0);
        Sel : in std_logic_vector(3 downto 0);
        DatIn : in std_logic_vector(31 downto 0);
        We : in std_logic;
        Stb : in std_logic;
        Cyc : in  std_logic_vector(0 downto 0);
        LoaderBlk_DatOut : out std_logic_vector(31 downto 0);
        LoaderBlk_Ack : out std_logic;
        LoaderBlk_Unoccupied_Ack : out std_logic;
        Run : out std_logic;
        Loaded : in std_logic;
        Busy : in std_logic
      );
  end component LoaderBlk_WasmFpgaLoader;

  component WasmFpgaLoader_StoreBlk is
    port (
        Clk : in std_logic;
        Rst : in std_logic;
        Adr : out std_logic_vector(23 downto 0);
        Sel : out std_logic_vector(3 downto 0);
        DatIn : out std_logic_vector(31 downto 0);
        We : out std_logic;
        Stb : out std_logic;
        Cyc : out  std_logic_vector(0 downto 0);
        StoreBlk_DatOut : in std_logic_vector(31 downto 0);
        StoreBlk_Ack : in std_logic;
        StoreBlk_Unoccupied_Ack : in std_logic;
        Operation : in std_logic;
        Run : in std_logic;
        Busy : out std_logic;
        ModuleInstanceUID : in std_logic_vector(31 downto 0);
        SectionUID : in std_logic_vector(31 downto 0);
        Idx : in std_logic_vector(31 downto 0);
        Address_ToBeRead : out std_logic_vector(31 downto 0);
        Address_Written : in std_logic_vector(31 downto 0)
    );
  end component;

  signal ReadModuleState : unsigned(7 downto 0);
  signal ReadModuleRun : std_logic;
  signal ReadModuleBusy : std_logic;
  signal ReadAddress : std_logic_vector(23 downto 0);
  signal ReadData : std_logic_vector(7 downto 0);
  signal ReadModuleData : std_logic_vector(31 downto 0);

  constant ReadModuleStateIdle0 : natural := 0;
  constant ReadModuleStateReadCyc0 : natural := 1;
  constant ReadModuleStateReadAck0 : natural := 2;

  signal Rst : std_logic;
  signal Run : std_logic;
  signal Busy : std_logic;

  signal LoaderBlk_DatOut : std_logic_vector(31 downto 0);
  signal LoaderBlk_Ack : std_logic;
  signal LoaderBlk_Unoccupied_Ack : std_logic;

  signal ModuleInstanceUID : std_logic_vector(31 downto 0);
  signal SectionUID : std_logic_vector(31 downto 0);
  signal Idx : std_logic_vector(31 downto 0);
  signal Address : std_logic_vector(31 downto 0);

  signal StoreRun : std_logic;
  signal StoreBusy : std_logic;

  signal Opcode : std_logic_vector(7 downto 0);
  signal ReadBinaryMagic : std_logic_vector(31 downto 0);
  signal ReadBinaryVersion : std_logic_vector(31 downto 0);

  signal NumTypesIteration : unsigned(31 downto 0);
  signal NumImportsIteration : unsigned(31 downto 0);
  signal NumParamsIteration : unsigned(31 downto 0);
  signal NumResultsIteration : unsigned(31 downto 0);
  signal NumFunctionsIteration : unsigned(31 downto 0);
  signal NumExportsIteration : unsigned(31 downto 0);
  signal NumTablesIteration : unsigned(31 downto 0);
  signal NumMemoriesIteration : unsigned(31 downto 0);
  signal NumGlobalsIteration : unsigned(31 downto 0);
  signal NumDataIteration : unsigned(31 downto 0);
  signal NumElementsIteration : unsigned(31 downto 0);

  signal NumTypes : std_logic_vector(31 downto 0);
  signal NumImports : std_logic_vector(31 downto 0);
  signal NumParams : std_logic_vector(31 downto 0);
  signal NumResults : std_logic_vector(31 downto 0);
  signal NumFunctions : std_logic_vector(31 downto 0);
  signal NumExports : std_logic_vector(31 downto 0);
  signal NumTables : std_logic_vector(31 downto 0);
  signal NumMemories : std_logic_vector(31 downto 0);
  signal NumGlobals : std_logic_vector(31 downto 0);
  signal NumData : std_logic_vector(31 downto 0);
  signal NumElements : std_logic_vector(31 downto 0);

  signal StartFuncIndex : std_logic_vector(31 downto 0);

  signal DecodedValue : std_logic_vector(31 downto 0);

  signal LoadedBuf : std_logic;

	signal LoaderState : unsigned(7 downto 0);
  signal LoaderStateReturn : unsigned(7 downto 0);
  signal LoaderStateReturnU32 : unsigned(7 downto 0);
  signal LoaderStateReturnLimits : unsigned(7 downto 0);
  signal LoaderStateReturnTableType : unsigned(7 downto 0);
  signal LoaderStateReturnGlobalType : unsigned(7 downto 0);

  constant LoaderStateIdle0 : natural := 0;
	constant LoaderState0 : natural := 1;
	constant LoaderState1 : natural := 2;
	constant LoaderState2 : natural := 3;
	constant LoaderState3 : natural := 4;
	constant LoaderState4 : natural := 5;
	constant LoaderState5 : natural := 6;
	constant LoaderState6 : natural := 7;
	constant LoaderState7 : natural := 8;
	constant LoaderState8 : natural := 10;
	constant LoaderState9 : natural := 11;
	constant LoaderState10 : natural := 12;
	constant LoaderState11 : natural := 13;
	constant LoaderState12 : natural := 14;
	constant LoaderState13 : natural := 15;

  constant LoaderStateSectionType0 : natural := 20;
  constant LoaderStateSectionType1 : natural := 21;
  constant LoaderStateSectionType2 : natural := 22;
  constant LoaderStateSectionType3 : natural := 23;
  constant LoaderStateSectionType4 : natural := 24;

	constant LoaderStateParseFuncType0 : natural := 30;
	constant LoaderStateParseFuncType1 : natural := 31;
	constant LoaderStateParseFuncType2 : natural := 32;
	constant LoaderStateParseFuncType3 : natural := 33;

	constant LoaderStateSectionImport0 : natural := 40;
	constant LoaderStateSectionImport1 : natural := 41;
	constant LoaderStateSectionImport2 : natural := 42;
	constant LoaderStateSectionImport3 : natural := 43;
	constant LoaderStateSectionImport4 : natural := 44;
	constant LoaderStateSectionImport5 : natural := 45;
	constant LoaderStateSectionImport6 : natural := 46;
	constant LoaderStateSectionImportFuncType0 : natural := 47;
  constant LoaderStateSectionImportMemType0 : natural := 54;

  constant LoaderStateGlobalType0 : natural := 55;
  constant LoaderStateGlobalType1 : natural := 56;
  constant LoaderStateGlobalType2 : natural := 57;
  constant LoaderStateGlobalType3 : natural := 58;

	constant LoaderStateSectionFunction0 : natural := 60;
	constant LoaderStateSectionFunction1 : natural := 61;
  constant LoaderStateSectionFunction2 : natural := 62;
  constant LoaderStateSectionFunction3 : natural := 63;
  constant LoaderStateSectionFunction4 : natural := 64;

	constant LoaderStateSectionTable0 : natural := 70;
	constant LoaderStateSectionTable1 : natural := 71;
  constant LoaderStateSectionTable2 : natural := 72;
  constant LoaderStateSectionTable3 : natural := 73;

	constant LoaderStateSectionMemory0 : natural := 80;
	constant LoaderStateSectionMemory1 : natural := 81;
	constant LoaderStateSectionMemory2 : natural := 82;
	constant LoaderStateSectionMemory3 : natural := 83;

	constant LoaderStateSectionGlobal0 : natural := 90;
	constant LoaderStateSectionGlobal1 : natural := 91;
	constant LoaderStateSectionGlobal2 : natural := 92;
	constant LoaderStateSectionGlobal3 : natural := 93;

	constant LoaderStateSectionExport0 : natural := 100;
	constant LoaderStateSectionExport1 : natural := 101;
	constant LoaderStateSectionExport2 : natural := 102;
	constant LoaderStateSectionExport3 : natural := 103;
	constant LoaderStateSectionExport4 : natural := 104;
	constant LoaderStateSectionExport5 : natural := 105;
	constant LoaderStateSectionExport6 : natural := 106;

	constant LoaderStateSectionStart0 : natural := 110;
	constant LoaderStateSectionStart1 : natural := 111;
	constant LoaderStateSectionStart2 : natural := 112;
	constant LoaderStateSectionStart3 : natural := 113;

	constant LoaderStateSectionElement0 : natural := 120;
	constant LoaderStateSectionElement1 : natural := 121;
	constant LoaderStateSectionElement2 : natural := 122;
	constant LoaderStateSectionElement3 : natural := 123;
	constant LoaderStateSectionElement4 : natural := 124;
	constant LoaderStateSectionElement5 : natural := 125;

	constant LoaderStateSectionCode0 : natural := 130;
	constant LoaderStateSectionCode1 : natural := 131;
	constant LoaderStateSectionCode2 : natural := 132;
	constant LoaderStateSectionCode3 : natural := 133;
	constant LoaderStateSectionCode4 : natural := 134;
	constant LoaderStateSectionCode5 : natural := 135;
	constant LoaderStateSectionCode6 : natural := 136;

	constant LoaderStateSectionData0 : natural := 140;
	constant LoaderStateSectionData1 : natural := 141;
	constant LoaderStateSectionData2 : natural := 142;
	constant LoaderStateSectionData3 : natural := 143;
	constant LoaderStateSectionData4 : natural := 144;
	constant LoaderStateSectionData5 : natural := 145;

	constant LoaderStateLimits0 : natural := 150;
	constant LoaderStateLimits1 : natural := 151;
	constant LoaderStateLimits2 : natural := 152;
	constant LoaderStateLimits3 : natural := 153;
  constant LoaderStateTableType0 : natural := 154;

	constant LoaderStateReadU32_0 : natural := 160;
	constant LoaderStateReadU32_1 : natural := 161;
	constant LoaderStateReadU32_2 : natural := 162;
	constant LoaderStateReadU32_3 : natural := 163;
	constant LoaderStateReadU32_4 : natural := 164;
	constant LoaderStateReadU32_5 : natural := 165;

  constant LoaderStateWriteStore0 : natural := 170;
  constant LoaderStateWriteStore1 : natural := 171;
  constant LoaderStateWriteStore2 : natural := 172;

  constant LoaderStateReadRam0 : natural := 250;
  constant LoaderStateReadRam1 : natural := 251;
  constant LoaderStateReadRam2 : natural := 252;

  constant LoaderStateLoaded : natural := 254;
  constant LoaderStateError : natural := 255;

  constant WasmBinaryMagic : std_logic_vector(31 downto 0) := x"6D736100";
  constant WasmBinaryVersion : std_logic_vector(31 downto 0) := x"00000001";

  constant SECTION_UID_TYPE : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"01";
  constant SECTION_UID_IMPORT : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"02";
  constant SECTION_UID_FUNCTION : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"03";
  constant SECTION_UID_TABLE : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"04";
  constant SECTION_UID_MEMORY : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"05";
  constant SECTION_UID_GLOBAL : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"06";
  constant SECTION_UID_EXPORT : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"07";
  constant SECTION_UID_START : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"08";
  constant SECTION_UID_ELEMENT : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"09";
  constant SECTION_UID_CODE : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"0A";
  constant SECTION_UID_DATA : std_logic_vector(31 downto 0) := (31 downto 8 => '0') & x"0B";

begin

  Rst <= not nRst;

  Ack <= LoaderBlk_Ack;
  DatOut <= LoaderBlk_DatOut;

  Memory_We <= '0';
  Memory_DatOut <= (others => '0');

  Loaded <= LoadedBuf;

  DecodeModule : process (Clk, Rst)
  begin
    if Rst = '1' then
      Opcode <= (others => '0');
      ReadModuleRun <= '0';
      ReadAddress <= (others => '0');
      ReadData <= (others => '0');
      ReadBinaryVersion <= (others => '0');
      ReadBinaryMagic <= (others => '0');
      DecodedValue <= (others => '0');
      NumTypesIteration <= (others => '0');
      NumImportsIteration <= (others => '0');
      NumParamsIteration <= (others => '0');
      NumResultsIteration <= (others => '0');
      NumFunctionsIteration <= (others => '0');
      NumExportsIteration <= (others => '0');
      NumTablesIteration <= (others => '0');
      NumMemoriesIteration <= (others => '0');
      NumGlobalsIteration <= (others => '0');
      NumDataIteration <= (others => '0');
      NumElementsIteration <= (others => '0');
      NumTypes <= (others => '0');
      NumImports <= (others => '0');
      NumParams <= (others => '0');
      NumResults <= (others => '0');
      NumFunctions <= (others => '0');
      NumExports <= (others => '0');
      NumTables <= (others => '0');
      NumMemories <= (others => '0');
      NumGlobals <= (others => '0');
      NumData <= (others => '0');
      NumElements <= (others => '0');
      ModuleInstanceUID <= (others => '0');
      SectionUID <= (others => '0');
      Idx <= (others => '0');
      Address <= (others => '0');
      StoreRun <= '0';
      LoadedBuf <= '0';
      LoaderState <= (others => '0');
      LoaderStateReturn <= (others => '0');
      LoaderStateReturnU32 <= (others => '0');
    elsif rising_edge(clk) then
      --
      -- Finished
      --
      if (LoaderState = LoaderStateIdle0) then
          Busy <= '0';
          if (Run = '1') then
              Busy <= '1';
              LoaderState <= to_unsigned(LoaderState0, LoaderState'LENGTH);
          end if;
      --
      -- WASM magic number
      --
      elsif (LoaderState = LoaderState0) then
        LoaderStateReturn <= to_unsigned(LoaderState1, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState1) then
        ReadBinaryMagic(7 downto 0) <= ReadData;
        LoaderStateReturn <= to_unsigned(LoaderState2, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState2) then
        ReadBinaryMagic(15 downto 8) <= ReadData;
        LoaderStateReturn <= to_unsigned(LoaderState3, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState3) then
        ReadBinaryMagic(23 downto 16) <= ReadData;
        LoaderStateReturn <= to_unsigned(LoaderState4, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState4) then
        ReadBinaryMagic(31 downto 24) <= ReadData;
        LoaderState <= to_unsigned(LoaderState5, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState5) then
        if (ReadBinaryMagic = WasmBinaryMagic) then
          LoaderState <= to_unsigned(LoaderState6, LoaderState'LENGTH);
        else
          LoaderState <= to_unsigned(LoaderStateError, LoaderState'LENGTH);
        end if;
        LoaderState <= to_unsigned(LoaderState6, LoaderState'LENGTH);
      --
      -- WASM binary version
      --
      elsif (LoaderState = LoaderState6) then
        LoaderStateReturn <= to_unsigned(LoaderState7, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState7) then
        ReadBinaryVersion(7 downto 0) <= ReadData;
        LoaderStateReturn <= to_unsigned(LoaderState8, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState8) then
        ReadBinaryVersion(15 downto 8) <= ReadData;
        LoaderStateReturn <= to_unsigned(LoaderState9, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState9) then
        ReadBinaryVersion(23 downto 16) <= ReadData;
        LoaderStateReturn <= to_unsigned(LoaderState10, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState10) then
        ReadBinaryVersion(31 downto 24) <= ReadData;
        LoaderState <= to_unsigned(LoaderState11, LoaderState'LENGTH);
      elsif (LoaderState = LoaderState11) then
        if (ReadBinaryVersion = WasmBinaryVersion) then
          LoaderStateReturn <= to_unsigned(LoaderStateSectionType0, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        else
          LoaderState <= to_unsigned(LoaderStateError, LoaderState'LENGTH);
        end if;
      --
      -- Section "Type" (1)
      --
      elsif (LoaderState = LoaderStateSectionType0) then
        if (ReadData = SECTION_UID_TYPE(7 downto 0)) then
          SectionUID <= SECTION_UID_TYPE;
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionType1, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
        else 
          LoaderState <= to_unsigned(LoaderStateSectionImport0, LoaderState'LENGTH);
        end if;
      elsif (LoaderState = LoaderStateSectionType1) then
          -- section size
          NumTypesIteration <= (others => '0');
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionType2, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionType2) then
          NumTypes <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionType3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionType3) then
          -- number of types
        if (NumTypesIteration /= unsigned(NumTypes)) then
            NumTypesIteration <= NumTypesIteration + 1;
            LoaderStateReturn <= to_unsigned(LoaderStateSectionType4, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        else
            NumTypesIteration <= (others => '0');
            LoaderStateReturn <= to_unsigned(LoaderStateSectionImport0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        end if;
      elsif (LoaderState = LoaderStateSectionType4) then
          -- type
          if (ReadData = x"60") then
            -- func
            NumParamsIteration <= (others => '0');
            LoaderStateReturnU32 <= to_unsigned(LoaderStateParseFuncType0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateError, LoaderState'LENGTH);
          end if;
      --
      -- Parse functype
      --
      elsif (LoaderState = LoaderStateParseFuncType0) then
          NumParams <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateParseFuncType1, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateParseFuncType1) then
        -- num params
        if (NumParamsIteration /= unsigned(NumParams)) then
          NumParamsIteration <= NumParamsIteration + 1;
          LoaderStateReturn <= to_unsigned(LoaderStateParseFuncType1, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        else
            NumResultsIteration <= (others => '0');
            LoaderStateReturnU32 <= to_unsigned(LoaderStateParseFuncType2, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
        end if;
      elsif (LoaderState = LoaderStateParseFuncType2) then
          NumResults <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateParseFuncType3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateParseFuncType3) then
        -- num results
        if (NumResultsIteration /= unsigned(NumResults)) then
          NumResultsIteration <= NumResultsIteration + 1;
          LoaderStateReturn <= to_unsigned(LoaderStateParseFuncType3, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        else
            LoaderState <= to_unsigned(LoaderStateSectionType3, LoaderState'LENGTH);
        end if;
      --
      -- Section "Import" (2)
      --
      elsif (LoaderState = LoaderStateSectionImport0) then
          if (ReadData = SECTION_UID_IMPORT(7 downto 0)) then
            SectionUID <= SECTION_UID_IMPORT;
            LoaderStateReturn <= to_unsigned(LoaderStateSectionImport1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionFunction0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionImport1) then
          -- section size
          NumImportsIteration <= (others => '0');
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionImport2, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionImport2) then
          NumImports <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionImport3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionImport3) then
          -- number of types
        if (NumImportsIteration /= unsigned(NumImports)) then
            NumImportsIteration <= NumImportsIteration + 1;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionImport4, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
        else
            LoaderStateReturn <= to_unsigned(LoaderStateSectionFunction0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        end if;
      elsif (LoaderState = LoaderStateSectionImport4) then
          -- string length of import module name
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionImport5, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionImport5) then
          -- string length of import field name
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderStateReturn <= to_unsigned(LoaderStateSectionImport6, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionImport6) then
          -- import kind 
          if (ReadData = x"00") then
            -- functype
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionImportFuncType0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          elsif (ReadData = x"01") then
            -- tabletype
            LoaderStateReturnTableType <= to_unsigned(LoaderStateSectionImport3, LoaderState'LENGTH);
            LoaderStateReturn <= to_unsigned(LoaderStateTableType0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          elsif (ReadData = x"02") then
            -- memtype
            LoaderStateReturnLimits <= to_unsigned(LoaderStateSectionImport3, LoaderState'LENGTH);
            LoaderStateReturn <= to_unsigned(LoaderStateLimits0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          elsif (ReadData = x"03") then
            -- globaltype
            LoaderStateReturnGlobalType <= to_unsigned(LoaderStateSectionImport3, LoaderState'LENGTH);
            LoaderStateReturn <= to_unsigned(LoaderStateGlobalType0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateError, LoaderState'LENGTH);
          end if;
      --
      -- Section "Import" (2) - FuncType
      --
      elsif (LoaderState = LoaderStateSectionImportFuncType0) then
          -- typeidx
          LoaderState <= to_unsigned(LoaderStateSectionImport3, LoaderState'LENGTH);
      --
      -- Section "Import" (2) - MemType
      --
      elsif (LoaderState = LoaderStateSectionImportMemType0) then
          -- export func index
          LoaderState <= to_unsigned(LoaderStateSectionExport3, LoaderState'LENGTH);
      --
      -- Section "Function" (3)
      --
      elsif (LoaderState = LoaderStateSectionFunction0) then
          if (ReadData = SECTION_UID_FUNCTION(7 downto 0)) then
            SectionUID <= SECTION_UID_FUNCTION;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionFunction1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionTable0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionFunction1) then
          -- section size
            NumFunctionsIteration <= (others => '0');
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionFunction2, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionFunction2) then
          NumFunctions <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionFunction3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionFunction3) then
          -- num functions
          if (NumFunctionsIteration /= unsigned(NumFunctions)) then
            NumFunctionsIteration <= NumFunctionsIteration + 1;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionFunction4, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateSectionTable0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionFunction4) then
          -- function signature index
          LoaderState <= to_unsigned(LoaderStateSectionFunction3, LoaderState'LENGTH);
      --
      -- Section "Table" (4)
      --
      elsif (LoaderState = LoaderStateSectionTable0) then
          if (ReadData = SECTION_UID_TABLE(7 downto 0)) then
            SectionUID <= SECTION_UID_TABLE;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionTable1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionMemory0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionTable1) then
          -- section size
          NumTablesIteration <= (others => '0');
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionTable2, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionTable2) then
          NumTables <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionTable3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionTable3) then
          -- num tables
          if (NumTablesIteration /= unsigned(NumTables)) then
            NumTablesIteration <= NumTablesIteration + 1;
            LoaderStateReturnTableType <= to_unsigned(LoaderStateSectionTable3, LoaderState'LENGTH);
            LoaderStateReturn <= to_unsigned(LoaderStateTableType0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateSectionMemory0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          end if;
      --
      -- Section "Memory" (5)
      --
      elsif (LoaderState = LoaderStateSectionMemory0) then
          if (ReadData = SECTION_UID_MEMORY(7 downto 0)) then
            SectionUID <= SECTION_UID_MEMORY;
            LoaderStateReturn <= to_unsigned(LoaderStateSectionMemory1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionGlobal0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionMemory1) then
          -- section size
            NumMemoriesIteration <= (others => '0');
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionMemory2, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionMemory2) then
          NumMemories <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionMemory3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionMemory3) then
          -- num memories
          if (NumMemoriesIteration /= unsigned(NumMemories)) then
            NumMemoriesIteration <= NumMemoriesIteration + 1;
            LoaderStateReturnLimits <= to_unsigned(LoaderStateSectionMemory3, LoaderState'LENGTH);
            LoaderStateReturn <= to_unsigned(LoaderStateLimits0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateSectionGlobal0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          end if;
      --
      -- Section "Global" (6)
      --
      elsif (LoaderState = LoaderStateSectionGlobal0) then
          if (ReadData = SECTION_UID_GLOBAL(7 downto 0)) then
            SectionUID <= SECTION_UID_GLOBAL;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionGlobal1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionExport0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionGlobal1) then
          -- section size
            NumGlobalsIteration <= (others => '0');
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionGlobal2, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionGlobal2) then
          NumGlobals <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionGlobal3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionGlobal3) then
          -- num memories
          if (NumGlobalsIteration /= unsigned(NumGlobals)) then
            NumGlobalsIteration <= NumGlobalsIteration + 1;
            LoaderStateReturnGlobalType <= to_unsigned(LoaderStateSectionGlobal3, LoaderState'LENGTH);
            LoaderStateReturn <= to_unsigned(LoaderStateGlobalType0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateSectionExport0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          end if;
      --
      -- Section "Export" (7)
      --
      elsif (LoaderState = LoaderStateSectionExport0) then
          if (ReadData = SECTION_UID_EXPORT(7 downto 0)) then
            SectionUID <= SECTION_UID_EXPORT;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionExport1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionStart0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionExport1) then
          -- section size
          NumExportsIteration <= (others => '0');
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionExport2, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionExport2) then
          NumExports <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionExport3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionExport3) then
          -- num exports
          if (NumExportsIteration /= unsigned(NumExports)) then
            NumExportsIteration <= NumExportsIteration + 1;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionExport4, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateSectionStart0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionExport4) then
          -- string length
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderStateReturn <= to_unsigned(LoaderStateSectionExport5, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionExport5) then
          -- export kind
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionExport6, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionExport6) then
          -- export func index
          LoaderState <= to_unsigned(LoaderStateSectionExport3, LoaderState'LENGTH);
      --
      -- Section "Start" (8)
      --
      elsif (LoaderState = LoaderStateSectionStart0) then
          if (ReadData = SECTION_UID_START(7 downto 0)) then
            SectionUID <= SECTION_UID_START;
            Idx <= (others => '0');
            Address <= x"00" & ReadAddress;
            LoaderStateReturn <= to_unsigned(LoaderStateSectionStart1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateWriteStore0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionElement0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionStart1) then
        LoaderStateReturn <= to_unsigned(LoaderStateSectionStart2, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionStart2) then
          -- section size
          NumExportsIteration <= (others => '0');
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionStart3, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionStart3) then
          StartFuncIndex <= DecodedValue;
          LoaderStateReturn <= to_unsigned(LoaderStateSectionElement0, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      --
      -- Section "Element" (9)
      --
      elsif (LoaderState = LoaderStateSectionElement0) then
          if (ReadData = SECTION_UID_ELEMENT(7 downto 0)) then
            SectionUID <= SECTION_UID_ELEMENT;
            LoaderStateReturn <= to_unsigned(LoaderStateSectionElement1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionCode0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionElement1) then
          -- section size
          NumElementsIteration <= (others => '0');
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionElement2, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionElement2) then
          NumElements <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionElement3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionElement3) then
          -- num elements
          if (NumElementsIteration /= unsigned(NumElements)) then
            NumElementsIteration <= NumElementsIteration + 1;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionElement4, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateSectionCode0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionElement4) then
          -- typeidx
          if (ReadData /= x"0B") then
            LoaderStateReturn <= to_unsigned(LoaderStateSectionElement4, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            NumFunctionsIteration <= (others => '0');
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionElement5, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionElement4) then
          NumFunctions <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionElement5, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionElement5) then
          -- num elements
          if (NumFunctionsIteration /= unsigned(NumFunctions)) then
            NumFunctionsIteration <= NumFunctionsIteration + 1;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionElement5, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionElement3, LoaderState'LENGTH);
          end if;
      --
      -- Section "Code" (10)
      --
      elsif (LoaderState = LoaderStateSectionCode0) then
          if (ReadData = SECTION_UID_CODE(7 downto 0)) then
            SectionUID <= SECTION_UID_CODE;
            Idx <= (others => '0');
            Address <= x"00" & ReadAddress;
            LoaderStateReturn <= to_unsigned(LoaderStateSectionCode1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateWriteStore0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateSectionData0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionCode1) then
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionCode2, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionCode2) then
          -- section size
          NumFunctionsIteration <= (others => '0');
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionCode3, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionCode3) then
          NumFunctions <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionCode4, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionCode4) then
          -- num functions
          if (NumFunctionsIteration /= unsigned(NumFunctions)) then
            NumFunctionsIteration <= NumFunctionsIteration + 1;
            Idx <= std_logic_vector(NumFunctionsIteration);
            Address <= x"00" & ReadAddress;
            LoaderStateReturn <= to_unsigned(LoaderStateSectionCode5, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateWriteStore0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateSectionData0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionCode5) then
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionCode6, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionCode6) then
          -- func body size
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderState <= to_unsigned(LoaderStateSectionCode4, LoaderState'LENGTH);
      --
      -- Section "Data" (11)
      --
      elsif (LoaderState = LoaderStateSectionData0) then
          if (ReadData = SECTION_UID_DATA(7 downto 0)) then
            SectionUID <= SECTION_UID_DATA;
            LoaderStateReturn <= to_unsigned(LoaderStateSectionData1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateLoaded, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionData1) then
          -- section size 
          NumDataIteration <= (others => '0');
          LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionData2, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionData2) then
          NumData <= DecodedValue;
          LoaderState <= to_unsigned(LoaderStateSectionData3, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateSectionData3) then
          -- num data segments
          if (NumDataIteration /= unsigned(NumData)) then
            NumDataIteration <= NumDataIteration + 1;
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionData4, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateLoaded, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionData4) then
          -- data segment flags (memidx)
          if (ReadData /= x"0B") then
            LoaderStateReturn <= to_unsigned(LoaderStateSectionData4, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderStateReturnU32 <= to_unsigned(LoaderStateSectionData5, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateSectionData5) then
          -- data segment size
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderState <= to_unsigned(LoaderStateSectionData3, LoaderState'LENGTH);
      --
      -- Loaded
      --
      elsif (LoaderState = LoaderStateLoaded) then
        LoadedBuf <= '1';
        LoaderState <= to_unsigned(LoaderStateIdle0, LoaderState'LENGTH);
      --
      -- Read globaltype
      --
      elsif (LoaderState = LoaderStateGlobalType0) then
          -- valtype
          LoaderStateReturn <= to_unsigned(LoaderStateGlobalType1, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateGlobalType1) then
          -- mutability
          LoaderStateReturn <= to_unsigned(LoaderStateGlobalType2, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateGlobalType2) then
          -- data segment flags (memidx)
          if (ReadData /= x"0B") then
            LoaderStateReturn <= to_unsigned(LoaderStateGlobalType2, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderStateReturn <= to_unsigned(LoaderStateGlobalType3, LoaderState'LENGTH);
          end if;
      --
      -- Read tabletype
      --
      elsif (LoaderState = LoaderStateTableType0) then
          -- elemtype
          if (ReadData = x"70") then
            LoaderStateReturnLimits <= LoaderStateReturnTableType;
            LoaderStateReturn <= to_unsigned(LoaderStateLimits0, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateError, LoaderState'LENGTH);
          end if;
      --
      -- Read limits
      --
      elsif (LoaderState = LoaderStateLimits0) then
          -- limits
          if (ReadData = x"00") then
            -- min
            LoaderStateReturnU32 <= to_unsigned(LoaderStateLimits1, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          elsif(ReadData = x"01") then
            -- min, max
            LoaderStateReturnU32 <= to_unsigned(LoaderStateLimits2, LoaderState'LENGTH);
            LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
          else
            LoaderState <= to_unsigned(LoaderStateError, LoaderState'LENGTH);
          end if;
      elsif (LoaderState = LoaderStateLimits1) then
          -- min
          LoaderState <= LoaderStateReturnLimits;
      elsif (LoaderState = LoaderStateLimits2) then
          -- min
          LoaderStateReturnU32 <= to_unsigned(LoaderStateLimits3, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadU32_0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateLimits3) then
          -- max
          LoaderState <= LoaderStateReturnLimits;
      --
      -- Read u32 (LEB128 encoded)
      --
      elsif (LoaderState = LoaderStateReadU32_0) then
        DecodedValue <= (others => '0');
        LoaderStateReturn <= to_unsigned(LoaderStateReadU32_1, LoaderState'LENGTH);
        LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateReadU32_1) then
        if ((ReadData and x"80") = x"00") then
          -- 1 byte
          DecodedValue(6 downto 0) <= ReadData(6 downto 0);
          LoaderState <= LoaderStateReturnU32;
        else 
          LoaderStateReturn <= to_unsigned(LoaderStateReadU32_2, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        end if;
      elsif (LoaderState = LoaderStateReadU32_3) then
        if ((ReadData and x"80") = x"00") then
          -- 2 byte
          DecodedValue(13 downto 7) <= ReadData(6 downto 0);
          LoaderState <= LoaderStateReturnU32;
        else
          LoaderStateReturn <= to_unsigned(LoaderStateReadU32_4, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        end if;
      elsif (LoaderState = LoaderStateReadU32_4) then
        if ((ReadData and x"80") = x"00") then
          -- 3 byte
          DecodedValue(20 downto 14) <= ReadData(6 downto 0);
          LoaderState <= LoaderStateReturnU32;
        else
          LoaderStateReturn <= to_unsigned(LoaderStateReadU32_5, LoaderState'LENGTH);
          LoaderState <= to_unsigned(LoaderStateReadRam0, LoaderState'LENGTH);
        end if;
      elsif (LoaderState = LoaderStateReadU32_5) then
        if ((ReadData and x"80") = x"00") then
          -- 4 byte
          DecodedValue(27 downto 21) <= ReadData(6 downto 0);
          LoaderState <= LoaderStateReturnU32;
        else
          -- > u32 not supported
          LoaderState <= to_unsigned(LoaderStateError, LoaderState'LENGTH);
        end if;
      --
      -- Read from Module RAM
      --
      elsif (LoaderState = LoaderStateReadRam0) then
        ReadModuleRun <= '1';
        LoaderState <= to_unsigned(LoaderStateReadRam1, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateReadRam1) then
        LoaderState <= to_unsigned(LoaderStateReadRam2, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateReadRam2) then
        ReadModuleRun <= '0';
        if(ReadModuleBusy = '0') then
            if ReadAddress(1 downto 0) = "00" then
                ReadData <= ReadModuleData(7 downto 0);
            elsif ReadAddress(1 downto 0) = "01" then
                ReadData <= ReadModuleData(15 downto 8);
            elsif ReadAddress(1 downto 0) = "10" then
                ReadData <= ReadModuleData(23 downto 16);
            else 
                ReadData <= ReadModuleData(31 downto 24);
            end if;
            ReadAddress <= std_logic_vector(unsigned(ReadAddress) + 1);
            LoaderState <= LoaderStateReturn;
        end if;
      --
      -- Write to Store
      --
      elsif (LoaderState = LoaderStateWriteStore0) then
        StoreRun <= '1';
        LoaderState <= to_unsigned(LoaderStateWriteStore1, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateWriteStore1) then
        LoaderState <= to_unsigned(LoaderStateWriteStore2, LoaderState'LENGTH);
      elsif (LoaderState = LoaderStateWriteStore2) then
        StoreRun <= '0';
        if(StoreBusy = '0') then
          LoaderState <= LoaderStateReturn;
        end if;
      --
      -- Trap
      --
      elsif (LoaderState = LoaderStateError) then
        LoaderState <= to_unsigned(LoaderStateError, LoaderState'LENGTH);
      end if;
    end if;
  end process;

  ReadModule : process (Clk, Rst) is
  begin
    if (Rst = '1') then
      ReadModuleBusy <= '0';
      ReadModuleData <= (others => '0');
      Memory_Cyc <= (others => '0');
      Memory_Stb <= '0';
      Memory_Adr <= (others => '0');
      Memory_Sel <= (others => '0');
      ReadModuleState <= (others => '0');
    elsif rising_edge(Clk) then
      if( ReadModuleState = ReadModuleStateIdle0 ) then
        ReadModuleBusy <= '0';
        Memory_Cyc <= (others => '0');
        Memory_Stb <= '0';
        Memory_Adr <= (others => '0');
        Memory_Sel <= (others => '0');
        if( ReadModuleRun = '1' ) then
          ReadModuleBusy <= '1';
          Memory_Cyc <= "1";
          Memory_Stb <= '1';
          Memory_Adr <= "00" & ReadAddress(23 downto 2);
          Memory_Sel <= (others => '1');
          ReadModuleState <= to_unsigned(ReadModuleStateReadCyc0, ReadModuleState'LENGTH);
        end if;
      elsif( ReadModuleState = ReadModuleStateReadCyc0 ) then
        if ( Memory_Ack = '1' ) then
          ReadModuleData <= Memory_DatIn;
          ReadModuleState <= to_unsigned(ReadModuleStateReadAck0, ReadModuleState'LENGTH);
        end if;
      elsif( ReadModuleState = ReadModuleStateReadAck0 ) then
        Memory_Cyc <= (others => '0');
        Memory_Stb <= '0';
        ReadModuleBusy <= '0';
        ReadModuleState <= to_unsigned(ReadModuleStateIdle0, ReadModuleState'LENGTH);
      end if;
    end if;
  end process;

  WasmFpgaLoader_StoreBlk_i : WasmFpgaLoader_StoreBlk
      port map (
        Clk => Clk,
        Rst => Rst,
        Adr => Store_Adr,
        Sel => Store_Sel,
        DatIn => Store_DatOut,
        We => Store_We,
        Stb => Store_Stb,
        Cyc => Store_Cyc,
        StoreBlk_DatOut => Store_DatIn,
        StoreBlk_Ack => Store_Ack,
        StoreBlk_Unoccupied_Ack => '0',
        Operation => WASMFPGASTORE_VAL_Write,
        Run => StoreRun,
        Busy => StoreBusy,
        ModuleInstanceUID => ModuleInstanceUID,
        SectionUID => SectionUID,
        Idx => Idx,
        Address_ToBeRead => open,
        Address_Written => Address
      );

  LoaderBlk_WasmFpgaLoader_i : LoaderBlk_WasmFpgaLoader
      port map (
        Clk => Clk,
        Rst => Rst,
        Adr => Adr,
        Sel => Sel,
        DatIn => DatIn,
        We => We,
        Stb => Stb,
        Cyc => Cyc,
        LoaderBlk_DatOut => LoaderBlk_DatOut,
        LoaderBlk_Ack => LoaderBlk_Ack,
        LoaderBlk_Unoccupied_Ack => LoaderBlk_Unoccupied_Ack,
        Run => Run,
        Loaded => LoadedBuf,
        Busy => Busy
      );

end;
