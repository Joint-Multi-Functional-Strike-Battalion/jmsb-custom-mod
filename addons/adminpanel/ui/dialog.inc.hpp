// TAC//ADMIN - the console, laid out to admin-console-dark.png.
//
// THE LAYOUT IS NEW; THE IDCs ARE NOT. Every control below carries the number
// the mission panel gave it, which is what lets the sixty-seven ported functions
// drive this screen without a line of their addressing changing. Rearranging a
// dialog is free when nothing addresses controls by position, and that is the
// whole reason this port was possible in an afternoon.
//
// WHAT CHANGED AND WHY. The panel was a 0.57-wide box floating in the middle of
// the screen with a 0.27 map in it - a window, in a suite that does not have
// windows. The console is the screen: a player rail down the left, the map
// filling the middle with the code box under it, and the selected man's state
// down the right. Three columns, one grid, the same rules and type as every
// other jmfsb screen.
//
// COLOURS ARE PLACEHOLDERS. FUNC(style) repaints the whole display from the
// player's tacpad scheme the moment it opens, and again whenever the scheme
// changes; what is written here is the dark scheme so that nothing flashes.
//
// GEOMETRY IS IN SAFE-ZONE FRACTIONS, written out in full rather than through a
// grid macro, so a control can be nudged by reading one line.
//
// NO STRUCTURED TEXT CARRIES AN INLINE color=. It would win over the theme's
// ctrlSetTextColor and there would be twelve labels on this screen that ignored
// the scheme - which is exactly the drift the tacpad's one-theme rule exists to
// prevent. Weight and size are set inline; colour never is.

class GVAR(console) {
    idd = 6969;
    movingEnable = 0;
    enableSimulation = 1;

    onLoad = QUOTE(uiNamespace setVariable [ARR_2('admp_displayVar',_this select 0)]; [] call FUNC(style); [] spawn admp_fnc_displayOpened;);
    onUnload = QUOTE([] call admp_fnc_displayClosed;);

    class controlsBackground {
        // The ground. Full bleed, because the console IS the screen - there is
        // no map showing round the edges to protect.
        class BACKGROUND: RscADMPText {
            idc = IDC_ADMINPANEL_BACKGROUND;
            x = "safezoneX";
            y = "safezoneY";
            w = "safezoneW";
            h = "safezoneH";
            colorBackground[] = {0.05, 0.05, 0.05, 0.96};
        };
    };

    class controls {
        // ------------------------------------------------------------ header --
        class MAIN_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_MAIN_TITLE;
            // The wordmark is written at runtime - see FUNC(style). A double
            // slash in a CONFIG string is a preprocessor gamble this screen does
            // not need to take; in SQF it is safe, and that is where it is set.
            text = "";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.008 * safezoneH + safezoneY";
            w = "0.100 * safezoneW";
            h = "0.036 * safezoneH";
        };

        class HEADER_SUBTITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_HEADER_SUBTITLE;
            text = "<t font='RobotoCondensedBold' size='0.75'>1ST JOINT MULTI-FUNCTIONAL STRIKE BATTALION  ADMIN PANEL</t>";
            x = "0.108 * safezoneW + safezoneX";
            y = "0.008 * safezoneH + safezoneY";
            w = "0.200 * safezoneW";
            h = "0.036 * safezoneH";
        };

        // The server strip. SFPS and AI are the two numbers an admin looks at
        // before anything else, so they are in the title bar rather than buried
        // in a block down the side where the panel had them.
        class ADMIN_SERVERFPS: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_ADMIN_SERVERFPS;
            text = "<t font='RobotoCondensedBold' size='0.8' align='right'>SFPS --</t>";
            x = "0.700 * safezoneW + safezoneX";
            y = "0.008 * safezoneH + safezoneY";
            w = "0.080 * safezoneW";
            h = "0.036 * safezoneH";
        };

        class ADMIN_ACTIVEAI: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_ADMIN_ACTIVEAI;
            text = "<t font='RobotoCondensedBold' size='0.8' align='right'>AI --</t>";
            x = "0.784 * safezoneW + safezoneX";
            y = "0.008 * safezoneH + safezoneY";
            w = "0.050 * safezoneW";
            h = "0.036 * safezoneH";
        };

        class HEADER_PLAYERCOUNT: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_HEADER_PLAYERCOUNT;
            text = "<t font='RobotoCondensedBold' size='0.8' align='right'>PLAYERS --</t>";
            x = "0.838 * safezoneW + safezoneX";
            y = "0.008 * safezoneH + safezoneY";
            w = "0.070 * safezoneW";
            h = "0.036 * safezoneH";
        };

        // Who you are on this screen, said in the accent. An admin console that
        // does not name its admin is how the wrong person presses BAN.
        // Centred in the title bar; the top-right corner is where a CLOSE
        // belongs (user, 2026-09-05: "move the admin box to the centre and put
        // a close button in its place").
        class HEADER_ADMINCHIP: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_HEADER_ADMINCHIP;
            text = "<t font='RobotoCondensedBold' size='0.8' align='center'>ADMIN</t>";
            x = "0.461 * safezoneW + safezoneX";
            y = "0.012 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.028 * safezoneH";
            colorBackground[] = {0.761, 0.659, 0.471, 1};
        };

        class HEADER_CLOSE: RscADMPButton {
            idc = IDC_ADMINPANEL_HEADER_CLOSE;
            text = "CLOSE";
            x = "0.914 * safezoneW + safezoneX";
            y = "0.012 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.028 * safezoneH";
            onButtonClick = "closeDialog 2;";
        };

        // TIME / WEATHER opens its own small dialog over the console, as ADMIN
        // MESSAGE does - the console has no free rail for a dozen more controls.
        class HEADER_ENVIRONMENT: RscADMPButton {
            idc = IDC_ADMINPANEL_HEADER_ENVIRONMENT;
            text = "TIME / WEATHER";
            tooltip = "Set the time of day, the speed of time and the weather for everybody.";
            x = "0.590 * safezoneW + safezoneX";
            y = "0.012 * safezoneH + safezoneY";
            w = "0.100 * safezoneW";
            h = "0.028 * safezoneH";
            onButtonClick = QUOTE(createDialog QQGVAR(environment););
        };

        // ------------------------------------------------------- player list --
        class PLAYERLIST_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYERLIST_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>P L A Y E R   L I S T</t>";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.052 * safezoneH + safezoneY";
            w = "0.120 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class PLAYERLIST_COUNT: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYERLIST_COUNT;
            text = "<t font='RobotoCondensedBold' size='0.8' align='right'>0</t>";
            x = "0.128 * safezoneW + safezoneX";
            y = "0.052 * safezoneH + safezoneY";
            w = "0.050 * safezoneW";
            h = "0.026 * safezoneH";
        };

        // FILTER, WHICH THE PANEL HAD NO WAY OF DOING. Sixty men on a listbox
        // sorted alphabetically is a scroll hunt, and the man you are looking
        // for is the one who just did something.
        class PLAYERLIST_FILTER: RscADMPEdit {
            idc = IDC_ADMINPANEL_PLAYERLIST_FILTER;
            text = "";
            tooltip = "Type to narrow the list. Matches any part of a name.";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.084 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.030 * safezoneH";
            onKeyUp = QUOTE([] call FUNC(filterList););
        };

        class PLAYERLIST_LISTBOX: RscADMPListbox {
            idc = IDC_ADMINPANEL_PLAYERLIST_LISTBOX;
            x = "0.008 * safezoneW + safezoneX";
            y = "0.120 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.320 * safezoneH";
            onLBSelChanged = "[] call admp_fnc_LBSelectionChanged;";
            onLBDblClick = "[] call admp_fnc_centreMapOnPlayer;";
        };

        // -------------------------------------------------------- utilities --
        class UTILITIES_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_UTILITIES_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>U T I L I T I E S</t>";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.450 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.026 * safezoneH";
        };

        // The four toggles keep their BACK plates: the ported
        // fn_updateToggleControls recolours those, not the buttons, so a plate
        // is how the screen says godmode is currently on.
        class UTILITIES_GODMODE_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_UTILITIES_GODMODE_BACK;
            text = "";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.484 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        class UTILITIES_GODMODE: RscADMPButton {
            idc = IDC_ADMINPANEL_UTILITIES_GODMODE;
            text = "GODMODE";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.484 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = "[] call admp_fnc_godmode;";
        };

        class UTILITIES_INFAMMO_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_UTILITIES_INFAMMO_BACK;
            text = "";
            x = "0.096 * safezoneW + safezoneX";
            y = "0.484 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        class UTILITIES_INFAMMO: RscADMPButton {
            idc = IDC_ADMINPANEL_UTILITIES_INFAMMO;
            text = "INF AMMO";
            x = "0.096 * safezoneW + safezoneX";
            y = "0.484 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = "[] spawn admp_fnc_infiniteAmmo;";
        };

        class UTILITIES_JMFSB_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_UTILITIES_JMFSB_BACK;
            text = "";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.522 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        class UTILITIES_JMFSB: RscADMPButton {
            idc = IDC_ADMINPANEL_UTILITIES_JMFSB;
            text = "JMFSB";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.522 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = "[] call admp_fnc_jmfsb;";
        };

        // ARSENAL had no handler in the mission at all - the button was there
        // and did nothing. admp_fnc_arsenal was written and never wired.
        //
        // THE ARGUMENT IS NOT OPTIONAL. fn_arsenal.sqf opens on
        // `if (_shift)` with no default, so a bare [] left _shift nil and the
        // click died on that line every time - the button LOOKED wired and
        // still did nothing. False = the ACE arsenal, which is the one this
        // mission runs; the BI path behind `true` stays for a caller that
        // wants it.
        class UTILITIES_ARSENAL: RscADMPButton {
            idc = IDC_ADMINPANEL_UTILITIES_ARSENAL;
            text = "ARSENAL";
            x = "0.096 * safezoneW + safezoneX";
            y = "0.522 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = "[false] call admp_fnc_arsenal;";
        };

        // ---------------------------------------------------- admin actions --
        class ADMIN_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_ADMIN_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>A D M I N   A C T I O N S</t>";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.570 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class ADMIN_SPECTATE_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_ADMIN_SPECTATE_BACK;
            text = "";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.604 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        class ADMIN_SPECTATE: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_SPECTATE;
            text = "SPECTATE";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.604 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = "[] spawn admp_fnc_toggleSpectator;";
        };

        class ADMIN_ZEUS_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_ADMIN_ZEUS_BACK;
            text = "";
            x = "0.096 * safezoneW + safezoneX";
            y = "0.604 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        class ADMIN_ZEUS: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_ZEUS;
            text = "ZEUS";
            x = "0.096 * safezoneW + safezoneX";
            y = "0.604 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = "[] call admp_fnc_toggleZeus;";
        };

        class ADMIN_KICK: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_KICK;
            text = "KICK";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.642 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = "[] call admp_fnc_kick;";
        };

        // BAN IS THE ONE PERMANENTLY LOUD CONTROL. It is filled in the accent
        // rather than outlined, which is the design's way of saying a button is
        // not undoable - and it is the only one on this screen that is not.
        class ADMIN_BAN_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_ADMIN_BAN_BACK;
            text = "";
            x = "0.096 * safezoneW + safezoneX";
            y = "0.642 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.761, 0.659, 0.471, 1};
        };

        class ADMIN_BAN: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_BAN;
            text = "BAN";
            x = "0.096 * safezoneW + safezoneX";
            y = "0.642 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = "[] spawn admp_fnc_ban;";
        };

        class ADMIN_SERVERLOCK: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_SERVERLOCK;
            text = "LOCK SERVER";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.680 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = "[] call admp_fnc_toggleServerLock;";
        };

        // TAC//PAC - the website's pages in game. In the box under the vehicle
        // column, beside WAKE UP / HEAL FULL and their height (user,
        // 2026-09-10: "move the TAC/PAC button and make the size of the green
        // box"); it only does anything with the pac addon loaded.
        class ADMIN_PAC: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_PAC;
            text = "TAC//PAC";
            tooltip = "TAC//PAC - the website's pages in game: dashboard, roster, applications, PAC actions, orders, configs, templates, ORBAT, Mongo docs, backup.";
            font = "RobotoCondensedBold";
            sizeEx = "1.1 * (0.025 * safezoneH)";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.892 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.070 * safezoneH";
            // ONE DIALOG (2026-09-09), opening on the dashboard as the website
            // does, with the website's nav bar along its top.
            onButtonClick = "if (!isNil 'jmfsb_pac_fnc_uiOpen') then {[] call jmfsb_pac_fnc_uiOpen}";
        };

        class ADMIN_ROLEACCESS: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_ROLEACCESS;
            text = "ROLE ACCESS";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.718 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = "[] call admp_fnc_toggleRoleAccess;";
        };

        class ADMIN_SERVERHEALALL: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_SERVERHEALALL;
            text = "HEAL ALL";
            x = "0.096 * safezoneW + safezoneX";
            y = "0.718 * safezoneH + safezoneY";
            w = "0.082 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = "[] call admp_fnc_Healall;";
        };

        // ----------------------------------------------------------- mission --
        class MISSION_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_MISSION_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>M I S S I O N</t>";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.758 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class MISSION_LOADED_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_MISSION_LOADED_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>LOADED MISSION</t>";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.788 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.022 * safezoneH";
        };

        // The MISSION block was entirely commented out upstream, because its
        // button shared an idc with HEAL ALL - see idcs.inc.hpp. With a number
        // of its own it works, so it is back.
        class MISSION_ENDCOMBO: RscADMPCombo {
            idc = IDC_ADMINPANEL_MISSION_ENDCOMBO;
            x = "0.008 * safezoneW + safezoneX";
            y = "0.814 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class MISSION_ENDBUTTON: RscADMPButton {
            idc = IDC_ADMINPANEL_MISSION_ENDBUTTON;
            text = "END MISSION";
            tooltip = "Ends the mission for everybody with the selected ending. Press twice.";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.850 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.032 * safezoneH";
            colorText[] = {0.761, 0.659, 0.471, 1};
            onButtonClick = QUOTE([] call FUNC(confirmEnd););
        };

        class ADMIN_MESSAGE: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_MESSAGE;
            text = "ADMIN MESSAGE";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.892 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = QUOTE(createDialog QQGVAR(message););
        };

        class ADMIN_PROMOTE_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_ADMIN_PROMOTE_BACK;
            text = "";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.930 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        class ADMIN_PROMOTE: RscADMPButton {
            idc = IDC_ADMINPANEL_ADMIN_PROMOTE;
            text = "TOGGLE ADMIN";
            tooltip = "Grants or revokes admin access for the selected player, for this session.";
            x = "0.008 * safezoneW + safezoneX";
            y = "0.930 * safezoneH + safezoneY";
            w = "0.170 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = "[] spawn admp_fnc_grantAdminAccess;";
        };

        // --------------------------------------------------------------- map --
        class MAP_DESCRIPTION: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_MAP_DESCRIPTION;
            text = "<t font='RobotoCondensedBold' size='0.7'>M A P</t>";
            tooltip = "Single Unit:\n  Teleport Selected Unit:          SHIFT+LMB\n  Teleport TO Selected Unit:          ALT+LMB\n  Bring Selected Unit:          ALT+SHIFT+LMB\nGroup:\n  Teleport Unit + Group:          CTRL+SHIFT+LMB";
            x = "0.187 * safezoneW + safezoneX";
            y = "0.052 * safezoneH + safezoneY";
            w = "0.360 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class MAP_CURSOR: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_MAP_CURSOR;
            text = "<t font='RobotoCondensedBold' size='0.75' align='right'>CURSOR ------</t>";
            x = "0.550 * safezoneW + safezoneX";
            y = "0.052 * safezoneH + safezoneY";
            w = "0.147 * safezoneW";
            h = "0.026 * safezoneH";
        };

        // Not `class MAP` - CBA already defines a MAP(ARR,CODE) macro, and the
        // preprocessor sees a class of that name as a call to it.
        class ADMINMAP: RscADMPMapControl {
            idc = IDC_ADMINPANEL_MAP;
            x = "0.187 * safezoneW + safezoneX";
            y = "0.080 * safezoneH + safezoneY";
            w = "0.510 * safezoneW";
            h = "0.628 * safezoneH";
            onMouseButtonDown = "params ['_control', '_button', '_xPos', '_yPos', '_shift', '_ctrl', '_alt']; [[_xPos, _yPos], _shift, _ctrl, _alt, _button] spawn admp_fnc_handleMapClick;";
            onMouseMoving = QUOTE(call FUNC(mapCursor);); // call already inherits _this
        };

        // WHAT THE MAP IS SHOWING. The panel tracked players and only players,
        // which is fine until the thing you are chasing is an empty helicopter
        // or an AI group that will not stop shooting.
        class MAP_TAB_PLAYERS: RscADMPButton {
            idc = IDC_ADMINPANEL_MAP_TAB_PLAYERS;
            text = "PLAYERS";
            x = "0.196 * safezoneW + safezoneX";
            y = "0.090 * safezoneH + safezoneY";
            w = "0.060 * safezoneW";
            h = "0.028 * safezoneH";
            onButtonClick = QUOTE(['players'] call FUNC(mapFilter););
        };

        class MAP_TAB_VEHICLES: RscADMPButton {
            idc = IDC_ADMINPANEL_MAP_TAB_VEHICLES;
            text = "VEHICLES";
            x = "0.258 * safezoneW + safezoneX";
            y = "0.090 * safezoneH + safezoneY";
            w = "0.060 * safezoneW";
            h = "0.028 * safezoneH";
            onButtonClick = QUOTE(['vehicles'] call FUNC(mapFilter););
        };

        class MAP_TAB_AI: RscADMPButton {
            idc = IDC_ADMINPANEL_MAP_TAB_AI;
            text = "AI";
            x = "0.320 * safezoneW + safezoneX";
            y = "0.090 * safezoneH + safezoneY";
            w = "0.036 * safezoneW";
            h = "0.028 * safezoneH";
            onButtonClick = QUOTE(['ai'] call FUNC(mapFilter););
        };

        class MAP_TAB_MARKERS: RscADMPButton {
            idc = IDC_ADMINPANEL_MAP_TAB_MARKERS;
            text = "MARKERS";
            tooltip = "Trackers off - the mission's own markers only.";
            x = "0.358 * safezoneW + safezoneX";
            y = "0.090 * safezoneH + safezoneY";
            w = "0.060 * safezoneW";
            h = "0.028 * safezoneH";
            onButtonClick = QUOTE(['markers'] call FUNC(mapFilter););
        };

        // ---------------------------------------------------------- the code --
        class REMOTEEXEC_HEADING: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_REMOTEEXEC_HEADING;
            text = "<t font='RobotoCondensedBold' size='0.7'>E X E C U T E</t>";
            x = "0.187 * safezoneW + safezoneX";
            y = "0.716 * safezoneH + safezoneY";
            w = "0.070 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class REMOTEEXEC_SERVEREXEC_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_REMOTEEXEC_SERVEREXEC_BACK;
            text = "";
            x = "0.258 * safezoneW + safezoneX";
            y = "0.714 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.030 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        class REMOTEEXEC_SERVEREXEC: RscADMPButton {
            idc = IDC_ADMINPANEL_REMOTEEXEC_SERVEREXEC;
            text = "SERVER";
            x = "0.258 * safezoneW + safezoneX";
            y = "0.714 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.030 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = QUOTE([1] call FUNC(execTarget););
        };

        class REMOTEEXEC_LOCALEXEC_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_REMOTEEXEC_LOCALEXEC_BACK;
            text = "";
            x = "0.308 * safezoneW + safezoneX";
            y = "0.714 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.030 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        class REMOTEEXEC_LOCALEXEC: RscADMPButton {
            idc = IDC_ADMINPANEL_REMOTEEXEC_LOCALEXEC;
            text = "LOCAL";
            x = "0.308 * safezoneW + safezoneX";
            y = "0.714 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.030 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = QUOTE([2] call FUNC(execTarget););
        };

        class REMOTEEXEC_EXECBUTTON_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_REMOTEEXEC_EXECBUTTON_BACK;
            text = "";
            x = "0.358 * safezoneW + safezoneX";
            y = "0.714 * safezoneH + safezoneY";
            w = "0.058 * safezoneW";
            h = "0.030 * safezoneH";
            colorBackground[] = {0.10, 0.10, 0.10, 1};
        };

        // REMOTE names its target, because "remote" on its own is how code ends
        // up running on the wrong man's machine.
        //
        // THE THREE FIT THE CODE COLUMN (0.258 to 0.416, inside the edit box's
        // 0.417 right edge). REMOTE used to run to 0.464, into the RETURN column,
        // which is why RETURN sat a row lower than EXECUTE (user, 2026-09-05:
        // "make the 3 buttons fit so the return can be on the same level").
        class REMOTEEXEC_EXECBUTTON: RscADMPButton {
            idc = IDC_ADMINPANEL_REMOTEEXEC_EXECBUTTON;
            text = "REMOTE";
            x = "0.358 * safezoneW + safezoneX";
            y = "0.714 * safezoneH + safezoneY";
            w = "0.058 * safezoneW";
            h = "0.030 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            onButtonClick = QUOTE([0] call FUNC(execTarget););
        };

        class REMOTEEXEC_HISTORY_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_REMOTEEXEC_HISTORY_LABEL;
            text = "<t font='RobotoCondensedBold' size='0.7' align='right'>H I S T O R Y</t>";
            x = "0.570 * safezoneW + safezoneX";
            y = "0.716 * safezoneH + safezoneY";
            w = "0.080 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class REMOTEEXEC_PREV: RscADMPButton {
            idc = IDC_ADMINPANEL_REMOTEEXEC_PREV;
            text = QPATHTOF(ui\icons\arrow_left.paa);
            style = ST_PICTURE;
            x = "0.654 * safezoneW + safezoneX";
            y = "0.716 * safezoneH + safezoneY";
            w = "0.020 * safezoneW";
            h = "0.026 * safezoneH";
            onButtonClick = "if ((admp_debug_codeIndex-1) >= 0) then {admp_debug_codeIndex = admp_debug_codeIndex-1; [] call admp_fnc_loadPreviousCode;};";
        };

        class REMOTEEXEC_NEXT: RscADMPButton {
            idc = IDC_ADMINPANEL_REMOTEEXEC_NEXT;
            text = QPATHTOF(ui\icons\arrow_right.paa);
            style = ST_PICTURE;
            x = "0.676 * safezoneW + safezoneX";
            y = "0.716 * safezoneH + safezoneY";
            w = "0.020 * safezoneW";
            h = "0.026 * safezoneH";
            onButtonClick = "if ((admp_debug_codeIndex+1) < count admp_debug_previousCode) then {admp_debug_codeIndex = admp_debug_codeIndex+1; [] call admp_fnc_loadPreviousCode;};";
        };

        class REMOTEEXEC_EDITBOX: RscADMPEdit {
            idc = IDC_ADMINPANEL_REMOTEEXEC_EDITBOX;
            text = "";
            style = "0x00 + 0x40 + 0x100";
            x = "0.187 * safezoneW + safezoneX";
            y = "0.750 * safezoneH + safezoneY";
            w = "0.230 * safezoneW";
            h = "0.184 * safezoneH";
            onLoad = "_this#0 ctrlSetText admp_debug_latestCode;";
        };

        class REMOTEEXEC_EXECRUN: RscADMPButton {
            idc = -1;
            text = "RUN";
            tooltip = "Runs on whichever target was pressed last - server unless you say otherwise.";
            x = "0.187 * safezoneW + safezoneX";
            y = "0.942 * safezoneH + safezoneY";
            w = "0.054 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.761, 0.659, 0.471, 1};
            colorText[] = {0.05, 0.05, 0.05, 1};
            onButtonClick = QUOTE([] call FUNC(execRun););
        };

        class REMOTEEXEC_CLEAR: RscADMPButton {
            idc = IDC_ADMINPANEL_REMOTEEXEC_CLEAR;
            text = "CLEAR";
            x = "0.245 * safezoneW + safezoneX";
            y = "0.942 * safezoneH + safezoneY";
            w = "0.062 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = QUOTE([] call FUNC(execClear););
        };

        class REMOTEEXEC_HINT: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_REMOTEEXEC_HINT;
            text = "<t font='RobotoCondensedBold' size='0.7' align='right'>C T R L  +  E N T E R</t>";
            x = "0.311 * safezoneW + safezoneX";
            y = "0.942 * safezoneH + safezoneY";
            w = "0.106 * safezoneW";
            h = "0.032 * safezoneH";
        };

        // Level with EXECUTE, and the box level with the code box - see the
        // note on REMOTEEXEC_EXECBUTTON.
        class REMOTEEXEC_RETURN_HEAD: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_REMOTEEXEC_RETURN_HEAD;
            text = "<t font='RobotoCondensedBold' size='0.7'>R E T U R N</t>";
            x = "0.425 * safezoneW + safezoneX";
            y = "0.716 * safezoneH + safezoneY";
            w = "0.100 * safezoneW";
            h = "0.026 * safezoneH";
        };

        // THE ANSWER, WHICH THE PANEL NEVER SHOWED. Code ran and whatever it
        // returned went nowhere - the only feedback was a notification saying it
        // had been sent. A debug console that will not tell you what came back
        // is a way of guessing.
        class REMOTEEXEC_RETURN: RscADMPListbox {
            idc = IDC_ADMINPANEL_REMOTEEXEC_RETURN;
            x = "0.425 * safezoneW + safezoneX";
            y = "0.750 * safezoneH + safezoneY";
            w = "0.272 * safezoneW";
            h = "0.184 * safezoneH";
        };

        // COPY puts the whole return on the clipboard - a value you can only
        // read off a listbox is a value you retype (user, 2026-09-05).
        class REMOTEEXEC_COPY: RscADMPButton {
            idc = IDC_ADMINPANEL_REMOTEEXEC_COPY;
            text = "COPY";
            tooltip = "Copies the return value to the clipboard";
            x = "0.425 * safezoneW + safezoneX";
            y = "0.942 * safezoneH + safezoneY";
            w = "0.062 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = QUOTE([] call FUNC(execCopy););
        };

        // --------------------------------------------------------- the rail --
        class PLAYER_CAMDISPLAY_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_CAMDISPLAY_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>P L A Y E R   V I E W</t>";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.052 * safezoneH + safezoneY";
            w = "0.150 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class PLAYER_CAMDISPLAY_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_PLAYER_CAMDISPLAY_BACK;
            text = "";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.080 * safezoneH + safezoneY";
            w = "0.290 * safezoneW";
            h = "0.180 * safezoneH";
            colorBackground[] = {0.09, 0.10, 0.09, 1};
        };

        class PLAYER_CAMDISPLAY: RscADMPPicture {
            idc = IDC_ADMINPANEL_PLAYER_CAMDISPLAY;
            text = "#(argb,256,256,1)r2t(admpcamrender,1)";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.080 * safezoneH + safezoneY";
            w = "0.290 * safezoneW";
            h = "0.180 * safezoneH";
            onLoad = "[] spawn {sleep 0.05; if (admp_camera_NVGmode) then {'admpcamrender' setPiPEffect [1];};};";
        };

        class PLAYER_CAMDISPLAY_READOUT: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_CAMDISPLAY_READOUT;
            text = "<t font='RobotoCondensedBold' size='0.75'>------  -- M ASL  HDG ---</t>";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.234 * safezoneH + safezoneY";
            w = "0.282 * safezoneW";
            h = "0.024 * safezoneH";
        };

        class PLAYER_CAMDISPLAY_VIEWMODE: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_CAMDISPLAY_VIEWMODE;
            text = "TOGGLE VIEW";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.266 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.030 * safezoneH";
            onButtonClick = "admp_camera_firstPersonMode = !admp_camera_firstPersonMode;";
        };

        class PLAYER_CAMDISPLAY_VISMODE: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_CAMDISPLAY_VISMODE;
            text = "NVG MODE";
            x = "0.849 * safezoneW + safezoneX";
            y = "0.266 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.030 * safezoneH";
            onButtonClick = "admp_camera_NVGmode = !admp_camera_NVGmode; 'admpcamrender' setPiPEffect [parseNumber admp_camera_NVGmode];";
        };

        // ---------------------------------------------------- player + info --
        class PLAYER_INFO_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_INFO_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>P L A Y E R   I N F O</t>";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.302 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.024 * safezoneH";
        };

        class PLAYER_INFO_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_PLAYER_INFO_BACK;
            text = "";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.330 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.166 * safezoneH";
            colorBackground[] = {0.08, 0.08, 0.08, 1};
        };

        class PLAYER_INFO_NAME: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_INFO_NAME;
            text = "NAME";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.334 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_INFO_SIDE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_INFO_SIDE;
            text = "SIDE";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.366 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_INFO_GRID: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_INFO_GRID;
            text = "GRID";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.398 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
            colorText[] = {0.761, 0.659, 0.471, 1};
        };

        class PLAYER_INFO_FPS: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_INFO_FPS;
            text = "FPS";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.430 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_INFO_VEHICLE_INFO: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_INFO_VEHICLE_INFO;
            text = "IN VEHICLE";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.462 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        // -------------------------------------------------------- the skills --
        class PLAYER_SKILLS_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>P L A Y E R   S K I L L S</t>";
            x = "0.849 * safezoneW + safezoneX";
            y = "0.302 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.024 * safezoneH";
        };

        class PLAYER_SKILLS_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_BACK;
            text = "";
            x = "0.849 * safezoneW + safezoneX";
            y = "0.330 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.270 * safezoneH";
            colorBackground[] = {0.08, 0.08, 0.08, 1};
        };

        class ADMIN_RANK_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_ADMIN_RANK_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>RANK</t>";
            x = "0.853 * safezoneW + safezoneX";
            y = "0.334 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class ADMIN_RANK_COMBO: RscADMPCombo {
            idc = IDC_ADMINPANEL_ADMIN_RANK_COMBO;
            x = "0.853 * safezoneW + safezoneX";
            y = "0.356 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.030 * safezoneH";
            onLBSelChanged = "[] call admp_fnc_setPlayerRank;";
        };

        // THE SKILLS, EACH BY ITS NAME (user, 2026-10-08: "remove the eng and
        // medic drop down, type out the name of each skill"). One box per skill
        // in two columns, the label the skill's full name - TAC//PAC's own
        // name for it when PAC is loaded (admp_fnc_labelSkills), these words
        // otherwise. The MEDICAL and ENGINEERING pickers that chose a level
        // are gone: the level is the skill's business in PAC, not the panel's.
        // DRA went with them - nothing in the mod or a mission reads it.
        class PLAYER_SKILLS_CLS_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_CLS_CHECKBOX;
            x = "0.853 * safezoneW + safezoneX";
            y = "0.392 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_CLS_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_CLS_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>Combat Lifesaver</t>";
            x = "0.872 * safezoneW + safezoneX";
            y = "0.392 * safezoneH + safezoneY";
            w = "0.052 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_MED_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_MED_CHECKBOX;
            x = "0.925 * safezoneW + safezoneX";
            y = "0.392 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_MED_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_MED_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>Medic</t>";
            x = "0.944 * safezoneW + safezoneX";
            y = "0.392 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_ENG_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_ENG_CHECKBOX;
            x = "0.853 * safezoneW + safezoneX";
            y = "0.420 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_ENG_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_ENG_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>Engineer</t>";
            x = "0.872 * safezoneW + safezoneX";
            y = "0.420 * safezoneH + safezoneY";
            w = "0.052 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_EOD_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_EOD_CHECKBOX;
            x = "0.925 * safezoneW + safezoneX";
            y = "0.420 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_EOD_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_EOD_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>Breacher / EOD</t>";
            x = "0.944 * safezoneW + safezoneX";
            y = "0.420 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_ISR_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_ISR_CHECKBOX;
            x = "0.853 * safezoneW + safezoneX";
            y = "0.448 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_ISR_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_ISR_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>ISR</t>";
            x = "0.872 * safezoneW + safezoneX";
            y = "0.448 * safezoneH + safezoneY";
            w = "0.052 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_JFO_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_JFO_CHECKBOX;
            x = "0.925 * safezoneW + safezoneX";
            y = "0.448 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_JFO_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_JFO_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>JFO</t>";
            x = "0.944 * safezoneW + safezoneX";
            y = "0.448 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_UAV_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_UAV_CHECKBOX;
            x = "0.853 * safezoneW + safezoneX";
            y = "0.476 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_UAV_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_UAV_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>UAV operator</t>";
            x = "0.872 * safezoneW + safezoneX";
            y = "0.476 * safezoneH + safezoneY";
            w = "0.052 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_MKS_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_MKS_CHECKBOX;
            x = "0.925 * safezoneW + safezoneX";
            y = "0.476 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_MKS_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_MKS_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>Marksman</t>";
            x = "0.944 * safezoneW + safezoneX";
            y = "0.476 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_SNP_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_SNP_CHECKBOX;
            x = "0.853 * safezoneW + safezoneX";
            y = "0.504 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_SNP_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_SNP_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>Sniper</t>";
            x = "0.872 * safezoneW + safezoneX";
            y = "0.504 * safezoneH + safezoneY";
            w = "0.052 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_HVY_CHECKBOX: RscADMPCheckbox {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_HVY_CHECKBOX;
            x = "0.925 * safezoneW + safezoneX";
            y = "0.504 * safezoneH + safezoneY";
            w = "0.018 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_HVY_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_HVY_LABEL;
            text = "<t font='RobotoCondensed' size='0.7'>Heavy Weapons</t>";
            x = "0.944 * safezoneW + safezoneX";
            y = "0.504 * safezoneH + safezoneY";
            w = "0.048 * safezoneW";
            h = "0.024 * safezoneH";
        };
        class PLAYER_SKILLS_APPLY_BUTTON: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_SKILLS_APPLY_BUTTON;
            text = "APPLY SKILLS";
            x = "0.903 * safezoneW + safezoneX";
            y = "0.566 * safezoneH + safezoneY";
            w = "0.085 * safezoneW";
            h = "0.030 * safezoneH";
            colorBackground[] = {0.761, 0.659, 0.471, 1};
            colorText[] = {0.05, 0.05, 0.05, 1};
            onButtonClick = "[] call admp_fnc_applySkills;";
        };

        // ------------------------------------------------------- the vehicle --
        class PLAYER_VEHICLE_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>V E H I C L E</t>";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.606 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.024 * safezoneH";
        };

        class PLAYER_VEHICLE_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_BACK;
            text = "";
            x = "0.702 * safezoneW + safezoneX";
            y = "0.634 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.240 * safezoneH";
            colorBackground[] = {0.08, 0.08, 0.08, 1};
        };

        class PLAYER_VEHICLE_DISMOUNT: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_DISMOUNT;
            text = "DISMOUNT";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.640 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.030 * safezoneH";
            onButtonClick = "[] call admp_fnc_forceDismount;";
        };

        class PLAYER_VEHICLE_UNSTUCK: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_UNSTUCK;
            text = "UNSTUCK";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.676 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.030 * safezoneH";
            onButtonClick = "[] call admp_fnc_vehicleUnstuck;";
        };

        class PLAYER_VEHICLE_SERVICE_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_SERVICE_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>SERVICE</t>";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.712 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.022 * safezoneH";
        };

        // Icon buttons with their own labels underneath, exactly as upstream had
        // them - the three-letter caption is a separate control because a button
        // in ST_PICTURE style cannot carry text.
        class PLAYER_VEHICLE_REPAIR: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_REPAIR;
            text = "\a3\ui_f\data\igui\cfg\simpletasks\types\repair_ca.paa";
            style = ST_PICTURE;
            x = "0.706 * safezoneW + safezoneX";
            y = "0.736 * safezoneH + safezoneY";
            w = "0.038 * safezoneH * pixelW / pixelH";
            h = "0.038 * safezoneH";
            onButtonClick = "[] call admp_fnc_repairVehicle;";
        };

        class PLAYER_VEHICLE_REPTEXT: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_REPTEXT;
            text = "<t font='RobotoCondensedBold' size='0.7' align='center'>REP</t>";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.776 * safezoneH + safezoneY";
            w = "0.041 * safezoneW";
            h = "0.020 * safezoneH";
        };

        class PLAYER_VEHICLE_REFUEL: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_REFUEL;
            text = "\a3\ui_f\data\igui\cfg\simpletasks\types\refuel_ca.paa";
            style = ST_PICTURE;
            x = "0.753 * safezoneW + safezoneX";
            y = "0.736 * safezoneH + safezoneY";
            w = "0.038 * safezoneH * pixelW / pixelH";
            h = "0.038 * safezoneH";
            onButtonClick = "[] call admp_fnc_refuelVehicle;";
        };

        class PLAYER_VEHICLE_REFTEXT: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_REFTEXT;
            text = "<t font='RobotoCondensedBold' size='0.7' align='center'>REF</t>";
            x = "0.753 * safezoneW + safezoneX";
            y = "0.776 * safezoneH + safezoneY";
            w = "0.041 * safezoneW";
            h = "0.020 * safezoneH";
        };

        class PLAYER_VEHICLE_REARM: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_REARM;
            text = "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa";
            style = ST_PICTURE;
            x = "0.800 * safezoneW + safezoneX";
            y = "0.736 * safezoneH + safezoneY";
            w = "0.038 * safezoneH * pixelW / pixelH";
            h = "0.038 * safezoneH";
            onButtonClick = "[] call admp_fnc_rearmVehicle;";
        };

        class PLAYER_VEHICLE_REATEXT: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_REATEXT;
            text = "<t font='RobotoCondensedBold' size='0.7' align='center'>REA</t>";
            x = "0.800 * safezoneW + safezoneX";
            y = "0.776 * safezoneH + safezoneY";
            w = "0.041 * safezoneW";
            h = "0.020 * safezoneH";
        };

        // WHAT THE THREE ICONS ACTUALLY ACT ON. They service the nearest vehicle
        // to the selected man, not a vehicle he is in - which is not obvious from
        // three pictures, and is the difference between repairing his truck and
        // repairing somebody else's.
        class PLAYER_VEHICLE_NOTE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_VEHICLE_NOTE;
            text = "<t font='RobotoCondensed' size='0.7'>Service acts on the nearest vehicle to the selection.</t>";
            x = "0.706 * safezoneW + safezoneX";
            y = "0.800 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.062 * safezoneH";
        };

        // ------------------------------------------------------- the medical --
        class PLAYER_MEDICAL_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_TITLE;
            text = "<t font='RobotoCondensedBold' size='0.7'>M E D I C A L</t>";
            x = "0.849 * safezoneW + safezoneX";
            y = "0.606 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.024 * safezoneH";
        };

        class PLAYER_MEDICAL_BACK: RscADMPText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_BACK;
            text = "";
            x = "0.849 * safezoneW + safezoneX";
            y = "0.634 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.240 * safezoneH";
            colorBackground[] = {0.08, 0.08, 0.08, 1};
        };

        class PLAYER_MEDICAL_STATUS: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_STATUS;
            text = "STATUS";
            x = "0.853 * safezoneW + safezoneX";
            y = "0.640 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_MEDICAL_HEART: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_HEART;
            text = "HEART RATE";
            x = "0.853 * safezoneW + safezoneX";
            y = "0.672 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_MEDICAL_BLDPRES: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_BLDPRES;
            text = "BLOOD PRES";
            x = "0.853 * safezoneW + safezoneX";
            y = "0.704 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_MEDICAL_BLDVOL: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_BLDVOL;
            text = "BLOOD VOL";
            x = "0.853 * safezoneW + safezoneX";
            y = "0.736 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_MEDICAL_PAIN: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_PAIN;
            text = "PAIN";
            x = "0.853 * safezoneW + safezoneX";
            y = "0.768 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_MEDICAL_SP02: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_SP02;
            text = "SPO2";
            x = "0.853 * safezoneW + safezoneX";
            y = "0.800 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };
        // BLOOD TYPE (user, 2026-08-28) - dealt once per player by
        // jmfsb_common_fnc_bloodType, or whatever the mission set on the unit.
        class PLAYER_MEDICAL_BLOOD: RscADMPStructuredText {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_BLOOD;
            text = "BLOOD TYPE";
            x = "0.853 * safezoneW + safezoneX";
            y = "0.832 * safezoneH + safezoneY";
            w = "0.135 * safezoneW";
            h = "0.028 * safezoneH";
        };

        class PLAYER_MEDICAL_WAKEUP: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_WAKEUP;
            text = "WAKE UP";
            x = "0.849 * safezoneW + safezoneX";
            y = "0.892 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.032 * safezoneH";
            onButtonClick = "[] spawn admp_fnc_wakeUp;";
        };

        class PLAYER_MEDICAL_FULLHEAL: RscADMPButton {
            idc = IDC_ADMINPANEL_PLAYER_MEDICAL_FULLHEAL;
            text = "HEAL FULL";
            x = "0.849 * safezoneW + safezoneX";
            y = "0.930 * safezoneH + safezoneY";
            w = "0.143 * safezoneW";
            h = "0.032 * safezoneH";
            colorBackground[] = {0.761, 0.659, 0.471, 1};
            colorText[] = {0.05, 0.05, 0.05, 1};
            onButtonClick = "[] call admp_fnc_fullHeal;";
        };
    };
};

// THE MESSAGE BOX. A small dialog, deliberately - it is one field and a send,
// and it opens over the console rather than replacing it. Anyone may open this,
// admin or not, which is how a player reaches an admin in the first place.
class GVAR(message) {
    idd = 6970;
    movingEnable = 0;
    enableSimulation = 1;

    onLoad = QUOTE(uiNamespace setVariable [ARR_2('admp_messageDisplayVar',_this select 0)]; [] call FUNC(styleMessage); [] call admp_fnc_messageDisplayOpened;);
    onUnload = "";

    class controlsBackground {
        class BACKGROUND: RscADMPText {
            idc = IDC_ADMINMESSAGE_BACKGROUND;
            x = "0.290 * safezoneW + safezoneX";
            y = "0.200 * safezoneH + safezoneY";
            w = "0.420 * safezoneW";
            h = "0.560 * safezoneH";
            colorBackground[] = {0.05, 0.05, 0.05, 0.96};
        };
    };

    class controls {
        class MAIN_TITLE: RscADMPStructuredText {
            idc = IDC_ADMINMESSAGE_MAIN_TITLE;
            text = ""; // written at runtime - see FUNC(styleMessage)
            x = "0.298 * safezoneW + safezoneX";
            y = "0.208 * safezoneH + safezoneY";
            w = "0.404 * safezoneW";
            h = "0.036 * safezoneH";
        };

        class RECIPIENT_TEXT: RscADMPStructuredText {
            idc = IDC_ADMINMESSAGE_RECIPIENT_TEXT;
            text = "<t font='RobotoCondensed' size='0.75'>RECIPIENT</t>";
            x = "0.298 * safezoneW + safezoneX";
            y = "0.252 * safezoneH + safezoneY";
            w = "0.190 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class PLAYER_SELECTOR: RscADMPCombo {
            idc = IDC_ADMINMESSAGE_PLAYER_SELECTOR;
            x = "0.298 * safezoneW + safezoneX";
            y = "0.276 * safezoneH + safezoneY";
            w = "0.190 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class MESSAGE_EDIT_BOX: RscADMPEdit {
            idc = IDC_ADMINMESSAGE_MESSAGE_EDIT_BOX;
            text = "";
            style = "0x00 + 0x40 + 0x100";
            x = "0.298 * safezoneW + safezoneX";
            y = "0.316 * safezoneH + safezoneY";
            w = "0.190 * safezoneW";
            h = "0.360 * safezoneH";
        };

        class SEND_BUTTON_BACK: RscADMPText {
            idc = IDC_ADMINMESSAGE_SEND_BUTTON_BACK;
            text = "";
            x = "0.298 * safezoneW + safezoneX";
            y = "0.686 * safezoneH + safezoneY";
            w = "0.190 * safezoneW";
            h = "0.034 * safezoneH";
            colorBackground[] = {0.761, 0.659, 0.471, 1};
        };

        class SEND_BUTTON: RscADMPButton {
            idc = IDC_ADMINMESSAGE_SEND_BUTTON;
            text = "SEND";
            x = "0.298 * safezoneW + safezoneX";
            y = "0.686 * safezoneH + safezoneY";
            w = "0.190 * safezoneW";
            h = "0.034 * safezoneH";
            colorBackground[] = {0, 0, 0, 0};
            colorText[] = {0.05, 0.05, 0.05, 1};
            onButtonClick = "[] call admp_fnc_sendMessage;";
        };

        class MESSAGE_VIEWER_HISTORY_HEADING: RscADMPStructuredText {
            idc = IDC_ADMINMESSAGE_MESSAGE_VIEWER_HISTORY_HEADING;
            text = "<t font='RobotoCondensedBold' size='0.7'>H I S T O R Y</t>";
            x = "0.498 * safezoneW + safezoneX";
            y = "0.252 * safezoneH + safezoneY";
            w = "0.204 * safezoneW";
            h = "0.024 * safezoneH";
        };

        class MESSAGE_VIEWER_HISTORY_LIST: RscADMPListbox {
            idc = IDC_ADMINMESSAGE_MESSAGE_VIEWER_HISTORY_LIST;
            x = "0.498 * safezoneW + safezoneX";
            y = "0.276 * safezoneH + safezoneY";
            w = "0.204 * safezoneW";
            h = "0.160 * safezoneH";
            onLBSelChanged = "[] call admp_fnc_messageHistorySelection;";
        };

        class MESSAGE_VIEWER_HEADING: RscADMPStructuredText {
            idc = IDC_ADMINMESSAGE_MESSAGE_VIEWER_HEADING;
            text = "<t font='RobotoCondensedBold' size='0.7'>M E S S A G E</t>";
            x = "0.498 * safezoneW + safezoneX";
            y = "0.446 * safezoneH + safezoneY";
            w = "0.204 * safezoneW";
            h = "0.024 * safezoneH";
        };

        class MESSAGE_VIEWER_BACKGROUND: RscADMPText {
            idc = IDC_ADMINMESSAGE_MESSAGE_VIEWER_BACKGROUND;
            text = "";
            x = "0.498 * safezoneW + safezoneX";
            y = "0.470 * safezoneH + safezoneY";
            w = "0.204 * safezoneW";
            h = "0.250 * safezoneH";
            colorBackground[] = {0.08, 0.08, 0.08, 1};
        };

        class MESSAGE_VIEWER_SENDER: RscADMPText {
            idc = IDC_ADMINMESSAGE_MESSAGE_VIEWER_SENDER;
            text = "FROM:";
            x = "0.502 * safezoneW + safezoneX";
            y = "0.474 * safezoneH + safezoneY";
            w = "0.196 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class MESSAGE_VIEWER_RECEIVER: RscADMPText {
            idc = IDC_ADMINMESSAGE_MESSAGE_VIEWER_RECEIVER;
            text = "TO:";
            x = "0.502 * safezoneW + safezoneX";
            y = "0.502 * safezoneH + safezoneY";
            w = "0.196 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class MESSAGE_VIEWER_MESSAGE_HEADING: RscADMPStructuredText {
            idc = IDC_ADMINMESSAGE_MESSAGE_VIEWER_MESSAGE_HEADING;
            text = "<t font='RobotoCondensed' size='0.75'>MESSAGE</t>";
            x = "0.502 * safezoneW + safezoneX";
            y = "0.532 * safezoneH + safezoneY";
            w = "0.196 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class MESSAGE_VIEWER_MESSAGE_TEXT: RscADMPStructuredText {
            idc = IDC_ADMINMESSAGE_MESSAGE_VIEWER_MESSAGE_TEXT;
            text = "";
            x = "0.502 * safezoneW + safezoneX";
            y = "0.556 * safezoneH + safezoneY";
            w = "0.196 * safezoneW";
            h = "0.160 * safezoneH";
        };
    };
};

// TIME / WEATHER. A small dialog over the console, like the message box: the
// time of day and how fast it runs, and the weather - set for everybody
// (user, 2026-10-16). FUNC(envLoad) fills the combos from the current values and
// paints it; FUNC(envApply) sends what is picked to the server.
class GVAR(environment) {
    idd = IDD_ADMINPANEL_ENVIRONMENT;
    movingEnable = 0;
    enableSimulation = 1;

    onLoad = QUOTE([_this select 0] call FUNC(envLoad););

    class controlsBackground {
        class BACKGROUND: RscADMPText {
            idc = IDC_ADMINENV_BACKGROUND;
            text = "";
            x = "0.330 * safezoneW + safezoneX";
            y = "0.230 * safezoneH + safezoneY";
            w = "0.340 * safezoneW";
            h = "0.500 * safezoneH";
            colorBackground[] = {0.05, 0.05, 0.05, 0.96};
        };
    };

    class controls {
        class TITLE: RscADMPStructuredText {
            idc = IDC_ADMINENV_TITLE;
            text = ""; // written at runtime - see FUNC(envLoad)
            x = "0.338 * safezoneW + safezoneX";
            y = "0.238 * safezoneH + safezoneY";
            w = "0.324 * safezoneW";
            h = "0.036 * safezoneH";
        };

        class READOUT: RscADMPStructuredText {
            idc = IDC_ADMINENV_READOUT;
            text = ""; // kept current by FUNC(envReadout)
            x = "0.338 * safezoneW + safezoneX";
            y = "0.278 * safezoneH + safezoneY";
            w = "0.324 * safezoneW";
            h = "0.050 * safezoneH";
        };

        class TIME_HEAD: RscADMPStructuredText {
            idc = IDC_ADMINENV_TIME_HEAD;
            text = "<t font='RobotoCondensedBold' size='0.7'>T I M E</t>";
            x = "0.338 * safezoneW + safezoneX";
            y = "0.336 * safezoneH + safezoneY";
            w = "0.324 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class HOUR_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINENV_HOUR_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>HOUR</t>";
            x = "0.338 * safezoneW + safezoneX";
            y = "0.364 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class MINUTE_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINENV_MINUTE_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>MINUTE</t>";
            x = "0.420 * safezoneW + safezoneX";
            y = "0.364 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class SPEED_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINENV_SPEED_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>SPEED</t>";
            x = "0.502 * safezoneW + safezoneX";
            y = "0.364 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class HOUR: RscADMPCombo {
            idc = IDC_ADMINENV_HOUR;
            x = "0.338 * safezoneW + safezoneX";
            y = "0.388 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class MINUTE: RscADMPCombo {
            idc = IDC_ADMINENV_MINUTE;
            x = "0.420 * safezoneW + safezoneX";
            y = "0.388 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class SPEED: RscADMPCombo {
            idc = IDC_ADMINENV_SPEED;
            x = "0.502 * safezoneW + safezoneX";
            y = "0.388 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class TIME_APPLY: RscADMPButton {
            idc = IDC_ADMINENV_TIME_APPLY;
            text = "SET TIME";
            tooltip = "Sets the clock and the speed of time for everybody.";
            colorBackground[] = {0.761, 0.659, 0.471, 1};
            colorText[] = {0.05, 0.05, 0.05, 1};
            onButtonClick = QUOTE(['time'] call FUNC(envApply););
            x = "0.584 * safezoneW + safezoneX";
            y = "0.388 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class DAWN: RscADMPButton {
            idc = IDC_ADMINENV_DAWN;
            text = "DAWN";
            tooltip = "Puts this time in the combos - SET TIME applies it.";
            onButtonClick = QUOTE(['dawn'] call FUNC(envTimeOf););
            x = "0.338 * safezoneW + safezoneX";
            y = "0.424 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class NOON: RscADMPButton {
            idc = IDC_ADMINENV_NOON;
            text = "NOON";
            tooltip = "Puts this time in the combos - SET TIME applies it.";
            onButtonClick = QUOTE(['noon'] call FUNC(envTimeOf););
            x = "0.420 * safezoneW + safezoneX";
            y = "0.424 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class DUSK: RscADMPButton {
            idc = IDC_ADMINENV_DUSK;
            text = "DUSK";
            tooltip = "Puts this time in the combos - SET TIME applies it.";
            onButtonClick = QUOTE(['dusk'] call FUNC(envTimeOf););
            x = "0.502 * safezoneW + safezoneX";
            y = "0.424 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class MIDNIGHT: RscADMPButton {
            idc = IDC_ADMINENV_MIDNIGHT;
            text = "MIDNIGHT";
            tooltip = "Puts this time in the combos - SET TIME applies it.";
            onButtonClick = QUOTE(['midnight'] call FUNC(envTimeOf););
            x = "0.584 * safezoneW + safezoneX";
            y = "0.424 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class WEATHER_HEAD: RscADMPStructuredText {
            idc = IDC_ADMINENV_WEATHER_HEAD;
            text = "<t font='RobotoCondensedBold' size='0.7'>W E A T H E R</t>";
            x = "0.338 * safezoneW + safezoneX";
            y = "0.466 * safezoneH + safezoneY";
            w = "0.324 * safezoneW";
            h = "0.026 * safezoneH";
        };

        class OVERCAST_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINENV_OVERCAST_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>OVERCAST</t>";
            x = "0.338 * safezoneW + safezoneX";
            y = "0.494 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class RAIN_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINENV_RAIN_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>RAIN</t>";
            x = "0.420 * safezoneW + safezoneX";
            y = "0.494 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class FOG_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINENV_FOG_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>FOG</t>";
            x = "0.502 * safezoneW + safezoneX";
            y = "0.494 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class WIND_LABEL: RscADMPStructuredText {
            idc = IDC_ADMINENV_WIND_LABEL;
            text = "<t font='RobotoCondensed' size='0.75'>WIND</t>";
            x = "0.584 * safezoneW + safezoneX";
            y = "0.494 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.022 * safezoneH";
        };

        class OVERCAST: RscADMPCombo {
            idc = IDC_ADMINENV_OVERCAST;
            x = "0.338 * safezoneW + safezoneX";
            y = "0.518 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class RAIN: RscADMPCombo {
            idc = IDC_ADMINENV_RAIN;
            x = "0.420 * safezoneW + safezoneX";
            y = "0.518 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class FOG: RscADMPCombo {
            idc = IDC_ADMINENV_FOG;
            x = "0.502 * safezoneW + safezoneX";
            y = "0.518 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class WIND: RscADMPCombo {
            idc = IDC_ADMINENV_WIND;
            x = "0.584 * safezoneW + safezoneX";
            y = "0.518 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class CLEAR: RscADMPButton {
            idc = IDC_ADMINENV_CLEAR;
            text = "CLEAR";
            tooltip = "Puts this weather in the combos - SET WEATHER applies it.";
            onButtonClick = QUOTE(['clear'] call FUNC(envPreset););
            x = "0.338 * safezoneW + safezoneX";
            y = "0.556 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class CLOUDY: RscADMPButton {
            idc = IDC_ADMINENV_CLOUDY;
            text = "CLOUDY";
            tooltip = "Puts this weather in the combos - SET WEATHER applies it.";
            onButtonClick = QUOTE(['cloudy'] call FUNC(envPreset););
            x = "0.420 * safezoneW + safezoneX";
            y = "0.556 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class STORM: RscADMPButton {
            idc = IDC_ADMINENV_STORM;
            text = "STORM";
            tooltip = "Puts this weather in the combos - SET WEATHER applies it.";
            onButtonClick = QUOTE(['storm'] call FUNC(envPreset););
            x = "0.502 * safezoneW + safezoneX";
            y = "0.556 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class FOGGY: RscADMPButton {
            idc = IDC_ADMINENV_FOGGY;
            text = "FOG";
            tooltip = "Puts this weather in the combos - SET WEATHER applies it.";
            onButtonClick = QUOTE(['foggy'] call FUNC(envPreset););
            x = "0.584 * safezoneW + safezoneX";
            y = "0.556 * safezoneH + safezoneY";
            w = "0.078 * safezoneW";
            h = "0.030 * safezoneH";
        };

        class WEATHER_APPLY: RscADMPButton {
            idc = IDC_ADMINENV_WEATHER_APPLY;
            text = "SET WEATHER";
            tooltip = "Changes the weather for everybody, at once. Rain needs heavy overcast to fall.";
            colorBackground[] = {0.761, 0.659, 0.471, 1};
            colorText[] = {0.05, 0.05, 0.05, 1};
            onButtonClick = QUOTE(['weather'] call FUNC(envApply););
            x = "0.338 * safezoneW + safezoneX";
            y = "0.596 * safezoneH + safezoneY";
            w = "0.324 * safezoneW";
            h = "0.032 * safezoneH";
        };

        class NOTE: RscADMPStructuredText {
            idc = IDC_ADMINENV_NOTE;
            text = "<t font='RobotoCondensed' size='0.7'>A weather module in the mission may move the weather on again at its next cycle.</t>";
            x = "0.338 * safezoneW + safezoneX";
            y = "0.636 * safezoneH + safezoneY";
            w = "0.324 * safezoneW";
            h = "0.046 * safezoneH";
        };

        class CLOSE: RscADMPButton {
            idc = IDC_ADMINENV_CLOSE;
            text = "CLOSE";
            onButtonClick = QUOTE(closeDialog 2;);
            x = "0.338 * safezoneW + safezoneX";
            y = "0.690 * safezoneH + safezoneY";
            w = "0.324 * safezoneW";
            h = "0.032 * safezoneH";
        };
    };
};
