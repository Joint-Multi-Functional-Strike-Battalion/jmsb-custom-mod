#include "script_component.hpp"
/*
 * Author: YonV
 * Server: RECORD AS TARGET (user, 2026-11-02) - the observer's `record` in a
 * battery's call-for-fire thread (FUNC(threadReply)). The mission's point,
 * where the last correction put it, becomes a named target:
 *
 *   THE NAME     the battery's two letters (FUNC(targetPrefix)) and a running
 *                number from TARGET_FIRST - "AB1001". A name that is already a
 *                marker is skipped: an Eden marker named so is a pre-planned
 *                target, and is never moved or taken over
 *   THE MARKER   a map marker of that name on the point, the name its text,
 *                for the battery's side: made on the server, so the server's
 *                card reader (support gridPos) finds it by name - CFF GRID's
 *                target and CFF SHIFT's known point fire on it again - and
 *                hidden on every other side's machine (FUNC(targetLocal), JIP)
 *
 * Recorded again with the point unmoved, the same name. Credit: target
 * points kept for re-fire and shown on the map are an idea of Tun Firesupport
 * by Tuntematon / Armafinland (its bookmarks and TRP markers); the naming is
 * the doctrinal target number, two letters and four figures.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The target's name, "" when none was recorded <STRING>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_record
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {""};

private _order = _logic getVariable [QGVAR(threadOrder), createHashMap];
private _target = _order getOrDefault ["target", []];
if (_target isEqualTo []) exitWith {""};

private _done = _order getOrDefault ["recorded", []];
if (_done isNotEqualTo [] && {(_done select 1) isEqualTo _target}) exitWith {_done select 0};

// The next number no marker has.
private _prefix = _logic getVariable [QGVAR(targetPrefix), ""];
private _from = (_logic getVariable [QGVAR(targetNo), TARGET_FIRST - 1]) + 1;
private _name = "";
for "_n" from _from to TARGET_LAST do {
    private _try = format [TARGET_FORMAT, _prefix, _n];
    if (markerShape _try isEqualTo "") exitWith {
        _name = _try;
        _logic setVariable [QGVAR(targetNo), _n];
    };
};
if (_name isEqualTo "") exitWith {""};

// Made locally, then one global command sends the whole marker.
createMarkerLocal [_name, _target];
_name setMarkerTypeLocal TARGET_MARK_ICON;
_name setMarkerColorLocal TARGET_MARK_COLOR;
_name setMarkerTextLocal _name;
_name setMarkerAlpha TARGET_MARK_ALPHA;

private _side = _logic getVariable [QGVAR(side), sideUnknown];
[_name, _side] remoteExecCall [QFUNC(targetLocal), 0, format ["%1_target_%2", QUOTE(ADDON), _name]];

_order set ["recorded", [_name, +_target]];
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
private _grid = mapGridPosition _target;
INFO_3("%1 recorded target %2 at %3",_callsign,_name,_grid);

_name
