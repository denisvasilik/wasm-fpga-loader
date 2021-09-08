


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



package WasmFpgaLoaderDebugWshBn_Package is


-- type decalarations ---------------------------------                    

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_2_t is                                        
      array (natural range <>) of std_logic_vector(1 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_3_t is                                        
      array (natural range <>) of std_logic_vector(1 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_4_t is                                        
      array (natural range <>) of std_logic_vector(3 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_5_t is                                        
      array (natural range <>) of std_logic_vector(4 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_6_t is                                        
      array (natural range <>) of std_logic_vector(5 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_7_t is                                        
      array (natural range <>) of std_logic_vector(6 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_8_t is                                        
      array (natural range <>) of std_logic_vector(7 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_9_t is                                        
      array (natural range <>) of std_logic_vector(8 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_10_t is                                    
      array (natural range <>) of std_logic_vector(9 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_11_t is                                    
      array (natural range <>) of std_logic_vector(10 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_12_t is                                    
      array (natural range <>) of std_logic_vector(11 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_13_t is                                    
      array (natural range <>) of std_logic_vector(12 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_14_t is                                    
      array (natural range <>) of std_logic_vector(13 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_15_t is                                    
      array (natural range <>) of std_logic_vector(14 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_16_t is                                    
      array (natural range <>) of std_logic_vector(15 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_24_t is                                    
      array (natural range <>) of std_logic_vector(23 downto 0);     

    type WasmFpgaLoaderDebug_arr_of_std_logic_vector_32_t is                                    
      array (natural range <>) of std_logic_vector(31 downto 0);    


    type T_WasmFpgaLoaderDebugWshBnDn is
    record
        Adr :   std_logic_vector(23 downto 0);
        Sel :   std_logic_vector(3 downto 0);
        DatIn :   std_logic_vector(31 downto 0);
        We :   std_logic;
        Stb :   std_logic;
        Cyc :   std_logic_vector(0 downto 0);
    end record;

    type array_of_T_WasmFpgaLoaderDebugWshBnDn is
      array (natural range <>) of T_WasmFpgaLoaderDebugWshBnDn;


    type T_WasmFpgaLoaderDebugWshBnUp is
    record
        DatOut :   std_logic_vector(31 downto 0);
        Ack :   std_logic;
    end record;

    type array_of_T_WasmFpgaLoaderDebugWshBnUp is
      array (natural range <>) of T_WasmFpgaLoaderDebugWshBnUp;

    type T_WasmFpgaLoaderDebugWshBn_UnOccpdRcrd is
    record
        forRecord_Adr :   std_logic_vector(23 downto 0);
        forRecord_Sel :   std_logic_vector(3 downto 0);
        forRecord_We :   std_logic;
        forRecord_Cyc :   std_logic_vector(0 downto 0);
        Unoccupied_Ack :   std_logic;
    end record;

    type array_of_T_WasmFpgaLoaderDebugWshBn_UnOccpdRcrd is
      array (natural range <>) of T_WasmFpgaLoaderDebugWshBn_UnOccpdRcrd;


    type T_EngineBlk_WasmFpgaLoaderDebugWshBn is
    record
        Loaded :   std_logic;
        Running :   std_logic;
        Address :   std_logic_vector(23 downto 0);
        Error :   std_logic_vector(7 downto 0);
    end record;

    type array_of_T_EngineBlk_WasmFpgaLoaderDebugWshBn is
      array (natural range <>) of T_EngineBlk_WasmFpgaLoaderDebugWshBn;




    -- ---------- WebAssembly Engine Block( EngineBlk ) ----------
    -- BUS: 

    constant WASMFPGALOADERDEBUG_ADR_BLK_BASE_EngineBlk                                              : std_logic_vector(23 downto 0) := x"000000";
    constant WASMFPGALOADERDEBUG_ADR_BLK_SIZE_EngineBlk                                              : std_logic_vector(23 downto 0) := x"00000F";

        -- StatusReg: Status Register 
        constant WASMFPGALOADERDEBUG_WIDTH_StatusReg                                                 : integer := 32;
        constant WASMFPGALOADERDEBUG_ADR_StatusReg                                                   : std_logic_vector(23 downto 0) := std_logic_vector(x"000000" + unsigned(WASMFPGALOADERDEBUG_ADR_BLK_BASE_EngineBlk));

            -- 
            constant WASMFPGALOADERDEBUG_BUS_MASK_Loaded                                             : std_logic_vector(31 downto 0) := x"00000002";

                -- Module has not been loaded.
                constant WASMFPGALOADERDEBUG_VAL_ModuleHasNotBeenLoaded                              : std_logic := '0';
                -- Module has been loaded.
                constant WASMFPGALOADERDEBUG_VAL_ModuleHasBeenLoaded                                 : std_logic := '1';


            -- 
            constant WASMFPGALOADERDEBUG_BUS_MASK_Running                                            : std_logic_vector(31 downto 0) := x"00000001";

                -- Loader is not running.
                constant WASMFPGALOADERDEBUG_VAL_IsNotRunning                                        : std_logic := '0';
                -- Loader is running.
                constant WASMFPGALOADERDEBUG_VAL_IsRunning                                           : std_logic := '1';


        -- AddressReg: Address Register 
        constant WASMFPGALOADERDEBUG_WIDTH_AddressReg                                                : integer := 32;
        constant WASMFPGALOADERDEBUG_ADR_AddressReg                                                  : std_logic_vector(23 downto 0) := std_logic_vector(x"000004" + unsigned(WASMFPGALOADERDEBUG_ADR_BLK_BASE_EngineBlk));

            -- Address of the current position in the module ram.

            constant WASMFPGALOADERDEBUG_BUS_MASK_Address                                            : std_logic_vector(31 downto 0) := x"00FFFFFF";

        -- ErrorReg: Error Register 
        constant WASMFPGALOADERDEBUG_WIDTH_ErrorReg                                                  : integer := 32;
        constant WASMFPGALOADERDEBUG_ADR_ErrorReg                                                    : std_logic_vector(23 downto 0) := std_logic_vector(x"00000C" + unsigned(WASMFPGALOADERDEBUG_ADR_BLK_BASE_EngineBlk));

            -- Internal error code of the WASM module loader.

            constant WASMFPGALOADERDEBUG_BUS_MASK_Error                                              : std_logic_vector(31 downto 0) := x"000000FF";




end WasmFpgaLoaderDebugWshBn_Package;
