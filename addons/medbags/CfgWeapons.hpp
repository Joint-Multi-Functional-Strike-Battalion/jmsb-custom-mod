class CfgWeapons {

    class CBA_MiscItem;
    class CBA_MiscItem_ItemInfo;
    class ACE_ItemCore: CBA_MiscItem {};

    // MEDICAL SUPPLIES

    class GVAR(FirstAid): ACE_ItemCore {
        scope = 2;
        author = QAUTHOR;
        ACE_isMedicalItem = 1;
        displayName = "Boo Boo Bag";
        descriptionShort = "Contains material for first aid";
        editorPreview = QPATHTOF(data\previews\firstaid.jpg);
        picture = QPATHTOF(data\ui\firstaid_ca.paa);
        model = "\a3\weapons_f\ammo\mag_firstaidkit.p3d";
        icon = "iconObject_1x1";
        mapSize = 0.015;
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 10;
        };
    };

    class GVAR(MedicKit): ACE_ItemCore {
        scope = 2;
        author = QAUTHOR;
        ACE_isMedicalItem = 1;
        displayName = "Medic Bag";
        descriptionShort = "Contains materials to resupply medics";
        editorPreview = QPATHTOF(data\previews\medickit.jpg);
        picture = QPATHTOF(data\ui\medickit_ca.paa);
        model = "\a3\props_f_orange\humanitarian\camps\firstaidkit_01_closed_f.p3d";
        icon = "iconObject_1x1";
        mapSize = 0.015;
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 24;
        };
    };

    class GVAR(Trauma): ACE_ItemCore {
        scope = 2;
        author = QAUTHOR;
        ACE_isMedicalItem = 1;
        displayName = "Trauma Kit";
        descriptionShort = "Contains materials for medics";
        editorPreview = QPATHTOF(data\previews\medickit.jpg);
        picture = QPATHTOF(data\ui\medickit_ca.paa);
        model = "\a3\props_f_orange\humanitarian\camps\firstaidkit_01_closed_f.p3d";
        icon = "iconObject_1x1";
        mapSize = 0.015;
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 50;
        };
    };

        class GVAR(Fluid): ACE_ItemCore {
        scope = 2;
        author = QAUTHOR;
        ACE_isMedicalItem = 1;
        displayName = "Fluid Kit";
        descriptionShort = "Box of Water";
        editorPreview = QPATHTOF(data\previews\medickit.jpg);
        picture = QPATHTOF(data\ui\medickit_ca.paa);
        model = "\a3\props_f_orange\humanitarian\camps\firstaidkit_01_closed_f.p3d";
        icon = "iconObject_1x1";
        mapSize = 0.015;
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 35;
        };
    };

    class GVAR(DrugKit): ACE_ItemCore {
        scope = 2;
        author = QAUTHOR;
        displayName = "Drug Kit";
        ACE_isMedicalItem = 1;
        descriptionShort = "Contains DURGS!";
        editorPreview = QPATHTOF(data\previews\booboo_ca.paa);
        picture = QPATHTOF(data\previews\booboo_ca.paa);
        model = "\a3\props_f_orange\humanitarian\camps\firstaidkit_01_closed_f.p3d";
        icon = "iconObject_1x1";
        mapSize = 0.015;
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 12;
        };
    };
    // MOPP BAGS (user, 2026-10-10: "3 mopp bags based on camo and acm cbrn self
    // drugs"). One per CBRN suit camo; unpacking gives that suit (GVAR(suit))
    // plus the shared GVAR(contentsMopp) list - respirator and the ACM CBRN
    // self-aid autoinjectors. One self-action unpacks whichever bag is carried.
    class GVAR(Mopp_MTP): ACE_ItemCore {
        scope = 2;
        author = QAUTHOR;
        displayName = "MOPP Bag (MTP)";
        descriptionShort = "CBRN suit (MTP), respirator and CBRN autoinjectors";
        editorPreview = QPATHTOF(data\previews\booboo_ca.paa);
        picture = QPATHTOF(data\previews\booboo_ca.paa);
        model = "\a3\props_f_orange\humanitarian\camps\firstaidkit_01_closed_f.p3d";
        icon = "iconObject_1x1";
        mapSize = 0.015;
        GVAR(suit) = "U_B_CBRN_Suit_01_MTP_F";
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 60;
        };
    };
    class GVAR(Mopp_Tropic): GVAR(Mopp_MTP) {
        displayName = "MOPP Bag (Tropic)";
        descriptionShort = "CBRN suit (Tropic), respirator and CBRN autoinjectors";
        GVAR(suit) = "U_B_CBRN_Suit_01_Tropic_F";
    };
    class GVAR(Mopp_Wdl): GVAR(Mopp_MTP) {
        displayName = "MOPP Bag (Woodland)";
        descriptionShort = "CBRN suit (Woodland), respirator and CBRN autoinjectors";
        GVAR(suit) = "U_B_CBRN_Suit_01_Wdl_F";
    };
};
