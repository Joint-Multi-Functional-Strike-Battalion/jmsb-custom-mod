#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_scannerRead

Description:
    One sweep of everything the scanner shows. Kept separate from the drawing so
    the readings can be tested on their own (see #jmfsb hack.scan) and so the
    screen never contains logic.

    Every value is read live from the player's own position, which is the whole
    point of a hand-held: walking changes the answer.

Returns:
    ARRAY - [_droneState, _droneDist, _droneDir, _jamFactor, _chanText, _freqText,
             _meshCount, _droneTag, _jamRadio, _jamData, _jamGps].

            THE THREE DOMAINS ARE APPENDED, NOT SUBSTITUTED. Index 3 is still
            the worst of them - "is the spectrum dirty" - because the drone
            page, the dashboard lamps and every other reader wants one number
            and reads it positionally. 8, 9 and 10 are radio, data and GPS for
            the readouts that show which service is down.

            _droneDir is a compass bearing, -1 when
             nothing is up; _droneTag is "faction / airframe", "" when clear.
            _droneState 0 clear / 1 warn / 2 alert.
            The net reading comes back as two strings rather than one sentence
            because the screen prints them in separate columns.

Author:
    JMSB
---------------------------------------------------------------------------- */
// CACHED, because this is the most expensive thing the devices do and it was
// being run more than once a second on every client with a device open.
//
// The drone sweep alone is a nearEntities over TWO KILOMETRES, and on an ALiVE
// map that is a lot of entities to walk. widgetTick calls this once a second
// for the dashboard lamps, and the drone page's own refresh calls it again -
// so with that page up the sweep ran twice a second, forever, for a readout
// that cannot meaningfully change that fast.
//
// One sweep per SCN_CACHE_TTL, shared by every caller. uiNamespace rather than
// missionNamespace: this is a client-local reading about the player standing
// here, and nothing on the server has any business reading it.
private _now = diag_tickTime;
private _cached = uiNamespace getVariable [QGVAR(scanCache), []];
if (_cached isNotEqualTo [] && {_now < (_cached select 0)}) exitWith {
    _cached select 1
};

private _pos = getPosASL player;

// --- 1. drones -------------------------------------------------------------
// Anything unmanned and hostile. Distance decides the lamp, not intent - a
// recon quad you have not noticed is exactly what this is for.
private _mySide = side group player;
private _nearest = -1;
private _nearestObj = objNull;
{
    if (!alive _x) then { continue };
    if !(unitIsUAV _x) then { continue };
    // WARN ONLY ON A DRONE POSITIVELY IDENTIFIED AS HOSTILE. The side comes off
    // the CREW - a UAV carries its AI whether or not a player is connected, and
    // effectiveCommander returns objNull the moment nobody is flying it, which
    // is what made our own drones alarm.
    private _crew = crew _x;
    private _theirSide = if (_crew isEqualTo []) then {side _x} else {side (_crew select 0)};
    if !(_theirSide in [east, west, resistance]) then { continue };
    if (_theirSide getFriend _mySide >= 0.6) then { continue };
    private _d = _pos distance (getPosASL _x);
    if (_nearest < 0 || _d < _nearest) then { _nearest = _d; _nearestObj = _x };
} forEach (player nearEntities [["Air", "LandVehicle", "Ship"], SCN_DRONE_WARN]);

private _droneState = switch (true) do {
    case (_nearest < 0): { 0 };
    case (_nearest <= SCN_DRONE_ALERT): { 2 };
    default { 1 };
};

// Compass bearing to it. A range on its own tells you to worry; a bearing tells
// you which way to look, and which way to move.
private _droneDir = -1;
if (!isNull _nearestObj) then {
    _droneDir = round (_pos getDir (getPosASL _nearestObj)) % 360;
};

// --- 2. jamming ------------------------------------------------------------
// Straight off the same function the radios are degraded by, so the scanner and
// the radio can never disagree about whether you are standing in a field.
//
// This was hard-wired to 0 with a note saying jamming had been deleted. It has
// not been deleted for some time - the readout has just been reporting CLEAR
// inside every jammer on the map since. Soft-linked, because hacking does not
// depend on jamming and a mission may well run one without the other.
private _jam = 0;
if (!isNil "jmfsb_jamming_fnc_jamFactor") then {
    // "any": a spectrum scanner reads the spectrum. It reports that the air
    // is dirty here, and leaves working out WHICH service is down to the
    // player finding out their radio still works but TAC//MSG does not.
    _jam = ([_pos, 0, "any"] call jmfsb_jamming_fnc_jamFactor) param [0, 0];
};

// --- 3. own net ------------------------------------------------------------
private _chanText = "NO RADIO";
private _freqText = "";
if (!isNil "acre_api_fnc_getCurrentRadio") then {
    private _cur = call acre_api_fnc_getCurrentRadio;
    if (_cur isEqualType "" && _cur isNotEqualTo "") then {
        private _i = _cur find "_ID_";
        private _base = if (_i > 0) then { _cur select [0, _i] } else { _cur };
        private _preset = [_cur] call acre_api_fnc_getPreset;
        private _ch = [_cur] call acre_api_fnc_getRadioChannel;
        private _f = [_base, _preset, _ch, "frequencyTX"] call acre_api_fnc_getPresetChannelField;
        // ACRE's getRadioChannel ALREADY RETURNS 1-N ("Channel number, 1-N
        // depending on the radio", api\fnc_getRadioChannel.sqf) - the +1 here
        // is what had the app and the sensor panel reading CH 2 while the
        // radio in hand said CH 1.
        _chanText = format ["CH %1", _ch];
        _freqText = if (isNil "_f") then { "-- MHz" } else { format ["%1 MHz", _f] };
    };
} else {
    // GAME VOICE (jmfsb_voice): a net, not a channel, and no frequency - the
    // second column is whether the net reaches anyone (netState's reachable).
    if (!isNil QEFUNC(voice,activeNet)) then {
        private _net = [] call EFUNC(voice,activeNet);
        if (_net isEqualType "" && _net isNotEqualTo "") then {
            private _state = if (isNil QEFUNC(voice,netState)) then {[]} else {[] call EFUNC(voice,netState)};
            private _i = _state findIf {(_x param [0, ""]) isEqualTo _net};
            private _row = if (_i < 0) then {[]} else {_state select _i};
            _chanText = _row param [1, _net];
            _freqText = ["NO LINK", "LINK"] select (_row param [6, false]);
        };
    };
};

// --- mesh stand-in ---------------------------------------------------------
// There is no mesh networking yet, so proximity to a friendly stands in for it:
// someone close enough to relay. Replace this with the real link state when a
// mesh exists - nothing else needs to change.
private _mesh = {
    alive _x && {_x isNotEqualTo player}
    && {(side group _x) getFriend _mySide >= 0.6}
    && {(getPosASL _x) distance _pos <= SCN_MESH_RANGE}
} count allPlayers;

// WHOSE IT IS AND WHAT IT IS. A bearing and a range say to worry and which
// way to look; they do not say whether that is somebody's recon quad or a
// gunship, which is the part that decides what you do about it.
private _tag = [_nearestObj] call FUNC(droneTag);

// PER DOMAIN, for the readouts that name the service. Four reads of one
// calculator rather than four calculators - and they cost nothing on top of the
// one above, because this whole function is cached for SCN_CACHE_TTL and the
// registry walk is the same walk with a different gate. The literals are
// jamming's DOM_* - see its script_component.hpp; this addon does not include it.
private _jamRadio = 0;
private _jamData = 0;
private _jamGps = 0;
if (!isNil "jmfsb_jamming_fnc_jamFactor") then {
    _jamRadio = ([_pos, 0, "radio"] call jmfsb_jamming_fnc_jamFactor) param [0, 0];
    _jamData = ([_pos, 0, "data"] call jmfsb_jamming_fnc_jamFactor) param [0, 0];
    _jamGps = ([_pos, 0, "gps"] call jmfsb_jamming_fnc_jamFactor) param [0, 0];
};

private _out = [_droneState, _nearest, _droneDir, _jam, _chanText, _freqText, _mesh, _tag,
                _jamRadio, _jamData, _jamGps];
uiNamespace setVariable [QGVAR(scanCache), [_now + SCN_CACHE_TTL, _out]];

_out
