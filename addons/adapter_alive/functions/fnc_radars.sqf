#include "script_component.hpp"
/*
 * Author: YonV
 * Every radar ALiVE is running as a profile, as a hunt pool.
 *
 * ALiVE has no radar registry and no radar test of its own - its SAM radars
 * are just vehicle profiles whose class descends from the base game's
 * Radar_System_0N_base_F, and a mod's radar (the 76N6 Clam Shell, a coastal
 * search set) is a vehicle profile with "radar" or the set's name in the
 * class. Both are read here so a network's EYES are hunted as one thing,
 * beside the launchers they feed - the split the anti-ship design makes,
 * applied to every network.
 *
 * The class test is cached: profiles are walked every hint and every hack.
 *
 * Arguments: None
 *
 * Return Value:
 * [[profileID <STRING>, pos <ARRAY>, side <SIDE>], ...] <ARRAY>
 *
 * Example:
 * call jmfsb_adapter_alive_fnc_radars
 *
 * Public: Yes
 */

if (!GVAR(ready)) exitWith {[]};

private _handler = [ALIVE_profileHandler, "profiles"] call ALiVE_fnc_hashGet;
if (isNil "_handler") exitWith {[]};
if !(_handler isEqualType []) exitWith {[]};

if (isNil QGVAR(radarClassCache)) then { GVAR(radarClassCache) = createHashMap };

private _out = [];
{
    private _p = _x;
    if !(_p isEqualType []) then {continue};
    if (([_p, "type", ""] call ALiVE_fnc_hashGet) isNotEqualTo "vehicle") then {continue};
    private _cls = [_p, "vehicleClass", ""] call ALiVE_fnc_hashGet;
    if (_cls isEqualTo "") then {continue};

    private _isRadar = GVAR(radarClassCache) get _cls;
    if (isNil "_isRadar") then {
        private _low = toLower _cls;
        _isRadar = _cls isKindOf "Radar_System_01_base_F"
            || {_cls isKindOf "Radar_System_02_base_F"}
            || {"radar" in _low}
            || {"76n6" in _low}
            || {"clamshell" in _low};
        GVAR(radarClassCache) set [_cls, _isRadar];
    };
    if (!_isRadar) then {continue};

    private _sideText = toUpper ([_p, "side", ""] call ALiVE_fnc_hashGet);
    private _side = [_sideText, sideUnknown] call EFUNC(common,sideFromText);
    private _pos = [_p, "position", []] call ALiVE_fnc_hashGet;
    private _id = [_p, "profileID", ""] call ALiVE_fnc_hashGet;
    if (_pos isNotEqualTo [] && _id isNotEqualTo "") then {
        _out pushBack [_id, _pos, _side];
    };
} forEach (_handler select HASH_VALUES);

_out
