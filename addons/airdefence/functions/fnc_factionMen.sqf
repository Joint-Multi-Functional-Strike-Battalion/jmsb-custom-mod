#include "script_component.hpp"
/*
 * Author: YonV
 * Infantry classes belonging to a faction, for crewing MANPAD teams.
 *
 * Its own men, so a team looks like the rest of the commander's force rather
 * than a squad of strangers on a hill. Cached: this is a sweep of every vehicle
 * class in the mission and must not run per team.
 *
 * Arguments:
 * 0: The faction <STRING>
 * 1: The side, for the fallback <SIDE>
 *
 * Return Value:
 * Man classes, [] if none <ARRAY>
 *
 * Example:
 * ["OPF_G_F", east] call jmfsb_airdefence_fnc_factionMen
 */

params [["_faction", "", [""]], ["_side", sideUnknown, [sideUnknown]]];

if (isNil QGVAR(menCache)) then { GVAR(menCache) = createHashMap };

private _key = format ["%1_%2", _faction, _side];
private _hit = GVAR(menCache) get _key;
if (!isNil "_hit") exitWith {_hit};

private _kinds = [];

if (_faction isNotEqualTo "") then {
    {
        private _cls = configName _x;
        if (getNumber (_x >> "scope") == 2
            && {getText (_x >> "faction") == _faction}
            && {_cls isKindOf "CAManBase"}) then {
            _kinds pushBack _cls;
        };
    } forEach ("true" configClasses (configFile >> "CfgVehicles"));
};

if (_kinds isEqualTo []) then {
    private _fallback = switch (_side) do {
        case west: {"B_Soldier_F"};
        case independent: {"I_Soldier_F"};
        default {"O_Soldier_F"};
    };
    if (isClass (configFile >> "CfgVehicles" >> _fallback)) then {
        _kinds = [_fallback];
    };
    INFO_1("faction '%1' fields nobody - MANPAD teams fall back to a vanilla rifleman",_faction);
};

GVAR(menCache) set [_key, _kinds];

_kinds
