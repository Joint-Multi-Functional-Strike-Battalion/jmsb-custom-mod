#include "script_component.hpp"
/*
 * Author: YonV
 * The side a faction class fights for, read from the faction's own config.
 *
 * THE OTHER HALF OF FUNC(sideFromText). That one reads a side NAME - "GUER",
 * "blufor" - which is what module fields hold. This reads a FACTION CLASS -
 * "OPF_T_F", "Atlas_BLU_H_F", "IND_C_F" - which is what ALiVE's own modules
 * hold, and what has to be turned back into a side before anything of this
 * mod's can decide whose ground or whose airframe something is.
 *
 * CfgFactionClasses side numbers are Arma's own: 0 east, 1 west, 2
 * independent, 3 civilian. A faction with no side entry - a mod's, usually -
 * is sideUnknown rather than a guess, because the callers of this treat
 * "cannot say" and "west" very differently.
 *
 * Cached: this is asked once per placement module per TAOR read, and a config
 * lookup that always returns the same answer should only cost once.
 *
 * Arguments:
 * 0: Faction class <STRING>
 * 1: What an unreadable faction returns <SIDE> (optional, default sideUnknown)
 *
 * Return Value:
 * The side <SIDE>
 *
 * Example:
 * private _side = ["OPF_T_F"] call jmfsb_common_fnc_sideOfFaction
 *
 * Public: Yes
 */

params [["_faction", "", [""]], ["_default", sideUnknown, [sideUnknown]]];

if (_faction isEqualTo "") exitWith {_default};

private _cache = missionNamespace getVariable [QGVAR(factionSideCache), createHashMap];
private _hit = _cache getOrDefault [_faction, sideUnknown];

if (_hit isEqualTo sideUnknown) then {
    private _cfg = configFile >> "CfgFactionClasses" >> _faction;

    if (isNumber (_cfg >> "side")) then {
        _hit = switch (getNumber (_cfg >> "side")) do {
            case 0: {east};
            case 1: {west};
            case 2: {independent};
            case 3: {civilian};
            default {sideUnknown};
        };
    };

    _cache set [_faction, _hit];
    missionNamespace setVariable [QGVAR(factionSideCache), _cache];
};

[_hit, _default] select (_hit isEqualTo sideUnknown)
