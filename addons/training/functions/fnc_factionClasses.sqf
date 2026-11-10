#include "script_component.hpp"
/*
 * Author: YonV
 * Every faction's spawnable classes, read once off CfgVehicles and kept: the
 * riflemen (public men carrying a primary weapon), the static weapons and the
 * armed cars, APCs and tanks. Side comes from the classes' own config.
 *
 * Arguments:
 * 0: Faction class, "" for the whole table <STRING> (optional, default "")
 *
 * Return Value:
 * For a faction: [side, men, statics, vehicles], [] for an unknown one;
 * for "": the table, faction -> that <HASHMAP or ARRAY>
 *
 * Example:
 * ["OPF_F"] call jmfsb_training_fnc_factionClasses
 *
 * Public: No
 */

params [["_faction", "", [""]]];

if (isNil QGVAR(factionTable)) then {
    private _table = createHashMap;
    {
        private _class = configName _x;
        private _f = getText (_x >> "faction");
        if (_f isEqualTo "") then {continue};
        private _row = _table getOrDefault [_f, [(getNumber (_x >> "side")) call BIS_fnc_sideType, [], [], []]];
        switch (true) do {
            case (_class isKindOf "CAManBase"): {
                // a primary weapon among the weapons - not a pilot, crewman or diver with a pistol
                if ((getArray (_x >> "weapons")) findIf {getNumber (configFile >> "CfgWeapons" >> _x >> "type") isEqualTo 1} >= 0) then {
                    (_row # 1) pushBack _class;
                };
            };
            case (_class isKindOf "StaticWeapon"): {(_row # 2) pushBack _class};
            case ((_class isKindOf "Car" || _class isKindOf "Tank") && {(getArray (_x >> "Turrets" >> "MainTurret" >> "weapons")) isNotEqualTo []}): {
                (_row # 3) pushBack _class;
            };
        };
        _table set [_f, _row];
    } forEach ("getNumber (_x >> 'scope') == 2" configClasses (configFile >> "CfgVehicles"));
    GVAR(factionTable) = _table;
};

if (_faction isEqualTo "") exitWith {GVAR(factionTable)};
GVAR(factionTable) getOrDefault [_faction, []]
