// TAC//SUPPORT AS A DIALOG - the host ALiVE's own tablet uses, and the one a
// real map control actually works in. Embedded in a drawn panel on the map
// display, the map control bled past its frame and fed its drags to the big
// map underneath; in a dialog it clips, pans itself only, and CLOSE is a
// closeDisplay nothing can sit on top of.
//
// THE VANILLA MAP ONLY. On the tablet the board does not open this dialog -
// it draws inside the device's app area and picks on its own map
// (FUNC(appSupport)).
//
// The map's numbers below are where it starts; FUNC(appSupport) lays it into
// the board's map hole every draw (the hole's top moved down under the tab
// row, which is sized off the text). The board's own geometry is
// SUP_FRAME_NATIVE / SUP_MAP_L_K / SUP_MAP_B_K in script_component.hpp.

// RscText IS FORWARD-DECLARED, and jmfsb's copy of this file does not do it.
// `class Backdrop: RscText` fails L-C04 "class's parent is not present"
// otherwise - it happens to resolve in jmfsb's include order and does not here.
// Worth carrying back to jmfsb either way: an inherited class you do not
// declare is a build that depends on somebody else's include order.
class RscText;
class RscMapControl;

class GVAR(supportDlg) {
    idd = 8960;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(supportDlg),_this select 0)]);
    onUnload = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(supportDlg),displayNull)]);

    class controlsBackground {
        class Backdrop: RscText {
            idc = -1;
            x = "safezoneXAbs";
            y = "safezoneY";
            w = "safezoneWAbs";
            h = "safezoneH";
            colorBackground[] = {0, 0, 0, 0.45};
        };
    };

    class controls {
        // The right column IS the map. Config-declared so the engine hosts
        // it properly; FUNC(appSupport) hangs the click and draw handlers on
        // it at open.
        class SupportMap: RscMapControl {
            idc = 8961;
            x = "safezoneX + 0.545 * safezoneW";
            y = "safezoneY + 0.20 * safezoneH";
            w = "0.285 * safezoneW";
            h = "0.52 * safezoneH";
        };
    };
};
