// THE TABLET. One dialog that is a backdrop, a map and a frame, and nothing
// else: everything on the screen is the tacpad suite, created at runtime by
// jmfsb_tacpad against this display exactly as it is created against the
// vanilla map - the dialog is handed over as the host (see
// tacpad/shared.inc.hpp) and the shell draws into the screen rectangle.
//
// NO GEOMETRY HERE. The frame is a square texture with the device somewhere
// inside it and the screen a rectangle inside that, and none of it can be
// written against a monitor whose aspect is not known until the dialog opens.
// FUNC(layout) sizes and places both controls at open, from CfgJmfsbDevices.

class RscText;
class RscPicture;
class RscMapControl;
class RscButton;

// A key printed on the frame, as a button: nothing drawn, the art shows
// through, only the click and the tooltip are its. FUNC(keyButtons).
class GVAR(keyButton): RscButton {
    idc = -1;
    text = "";
    x = 0;
    y = 0;
    w = 0;
    h = 0;
    colorText[] = {0, 0, 0, 0};
    colorDisabled[] = {0, 0, 0, 0};
    colorBackground[] = {0, 0, 0, 0};
    colorBackgroundDisabled[] = {0, 0, 0, 0};
    colorBackgroundActive[] = {1, 1, 1, 0.12};
    colorFocused[] = {0, 0, 0, 0};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0, 0, 0};
};

class GVAR(tablet) {
    idd = IDD_TABLET;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = QUOTE([_this select 0] call FUNC(onLoad));
    onUnload = QUOTE([_this select 0] call FUNC(onUnload));

    class controlsBackground {
        // Dims the world, so the device reads as the thing in your hands and
        // not as a window over the game.
        class Backdrop: RscText {
            idc = IDC_TABLET_BACKDROP;
            x = "safezoneXAbs";
            y = "safezoneY";
            w = "safezoneWAbs";
            h = "safezoneH";
            colorBackground[] = {0, 0, 0, 0.6};
        };

        // THE SCREEN IS THE MAP, IN THE BACKGROUND LAYER - as CA_Map is on the
        // vanilla map display. In the foreground it was drawn over everything:
        // over the frame, so its square corners stuck out past the rounded
        // bezel, and over every panel the suite built, which is why the first
        // tablets showed a map and no UI (RPT 2026-10-19: eight panels built,
        // shown, on screen, and invisible).
        // Declared, not ctrlCreate'd: the engine hosts
        // a map control properly only when it is part of the display's own
        // definition - jmfsb_tacpad_apps' support dialog learned that the hard
        // way. It is sized to the screen rectangle at open, so the bezel is
        // never under it.
        class Map: RscMapControl {
            idc = IDC_TABLET_MAP;
            x = 0;
            y = 0;
            w = 0;
            h = 0;
        };
    };

    class controls {
        // THE FRAME, OVER THE MAP, so the bezel covers the map's square corners
        // where the screen's are rounded. Its screen area and everything
        // outside the device are transparent - the texture is cut that way by
        // the generator - and a static picture takes no click, so the map and
        // the panels under it are untouched by it.
        class Frame: RscPicture {
            idc = IDC_TABLET_FRAME;
            text = "";
            x = 0;
            y = 0;
            w = 0;
            h = 0;
        };
    };
};
