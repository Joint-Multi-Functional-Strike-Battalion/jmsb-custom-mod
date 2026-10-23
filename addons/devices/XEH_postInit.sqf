#include "script_component.hpp"

if (!hasInterface) exitWith {};

// THE KEY. Numpad 5 by default (docs/SPEC_TACNET.json D16: the numpad is the
// device's key block) - it was Ctrl+Home, cTab's chord, until the numpad
// replaced it (user, 2026-10-20). Configure Addons > 1st Joint
// Multi-Functional Strike Battalion. While the tablet is open the dialog has
// the keyboard, so FUNC(keyDown) closes it on the same binding. In a drone's
// seat (FUNC(uavControl)) the same key gives the seat back first - the tablet
// is the thing he flew it from, and the key he reaches for to get out.
[
    JMFSB_CATEGORY,
    QGVAR(tabletKey),
    ["Open Tablet", "Opens the tablet, in TABLET display mode; closes it when it is open. In a drone's seat it releases the drone instead. Also at the top of the ACE self-interaction menu. Numpad 5 by default."],
    {
        if (GVAR(uavActive)) exitWith {
            ["release"] call FUNC(uavControl);
            true
        };
        ["large"] call FUNC(toggle);
        true
    },
    {false},
    [KEY_TABLET, [false, false, false]]
] call CBA_fnc_addKeybind;

// ACE self-interaction > Tablet, at the top level (user: "needs to be top layer"). On the class, not the player
// object, so it survives a respawn. Shown only in tablet mode: in native mode
// the suite is on the map screen and there is no device to open.
//
// ACE is not required - the suite is assembled from whatever a mission has -
// so this is guarded rather than assumed, and the key is the way in without it.
if (!isNil "ace_interact_menu_fnc_createAction") then {
    private _action = [
        QGVAR(tablet), "Tablet", TABLET_ACTION_ICON,
        {["large"] call FUNC(open)},
        {HOST_DEVICE}
    ] call ace_interact_menu_fnc_createAction;
    // WITH INHERITANCE, or only a bare CAManBase gets it and no player is
    // one - every slot is a faction class. ACE defaults that argument to false.
    ["CAManBase", 1, ["ACE_SelfActions"], _action, true] call ace_interact_menu_fnc_addActionToClass;

    // VEHICLE TABLET, from any seat - driver, commander, gunner or passenger -
    // of a land vehicle, an aircraft or a boat. A self action on the vehicle's
    // class is shown to the men inside it; the condition keeps it to them and
    // to tablet mode. The vehicle is handed over so the bar and the ON BOARD
    // rail name the right one. A static weapon is a LandVehicle and a parachute
    // an Air to the engine, and neither is a vehicle with a tablet in it.
    private _vehicleTablet = [
        QGVAR(vehicleTablet), "Vehicle tablet", TABLET_ACTION_ICON,
        {[VEHICLE_DEVICE, _target] call FUNC(open)},
        {
            HOST_DEVICE
            && {_player in crew _target}
            && {(VEHICLE_TABLET_EXCLUDED findIf {_target isKindOf _x}) < 0}
        }
    ] call ace_interact_menu_fnc_createAction;
    {
        [_x, 1, ["ACE_SelfActions"], _vehicleTablet, true] call ace_interact_menu_fnc_addActionToClass;
    } forEach ["LandVehicle", "Air", "Ship"];
};

// THE WALKING VIEW - the phone and the side devices. One loop decides whether
// it should be up and keeps it drawn; see FUNC(overlayTick). The key hides and
// shows it; everything else about it - shown, a side device's edge, sizes,
// zoom, opacity - is set on the tablet, SETTINGS > DEVICES (FUNC(settingsRows)),
// not in the ACE menu. Cut at mission end because a title layer does not go
// down on its own.
[{[] call FUNC(overlayTick)}, OVERLAY_TICK, []] call CBA_fnc_addPerFrameHandler;

// DRONE CONTROL WITHOUT A UAV TERMINAL: the link and the seat are let go of
// on death, a lost DATA link, a lost seat and the rest (FUNC(uavTick)), and
// the seat is given back before the mission ends under it.
[{[] call FUNC(uavTick)}, UAV_TICK, []] call CBA_fnc_addPerFrameHandler;
addMissionEventHandler ["Ended", {["release"] call FUNC(uavControl)}];
addMissionEventHandler ["Ended", {[] call FUNC(overlayClose)}];

// RF raises this on a client as each new slice of his links lands - before it
// has finished indexing that slice, so only a flag is set here and the tick
// reads RF afterwards (FUNC(overlayRf)).
[QEGVAR(rf,linkChanged), {GVAR(overlayRfDirty) = true}] call CBA_fnc_addEventHandler;

// THE PLAYER'S OWN TRANSMISSION, for the squad list's TX and the talking box:
// the voice API's talking list is who he HEARS, so his own comes off its talk
// event (FUNC(voiceTalkers)).
[QEGVAR(voice,talk), {
    params [["_unit", objNull, [objNull]], ["_netId", "", [""]], ["_on", false, [false]]];
    if (_unit isEqualTo (call CBA_fnc_currentUnit)) then {
        GVAR(talkSelf) = ["", _netId] select _on;
    };
}] call CBA_fnc_addEventHandler;

// A CALL'S LAST WORD - a failure reason, the priority warning, its end - for
// the notification line (FUNC(voiceLine)).
[QEGVAR(voice,callState), {
    params ["", ["_state", "", [""]]];
    GVAR(callLast) = [_state, CBA_missionTime];
}] call CBA_fnc_addEventHandler;

// YOUR OWN TRANSMISSION shows at once (user, 2026-10-21: "need feedback that
// you're talking on a net"): the net chip you key goes red with TX
// (FUNC(overlayNets)), redrawn on the key, not on the next tick.
[QEGVAR(voice,talk), {
    params [["_unit", objNull, [objNull]]];
    if (_unit isEqualTo (call CBA_fnc_currentUnit)) then {[] call FUNC(overlayTick)};
}] call CBA_fnc_addEventHandler;

// RAISING A SIGHT takes the walking view down at once, not on the next tick
// (FUNC(overlayHidden)); lowering it puts it back the same way.
["cameraView", {[] call FUNC(overlayTick)}] call CBA_fnc_addPlayerEventHandler;

// A RING OR A CALL CHANGING STATE redraws the walking view at once - the RING
// cell, the notification line, the RADIO app - rather than on the next tick.
{
    [_x, {[] call FUNC(overlayTick)}] call CBA_fnc_addEventHandler;
} forEach [QEGVAR(voice,callRing), QEGVAR(voice,callState), QEGVAR(voice,netsChanged)];

[
    JMFSB_CATEGORY,
    QGVAR(overlayKey),
    ["Toggle Device", "Hides the phone or side device in the GPS slot, and shows it again. Ctrl+End by default."],
    {
        [] call FUNC(overlayToggle);
        true
    },
    {false},
    [DIK_END, [false, true, false]]
] call CBA_fnc_addKeybind;

// THE SIX BUTTONS PRINTED ON THE DEVICE FRAMES - F1-F4, LEFT, RIGHT - on the
// numpad by default: Ctrl + 1-4 and 0 / . (docs/SPEC_TACNET.json D16; user,
// 2026-10-20: "we are not using keyboard F1-F4, we are using numpad";
// 2026-10-21: "make the f keys on the devices be numpad + ctrl" - plain 1-4
// are SELECT NET 1-4 now). The
// walking view is a title layer and takes no mouse, so each is a keybind,
// named for its printed label. On the walking view each does the player's
// setting (jmfsb_devices_buttonF1 ..; the voice keys by default) or, while the
// RADIO app is open there, its soft keys and cursor (FUNC(overlayButton)). On
// the tablet the same bindings press the tablet frame's keys (FUNC(keyDown)).
{
    [
        JMFSB_CATEGORY,
        format ["%1_%2", QGVAR(button), _x],
        [format ["Device button %1", _x], "Presses this key on the device frame. Walking view: what Addon Options or the tablet's SETTINGS > DEVICE KEYS set it to (the voice keys by default), or the RADIO app's soft keys and cursor while it is open. Tablet: the frame's own key."],
        compile format ["[%1] call %2", _forEachIndex, QFUNC(overlayButton)],
        {false},
        [BUTTON_KEYS select _forEachIndex, [BUTTON_MODS_ARROW, BUTTON_MODS_F] select (_forEachIndex < BUTTON_F_COUNT)]
    ] call CBA_fnc_addKeybind;
} forEach BUTTON_LABELS;

// SELECT NET 1-9: the number on a net chip is its key (user, 2026-10-21).
// Numpad 1-4 for the first four; 5-9 start unbound, because numpad 5-9 are
// the tablet, RADIO, its tabs and TIC - bind them in Configure Addons.
for "_i" from 1 to NET_SELECT_KEYS do {
    [
        JMFSB_CATEGORY,
        format ["%1_%2", QGVAR(netSelect), _i],
        [format ["Select net %1", _i], format ["Makes net %1 - the chip numbered %1 on the phone, side device or tablet - your active net.", _i]],
        compile format ["[%1] call %2", _i, QFUNC(netSelect)],
        {false},
        [NET_SELECT_DEFAULTS param [_i - 1, -1], [false, false, false]]
    ] call CBA_fnc_addKeybind;
};

// THE REST OF THE NUMPAD BLOCK. 6 opens and closes the RADIO app full screen
// on the carried phone or side device; 7 / 8 step its tabs. On the tablet
// FUNC(keyDown) answers the same bindings for the tablet's RADIO app.
[
    JMFSB_CATEGORY,
    QGVAR(radioAppKey),
    ["Device RADIO app", "Opens or closes the RADIO app on the phone or side device in the GPS slot (on the tablet while it is open: its RADIO app). Numpad 6 by default."],
    {
        if (isNull (uiNamespace getVariable [QGVAR(overlayDisplay), displayNull])) exitWith {false};
        [] call FUNC(radioApp);
        true
    },
    {false},
    [KEY_RADIO_APP, [false, false, false]]
] call CBA_fnc_addKeybind;

{
    _x params ["_action", "_title", "_code", "_key"];
    [
        JMFSB_CATEGORY,
        _action,
        [_title, "Steps the RADIO app's tabs - NETS, CALLS, MANAGE - on the phone or side device while it is open, and on the tablet."],
        compile format ["[%1] call %2", _code, QFUNC(radioKey)],
        {false},
        [_key, [false, false, false]]
    ] call CBA_fnc_addKeybind;
} forEach [
    [QGVAR(tabPrev), "Device previous tab", RADIO_TAB_PREV, KEY_TAB_PREV],
    [QGVAR(tabNext), "Device next tab", RADIO_TAB_NEXT, KEY_TAB_NEXT]
];

// A size change relays the device out. The map and the frame are placed by
// FUNC(layout) at open and nothing already on screen can grow by being
// repainted - so the dialog is closed and opened again at the new size.
[QGVAR(tabletFill_changed), {
    if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};
    private _device = GVAR(device);
    private _vehicle = GVAR(vehicle);
    [] call FUNC(close);
    [{_this call FUNC(open)}, [_device, _vehicle]] call CBA_fnc_execNextFrame;
}] call CBA_fnc_addEventHandler;

// A DISPLAY MODE CHANGE CLOSES THE TABLET. The shell's own handler has already
// taken the suite down and given the host back, so whatever the new mode is,
// the dialog is a frame round a map with nothing hosted in it. Closed here, its
// onUnload stops the row tick; the next open builds for the new mode.
[QEGVAR(tacpad,displayMode_changed), {[] call FUNC(close)}] call CBA_fnc_addEventHandler;
