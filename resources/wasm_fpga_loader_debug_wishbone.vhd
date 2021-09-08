

-- ========== WebAssembly Engine Block( EngineBlk) ========== 

-- This block describes the WebAssembly engine block.
-- BUS: 


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.WasmFpgaLoaderDebugWshBn_Package.all;

entity EngineBlk_WasmFpgaLoaderDebug is
    port (
        Clk : in std_logic;
        Rst : in std_logic;
        Adr : in std_logic_vector(23 downto 0);
        Sel : in std_logic_vector(3 downto 0);
        DatIn : in std_logic_vector(31 downto 0);
        We : in std_logic;
        Stb : in std_logic;
        Cyc : in  std_logic_vector(0 downto 0);
        EngineBlk_DatOut : out std_logic_vector(31 downto 0);
        EngineBlk_Ack : out std_logic;
        EngineBlk_Unoccupied_Ack : out std_logic;
        Loaded : in std_logic;
        Running : in std_logic;
        Address : in std_logic_vector(23 downto 0);
        Error : in std_logic_vector(7 downto 0)
     );
end EngineBlk_WasmFpgaLoaderDebug;



architecture arch_for_synthesys of EngineBlk_WasmFpgaLoaderDebug is

    -- ---------- block variables ---------- 
    signal PreMuxAck_Unoccupied : std_logic;
    signal UnoccupiedDec : std_logic_vector(1 downto 0);
    signal EngineBlk_PreDatOut : std_logic_vector(31 downto 0);
    signal EngineBlk_PreAck : std_logic;
    signal EngineBlk_Unoccupied_PreAck : std_logic;
    signal PreMuxDatOut_StatusReg : std_logic_vector(31 downto 0);
    signal PreMuxAck_StatusReg : std_logic;
    signal PreMuxDatOut_AddressReg : std_logic_vector(31 downto 0);
    signal PreMuxAck_AddressReg : std_logic;
    signal PreMuxDatOut_ErrorReg : std_logic_vector(31 downto 0);
    signal PreMuxAck_ErrorReg : std_logic;

    signal WriteDiff_StatusReg : std_logic;
    signal ReadDiff_StatusReg : std_logic;


    signal WriteDiff_AddressReg : std_logic;
    signal ReadDiff_AddressReg : std_logic;


    signal WriteDiff_ErrorReg : std_logic;
    signal ReadDiff_ErrorReg : std_logic;



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

    EngineBlk_DatOut <= EngineBlk_PreDatOut;
    EngineBlk_Ack <=  EngineBlk_PreAck;
    EngineBlk_Unoccupied_Ack <= EngineBlk_Unoccupied_PreAck;

    mux_data_ack_out : process (Cyc, Adr, 
                                PreMuxDatOut_StatusReg,
                                PreMuxAck_StatusReg,
                                PreMuxDatOut_AddressReg,
                                PreMuxAck_AddressReg,
                                PreMuxDatOut_ErrorReg,
                                PreMuxAck_ErrorReg,
                                PreMuxAck_Unoccupied
                                )
    begin 
        EngineBlk_PreDatOut <= x"0000_0000"; -- default statements
        EngineBlk_PreAck <= '0'; 
        EngineBlk_Unoccupied_PreAck <= '0';
        if ( (Cyc(0) = '1') 
              and (unsigned(Adr) >= unsigned(WASMFPGALOADERDEBUG_ADR_BLK_BASE_EngineBlk) )
              and (unsigned(Adr) <= (unsigned(WASMFPGALOADERDEBUG_ADR_BLK_BASE_EngineBlk) + unsigned(WASMFPGALOADERDEBUG_ADR_BLK_SIZE_EngineBlk) - 1)) )
        then 
            if ( (unsigned(Adr)/4)*4  = ( unsigned(WASMFPGALOADERDEBUG_ADR_StatusReg)) ) then
                 EngineBlk_PreDatOut <= PreMuxDatOut_StatusReg;
                EngineBlk_PreAck <= PreMuxAck_StatusReg;
            elsif ( (unsigned(Adr)/4)*4  = ( unsigned(WASMFPGALOADERDEBUG_ADR_AddressReg)) ) then
                 EngineBlk_PreDatOut <= PreMuxDatOut_AddressReg;
                EngineBlk_PreAck <= PreMuxAck_AddressReg;
            elsif ( (unsigned(Adr)/4)*4  = ( unsigned(WASMFPGALOADERDEBUG_ADR_ErrorReg)) ) then
                 EngineBlk_PreDatOut <= PreMuxDatOut_ErrorReg;
                EngineBlk_PreAck <= PreMuxAck_ErrorReg;
            else 
                EngineBlk_PreAck <= PreMuxAck_Unoccupied;
                EngineBlk_Unoccupied_PreAck <= PreMuxAck_Unoccupied;
            end if;
        end if;
    end process;


    -- ---------- block functions ---------- 


    -- .......... StatusReg, Width: 32, Type: Synchronous  .......... 

    ack_imdt_part_StatusReg0 : process (Adr, We, Stb, Cyc, PreMuxAck_StatusReg)
    begin 
        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADERDEBUG_ADR_StatusReg) ) then 
            WriteDiff_StatusReg <=  We and Stb and Cyc(0) and not PreMuxAck_StatusReg;
        else
            WriteDiff_StatusReg <= '0';
        end if;

        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADERDEBUG_ADR_StatusReg) ) then 
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
            Running
            )
    begin 
         PreMuxDatOut_StatusReg <= x"0000_0000";
         PreMuxDatOut_StatusReg(1) <= Loaded;
         PreMuxDatOut_StatusReg(0) <= Running;
    end process;





    -- .......... AddressReg, Width: 32, Type: Synchronous  .......... 

    ack_imdt_part_AddressReg0 : process (Adr, We, Stb, Cyc, PreMuxAck_AddressReg)
    begin 
        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADERDEBUG_ADR_AddressReg) ) then 
            WriteDiff_AddressReg <=  We and Stb and Cyc(0) and not PreMuxAck_AddressReg;
        else
            WriteDiff_AddressReg <= '0';
        end if;

        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADERDEBUG_ADR_AddressReg) ) then 
            ReadDiff_AddressReg <= not We and Stb and Cyc(0) and not PreMuxAck_AddressReg;
        else
            ReadDiff_AddressReg <= '0';
        end if;
    end process;

    reg_syn_clk_part_AddressReg0 : process (Clk, Rst)
    begin 
        if (Rst = '1') then 
            PreMuxAck_AddressReg <= '0';
        elsif rising_edge(Clk) then
            PreMuxAck_AddressReg <= WriteDiff_AddressReg or ReadDiff_AddressReg; 
        end if;
    end process;

    mux_premuxdatout_AddressReg0 : process (
            Address
            )
    begin 
         PreMuxDatOut_AddressReg <= x"0000_0000";
         PreMuxDatOut_AddressReg(23 downto 0) <= Address;
    end process;





    -- .......... ErrorReg, Width: 32, Type: Synchronous  .......... 

    ack_imdt_part_ErrorReg0 : process (Adr, We, Stb, Cyc, PreMuxAck_ErrorReg)
    begin 
        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADERDEBUG_ADR_ErrorReg) ) then 
            WriteDiff_ErrorReg <=  We and Stb and Cyc(0) and not PreMuxAck_ErrorReg;
        else
            WriteDiff_ErrorReg <= '0';
        end if;

        if ( (unsigned(Adr)/4)*4 = unsigned(WASMFPGALOADERDEBUG_ADR_ErrorReg) ) then 
            ReadDiff_ErrorReg <= not We and Stb and Cyc(0) and not PreMuxAck_ErrorReg;
        else
            ReadDiff_ErrorReg <= '0';
        end if;
    end process;

    reg_syn_clk_part_ErrorReg0 : process (Clk, Rst)
    begin 
        if (Rst = '1') then 
            PreMuxAck_ErrorReg <= '0';
        elsif rising_edge(Clk) then
            PreMuxAck_ErrorReg <= WriteDiff_ErrorReg or ReadDiff_ErrorReg; 
        end if;
    end process;

    mux_premuxdatout_ErrorReg0 : process (
            Error
            )
    begin 
         PreMuxDatOut_ErrorReg <= x"0000_0000";
         PreMuxDatOut_ErrorReg(7 downto 0) <= Error;
    end process;






end architecture;




library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.WasmFpgaLoaderDebugWshBn_Package.all;

-- ========== Wishbone for WasmFpgaLoaderDebug (WasmFpgaLoaderDebugWishbone) ========== 

entity WasmFpgaLoaderDebugWshBn is
    port (
        Clk : in std_logic;
        Rst : in std_logic;
        WasmFpgaLoaderDebugWshBnDn : in T_WasmFpgaLoaderDebugWshBnDn;
        WasmFpgaLoaderDebugWshBnUp : out T_WasmFpgaLoaderDebugWshBnUp;
        WasmFpgaLoaderDebugWshBn_UnOccpdRcrd : out T_WasmFpgaLoaderDebugWshBn_UnOccpdRcrd;
        EngineBlk_WasmFpgaLoaderDebugWshBn : in T_EngineBlk_WasmFpgaLoaderDebugWshBn
     );
end WasmFpgaLoaderDebugWshBn;



architecture arch_for_synthesys of WasmFpgaLoaderDebugWshBn is

    component EngineBlk_WasmFpgaLoaderDebug is
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            Adr : in std_logic_vector(23 downto 0);
            Sel : in std_logic_vector(3 downto 0);
            DatIn : in std_logic_vector(31 downto 0);
            We : in std_logic;
            Stb : in std_logic;
            Cyc : in  std_logic_vector(0 downto 0);
            EngineBlk_DatOut : out std_logic_vector(31 downto 0);
            EngineBlk_Ack : out std_logic;
            EngineBlk_Unoccupied_Ack : out std_logic;
            Loaded : in std_logic;
            Running : in std_logic;
            Address : in std_logic_vector(23 downto 0);
            Error : in std_logic_vector(7 downto 0)
         );
    end component; 


    -- ---------- internal wires ----------

    signal Sel : std_logic_vector(3 downto 0);
    signal EngineBlk_DatOut : std_logic_vector(31 downto 0);
    signal EngineBlk_Ack : std_logic;
    signal EngineBlk_Unoccupied_Ack : std_logic;


begin 


    -- ---------- Connect register instances ----------

    i_EngineBlk_WasmFpgaLoaderDebug :  EngineBlk_WasmFpgaLoaderDebug
     port map (
        Clk => Clk,
        Rst => Rst,
        Adr => WasmFpgaLoaderDebugWshBnDn.Adr,
        Sel => Sel,
        DatIn => WasmFpgaLoaderDebugWshBnDn.DatIn,
        We =>  WasmFpgaLoaderDebugWshBnDn.We,
        Stb => WasmFpgaLoaderDebugWshBnDn.Stb,
        Cyc => WasmFpgaLoaderDebugWshBnDn.Cyc,
        EngineBlk_DatOut => EngineBlk_DatOut,
        EngineBlk_Ack => EngineBlk_Ack,
        EngineBlk_Unoccupied_Ack => EngineBlk_Unoccupied_Ack,
        Loaded => EngineBlk_WasmFpgaLoaderDebugWshBn.Loaded,
        Running => EngineBlk_WasmFpgaLoaderDebugWshBn.Running,
        Address => EngineBlk_WasmFpgaLoaderDebugWshBn.Address,
        Error => EngineBlk_WasmFpgaLoaderDebugWshBn.Error
     );


    Sel <= WasmFpgaLoaderDebugWshBnDn.Sel;                                                      

    WasmFpgaLoaderDebugWshBn_UnOccpdRcrd.forRecord_Adr <= WasmFpgaLoaderDebugWshBnDn.Adr;
    WasmFpgaLoaderDebugWshBn_UnOccpdRcrd.forRecord_Sel <= Sel;
    WasmFpgaLoaderDebugWshBn_UnOccpdRcrd.forRecord_We <= WasmFpgaLoaderDebugWshBnDn.We;
    WasmFpgaLoaderDebugWshBn_UnOccpdRcrd.forRecord_Cyc <= WasmFpgaLoaderDebugWshBnDn.Cyc;

    -- ---------- Or all DataOuts and Acks of blocks ----------

     WasmFpgaLoaderDebugWshBnUp.DatOut <= 
        EngineBlk_DatOut;

     WasmFpgaLoaderDebugWshBnUp.Ack <= 
        EngineBlk_Ack;

     WasmFpgaLoaderDebugWshBn_UnOccpdRcrd.Unoccupied_Ack <= 
        EngineBlk_Unoccupied_Ack;





end architecture;



