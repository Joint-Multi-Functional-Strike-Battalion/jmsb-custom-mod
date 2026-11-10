#include "script_component.hpp"
/*
 * Author: YonV
 * A side's artillery, from the profile system, as a hunt pool (new.md
 * section 1.1 - jmfsb spawns none of this).
 *
 * The test is the config's own artilleryScanner flag, so whatever ALiVE
 * placed or virtualised is what the hunt sees, and a battery that dies leaves
 * the pool by itself. Vehicle profiles only - a mortar in a man's backpack is
 * not a battery.
 *
 * Arguments:
 * 0: Side <SIDE> (sideUnknown = every side)
 *
 * Return Value:
 * [[profileID <STRING>, pos <ARRAY>, side <SIDE>], ...] <ARRAY>
 *
 * Example:
 * [east] call jmfsb_adapter_alive_fnc_artyTargets
 */

params [["_side", sideUnknown, [sideUnknown]]];

if (!GVAR(ready)) exitWith {[]};

private _handler = [ALIVE_profileHandler, "profiles"] call ALiVE_fnc_hashGet;
if (isNil "_handler") exitWith {[]};
if !(_handler isEqualType []) exitWith {[]};

private _out = [];
{
    private _p = _x;
    if !(_p isEqualType []) then {continue};
    if (([_p, "type", ""] call ALiVE_fnc_hashGet) isNotEqualTo "vehicle") then {continue};

    private _cls = [_p, "vehicleClass", ""] call ALiVE_fnc_hashGet;
    if (_cls isEqualTo "") then {continue};
    if (getNumber (configFile >> "CfgVehicles" >> _cls >> "artilleryScanner") != 1) then {continue};

    private _sideText = toUpper ([_p, "side", ""] call ALiVE_fnc_hashGet);
    private _pside = [_sideText, sideUnknown] call EFUNC(common,sideFromText);
    if (_side isNotEqualTo sideUnknown && _pside isNotEqualTo _side) then {continue};

    private _pos = [_p, "position", []] call ALiVE_fnc_hashGet;
    private _id = [_p, "profileID", ""] call ALiVE_fnc_hashGet;
    if (_pos isNotEqualTo [] && _id isNotEqualTo "") then {
        _out pushBack [_id, _pos, _pside];
    };
} forEach (_handler select HASH_VALUES);

_out
