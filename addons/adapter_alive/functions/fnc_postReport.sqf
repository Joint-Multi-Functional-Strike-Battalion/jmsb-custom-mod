#include "script_component.hpp"
/*
 * Author: YonV
 * Files a report with ALiVE's C2ISTAR as a spotrep or a sitrep, with a
 * companion map marker. Silently does nothing when ALiVE, or the C2ISTAR
 * module that owns those systems, is not there.
 *
 * The caller hands over flat named fields and never sees an ALiVE symbol -
 * that is the whole point of this function existing rather than the messaging
 * addon posting directly, which is what the cTab version used to do.
 *
 * Field names taken, all optional and all strings:
 *   spotrep  loc size type activity remarks dateTime
 *   sitrep   callsign loc en ekia ff fkia fwia civ ammo cas veh cs remarks
 *            markerType
 *
 * Arguments:
 * 0: Kind - "spotrep" or "sitrep" <STRING>
 * 1: Reporting player <OBJECT>
 * 2: Position the report is about <ARRAY>
 * 3: Fields <ARRAY> - [name, value] pairs
 * 4: Locality - "GLOBAL", "SIDE" or "GROUP" <STRING> (optional, default "SIDE")
 *
 * Return Value:
 * Posted <BOOL>
 *
 * Example:
 * ["spotrep", player, _pos, [["size", "Squad"]], "SIDE"] call jmfsb_adapter_alive_fnc_postReport
 *
 * Public: Yes
 */

params [
    ["_kind", "", [""]],
    ["_unit", objNull, [objNull]],
    ["_pos", [], [[]]],
    ["_fields", [], [[]]],
    ["_locality", "SIDE", [""]]
];

if (!isServer) exitWith {false};
if !(_kind in ["spotrep", "sitrep"]) exitWith {false};
if (isNull _unit || {_pos isEqualTo []}) exitWith {false};

if (isNil "ALiVE_SYS_marker") exitWith {
    INFO_1("%1 not posted - ALiVE marker system absent",_kind);
    false
};

private _system = ["ALiVE_SYS_spotrep", "ALiVE_SYS_sitrep"] select (_kind == "sitrep");
if (isNil _system) exitWith {
    INFO_2("%1 not posted - %2 absent, C2ISTAR is probably not on the map",_kind,_system);
    false
};

private _f = createHashMapFromArray _fields;
private _uid = getPlayerUID _unit;
private _grid = mapGridPosition _pos;

private _localityValue = switch (_locality) do {
    case "GROUP": {str (group _unit)};
    case "SIDE": {str (side (group _unit))};
    default {"GLOBAL"};
};

date params ["", "", "_d", "_h", "_mi"];
private _dtg = format ["%1%2%3Z", [_d, 2] call CBA_fnc_formatNumber, [_h, 2] call CBA_fnc_formatNumber, [_mi, 2] call CBA_fnc_formatNumber];

// Unique per report and per machine, so two people filing at once cannot
// collide on a name ALiVE would then overwrite.
GVAR(reportIndex) = (missionNamespace getVariable [QGVAR(reportIndex), 0]) + 1;
private _suffix = format ["jmfsb%1x%2", clientOwner, GVAR(reportIndex)];
private _markerName = "MKR" + _suffix;

private _isSpotrep = _kind == "spotrep";
private _markerType = [_f getOrDefault ["markerType", "b_inf"], "o_unknown"] select _isSpotrep;
private _markerColor = switch (_markerType select [0, 2]) do {
    case "b_": {"ColorBLUFOR"};
    case "o_": {"ColorOPFOR"};
    case "n_": {"ColorIndependent"};
    default {"ColorBlack"};
};

private _markerText = if (_isSpotrep) then {
    format ["CONTACT %1", _f getOrDefault ["loc", _grid]]
} else {
    format ["%1_%2", groupId (group _unit), _dtg]
};

// KEY SPELLING IS LOAD-BEARING. ALiVE reads these hashes with QGVAR()/QMOD()
// keys built from PREFIX "ALiVE" - "ALiVE_SYS_marker_shape", not
// "ALIVE_SYS_marker_shape" - and ALiVE_fnc_hashGet matches with a
// case-sensitive find. The upper-case spelling silently returns nil for every
// field and createMarker fails. Verified against sys_marker/fnc_marker.sqf
// (createMarker) and main/script_mod.hpp (PREFIX).
private _markerHash = [] call ALiVE_fnc_hashCreate;
{
    [_markerHash, _x # 0, _x # 1] call ALiVE_fnc_hashSet;
} forEach [
    ["ALiVE_SYS_marker_shape", "ICON"],
    ["ALiVE_SYS_marker_type", _markerType],
    ["ALiVE_SYS_marker_color", _markerColor],
    ["ALiVE_SYS_marker_size", [1, 1]],
    ["ALiVE_SYS_marker_pos", _pos],
    ["ALiVE_SYS_marker_dir", 0],
    ["ALiVE_SYS_marker_text", _markerText],
    ["ALiVE_SYS_marker_locality", _locality],
    ["ALiVE_SYS_marker_localityValue", _localityValue],
    ["ALiVE_SYS_marker_player", _uid],
    ["ALiVE_SYS_marker_hasspotrep", _isSpotrep],
    ["ALiVE_SYS_marker_spotrep", ["", "SP" + _suffix] select _isSpotrep]
];

private _reportHash = [] call ALiVE_fnc_hashCreate;
private _pairs = if (_isSpotrep) then {
    [
        ["ALiVE_SYS_spotrep_callsign", format ["%1:%2", groupId (group _unit), name _unit]],
        ["ALiVE_SYS_spotrep_DTG", _dtg],
        ["ALiVE_SYS_spotrep_dateTime", _f getOrDefault ["dateTime", "NOW"]],
        ["ALiVE_SYS_spotrep_loc", _f getOrDefault ["loc", _grid]],
        ["ALiVE_SYS_spotrep_faction", "UNKNOWN"],
        ["ALiVE_SYS_spotrep_size", _f getOrDefault ["size", "Unknown"]],
        ["ALiVE_SYS_spotrep_type", _f getOrDefault ["type", "Unknown"]],
        ["ALiVE_SYS_spotrep_activity", toUpper (_f getOrDefault ["activity", "STATIC"])],
        ["ALiVE_SYS_spotrep_factivity", "OBSERVING"],
        ["ALiVE_SYS_spotrep_remarks", _f getOrDefault ["remarks", ""]],
        ["ALiVE_SYS_spotrep_markername", _markerName],
        ["ALiVE_SYS_spotrep_locality", _locality],
        ["ALiVE_SYS_spotrep_localityValue", _localityValue],
        ["ALiVE_SYS_spotrep_player", _uid]
    ]
} else {
    [
        ["ALiVE_SYS_sitrep_player", _uid],
        ["ALiVE_SYS_sitrep_callsign", _f getOrDefault ["callsign", format ["%1:%2", groupId (group _unit), name _unit]]],
        ["ALiVE_SYS_sitrep_DTG", _dtg],
        ["ALiVE_SYS_sitrep_dateTime", "NOW"],
        ["ALiVE_SYS_sitrep_loc", _f getOrDefault ["loc", _grid]],
        ["ALiVE_SYS_sitrep_en", _f getOrDefault ["en", "NONE"]],
        ["ALiVE_SYS_sitrep_ekia", _f getOrDefault ["ekia", "0"]],
        ["ALiVE_SYS_sitrep_ff", _f getOrDefault ["ff", ""]],
        ["ALiVE_SYS_sitrep_fkia", _f getOrDefault ["fkia", "0"]],
        ["ALiVE_SYS_sitrep_fwia", _f getOrDefault ["fwia", "0"]],
        ["ALiVE_SYS_sitrep_civ", _f getOrDefault ["civ", "NONE"]],
        ["ALiVE_SYS_sitrep_ammo", _f getOrDefault ["ammo", "GREEN"]],
        ["ALiVE_SYS_sitrep_cas", _f getOrDefault ["cas", "GREEN"]],
        ["ALiVE_SYS_sitrep_veh", _f getOrDefault ["veh", "GREEN"]],
        ["ALiVE_SYS_sitrep_cs", _f getOrDefault ["cs", "GREEN"]],
        ["ALiVE_SYS_sitrep_remarks", _f getOrDefault ["remarks", ""]],
        ["ALiVE_SYS_sitrep_group", str (group _unit)],
        ["ALiVE_SYS_sitrep_pos", _pos],
        ["ALiVE_SYS_sitrep_locality", _locality],
        ["ALiVE_SYS_sitrep_localityValue", _localityValue]
    ]
};

{
    [_reportHash, _x # 0, _x # 1] call ALiVE_fnc_hashSet;
} forEach _pairs;

// ALiVE's own report systems are scheduled - calling them unscheduled from an
// event handler is what made the cTab version spawn, and it is still true here.
[_kind, _reportHash, ["SP" + _suffix, "ST" + _suffix] select (!_isSpotrep), _markerName, _markerHash] spawn {
    params ["_kind", "_reportHash", "_reportName", "_markerName", "_markerHash"];

    if (_kind == "spotrep") then {
        [ALiVE_SYS_spotrep, "addspotrep", [_reportName, _reportHash]] call ALiVE_fnc_spotrep;
    } else {
        [ALiVE_SYS_sitrep, "addsitrep", [_reportName, _reportHash]] call ALiVE_fnc_sitrep;
    };

    [ALiVE_SYS_marker, "addMarker", [_markerName, _markerHash]] call ALiVE_fnc_marker;
};

true
