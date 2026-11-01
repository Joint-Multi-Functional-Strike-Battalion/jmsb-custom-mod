#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: one shot (or one fire mission) from a PLAYER'S artillery, counted
 * towards the enemy's counter-battery fix (user, 2026-10-25: "lets add it back,
 * but we need an exception not to counter-battery AI arty", then "player side
 * virtual are the exception"). Only a player-crewed gun firing calls this (the
 * client hook in XEH_postInit) - so AI artillery and the players' virtual
 * TAC//SUPPORT batteries never reach it.
 *
 * The enemy's radar needs cbShots rounds from one source inside cbWindow
 * seconds to fix it. Then cbChance is rolled once; a hit has the enemy answer
 * cbDelayMin-cbDelayMax seconds later on where the source WAS at the fix -
 * so a crew that shoots and moves can be gone. One answer per source per
 * cbCooldown seconds.
 *
 * Arguments:
 * 0: The source - the gun, or the support module's battery logic <OBJECT>
 * 1: The player who fired or called it <OBJECT>
 * 2: Shots this counts as <NUMBER> (optional, default 1)
 *
 * Return Value:
 * A counter-battery mission was ordered <BOOL>
 *
 * Example:
 * [_gun, _player] call jmfsb_reaction_fnc_cbShot
 *
 * Public: No
 */

params [["_source", objNull, [objNull]], ["_shooter", objNull, [objNull]], ["_shots", 1, [0]]];

if (!isServer || {isNull _source} || {!isPlayer _shooter}) exitWith {false};
// From a client by remoteExec (review R1: it was a CBA event, so any client
// could name any gun and bring the enemy's guns down on it): the shooter is
// the sender's own, crews this gun, and it is artillery; one shot per call.
if (isRemoteExecuted) then {
    if !([_shooter] call EFUNC(common,senderIs)) exitWith {_source = objNull};
    if !(_shooter in crew _source) exitWith {_source = objNull};
    if (getNumber (configOf _source >> "artilleryScanner") <= 0) exitWith {_source = objNull};
    _shots = 1;
};
if (isNull _source) exitWith {
    WARNING_1("cbShot: refused - machine %1 does not crew that gun",remoteExecutedOwner);
    false
};
if (!GVAR(moduleUp) || GVAR(cbChance) <= 0) exitWith {false};

private _key = hashValue _source;
if (CBA_missionTime < (GVAR(cbLast) getOrDefault [_key, -1e9]) + GVAR(cbCooldown)) exitWith {false};

// The tally, restarted when the window has passed since its first shot.
(GVAR(cbTally) getOrDefault [_key, [0, CBA_missionTime]]) params ["_count", "_first"];
if (CBA_missionTime - _first > GVAR(cbWindow)) then {
    _count = 0;
    _first = CBA_missionTime;
};
_count = _count + _shots;
if (_count < GVAR(cbShots)) exitWith {
    GVAR(cbTally) set [_key, [_count, _first]];
    false
};

// Fixed. Whatever the roll, this source is done for the cooldown.
GVAR(cbTally) deleteAt _key;
GVAR(cbLast) set [_key, CBA_missionTime];
if (random 100 >= GVAR(cbChance)) exitWith {
    INFO_1("counter-battery: %1 tracked, no answer this time",mapGridPosition _source);
    false
};

private _pos = getPosATL _source;
// A battery off the edge of the map has nothing there to hit.
if !(_pos inArea [[worldSize / 2, worldSize / 2], worldSize / 2, worldSize / 2, 0, true]) exitWith {false};

private _delay = GVAR(cbDelayMin) + random ((GVAR(cbDelayMax) - GVAR(cbDelayMin)) max 0);
INFO_3("counter-battery: %1 fixed, answer in %2 s (fired by %3)",mapGridPosition _pos,round _delay,name _shooter);
[QGVAR(cbTracked), [_pos, side group _shooter, _delay]] call CBA_fnc_localEvent;
[{_this call FUNC(cbFire)}, [_pos, side group _shooter], _delay] call CBA_fnc_waitAndExecute;
true
