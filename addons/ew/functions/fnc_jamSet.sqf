#include "script_component.hpp"
/*
 * Author: JMSB
 * EA: sets a man's jammer (DESIGN_EW "EA"). One jammer per operator,
 * radiating from what FUNC(kit) says he jams from - the vehicle carrying a
 * jammer module. On a client this forwards to the server, which
 * owns every jammer and checks the kit again.
 *
 * Changes (all optional):
 *   mode   barrage | spot | sweep | gps | spoof (spot and spoof: ISR only)
 *   band   barrage band, one of the host's bands
 *   track  spot target: a track id of his own side; the jammer takes the net
 *          and band of the emitter behind it
 *   power  index into the host's power steps (pack 1 / 5 / 20 W, vehicle
 *          also 50 W)
 *   duty   index into DUTY_STEPS
 *   on     switched on or not (on the air is FUNC(jamUpdate)'s "tx")
 *   pattern    omni | sector
 *   azimuth    the sector's azimuth, degrees true, to AZIMUTH_STEP_DEG
 *   filter     broadband | targeted (barrage; targeted: ISR only)
 *   freq       targeted: a track id of his own side; the jammer tunes to its
 *              MHz (FUNC(trackMhz)) and takes its band
 *   operation  continuous | auto (FUNC(jamAuto))
 *
 * A new jammer is given its side's lowest free DEVICE ID (GJ-01, GJ-02 ...),
 * kept while it exists. The GPS zone and whether it is on the air are
 * FUNC(jamUpdate)'s. Refusals are told to the man as a warning.
 *
 * Arguments:
 * 0: Operator <OBJECT>
 * 1: Changes <ARRAY of [STRING, ANY] or HASHMAP>
 *
 * Return Value:
 * Accepted (server), forwarded (client) <BOOL>
 *
 * Example:
 * [player, [["mode", "barrage"], ["band", "VHF"], ["on", true]]] call jmfsb_ew_fnc_jamSet
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_changes", [], [[], createHashMap]]];

if (!isServer) exitWith {
    [QGVAR(jamSet), [_unit, _changes]] call CBA_fnc_serverEvent;
    true
};
if (isNull _unit) exitWith {false};
if (_changes isEqualType []) then {_changes = createHashMapFromArray _changes};

private _kit = [_unit] call FUNC(kit);
private _host = _kit get "host";
private _id = "ew_jam_" + getPlayerUID _unit;
if (isNull _host) exitWith {
    [_id] call FUNC(jamOff);
    [_unit, "EA", "NO JAMMER", "CREW A VEHICLE WITH AN EW JAMMER MODULE IN ITS CARGO"] call FUNC(warn);
    [[_unit], false] call FUNC(publish);
    false
};

private _bands = VEHICLE_BANDS;
private _powers = POWER_VEHICLE;
private _side = str side group _unit;

private _j = GVAR(jammers) getOrDefault [_id, createHashMap];
if (count _j == 0) then {
    private _taken = ((values GVAR(jammers)) select {(_x get "side") isEqualTo _side}) apply {_x get "devNo"};
    private _no = 1;
    while {_no in _taken} do {_no = _no + 1};
    _j = createHashMapFromArray [
        ["id", _id], ["mode", MODE_BARRAGE], ["band", _bands select 0], ["net", ""],
        ["netBand", ""], ["track", ""], ["power", 0], ["duty", count DUTY_STEPS - 1],
        ["on", false], ["tx", false], ["zone", ""],
        ["devNo", _no], ["devId", format [DEV_ID_FORMAT, [_no, DEV_ID_DIGITS] call CBA_fnc_formatNumber]],
        ["pattern", PATTERN_OMNI], ["azimuth", 0], ["filter", FILTER_BROADBAND], ["freq", 0],
        ["operation", OP_CONTINUOUS], ["engaged", false], ["engagedWhy", ""]
    ];
    GVAR(jammers) set [_id, _j];
};
_j set ["host", _host];
_j set ["operator", _unit];
_j set ["side", _side];
_j set ["bands", _bands];

private _refuse = "";
{
    switch (_x) do {
        case "mode": {
            if !(_y in MODES) exitWith {};
            if (_y in MODES_ISR && {!(_kit get "isr")}) exitWith {_refuse = format ["%1 IS FOR ISR OPERATORS", toUpper _y]};
            _j set ["mode", _y];
        };
        case "band": {
            if !(_y in _bands) exitWith {};
            // A new band leaves the tuned frequency behind.
            if (_y isNotEqualTo (_j get "band")) then {_j set ["freq", 0]};
            _j set ["band", _y];
        };
        case "track": {
            if (_y isEqualType "") then {_j set ["track", _y]};
        };
        case "power": {
            if (_y isEqualType 0) then {_j set ["power", ((round _y) max 0) min (count _powers - 1)]};
        };
        case "duty": {
            if (_y isEqualType 0) then {_j set ["duty", ((round _y) max 0) min (count DUTY_STEPS - 1)]};
        };
        case "on": {
            if (_y isEqualType true) then {_j set ["on", _y]};
        };
        case "pattern": {
            if (_y in PATTERNS) then {_j set ["pattern", _y]};
        };
        case "azimuth": {
            if !(_y isEqualType 0) exitWith {};
            private _az = (round (_y / AZIMUTH_STEP_DEG)) * AZIMUTH_STEP_DEG;
            _j set ["azimuth", ((_az mod DEGREES_FULL) + DEGREES_FULL) mod DEGREES_FULL];
        };
        case "filter": {
            if !(_y in FILTERS) exitWith {};
            if (_y isEqualTo FILTER_TARGETED && {!(_kit get "isr")}) exitWith {_refuse = "TARGETED IS FOR ISR OPERATORS"};
            _j set ["filter", _y];
        };
        case "freq": {
            if !(_y isEqualType "") exitWith {};
            private _t = (GVAR(tracks) getOrDefault [_side, createHashMap]) getOrDefault [_y, createHashMap];
            if (count _t == 0 || {!((_t get "band") in _bands)}) exitWith {_refuse = "NO ES TRACK THIS JAMMER CAN TUNE TO"};
            _j set ["band", _t get "band"];
            _j set ["freq", [_t] call FUNC(trackMhz)];
        };
        case "operation": {
            if !(_y in OPERATIONS) exitWith {};
            _j set ["operation", _y];
            // Looked at on the next DF tick rather than up to AUTO_CHECK_S on.
            GVAR(jamAutoAt) = 0;
        };
    };
} forEach _changes;
if !((_j get "band") in _bands) then {_j set ["band", _bands select 0]};

// SPOT NEEDS AN ES TRACK, and takes the net of the emitter behind it.
if ((_j get "mode") isEqualTo MODE_SPOT) then {
    private _track = (GVAR(tracks) getOrDefault [_side, createHashMap]) getOrDefault [_j get "track", createHashMap];
    private _e = GVAR(lastEmitters) getOrDefault [_track getOrDefault ["emitter", ""], createHashMap];
    private _nets = (_e getOrDefault ["nets", []]) - [NET_DATA];
    if ((_e getOrDefault ["nets", []]) isEqualTo [NET_DATA]) then {_nets = [NET_DATA]};
    private _net = _nets param [0, ""];
    private _netBand = [_net] call EFUNC(rf,netBand);
    if (_net isEqualTo "" || {!(_netBand in _bands)}) exitWith {
        _refuse = "SPOT NEEDS A FRESH ES TRACK ON A NET THIS JAMMER REACHES";
        _j set ["on", false];
    };
    _j set ["net", _net];
    _j set ["netBand", _netBand];
};

private _powerIdx = _j get "power";
_j set ["dBm", _powers select _powerIdx];
_j set ["dutyFrac", DUTY_STEPS select (_j get "duty")];
_j set ["radius", switch (_j get "mode") do {
    case MODE_GPS: {GPS_RADIUS_STEPS select (_powerIdx min (count GPS_RADIUS_STEPS - 1))};
    case MODE_SPOOF: {GVAR(spoofRadius) * (_powerIdx + 1) / count _powers};
    default {0};
}];

// ON THE AIR, and the GPS zone that follows it (FUNC(jamUpdate)).
private _zoneRefuse = [_j] call FUNC(jamUpdate);
if (_refuse isEqualTo "") then {_refuse = _zoneRefuse};

if (_refuse isNotEqualTo "") then {
    [_unit, "EA", _refuse, ""] call FUNC(warn);
};
TRACE_3("jammer set",_id,_j get "mode",_j get "tx");
[[_unit], false] call FUNC(publish);

_refuse isEqualTo ""
