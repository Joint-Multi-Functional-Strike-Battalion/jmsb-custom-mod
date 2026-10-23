class CfgVehicles {
    class Item_Base_F;
    class EGVAR(backpack,B_RadioBag_01_Multicam);

    // THE RADIO ON THE GROUND, as an editor and Zeus placeable: an item holder
    // carrying one set. A radio a player drops uses the item's own (vanilla)
    // model without this class; this is for the mission maker who wants one
    // lying on a table.
    class Item_jmfsb_mpu5: Item_Base_F {
        author = QAUTHOR;
        scope = 2;
        scopeCurator = 2;
        displayName = "[JMSB] MPU5";
        vehicleClass = "Items";
        class TransportItems {
            class _xx_jmfsb_mpu5 {
                name = "jmfsb_mpu5";
                count = 1;
            };
        };
    };

    class Item_jmfsb_tw950: Item_Base_F {
        author = QAUTHOR;
        scope = 2;
        scopeCurator = 2;
        displayName = "[JMSB] TW-950";
        vehicleClass = "Items";
        class TransportItems {
            class _xx_jmfsb_tw950 {
                name = "jmfsb_tw950";
                count = 1;
            };
        };
    };

    // THE MPU5 MANPACK: the long range set on the back, for SL / PL / RTO /
    // JTAC - under TFAR (a TFAR long range set through jmfsb_backpack's radio
    // bag base, compatibility/tfar_radios) and ACRE. Under game voice it is a
    // bag and nothing more: no man packs there (user, 2026-10-21), and
    // jmfsb_rf_fnc_carriedSets reads nothing off the back.
    class jmfsb_mpu5_lr: EGVAR(backpack,B_RadioBag_01_Multicam) {
        author = QAUTHOR;
        scope = 2;
        scopeCurator = 2;
        scopeArsenal = 2;
        displayName = "[JMSB] MPU5 Manpack";
        EGVAR(rf,profile) = "manpack";
    };
};
