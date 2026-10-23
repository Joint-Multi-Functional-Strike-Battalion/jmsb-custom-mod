class CfgWeapons {
    class ItemRadio;

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
