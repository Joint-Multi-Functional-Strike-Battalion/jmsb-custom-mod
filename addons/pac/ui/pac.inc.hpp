// TAC//PAC - THE ONE DIALOG (2026-09-09).
//
// The website is one shell - a bar across the top with the pages on it, the
// page you are on drawn under it - and this is that shell in game. One
// display, one set of controls, and every page (FUNC(pgDashboard),
// FUNC(pgRoster), ...) redraws them: it hides what it does not use, places
// what it does, fills it, and names the buttons along the foot.
//
// It replaced three dialogs (the personnel panel, EDIT STRUCTURE, MANAGE)
// that each had their own layout, their own lists and their own idea of where
// a button goes, none of which was the website's (user, 2026-09-09: "a few
// buttons that go to pages they look like the old ones that do not match the
// experience i keep asking for so start over ... make it look as much like
// the web as possible").
//
// THE COLOURS ARE THE UNIT'S (rebrand 2026-10-08, the G logo: ranger green
// and tan): dark green ground, ranger-green panel, paper ink, sage for the
// secondary text, tan for the accent and links, red for danger - the same
// tokens jmsb.info and pac.jmsb.info paint with.
// The typeface is the suite's (RobotoCondensed) because that is what the
// game has; everything else is the stylesheet's.

#define PAC_C_GROUND   {0.125, 0.149, 0.110, 1}   // #20261C
#define PAC_C_WELL     {0.082, 0.098, 0.071, 1}   // #151912
#define PAC_C_PANEL    {0.227, 0.267, 0.200, 1}   // #3A4433
#define PAC_C_RAISE    {0.290, 0.329, 0.263, 1}   // #4A5443
#define PAC_C_LINE     {0.353, 0.396, 0.322, 1}   // #5A6552
#define PAC_C_INK      {0.914, 0.894, 0.831, 1}   // #E9E4D3
#define PAC_C_DIM      {0.663, 0.682, 0.584, 1}   // #A9AE95
#define PAC_C_FAINT    {0.420, 0.447, 0.376, 1}   // #6B7260
#define PAC_C_ACCENT   {0.761, 0.659, 0.471, 1}   // #C2A878
#define PAC_C_ACCENT_DIM {0.761, 0.659, 0.471, 0.13}
#define PAC_C_HOT      {0.894, 0.341, 0.290, 1}
#define PAC_C_NONE     {0, 0, 0, 0}

// TEXT SIZES ARE WRITTEN OUT. They were a macro, PAC_SZ(f) = "f * (0.025 *
// safezoneH)" - and a macro parameter is NOT substituted inside a quoted
// string, so every control had sizeEx = "f * ..." = 0 and the whole dialog
// drew without a letter on it (seen in game 2026-09-10: "this is not a PAC").

// ---- the control family -----------------------------------------------------

class PacText: RscADMPText {
    colorText[] = PAC_C_INK;
    sizeEx = "0.8 * (0.025 * safezoneH)";
};

// A label: the website's <label> and <th> - small, grey, uppercase where the
// page says so.
class PacLabel: PacText {
    colorText[] = PAC_C_DIM;
    sizeEx = "0.72 * (0.025 * safezoneH)";
};

class PacFill: RscADMPText {
    text = "";
    colorBackground[] = PAC_C_PANEL;
};

class PacRich: RscADMPStructuredText {
    size = "0.8 * (0.025 * safezoneH)";
    class Attributes {
        font = "RobotoCondensed";
        color = "#E3E9EF";
        align = "left";
        shadow = 0;
    };
};

// The website's button: accent-filled, dark text, uppercase.
class PacButton: RscADMPButton {
    sizeEx = "0.72 * (0.025 * safezoneH)";
    colorText[] = PAC_C_GROUND;
    colorActive[] = PAC_C_GROUND;
    colorBackground[] = PAC_C_ACCENT;
    colorBackgroundActive[] = {0.850, 0.760, 0.580, 1};
    colorBackgroundDisabled[] = PAC_C_LINE;
    colorDisabled[] = PAC_C_FAINT;
    colorFocused[] = PAC_C_ACCENT;
    onButtonClick = QUOTE([_this select 0] call FUNC(uiClick));
};

// A nav link: grey text on the bar, white under the pointer, accent (with the
// underline control moved beneath it) for the page you are on.
class PacNav: RscADMPButton {
    sizeEx = "0.68 * (0.025 * safezoneH)";
    colorText[] = PAC_C_DIM;
    colorActive[] = PAC_C_INK;
    colorBackground[] = PAC_C_NONE;
    colorBackgroundActive[] = PAC_C_NONE;
    colorFocused[] = PAC_C_NONE;
    colorBackgroundDisabled[] = PAC_C_NONE;
    colorDisabled[] = PAC_C_FAINT;
    onButtonClick = QUOTE([_this select 0] call FUNC(uiClick));
};

class PacEdit: RscADMPEdit {
    sizeEx = "0.78 * (0.025 * safezoneH)";
    colorText[] = PAC_C_INK;
    colorBackground[] = PAC_C_WELL;
    colorSelection[] = PAC_C_ACCENT_DIM;
};

// MULTI-LINE CAPABLE. Every form edit is this, so a row that holds prose is
// the same control given more height rather than a different control.
class PacEditMulti: PacEdit {
    style = 16;          // ST_MULTI
    lineSpacing = 1;
};

class PacCombo: RscADMPCombo {
    sizeEx = "0.78 * (0.025 * safezoneH)";
    colorText[] = PAC_C_INK;
    colorBackground[] = PAC_C_WELL;
    colorSelectBackground[] = PAC_C_RAISE;
    colorScrollbar[] = PAC_C_ACCENT;
    onLBSelChanged = QUOTE(call FUNC(uiComboChange));
};

// A TABLE. The website's <table class=grid>: a header row in faint capitals,
// one row an item, the row under the pointer raised. Columns are real
// columns (CT_LISTNBOX), set per page with lnbSetColumnsPos, and the header
// is row 0 of the same control so it cannot drift from the data under it.
class PacList: RscListNBox {
    idc = -1;
    style = 0;
    font = "RobotoCondensed";
    sizeEx = "0.78 * (0.025 * safezoneH)";
    rowHeight = "1.25 * (0.025 * safezoneH)";
    colorText[] = PAC_C_INK;
    colorBackground[] = PAC_C_PANEL;
    colorSelect[] = PAC_C_INK;
    colorSelect2[] = PAC_C_INK;
    colorSelectBackground[] = PAC_C_RAISE;
    colorSelectBackground2[] = PAC_C_RAISE;
    colorDisabled[] = PAC_C_FAINT;
    colorScrollbar[] = PAC_C_FAINT;
    columns[] = {0};
    drawSideArrows = 0;
    idcLeft = -1;
    idcRight = -1;
    period = 0;
    shadow = 0;
    x = 0; y = 0; w = 0; h = 0;
    onLBSelChanged = QUOTE(call FUNC(uiListClick));
    class ListScrollBar {
        color[] = PAC_C_FAINT;
        colorActive[] = PAC_C_INK;
        colorDisabled[] = PAC_C_LINE;
        thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
        arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
        arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
        border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
        scrollSpeed = 0.01;
    };
};

// ---- the shell ----------------------------------------------------------------

// EVERY CONTROL IS A CHILD OF ONE GROUP (2026-10-20). The dialog used to declare
// them straight onto the display, which is a screen that can only ever be a
// dialog - and inside the tablet nothing may be (user, 2026-10-20: "all apps
// need to be inside the tablet"). A root controls-group class can be
// ctrlCreate'd onto the device dialog with every child it declares, so the same
// controls, the same handlers and the same idcs serve both hosts: the dialog
// below is this group at the full safe zone, and FUNC(uiHost) creates it at the
// tablet's map area. Child positions are fractions of the GROUP (no safezoneX /
// safezoneY offsets), and FUNC(uiPlace) places in fractions of the group too.
// The order is the old order - the background controls first - so the
// stacking is what it was.
class GVAR(shell): RscControlsGroupNoScrollbars {
    idc = PAC_IDC_SHELL;
    x = "safezoneX"; y = "safezoneY"; w = "safezoneW"; h = "safezoneH";

    class controls {
        class BACKGROUND: RscADMPText {
            idc = PAC_IDC_BACKGROUND;
            x = "0"; y = "0"; w = "safezoneW"; h = "safezoneH";
            colorBackground[] = {0.125, 0.149, 0.110, 0.98};
        };
        // The bar: the website's, a shade lighter than the page with a rule
        // under it.
        class BAR_BG: PacFill {
            idc = PAC_IDC_BAR_BG;
            x = "0"; y = "0"; w = "safezoneW"; h = "0.074 * safezoneH";
        };
        class BAR_LINE: PacFill {
            idc = PAC_IDC_BAR_LINE;
            colorBackground[] = PAC_C_LINE;
            x = "0"; y = "0.074 * safezoneH"; w = "safezoneW"; h = "0.002 * safezoneH";
        };

        class BRAND: PacText {
            idc = PAC_IDC_BRAND; text = "TAC//PAC";
            font = "RobotoCondensedBold";
            sizeEx = "0.9 * (0.025 * safezoneH)";
            x = "0.012 * safezoneW"; y = "0.008 * safezoneH";
            w = "0.120 * safezoneW"; h = "0.030 * safezoneH";
        };
        class UNIT: PacLabel {
            idc = PAC_IDC_UNIT; text = "";
            x = "0.132 * safezoneW"; y = "0.008 * safezoneH";
            w = "0.400 * safezoneW"; h = "0.030 * safezoneH";
        };
        class WHO: PacLabel {
            idc = PAC_IDC_WHO; text = "";
            style = 1;
            colorText[] = PAC_C_FAINT;
            x = "0.600 * safezoneW"; y = "0.008 * safezoneH";
            w = "0.290 * safezoneW"; h = "0.030 * safezoneH";
        };
        class CLOSE: PacNav {
            idc = PAC_IDC_CLOSE; text = "CLOSE";
            x = "0.898 * safezoneW"; y = "0.008 * safezoneH";
            w = "0.090 * safezoneW"; h = "0.028 * safezoneH";
            // FUNC(uiClose), not closeDialog: inside the tablet the dialog is
            // the device, and closing it would take the tablet with the page.
            onButtonClick = QUOTE([] call FUNC(uiClose));
        };

        // The nav. Positions are nominal - FUNC(uiNav) lays the visible ones
        // out from the left and hides the rest.
        class NAV_1: PacNav { idc = PAC_IDC_NAV1; text = ""; x = "0.012 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_2: PacNav { idc = PAC_IDC_NAV2; text = ""; x = "0.108 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_3: PacNav { idc = PAC_IDC_NAV3; text = ""; x = "0.204 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_4: PacNav { idc = PAC_IDC_NAV4; text = ""; x = "0.300 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_5: PacNav { idc = PAC_IDC_NAV5; text = ""; x = "0.396 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_6: PacNav { idc = PAC_IDC_NAV6; text = ""; x = "0.492 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_7: PacNav { idc = PAC_IDC_NAV7; text = ""; x = "0.588 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_8: PacNav { idc = PAC_IDC_NAV8; text = ""; x = "0.684 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_9: PacNav { idc = PAC_IDC_NAV9; text = ""; x = "0.780 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_10: PacNav { idc = PAC_IDC_NAV10; text = ""; x = "0.876 * safezoneW"; y = "0.040 * safezoneH"; w = "0.090 * safezoneW"; h = "0.028 * safezoneH"; };
        class NAV_UL: PacFill {
            idc = PAC_IDC_NAV_UL;
            colorBackground[] = PAC_C_ACCENT;
            x = "0.012 * safezoneW"; y = "0.070 * safezoneH";
            w = "0.090 * safezoneW"; h = "0.003 * safezoneH";
        };

        // Breadcrumb, page title, the sub-tab row.
        class CRUMB: PacRich {
            idc = PAC_IDC_CRUMB; text = "";
            size = "0.7 * (0.025 * safezoneH)";
            x = "0.012 * safezoneW"; y = "0.086 * safezoneH";
            w = "0.976 * safezoneW"; h = "0.022 * safezoneH";
        };
        class PAGE_TITLE: PacRich {
            idc = PAC_IDC_PAGE_TITLE; text = "";
            size = "1.3 * (0.025 * safezoneH)";
            x = "0.012 * safezoneW"; y = "0.108 * safezoneH";
            w = "0.700 * safezoneW"; h = "0.040 * safezoneH";
        };
        class FILTER_LABEL: PacLabel {
            idc = PAC_IDC_FILTER_LABEL; text = "FILTER";
            style = 1;
            x = "0.720 * safezoneW"; y = "0.114 * safezoneH";
            w = "0.080 * safezoneW"; h = "0.030 * safezoneH";
        };
        class FILTERBOX: PacEdit {
            idc = PAC_IDC_FILTER; text = "";
            x = "0.808 * safezoneW"; y = "0.114 * safezoneH";
            w = "0.180 * safezoneW"; h = "0.030 * safezoneH";
            onKeyUp = QUOTE([] call FUNC(uiFilter); false);
        };
        class SUB_1: PacNav { idc = PAC_IDC_SUB1; text = ""; x = "0.012 * safezoneW"; y = "0.152 * safezoneH"; w = "0.118 * safezoneW"; h = "0.026 * safezoneH"; };
        class SUB_2: PacNav { idc = PAC_IDC_SUB2; text = ""; x = "0.134 * safezoneW"; y = "0.152 * safezoneH"; w = "0.118 * safezoneW"; h = "0.026 * safezoneH"; };
        class SUB_3: PacNav { idc = PAC_IDC_SUB3; text = ""; x = "0.256 * safezoneW"; y = "0.152 * safezoneH"; w = "0.118 * safezoneW"; h = "0.026 * safezoneH"; };
        class SUB_4: PacNav { idc = PAC_IDC_SUB4; text = ""; x = "0.378 * safezoneW"; y = "0.152 * safezoneH"; w = "0.118 * safezoneW"; h = "0.026 * safezoneH"; };
        class SUB_5: PacNav { idc = PAC_IDC_SUB5; text = ""; x = "0.500 * safezoneW"; y = "0.152 * safezoneH"; w = "0.118 * safezoneW"; h = "0.026 * safezoneH"; };
        class SUB_6: PacNav { idc = PAC_IDC_SUB6; text = ""; x = "0.622 * safezoneW"; y = "0.152 * safezoneH"; w = "0.118 * safezoneW"; h = "0.026 * safezoneH"; };
        class SUB_7: PacNav { idc = PAC_IDC_SUB7; text = ""; x = "0.744 * safezoneW"; y = "0.152 * safezoneH"; w = "0.118 * safezoneW"; h = "0.026 * safezoneH"; };
        class SUB_8: PacNav { idc = PAC_IDC_SUB8; text = ""; x = "0.866 * safezoneW"; y = "0.152 * safezoneH"; w = "0.118 * safezoneW"; h = "0.026 * safezoneH"; };

        // The tiles.
        class TILE_BG_1: PacFill { idc = PAC_IDC_TILE_BG1; x = "0.012 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.084 * safezoneH"; };
        class TILE_LINE_1: PacFill { idc = PAC_IDC_TILE_LINE1; colorBackground[] = PAC_C_ACCENT; x = "0.012 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.002 * safezoneH"; };
        class TILE_TXT_1: PacRich { idc = PAC_IDC_TILE_TXT1; text = ""; x = "0.022 * safezoneW"; y = "0.194 * safezoneH"; w = "0.218 * safezoneW"; h = "0.072 * safezoneH"; };
        class TILE_BG_2: PacFill { idc = PAC_IDC_TILE_BG2; x = "0.258 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.084 * safezoneH"; };
        class TILE_LINE_2: PacFill { idc = PAC_IDC_TILE_LINE2; colorBackground[] = PAC_C_ACCENT; x = "0.258 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.002 * safezoneH"; };
        class TILE_TXT_2: PacRich { idc = PAC_IDC_TILE_TXT2; text = ""; x = "0.268 * safezoneW"; y = "0.194 * safezoneH"; w = "0.218 * safezoneW"; h = "0.072 * safezoneH"; };
        class TILE_BG_3: PacFill { idc = PAC_IDC_TILE_BG3; x = "0.504 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.084 * safezoneH"; };
        class TILE_LINE_3: PacFill { idc = PAC_IDC_TILE_LINE3; colorBackground[] = PAC_C_ACCENT; x = "0.504 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.002 * safezoneH"; };
        class TILE_TXT_3: PacRich { idc = PAC_IDC_TILE_TXT3; text = ""; x = "0.514 * safezoneW"; y = "0.194 * safezoneH"; w = "0.218 * safezoneW"; h = "0.072 * safezoneH"; };
        class TILE_BG_4: PacFill { idc = PAC_IDC_TILE_BG4; x = "0.75 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.084 * safezoneH"; };
        class TILE_LINE_4: PacFill { idc = PAC_IDC_TILE_LINE4; colorBackground[] = PAC_C_ACCENT; x = "0.75 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.002 * safezoneH"; };
        class TILE_TXT_4: PacRich { idc = PAC_IDC_TILE_TXT4; text = ""; x = "0.760 * safezoneW"; y = "0.194 * safezoneH"; w = "0.218 * safezoneW"; h = "0.072 * safezoneH"; };
        class TILE_BG_5: PacFill { idc = PAC_IDC_TILE_BG5; x = "0.012 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.084 * safezoneH"; };
        class TILE_LINE_5: PacFill { idc = PAC_IDC_TILE_LINE5; colorBackground[] = PAC_C_ACCENT; x = "0.012 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.002 * safezoneH"; };
        class TILE_TXT_5: PacRich { idc = PAC_IDC_TILE_TXT5; text = ""; x = "0.022 * safezoneW"; y = "0.194 * safezoneH"; w = "0.218 * safezoneW"; h = "0.072 * safezoneH"; };
        class TILE_BG_6: PacFill { idc = PAC_IDC_TILE_BG6; x = "0.258 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.084 * safezoneH"; };
        class TILE_LINE_6: PacFill { idc = PAC_IDC_TILE_LINE6; colorBackground[] = PAC_C_ACCENT; x = "0.258 * safezoneW"; y = "0.186 * safezoneH"; w = "0.238 * safezoneW"; h = "0.002 * safezoneH"; };
        class TILE_TXT_6: PacRich { idc = PAC_IDC_TILE_TXT6; text = ""; x = "0.268 * safezoneW"; y = "0.194 * safezoneH"; w = "0.218 * safezoneW"; h = "0.072 * safezoneH"; };

        // The tables and text blocks. Nominal positions; a page places them.
        class LIST_HEAD: PacRich {
            idc = PAC_IDC_LIST_HEAD; text = "";
            x = "0.012 * safezoneW"; y = "0.186 * safezoneH";
            w = "0.976 * safezoneW"; h = "0.028 * safezoneH";
        };
        class LIST: PacList {
            idc = PAC_IDC_LIST;
            x = "0.012 * safezoneW"; y = "0.216 * safezoneH";
            w = "0.976 * safezoneW"; h = "0.680 * safezoneH";
        };
        class LIST2_HEAD: LIST_HEAD { idc = PAC_IDC_LIST2_HEAD; };
        class LIST2: LIST { idc = PAC_IDC_LIST2; };
        class LIST3_HEAD: LIST_HEAD { idc = PAC_IDC_LIST3_HEAD; };
        class LIST3: LIST { idc = PAC_IDC_LIST3; };
        class TEXT_HEAD: LIST_HEAD { idc = PAC_IDC_TEXT_HEAD; };
        class TEXT: PacRich {
            idc = PAC_IDC_TEXT; text = "";
            colorBackground[] = PAC_C_PANEL;
            x = "0.012 * safezoneW"; y = "0.216 * safezoneH";
            w = "0.976 * safezoneW"; h = "0.680 * safezoneH";
        };
        class BIGEDIT_HEAD: LIST_HEAD { idc = PAC_IDC_BIGEDIT_HEAD; };
        class BIGEDIT: PacEditMulti {
            idc = PAC_IDC_BIGEDIT; text = "";
            x = "0.012 * safezoneW"; y = "0.216 * safezoneH";
            w = "0.976 * safezoneW"; h = "0.680 * safezoneH";
        };

        // The form: row n is idcs 60+3n (label), 61+3n (edit), 62+3n (combo) -
        // PAC_IDC_FORM_LABEL(n) / _EDIT(n) / _COMBO(n) in idcs.inc.hpp. Written
        // out rather than by a macro: HEMTT will not take a class from one.
        class FORM_LABEL_0: PacLabel { idc = 60; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_0: PacEditMulti { idc = 61; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_0: PacCombo { idc = 62; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_1: PacLabel { idc = 63; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_1: PacEditMulti { idc = 64; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_1: PacCombo { idc = 65; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_2: PacLabel { idc = 66; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_2: PacEditMulti { idc = 67; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_2: PacCombo { idc = 68; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_3: PacLabel { idc = 69; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_3: PacEditMulti { idc = 70; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_3: PacCombo { idc = 71; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_4: PacLabel { idc = 72; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_4: PacEditMulti { idc = 73; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_4: PacCombo { idc = 74; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_5: PacLabel { idc = 75; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_5: PacEditMulti { idc = 76; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_5: PacCombo { idc = 77; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_6: PacLabel { idc = 78; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_6: PacEditMulti { idc = 79; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_6: PacCombo { idc = 80; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_7: PacLabel { idc = 81; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_7: PacEditMulti { idc = 82; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_7: PacCombo { idc = 83; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_8: PacLabel { idc = 84; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_8: PacEditMulti { idc = 85; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_8: PacCombo { idc = 86; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_9: PacLabel { idc = 87; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_9: PacEditMulti { idc = 88; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_9: PacCombo { idc = 89; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_10: PacLabel { idc = 90; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_10: PacEditMulti { idc = 91; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_10: PacCombo { idc = 92; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_11: PacLabel { idc = 93; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_11: PacEditMulti { idc = 94; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_11: PacCombo { idc = 95; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_12: PacLabel { idc = 96; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_12: PacEditMulti { idc = 97; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_12: PacCombo { idc = 98; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_13: PacLabel { idc = 99; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_13: PacEditMulti { idc = 100; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_13: PacCombo { idc = 101; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_14: PacLabel { idc = 102; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_14: PacEditMulti { idc = 103; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_14: PacCombo { idc = 104; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_LABEL_15: PacLabel { idc = 105; text = ""; x = "0.012 * safezoneW"; y = "0.2 * safezoneH"; w = "0.170 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_EDIT_15: PacEditMulti { idc = 106; text = ""; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };
        class FORM_COMBO_15: PacCombo { idc = 107; x = "0.190 * safezoneW"; y = "0.2 * safezoneH"; w = "0.500 * safezoneW"; h = "0.032 * safezoneH"; };

        // The flash line above the actions, and the actions.
        class HINT: PacRich {
            idc = PAC_IDC_HINT; text = "";
            size = "0.75 * (0.025 * safezoneH)";
            x = "0.012 * safezoneW"; y = "0.906 * safezoneH";
            w = "0.976 * safezoneW"; h = "0.028 * safezoneH";
        };
        class BACK: PacNav {
            idc = PAC_IDC_BACK; text = "< BACK";
            style = 0;
            colorText[] = PAC_C_ACCENT;
            x = "0.012 * safezoneW"; y = "0.940 * safezoneH";
            w = "0.090 * safezoneW"; h = "0.034 * safezoneH";
        };
        class BTN_1: PacButton { idc = PAC_IDC_BTN1; text = ""; x = "0.108 * safezoneW"; y = "0.940 * safezoneH"; w = "0.140 * safezoneW"; h = "0.034 * safezoneH"; };
        class BTN_2: PacButton { idc = PAC_IDC_BTN2; text = ""; x = "0.256 * safezoneW"; y = "0.940 * safezoneH"; w = "0.140 * safezoneW"; h = "0.034 * safezoneH"; };
        class BTN_3: PacButton { idc = PAC_IDC_BTN3; text = ""; x = "0.404 * safezoneW"; y = "0.940 * safezoneH"; w = "0.140 * safezoneW"; h = "0.034 * safezoneH"; };
        class BTN_4: PacButton { idc = PAC_IDC_BTN4; text = ""; x = "0.552 * safezoneW"; y = "0.940 * safezoneH"; w = "0.140 * safezoneW"; h = "0.034 * safezoneH"; };
        class BTN_5: PacButton { idc = PAC_IDC_BTN5; text = ""; x = "0.700 * safezoneW"; y = "0.940 * safezoneH"; w = "0.140 * safezoneW"; h = "0.034 * safezoneH"; };
        class BTN_6: PacButton { idc = PAC_IDC_BTN6; text = ""; x = "0.848 * safezoneW"; y = "0.940 * safezoneH"; w = "0.140 * safezoneW"; h = "0.034 * safezoneH"; };

        // ARE YOU SURE. A dimmed page, a box, the question, YES in red, NO.
        class CONFIRM_DIM: RscADMPText {
            idc = PAC_IDC_CONFIRM_DIM; text = "";
            colorBackground[] = {0, 0, 0, 0.65};
            x = "0"; y = "0"; w = "safezoneW"; h = "safezoneH";
        };
        class CONFIRM_BOX: PacFill {
            idc = PAC_IDC_CONFIRM_BOX;
            x = "0.300 * safezoneW"; y = "0.380 * safezoneH";
            w = "0.400 * safezoneW"; h = "0.200 * safezoneH";
        };
        class CONFIRM_TEXT: PacRich {
            idc = PAC_IDC_CONFIRM_TEXT; text = "";
            size = "0.85 * (0.025 * safezoneH)";
            x = "0.316 * safezoneW"; y = "0.396 * safezoneH";
            w = "0.368 * safezoneW"; h = "0.120 * safezoneH";
        };
        class CONFIRM_YES: PacButton {
            idc = PAC_IDC_CONFIRM_YES; text = "YES, DO IT";
            colorText[] = PAC_C_GROUND;
            colorActive[] = PAC_C_GROUND;
            colorBackground[] = PAC_C_HOT;
            colorBackgroundActive[] = {0.96, 0.45, 0.40, 1};
            x = "0.316 * safezoneW"; y = "0.528 * safezoneH";
            w = "0.176 * safezoneW"; h = "0.034 * safezoneH";
            onButtonClick = QUOTE([true] call FUNC(uiConfirmAnswer));
        };
        class CONFIRM_NO: PacButton {
            idc = PAC_IDC_CONFIRM_NO; text = "NO";
            colorText[] = PAC_C_INK;
            colorBackground[] = PAC_C_RAISE;
            colorBackgroundActive[] = PAC_C_LINE;
            x = "0.508 * safezoneW"; y = "0.528 * safezoneH";
            w = "0.176 * safezoneW"; h = "0.034 * safezoneH";
            onButtonClick = QUOTE([false] call FUNC(uiConfirmAnswer));
        };
    };
};

// ---- the dialog ---------------------------------------------------------------

class GVAR(pac) {
    idd = 69700;
    movingEnable = 0;
    enableSimulation = 1;

    onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(display),_this select 0)]; uiNamespace setVariable [ARR_2(QQGVAR(shell),(_this select 0) displayCtrl PAC_IDC_SHELL)]; [] call FUNC(uiLoaded););
    onUnload = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(display),displayNull)]; uiNamespace setVariable [ARR_2(QQGVAR(shell),controlNull)];);

    class controls {
        class SHELL: GVAR(shell) {};
    };
};
