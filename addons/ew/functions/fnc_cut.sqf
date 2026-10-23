#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: one DF cut - a bearing from a sensor to an emitter - laid on the
 * hearing side's track for that emitter, made if it is new. The bearing is
 * the true one plus an error that grows as the SNR falls (DESIGN_EW "DF").
 * A sensor holding one of the emitter's keys NAMES the track (net and set);
 * otherwise it is energy, a band and a class. The man being cut is told
 * DF ON YOU (once per DF_ON_YOU_COOLDOWN). The bearing is measured from where
 * the sensor stands; the cut is laid from where its GPS says it stands, so a
 * spoofed sensor's cuts - and the fixes crossed from them - land off target.
 *
 * Arguments:
 * 0: Hearing side <STRING>
 * 1: Emitter, as FUNC(collect) builds it <HASHMAP>
 * 2: Sensor position ASL <ARRAY>
 * 3: Sensor bearing error deg <NUMBER>
 * 4: Detection [band, rx dBm, snr dB] <ARRAY>
 * 5: Nets the sensor decodes the emitter on <ARRAY of STRINGs>
 * 6: Where the sensor's GPS puts it, ASL (optional, default where it is) <ARRAY>
 *
 * Return Value:
 * Track <HASHMAP>
 *
 * Example:
 * ["WEST", _emitter, _pos, 10, ["VHF", -90, 12], []] call jmfsb_ew_fnc_cut
 *
 * Public: No
 */

params [
    ["_side", "", [""]],
    ["_e", createHashMap, [createHashMap]],
    ["_from", [0, 0, 0], [[]], 3],
    ["_baseErr", 0, [0]],
    ["_det", [], [[]], 3],
    ["_shared", [], [[]]],
    ["_gpsPos", [], [[]]]
];
if (_gpsPos isEqualTo []) then {_gpsPos = _from};

_det params ["_band", "_rx", "_snr"];
private _now = CBA_missionTime;
private _emitterId = _e get "id";
private _target = _e get "pos";

private _err = _baseErr * (((SNR_GOOD_DB / (_snr max 1)) max 1) min ERR_MAX_MULT);
private _bearing = ((_from getDir _target) + random [-_err, 0, _err] + 360) % 360;

private _sideTracks = GVAR(tracks) getOrDefault [_side, createHashMap];
GVAR(tracks) set [_side, _sideTracks];
private _key = _side + "|" + _emitterId;
private _trackId = GVAR(trackIndex) getOrDefault [_key, ""];
private _track = _sideTracks getOrDefault [_trackId, createHashMap];
private _class = [_e] call FUNC(classify);

if (count _track == 0) then {
    GVAR(nextTrack) = GVAR(nextTrack) + 1;
    _trackId = format ["T%1", GVAR(nextTrack)];
    GVAR(trackIndex) set [_key, _trackId];
    _track = createHashMapFromArray [
        ["id", _trackId], ["side", _side], ["emitter", _emitterId], ["cuts", []],
        ["fix", []], ["fixErr", 0], ["first", _now], ["named", ""], ["conf", 0]
    ];
    _sideTracks set [_trackId, _track];
    [QGVAR(trackNew), [_side, _trackId, _class]] call CBA_fnc_localEvent;
    switch (_class) do {
        case CLASS_JAM: {[_side, THREAT_JAMMER, format ["%1 JAMMER HEARD, TRACK %2", _band, _trackId], "DF IT, SEND THE FIX, CHANGE BAND"] call FUNC(warnSide)};
        case CLASS_SPOOF: {[_side, THREAT_SPOOFER, format ["GPS SPOOFER HEARD, TRACK %1", _trackId], "TRUST MAP AND COMPASS, DF IT"] call FUNC(warnSide)};
        case CLASS_VIDEO: {[_side, THREAT_DRONE, format ["DRONE LINK HEARD, TRACK %1", _trackId], "TAKE COVER, JAM ITS VIDEO BAND"] call FUNC(warnSide)};
    };
};

_track set ["band", _band];
_track set ["dbm", round _rx];
_track set ["class", _class];
_track set ["last", _now];
_track set ["source", _e get "source"];
if (_shared isNotEqualTo []) then {
    private _obj = _e get "object";
    private _who = if (_obj isKindOf "CAManBase") then {name _obj} else {getText (configOf _obj >> "displayName")};
    _track set ["named", format ["%1 / %2", _shared select 0, _who]];
};

private _cuts = _track get "cuts";
_cuts pushBack [[_gpsPos select 0, _gpsPos select 1], _bearing, _err, _now];
if (count _cuts > CUTS_KEPT) then {_cuts deleteRange [0, count _cuts - CUTS_KEPT]};

// DF ON YOU, to every player the cut emitter belongs to.
private _obj = _e get "object";
if (_now - (GVAR(dfOnYouAt) getOrDefault [_emitterId, -1e9]) >= DF_ON_YOU_COOLDOWN) then {
    private _men = (if (_obj isKindOf "CAManBase") then {[_obj]} else {crew _obj}) select {isPlayer _x};
    if (_men isEqualTo []) exitWith {};
    GVAR(dfOnYouAt) set [_emitterId, _now];
    [QGVAR(dfOnYou), [_emitterId, _side]] call CBA_fnc_localEvent;
    {
        [_x, THREAT_DF, format ["%1 CUT ON YOUR %2 SET", _side, _band], "MOVE, TRANSMIT LESS, RAISE EMCON"] call FUNC(warn);
    } forEach _men;
};

_track
