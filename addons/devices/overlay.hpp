// THE WALKING VIEW. The phone and the two side devices are one title layer:
// a ground the colour of the scheme, the status cells, a map with the squad
// list, the talking chip and the call strip over it, a row of net cells and
// the frame over the lot. No status row and no notification line (user,
// 2026-10-21). Nothing here has a position -
// FUNC(overlayPlace) lays every control out from CfgJmfsbDevices at runtime,
// the way FUNC(layout) does for the tablet, because a square texture cannot
// be placed on a monitor whose aspect is not known until it is up.
//
// A TITLE LAYER, NOT A DIALOG (user, 2026-10-19): the walking view is read
// only and takes no input. The map control is declared here rather than
// ctrlCreate'd because the engine hosts a map properly only when it is part
// of the display's own definition - see dialog.hpp.
//
// RscText, RscPicture and RscMapControl are already declared by dialog.hpp,
// which config.cpp includes before this file.

class RscStructuredText;

// A net cell: the outline (a coloured block), the label inset over it so the
// block shows round it as the outline, and the receive-only R. Square, no
// rounded corners (user, 2026-10-19).
#define OVERLAY_NET_CELL(N) \
    class DOUBLES(netEdge,N): RscText { \
        idc = IDC_OVERLAY_NETEDGE(N); \
        text = ""; \
        colorBackground[] = {0, 0, 0, 0}; \
        x = 0; y = 0; w = 0; h = 0; \
    }; \
    class DOUBLES(net,N): RscText { \
        idc = IDC_OVERLAY_NET(N); \
        style = ST_CENTER; \
        font = "RobotoCondensedBold"; \
        text = ""; \
        colorBackground[] = {0, 0, 0, 0}; \
        x = 0; y = 0; w = 0; h = 0; \
    }; \
    class DOUBLES(netRx,N): RscText { \
        idc = IDC_OVERLAY_NETRX(N); \
        font = "RobotoCondensed"; \
        text = "R"; \
        colorBackground[] = {0, 0, 0, 0}; \
        x = 0; y = 0; w = 0; h = 0; \
    }

// A status cell: icon word and value, one line, centred; red ground when it
// alerts - the old top bar (user, 2026-10-21).
#define OVERLAY_STATUS_CELL(N) \
    class DOUBLES(cell,N): RscText { \
        idc = IDC_OVERLAY_CELL(N); \
        style = ST_CENTER; \
        font = "RobotoCondensedBold"; \
        text = ""; \
        colorBackground[] = {0, 0, 0, 0}; \
        x = 0; y = 0; w = 0; h = 0; \
    }

#define OVERLAY_TEXT(NAME,IDC,FONT) \
    class NAME: RscStructuredText { \
        idc = IDC; \
        x = 0; y = 0; w = 0; h = 0; \
        colorBackground[] = {0, 0, 0, 0}; \
        class Attributes { \
            font = FONT; \
            color = "#FFFFFF"; \
            align = "left"; \
            shadow = 0; \
        }; \
    }

class RscTitles {
    class GVAR(overlay) {
        idd = IDD_OVERLAY;
        movingEnable = 0;
        fadeIn = 0;
        fadeOut = 0;
        duration = "1e+011";
        onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(overlayDisplay),_this select 0)]);
        class controls {
            // Creation order is paint order: ground, the map, what sits on
            // the map, the rows, and the frame whose transparent screen lets
            // it all through.
            class Ground: RscText {
                idc = IDC_OVERLAY_GROUND;
                text = "";
                colorBackground[] = {0, 0, 0, 1};
                x = 0; y = 0; w = 0; h = 0;
            };
            class Map: RscMapControl {
                idc = IDC_OVERLAY_MAP;
                x = 0; y = 0; w = 0; h = 0;
            };
            OVERLAY_TEXT(Squad,IDC_OVERLAY_SQUAD,"RobotoCondensed");
            OVERLAY_TEXT(Squad2,IDC_OVERLAY_SQUAD2,"RobotoCondensed");
            OVERLAY_TEXT(Talk,IDC_OVERLAY_TALK,"RobotoCondensedBold");
            OVERLAY_TEXT(Call,IDC_OVERLAY_CALL,"RobotoCondensed");
            OVERLAY_STATUS_CELL(0);
            OVERLAY_STATUS_CELL(1);
            OVERLAY_STATUS_CELL(2);
            OVERLAY_STATUS_CELL(3);
            OVERLAY_STATUS_CELL(4);
            OVERLAY_STATUS_CELL(5);
            OVERLAY_NET_CELL(0);
            OVERLAY_NET_CELL(1);
            OVERLAY_NET_CELL(2);
            OVERLAY_NET_CELL(3);
            OVERLAY_NET_CELL(4);
            OVERLAY_NET_CELL(5);
            OVERLAY_NET_CELL(6);
            OVERLAY_NET_CELL(7);
            class Frame: RscPicture {
                idc = IDC_OVERLAY_FRAME;
                text = "";
                x = 0; y = 0; w = 0; h = 0;
            };
        };
    };
};
