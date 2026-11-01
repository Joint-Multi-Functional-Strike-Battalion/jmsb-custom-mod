#include "script_component.hpp"

if (!hasInterface) exitWith {};

// THE PROFILE'S OLD DEFAULTS MOVE TO TODAY'S (KEYBIND_MIGRATIONS,
// script_component.hpp): before any keybind below registers, since CBA reads
// the profile's registry as each one does. A bind that is empty or one of
// the old defaults was never the player's choice.
private _registry = profileNamespace getVariable [CBA_KEYBIND_REGISTRY, []];
if ([_registry] call CBA_fnc_isHash) then {
    private _moved = [];
    {
        _x params ["_action", "_olds", "_new"];
        private _key = toLower format ["%1$%2", JMFSB_CATEGORY, _action];
        private _stored = [_registry, _key] call CBA_fnc_hashGet;
        if (isNil "_stored" || {!(_stored isEqualType [])} || {_stored isEqualTo [_new]}) then {continue};
        private _live = _stored select {_x isEqualType [] && {(_x param [0, 0]) > DIK_ESCAPE}};
        if (_live isEqualTo [] || {(_olds findIf {_live isEqualTo [_x]}) >= 0}) then {
            [_registry, _key, [_new]] call CBA_fnc_hashSet;
            _moved pushBack _action;
        };
    } forEach KEYBIND_MIGRATIONS;
    if (_moved isNotEqualTo []) then {
        profileNamespace setVariable [CBA_KEYBIND_REGISTRY, _registry];
        saveProfileNamespace;
        INFO_1("keybinds moved to the numpad standard: %1",_moved);
    };
};

// THE KEY. Numpad Enter by default (2026-10-30, with 6-9 the device keys; it
// was 8 from the 2026-10-25 standard, 5 before that, and Ctrl+Home, cTab's
// chord, until the numpad replaced it on 2026-10-20; docs/SPEC_TACNET.json
// D16: the numpad is the device's key block). Configure Addons > 1st Joint
// Multi-Functional Strike Battalion. While the tablet is open the dialog has
// the keyboard, so FUNC(keyDown) closes it on the same binding. In a drone's
// seat (FUNC(uavControl)) the same key gives the seat back first - the tablet
// is the thing he flew it from, and the key he reaches for to get out.
[
    JMFSB_CATEGORY,
    QGVAR(tabletKey),
    ["Open Tablet", "Opens the tablet, in TABLET display mode; closes it when it is open. In a drone's seat it releases the drone instead. Also at the top of the ACE self-interaction menu. Numpad Enter by default."],
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

// A RING IS SAID ON THE SCREEN, not only on the call strip (user, 2026-10-24:
// "a pop up on the phone that says press something maybe 9 on the key pad to
// answer"): a notification names the caller and the keys as he has them
// bound - the TIC key answers while a call rings (FUNC(voiceAnswer)), the
// device F4 key declines.
[QEGVAR(voice,callRing), {
    params ["", ["_from", objNull, [objNull]]];
    if (isNil QEFUNC(notify,notify)) exitWith {};
    [
        "CALL",
        format [
            "Incoming from %1 - %2 to answer%3.",
            [name _from, "?"] select (isNull _from),
            [QGVAR(answerKey)] call FUNC(keyLabel),
            [
                format [", %1 to decline", [QGVAR(declineKey)] call FUNC(keyLabel)], ""
            ] select (([QGVAR(declineKey)] call FUNC(keyLabel)) in [KEY_LABEL_UNBOUND, KEY_LABEL_NONE])
        ],
        RING_NOTIFY_COLOUR
    ] call EFUNC(notify,notify);
}] call CBA_fnc_addEventHandler;

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

// THE SIX BUTTONS PRINTED ON THE DEVICE FRAMES - F1-F4, LEFT, RIGHT. The
// arrows are numpad 0 / .; F1-F4 are numpad 6 7 8 9 (user, 2026-10-30), with
// 1-5 the nets - each is rebindable. The
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
// Numpad 1-5 for the first five (user, 2026-10-30); 6-9 start unbound,
// because numpad 6-9 are the device keys. Ctrl + the same key mutes or
// unmutes that net (MUTE NET 1-9 below).
for "_i" from 1 to NET_SELECT_KEYS do {
    [
        JMFSB_CATEGORY,
        format ["%1_%2", QGVAR(netSelect), _i],
        [format ["Select net %1", _i], format ["Makes net %1 - the chip numbered %1 on the phone, side device or tablet - your active net.", _i]],
        compile format ["[%1] call %2", _i, QFUNC(netSelect)],
        {false},
        [NET_SELECT_DEFAULTS param [_i - 1, -1], NET_SELECT_MODS]
    ] call CBA_fnc_addKeybind;
    // MUTE NET 1-9: Ctrl + the same key (user, 2026-10-25: "Ctrl and press
    // 1-6 make a toggle mute").
    [
        JMFSB_CATEGORY,
        format ["%1_%2", QGVAR(netMute), _i],
        [format ["Mute net %1", _i], format ["Mutes or unmutes net %1 - the chip numbered %1. Your active net does not change.", _i]],
        compile format ["[%1] call %2", _i, QFUNC(netMute)],
        {false},
        [NET_SELECT_DEFAULTS param [_i - 1, -1], NET_MUTE_MODS]
    ] call CBA_fnc_addKeybind;
};

// THE RADIO APP on the carried phone or side device, and its tabs - no
// default keys since the numpad standard (user, 2026-10-25). On the tablet
// FUNC(keyDown) answers the same bindings for the tablet's RADIO app.
[
    JMFSB_CATEGORY,
    QGVAR(radioAppKey),
    ["Device RADIO app", "Opens or closes the RADIO app on the phone or side device in the GPS slot (on the tablet while it is open: its RADIO app). No default key - bind one in Configure Addons."],
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
        [_key, TAB_MODS]
    ] call CBA_fnc_addKeybind;
} forEach [
    [QGVAR(tabPrev), "Device previous tab", RADIO_TAB_PREV, KEY_TAB_PREV],
    [QGVAR(tabNext), "Device next tab", RADIO_TAB_NEXT, KEY_TAB_NEXT]
];

// ANSWER / HANG UP, numpad * (the numpad standard, user 2026-10-25): answers
// the call that is ringing, else hangs up the one he is in.
[
    JMFSB_CATEGORY,
    QGVAR(answerKey),
    ["Answer / hang up call", "Answers the call ringing you; with none ringing, hangs up the call you are in. Numpad * by default."],
    {[] call FUNC(voiceAnswerKey)},
    {false},
    [KEY_ANSWER, [false, false, false]]
] call CBA_fnc_addKeybind;

// DECLINE, numpad / (user, 2026-10-30: "/ = no, do not answer"): declines the
// call ringing you; closes the quick-add list when it is open.
[
    JMFSB_CATEGORY,
    QGVAR(declineKey),
    ["Decline call", "Declines the call ringing you; closes the quick-add list when it is open. Numpad / by default."],
    {[] call FUNC(voiceDeclineKey)},
    {false},
    [KEY_DECLINE, [false, false, false]]
] call CBA_fnc_addKeybind;

// VOICE ACTIVATION ON / OFF, numpad + (2026-10-30; it was 7): flips the
// player's own setting (jmfsb_adapter_von_vad) - tick it only with Arma's VON
// on voice activation.
[
    JMFSB_CATEGORY,
    QGVAR(vadKey),
    ["Voice activation on / off", "Turns the mod's voice activation mode on or off (Addon Options > JMSB - Voice (Built-in)). Use it with Arma's VON set to voice activation. Numpad + by default."],
    {[] call FUNC(voiceVadToggle)},
    {false},
    [KEY_VAD, [false, false, false]]
] call CBA_fnc_addKeybind;

// CALL CAMERA FACE / VIEW (user, 2026-10-28: "the flip needs a key bind"):
// what his camera sends on a live call. No default key.
[
    JMFSB_CATEGORY,
    QGVAR(callCamKey),
    ["Call camera: face / view", "On a live call, flips what your camera sends: your face, or what you see. The same as SEND VIEW / SEND FACE on the RADIO app. No default key."],
    {[] call FUNC(voiceCamKey)},
    {false},
    [KEY_CALL_CAM, [false, false, false]]
] call CBA_fnc_addKeybind;

// THE CALL'S WINDOW STAYS ON TOP of the tablet: an app draws its controls over
// whatever is there, so the window is drawn again after every app draw.
[QEGVAR(tacpad,appOpened), {
    [uiNamespace getVariable [QGVAR(display), displayNull]] call FUNC(tabletCall);
}] call CBA_fnc_addEventHandler;

// The echo test's row on the RADIO app and the tablet's RADIO page follows
// its state (jmfsb_adapter_livekit_fnc_echo raises it).
[QEGVAR(adapter_livekit,echo), {
    if (GVAR(radioOpen)) then {[] call FUNC(overlayTick)};
    if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo "radio") then {
        ["radio"] call EFUNC(tacpad,openApp);
    };
}] call CBA_fnc_addEventHandler;

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
