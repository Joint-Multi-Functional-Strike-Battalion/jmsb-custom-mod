#include "script_component.hpp"
/*
 * Author: YonV
 * A battery's stock from the Virtual Artillery round attributes (HE, smoke,
 * illumination, cluster, guided: a class and a round count each), with the
 * module defaults for any it does not have - so a retired Artillery Battery
 * module with no guns and no ammunition list carries what a freshly placed
 * Virtual Artillery module does.
 *
 *   [name, roundsLeft, ammo class, kind]   roundsLeft -1 = unlimited
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * Stock <ARRAY>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_stockFromTable
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

private _callsign = _logic getVariable ["callsign", ""];
private _stock = [];

// [name, kind, class attribute, class default, rounds attribute, rounds default]
private _table = [
    ["HE", "he", "heClass", "Sh_155mm_AMOS", "heRounds", 96],
    ["SMOKE", "smoke", "smokeClass", "Smoke_120mm_AMOS_White", "smokeRounds", 24],
    ["ILLUM", "illum", "illumClass", "F_40mm_White_Illumination", "illumRounds", 12],
    ["CLUSTER", "cluster", "clusterClass", "", "clusterRounds", 0],
    ["GUIDED", "guided", "guidedClass", "", "guidedRounds", 0]
];

// A MAGAZINE CLASS IS ACCEPTED TOO (user, 2026-11-02; a module that takes the
// gun's magazines is Tun Firesupport's idea, by Tuntematon / Armafinland): it
// fires the shell the magazine carries - its `ammo` - and the RPT says which.
// A class that is neither is not carried, with an RPT line.
{
    _x params ["_name", "_kind", "_clsVar", "_clsDef", "_rdsVar", "_rdsDef"];
    private _cls = trim (_logic getVariable [_clsVar, _clsDef]);
    private _rounds = round (_logic getVariable [_rdsVar, _rdsDef]);
    if (_cls isNotEqualTo "" && _rounds isNotEqualTo 0) then {
        if (!isClass (configFile >> "CfgAmmo" >> _cls) && {isClass (configFile >> "CfgMagazines" >> _cls)}) then {
            private _ammo = getText (configFile >> "CfgMagazines" >> _cls >> "ammo");
            INFO_4("Artillery '%1': %2 magazine '%3' fires '%4'",_callsign,_name,_cls,_ammo);
            _cls = _ammo;
        };
        if (isClass (configFile >> "CfgAmmo" >> _cls)) then {
            _stock pushBack [_name, -1 max _rounds, _cls, _kind];
        } else {
            WARNING_3("Artillery '%1': %2 class '%3' is neither a CfgAmmo nor a CfgMagazines class - that type is not carried",_callsign,_name,_cls);
        };
    };
} forEach _table;

_stock
