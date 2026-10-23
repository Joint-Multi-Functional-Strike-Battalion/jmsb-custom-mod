// THE DEVICES AS ITEMS. Each is the vanilla GPS with a different name: it
// goes in the GPS slot, replaces the vanilla GPS there, and keeps the engine's
// own GPS behaviour (the mini-map stays available). The walking view shows
// only while one of these is assigned - see FUNC(overlayDevice) - and a
// player carries ONE of the three.
//
// THE PICTURE is the device with a lit screen (tools/gen_device_icons.py), not
// the frame texture, whose screen is a transparent hole and read as an empty
// dark rectangle in the arsenal (user, 2026-10-21).
//
// On the ground they wear the vanilla UAV terminal's model (user, 2026-10-19):
// the frames are screen textures, not objects.

class CfgWeapons {
    class ItemGPS;

    class GVAR(phone): ItemGPS {
        author = QAUTHOR;
        MACRO_ITEM_COMMON
        displayName = "[JMSB] Phone";
        descriptionShort = "Phone. A GPS with the unit's walking view on it: status, traffic, map and nets, bottom centre of the screen.";
        picture = QPATHTOF(data\phone_icon_ca.paa);
        model = "\A3\Drones_F\Weapons_F_Gamma\Items\UAV_controller_F.p3d";
    };

    class GVAR(side): ItemGPS {
        author = QAUTHOR;
        MACRO_ITEM_COMMON
        displayName = "[JMSB] Side Device";
        descriptionShort = "Side device. A GPS with the unit's walking view on it, against the left or right edge of the screen - your choice when you bring it up.";
        picture = QPATHTOF(data\side_icon_ca.paa);
        model = "\A3\Drones_F\Weapons_F_Gamma\Items\UAV_controller_F.p3d";
    };

    class GVAR(side2): ItemGPS {
        author = QAUTHOR;
        MACRO_ITEM_COMMON
        displayName = "[JMSB] Side Device 2";
        descriptionShort = "Side device, second pattern. A GPS with the unit's walking view on it, against the left or right edge of the screen.";
        picture = QPATHTOF(data\side2_icon_ca.paa);
        model = "\A3\Drones_F\Weapons_F_Gamma\Items\UAV_controller_F.p3d";
    };
};
