#include "script_component.hpp"
/*
 * Author: YonV
 * Server: sends a side its open LZs and DZs (FUNC(zones)) - every thread's of
 * that side in one list, by remoteExec to every machine under one JIP id per
 * side (the mod's pattern for a side's map marks, support_fires FUNC(mark)), so
 * a player joining mid-mission gets it and a newer list replaces it. Each client
 * keeps only his own side's (FUNC(zonesLocal), which takes only the server's
 * word). An empty list leaves the JIP queue.
 *
 * A THREAD THAT ENDED UNSAID. Before it sends, a thread gone from messaging or
 * over (CLOSED, DECLINED, ABORTED) whose provider never cleared its zones loses
 * them here, and its side is sent too - unless they are held for a stick still in
 * the air (FUNC(zonesHold)).
 *
 * Arguments:
 * 0: The sides to send <ARRAY of SIDEs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[west]] call jmfsb_support_fnc_zonesPublish
 *
 * Public: No
 */

params [["_sides", [], [[]]]];

if (!isServer) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("zonesPublish: refused - remote call from machine %1",remoteExecutedOwner);
};

private _all = localNamespace getVariable [QGVAR(zoneThreads), createHashMap];
private _threads = missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap];
private _stale = (keys _all) select {
    (_all get _x) params ["", "", "_held"];
    private _thread = _threads getOrDefault [_x, createHashMap];
    !_held && {
        _thread isEqualTo createHashMap
        || {_thread getOrDefault ["closed", false]}
        || {(_thread getOrDefault ["status", ""]) in STATES_OVER}
    }
};
{
    _sides pushBack ((_all get _x) select 0);
    _all deleteAt _x;
} forEach _stale;
localNamespace setVariable [QGVAR(zoneThreads), _all];

{
    private _side = _x;
    private _list = [];
    {
        _y params ["_owner", "_rows"];
        if (_owner isEqualTo _side) then {_list append _rows};
    } forEach _all;

    private _jip = format [ZONE_JIP, QUOTE(ADDON), _side];
    if (_list isEqualTo []) then {
        remoteExecCall ["", _jip];
        [_side, []] remoteExecCall [QFUNC(zonesLocal), 0];
    } else {
        [_side, _list] remoteExecCall [QFUNC(zonesLocal), 0, _jip];
    };
} forEach (_sides arrayIntersect _sides);
