#include "script_component.hpp"
/*
 * Author: JMSB
 * Loads every player near a boarding point into cargo. SERVER SIDE.
 *
 * Reached by remoteExec from the button's ACE action (review R1: it was a CBA
 * event, so any client could load everybody at any point from anywhere). The
 * presser must be the sender's own unit, alive and within BOARD_PRESS_RANGE of
 * one of the point's buttons, and the point's range, transport and options are
 * the server's own copy (FUNC(moduleController)), not the logic's public
 * variables.
 *
 * The presser is not the owner of the other players, and moveInCargo wants
 * the unit local - so each seating is sent to the machine that owns that
 * player rather than run here and hoped for.
 *
 * Nobody is teleported across the map: the range is the mission's, and a
 * player outside it is simply not this button's business. People already in a
 * vehicle are left where they are, because pulling a gunner out of his turret
 * to sit in the back of a truck is never what was meant.
 *
 * Arguments:
 * 0: The module <OBJECT>
 * 1: The player who pressed <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, player] remoteExecCall ["jmfsb_boarding_fnc_board", 2]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_presser", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};
if (!alive _presser || {!([_presser] call EFUNC(common,senderIs))}) exitWith {
    WARNING_2("board: refused - machine %1 named %2",remoteExecutedOwner,_presser);
};

private _point = (localNamespace getVariable [QGVAR(points), createHashMap]) getOrDefault [netId _logic, []];
if (_point isEqualTo []) exitWith {
    WARNING_1("board: refused - %1 is not a boarding point",_logic);
};
_point params ["_range", "_buttons", "_synced", "_sideOnly", "_skipPresser"];

if ((_buttons findIf {!isNull _x && {(_presser distance _x) <= BOARD_PRESS_RANGE}}) < 0) exitWith {
    WARNING_1("board: refused - %1 is not at a button of this point",name _presser);
};

private _at = getPosATL _logic;

// FUNC(notify) is client-local and takes three arguments; the server telling
// one player something has to be sent to that player's machine.
private _fnc_tell = {
    params ["_to", "_text", "_colour"];
    if (isNull _to) exitWith {};
    ["Boarding", _text, _colour] remoteExec [QEFUNC(notify,notify), _to];
};

private _vehicles = [_logic, _synced] call FUNC(seatsFor);
if (_vehicles isEqualTo []) exitWith {
    [_presser, "No transport with room here.", [1, 0.3, 0.3, 1]] call _fnc_tell;
};

private _who = (allPlayers - entities "HeadlessClient_F") select {
    alive _x
    && {isNull objectParent _x}
    && {(_at distance2D _x) <= _range}
    && {!(_skipPresser && _x isEqualTo _presser)}
    && {!_sideOnly || {isNull _presser} || {side group _x isEqualTo side group _presser}}
};

if (_who isEqualTo []) exitWith {
    [_presser, "Nobody on foot in range.", [1, 0.3, 0.3, 1]] call _fnc_tell;
};

// Fill the nearest vehicle before moving to the next. The free seats are
// counted once and kept here: the moveIn happens later on each player's own
// machine, so emptyPositions does not drop during this loop and would send the
// whole crowd to the first vehicle.
private _free = _vehicles apply {_x emptyPositions "cargo"};
private _seated = 0;
private _left = [];

{
    private _unit = _x;
    private _i = _free findIf {_x > 0};

    if (_i < 0) then {
        _left pushBack _unit;
    } else {
        _free set [_i, (_free select _i) - 1];
        // where the unit is local - moveInCargo on a remote player does not
        // reliably take
        [_unit, _vehicles select _i] remoteExec ["moveInCargo", _unit];
        _seated = _seated + 1;
    };
} forEach _who;

// Told to the people it happened to, not to the whole server: a section
// boarding in one town is nobody else's business.
{
    [_x, format ["%1 aboard.", _seated], [0.914, 0.651, 0.235, 1]] call _fnc_tell;
} forEach (_who - _left);

if (_left isNotEqualTo []) then {
    [_presser, format ["%1 could not be seated - no room left.", count _left],
        [1, 0.3, 0.3, 1]] call _fnc_tell;
};

INFO_2("boarding point loaded %1, %2 left standing",_seated,count _left);
