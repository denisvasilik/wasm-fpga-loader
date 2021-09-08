library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.WasmFpgaLoaderPackage.all;
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
end;

architecture WasmFpgaLoaderArchitecture of WasmFpgaLoader is

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

	signal LoaderState : std_logic_vector(7 downto 0);
  signal LoaderStateReturn : std_logic_vector(7 downto 0);
  signal LoaderStateReturnU32 : std_logic_vector(7 downto 0);
  signal LoaderStateReturnLimits : std_logic_vector(7 downto 0);
  signal LoaderStateReturnTableType : std_logic_vector(7 downto 0);
  signal LoaderStateReturnGlobalType : std_logic_vector(7 downto 0);

  constant WasmBinaryMagic : std_logic_vector(31 downto 0) := x"6D736100";
  constant WasmBinaryVersion : std_logic_vector(31 downto 0) := x"00000001";

  constant SECTION_UID_TYPE : std_logic_vector(31 downto 0) := x"00000001";
  constant SECTION_UID_IMPORT : std_logic_vector(31 downto 0) := x"00000002";
  constant SECTION_UID_FUNCTION : std_logic_vector(31 downto 0) := x"00000003";
  constant SECTION_UID_TABLE : std_logic_vector(31 downto 0) := x"00000004";
  constant SECTION_UID_MEMORY : std_logic_vector(31 downto 0) := x"00000005";
  constant SECTION_UID_GLOBAL : std_logic_vector(31 downto 0) := x"00000006";
  constant SECTION_UID_EXPORT : std_logic_vector(31 downto 0) := x"00000007";
  constant SECTION_UID_START : std_logic_vector(31 downto 0) := x"00000008";
  constant SECTION_UID_ELEMENT : std_logic_vector(31 downto 0) := x"00000009";
  constant SECTION_UID_CODE : std_logic_vector(31 downto 0) := x"0000000A";
  constant SECTION_UID_DATA : std_logic_vector(31 downto 0) := x"0000000B";

begin

  Rst <= not nRst;

  Ack <= LoaderBlk_Ack;
  DatOut <= LoaderBlk_DatOut;

  Memory_We <= '0';
  Memory_DatOut <= (others => '0');

  Loaded <= LoadedBuf;

  DecodeModule : process (Clk, Rst)
    constant StateIdle0 : std_logic_vector(7 downto 0) := x"00";
    constant StateMagicNumber0 : std_logic_vector(7 downto 0) := x"01";
    constant StateMagicNumber1 : std_logic_vector(7 downto 0) := x"02";
    constant StateMagicNumber2 : std_logic_vector(7 downto 0) := x"03";
    constant StateMagicNumber3 : std_logic_vector(7 downto 0) := x"04";
    constant StateMagicNumber4 : std_logic_vector(7 downto 0) := x"05";
    constant StateMagicNumber5 : std_logic_vector(7 downto 0) := x"06";
    constant StateBinaryVersion6 : std_logic_vector(7 downto 0) := x"07";
    constant StateBinaryVersion7 : std_logic_vector(7 downto 0) := x"08";
    constant StateBinaryVersion8 : std_logic_vector(7 downto 0) := x"09";
    constant StateBinaryVersion9 : std_logic_vector(7 downto 0) := x"0A";
    constant StateBinaryVersion10 : std_logic_vector(7 downto 0) := x"0B";
    constant StateBinaryVersion11 : std_logic_vector(7 downto 0) := x"0C";
    constant StateSectionType0 : std_logic_vector(7 downto 0) := x"0F";
    constant StateSectionType1 : std_logic_vector(7 downto 0) := x"10";
    constant StateSectionType2 : std_logic_vector(7 downto 0) := x"11";
    constant StateSectionType3 : std_logic_vector(7 downto 0) := x"12";
    constant StateSectionType4 : std_logic_vector(7 downto 0) := x"13";
    constant StateParseFuncType0 : std_logic_vector(7 downto 0) := x"14";
    constant StateParseFuncType1 : std_logic_vector(7 downto 0) := x"15";
    constant StateParseFuncType2 : std_logic_vector(7 downto 0) := x"16";
    constant StateParseFuncType3 : std_logic_vector(7 downto 0) := x"17";
    constant StateSectionImport0 : std_logic_vector(7 downto 0) := x"18";
    constant StateSectionImport1 : std_logic_vector(7 downto 0) := x"19";
    constant StateSectionImport2 : std_logic_vector(7 downto 0) := x"20";
    constant StateSectionImport3 : std_logic_vector(7 downto 0) := x"21";
    constant StateSectionImport4 : std_logic_vector(7 downto 0) := x"22";
    constant StateSectionImport5 : std_logic_vector(7 downto 0) := x"23";
    constant StateSectionImport6 : std_logic_vector(7 downto 0) := x"24";
    constant StateSectionImportFuncType0 : std_logic_vector(7 downto 0) := x"25";
    constant StateSectionImportMemType0 : std_logic_vector(7 downto 0) := x"26";
    constant StateGlobalType0 : std_logic_vector(7 downto 0) := x"27";
    constant StateGlobalType1 : std_logic_vector(7 downto 0) := x"28";
    constant StateGlobalType2 : std_logic_vector(7 downto 0) := x"29";
    constant StateGlobalType3 : std_logic_vector(7 downto 0) := x"2A";
    constant StateSectionFunction0 : std_logic_vector(7 downto 0) := x"2B";
    constant StateSectionFunction1 : std_logic_vector(7 downto 0) := x"2C";
    constant StateSectionFunction2 : std_logic_vector(7 downto 0) := x"2D";
    constant StateSectionFunction3 : std_logic_vector(7 downto 0) := x"2E";
    constant StateSectionFunction4 : std_logic_vector(7 downto 0) := x"2F";
    constant StateSectionTable0 : std_logic_vector(7 downto 0) := x"30";
    constant StateSectionTable1 : std_logic_vector(7 downto 0) := x"31";
    constant StateSectionTable2 : std_logic_vector(7 downto 0) := x"32";
    constant StateSectionTable3 : std_logic_vector(7 downto 0) := x"33";
    constant StateSectionMemory0 : std_logic_vector(7 downto 0) := x"34";
    constant StateSectionMemory1 : std_logic_vector(7 downto 0) := x"35";
    constant StateSectionMemory2 : std_logic_vector(7 downto 0) := x"36";
    constant StateSectionMemory3 : std_logic_vector(7 downto 0) := x"37";
    constant StateSectionGlobal0 : std_logic_vector(7 downto 0) := x"38";
    constant StateSectionGlobal1 : std_logic_vector(7 downto 0) := x"39";
    constant StateSectionGlobal2 : std_logic_vector(7 downto 0) := x"3A";
    constant StateSectionGlobal3 : std_logic_vector(7 downto 0) := x"3B";
    constant StateSectionExport0 : std_logic_vector(7 downto 0) := x"3C";
    constant StateSectionExport1 : std_logic_vector(7 downto 0) := x"3D";
    constant StateSectionExport2 : std_logic_vector(7 downto 0) := x"3E";
    constant StateSectionExport3 : std_logic_vector(7 downto 0) := x"3F";
    constant StateSectionExport4 : std_logic_vector(7 downto 0) := x"40";
    constant StateSectionExport5 : std_logic_vector(7 downto 0) := x"41";
    constant StateSectionExport6 : std_logic_vector(7 downto 0) := x"42";
    constant StateSectionStart0 : std_logic_vector(7 downto 0) := x"43";
    constant StateSectionStart1 : std_logic_vector(7 downto 0) := x"44";
    constant StateSectionStart2 : std_logic_vector(7 downto 0) := x"45";
    constant StateSectionStart3 : std_logic_vector(7 downto 0) := x"46";
    constant StateSectionElement0 : std_logic_vector(7 downto 0) := x"47";
    constant StateSectionElement1 : std_logic_vector(7 downto 0) := x"48";
    constant StateSectionElement2 : std_logic_vector(7 downto 0) := x"49";
    constant StateSectionElement3 : std_logic_vector(7 downto 0) := x"4A";
    constant StateSectionElement4 : std_logic_vector(7 downto 0) := x"4B";
    constant StateSectionElement5 : std_logic_vector(7 downto 0) := x"4C";
    constant StateSectionCode0 : std_logic_vector(7 downto 0) := x"4D";
    constant StateSectionCode1 : std_logic_vector(7 downto 0) := x"4E";
    constant StateSectionCode2 : std_logic_vector(7 downto 0) := x"4F";
    constant StateSectionCode3 : std_logic_vector(7 downto 0) := x"50";
    constant StateSectionCode4 : std_logic_vector(7 downto 0) := x"51";
    constant StateSectionCode5 : std_logic_vector(7 downto 0) := x"52";
    constant StateSectionCode6 : std_logic_vector(7 downto 0) := x"53";
    constant StateSectionData0 : std_logic_vector(7 downto 0) := x"54";
    constant StateSectionData1 : std_logic_vector(7 downto 0) := x"55";
    constant StateSectionData2 : std_logic_vector(7 downto 0) := x"56";
    constant StateSectionData3 : std_logic_vector(7 downto 0) := x"57";
    constant StateSectionData4 : std_logic_vector(7 downto 0) := x"58";
    constant StateSectionData5 : std_logic_vector(7 downto 0) := x"59";
    constant StateLimits0 : std_logic_vector(7 downto 0) := x"5A";
    constant StateLimits1 : std_logic_vector(7 downto 0) := x"5B";
    constant StateLimits2 : std_logic_vector(7 downto 0) := x"5C";
    constant StateLimits3 : std_logic_vector(7 downto 0) := x"5D";
    constant StateTableType0 : std_logic_vector(7 downto 0) := x"5E";
    constant StateReadU32_0 : std_logic_vector(7 downto 0) := x"5F";
    constant StateReadU32_1 : std_logic_vector(7 downto 0) := x"60";
    constant StateReadU32_2 : std_logic_vector(7 downto 0) := x"61";
    constant StateReadU32_3 : std_logic_vector(7 downto 0) := x"62";
    constant StateReadU32_4 : std_logic_vector(7 downto 0) := x"63";
    constant StateReadU32_5 : std_logic_vector(7 downto 0) := x"64";
    constant StateWriteStore0 : std_logic_vector(7 downto 0) := x"65";
    constant StateWriteStore1 : std_logic_vector(7 downto 0) := x"66";
    constant StateWriteStore2 : std_logic_vector(7 downto 0) := x"67";
    constant StateReadRam0 : std_logic_vector(7 downto 0) := x"68";
    constant StateReadRam1 : std_logic_vector(7 downto 0) := x"69";
    constant StateReadRam2 : std_logic_vector(7 downto 0) := x"6A";
    constant StateLoaded0 : std_logic_vector(7 downto 0) := x"80";
    constant StateError : std_logic_vector(7 downto 0) := x"FF";
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
      Busy <= '0';
      StoreRun <= '0';
      LoadedBuf <= '0';
      StartFuncIndex <= (others => '0');
      LoaderState <= (others => '0');
      LoaderStateReturn <= (others => '0');
      LoaderStateReturnU32 <= (others => '0');
      LoaderStateReturnLimits <= (others => '0');
      LoaderStateReturnTableType <= (others => '0');
      LoaderStateReturnGlobalType <= (others => '0');
    elsif rising_edge(clk) then
      --
      -- Finished
      --
      if (LoaderState = StateIdle0) then
          Busy <= '0';
          if (Run = '1') then
              Busy <= '1';
              LoaderState <= StateMagicNumber0;
          end if;
      --
      -- WASM magic number
      --
      elsif (LoaderState = StateMagicNumber0) then
        LoaderStateReturn <= StateMagicNumber1;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateMagicNumber1) then
        ReadBinaryMagic(7 downto 0) <= ReadData;
        LoaderStateReturn <= StateMagicNumber2;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateMagicNumber2) then
        ReadBinaryMagic(15 downto 8) <= ReadData;
        LoaderStateReturn <= StateMagicNumber3;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateMagicNumber3) then
        ReadBinaryMagic(23 downto 16) <= ReadData;
        LoaderStateReturn <= StateMagicNumber4;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateMagicNumber4) then
        ReadBinaryMagic(31 downto 24) <= ReadData;
        LoaderState <= StateMagicNumber5;
      elsif (LoaderState = StateMagicNumber5) then
        if (ReadBinaryMagic = WasmBinaryMagic) then
          LoaderState <= StateBinaryVersion6;
        else
          LoaderState <= StateError;
        end if;
      --
      -- WASM binary version
      --
      elsif (LoaderState = StateBinaryVersion6) then
        LoaderStateReturn <= StateBinaryVersion7;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateBinaryVersion7) then
        ReadBinaryVersion(7 downto 0) <= ReadData;
        LoaderStateReturn <= StateBinaryVersion8;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateBinaryVersion8) then
        ReadBinaryVersion(15 downto 8) <= ReadData;
        LoaderStateReturn <= StateBinaryVersion9;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateBinaryVersion9) then
        ReadBinaryVersion(23 downto 16) <= ReadData;
        LoaderStateReturn <= StateBinaryVersion10;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateBinaryVersion10) then
        ReadBinaryVersion(31 downto 24) <= ReadData;
        LoaderState <= StateBinaryVersion11;
      elsif (LoaderState = StateBinaryVersion11) then
        if (ReadBinaryVersion = WasmBinaryVersion) then
          LoaderStateReturn <= StateSectionType0;
          LoaderState <= StateReadRam0;
        else
          LoaderState <= StateError;
        end if;
      --
      -- Section "Type" (1)
      --
      elsif (LoaderState = StateSectionType0) then
        if (ReadData = SECTION_UID_TYPE(7 downto 0)) then
          SectionUID <= SECTION_UID_TYPE;
          LoaderStateReturnU32 <= StateSectionType1;
          LoaderState <= StateReadU32_0;
        else
          LoaderState <= StateSectionImport0;
        end if;
      elsif (LoaderState = StateSectionType1) then
          -- section size
          NumTypesIteration <= (others => '0');
          LoaderStateReturnU32 <= StateSectionType2;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionType2) then
          NumTypes <= DecodedValue;
          LoaderState <= StateSectionType3;
      elsif (LoaderState = StateSectionType3) then
          -- number of types
        if (NumTypesIteration /= unsigned(NumTypes)) then
            NumTypesIteration <= NumTypesIteration + 1;
            LoaderStateReturn <= StateSectionType4;
            LoaderState <= StateReadRam0;
        else
            NumTypesIteration <= (others => '0');
            LoaderStateReturn <= StateSectionImport0;
            LoaderState <= StateReadRam0;
        end if;
      elsif (LoaderState = StateSectionType4) then
          -- type
          if (ReadData = x"60") then
            -- func
            NumParamsIteration <= (others => '0');
            LoaderStateReturnU32 <= StateParseFuncType0;
            LoaderState <= StateReadU32_0;
          else
            LoaderState <= StateError;
          end if;
      --
      -- Parse functype
      --
      elsif (LoaderState = StateParseFuncType0) then
          NumParams <= DecodedValue;
          LoaderState <= StateParseFuncType1;
      elsif (LoaderState = StateParseFuncType1) then
        -- num params
        if (NumParamsIteration /= unsigned(NumParams)) then
          NumParamsIteration <= NumParamsIteration + 1;
          LoaderStateReturn <= StateParseFuncType1;
          LoaderState <= StateReadRam0;
        else
            NumResultsIteration <= (others => '0');
            LoaderStateReturnU32 <= StateParseFuncType2;
            LoaderState <= StateReadU32_0;
        end if;
      elsif (LoaderState = StateParseFuncType2) then
          NumResults <= DecodedValue;
          LoaderState <= StateParseFuncType3;
      elsif (LoaderState = StateParseFuncType3) then
        -- num results
        if (NumResultsIteration /= unsigned(NumResults)) then
          NumResultsIteration <= NumResultsIteration + 1;
          LoaderStateReturn <= StateParseFuncType3;
          LoaderState <= StateReadRam0;
        else
            LoaderState <= StateSectionType3;
        end if;
      --
      -- Section "Import" (2)
      --
      elsif (LoaderState = StateSectionImport0) then
          if (ReadData = SECTION_UID_IMPORT(7 downto 0)) then
            SectionUID <= SECTION_UID_IMPORT;
            LoaderStateReturn <= StateSectionImport1;
            LoaderState <= StateReadRam0;
          else
            LoaderState <= StateSectionFunction0;
          end if;
      elsif (LoaderState = StateSectionImport1) then
          -- section size
          NumImportsIteration <= (others => '0');
          LoaderStateReturnU32 <= StateSectionImport2;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionImport2) then
          NumImports <= DecodedValue;
          LoaderState <= StateSectionImport3;
      elsif (LoaderState = StateSectionImport3) then
          -- number of types
        if (NumImportsIteration /= unsigned(NumImports)) then
            NumImportsIteration <= NumImportsIteration + 1;
            LoaderStateReturnU32 <= StateSectionImport4;
            LoaderState <= StateReadU32_0;
        else
            LoaderStateReturn <= StateSectionFunction0;
            LoaderState <= StateReadRam0;
        end if;
      elsif (LoaderState = StateSectionImport4) then
          -- string length of import module name
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderStateReturnU32 <= StateSectionImport5;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionImport5) then
          -- string length of import field name
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderStateReturn <= StateSectionImport6;
          LoaderState <= StateReadRam0;
      elsif (LoaderState = StateSectionImport6) then
          -- import kind
          if (ReadData = x"00") then
            -- functype
            LoaderStateReturnU32 <= StateSectionImportFuncType0;
            LoaderState <= StateReadU32_0;
          elsif (ReadData = x"01") then
            -- tabletype
            LoaderStateReturnTableType <= StateSectionImport3;
            LoaderStateReturn <= StateTableType0;
            LoaderState <= StateReadRam0;
          elsif (ReadData = x"02") then
            -- memtype
            LoaderStateReturnLimits <= StateSectionImport3;
            LoaderStateReturn <= StateLimits0;
            LoaderState <= StateReadRam0;
          elsif (ReadData = x"03") then
            -- globaltype
            LoaderStateReturnGlobalType <= StateSectionImport3;
            LoaderStateReturn <= StateGlobalType0;
            LoaderState <= StateReadRam0;
          else
            LoaderState <= StateError;
          end if;
      --
      -- Section "Import" (2) - FuncType
      --
      elsif (LoaderState = StateSectionImportFuncType0) then
          -- typeidx
          LoaderState <= StateSectionImport3;
      --
      -- Section "Import" (2) - MemType
      --
      elsif (LoaderState = StateSectionImportMemType0) then
          -- export func index
          LoaderState <= StateSectionExport3;
      --
      -- Section "Function" (3)
      --
      elsif (LoaderState = StateSectionFunction0) then
          if (ReadData = SECTION_UID_FUNCTION(7 downto 0)) then
            SectionUID <= SECTION_UID_FUNCTION;
            LoaderStateReturnU32 <= StateSectionFunction1;
            LoaderState <= StateReadU32_0;
          else
            LoaderState <= StateSectionTable0;
          end if;
      elsif (LoaderState = StateSectionFunction1) then
          -- section size
            NumFunctionsIteration <= (others => '0');
            LoaderStateReturnU32 <= StateSectionFunction2;
            LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionFunction2) then
          NumFunctions <= DecodedValue;
          LoaderState <= StateSectionFunction3;
      elsif (LoaderState = StateSectionFunction3) then
          -- num functions
          if (NumFunctionsIteration /= unsigned(NumFunctions)) then
            NumFunctionsIteration <= NumFunctionsIteration + 1;
            LoaderStateReturnU32 <= StateSectionFunction4;
            LoaderState <= StateReadU32_0;
          else
            LoaderStateReturn <= StateSectionTable0;
            LoaderState <= StateReadRam0;
          end if;
      elsif (LoaderState = StateSectionFunction4) then
          -- function signature index
          LoaderState <= StateSectionFunction3;
      --
      -- Section "Table" (4)
      --
      elsif (LoaderState = StateSectionTable0) then
          if (ReadData = SECTION_UID_TABLE(7 downto 0)) then
            SectionUID <= SECTION_UID_TABLE;
            LoaderStateReturnU32 <= StateSectionTable1;
            LoaderState <= StateReadU32_0;
          else
            LoaderState <= StateSectionMemory0;
          end if;
      elsif (LoaderState = StateSectionTable1) then
          -- section size
          NumTablesIteration <= (others => '0');
          LoaderStateReturnU32 <= StateSectionTable2;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionTable2) then
          NumTables <= DecodedValue;
          LoaderState <= StateSectionTable3;
      elsif (LoaderState = StateSectionTable3) then
          -- num tables
          if (NumTablesIteration /= unsigned(NumTables)) then
            NumTablesIteration <= NumTablesIteration + 1;
            LoaderStateReturnTableType <= StateSectionTable3;
            LoaderStateReturn <= StateTableType0;
            LoaderState <= StateReadRam0;
          else
            LoaderStateReturn <= StateSectionMemory0;
            LoaderState <= StateReadRam0;
          end if;
      --
      -- Section "Memory" (5)
      --
      elsif (LoaderState = StateSectionMemory0) then
          if (ReadData = SECTION_UID_MEMORY(7 downto 0)) then
            SectionUID <= SECTION_UID_MEMORY;
            LoaderStateReturn <= StateSectionMemory1;
            LoaderState <= StateReadRam0;
          else
            LoaderState <= StateSectionGlobal0;
          end if;
      elsif (LoaderState = StateSectionMemory1) then
          -- section size
            NumMemoriesIteration <= (others => '0');
            LoaderStateReturnU32 <= StateSectionMemory2;
            LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionMemory2) then
          NumMemories <= DecodedValue;
          LoaderState <= StateSectionMemory3;
      elsif (LoaderState = StateSectionMemory3) then
          -- num memories
          if (NumMemoriesIteration /= unsigned(NumMemories)) then
            NumMemoriesIteration <= NumMemoriesIteration + 1;
            LoaderStateReturnLimits <= StateSectionMemory3;
            LoaderStateReturn <= StateLimits0;
            LoaderState <= StateReadRam0;
          else
            LoaderStateReturn <= StateSectionGlobal0;
            LoaderState <= StateReadRam0;
          end if;
      --
      -- Section "Global" (6)
      --
      elsif (LoaderState = StateSectionGlobal0) then
          if (ReadData = SECTION_UID_GLOBAL(7 downto 0)) then
            SectionUID <= SECTION_UID_GLOBAL;
            LoaderStateReturnU32 <= StateSectionGlobal1;
            LoaderState <= StateReadU32_0;
          else
            LoaderState <= StateSectionExport0;
          end if;
      elsif (LoaderState = StateSectionGlobal1) then
          -- section size
            NumGlobalsIteration <= (others => '0');
            LoaderStateReturnU32 <= StateSectionGlobal2;
            LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionGlobal2) then
          NumGlobals <= DecodedValue;
          LoaderState <= StateSectionGlobal3;
      elsif (LoaderState = StateSectionGlobal3) then
          -- num memories
          if (NumGlobalsIteration /= unsigned(NumGlobals)) then
            NumGlobalsIteration <= NumGlobalsIteration + 1;
            LoaderStateReturnGlobalType <= StateSectionGlobal3;
            LoaderStateReturn <= StateGlobalType0;
            LoaderState <= StateReadRam0;
          else
            LoaderStateReturn <= StateSectionExport0;
            LoaderState <= StateReadRam0;
          end if;
      --
      -- Section "Export" (7)
      --
      elsif (LoaderState = StateSectionExport0) then
          if (ReadData = SECTION_UID_EXPORT(7 downto 0)) then
            SectionUID <= SECTION_UID_EXPORT;
            LoaderStateReturnU32 <= StateSectionExport1;
            LoaderState <= StateReadU32_0;
          else
            LoaderState <= StateSectionStart0;
          end if;
      elsif (LoaderState = StateSectionExport1) then
          -- section size
          NumExportsIteration <= (others => '0');
          LoaderStateReturnU32 <= StateSectionExport2;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionExport2) then
          NumExports <= DecodedValue;
          LoaderState <= StateSectionExport3;
      elsif (LoaderState = StateSectionExport3) then
          -- num exports
          if (NumExportsIteration /= unsigned(NumExports)) then
            NumExportsIteration <= NumExportsIteration + 1;
            LoaderStateReturnU32 <= StateSectionExport4;
            LoaderState <= StateReadU32_0;
          else
            LoaderStateReturn <= StateSectionStart0;
            LoaderState <= StateReadRam0;
          end if;
      elsif (LoaderState = StateSectionExport4) then
          -- string length
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderStateReturn <= StateSectionExport5;
          LoaderState <= StateReadRam0;
      elsif (LoaderState = StateSectionExport5) then
          -- export kind
          LoaderStateReturnU32 <= StateSectionExport6;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionExport6) then
          -- export func index
          LoaderState <= StateSectionExport3;
      --
      -- Section "Start" (8)
      --
      elsif (LoaderState = StateSectionStart0) then
          if (ReadData = SECTION_UID_START(7 downto 0)) then
            SectionUID <= SECTION_UID_START;
            Idx <= (others => '0');
            Address <= x"00" & ReadAddress;
            LoaderStateReturn <= StateSectionStart1;
            LoaderState <= StateWriteStore0;
          else
            LoaderState <= StateSectionElement0;
          end if;
      elsif (LoaderState = StateSectionStart1) then
        LoaderStateReturn <= StateSectionStart2;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateSectionStart2) then
          -- section size
          LoaderStateReturnU32 <= StateSectionStart3;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionStart3) then
          StartFuncIndex <= DecodedValue;
          LoaderStateReturn <= StateSectionElement0;
          LoaderState <= StateReadRam0;
      --
      -- Section "Element" (9)
      --
      elsif (LoaderState = StateSectionElement0) then
          if (ReadData = SECTION_UID_ELEMENT(7 downto 0)) then
            SectionUID <= SECTION_UID_ELEMENT;
            LoaderStateReturn <= StateSectionElement1;
            LoaderState <= StateReadRam0;
          else
            LoaderState <= StateSectionCode0;
          end if;
      elsif (LoaderState = StateSectionElement1) then
          -- section size
          NumElementsIteration <= (others => '0');
          LoaderStateReturnU32 <= StateSectionElement2;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionElement2) then
          NumElements <= DecodedValue;
          LoaderState <= StateSectionElement3;
      elsif (LoaderState = StateSectionElement3) then
          -- num elements
          if (NumElementsIteration /= unsigned(NumElements)) then
            NumElementsIteration <= NumElementsIteration + 1;
            LoaderStateReturnU32 <= StateSectionElement4;
            LoaderState <= StateReadU32_0;
          else
            LoaderStateReturn <= StateSectionCode0;
            LoaderState <= StateReadRam0;
          end if;
      elsif (LoaderState = StateSectionElement4) then
          -- typeidx
          if (ReadData /= x"0B") then
            LoaderStateReturn <= StateSectionElement4;
            LoaderState <= StateReadRam0;
          else
            NumFunctionsIteration <= (others => '0');
            LoaderStateReturnU32 <= StateSectionElement5;
            LoaderState <= StateReadU32_0;
          end if;
      elsif (LoaderState = StateSectionElement4) then
          NumFunctions <= DecodedValue;
          LoaderState <= StateSectionElement5;
      elsif (LoaderState = StateSectionElement5) then
          -- num elements
          if (NumFunctionsIteration /= unsigned(NumFunctions)) then
            NumFunctionsIteration <= NumFunctionsIteration + 1;
            LoaderStateReturnU32 <= StateSectionElement5;
            LoaderState <= StateReadU32_0;
          else
            LoaderState <= StateSectionElement3;
          end if;
      --
      -- Section "Code" (10)
      --
      elsif (LoaderState = StateSectionCode0) then
          if (ReadData = SECTION_UID_CODE(7 downto 0)) then
            SectionUID <= SECTION_UID_CODE;
            Idx <= (others => '1');
            Address <= x"00" & ReadAddress;
            LoaderStateReturn <= StateSectionCode1;
            LoaderState <= StateWriteStore0;
          else
            LoaderState <= StateSectionData0;
          end if;
      elsif (LoaderState = StateSectionCode1) then
            LoaderStateReturnU32 <= StateSectionCode2;
            LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionCode2) then
          -- section size
          NumFunctionsIteration <= (others => '0');
          LoaderStateReturnU32 <= StateSectionCode3;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionCode3) then
          NumFunctions <= DecodedValue;
          LoaderState <= StateSectionCode4;
      elsif (LoaderState = StateSectionCode4) then
          -- num functions
          if (NumFunctionsIteration /= unsigned(NumFunctions)) then
            NumFunctionsIteration <= NumFunctionsIteration + 1;
            Idx <= std_logic_vector(NumFunctionsIteration);
            Address <= x"00" & ReadAddress;
            LoaderStateReturn <= StateSectionCode5;
            LoaderState <= StateWriteStore0;
          else
            LoaderStateReturn <= StateSectionData0;
            LoaderState <= StateReadRam0;
          end if;
      elsif (LoaderState = StateSectionCode5) then
            LoaderStateReturnU32 <= StateSectionCode6;
            LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionCode6) then
          -- func body size
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderState <= StateSectionCode4;
      --
      -- Section "Data" (11)
      --
      elsif (LoaderState = StateSectionData0) then
          if (ReadData = SECTION_UID_DATA(7 downto 0)) then
            SectionUID <= SECTION_UID_DATA;
            LoaderStateReturn <= StateSectionData1;
            LoaderState <= StateReadRam0;
          else
            LoaderState <= StateLoaded0;
          end if;
      elsif (LoaderState = StateSectionData1) then
          -- section size
          NumDataIteration <= (others => '0');
          LoaderStateReturnU32 <= StateSectionData2;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateSectionData2) then
          NumData <= DecodedValue;
          LoaderState <= StateSectionData3;
      elsif (LoaderState = StateSectionData3) then
          -- num data segments
          if (NumDataIteration /= unsigned(NumData)) then
            NumDataIteration <= NumDataIteration + 1;
            LoaderStateReturnU32 <= StateSectionData4;
            LoaderState <= StateReadU32_0;
          else
            LoaderStateReturn <= StateLoaded0;
            LoaderState <= StateReadRam0;
          end if;
      elsif (LoaderState = StateSectionData4) then
          -- data segment flags (memidx)
          if (ReadData /= x"0B") then
            LoaderStateReturn <= StateSectionData4;
            LoaderState <= StateReadRam0;
          else
            LoaderStateReturnU32 <= StateSectionData5;
            LoaderState <= StateReadU32_0;
          end if;
      elsif (LoaderState = StateSectionData5) then
          -- data segment size
          ReadAddress <= std_logic_vector(unsigned(ReadAddress) + unsigned(DecodedValue(9 downto 0)));
          LoaderState <= StateSectionData3;
      --
      -- Loaded
      --
      elsif (LoaderState = StateLoaded0) then
        LoadedBuf <= '1';
      --
      -- Read globaltype
      --
      elsif (LoaderState = StateGlobalType0) then
          -- valtype
          LoaderStateReturn <= StateGlobalType1;
          LoaderState <= StateReadRam0;
      elsif (LoaderState = StateGlobalType1) then
          -- mutability
          LoaderStateReturn <= StateGlobalType2;
          LoaderState <= StateReadRam0;
      elsif (LoaderState = StateGlobalType2) then
          -- data segment flags (memidx)
          if (ReadData /= x"0B") then
            LoaderStateReturn <= StateGlobalType2;
            LoaderState <= StateReadRam0;
          else
            LoaderStateReturn <= StateGlobalType3;
          end if;
      --
      -- Read tabletype
      --
      elsif (LoaderState = StateTableType0) then
          -- elemtype
          if (ReadData = x"70") then
            LoaderStateReturnLimits <= LoaderStateReturnTableType;
            LoaderStateReturn <= StateLimits0;
            LoaderState <= StateReadRam0;
          else
            LoaderState <= StateError;
          end if;
      --
      -- Read limits
      --
      elsif (LoaderState = StateLimits0) then
          -- limits
          if (ReadData = x"00") then
            -- min
            LoaderStateReturnU32 <= StateLimits1;
            LoaderState <= StateReadU32_0;
          elsif(ReadData = x"01") then
            -- min, max
            LoaderStateReturnU32 <= StateLimits2;
            LoaderState <= StateReadU32_0;
          else
            LoaderState <= StateError;
          end if;
      elsif (LoaderState = StateLimits1) then
          -- min
          LoaderState <= LoaderStateReturnLimits;
      elsif (LoaderState = StateLimits2) then
          -- min
          LoaderStateReturnU32 <= StateLimits3;
          LoaderState <= StateReadU32_0;
      elsif (LoaderState = StateLimits3) then
          -- max
          LoaderState <= LoaderStateReturnLimits;
      --
      -- Read u32 (LEB128 encoded)
      --
      elsif (LoaderState = StateReadU32_0) then
        DecodedValue <= (others => '0');
        LoaderStateReturn <= StateReadU32_1;
        LoaderState <= StateReadRam0;
      elsif (LoaderState = StateReadU32_1) then
        if ((ReadData and x"80") = x"00") then
          -- 1 byte
          DecodedValue(6 downto 0) <= ReadData(6 downto 0);
          LoaderState <= LoaderStateReturnU32;
        else
          LoaderStateReturn <= StateReadU32_2;
          LoaderState <= StateReadRam0;
        end if;
      elsif (LoaderState = StateReadU32_3) then
        if ((ReadData and x"80") = x"00") then
          -- 2 byte
          DecodedValue(13 downto 7) <= ReadData(6 downto 0);
          LoaderState <= LoaderStateReturnU32;
        else
          LoaderStateReturn <= StateReadU32_4;
          LoaderState <= StateReadRam0;
        end if;
      elsif (LoaderState = StateReadU32_4) then
        if ((ReadData and x"80") = x"00") then
          -- 3 byte
          DecodedValue(20 downto 14) <= ReadData(6 downto 0);
          LoaderState <= LoaderStateReturnU32;
        else
          LoaderStateReturn <= StateReadU32_5;
          LoaderState <= StateReadRam0;
        end if;
      elsif (LoaderState = StateReadU32_5) then
        if ((ReadData and x"80") = x"00") then
          -- 4 byte
          DecodedValue(27 downto 21) <= ReadData(6 downto 0);
          LoaderState <= LoaderStateReturnU32;
        else
          -- > u32 not supported
          LoaderState <= StateError;
        end if;
      --
      -- Read from Module RAM
      --
      elsif (LoaderState = StateReadRam0) then
        ReadModuleRun <= '1';
        LoaderState <= StateReadRam1;
      elsif (LoaderState = StateReadRam1) then
        LoaderState <= StateReadRam2;
      elsif (LoaderState = StateReadRam2) then
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
      elsif (LoaderState = StateWriteStore0) then
        StoreRun <= '1';
        LoaderState <= StateWriteStore1;
      elsif (LoaderState = StateWriteStore1) then
        LoaderState <= StateWriteStore2;
      elsif (LoaderState = StateWriteStore2) then
        StoreRun <= '0';
        if(StoreBusy = '0') then
          LoaderState <= LoaderStateReturn;
        end if;
      --
      -- Trap
      --
      elsif (LoaderState = StateError) then
        LoaderState <= StateError;
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

  WasmFpgaLoader_StoreBlk_i : entity work.WasmFpgaLoader_StoreBlk
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

  LoaderBlk_WasmFpgaLoader_i : entity work.LoaderBlk_WasmFpgaLoader
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
