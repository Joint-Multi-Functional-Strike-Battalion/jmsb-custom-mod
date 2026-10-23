// THE EW RECEIVER: the "dedicated" DF set of DESIGN_EW (bearing error 2 deg,
// every band) and an anti-spoof GPS. A CBA misc item, so it goes in a uniform,
// vest or backpack, or in a vehicle's cargo for the crew.
class CfgWeapons {
    class CBA_MiscItem;
    class CBA_MiscItem_ItemInfo;

    class GVAR(receiver): CBA_MiscItem {
        scope = 2;
        scopeArsenal = 2;
        scopeCurator = 2;
        displayName = "EW Receiver (DF)";
        author = QAUTHOR;
        descriptionShort = "Wideband intercept and direction-finding receiver. Best DF bearing, hears every band, and its GPS shows SUSPECT instead of following a spoofer.";
        model = "\a3\Props_F_Enoch\Military\Equipment\BatteryPack_01_Closed_F.p3d";
        editorCategory = "EdCat_Equipment";
        editorSubcategory = "EdSubcat_InventoryItems";

        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 20;
        };
    };
};
