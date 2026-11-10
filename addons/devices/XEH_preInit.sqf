#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// THE KEY LAYOUT (GVAR(keyLayout), KEY_LAYOUT_TABLE): each device key's
// default for the layout picked (FUNC(keyDefault)), and the other layout's,
// which a stored bind may still hold.
if (isNil QGVAR(keyLayout)) then {GVAR(keyLayout) = KEY_LAYOUT_F};
private _fRow = GVAR(keyLayout) isNotEqualTo KEY_LAYOUT_NUMPAD;
GVAR(keyDefaults) = createHashMap;
private _otherLayout = createHashMap;
private _fnc_layoutKey = {
    params ["_action", "_fBind", "_padBind"];
    GVAR(keyDefaults) set [toLower _action, [_padBind, _fBind] select _fRow];
    _otherLayout set [toLower _action, [_fBind, _padBind] select _fRow];
};
{_x call _fnc_layoutKey} forEach KEY_LAYOUT_TABLE;
for "_i" from 1 to NET_SELECT_KEYS do {
    private _fKey = KEY_LAYOUT_NETS_F param [_i - 1, KEY_NONE];
    private _padKey = NET_SELECT_DEFAULTS param [_i - 1, KEY_NONE];
    [format ["%1_%2", QGVAR(netSelect), _i], [_fKey, KEY_MODS_SHIFT], [_padKey, NET_SELECT_MODS]] call _fnc_layoutKey;
    [format ["%1_%2", QGVAR(netMute), _i], [_fKey, NET_MUTE_MODS], [_padKey, NET_MUTE_MODS]] call _fnc_layoutKey;
};

// THE PROFILE'S OLD DEFAULTS MOVE TO TODAY'S (KEYBIND_MIGRATIONS, and the
// other key layout's defaults): here, before any addon registers a keybind,
// since CBA reads the profile's registry as each one does. A bind that is
// empty or one of the old defaults was never the player's choice; a key the
// layout names moves to that layout's default.
if (hasInterface) then {
    private _registry = profileNamespace getVariable [CBA_KEYBIND_REGISTRY, []];
    if !([_registry] call CBA_fnc_isHash) exitWith {};
    private _moves = createHashMap;
    {
        _x params ["_action", "_olds", "_new"];
        _moves set [toLower _action, [_olds, _new]];
    } forEach KEYBIND_MIGRATIONS;
    {
        (_moves getOrDefault [_x, [[], _y]]) params ["_olds"];
        _moves set [_x, [_olds + [_otherLayout get _x], _y]];
    } forEach GVAR(keyDefaults);
    private _moved = [];
    {
        _y params ["_olds", "_new"];
        private _key = toLower format ["%1$%2", JMFSB_CATEGORY, _x];
        private _stored = [_registry, _key] call CBA_fnc_hashGet;
        if (isNil "_stored" || {!(_stored isEqualType [])} || {_stored isEqualTo [_new]}) then {continue};
        private _live = _stored select {_x isEqualType [] && {(_x param [0, 0]) > DIK_ESCAPE}};
        if (_live isEqualTo [] || {(_olds findIf {_live isEqualTo [_x]}) >= 0}) then {
            [_registry, _key, [_new]] call CBA_fnc_hashSet;
            _moved pushBack _x;
        };
    } forEach _moves;
    if (_moved isNotEqualTo []) then {
        profileNamespace setVariable [CBA_KEYBIND_REGISTRY, _registry];
        saveProfileNamespace;
        INFO_2("keybinds moved to the %1 layout: %2",GVAR(keyLayout),_moved);
    };
};

// Which frame the dialog is wearing, and for the vehicle tablet which vehicle.
// Set by FUNC(open) before createDialog, because the dialog's onLoad has no
// arguments of its own to be told with.
GVAR(device) = "large";
GVAR(vehicle) = objNull;

// THE TABLET SCREEN'S ROWS: the tick that redraws them (FUNC(tabletChrome)),
// and the time of the newest notification the player has seen - clicking the
// notification line opens the log and moves it (FUNC(tabletLog)).
GVAR(tabletPFH) = -1;
GVAR(notifySeen) = -1;

// VEHICLE STATUS's refresh loop (FUNC(appVehicle)). In missionNamespace, not
// uiNamespace: CBA numbers its handlers afresh each mission, so a handle that
// outlived one would name - and remove - somebody else's loop in the next.
GVAR(vehiclePFH) = -1;

// ON BOARD, the vehicle tablet's left rail in place of the squad rail. A shell
// panel like the rail, so it is placed, refreshed and hidden behind apps the
// same way; it exists only on the vehicle tablet, and only the vehicle
// tablet's layout table gives it a place (TABLET_PLACES_VEHICLE).
["onboard", "ON BOARD", TABLET_RAIL, FUNC(panelOnBoard), FUNC(panelOnBoard), 2, true, {
    HOST_DEVICE && GVAR(device) isEqualTo VEHICLE_DEVICE
}] call EFUNC(tacpad,register);

// VEHICLE STATUS's live tile, offered to tacpad_apps' band. It answers no
// tile unless the vehicle tablet is up (FUNC(vehicleTile)); the app behind it
// is registered with the shell only while it is (FUNC(onLoad)).
EGVAR(tacpad_apps,tileProviders) set [VEHICLE_APP, FUNC(vehicleTile)];
// The vehicle tablet is its gate, not the role: a mission's role tiles[] would
// otherwise hide it from every crew, while the arrows and F-keys still open it.
EGVAR(tacpad_apps,tileUngated) pushBackUnique VEHICLE_APP;

// THE WALKING VIEW'S STATE. Shown is the toggle key's answer and edge is where
// a side device goes; both are the player's, kept in his profile
// (FUNC(overlaySetShown), FUNC(overlaySetEdge)) and set on the tablet,
// SETTINGS > DEVICES. The key is what the layer was last placed for, so a tick
// only re-lays it out when the device, the edge, the size, the opacity or the
// scheme has changed.
GVAR(overlayShown) = profileNamespace getVariable [QGVAR(overlayShown), true];
if !(GVAR(overlayShown) isEqualType true) then {GVAR(overlayShown) = true};
GVAR(overlayEdge) = profileNamespace getVariable [QGVAR(overlayEdge), EDGES select 0];
if !(GVAR(overlayEdge) in EDGES) then {GVAR(overlayEdge) = EDGES select 0};
GVAR(overlayKey) = "";

// THE NET BUTTONS (user, 2026-11-07): which net sits on each of the twelve
// (QUICK 1-4, page 2, page 3), the player's, kept in his profile and set on
// the tablet's RADIO app (FUNC(netAssign)); NET_BUTTON_AUTO for AUTO. A
// stored value of the wrong shape starts over all AUTO. The page the net rows
// show is this session's only (FUNC(netButtons), FUNC(netPageStep)).
GVAR(netButtons) = [];
for "_i" from 1 to NET_BUTTONS do {GVAR(netButtons) pushBack NET_BUTTON_AUTO};
private _stored = profileNamespace getVariable [QGVAR(netButtons), []];
// NET_BUTTONS strings, or it starts over; a longer list from when there were
// twelve buttons keeps its first eight (2026-11-08)
if (_stored isEqualType [] && {count _stored >= NET_BUTTONS}) then {
    _stored = _stored select [0, NET_BUTTONS];
    if (_stored isEqualTypeArray GVAR(netButtons)) then {GVAR(netButtons) = _stored};
};
GVAR(netPage) = 0;

// THE TABLET'S SETTINGS PAGE carries the phone and side devices' settings -
// they have no ACE menu of their own. Two sections in its rail, rows from
// FUNC(settingsRows), drawn by jmfsb_tacpad_apps_fnc_appSettings.
EGVAR(tacpad_apps,settingsSections) pushBack ["devices", "DEVICES", {["devices"] call FUNC(settingsRows)}];
EGVAR(tacpad_apps,settingsSections) pushBack ["devkeys", "DEVICE KEYS", {["devkeys"] call FUNC(settingsRows)}];

// THE STATUS ROW'S PROVIDERS: label -> code answering [text, value, state].
// Built here so another addon can add or replace one in its own postInit; the
// order is the row's, left to right.
GVAR(overlayProviders) = [] call FUNC(overlayProviders);
// BATT between GPS and DRONES (user, 2026-10-30: the battery % on the phone).
// NO NET CELL (user, 2026-10-31: "do we need net% any more" - no: it gauged
// the game VON's ten custom channels, and the voice server has no such
// count). The provider stays for a VON-fallback mission to add back.
// NO GPS CELL (user, 2026-11-01: "Drop GPS, space the rest"). The provider
// stays, like NET's, for a mission or addon to put back in the order.
GVAR(overlayOrder) = ["MESH", "JAM", "BATT", "DRONES", "MSG"];
// The shown device's class (FUNC(deviceClass)), set by FUNC(overlayPlace);
// the rows switch on it (FUNC(overlayRows)).
GVAR(overlayClass) = "";

// RF's summary for the walking view (FUNC(overlayRf)), rebuilt by the tick
// whenever jmfsb_rf_linkChanged has marked it dirty; and the last man heard,
// [unit, voice, time], for the talking chip (FUNC(overlayTalker)).
GVAR(overlayRf) = createHashMap;
GVAR(overlayRfDirty) = true;
GVAR(overlayTalker) = [objNull, 0, 0, ""];
// The EMCON level the RF summary was last built with (FUNC(emconLevel)); a
// new one off jmfsb_ew's slice marks the summary dirty (XEH_postInit).
GVAR(emconSeen) = 0;
// DRONE MARKS on the walking view's map: [accent, [[drone, callsign], ...]]
// (FUNC(overlayDrones)), re-read by the tick at this mission time, drawn each
// frame (FUNC(overlayDrawDrones)) with the mil_circle marker's texture.
GVAR(overlayDrones) = [[0, 0, 0, 0], []];
GVAR(overlayDronesNext) = 0;
GVAR(droneIcon) = getText (configFile >> "CfgMarkers" >> DRONE_MARK_MARKER >> "icon");

// GAME VOICE ON THE DEVICES (docs/DESIGN_VOICE.md). The net the player is
// transmitting on, "" when he is not (off jmfsb_voice_talk, XEH_postInit); the
// last state a call reached, [state, time], for the notification line
// (FUNC(voiceLine), off jmfsb_voice_callState); and
// the talking table built once a frame from it and the voice API
// (FUNC(voiceTalkers)). The small devices' RADIO app - open, its tab, its
// cursor, whether the cursor is on the group chips (FUNC(radioApp)) - and the
// walking view's F2 quick-add list and its cursor (FUNC(voiceAction)).
GVAR(talkSelf) = "";
GVAR(callLast) = ["", -1];
GVAR(talkersCache) = [-1, createHashMap];
GVAR(radioOpen) = false;
// Screens other addons put over the walking view's map, id -> draw code
// (FUNC(overlayDraw)) - the AiTR patient vitals set one.
GVAR(overlayScreens) = createHashMap;
// Addons that take the walking view's keys while they are on, id -> code
// (FUNC(overlayButton)) - the watch HUD sets one.
GVAR(buttonHooks) = createHashMap;
GVAR(radioTab) = "nets";
GVAR(radioCursor) = 0;
GVAR(radioGroupMode) = false;
GVAR(quickOpen) = false;
GVAR(quickCursor) = 0;

// DRONE CONTROL WITHOUT A UAV TERMINAL (FUNC(uavControl)): the drone linked,
// whether a seat in it is held, which seat in which drone, the release action
// on it, and the view the player left in.
GVAR(uavLinked) = objNull;
GVAR(uavActive) = false;
GVAR(uavSeat) = objNull;
GVAR(uavFlying) = objNull;
GVAR(uavAction) = -1;
GVAR(uavView) = UAV_VIEW_DRIVER;

// DRONE ORDERS land on the machine that owns the drone's group - the server
// for most UAV crews, the launcher's client for a hand-thrown one - by
// remoteExec through the server, which checks the sender (FUNC(uavOrder),
// review S7); no CBA event. Which weapon of a class is its laser designator,
// worked out once per class.
GVAR(uavLaserCache) = createHashMap;

ADDON = true;
