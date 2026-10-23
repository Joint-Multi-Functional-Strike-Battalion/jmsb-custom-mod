#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

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

// THE TABLET'S SETTINGS PAGE carries the phone and side devices' settings -
// they have no ACE menu of their own. Two sections in its rail, rows from
// FUNC(settingsRows), drawn by jmfsb_tacpad_apps_fnc_appSettings.
EGVAR(tacpad_apps,settingsSections) pushBack ["devices", "DEVICES", {["devices"] call FUNC(settingsRows)}];
EGVAR(tacpad_apps,settingsSections) pushBack ["devkeys", "DEVICE KEYS", {["devkeys"] call FUNC(settingsRows)}];

// THE STATUS ROW'S PROVIDERS: label -> code answering [text, value, state].
// Built here so another addon can add or replace one in its own postInit; the
// order is the row's, left to right.
GVAR(overlayProviders) = [] call FUNC(overlayProviders);
GVAR(overlayOrder) = ["NET", "MESH", "JAM", "GPS", "DRONES", "MSG"];

// RF's summary for the walking view (FUNC(overlayRf)), rebuilt by the tick
// whenever jmfsb_rf_linkChanged has marked it dirty; and the last man heard,
// [unit, voice, time], for the talking chip (FUNC(overlayTalker)).
GVAR(overlayRf) = createHashMap;
GVAR(overlayRfDirty) = true;
GVAR(overlayTalker) = [objNull, 0, 0, ""];

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
// for most UAV crews, the launcher's client for a hand-thrown one - so the
// handler is on every machine, not only on players' (FUNC(uavOrder)). Which
// weapon of a class is its laser designator, worked out once per class.
[QGVAR(uavOrder), {_this call FUNC(uavOrder)}] call CBA_fnc_addEventHandler;
GVAR(uavLaserCache) = createHashMap;

ADDON = true;
