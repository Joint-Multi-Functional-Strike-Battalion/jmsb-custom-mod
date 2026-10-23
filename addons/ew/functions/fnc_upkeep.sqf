#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, each DF tick, before anything is heard: drops what is gone.
 *
 *   jammers   whose operator died or left, or no longer has the kit he
 *             jammed with (dropped the pack, left the vehicle)
 *   decoys    whose battery ran out (FUNC(decoyPlace)) or whose antenna was
 *             destroyed - the RF node goes, and the prop with a flat battery
 *   external  emitters whose object is gone
 *   memory    the first-heard and last-traffic times of nodes RF no longer
 *             hands over, and AI groups' radios not asked about for two
 *             refreshes (FUNC(aiSet))
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ew_fnc_upkeep
 *
 * Public: No
 */

private _now = CBA_missionTime;

private _gone = [];
{
    private _unit = _y get "operator";
    if (isNull _unit || {!alive _unit} || {!isPlayer _unit}) then {
        _gone pushBack _x;
        continue;
    };
    if ((([_unit] call FUNC(kit)) get "host") isNotEqualTo (_y get "host")) then {_gone pushBack _x};
} forEach GVAR(jammers);
{
    [_x] call FUNC(jamOff);
} forEach _gone;

_gone = [];
{
    _y params ["_prop", "", "_expires"];
    if (isNull _prop || {!alive _prop} || _now >= _expires) then {_gone pushBack _x};
} forEach GVAR(decoys);
{
    private _entry = GVAR(decoys) deleteAt _x;
    [_x] call EFUNC(rf,unregister);
    private _prop = _entry select 0;
    if (!isNull _prop && {alive _prop}) then {deleteVehicle _prop};
} forEach _gone;

_gone = [];
{
    if (isNull (_y select 0) || {!alive (_y select 0)}) then {_gone pushBack _x};
} forEach GVAR(external);
{
    GVAR(external) deleteAt _x;
} forEach _gone;

private _live = GVAR(rfEmitters) apply {_x select 0};
{
    private _map = _x;
    {
        _map deleteAt _x;
    } forEach ((keys _map) - _live);
} forEach [GVAR(firstSeen), GVAR(lastTx)];

_gone = [];
{
    if ((_now - (_y select 0)) > 2 * AI_SET_REFRESH_S) then {_gone pushBack _x};
} forEach GVAR(aiSets);
{
    GVAR(aiSets) deleteAt _x;
} forEach _gone;
