#include "script_component.hpp"
/*
 * Author: JMSB
 * Paints and sizes the console from the player's tacpad settings.
 *
 * WHY A FUNCTION AND NOT CONFIG. The colours in ui\dialog.inc.hpp are the dark
 * scheme, written once so the display never flashes a wrong colour on the way
 * up. Everything a player can actually change - which of the seven schemes, how
 * solid the ground is, how big the whole thing should be - lives in the tacpad's
 * CBA settings, and a config file cannot read those. So the display opens, and
 * the first thing it does is repaint itself in whatever the player picked.
 *
 * THE SCALE IS APPLIED ABOUT THE CENTRE OF THE SCREEN. A console shrunk from the
 * top-left corner drifts off toward it; shrunk about the middle it stays a
 * console, just smaller, with a margin round it. Type is scaled with the boxes -
 * a smaller console with the same size text is a cramped console, not a small
 * one.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_style
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

// The ground the console is painted on. The tacpad's own opacity setting, given
// a floor: this screen covers the world completely, and a see-through admin
// console with a firefight visible behind it is unreadable in a way a panel over
// a map is not.
// SETTINGS MAY NOT BE IN YET. A keybind pressed in the first seconds of a
// mission gets here before CBA_settingsInitialized, and a bare EGVAR read then
// is an undefined-variable error rather than a default. Both are read through
// their defaults for that one case.
private _opacity = ((missionNamespace getVariable [QEGVAR(tacpad,opacity), 0.92]) max 0.88) min 1;
private _base = [_ground # 0, _ground # 1, _ground # 2, _opacity];

// A block sits slightly off the ground so the regions read as regions without a
// rule round every one of them. Lifted toward the ink, which keeps it correct on
// a light scheme as well as a dark one.
private _lift = [
    ((_ground # 0) * 0.82) + ((_ink # 0) * 0.18),
    ((_ground # 1) * 0.82) + ((_ink # 1) * 0.18),
    ((_ground # 2) * 0.82) + ((_ink # 2) * 0.18),
    _opacity
];

private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

// ---------------------------------------------------------------- the paint --
{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetBackgroundColor _base};
} forEach [IDC_ADMINPANEL_BACKGROUND];

// The blocks: the four rails on the right and the plates behind the toggles.
// The toggle plates are ONLY set here when they are off - fn_updateToggleControls
// owns them the rest of the time and repaints them every tick.
{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetBackgroundColor _lift};
} forEach [
    IDC_ADMINPANEL_PLAYER_INFO_BACK,
    IDC_ADMINPANEL_PLAYER_SKILLS_BACK,
    IDC_ADMINPANEL_PLAYER_VEHICLE_BACK,
    IDC_ADMINPANEL_PLAYER_MEDICAL_BACK,
    IDC_ADMINPANEL_PLAYER_CAMDISPLAY_BACK,
    IDC_ADMINPANEL_REMOTEEXEC_SERVEREXEC_BACK,
    IDC_ADMINPANEL_REMOTEEXEC_LOCALEXEC_BACK,
    IDC_ADMINPANEL_REMOTEEXEC_EXECBUTTON_BACK
];

// The loud ones. BAN, APPLY, HEAL FULL, RUN and the admin chip are the controls
// the design fills solid - three of them because they cannot be undone and two
// because they are the point of the screen they are on.
{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetBackgroundColor _accent};
} forEach [
    IDC_ADMINPANEL_ADMIN_BAN_BACK,
    IDC_ADMINPANEL_HEADER_ADMINCHIP
];

{
    private _ctrl = _display displayCtrl _x;
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetBackgroundColor _accent;
    _ctrl ctrlSetTextColor _ground;
} forEach [
    IDC_ADMINPANEL_PLAYER_SKILLS_APPLY_BUTTON,
    IDC_ADMINPANEL_PLAYER_MEDICAL_FULLHEAL,
    IDC_ADMINPANEL_REMOTEEXEC_EXECBUTTON
];

// Everything that takes typing or a selection: the list, the filter, the code
// box, the return log and the four combos. One ground, one ink, one selection
// colour, so a dropdown does not look like it came from another mod.
{
    private _ctrl = _display displayCtrl _x;
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetBackgroundColor _lift;
    _ctrl ctrlSetTextColor _ink;
} forEach [
    IDC_ADMINPANEL_PLAYERLIST_LISTBOX,
    IDC_ADMINPANEL_PLAYERLIST_FILTER,
    IDC_ADMINPANEL_REMOTEEXEC_EDITBOX,
    IDC_ADMINPANEL_REMOTEEXEC_RETURN,
    IDC_ADMINPANEL_ADMIN_RANK_COMBO,
    IDC_ADMINPANEL_MISSION_ENDCOMBO
];

// The plain readouts. Text only - their grounds are the blocks behind them.
{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetTextColor _ink};
} forEach [
    IDC_ADMINPANEL_PLAYER_INFO_NAME,
    IDC_ADMINPANEL_PLAYER_INFO_SIDE,
    IDC_ADMINPANEL_PLAYER_INFO_VEHICLE_INFO,
    IDC_ADMINPANEL_PLAYER_MEDICAL_HEART,
    IDC_ADMINPANEL_PLAYER_MEDICAL_BLDPRES,
    IDC_ADMINPANEL_PLAYER_MEDICAL_BLDVOL,
    IDC_ADMINPANEL_PLAYER_MEDICAL_PAIN,
    IDC_ADMINPANEL_PLAYER_MEDICAL_SP02,
    IDC_ADMINPANEL_PLAYER_MEDICAL_BLOOD
];

// The grid is the one readout in the accent, because it is the one an admin
// reads out loud.
{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetTextColor _accent};
} forEach [IDC_ADMINPANEL_PLAYER_INFO_GRID];

// The outlined buttons - everything that is not filled. Text in the ink, ground
// transparent so the block or the plate behind shows through, and the hover
// state in the accent.
{
    private _ctrl = _display displayCtrl _x;
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetTextColor _ink;
    _ctrl ctrlSetActiveColor _accent;
} forEach [
    IDC_ADMINPANEL_UTILITIES_GODMODE,
    IDC_ADMINPANEL_UTILITIES_INFAMMO,
    IDC_ADMINPANEL_UTILITIES_JMFSB,
    IDC_ADMINPANEL_UTILITIES_ARSENAL,
    IDC_ADMINPANEL_ADMIN_SPECTATE,
    IDC_ADMINPANEL_ADMIN_ZEUS,
    IDC_ADMINPANEL_ADMIN_KICK,
    IDC_ADMINPANEL_ADMIN_SERVERLOCK,
    IDC_ADMINPANEL_ADMIN_PAC,
    IDC_ADMINPANEL_ADMIN_ROLEACCESS,
    IDC_ADMINPANEL_ADMIN_SERVERHEALALL,
    IDC_ADMINPANEL_ADMIN_MESSAGE,
    IDC_ADMINPANEL_ADMIN_PROMOTE,
    IDC_ADMINPANEL_PLAYER_VEHICLE_DISMOUNT,
    IDC_ADMINPANEL_PLAYER_VEHICLE_UNSTUCK,
    IDC_ADMINPANEL_PLAYER_MEDICAL_WAKEUP,
    IDC_ADMINPANEL_PLAYER_CAMDISPLAY_VIEWMODE,
    IDC_ADMINPANEL_PLAYER_CAMDISPLAY_VISMODE,
    IDC_ADMINPANEL_MAP_TAB_PLAYERS,
    IDC_ADMINPANEL_MAP_TAB_VEHICLES,
    IDC_ADMINPANEL_MAP_TAB_AI,
    IDC_ADMINPANEL_MAP_TAB_MARKERS,
    IDC_ADMINPANEL_REMOTEEXEC_SERVEREXEC,
    IDC_ADMINPANEL_REMOTEEXEC_LOCALEXEC,
    IDC_ADMINPANEL_REMOTEEXEC_EXECBUTTON,
    IDC_ADMINPANEL_REMOTEEXEC_CLEAR
];

// END MISSION is a word in the accent on a transparent ground - loud enough to
// find, quiet enough that a mouse passing over it is not alarming. It is the one
// control on the screen that ends everybody's evening.
{
    private _ctrl = _display displayCtrl _x;
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetTextColor _accent;
    _ctrl ctrlSetActiveColor _accent;
} forEach [IDC_ADMINPANEL_MISSION_ENDBUTTON];

// The kickers - every micro-label above a block. Muted, because a label that is
// as loud as the number under it is a label competing with its own value.
{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetTextColor _mute};
} forEach [
    IDC_ADMINPANEL_HEADER_SUBTITLE,
    IDC_ADMINPANEL_MAP_CURSOR,
    IDC_ADMINPANEL_MISSION_LOADED_LABEL,
    IDC_ADMINPANEL_PLAYER_VEHICLE_SERVICE_LABEL,
    IDC_ADMINPANEL_PLAYER_VEHICLE_NOTE,
    IDC_ADMINPANEL_REMOTEEXEC_HINT,
    IDC_ADMINPANEL_REMOTEEXEC_HISTORY_LABEL,
    IDC_ADMINPANEL_ADMIN_RANK_LABEL
];

// The section headings, and the labels beside the skill checkboxes. Full ink -
// these ARE the readout, not a caption over one.
{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetTextColor _ink};
} forEach [
    IDC_ADMINPANEL_MAIN_TITLE,
    IDC_ADMINPANEL_PLAYERLIST_TITLE,
    IDC_ADMINPANEL_PLAYERLIST_COUNT,
    IDC_ADMINPANEL_UTILITIES_TITLE,
    IDC_ADMINPANEL_ADMIN_TITLE,
    IDC_ADMINPANEL_MISSION_TITLE,
    IDC_ADMINPANEL_MAP_DESCRIPTION,
    IDC_ADMINPANEL_REMOTEEXEC_HEADING,
    IDC_ADMINPANEL_REMOTEEXEC_RETURN_HEAD,
    IDC_ADMINPANEL_PLAYER_CAMDISPLAY_TITLE,
    IDC_ADMINPANEL_PLAYER_CAMDISPLAY_READOUT,
    IDC_ADMINPANEL_PLAYER_INFO_TITLE,
    IDC_ADMINPANEL_PLAYER_SKILLS_TITLE,
    IDC_ADMINPANEL_PLAYER_VEHICLE_TITLE,
    IDC_ADMINPANEL_PLAYER_MEDICAL_TITLE,
    IDC_ADMINPANEL_PLAYER_VEHICLE_REPTEXT,
    IDC_ADMINPANEL_PLAYER_VEHICLE_REFTEXT,
    IDC_ADMINPANEL_PLAYER_VEHICLE_REATEXT,
    IDC_ADMINPANEL_PLAYER_SKILLS_CLS_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_MED_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_ENG_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_EOD_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_ISR_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_JFO_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_UAV_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_MKS_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_SNP_LABEL,
    IDC_ADMINPANEL_PLAYER_SKILLS_HVY_LABEL,
    IDC_ADMINPANEL_ADMIN_SERVERFPS,
    IDC_ADMINPANEL_ADMIN_ACTIVEAI,
    IDC_ADMINPANEL_HEADER_PLAYERCOUNT,
    IDC_ADMINPANEL_PLAYER_INFO_FPS,
    IDC_ADMINPANEL_PLAYER_MEDICAL_STATUS
];

// The wordmark, written here rather than in config - see ui\dialog.inc.hpp.
private _title = _display displayCtrl IDC_ADMINPANEL_MAIN_TITLE;
if (!isNull _title) then {
    _title ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensedBold' size='1.5' color='%1'>TAC//ADMIN</t>",
        _ink call BIS_fnc_colorRGBAtoHTML
    ];
};

// Who is at the console, in the chip. A screen this destructive should always
// be able to answer "who was on it" without anybody having to remember.
private _chip = _display displayCtrl IDC_ADMINPANEL_HEADER_ADMINCHIP;
if (!isNull _chip) then {
    _chip ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensedBold' size='0.8' align='center' color='%1'>ADMIN  %2</t>",
        _ground call BIS_fnc_colorRGBAtoHTML,
        toUpper ([name player] call EFUNC(tacpad,xmlSafe))
    ];
};

// The two strips that say which of their buttons is the chosen one. Painted
// here as well as on every press, so the console opens showing its own state
// rather than four identical buttons.
[] call FUNC(mapTabs);
[] call FUNC(execTabs);

// ---------------------------------------------------------------- the scale --
// ON THE TABLET IT IS THE TABLET'S SCREEN, not the monitor and not the UI
// scale - see FUNC(fitHost).
if ([_display] call FUNC(fitHost)) exitWith {};

private _scale = missionNamespace getVariable [QEGVAR(tacpad,uiScale), 1];
if (_scale isEqualTo 1) exitWith {};

private _cx = safeZoneX + safeZoneW / 2;
private _cy = safeZoneY + safeZoneH / 2;
private _fontBase = 0.8 * (0.025 * safeZoneH);

{
    // The ground is the screen and stays the screen. Scaling it would leave a
    // hole round the edges with the world showing through, which is the one
    // thing this display is for covering.
    if (ctrlIDC _x isEqualTo IDC_ADMINPANEL_BACKGROUND) then {continue};

    (ctrlPosition _x) params ["_x0", "_y0", "_w0", "_h0"];
    _x ctrlSetPosition [
        _cx + (_x0 - _cx) * _scale,
        _cy + (_y0 - _cy) * _scale,
        _w0 * _scale,
        _h0 * _scale
    ];

    // Type with the boxes. There is no getter for a control's font height, so
    // the base is the one every control in ui\controls.inc.hpp is set to and the
    // inline <t size='...'> multipliers ride on top of it - which is why the
    // templates all carry the SAME sizeEx and vary by tag instead.
    _x ctrlSetFontHeight (_fontBase * _scale);

    _x ctrlCommit 0;
} forEach (allControls _display);
