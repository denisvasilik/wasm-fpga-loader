

-- ========== WebAssembly Module Loader Block( LoaderBlk) ========== 

-- This block describes the WebAssembly module loader block.
-- BUS: 


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.WasmFpgaLoaderWshBn_Package.all;

entity LoaderBlk_WasmFpgaLoader is
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
end LoaderBlk_WasmFpgaLoader;



architecture arch_for_synthesys of LoaderBlk_WasmFpgaLoader is

    -- ---------- block variables ---------- 
    signal PreMuxAck_Unoccupied : std_logic;
    signal UnoccupiedDec : std_logic_vector(1 downto 0);
    signal LoaderBlk_PreDatOut : std_logic_vector(31 downto 0);
    signal LoaderBlk_PreAck : std_logic;
    signal LoaderBlk_Unoccupied_PreAck : std_logic;
    signal PreMuxDatOut_ControlReg : std_logic_vector(31 downto 0);
    signal PreMuxAck_ControlReg : std_logic;
    signal PreMuxDatOut_StatusReg : std_logic_vector(31 downto 0);
    signal PreMuxAck_StatusReg : std_logic;

    signal WriteDiff_ControlReg : std_logic;
    signal ReadDiff_ControlReg : std_logic;


    signal WriteDiff_StatusReg : std_logic;
    signal ReadDiff_StatusReg : std_logic;


    signal WReg_Run : std_logic;

begin 

    -- ---------- block DatOut mux ----------

    gen_unoccupied_ack : process (Clk, Rst)
    begin 
        if (Rst = '1') then 
            PreMuxAck_Unoccupied <= '0';
            UnoccupiedDec <= "00";
        elsif rising_edge(Clk) then
            UnoccupiedDec(0) <= UnoccupiedDec(1); 
            UnoccupiedDec(1)  <= (Cyc(0)  and Stb);
            PreMuxAck_Unoccupied <= UnoccupiedDec(1) and not UnoccupiedDec(0);
        end if;
    end process;

    LoaderBlk_DatOut <= LoaderBlk_PreDatOut;
    LoaderBlk_Ack <=  LoaderBlk_PreAck;
    LoaderBlk_Unoccupied_Ack <= LoaderBlk_Unoccupied_PreAck;

    mux_data_ack_out : process (Cyc, Adr, 
                                PreMuxDatOut_ControlReg,
                                PreMuxAck_ControlReg,
                                PreMuxDatOut_StatusReg,
                                PreMuxAck_StatusReg,
                                PreMuxAck_Unoccupied
                                )
    begin 
        LoaderBlk_PreDatOut <= x"0000_0000"; -- default statements
        LoaderBlk_PreAck <= '0'; 
        LoaderBlk_Unoccupied_PreAck <= '0';
        if ( (Cyc(0) = '1') 
              and (unsigned(Adr) >= unsigned(WASMFPGALOADER_ADR_BLK_BASE_LoaderBlk) )
              and (unsigned(Adr) <= (unsigned(WASMFPGALOADER_ADR_BLK_BASE_LoaderBlk) + unsigned(WASMFPGALOADER_ADR_BLK_SIZE_LoaderBlk) - 1)) )
        then 
            if ( (unsigned(Adr)/4)*4  = ( unsigned(WASMFPGALOADER_ADR_ControlReg)) ) then
                 LoaderBlk_PreDatOut <= PreMuxDatOut_ControlReg;
                LoaderBlk_PreAck <= PreMuxAck_ControlReg;
            elsif ( (unsigned(Adr)/4)*4  = ( unsigned(WASMFPGALOADER_ADR_StatusReg)) ) then
                 LoaderBlk_PreDatOut <= PreMuxDatOut_StatusReg;
                LoaderBlk_PreAck <= PreMuxAck_StatusReg;
            else 
                LoaderBlk_PreAck <= PreMuxAck_Unoccupied;
                LoaderBlk_Unoccupied_PreAck <= PreMuxAck_Unoccupied;
            end if;
        end if;
    end process;


    -- ---------- block functions ---------- 


    -- .......... ControlReg, Width: 32, Type: Synchronous  .......... 

    ack_imdt_part_ControlReg0 : process (Adr, We, Stb, Cyc, PreMuxAck_ControlReg)
    begin 
        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADER_ADR_ControlReg) ) then 
            WriteDiff_ControlReg <=  We and Stb and Cyc(0) and not PreMuxAck_ControlReg;
        else
            WriteDiff_ControlReg <= '0';
        end if;

        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADER_ADR_ControlReg) ) then 
            ReadDiff_ControlReg <= not We and Stb and Cyc(0) and not PreMuxAck_ControlReg;
        else
            ReadDiff_ControlReg <= '0';
        end if;
    end process;

    reg_syn_clk_part_ControlReg0 : process (Clk, Rst)
    begin 
        if (Rst = '1') then 
            PreMuxAck_ControlReg <= '0';
            WReg_Run <= '0';
        elsif rising_edge(Clk) then
            PreMuxAck_ControlReg <= WriteDiff_ControlReg or ReadDiff_ControlReg; 
            if (WriteDiff_ControlReg = '1') then
                if (Sel(0) = '1') then WReg_Run <= DatIn(0); end if;
            else
            end if;
        end if;
    end process;

    mux_premuxdatout_ControlReg0 : process (
            WReg_Run
            )
    begin 
         PreMuxDatOut_ControlReg <= x"0000_0000";
         PreMuxDatOut_ControlReg(0) <= WReg_Run;
    end process;




    Run <= WReg_Run;

    -- .......... StatusReg, Width: 32, Type: Synchronous  .......... 

    ack_imdt_part_StatusReg0 : process (Adr, We, Stb, Cyc, PreMuxAck_StatusReg)
    begin 
        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADER_ADR_StatusReg) ) then 
            WriteDiff_StatusReg <=  We and Stb and Cyc(0) and not PreMuxAck_StatusReg;
        else
            WriteDiff_StatusReg <= '0';
        end if;

        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADER_ADR_StatusReg) ) then 
            ReadDiff_StatusReg <= not We and Stb and Cyc(0) and not PreMuxAck_StatusReg;
        else
            ReadDiff_StatusReg <= '0';
        end if;
    end process;

    reg_syn_clk_part_StatusReg0 : process (Clk, Rst)
    begin 
        if (Rst = '1') then 
            PreMuxAck_StatusReg <= '0';
        elsif rising_edge(Clk) then
            PreMuxAck_StatusReg <= WriteDiff_StatusReg or ReadDiff_StatusReg; 
        end if;
    end process;

    mux_premuxdatout_StatusReg0 : process (
            Loaded,
            Busy
            )
    begin 
         PreMuxDatOut_StatusReg <= x"0000_0000";
         PreMuxDatOut_StatusReg(1) <= Loaded;
         PreMuxDatOut_StatusReg(0) <= Busy;
    end process;






end architecture;




library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.WasmFpgaLoaderWshBn_Package.all;

-- ========== Wishbone for WasmFpgaLoader (WasmFpgaLoaderWishbone) ========== 

entity WasmFpgaLoaderWshBn is
    port (
        Clk : in std_logic;
        Rst : in std_logic;
        WasmFpgaLoaderWshBnDn : in T_WasmFpgaLoaderWshBnDn;
        WasmFpgaLoaderWshBnUp : out T_WasmFpgaLoaderWshBnUp;
        WasmFpgaLoaderWshBn_UnOccpdRcrd : out T_WasmFpgaLoaderWshBn_UnOccpdRcrd;
        WasmFpgaLoaderWshBn_LoaderBlk : out T_WasmFpgaLoaderWshBn_LoaderBlk;
        LoaderBlk_WasmFpgaLoaderWshBn : in T_LoaderBlk_WasmFpgaLoaderWshBn
     );
end WasmFpgaLoaderWshBn;



architecture arch_for_synthesys of WasmFpgaLoaderWshBn is

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
    end component; 


    -- ---------- internal wires ----------

    signal Sel : std_logic_vector(3 downto 0);
    signal LoaderBlk_DatOut : std_logic_vector(31 downto 0);
    signal LoaderBlk_Ack : std_logic;
    signal LoaderBlk_Unoccupied_Ack : std_logic;


begin 


    -- ---------- Connect register instances ----------

    i_LoaderBlk_WasmFpgaLoader :  LoaderBlk_WasmFpgaLoader
     port map (
        Clk => Clk,
        Rst => Rst,
        Adr => WasmFpgaLoaderWshBnDn.Adr,
        Sel => Sel,
        DatIn => WasmFpgaLoaderWshBnDn.DatIn,
        We =>  WasmFpgaLoaderWshBnDn.We,
        Stb => WasmFpgaLoaderWshBnDn.Stb,
        Cyc => WasmFpgaLoaderWshBnDn.Cyc,
        LoaderBlk_DatOut => LoaderBlk_DatOut,
        LoaderBlk_Ack => LoaderBlk_Ack,
        LoaderBlk_Unoccupied_Ack => LoaderBlk_Unoccupied_Ack,
        Run => WasmFpgaLoaderWshBn_LoaderBlk.Run,
        Loaded => LoaderBlk_WasmFpgaLoaderWshBn.Loaded,
        Busy => LoaderBlk_WasmFpgaLoaderWshBn.Busy
     );


    Sel <= WasmFpgaLoaderWshBnDn.Sel;                                                      

    WasmFpgaLoaderWshBn_UnOccpdRcrd.forRecord_Adr <= WasmFpgaLoaderWshBnDn.Adr;
    WasmFpgaLoaderWshBn_UnOccpdRcrd.forRecord_Sel <= Sel;
    WasmFpgaLoaderWshBn_UnOccpdRcrd.forRecord_We <= WasmFpgaLoaderWshBnDn.We;
    WasmFpgaLoaderWshBn_UnOccpdRcrd.forRecord_Cyc <= WasmFpgaLoaderWshBnDn.Cyc;

    -- ---------- Or all DataOuts and Acks of blocks ----------

     WasmFpgaLoaderWshBnUp.DatOut <= 
        LoaderBlk_DatOut;

     WasmFpgaLoaderWshBnUp.Ack <= 
        LoaderBlk_Ack;

     WasmFpgaLoaderWshBn_UnOccpdRcrd.Unoccupied_Ack <= 
        LoaderBlk_Unoccupied_Ack;





end architecture;



