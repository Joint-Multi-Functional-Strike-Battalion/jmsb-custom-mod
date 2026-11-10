#include "script_component.hpp"
/*
 * Author: YonV
 * One leader, in a safe house.
 *
 * He is a real man, not a profile: the whole chain is about finding and
 * reaching a particular person, and a profile cannot be captured alive.
 * He is pinned in his house between rotations, carries a phone so his body is
 * always worth searching, and his house may be watched.
 *
 * Arguments:
 * 0: Leader index <NUMBER>
 *
 * Return Value:
 * [unit, houseIndex, "up", tier] <ARRAY>
 *
 * Public: No
 */

params ["_i"];

private _hi = floor random count GVAR(houses);
private _house = GVAR(houses) select _hi;
private _spots = _house buildingPos -1;
private _at = _spots param [floor random count _spots, getPosATL _house];

// WHO from ALiVE: the asymmetric commander's own faction. Without ALiVE, the
// one FUNC(start) read off the mission (user, 2026-11-02).
private _faction = GVAR(asymFaction);
if (!isNil QEFUNC(adapter_alive,commanders) && {[] call EFUNC(common,aliveLoaded)}) then {
    {
        _x params ["_cside", "", "_cf"];
        if (_cside isEqualTo GVAR(asymSide)) exitWith { _faction = _cf };
    } forEach (call EFUNC(adapter_alive,commanders));
};

private _kinds = [];
{
    private _cls = configName _x;
    if (getNumber (_x >> "scope") == 2
        && {getText (_x >> "faction") == _faction}
        && {_cls isKindOf "CAManBase"}) then {
        _kinds pushBack _cls;
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

if (_kinds isEqualTo []) exitWith {
    WARNING_1("faction '%1' fields nobody - leader not created",_faction);
    [objNull, -1, "dead", 0]
};

// The common pre-spawn gate as a final assert - the house list is already
// TAOR-filtered at collection, this catches drift if that ever loosens.
// Same no-leader record the no-faction guard returns.
if (!([GVAR(asymSide), _at, "leader"] call EFUNC(common,taorGate))) exitWith {
    [objNull, -1, "dead", 0]
};

private _grp = createGroup [GVAR(asymSide), true];
private _u = _grp createUnit [selectRandom _kinds, _at, [], 0, "CAN_COLLIDE"];
_u setPosATL _at;
_u setName format ["Leader %1", _i + 1];
_u setRank "CAPTAIN";
_u disableAI "PATH";

_u setVariable [QGVAR(index), _i, true];
// His phone is the paperwork - the body is always worth searching.
_u setVariable ["jmfsb_hacking_carriesPhone", true, true];

_u addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator"];
    private _i = _unit getVariable [QGVAR(index), -1];

    // ONLY A PLAYER CUTS THE CHAIN. The instigator is the man behind a
    // vehicle's weapon, effectiveCommander credits a kill logged to the
    // vehicle itself; anything else - crossfire, a mine, ALiVE's own war -
    // and the network replaces him, because a kill nobody earned would end
    // a hunt nobody got to run.
    if (isNull _instigator) then {_instigator = _killer};
    private _byPlayer = isPlayer _instigator
        || {isPlayer _killer}
        || {!isNull _killer && {isPlayer effectiveCommander _killer}};

    if (_byPlayer) then {
        [_i, "dead"] call FUNC(down);
    } else {
        // Next frame, out from under the corpse's own Killed event.
        [{_this call FUNC(replace)}, [_i, _unit]] call CBA_fnc_execNextFrame;
    };
}];

// HIS CAR. Parked at the house he starts in and travelling with him from
// then on - see FUNC(rotate). A leader who can only walk between towns is a
// leader players never see moving.
private _car = [getPosATL _house, _house] call FUNC(leaderCar);
_u setVariable [QGVAR(car), _car, true];

[_house] call FUNC(armTrap);

[_u, _hi, "up", 0]
