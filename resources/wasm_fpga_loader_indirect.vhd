

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.WasmFpgaLoaderWshBn_Package.all;

entity tb_WasmFpgaLoaderWshBn is
end tb_WasmFpgaLoaderWshBn;

architecture arch_for_test of tb_WasmFpgaLoaderWshBn is

    component tbs_WshFileIo is              
    generic (                               
         inp_file  : string;                
         outp_file : string                 
        );                                  
    port(                                   
        clock        : in    std_logic;     
        reset        : in    std_logic;     
        WshDn        : out   T_WshDn;       
        WshUp        : in    T_WshUp        
        );                                  
    end component;                          



    component WasmFpgaLoaderWshBn is
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            WasmFpgaLoaderWshBnDn : in T_WasmFpgaLoaderWshBnDn;
            WasmFpgaLoaderWshBnUp : out T_WasmFpgaLoaderWshBnUp;
            WasmFpgaLoaderWshBn_UnOccpdRcrd : out T_WasmFpgaLoaderWshBn_UnOccpdRcrd;
            WasmFpgaLoaderWshBn_LoaderBlk : out T_WasmFpgaLoaderWshBn_LoaderBlk;
            LoaderBlk_WasmFpgaLoaderWshBn : in T_LoaderBlk_WasmFpgaLoaderWshBn
         );
    end component; 


    signal Clk : std_logic := '0';                                         
    signal Rst : std_logic := '1';                                         



    signal WshDn : T_WshDn;
    signal WshUp : T_WshUp;
    signal Wsh_UnOccpdRcrd : T_Wsh_UnOccpdRcrd;
    signal Wsh_LoaderBlk : T_Wsh_LoaderBlk;
    signal LoaderBlk_Wsh : T_LoaderBlk_Wsh;



begin 


    i_tbs_WshFileIo : tbs_WshFileIo            
    generic map (                              
        inp_file  => "tb_mC_stimuli.txt",      
        outp_file => "src/tb_mC_trace.txt")    
    port map (                                 
        clock   => Clk,                        
        reset   => Rst,                        
        WshDn   => WshDn,                      
        WshUp   => WshUp                       
    );                                         



    -- ---------- map wishbone component ---------- 

    i_WasmFpgaLoaderWshBn :  WasmFpgaLoaderWshBn
     port map (
        WshDn => WshDn,
        WshUp => WshUp,
        Wsh_UnOccpdRcrd => Wsh_UnOccpdRcrd,
        Wsh_LoaderBlk => Wsh_LoaderBlk,
        LoaderBlk_Wsh => LoaderBlk_Wsh
        );

    -- ---------- assign defaults to all wishbone inputs ---------- 

    -- ------------------- general additional signals ------------------- 

    -- ------------------- LoaderBlk ------------------- 
    -- ControlReg  
    -- StatusReg  
    LoaderBlk_Wsh.Loaded <= '0';
    LoaderBlk_Wsh.Busy <= '0';



    WshDn.Clk <= Clk;                                                  
    WshDn.Rst <= Rst;                                                  
    -- ---------- drive testbench time --------------------                       
    Clk   <= TRANSPORT NOT Clk AFTER 12500 ps;  -- 40Mhz                       
    Rst   <= TRANSPORT '0' AFTER 100 ns;                                       


end architecture;

