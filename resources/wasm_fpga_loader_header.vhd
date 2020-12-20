


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



package WasmFpgaLoaderWshBn_Package is


-- type decalarations ---------------------------------                    

    type WasmFpgaLoader_arr_of_std_logic_vector_2_t is                                        
      array (natural range <>) of std_logic_vector(1 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_3_t is                                        
      array (natural range <>) of std_logic_vector(1 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_4_t is                                        
      array (natural range <>) of std_logic_vector(3 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_5_t is                                        
      array (natural range <>) of std_logic_vector(4 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_6_t is                                        
      array (natural range <>) of std_logic_vector(5 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_7_t is                                        
      array (natural range <>) of std_logic_vector(6 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_8_t is                                        
      array (natural range <>) of std_logic_vector(7 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_9_t is                                        
      array (natural range <>) of std_logic_vector(8 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_10_t is                                    
      array (natural range <>) of std_logic_vector(9 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_11_t is                                    
      array (natural range <>) of std_logic_vector(10 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_12_t is                                    
      array (natural range <>) of std_logic_vector(11 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_13_t is                                    
      array (natural range <>) of std_logic_vector(12 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_14_t is                                    
      array (natural range <>) of std_logic_vector(13 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_15_t is                                    
      array (natural range <>) of std_logic_vector(14 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_16_t is                                    
      array (natural range <>) of std_logic_vector(15 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_24_t is                                    
      array (natural range <>) of std_logic_vector(23 downto 0);     

    type WasmFpgaLoader_arr_of_std_logic_vector_32_t is                                    
      array (natural range <>) of std_logic_vector(31 downto 0);    


    type T_WasmFpgaLoaderWshBnDn is
    record
        Adr :   std_logic_vector(23 downto 0);
        Sel :   std_logic_vector(3 downto 0);
        DatIn :   std_logic_vector(31 downto 0);
        We :   std_logic;
        Stb :   std_logic;
        Cyc :   std_logic_vector(0 downto 0);
    end record;

    type array_of_T_WasmFpgaLoaderWshBnDn is
      array (natural range <>) of T_WasmFpgaLoaderWshBnDn;


    type T_WasmFpgaLoaderWshBnUp is
    record
        DatOut :   std_logic_vector(31 downto 0);
        Ack :   std_logic;
    end record;

    type array_of_T_WasmFpgaLoaderWshBnUp is
      array (natural range <>) of T_WasmFpgaLoaderWshBnUp;

    type T_WasmFpgaLoaderWshBn_UnOccpdRcrd is
    record
        forRecord_Adr :   std_logic_vector(23 downto 0);
        forRecord_Sel :   std_logic_vector(3 downto 0);
        forRecord_We :   std_logic;
        forRecord_Cyc :   std_logic_vector(0 downto 0);
        Unoccupied_Ack :   std_logic;
    end record;

    type array_of_T_WasmFpgaLoaderWshBn_UnOccpdRcrd is
      array (natural range <>) of T_WasmFpgaLoaderWshBn_UnOccpdRcrd;

    type T_WasmFpgaLoaderWshBn_LoaderBlk is
    record
        Run :   std_logic;
    end record;

    type array_of_T_WasmFpgaLoaderWshBn_LoaderBlk is
      array (natural range <>) of T_WasmFpgaLoaderWshBn_LoaderBlk;


    type T_LoaderBlk_WasmFpgaLoaderWshBn is
    record
        Loaded :   std_logic;
        Busy :   std_logic;
    end record;

    type array_of_T_LoaderBlk_WasmFpgaLoaderWshBn is
      array (natural range <>) of T_LoaderBlk_WasmFpgaLoaderWshBn;




    -- ---------- WebAssembly Module Loader Block( LoaderBlk ) ----------
    -- BUS: 

    constant WASMFPGALOADER_ADR_BLK_BASE_LoaderBlk                                                   : std_logic_vector(23 downto 0) := x"000000";
    constant WASMFPGALOADER_ADR_BLK_SIZE_LoaderBlk                                                   : std_logic_vector(23 downto 0) := x"000010";

        -- ControlReg: Control Register 
        constant WASMFPGALOADER_WIDTH_ControlReg                                                     : integer := 32;
        constant WASMFPGALOADER_ADR_ControlReg                                                       : std_logic_vector(23 downto 0) := std_logic_vector(x"000000" + unsigned(WASMFPGALOADER_ADR_BLK_BASE_LoaderBlk));

            -- 
            constant WASMFPGALOADER_BUS_MASK_Run                                                     : std_logic_vector(31 downto 0) := x"00000001";

                -- Do not load modules
                constant WASMFPGALOADER_VAL_DoNotRun                                                 : std_logic := '0';
                -- Load modules
                constant WASMFPGALOADER_VAL_DoRun                                                    : std_logic := '1';


        -- StatusReg: Status Register 
        constant WASMFPGALOADER_WIDTH_StatusReg                                                      : integer := 32;
        constant WASMFPGALOADER_ADR_StatusReg                                                        : std_logic_vector(23 downto 0) := std_logic_vector(x"000004" + unsigned(WASMFPGALOADER_ADR_BLK_BASE_LoaderBlk));

            -- 
            constant WASMFPGALOADER_BUS_MASK_Loaded                                                  : std_logic_vector(31 downto 0) := x"00000002";

                -- Module has not been loaded.
                constant WASMFPGALOADER_VAL_HasNotBeenLoaded                                         : std_logic := '0';
                -- Module has been loaded.
                constant WASMFPGALOADER_VAL_HasBeenLoaded                                            : std_logic := '1';


            -- 
            constant WASMFPGALOADER_BUS_MASK_Busy                                                    : std_logic_vector(31 downto 0) := x"00000001";

                -- Module loader is idle.
                constant WASMFPGALOADER_VAL_IsNotBusy                                                : std_logic := '0';
                -- Module loader is busy.
                constant WASMFPGALOADER_VAL_IsBusy                                                   : std_logic := '1';





end WasmFpgaLoaderWshBn_Package;
