#include "..\script_component.hpp"
/*
 * Author: YonV
 * Server: mans a MOUT course (FUNC(mout)). Each spawn point gets a man at
 * the course's chance; a special point can swap him for a special man.
 * Each man is his own group, side from his config, and stays on his point.
 *
 * Arguments:
 * 0: Controller <OBJECT>
 *
 * Return Value:
 * Men spawned <ARRAY>
 *
 * Public: No
 */

params [["_ctrl", objNull, [objNull]]];

if (!isServer || {isNull _ctrl}) exitWith {[]};
if ((_ctrl getVariable [QGVAR(moutUnits), []]) isNotEqualTo []) exitWith {[]};

(_ctrl getVariable [QGVAR(mout), []]) params [["_name", ""], ["_points", []], ["_classes", []], ["_chance", 0], ["_specials", []]];

private _specialTypes = _specials apply {_x select 0};
private _units = [];

{
    if (random 100 < _chance) then {
        private _type = selectRandom _classes;
        private _special = _specialTypes find typeOf _x;
        if (_special >= 0) then {
            (_specials select _special) params ["", "_specialClasses", "_specialChance"];
            if (random 100 < _specialChance) then {
                _type = selectRandom _specialClasses;
            };
        };

        private _side = (getNumber (configFile >> "CfgVehicles" >> _type >> "side")) call BIS_fnc_sideType;
        private _grp = createGroup [_side, true];
        private _unit = _grp createUnit [_type, getPosATL _x, [], 0, "CAN_COLLIDE"];
        _unit setDir getDir _x;
        _unit setPosATL getPosATL _x;
        _unit disableAI "PATH";

        [QEGVAR(common,groupSpawned), [_grp, [], [false]]] call CBA_fnc_localEvent;
        _units pushBack _unit;
    };
} forEach _points;

_ctrl setVariable [QGVAR(moutUnits), _units, true];
INFO_2("mout: %1 manned with %2",_name,count _units);
_units
