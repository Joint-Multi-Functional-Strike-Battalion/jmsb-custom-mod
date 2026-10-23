#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one RETIRED JMSB - Artillery Battery module and runs it as a virtual
 * battery (user, 2026-10-20: "arty should be virtual"). The class stays so
 * the missions that placed it still load and still get their battery; it is
 * hidden from Eden and Zeus, and JMSB - Virtual Artillery is what new
 * missions place.
 *
 * NO GUN AIMS OR FIRES. Synced artillery, if any, gives three things read
 * once at start and is otherwise left alone - not crewed, not loaded, not
 * ordered, not watched:
 *   - where the battery is: the guns' centre (else the module)
 *   - how many guns: the count synced (else the Virtual Artillery default)
 *   - what it carries, when the Ammunition Per Gun field is blank: the
 *     rounds in the guns' artillery magazines, summed per magazine
 * The muzzle velocity is the first round's magazine initSpeed, times the
 * guns' top artillery charge when there are guns, and the range is what that
 * reaches (FUNC(ballistics)). The field's magazines (or CfgAmmo classes) are
 * rounds PER GUN, multiplied by the gun count. With no guns and no field the
 * battery carries the Virtual Artillery defaults.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, [], true] call jmfsb_support_fires_fnc_moduleArtillery
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};
if (_logic in GVAR(entities)) exitWith {};

private _callsign = _logic getVariable ["callsign", ""];
private _cfgMags = configFile >> "CfgMagazines";
private _cfgAmmo = configFile >> "CfgAmmo";

private _guns = ((synchronizedObjects _logic) + _units) arrayIntersect ((synchronizedObjects _logic) + _units);
_guns = _guns select {
    _x isKindOf "AllVehicles" && {getNumber (configOf _x >> "artilleryScanner") > 0}
};
private _gunCount = [VA_DEF_GUNS, count _guns] select (_guns isNotEqualTo []);

// One stock entry per magazine (or ammo) class: [name, rounds, ammo, kind].
private _byClass = createHashMap;
private _order = [];
private _add = {
    params ["_cls", "_rounds"];
    private _key = toLower _cls;
    if !(_key in _byClass) then {_order pushBack _cls};
    _byClass set [_key, (_byClass getOrDefault [_key, 0]) + _rounds];
};

{
    private _pair = (_x splitString ":") apply {[_x] call CBA_fnc_trim};
    _pair params [["_cls", ""], ["_n", "0"]];
    private _rounds = parseNumber _n;
    if (_cls isNotEqualTo "" && _rounds > 0) then {
        if (isClass (_cfgMags >> _cls) || {isClass (_cfgAmmo >> _cls)}) then {
            [_cls, _rounds * _gunCount] call _add;
        } else {
            WARNING_2("Artillery Battery '%1': '%2' is neither a magazine nor an ammo class - skipped",_callsign,_cls);
        };
    };
} forEach ((_logic getVariable ["ammunition", ""]) splitString ",");

if (_order isEqualTo []) then {
    {
        private _gun = _x;
        private _arty = (getArtilleryAmmo [_gun]) apply {toLower _x};
        {
            _x params ["_cls", "", "_ammo"];
            if ((toLower _cls) in _arty && _ammo > 0) then {[_cls, _ammo] call _add};
        } forEach (magazinesAllTurrets _gun);
    } forEach _guns;
};

private _stock = _order apply {
    private _cls = _x;
    private _isMag = isClass (_cfgMags >> _cls);
    private _ammo = [_cls, getText (_cfgMags >> _cls >> "ammo")] select _isMag;
    private _name = "";
    if (_isMag) then {
        _name = getText (_cfgMags >> _cls >> "displayNameShort");
        if (_name isEqualTo "") then {_name = getText (_cfgMags >> _cls >> "displayName")};
    };
    if (_name isEqualTo "") then {_name = _cls};
    [toUpper _name, _byClass get (toLower _cls), _ammo, toLower _cls]
} select {
    isClass (_cfgAmmo >> (_x select 2))
};

// The muzzle velocity from the first round fed by a magazine.
private _mv = VA_DEF_MV;
private _firstMag = _order findIf {isClass (_cfgMags >> _x)};
if (_firstMag > -1) then {
    private _speed = getNumber (_cfgMags >> (_order select _firstMag) >> "initSpeed");
    if (_speed > 0) then {_mv = _speed};
    if (_guns isNotEqualTo []) then {
        private _gun = _guns select 0;
        private _weapon = (_gun weaponsTurret ([[0], _gun unitTurret (gunner _gun)] select !(isNull gunner _gun))) param [0, ""];
        private _charges = (getArray (configFile >> "CfgWeapons" >> _weapon >> "modes")) apply {
            getNumber (configFile >> "CfgWeapons" >> _weapon >> _x >> "artilleryCharge")
        };
        private _top = selectMax (_charges + [0]);
        if (_top > 0) then {_mv = _mv * _top};
    };
};

if (_stock isEqualTo []) then {
    _stock = [_logic] call FUNC(stockFromTable);
    _mv = VA_DEF_MV;
};

private _origin = if (_guns isEqualTo []) then {
    getPosATL _logic
} else {
    private _sum = [0, 0, 0];
    {_sum = _sum vectorAdd (getPosATL _x)} forEach _guns;
    _sum vectorMultiply (1 / count _guns)
};

private _platform = if (_guns isEqualTo []) then {"VIRTUAL BATTERY"} else {
    toUpper getText (configOf (_guns select 0) >> "displayName")
};

INFO_3("Artillery Battery '%1' runs as a virtual battery: %2 guns, %3 round types",_callsign,_gunCount,count _stock);

[_logic, _stock, _gunCount, _origin, _mv, 0, _mv * _mv / GRAVITY, _platform, "STEEL"] call FUNC(setupBattery);
