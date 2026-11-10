class CfgWeapons {
    class ItemRadio;
    class CBA_MiscItem;
    class CBA_MiscItem_ItemInfo;

    // THE SPARE BATTERY (user, 2026-10-30: "add a battery to the arsenal for
    // the MPU5"). A kit item: SWAP BATTERY on the RADIO app spends one and
    // puts a full battery in the handheld (jmfsb_voice_fnc_batterySwap); RF
    // runs the handheld down (jmfsb_rf_batteryHours). Into the TAC//PAC
    // arsenals with tools/pac_add_items.py itemsTools tools/mpu5_battery.json.
    // THE PICTURE IS THE MPU5'S, a placeholder until a battery icon is
    // supplied; the model is the game's small-item box.
    class jmfsb_mpu5_battery: CBA_MiscItem {
        author = QAUTHOR;
        MACRO_ITEM_COMMON
        displayName = "[JMSB] MPU5 Battery";
        descriptionShort = "Spare battery for the MPU5 - swapped from the RADIO app";
        picture = QPATHTOF(data\mpu5_icon_ca.paa);
        model = "\A3\Weapons_F\Ammo\mag_univ.p3d";
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 8;
        };
    };

    // THE HANDHELDS. Vanilla radio-slot items: in the slot they open VON's
    // radio channels, and RF reads the profile each names. No dialog - the
    // radio UI is the device's RADIO app (docs/DESIGN_VOICE.md).
    //
    // ON THE GROUND they wear ItemRadio's own model, inherited, so a dropped
    // set is always visible. The generated MPU5 / TW-950 meshes (data\*.p3d,
    // tools/gen_radios.py) are not worn until they have been looked at in game
    // (the MPU5 was reported invisible on the ground).

    // The MPU5: the rifleman's and leader's set.
    class jmfsb_mpu5: ItemRadio {
        author = QAUTHOR;
        MACRO_ITEM_COMMON
        displayName = "[JMSB] MPU5";
        descriptionShort = "MPU5 MANET handheld radio";
        picture = QPATHTOF(data\mpu5_icon_ca.paa);
        EGVAR(rf,profile) = "handheld";
    };

    // The TrellisWare TW-950 TSM Shadow: the second MANET handheld.
    class jmfsb_tw950: ItemRadio {
        author = QAUTHOR;
        MACRO_ITEM_COMMON
        displayName = "[JMSB] TW-950";
        descriptionShort = "TrellisWare TW-950 TSM Shadow MANET handheld radio";
        picture = QPATHTOF(data\tw950_icon_ca.paa);
        EGVAR(rf,profile) = "legacy";
    };
};
